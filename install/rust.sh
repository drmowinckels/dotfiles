#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up Rust toolchain..."

if ! command -v rustup >/dev/null 2>&1; then
  log_info "Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --default-toolchain stable --no-modify-path --component rustfmt --component clippy
  . "$HOME/.cargo/env"
else
  log_info "rustup already installed"
  rustup self update || log_warn "rustup self update skipped"
  rustup update stable
  rustup component add rustfmt clippy 2>/dev/null || true
fi

log_info "Rust toolchain setup complete!"
