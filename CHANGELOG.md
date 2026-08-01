# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [0.1.0] - 2026-08-01

### Added
- Single menu bar toggle ("Stay Awake") that prevents both idle sleep (`caffeinate -dimsu`) and lid-close sleep (`pmset -a disablesleep`) together, and reverts both together.
- Crash-safe resync: a leftover `disablesleep 1` from a killed/crashed session is silently cleared on next launch.
- "Launch at Login" toggle via `SMAppService`.
- `install.sh` / `uninstall.sh` for one-command setup and teardown.
- GitHub Actions release pipeline that builds and attaches `StayAwake.app.zip` on tagged pushes.

### Known limitations
- Unsigned, unnotarized (no Apple Developer account yet) — see [SECURITY.md](SECURITY.md).
- macOS only. Windows/Linux tracked in the [Roadmap](README.md#roadmap).
