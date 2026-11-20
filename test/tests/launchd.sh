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

if "$HOME/.dotfiles/config/bin/claude-reaper.sh" --dry-run >/dev/null 2>&1; then
  success "claude-reaper.sh dry run succeeds"
else
  error "claude-reaper.sh dry run failed"
fi
