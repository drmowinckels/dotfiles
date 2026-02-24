#!/bin/sh

echo "Testing required directories..."
echo ""

test_directory() {
    local dir=$1
    local name=$2

    if [ -d "$dir" ]; then
        success "$name exists"
    else
        warn "$name does not exist: $dir"
    fi
}

test_directory "$HOME/.dotfiles" "Dotfiles directory"
test_directory "$HOME/.oh-my-zsh" "Oh My Zsh"
test_directory "$HOME/workspace" "Workspace directory"
