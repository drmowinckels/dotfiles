#!/bin/bash

set -e  # Exit on error

echo "================================"
echo "Updating Dotfiles & System"
echo "================================"
echo ""

DOTFILES="$HOME/.dotfiles"

# Parse command line arguments
SKIP_BREW=false
SKIP_GIT=false
SKIP_SUBMODULES=false
SKIP_CLAUDE=false
ONLY_SUBMODULES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --skip-brew)
            SKIP_BREW=true
            shift
            ;;
        --skip-git)
            SKIP_GIT=true
            shift
            ;;
        --skip-submodules)
            SKIP_SUBMODULES=true
            shift
            ;;
        --skip-claude)
            SKIP_CLAUDE=true
            shift
            ;;
        --only-submodules)
            ONLY_SUBMODULES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-brew       Skip Homebrew updates"
            echo "  --skip-git        Skip git pull for dotfiles"
            echo "  --skip-submodules Skip submodule update checks"
            echo "  --skip-claude     Skip Claude Code plugin updates"
            echo "  --only-submodules Only check and update submodules"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
done

check_submodule_updates() {
    echo "Checking for submodule updates..."
    cd "$DOTFILES"
    git submodule init 2>/dev/null
    git submodule update --init 2>/dev/null

    SUBMODULE_UPDATES=""
    while IFS= read -r submodule_path; do
        [ -z "$submodule_path" ] && continue
        if [ -d "$DOTFILES/$submodule_path/.git" ] || [ -f "$DOTFILES/$submodule_path/.git" ]; then
            cd "$DOTFILES/$submodule_path"
            git fetch origin 2>/dev/null
            LOCAL=$(git rev-parse HEAD 2>/dev/null)
            REMOTE=$(git rev-parse origin/HEAD 2>/dev/null || git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
            if [ -n "$LOCAL" ] && [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
                BEHIND=$(git rev-list --count HEAD..origin/HEAD 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
                SUBMODULE_UPDATES="${SUBMODULE_UPDATES}\n  • $submodule_path ($BEHIND commits behind)"
            fi
            cd "$DOTFILES"
        fi
    done < <(git config --file .gitmodules --get-regexp path | awk '{print $2}')

    if [ -n "$SUBMODULE_UPDATES" ]; then
        echo "⚠ Submodule updates available:"
        echo -e "$SUBMODULE_UPDATES"
        echo ""
        read -p "Update submodules now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git submodule update --remote --merge
            echo "✓ Submodules updated"
        fi
    else
        echo "✓ All submodules up to date"
    fi
    echo ""
}

if [ "$ONLY_SUBMODULES" = true ]; then
    check_submodule_updates
    exit 0
fi

# Update dotfiles from git
if [ "$SKIP_GIT" = false ]; then
    echo "Updating dotfiles from git..."
    cd "$DOTFILES"
    
    # Check if there are uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "Warning: You have uncommitted changes in your dotfiles"
        echo "Stashing changes before pull..."
        git stash
        STASHED=true
    else
        STASHED=false
    fi
    
    git pull origin main || git pull origin master
    
    if [ "$STASHED" = true ]; then
        echo "Reapplying stashed changes..."
        git stash pop
    fi
    
    echo "✓ Dotfiles updated"
    echo ""

    if [ "$SKIP_SUBMODULES" = false ]; then
        check_submodule_updates
    else
        echo "Skipping submodule checks (--skip-submodules flag set)"
        echo ""
    fi
else
    echo "Skipping git pull (--skip-git flag set)"
    echo ""
fi

# Update Homebrew and packages
if [ "$SKIP_BREW" = false ]; then
    if command -v brew >/dev/null 2>&1; then
        echo "Updating Homebrew..."
        brew update
        echo ""
        
        echo "Upgrading Homebrew packages..."
        brew upgrade
        echo ""
        
        echo "Installing/updating packages from Brewfile..."
        brew bundle --file="$DOTFILES/config/Brewfile"
        echo ""
        
        echo "Cleaning up Homebrew..."
        brew cleanup
        
        # Optional: show packages not in Brewfile
        echo ""
        echo "Checking for packages not in Brewfile..."
        brew bundle cleanup --file="$DOTFILES/config/Brewfile" --force
        echo ""
        
        echo "✓ Homebrew updated"
        echo ""
    else
        echo "Homebrew not found, skipping brew updates"
        echo ""
    fi
else
    echo "Skipping Homebrew updates (--skip-brew flag set)"
    echo ""
fi

# Update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Updating Oh My Zsh..."
    cd "$HOME/.oh-my-zsh"
    git pull
    echo "✓ Oh My Zsh updated"
    echo ""
fi

# Update Oh My Zsh plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Updating zsh-autosuggestions..."
    cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    git pull
    echo "✓ zsh-autosuggestions updated"
    echo ""
fi

# Refresh symlinks (in case any changed)
echo "Refreshing symlinks..."
"$DOTFILES/install/symlinks.sh"
echo ""

# Update Positron extensions
if command -v positron >/dev/null 2>&1; then
    echo "Updating Positron extensions..."
    positron --update-extensions
    echo "✓ Positron extensions updated"
    echo ""
fi

# Update Claude Code plugins
if [ "$SKIP_CLAUDE" = false ]; then
    if command -v claude >/dev/null 2>&1; then
        echo "Updating Claude Code plugin marketplaces..."
        claude plugin marketplace update 2>/dev/null || true
        echo "✓ Claude Code plugins updated"
        echo ""
    else
        echo "Claude Code not found, skipping plugin updates"
        echo ""
    fi
else
    echo "Skipping Claude Code plugin updates (--skip-claude flag set)"
    echo ""
fi

# Update R packages (optional - can be slow)
read -p "Update R packages? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v Rscript >/dev/null 2>&1; then
        if [ -f "$DOTFILES/config/r/install_pkgs.R" ]; then
            echo "Updating R packages..."
            Rscript "$DOTFILES/config/r/install_pkgs.R"
            echo "✓ R packages updated"
            echo ""
        fi
    else
        echo "R not found, skipping R package updates"
        echo ""
    fi
fi

echo "================================"
echo "Update Complete!"
echo "================================"
echo ""
echo "Summary:"
echo "  • Dotfiles synced with git"
echo "  • Submodules checked for updates"
echo "  • Homebrew and packages updated"
echo "  • Oh My Zsh and plugins updated"
echo "  • Claude Code plugins updated"
echo "  • Symlinks refreshed"
echo ""
echo "You may want to:"
echo "  1. Run ./test.sh to validate your setup"
echo "  2. Restart your terminal to load changes"
echo "  3. Run 'brew doctor' if you see any issues"
echo ""
