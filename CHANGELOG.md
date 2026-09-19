# Changelog

All notable changes to Simple Arsenal Swap will be documented here.

## Unreleased

## 0.2.0 - 2026-09-19

### Added

- Support Forever beta 1.60.1 (69913) support with a Camelot TOC (interface 16001)
  and namespaced `C_Item` APIs with legacy fallbacks. Live testing was confirmed
  by the maintainer on 2026-09-19.
- Regression coverage for modern and legacy APIs, item-cache misses, combat
  lockdown, overlapping arsenals, hotkey failures, capture, and status messages.

### Fixed

- Keep cursor item capture from writing to the global underscore variable.
- Display correctly formatted custom arsenal names in `/sas status`.
- Release hotkey capture and pending replacement confirmation when combat starts,
  and release arsenal-name keyboard focus before capturing a hotkey.
- Prefer an explicit off-hand match over an overlapping main-hand-only arsenal.
- Follow the game's current key-down/key-up setting through the secure template.
- Preserve existing bindings when assigning a new hotkey fails and restore session
  bindings if removing an old hotkey fails; save only a successful replacement.
- Guard the direct equipment API against combat lockdown as well as its caller.

## 0.1.2 - 2026-08-11

### Added

- Allow middle and extra mouse buttons, the mouse wheel, and keyboard-modified
  mouse clicks anywhere on the screen as the swap hotkey while excluding primary
  left and right clicks.

## 0.1.1 - 2026-08-11

### Fixed

- Use a dedicated 256px TGA icon in the in-game AddOns list.

## 0.1.0 - 2026-08-02

### Added

- Initial stable project structure for Classic Era/Hardcore and TBC Classic.
- Two configurable main-hand/off-hand arsenals with drag-and-drop item capture.
- Two-handed weapon handling that clears and disables the matching off hand.
- One configurable WoW keybinding backed by a hidden secure action button.
- Out-of-combat state-aware A/B switching and a precomputed Classic combat macro path.
- Compact movable settings window and `/sas` commands.
- Lua 5.1, database, macro-generation, and TOC validation tests.
- Double-click Windows deployment tool using the existing `ssh minipc` workflow.
- Shared Windows deployment launcher that validates and updates Simple Scrolling Loot,
  Better Loot Rolls, and Simple Arsenal Swap in one run.
- Close the Windows deployment window automatically on success and keep it open on failure.
- Custom Simple Arsenal Swap logo as the in-game addon icon.
- Confirmation dialog before replacing a hotkey already used by another action.
- On-screen confirmation after the requested arsenal is successfully equipped.
- Large 32px swap confirmation near the scrolling combat-text area.
- Optional custom names for Arsenal A and B, also used in status and swap-success messages.
