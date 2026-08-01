# StayAwake

A macOS menu bar toggle that keeps the Mac fully awake — including with the lid closed and no external display — while it's on, and returns to normal sleep behavior the moment it's off.

## Install

```
curl -fsSL https://raw.githubusercontent.com/OWNER/StayAwake/main/install.sh | bash
```

Downloads the latest release, installs it to `/Applications`, and launches it. Look for the ☕ icon in the menu bar. No Dock icon, no window.

The app isn't code-signed (no Apple Developer account yet), but a `curl`-based install doesn't get the browser "quarantine" flag that triggers Gatekeeper's unidentified-developer warning, and the installer strips it defensively regardless. If macOS still blocks it, right-click the app in `/Applications` → Open once.

## Use

- **Stay Awake** (menu item): toggles the Mac fully awake, lid included. Turning it on shows macOS's one-time admin-password prompt — that's unavoidable, since disabling lid-close sleep (`pmset disablesleep`) is a system-wide setting Apple gates behind admin rights. Turning it off reverts that setting and returns everything to normal. If the admin prompt is cancelled, the toggle stays "on" rather than lying about the state.
- **Launch at Login**: registers the app to start automatically.
- **Quit**: turns the toggle off first (if it was on) so the Mac is never left stuck awake, then exits.

If the app is force-quit or crashes while the toggle is on, the next launch silently detects and reverts the leftover system setting.

## Uninstall

```
curl -fsSL https://raw.githubusercontent.com/OWNER/StayAwake/main/uninstall.sh | bash
```

Quits the app, force-restores normal lid-close sleep regardless of the app's believed state, and removes it from `/Applications`.

## Build from source

```
swift build -c release
./package.sh .build/release/StayAwake
open .build/StayAwake.app
```

On this development machine specifically, SwiftPM's own manifest compilation is broken (a `PackageDescription` link error happens even for an empty `Package.swift` — a CommandLineTools install issue, unrelated to this project), so `./build.sh` (raw `swiftc`) is used instead of `swift build`. On a normal machine, `swift build -c release` should just work.

## Verification checklist

1. Run it, confirm the menu bar icon appears with no Dock icon.
2. Toggle "Stay Awake" on, confirm one admin prompt, close the lid on battery power, confirm the Mac stays awake.
3. Toggle off with the lid open, confirm normal idle/lid sleep resumes (`pmset -g` should show `disablesleep 0`).
4. Force-kill the app while the toggle is on, relaunch, confirm it silently resyncs `disablesleep` back to `0`.

## License

MIT — see [LICENSE](LICENSE).
