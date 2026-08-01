#!/bin/bash
# Downloads the latest StayAwake release and installs it to /Applications.
#   curl -fsSL https://raw.githubusercontent.com/MSreeGaneshNaik/StayAwake/main/install.sh | bash
set -euo pipefail

OWNER="MSreeGaneshNaik"
REPO="StayAwake"
APP_DIR="/Applications/StayAwake.app"

# GitHub's stable "latest release" redirect for a known asset name — avoids the
# api.github.com endpoint entirely, so it isn't subject to the unauthenticated
# REST API's 60-requests-per-hour-per-IP rate limit.
ZIP_URL="https://github.com/$OWNER/$REPO/releases/latest/download/StayAwake.app.zip"

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
