#!/bin/sh
#
# Reap abandoned Claude Code editor-extension processes.
#
# Positron and VS Code spawn a `native-binary/claude` process per session and
# parent it to a long-lived extension host. The host outlives the tab, so the
# processes accumulate until they exhaust RAM and swap.
#
# A process is reaped only when it is BOTH older than MAX_AGE_DAYS and has
# used less than CPU_BUDGET_PERCENT of one core across a sampling window.
#
# The budget is a threshold, not equality: an idle session still accrues a few
# centiseconds per window from Node timers and file watchers, so testing for
# an unchanged CPU counter classified every real process as busy and reaped
# nothing. Total CPU time is used rather than utime, because a process
# spinning in syscalls accrues stime and reads as idle on utime alone.
#
# shortcut: CPU idleness cannot distinguish an abandoned process from an open
# tab sitting at the prompt, so MAX_AGE_DAYS is the real guard. Upgrade to
# checking whether the owning editor window still holds the IPC socket if a
# live old session is ever killed.

set -u

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
. "$DOTFILES/install/lib/utils.sh"
set +e

MAX_AGE_DAYS="${CLAUDE_REAPER_MAX_AGE_DAYS:-3}"
GRACE_SECONDS="${CLAUDE_REAPER_GRACE_SECONDS:-10}"
CPU_SAMPLE_SECONDS="${CLAUDE_REAPER_CPU_SAMPLE_SECONDS:-60}"
PATTERN="${CLAUDE_REAPER_PATTERN:-extensions/anthropic\.claude-code-.*/resources/native-binary/claude}"

# An unvalidated knob is worse than a wrong one: a non-numeric sleep interval
# fails instantly under `set +e`, collapsing the sampling window to nothing and
# removing the only guard between an old process and SIGKILL.
require_int() {
  case "$2" in
  '' | *[!0-9]*)
    log_error "$1 must be a non-negative integer (got '$2')"
    exit 2
    ;;
  esac
}
require_int MAX_AGE_DAYS "$MAX_AGE_DAYS"
require_int GRACE_SECONDS "$GRACE_SECONDS"
require_int CPU_SAMPLE_SECONDS "$CPU_SAMPLE_SECONDS"

# The budget has to scale with the window: idle drift arrives in bursts, so a
# fixed centisecond allowance is either tighter than one burst (reaps nothing,
# the original bug) or looser than a short window can justify. Measured on this
# machine: idle processes stay under 2% CPU, a process serving a turn ran 97%.
CPU_BUDGET_PERCENT="${CLAUDE_REAPER_CPU_BUDGET_PERCENT:-5}"
require_int CPU_BUDGET_PERCENT "$CPU_BUDGET_PERCENT"
CPU_BUDGET_CS=$((CPU_SAMPLE_SECONDS * CPU_BUDGET_PERCENT))

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
  ps -eo pid=,etime=,command= | awk -v max_days="$MAX_AGE_DAYS" -v pat="$PATTERN" -v self="$$" -v parent="$PPID" '
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
      if (pid == self || pid == parent) next
      if (cmd !~ pat) next
      if (etime_secs(et) < max_days * 86400) next
      print pid "\t" et
    }
  '
}

# Total CPU time in centiseconds, for [[dd-]hh:]mm:ss.ff as ps prints it.
cpu_cs_of() {
  ps -o time= -p "$1" 2>/dev/null | awk '
    {
      gsub(/ /, "")
      d = 0
      if (index($0, "-") > 0) { split($0, p, "-"); d = p[1]; $0 = p[2] }
      n = split($0, f, ":")
      if (n == 3) { h = f[1]; m = f[2]; s = f[3] }
      else        { h = 0;    m = f[1]; s = f[2] }
      split(s, sec, ".")
      print ((d * 24 + h) * 60 + m) * 6000 + sec[1] * 100 + (sec[2] + 0)
    }
  '
}

# The command line must still match before any signal: PIDs are sampled, then
# reused freely across the sampling and grace windows.
still_matches() {
  ps -o command= -p "$1" 2>/dev/null | grep -qE "$PATTERN"
}

info "Scanning for Claude extension processes older than ${MAX_AGE_DAYS}d"

candidates=$(find_candidates)
if [ -z "$candidates" ]; then
  info "Nothing to reap"
  exit 0
fi

before=$(mktemp)
trap 'rm -f "$before"' EXIT INT TERM
echo "$candidates" | while IFS="$(printf '\t')" read -r pid age; do
  echo "$pid $(cpu_cs_of "$pid")"
done >"$before"

sleep "$CPU_SAMPLE_SECONDS"

idle=""
active=0
vanished=0
while read -r pid age; do
  was=$(awk -v p="$pid" '$1 == p { print $2 }' "$before")
  now=$(cpu_cs_of "$pid")
  if [ -z "$was" ] || [ -z "$now" ]; then
    vanished=$((vanished + 1))
    continue
  fi
  spent=$((now - was))
  if [ "$spent" -gt "$CPU_BUDGET_CS" ]; then
    info "Skipping $pid (age ${age}) — ${spent}cs CPU over ${CPU_SAMPLE_SECONDS}s, session looks active"
    active=$((active + 1))
    continue
  fi
  info "Reaping $pid (age ${age}) — ${spent}cs CPU over ${CPU_SAMPLE_SECONDS}s"
  idle="$idle $pid"
done <<EOF
$(echo "$candidates" | tr '\t' ' ')
EOF

if [ -z "$idle" ]; then
  info "No idle processes to reap ($active active)"
  exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
  warn "Dry run — would terminate:$idle"
  exit 0
fi

signalled=""
for pid in $idle; do
  if still_matches "$pid"; then
    kill -TERM "$pid" 2>/dev/null && signalled="$signalled $pid"
  else
    warn "Skipping $pid — no longer a Claude process, PID was reused"
    vanished=$((vanished + 1))
  fi
done

if [ -z "$signalled" ]; then
  info "Nothing signalled ($active active, $vanished gone)"
  exit 0
fi

sleep "$GRACE_SECONDS"

killed=0
forced=0
for pid in $signalled; do
  if ! kill -0 "$pid" 2>/dev/null; then
    killed=$((killed + 1))
    continue
  fi
  if still_matches "$pid"; then
    kill -KILL "$pid" 2>/dev/null
    forced=$((forced + 1))
    killed=$((killed + 1))
  else
    warn "Not forcing $pid — no longer a Claude process, PID was reused"
    vanished=$((vanished + 1))
  fi
done

info "Reaped $killed process(es), $forced needed SIGKILL, $active left running, $vanished gone"
