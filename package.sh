#!/bin/bash
# Assembles StayAwake.app from the built binary + Packaging/. Run build.sh (or
# `swift build -c release`) first.
set -euo pipefail
cd "$(dirname "$0")"

BINARY="${1:-.build/StayAwake}"
if [ ! -f "$BINARY" ]; then
    # Fall back to SwiftPM's release binary path if it exists (normal machines).
    if [ -f ".build/release/StayAwake" ]; then
        BINARY=".build/release/StayAwake"
    else
        echo "error: no built binary found at $BINARY (run build.sh or 'swift build -c release' first)" >&2
        exit 1
    fi
fi

APP=".build/StayAwake.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/StayAwake"
chmod +x "$APP/Contents/MacOS/StayAwake"
cp Packaging/Info.plist "$APP/Contents/Info.plist"
cp Packaging/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "Built $APP"
