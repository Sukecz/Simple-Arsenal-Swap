# AGENTS.md

## Project identity

- Display name: Simple Arsenal Swap
- Addon folder and namespace: `SimpleArsenalSwap`
- Per-character SavedVariables: `SimpleArsenalSwapDB`
- Primary slash command: `/sas`
- Primary targets: current WoW Classic Era, Classic Hardcore, and TBC Classic
- Language: Lua 5.1 compatible with WoW Classic
- Dependencies: none

## Product scope

Simple Arsenal Swap is a focused two-way main-hand/off-hand equipment switcher.
The player configures arsenal A and arsenal B by dragging items into four slots,
binds one key, and uses that key to alternate between the two arsenals.

Supported items are one-handed weapons, main-hand weapons, two-handed weapons,
off-hand weapons, shields, and held-in-off-hand items. It is not a complete
equipment manager, action-bar manager, stance manager, or automatic gear system.

## Protected-action safety

- Every swap must originate from a hardware click or key press.
- Use one named `SecureActionButtonTemplate` for the hotkey action.
- Never change secure attributes or bindings during combat lockdown.
- Never automate swaps from events, timers, stance changes, health, buffs, or combat state.
- Keep combat macro text fully determined before combat begins.
- Do not hide Blizzard errors or claim that combat swapping is verified without a live-client test.
- Treat Classic Era/Hardcore and TBC behavior as separate live verification targets.

## Development workflow

- Inspect `git status` before editing.
- Keep user-visible behavior documented in README and CHANGELOG.
- Run `bash tests/run.sh` before committing.
- Do not push, tag, publish, or create a release unless explicitly requested.
- Do not add a CurseForge project ID until the real project exists.
- Generated packages must contain one top-level `SimpleArsenalSwap` directory.
- Shared deployment is maintained only in
  `/home/msminipc/projects/wow-addon-deployer`; do not restore a private
  `tools/windows` copy in this repository. After completing any code, data, or
  UI change and after this project's tests pass, automatically run
  `/home/msminipc/bin/deploy-wow-addons-pc`. The central registry synchronizes
  each registered addon only to its installed supported clients. Skip
  deployment for read-only analysis, failed tests, or when the user explicitly
  says not to deploy. If the PC is unavailable, keep the local changes and
  report the deployment failure. This narrow permission does not authorize a
  commit, push, tag, CurseForge upload, or any other publication, and the deploy
  must preserve SavedVariables.

## Style

- Four-space indentation and Lua 5.1-compatible syntax.
- Keep database validation, item/API compatibility, secure swapping, UI, and slash commands separate.
- Use one addon namespace and only the SavedVariables table, slash-command globals,
  binding label, and the secure `/run` bridge as intentional globals.
- No polling and no external libraries.
