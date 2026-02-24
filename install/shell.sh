#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up shell environment..."

require_command curl
require_command git

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
else
    log_info "Oh My Zsh already installed"
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log_info "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    log_info "zsh-autosuggestions already installed"
fi

log_info "Shell setup complete!"
