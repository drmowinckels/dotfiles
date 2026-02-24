#!/bin/sh

echo "Testing required files..."
echo ""

test_file() {
    local file=$1
    local name=$2
    local required=$3

    if [ -f "$file" ]; then
        success "$name exists"
    else
        if [ "$required" = "true" ]; then
            error "$name does not exist: $file"
        else
            warn "$name does not exist (optional): $file"
        fi
    fi
}

test_file "$HOME/.dotfiles/config/Brewfile" "Brewfile" "true"

echo ""
echo "Testing environment files..."
echo ""

for envfile in aliases.zsh exports.zsh functions.zsh path.zsh zshrc lazy.zsh; do
    test_file "$HOME/.dotfiles/config/env/$envfile" "env/$envfile" "true"
done
