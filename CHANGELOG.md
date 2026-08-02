# Changelog

All notable changes to Simple Arsenal Swap will be documented here.

## Unreleased

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
