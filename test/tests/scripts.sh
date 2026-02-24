#!/bin/sh

echo "Testing installation scripts..."
echo ""

for script in homebrew.sh shell.sh symlinks.sh mackup.sh workspace.sh apps.sh; do
    if [ -f "$HOME/.dotfiles/install/$script" ]; then
        if [ -x "$HOME/.dotfiles/install/$script" ]; then
            success "install/$script is executable"
        else
            error "install/$script exists but is not executable"
        fi
    else
        error "install/$script does not exist"
    fi
done
