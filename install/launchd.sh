#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
AGENT_DIR="$DOTFILES/config/launchd"

log_info "Installing launchd agents..."

if [ ! -d "$LAUNCH_AGENTS" ]; then
  mkdir -p "$LAUNCH_AGENTS"
fi

for plist in "$AGENT_DIR"/*.plist; do
  [ -e "$plist" ] || continue

  label=$(basename "$plist" .plist)
  target="$LAUNCH_AGENTS/$(basename "$plist")"

  safe_symlink "$plist" "$target"

  # Reload so an edited plist takes effect without a logout.
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  if launchctl bootstrap "gui/$(id -u)" "$target" 2>/dev/null; then
    log_info "Loaded $label"
  else
    log_warn "Could not load $label (may already be loaded)"
  fi
done

log_info "Launchd agents installed!"
