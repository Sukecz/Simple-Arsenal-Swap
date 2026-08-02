# Simple Arsenal Swap

Simple Arsenal Swap is a small World of Warcraft Classic addon that alternates
between two configured weapon, shield, or off-hand combinations with one hotkey.

## Supported clients

- World of Warcraft Classic Era
- World of Warcraft Classic Hardcore
- Burning Crusade Classic Anniversary

The initial alpha targets interface `11509` for Era/Hardcore and `20506` for
TBC. Live-client verification is still required before these targets are
claimed as fully compatible.

## Usage

1. Type `/sas`.
2. Drag a main-hand weapon into both Arsenal A and Arsenal B.
3. Optionally drag a shield, off-hand weapon, or held item into either off-hand slot.
4. Click the Hotkey button and press the key or key combination to bind.
5. Press the hotkey to alternate between the two arsenals.

Right-click a configured item slot to clear it. A two-handed weapon automatically
clears and disables the matching off-hand slot. If the selected hotkey already
belongs to another action, the addon asks for confirmation before replacing it.
After the equipped items match the target arsenal, a green success message is
shown in Blizzard's scrolling combat-text area (or in the UI error-message area
when scrolling combat text is disabled or unavailable).

## Intended combinations

- one-handed weapon and shield to a two-handed weapon;
- one two-handed weapon to another two-handed weapon;
- dual-wield pair to another dual-wield pair;
- one-handed weapon and off-hand item to another combination;
- a main-hand-only switch that leaves the current off hand unchanged.

## Important limitations

- Every swap requires a physical hotkey press.
- Combat swaps are subject to Blizzard's weapon-swap cooldown and protected-action rules.
- Casting, loss of control, item locks, or insufficient bag space may prevent a swap.
- Configured items must be equipped or in the character's bags, not in the bank.
- Identical copies of the same item ID with different enchants may be ambiguous during combat.
- Combat A/B toggling must be verified in the live Era and TBC clients; offline tests cannot prove it.

The addon does not automatically react to combat, stances, abilities, health,
buffs, or equipment events. Those events are used only to refresh the display
and prepare the secure hotkey while outside combat.

## Commands

- `/sas` — open settings
- `/sas status` — report configuration and equipped arsenal state
- `/sas help` — show command help

## Development

Run the local validation suite with:

```bash
bash tests/run.sh
```

No external Lua libraries are required.

## Windows deployment

Keep these two files together on Windows and double-click the `.cmd` launcher:

- `tools/windows/Deploy-WoW-Addons.cmd`
- `tools/windows/Deploy-WoW-Addons.ps1`

The launcher uses the existing `ssh minipc` connection. It first runs the test
suite for Simple Scrolling Loot, Better Loot Rolls, and Simple Arsenal Swap on
MINIPC. If all tests pass, it stages and validates all three addons before
synchronizing their current runtime files into the Classic Era AddOns folder.
Unchanged files are left alone by Robocopy, and WoW SavedVariables are outside
the synchronized addon folders. The window closes automatically after a
successful run and stays open on an error so the failure message can be read.
