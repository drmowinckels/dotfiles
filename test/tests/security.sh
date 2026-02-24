#!/bin/sh

echo "Testing for common issues..."
echo ""

if git -C "$HOME/.dotfiles" grep -E "(ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59})" 2>/dev/null | grep -v ".env.example" >/dev/null; then
    error "Found potential GitHub token in tracked files"
else
    success "No exposed GitHub tokens found in tracked files"
fi

if git -C "$HOME/.dotfiles" check-ignore .env >/dev/null 2>&1; then
    success ".env is properly gitignored"
else
    warn ".env is not gitignored (may be tracked in git)"
fi

broken_links=$(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
if [ "$broken_links" -gt 0 ]; then
    warn "Found $broken_links broken symlink(s) in home directory"
fi
