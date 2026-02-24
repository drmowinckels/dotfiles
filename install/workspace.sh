#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

log_info "Setting up workspace..."

require_command git

workspace="$HOME/workspace"
mkdir -p "$workspace"

info_file="$DOTFILES/config/git/workspace"

if [ ! -f "$info_file" ]; then
    log_warn "No workspace file found at $info_file, skipping workspace setup"
    exit 0
fi

tail -n +2 "$info_file" | while IFS=$'\t' read -r folder_path remote_url; do
    [ -z "$folder_path" ] && continue

    dest_dir="${workspace}/${folder_path}"

    if [ -d "$dest_dir" ]; then
        log_info "Repository already exists: $dest_dir"
        continue
    fi

    mkdir -p "$(dirname "$dest_dir")"

    log_info "Cloning $remote_url to $dest_dir..."
    git clone "$remote_url" "$dest_dir"
done

log_info "Workspace setup complete!"
