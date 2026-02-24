#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Creating symlinks..."

safe_symlink "$DOTFILES/config/.mackup.cfg" "$HOME/.mackup.cfg"
safe_symlink "$DOTFILES/config/env/zshrc" "$HOME/.zshrc"

if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi
safe_symlink "$DOTFILES/config/ssh/config" "$HOME/.ssh/config"

safe_symlink "$DOTFILES/config/git/ignore" "$HOME/.gitignore"
safe_symlink "$DOTFILES/config/git/config" "$HOME/.gitconfig"

POSITRON_USER_DIR="$HOME/Library/Application Support/Positron/User"
if [ ! -d "$POSITRON_USER_DIR" ]; then
    mkdir -p "$POSITRON_USER_DIR"
fi
safe_symlink "$DOTFILES/config/vscode/settings.json" "$POSITRON_USER_DIR/settings.json"
safe_symlink "$DOTFILES/config/vscode/keybindings.json" "$POSITRON_USER_DIR/keybindings.json"

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [ ! -d "$VSCODE_USER_DIR" ]; then
    mkdir -p "$VSCODE_USER_DIR"
fi
safe_symlink "$DOTFILES/config/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
safe_symlink "$DOTFILES/config/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"

safe_symlink "$DOTFILES/config/claude" "$HOME/.claude"

if [ ! -d "$HOME/.config/opencode" ]; then
    mkdir -p "$HOME/.config/opencode"
fi
safe_symlink "$DOTFILES/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

if [ -n "$FREESURFER_HOME" ] && [ -d "$FREESURFER_HOME" ]; then
    sudo ln -sf "$DOTFILES/freesurfer_license.txt" "$FREESURFER_HOME/.license"
    log_info "Created FreeSurfer license symlink"
else
    log_warn "Skipping FreeSurfer license (FREESURFER_HOME not set or doesn't exist)"
fi

log_info "Symlinks created successfully!"
