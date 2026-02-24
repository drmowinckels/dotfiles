#!/bin/zsh

DOTFILES_CHECK_CACHE="$HOME/.cache/dotfiles-update-check"
DOTFILES_CHECK_INTERVAL=43200  # 12 hours in seconds

_dotfiles_check_updates() {
    local cache_file="$DOTFILES_CHECK_CACHE/status"
    local last_check="$DOTFILES_CHECK_CACHE/last_check"

    mkdir -p "$DOTFILES_CHECK_CACHE"

    # Check if we have cached results to display
    if [[ -f "$cache_file" && -s "$cache_file" ]]; then
        echo "\n\033[33m⚠ Dotfiles updates available:\033[0m"
        cat "$cache_file"
        echo "Run \033[1m$DOTFILES/update.sh\033[0m to update\n"
        rm -f "$cache_file"
    fi

    # Check if enough time has passed since last check
    if [[ -f "$last_check" ]]; then
        local last=$(cat "$last_check")
        local now=$(date +%s)
        if (( now - last < DOTFILES_CHECK_INTERVAL )); then
            return
        fi
    fi

    # Run check in background
    (
        cd "$DOTFILES" || return
        local updates=""

        # Fetch dotfiles repo
        git fetch origin 2>/dev/null
        local local_head=$(git rev-parse HEAD 2>/dev/null)
        local remote_head=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

        if [[ -n "$local_head" && -n "$remote_head" && "$local_head" != "$remote_head" ]]; then
            local behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || git rev-list --count HEAD..origin/master 2>/dev/null)
            updates+="  • dotfiles ($behind commits behind)\n"
        fi

        # Check submodules
        while IFS= read -r submodule_path; do
            [[ -z "$submodule_path" ]] && continue
            if [[ -d "$DOTFILES/$submodule_path/.git" || -f "$DOTFILES/$submodule_path/.git" ]]; then
                cd "$DOTFILES/$submodule_path"
                git fetch origin 2>/dev/null
                local sub_local=$(git rev-parse HEAD 2>/dev/null)
                local sub_remote=$(git rev-parse origin/HEAD 2>/dev/null || git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
                if [[ -n "$sub_local" && -n "$sub_remote" && "$sub_local" != "$sub_remote" ]]; then
                    local sub_behind=$(git rev-list --count HEAD..origin/HEAD 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
                    updates+="  • $submodule_path ($sub_behind commits behind)\n"
                fi
                cd "$DOTFILES"
            fi
        done < <(git config --file .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}')

        # Write results
        echo "$updates" > "$cache_file"
        date +%s > "$last_check"
    ) &>/dev/null &!
}

_dotfiles_check_updates
