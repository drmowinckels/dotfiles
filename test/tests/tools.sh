#!/bin/sh

echo "Testing optional tools..."
echo ""

test_command() {
    local cmd=$1
    local name=$2
    local required=$3

    if command -v "$cmd" >/dev/null 2>&1; then
        version=$($cmd --version 2>&1 | head -1)
        success "$name installed: $version"
    else
        if [ "$required" = "true" ]; then
            error "$name is not installed"
        else
            info "$name is not installed (optional)"
        fi
    fi
}

test_command "brew" "Homebrew" "true"
test_command "git" "Git" "true"
test_command "zsh" "Zsh" "true"
test_command "mackup" "Mackup" "false"
test_command "positron" "Positron" "false"
test_command "R" "R" "false"
