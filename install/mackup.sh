#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up Mackup..."

if ! command -v mackup >/dev/null 2>&1; then
    log_info "Installing Mackup..."
    require_command brew
    brew install mackup
else
    log_info "Mackup already installed"
fi

if [ -f "$HOME/.mackup.cfg" ]; then
    log_info "Restoring Mackup settings..."
    mackup restore
else
    log_warn "Mackup config not found, skipping restore"
fi

log_info "Mackup setup complete!"
