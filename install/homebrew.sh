#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up Homebrew..."

if ! xcode-select --version >/dev/null 2>&1; then
    log_info "Installing Xcode Command Line Tools..."
    sudo xcode-select --install
fi

if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    log_info "Homebrew already installed"
fi

log_info "Updating Homebrew..."
brew update

log_info "Installing Homebrew packages from Brewfile..."
NONINTERACTIVE=1 brew bundle --file="$DOTFILES/config/Brewfile"

log_info "Homebrew setup complete!"
