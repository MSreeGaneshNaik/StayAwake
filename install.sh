#!/bin/bash
# Downloads the latest StayAwake release and installs it to /Applications.
#   curl -fsSL https://raw.githubusercontent.com/MSreeGaneshNaik/StayAwake/main/install.sh | bash
set -euo pipefail

OWNER="MSreeGaneshNaik"
REPO="StayAwake"
APP_DIR="/Applications/StayAwake.app"

echo "Fetching latest StayAwake release..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases/latest")
ZIP_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*\.zip"' | sed -E 's/.*"(https[^"]+)"/\1/')

if [ -z "$ZIP_URL" ]; then
    echo "error: could not find a .zip asset on the latest release" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading $ZIP_URL"
curl -fsSL -o "$TMP_DIR/StayAwake.app.zip" "$ZIP_URL"

echo "Installing to $APP_DIR"
if pgrep -f "StayAwake.app/Contents/MacOS/StayAwake" > /dev/null 2>&1; then
    osascript -e 'tell application "StayAwake" to quit' > /dev/null 2>&1 || true
    sleep 1
fi
rm -rf "$APP_DIR"
ditto -x -k "$TMP_DIR/StayAwake.app.zip" "/Applications"

# curl downloads aren't quarantined by Gatekeeper the way browser downloads are,
# but strip the flag defensively in case it ended up set anyway.
xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true

echo "Launching StayAwake..."
open "$APP_DIR"

echo "Done. Look for the ☕ icon in your menu bar."
