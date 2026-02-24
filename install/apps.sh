#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up applications..."

if command -v positron >/dev/null 2>&1; then
    extensions_file="$DOTFILES/config/vscode/extensions.txt"
    if [ -f "$extensions_file" ]; then
        log_info "Installing Positron extensions..."
        cat "$extensions_file" | xargs -L1 positron --install-extension
    else
        log_warn "Extensions file not found: $extensions_file"
    fi
else
    log_warn "Positron not found, skipping extension installation"
fi

if command -v Rscript >/dev/null 2>&1; then
    install_script="$DOTFILES/config/r/install_pkgs.R"
    if [ -f "$install_script" ]; then
        log_info "Installing R packages..."
        Rscript "$install_script"
    else
        log_warn "R install script not found: $install_script"
    fi
else
    log_warn "R not found, skipping R package installation"
fi

log_info "Application setup complete!"
