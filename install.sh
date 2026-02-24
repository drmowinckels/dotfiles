#!/bin/sh

set -e  # Exit on error

echo "================================"
echo "Setting up your Mac..."
echo "================================"
echo ""

DOTFILES="$HOME/.dotfiles"

# Make sure all install scripts are executable
chmod +x "$DOTFILES"/install/*.sh

# Run installation modules in order
echo "Step 1: Homebrew"
"$DOTFILES/install/homebrew.sh"
echo ""

echo "Step 2: Symlinks"
"$DOTFILES/install/symlinks.sh"
echo ""

echo "Step 3: Mackup"
"$DOTFILES/install/mackup.sh"
echo ""

echo "Step 4: Shell (Oh My Zsh)"
"$DOTFILES/install/shell.sh"
echo ""

echo "Step 5: Workspace repositories"
"$DOTFILES/install/workspace.sh"
echo ""

echo "Step 6: Applications (Positron, R, etc.)"
"$DOTFILES/install/apps.sh"
echo ""

echo "Step 7: Claude Code plugins"
"$DOTFILES/install/claude.sh"
echo ""

echo "================================"
echo "Installation complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Optionally run ./.macos to set macOS defaults"
echo ""
