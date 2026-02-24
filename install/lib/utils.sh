#!/bin/sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo "${RED}[ERROR]${NC} $1" >&2; }

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command not found: $1"
        exit 1
    fi
}

safe_symlink() {
    local source=$1
    local target=$2

    if [ ! -e "$source" ]; then
        log_error "Source does not exist: $source"
        return 1
    fi

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        log_warn "Backing up existing $target"
        mv "$target" "${target}.backup"
    fi

    ln -s "$source" "$target"
    log_info "Created symlink: $target -> $source"
}
