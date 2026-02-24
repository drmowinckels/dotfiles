#!/bin/sh

set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

PLUGINS_CONF="$DOTFILES/config/claude/plugins.conf"
PLUGINS_CACHE="$HOME/.claude/plugins/marketplaces"

log_info "Setting up Claude Code plugins..."

if ! command -v claude >/dev/null 2>&1; then
    log_warn "Claude Code not installed, skipping plugin setup"
    log_info "Install Claude Code and run this script again to configure plugins"
    exit 0
fi

if [ ! -f "$PLUGINS_CONF" ]; then
    log_error "Plugin config not found: $PLUGINS_CONF"
    exit 1
fi

parse_section() {
    section=$1
    in_section=false
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            \#*|"") continue ;;
            \[*\])
                [ "$line" = "[$section]" ] && in_section=true || in_section=false
                ;;
            *)
                [ "$in_section" = true ] && echo "$line"
                ;;
        esac
    done < "$PLUGINS_CONF"
}

# Convert owner/repo to marketplace name (owner-repo format)
to_marketplace_name() {
    echo "$1" | tr '/' '-'
}

# Get all plugin names from a marketplace's cached manifest
get_marketplace_plugins() {
    marketplace_name=$1
    manifest="$PLUGINS_CACHE/$marketplace_name/.claude-plugin/marketplace.json"
    if [ -f "$manifest" ]; then
        grep -E '"name":' "$manifest" | tail -n +3 | sed 's/.*"name": *"\([^"]*\)".*/\1/'
    fi
}

# Process [install-all] - add marketplace and install all its plugins
log_info "Processing install-all marketplaces..."
parse_section "install-all" | while IFS= read -r source; do
    log_info "  Adding $source..."
    claude plugin marketplace add "$source" 2>/dev/null || true

    marketplace_name=$(to_marketplace_name "$source")
    plugins=$(get_marketplace_plugins "$marketplace_name")

    if [ -n "$plugins" ]; then
        echo "$plugins" | while IFS= read -r plugin; do
            log_info "    Installing $plugin@$marketplace_name..."
            claude plugin install "$plugin@$marketplace_name" 2>/dev/null || log_warn "Failed to install $plugin"
        done
    else
        log_warn "  Could not find plugins for $marketplace_name"
    fi
done

# Process [marketplaces] - just add, don't auto-install
log_info "Adding additional marketplaces..."
parse_section "marketplaces" | while IFS= read -r source; do
    log_info "  Adding $source..."
    claude plugin marketplace add "$source" 2>/dev/null || true
done

# Process [plugins] - install specific plugins
log_info "Installing individual plugins..."
parse_section "plugins" | while IFS= read -r plugin; do
    log_info "  Installing $plugin..."
    claude plugin install "$plugin" 2>/dev/null || log_warn "Failed to install $plugin"
done

log_info "Claude Code plugins configured!"
