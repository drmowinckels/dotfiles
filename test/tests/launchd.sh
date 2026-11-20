#!/bin/sh

echo "Testing launchd agents..."
echo ""

AGENT_DIR="$HOME/.dotfiles/config/launchd"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

if [ ! -d "$AGENT_DIR" ]; then
  error "config/launchd does not exist"
  return 0 2>/dev/null || true
fi

for plist in "$AGENT_DIR"/*.plist; do
  [ -e "$plist" ] || continue

  name=$(basename "$plist")
  label=$(basename "$plist" .plist)

  if plutil -lint "$plist" >/dev/null 2>&1; then
    success "$name is valid plist XML"
  else
    error "$name is malformed"
  fi

  if [ -L "$LAUNCH_AGENTS/$name" ]; then
    success "$name is symlinked into LaunchAgents"
  else
    warn "$name is not installed (run install/launchd.sh)"
  fi

  if launchctl list 2>/dev/null | grep -q "$label"; then
    success "$label is loaded"
  else
    warn "$label is not loaded"
  fi
done

if [ -x "$HOME/.dotfiles/config/bin/claude-reaper.sh" ]; then
  success "claude-reaper.sh is executable"
else
  error "claude-reaper.sh is missing or not executable"
fi

REAPER="$HOME/.dotfiles/config/bin/claude-reaper.sh"

# Every assertion below pins CLAUDE_REAPER_PATTERN to a purpose-spawned fixture
# and sets CLAUDE_REAPER_DRY_RUN, so a regression in the dry-run guard can only
# reach the fixture and never the real editor processes.
reaper_fixture() {
  CLAUDE_REAPER_PATTERN="$1" \
    CLAUDE_REAPER_MAX_AGE_DAYS="${2:-0}" \
    CLAUDE_REAPER_CPU_SAMPLE_SECONDS=3 \
    CLAUDE_REAPER_DRY_RUN=1 \
    "$REAPER" --dry-run 2>&1
}

/bin/sleep 97 &
idle_pid=$!
sh -c 'while :; do :; done' &
busy_pid=$!
sleep 1

out=$(reaper_fixture 'sleep 97')
if echo "$out" | grep -q "would terminate:.*$idle_pid"; then
  success "claude-reaper.sh selects an idle process"
else
  error "claude-reaper.sh did not select idle fixture $idle_pid"
fi

out=$(reaper_fixture 'while :')
if echo "$out" | grep -q "Skipping $busy_pid"; then
  success "claude-reaper.sh spares a busy process"
else
  error "claude-reaper.sh did not spare busy fixture $busy_pid"
fi

out=$(reaper_fixture 'sleep 97' 3)
if echo "$out" | grep -q "Nothing to reap"; then
  success "claude-reaper.sh honours the age floor"
else
  error "claude-reaper.sh reaped below the age floor"
fi

kill "$idle_pid" "$busy_pid" 2>/dev/null
wait "$idle_pid" "$busy_pid" 2>/dev/null

CLAUDE_REAPER_CPU_SAMPLE_SECONDS=notanumber "$REAPER" --dry-run >/dev/null 2>&1
if [ $? -eq 2 ]; then
  success "claude-reaper.sh rejects a non-numeric interval"
else
  error "claude-reaper.sh accepted a non-numeric interval"
fi

if "$REAPER" --bogus >/dev/null 2>&1; then
  error "claude-reaper.sh accepted an unknown argument"
else
  success "claude-reaper.sh rejects an unknown argument"
fi
