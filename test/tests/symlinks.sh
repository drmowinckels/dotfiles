#!/bin/sh

echo "Testing symlinks..."
echo ""

test_symlink() {
    local link=$1
    local expected_target=$2
    local name=$3
    local allow_mackup=${4:-false}

    if [ ! -L "$link" ]; then
        error "$name: Symlink does not exist at $link"
    elif [ ! -e "$link" ]; then
        error "$name: Symlink exists but target is broken: $link"
    else
        local actual_target=$(readlink "$link")
        if [ "$actual_target" = "$expected_target" ]; then
            success "$name"
        elif [ "$allow_mackup" = true ] && echo "$actual_target" | grep -q "Mackup"; then
            success "$name (managed by Mackup)"
        else
            warn "$name: Points to $actual_target instead of $expected_target"
        fi
    fi
}

test_symlink "$HOME/.zshrc" "$HOME/.dotfiles/config/env/zshrc" "ZSH config" false
test_symlink "$HOME/.gitconfig" "$HOME/.dotfiles/config/git/config" "Git config" true
test_symlink "$HOME/.gitignore" "$HOME/.dotfiles/config/git/ignore" "Git ignore" false
test_symlink "$HOME/.mackup.cfg" "$HOME/.dotfiles/config/.mackup.cfg" "Mackup config" true
test_symlink "$HOME/.Rprofile" "$HOME/.dotfiles/config/r/profile" "R profile" true

if [ -e "$HOME/.ssh/config" ]; then
    test_symlink "$HOME/.ssh/config" "$HOME/.dotfiles/config/ssh/config" "SSH config" true
else
    warn "SSH config not found (may not be set up yet)"
fi

test_symlink "$HOME/.claude" "$HOME/.dotfiles/config/claude" "Claude Code config" false
test_symlink "$HOME/.config/opencode/opencode.json" "$HOME/.dotfiles/config/opencode/opencode.json" "OpenCode config" false
