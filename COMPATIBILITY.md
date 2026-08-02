# Compatibility status

## Current alpha targets

| Client | Interface | Offline checks | Live test |
| --- | ---: | --- | --- |
| Classic Era | 11509 | Pending initial run | Not tested |
| Classic Hardcore | 11509 | Pending initial run | Not tested |
| TBC Classic Anniversary | 20506 | Pending initial run | Not tested |

Hardcore shares the Era client but still needs a normal non-dangerous UI and
binding check. Do not test combat behavior on a Hardcore character when a safer
Era character is available.

## Required first live test

Record the output of:

```lua
/dump GetBuildInfo()
/dump WOW_PROJECT_ID
```

Then verify:

1. `/sas` opens without a Lua error.
2. Bag and equipped-item drag-and-drop both populate slots.
3. A two-handed main hand clears and disables its off-hand slot.
4. Right-click clears a slot without moving or deleting the real item.
5. A free hotkey persists after `/reload`.
6. Replacing an existing hotkey requires pressing the conflicting key twice.
7. Out-of-combat A/B switching works for every configured combination.
8. In-combat A/B switching works repeatedly from the bound key.
9. A missing item, full bags, casting, and combat lockdown fail visibly and safely.
10. The hotkey still works with the settings window closed.

## Unproven combat mechanism

The alpha secure button contains one out-of-combat hardware-event bridge plus
precomputed `/equipslot [combat]` lines. Arsenal A is listed before Arsenal B.
In combat, lines for the already-equipped arsenal are no-ops and the first real
weapon change selects the opposite arsenal; Blizzard's weapon-swap cooldown is
expected to prevent the later reverse lines from undoing it.

That sequencing is based on established Classic addon practice but remains an
explicit live-client verification gate. If repeated single-key toggling is not
reliable, do not publish the addon. Capture the first Lua error, the exact item
combination, combat state, and whether the first or second press failed.
