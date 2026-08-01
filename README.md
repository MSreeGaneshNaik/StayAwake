# StayAwake

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/MSreeGaneshNaik/StayAwake)](https://github.com/MSreeGaneshNaik/StayAwake/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)](#requirements)
[![Swift](https://img.shields.io/badge/swift-5.9-orange)](Package.swift)

A menu bar toggle that keeps a Mac fully awake — lid closed, no external display, doesn't matter — for exactly as long as you need it, and hands the machine straight back to normal battery-saving sleep the instant you turn it off.

Built for one specific failure mode: you kick off a long build, test suite, or AI coding agent session, close the lid to walk away, and macOS kills it. StayAwake exists so that decision — stay running vs. go to sleep — is yours, not your lid's.

## Table of contents

- [Install](#install)
- [Requirements](#requirements)
- [Usage](#usage)
- [How it works](#how-it-works)
- [Security](#security)
- [Comparison](#comparison)
- [Uninstall](#uninstall)
- [Build from source](#build-from-source)
- [Verify it yourself](#verify-it-yourself)
- [Architecture](#architecture)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Install

```
curl -fsSL https://raw.githubusercontent.com/MSreeGaneshNaik/StayAwake/main/install.sh | bash
```

One command: downloads the latest release, installs it to `/Applications`, launches it. Look for the ☕ icon in the menu bar — no Dock icon, no window, no setup dialog.

Prefer not to pipe a script into `bash` sight unseen? Fair — see [Install script trust](SECURITY.md#install-script-trust) for how to inspect it first, or grab `StayAwake.app.zip` by hand from the [latest release](https://github.com/MSreeGaneshNaik/StayAwake/releases/latest) and drag it into `/Applications`.

## Requirements

macOS 13 (Ventura) or later. Apple Silicon or Intel. No dependencies, no runtime, no background daemon beyond the app itself while it's running.

## Usage

| Menu item | What it does |
|---|---|
| **Stay Awake** | The toggle. On: the Mac stays awake through idle timeouts *and* lid-close. Off: everything reverts to normal. Turning it on triggers macOS's one-time admin-password prompt (see [How it works](#how-it-works) for why that's unavoidable). If you cancel that prompt, the toggle stays exactly where it was — it never claims a state that isn't real. |
| **Launch at Login** | Registers StayAwake to start automatically, via `SMAppService` — no shell scripts, no `~/Library/LaunchAgents` file to manage by hand. |
| **Quit** | Turns the toggle off first (if it was on), *then* exits — the Mac is never left stuck awake because you quit the app. |

If StayAwake is force-quit or crashes while the toggle is on, the next launch silently detects and reverts the leftover system setting. You cannot end up with lid-close sleep permanently disabled by an app that's no longer running — as long as the app runs again at least once. (Deleting it entirely without running `uninstall.sh` is the one path around that — see [Uninstall](#uninstall).)

## How it works

macOS does not have a single sleep mechanism — it has two, and neither one is fully controllable from where the other lives:

- **Idle sleep** (display/system sleeps from inactivity, lid still open): preventable per-process, no privileges required, via IOKit power assertions. StayAwake shells out to Apple's own `caffeinate -dimsu` rather than reimplementing `IOPMAssertionCreateWithName` by hand — same mechanism, less surface area to get wrong.
- **Lid-close sleep**: enforced at a lower level tied to the lid sensor. No per-process assertion touches it. The only lever that works is the system-wide `pmset -a disablesleep 1` setting — undocumented by Apple but functional, and it requires one admin-privileged shell command, because it's a machine-wide setting, not an app-scoped one.

The toggle runs both together, as one atomic unit: turning on starts `caffeinate` and flips `disablesleep`; turning off reverses both. You never see or manage them as two separate switches. Full technical write-up, including the exact state-machine invariants and the crash-recovery design, is in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Security

- **Not code-signed or notarized.** No Apple Developer Program membership yet ($99/yr — see [Roadmap](#roadmap)). This means Gatekeeper would normally flag a *browser*-downloaded copy as from an "unidentified developer." The `curl`-based installer sidesteps that in practice — that quarantine flag is applied by browsers on download, not by a plain `curl` fetch — and defensively strips it either way. Full disclosure, not a workaround you need to trust blindly: read [SECURITY.md](SECURITY.md) for exactly what admin privileges the app requests and why.
- **One narrowly-scoped admin prompt, no persistent elevation.** The only privileged operation is `pmset -a disablesleep <0|1>`, requested fresh each time via macOS's standard Authorization Services prompt — no background daemon running as root, no stored credentials, no `SMJobBless` helper.
- **Zero telemetry, zero network calls from the running app.** All network activity is confined to the install/uninstall scripts fetching a release asset over HTTPS.

## Comparison

| | StayAwake | `caffeinate` (CLI) | [Amphetamine](https://apps.apple.com/app/amphetamine/id937984704) | [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) |
|---|---|---|---|---|
| Lid closed, no external display | ✅ | ❌ (idle sleep only) | ✅ (undocumented trick) | ❌ (by design — see its README) |
| One-click menu bar toggle | ✅ | ❌ (terminal only) | ✅ | ✅ |
| Open source | ✅ | (Apple, closed) | ❌ | ✅ |
| Dependencies | None | None | None | None |
| Price | Free | Free (built-in) | Free | Free |

## Uninstall

```
curl -fsSL https://raw.githubusercontent.com/MSreeGaneshNaik/StayAwake/main/uninstall.sh | bash
```

Quits the app if it's running, force-restores normal lid-close sleep *regardless* of what state the app believes it's in (cheap insurance against the one real edge case — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#crash-recovery)), then removes `/Applications/StayAwake.app`.

## Build from source

```
swift build -c release
./package.sh .build/release/StayAwake
open .build/StayAwake.app
```

`./build.sh` (raw `swiftc`) is a fallback for environments where SwiftPM's own manifest compilation is broken — a `PackageDescription` link error that happens even on an empty `Package.swift`, a CommandLineTools install issue unrelated to this project. On a normal machine, `swift build` just works.

## Verify it yourself

1. Run it, confirm the menu bar icon appears with no Dock icon.
2. Toggle **Stay Awake** on, confirm one admin prompt, close the lid on battery power, confirm the Mac stays awake.
3. Toggle off with the lid open, confirm normal idle/lid sleep resumes (`pmset -g` should show `disablesleep 0`).
4. Force-kill the app while the toggle is on, relaunch, confirm it silently resyncs `disablesleep` back to `0`.

## Architecture

```
Sources/StayAwake/
├── StayAwakeApp.swift       menu bar UI, wires the toggle to AwakeController
├── AwakeController.swift    the state machine — caffeinate + pmset, atomic on/off
├── LoginItemManager.swift   SMAppService wrapper for "Launch at Login"
└── StatusIconState.swift    off/on → menu bar glyph + tooltip
```

No third-party dependencies — `Foundation`, `Cocoa`, `ServiceManagement` only. Full design rationale, the state-machine invariants, and the crash-recovery guarantees: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Roadmap

Not built yet, tracked deliberately rather than half-implemented:

- **Code signing + notarization** — removes the Gatekeeper disclosure above entirely, and is a prerequisite for an official Homebrew cask (Homebrew now requires signed/notarized casks as of Sept 2026).
- **Windows** (`SetThreadExecutionState` + `powercfg` lid action) and **Linux** (`systemd-inhibit` + `logind.conf HandleLidSwitch=ignore`) — same two-mechanism design, ported.
- **Claude Code plugin hook** — auto-toggle for the duration of a coding-agent session (`SessionStart`/`Stop`), for people who want it automatic rather than manual.
- **Signed privileged helper** — removes the repeated admin prompt on every toggle-on, once there's a Developer ID to sign it with.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
