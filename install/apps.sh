#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up applications..."

if command -v positron >/dev/null 2>&1; then
    extensions_file="$DOTFILES/config/vscode/extensions.txt"
    if [ -f "$extensions_file" ]; then
        log_info "Installing Positron extensions..."
        cat "$extensions_file" | xargs -L1 positron --install-extension
    else
        log_warn "Extensions file not found: $extensions_file"
    fi
else
    log_warn "Positron not found, skipping extension installation"
fi

if command -v Rscript >/dev/null 2>&1; then
    install_script="$DOTFILES/config/r/install_pkgs.R"
    if [ -f "$install_script" ]; then
        log_info "Installing R packages..."
        Rscript "$install_script"
    else
        log_warn "R install script not found: $install_script"
    fi
else
    log_warn "R not found, skipping R package installation"
fi

if command -v npm >/dev/null 2>&1; then
    packages_file="$DOTFILES/config/npm/global-packages.txt"
    if [ -f "$packages_file" ]; then
        log_info "Installing global npm packages..."
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            [ -z "$pkg" ] && continue
            npm install -g "$pkg"
        done < "$packages_file"
    else
        log_warn "npm packages file not found: $packages_file"
    fi
else
    log_warn "npm not found, skipping global npm packages"
fi

if command -v ast-grep >/dev/null 2>&1 && command -v tree-sitter >/dev/null 2>&1; then
    ast_grep_dir="$HOME/.config/ast-grep"
    if [ ! -f "$ast_grep_dir/r.dylib" ]; then
        log_info "Building ast-grep R grammar..."
        mkdir -p "$ast_grep_dir"
        tmp_dir=$(mktemp -d)
        git clone --depth 1 https://github.com/r-lib/tree-sitter-r.git "$tmp_dir/tree-sitter-r"
        tree-sitter build --output "$ast_grep_dir/r.dylib" "$tmp_dir/tree-sitter-r"
        rm -rf "$tmp_dir"
    else
        log_info "ast-grep R grammar already built"
    fi
else
    log_warn "ast-grep or tree-sitter not found, skipping R grammar build"
fi

log_info "Application setup complete!"
