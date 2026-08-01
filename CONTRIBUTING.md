# Contributing

## Build

```
swift build -c release      # normal machines
./build.sh                  # fallback: raw swiftc, for environments where SwiftPM's
                             # manifest compilation is broken (see README)
./package.sh                # assembles StayAwake.app
open .build/StayAwake.app
```

No external dependencies — `swift build` needs nothing beyond the Swift toolchain.

## Before opening a PR

Run through the [verification checklist](README.md#verify-it-yourself) by hand — there's no automated test suite yet (a menu-bar app whose entire job is manipulating system sleep state doesn't have a clean way to run those checks in CI). If you're changing `AwakeController.swift`, pay particular attention to the on/off atomicity invariant described in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#state-machine) — `isOn` must never report a state that doesn't match the real `pmset`/`caffeinate` state, including on every failure path.

## Code style

- No comments unless they explain a non-obvious *why* (a hidden constraint, a workaround, a decision that would surprise a reader). Don't restate what the code already says.
- No speculative abstraction. If a pattern repeats twice, that's fine; reach for a helper on the third repetition, not before.
- Match the existing file layout: one type per file in `Sources/StayAwake/`, named after the type.

## Reporting bugs / requesting features

Use the issue templates. For anything security-relevant, see [SECURITY.md](SECURITY.md) instead of a public issue.
