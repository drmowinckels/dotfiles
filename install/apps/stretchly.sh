#!/bin/bash
set -e

DOTFILES="$HOME/.dotfiles"
. "$DOTFILES/install/lib/utils.sh"

APP_NAME="Stretchly"
REPO="hovancik/stretchly"

if [ -d "/Applications/$APP_NAME.app" ]; then
    log_info "$APP_NAME already installed"
    exit 0
fi

log_info "Installing $APP_NAME from GitHub..."
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" \
    | jq -r '.assets[] | select(.name | endswith("mac.dmg")) | .browser_download_url')

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    log_error "Could not find $APP_NAME download URL"
    exit 1
fi

TMPDIR=$(mktemp -d)
curl -L -o "$TMPDIR/stretchly.dmg" "$DOWNLOAD_URL"
hdiutil attach "$TMPDIR/stretchly.dmg" -nobrowse -quiet
cp -R "/Volumes/$APP_NAME/$APP_NAME.app" /Applications/
hdiutil detach "/Volumes/$APP_NAME" -quiet
rm -rf "$TMPDIR"

xattr -cr "/Applications/$APP_NAME.app"
log_info "$APP_NAME installed"
