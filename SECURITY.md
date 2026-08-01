# Security

## Threat model

StayAwake requests macOS admin privileges exactly once per toggle flip, for exactly one purpose: running `pmset -a disablesleep <0|1>`. That's the entire privileged surface area. Specifically:

- **No persistent privileged process.** Elevation happens via `osascript ... with administrator privileges` (Apple's standard Authorization Services prompt) for a single, hardcoded shell command, then the elevated context ends. There is no privileged daemon, no `SMJobBless` helper, nothing running as root in the background.
- **No user input reaches the privileged command.** `runPrivileged()` in `AwakeController.swift` is only ever called with the two literal strings `"pmset -a disablesleep 1"` and `"pmset -a disablesleep 0"` — never with anything constructed from external input. There is no command-injection surface today, by construction, not by sanitization.
- **No network access from the app itself.** The compiled app makes zero network calls. All network activity is confined to `install.sh` / `uninstall.sh` (one-time, at install/uninstall) fetching a release asset over HTTPS from `github.com`.
- **No telemetry, no analytics, no data collection of any kind.**
- **Not code-signed or notarized** (no Apple Developer Program membership yet — see the README's Security section for what that does and doesn't mean for you). This is disclosed, not hidden: verify the source yourself, or build from source instead of running the prebuilt release, if that matters for your use case.

## Install script trust

`install.sh` is fetched and piped to `bash`, the same pattern used by Homebrew, rustup, and most developer CLI installers. If you'd rather not trust that pattern blind:

```
curl -fsSL https://raw.githubusercontent.com/MSreeGaneshNaik/StayAwake/main/install.sh -o install.sh
less install.sh   # read it
bash install.sh
```

The script only ever touches `/Applications/StayAwake.app` and a `mktemp -d` temp directory it cleans up on exit — it does not modify shell profiles, does not install a launch agent itself (that's opt-in, via the app's own "Launch at Login" toggle, using `SMAppService`), and does not touch any file outside those two paths.

## Reporting a vulnerability

Open a [GitHub Security Advisory](https://github.com/MSreeGaneshNaik/StayAwake/security/advisories/new) on this repo, or open an issue if it's not sensitive. This is a small, single-maintainer project — please allow a reasonable window to respond before any public disclosure.
