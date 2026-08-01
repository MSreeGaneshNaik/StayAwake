## What and why

<!-- What does this change, and what problem does it solve? -->

## Checklist

- [ ] Ran the relevant steps of the [verification checklist](../README.md#verify-it-yourself) by hand
- [ ] If this touches `AwakeController.swift`: confirmed `isOn` still can't desync from the real `pmset`/`caffeinate` state on any failure path (see [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#state-machine))
- [ ] Updated `CHANGELOG.md`
