#!/bin/sh
#
# Reap abandoned Claude Code editor-extension processes.
#
# Positron and VS Code spawn a `native-binary/claude` process per session and
# parent it to a long-lived extension host. The host outlives the tab, so the
# processes accumulate until they exhaust RAM and swap.
#
# A process is reaped only when it is BOTH older than MAX_AGE_DAYS and burning
# no CPU across a short sampling window, so a long session that is mid-turn is
# left alone.

set -u

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
. "$DOTFILES/install/lib/utils.sh"
set +e

MAX_AGE_DAYS="${CLAUDE_REAPER_MAX_AGE_DAYS:-3}"
GRACE_SECONDS="${CLAUDE_REAPER_GRACE_SECONDS:-10}"
CPU_SAMPLE_SECONDS="${CLAUDE_REAPER_CPU_SAMPLE_SECONDS:-5}"
PATTERN="${CLAUDE_REAPER_PATTERN:-extensions/anthropic\.claude-code-.*/resources/native-binary/claude}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude-reaper"
LOG_FILE="$STATE_DIR/reaper.log"
MAX_LOG_BYTES=1048576

DRY_RUN=0
case "${1:-}" in
-n | --dry-run) DRY_RUN=1 ;;
"") ;;
*)
  log_error "Unknown argument: $1 (expected --dry-run)"
  exit 2
  ;;
esac
if [ "${CLAUDE_REAPER_DRY_RUN:-0}" = "1" ]; then
  DRY_RUN=1
fi

# The launchd job sets CLAUDE_REAPER_LOG so unattended runs land in the log
# file; run by hand, output goes to the terminal.
if [ "${CLAUDE_REAPER_LOG:-0}" = "1" ]; then
  mkdir -p "$STATE_DIR"
  if [ -f "$LOG_FILE" ] && [ "$(wc -c <"$LOG_FILE")" -gt "$MAX_LOG_BYTES" ]; then
    mv -f "$LOG_FILE" "$LOG_FILE.1"
  fi
  exec >>"$LOG_FILE" 2>&1
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# Scheduled output is only useful with a timestamp on every line.
stamp() { date '+%Y-%m-%dT%H:%M:%S%z'; }
info() { echo "${GREEN}[INFO]${NC} $(stamp) $1"; }
warn() { echo "${YELLOW}[WARN]${NC} $(stamp) $1"; }

find_candidates() {
  ps -eo pid=,etime=,command= | awk -v max_days="$MAX_AGE_DAYS" -v pat="$PATTERN" '
    function etime_secs(e,   parts, hms, n, d, h, m, s) {
      d = 0
      if (index(e, "-") > 0) {
        split(e, parts, "-")
        d = parts[1]
        e = parts[2]
      }
      n = split(e, hms, ":")
      if (n == 3) { h = hms[1]; m = hms[2]; s = hms[3] }
      else        { h = 0;      m = hms[1]; s = hms[2] }
      return ((d * 24 + h) * 60 + m) * 60 + s
    }
    {
      pid = $1
      et = $2
      cmd = ""
      for (i = 3; i <= NF; i++) cmd = cmd (i > 3 ? " " : "") $i
      if (cmd !~ pat) next
      if (etime_secs(et) < max_days * 86400) next
      print pid "\t" et
    }
  '
}

cpu_time_of() {
  ps -o utime= -p "$1" 2>/dev/null | tr -d ' '
}

info "Scanning for Claude extension processes older than ${MAX_AGE_DAYS}d"

candidates=$(find_candidates)
if [ -z "$candidates" ]; then
  info "Nothing to reap"
  exit 0
fi

before=$(mktemp)
echo "$candidates" | while IFS="$(printf '\t')" read -r pid age; do
  echo "$pid $(cpu_time_of "$pid")"
done >"$before"

sleep "$CPU_SAMPLE_SECONDS"

idle=""
active=0
while read -r pid age; do
  was=$(awk -v p="$pid" '$1 == p { print $2 }' "$before")
  now=$(cpu_time_of "$pid")
  if [ -z "$now" ]; then
    continue
  fi
  if [ "$was" != "$now" ]; then
    info "Skipping $pid (age ${age}) — burning CPU, session looks active"
    active=$((active + 1))
    continue
  fi
  info "Reaping $pid (age ${age})"
  idle="$idle $pid"
done <<EOF
$(echo "$candidates" | tr '\t' ' ')
EOF
rm -f "$before"

if [ -z "$idle" ]; then
  info "No idle processes to reap ($active active)"
  exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
  warn "Dry run — would terminate:$idle"
  exit 0
fi

for pid in $idle; do
  kill -TERM "$pid" 2>/dev/null
done

sleep "$GRACE_SECONDS"

killed=0
forced=0
for pid in $idle; do
  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null
    forced=$((forced + 1))
  fi
  killed=$((killed + 1))
done

info "Reaped $killed process(es), $forced needed SIGKILL, $active left running"
