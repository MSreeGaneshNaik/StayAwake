#!/bin/bash
# Uninstalls StayAwake and force-clears the lid-close-sleep override, regardless
# of whether the app thinks it's on or off — cheap insurance against the one
# real failure mode: deleting the app while its toggle is on would otherwise
# leave `disablesleep` stuck at 1 forever, since the app's own crash-resync
# check only runs on its next launch (which never happens once it's gone).
set -euo pipefail

APP_DIR="/Applications/StayAwake.app"

if pgrep -f "StayAwake.app/Contents/MacOS/StayAwake" > /dev/null 2>&1; then
    echo "Quitting StayAwake..."
    osascript -e 'tell application "StayAwake" to quit' > /dev/null 2>&1 || true
    sleep 1
fi

echo "Restoring normal lid-close sleep behavior (one admin prompt)..."
osascript -e 'do shell script "pmset -a disablesleep 0" with administrator privileges' > /dev/null

if [ -d "$APP_DIR" ]; then
    echo "Removing $APP_DIR"
    rm -rf "$APP_DIR"
fi

echo "Done. If you had enabled Launch at Login, it's now a dangling entry macOS will silently ignore — nothing to clean up by hand."
