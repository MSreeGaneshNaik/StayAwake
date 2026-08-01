# Architecture

## The constraint that shapes everything

macOS does not have one sleep mechanism — it has two, enforced at different layers, and StayAwake has to defeat both to make good on a single toggle:

| | Idle sleep | Lid-close sleep |
|---|---|---|
| Trigger | No user activity for N minutes | Lid sensor reports closed |
| Enforced by | Power Management, per-process assertions honored | Lower-level, tied to the lid sensor and (on unpowered/no-external-display configs) thermal safety logic |
| Can a background process opt out? | Yes — `IOPMAssertionCreateWithName` (what `caffeinate` wraps) | No per-process API. The only lever is the system-wide `pmset -a disablesleep` flag |
| Privilege required | None | Admin (it's a global setting, not scoped to one app) |

This is why the toggle can't be "one clean API call." `AwakeController.turnOn()` runs a `caffeinate -dimsu` child process (idle sleep) and an admin-escalated `pmset -a disablesleep 1` (lid-close sleep) as one atomic unit — both succeed or neither does.

## State machine

`AwakeController` (`Sources/StayAwake/AwakeController.swift`) exposes exactly one piece of state: `isOn: Bool`. There is no intermediate state, no "idle-only" mode exposed to the UI — that's a deliberate simplification per product decision, not a technical limitation (see [Roadmap](../README.md#roadmap) if that ever needs to change).

```
                 turnOn()                      turnOff()
   ┌──────┐  ─────────────────►  ┌──────┐  ─────────────────►  ┌──────┐
   │ off  │                      │  on  │                      │ off  │
   └──────┘  ◄─────────────────  └──────┘  ◄─────────────────  └──────┘
              rollback on failure           refuse to flip on failure
```

**Invariant: `isOn` never lies.** Both `turnOn()` and `turnOff()` only mutate state after the privileged `pmset` call has been confirmed to succeed:

- `turnOn()`: starts `caffeinate` first (cheap, reversible), then requests the admin prompt. If the prompt is cancelled, it terminates the `caffeinate` process it just started and returns `false` — no half-on state.
- `turnOff()`: requests the admin prompt *before* touching anything else. If it's cancelled, `caffeinate` keeps running and `isOn` stays `true` — the toggle keeps showing "on" because the system genuinely still has lid-close sleep disabled. The alternative (flipping the UI to "off" regardless) was an actual bug caught during testing: it would silently desync the displayed state from `pmset`'s real value.

## Crash recovery

`caffeinate` dying (app killed, crash, `kill -9`) is self-healing — it's a child process, so its IOKit assertions release the moment it exits. `disablesleep 1` is not self-healing — it's a system-wide setting that persists across reboots until something sets it back to `0`.

`resyncAfterCrashIfNeeded()` runs once at every launch, before the toggle is touched: it reads `pmset -g`, and if it finds `disablesleep 1` left over from a session that never got to call `turnOff()`, it silently clears it. This is the only place the app touches system state without a user-initiated toggle action, and it only ever moves the setting toward "off," never "on."

The one gap this doesn't cover: the app being *deleted* while `disablesleep 1` is set (no next launch to run the resync). `uninstall.sh` closes that gap by force-running `pmset -a disablesleep 0` unconditionally, regardless of what state it believes the app was in.

## File map

```
Sources/StayAwake/
├── StayAwakeApp.swift       @main entry point, NSStatusItem + menu, wires UI to AwakeController
├── AwakeController.swift    the state machine above — the only file that shells out to caffeinate/pmset
├── LoginItemManager.swift   thin wrapper over SMAppService for the "Launch at Login" checkbox
└── StatusIconState.swift    off/on → menu bar glyph + tooltip text mapping

Packaging/
├── Info.plist               bundle metadata, LSUIElement=true (no Dock icon)
└── AppIcon.icns              placeholder ☕ icon, generated programmatically (see git history)

build.sh      swiftc-direct build (bypasses a local SwiftPM toolchain issue, see README)
package.sh    assembles Sources output + Packaging/ into StayAwake.app
install.sh    curl-based installer — fetches the latest release, unpacks to /Applications
uninstall.sh  quits the app, force-clears disablesleep, removes the app
```

No third-party dependencies. `Foundation`, `Cocoa`, and `ServiceManagement` only.

## Why a plain-text menu bar glyph, not an SF Symbol image

The first version used `NSImage(systemSymbolName:)`. If a symbol name doesn't resolve on a given OS build, `NSStatusItem`'s button renders with a `nil` image — not a crash, not an error, just a blank space that looks identical to "the app isn't running." `StatusIconState.menuBarGlyph` returns a plain string (`☕` / `☕●`) instead: it cannot fail to render, because there's no symbol lookup involved at all.
