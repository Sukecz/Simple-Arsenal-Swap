# Compatibility status

## Version 0.1.0 targets

| Client | Interface | Offline checks | Live test |
| --- | ---: | --- | --- |
| Classic Era | 11509 | Passed | User testing in progress |
| Classic Hardcore | 11509 | Passed | Not separately tested |
| TBC Classic Anniversary | 20506 | Passed | Not separately tested |

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
6. Replacing an existing hotkey requires explicit confirmation and Cancel preserves both bindings.
7. Out-of-combat A/B switching works for every configured combination.
8. In-combat A/B switching works repeatedly from the bound key.
9. A missing item, full bags, casting, and combat lockdown fail visibly and safely.
10. The hotkey still works with the settings window closed.

## Combat mechanism

The secure button contains one out-of-combat hardware-event bridge plus
precomputed `/equipslot [combat]` lines. Arsenal A is listed before Arsenal B.
In combat, lines for the already-equipped arsenal are no-ops and the first real
weapon change selects the opposite arsenal; Blizzard's weapon-swap cooldown is
expected to prevent the later reverse lines from undoing it.

That sequencing still needs broader live-client coverage. If repeated single-key
toggling is not reliable, capture the first Lua error, the exact item combination,
combat state, and whether the first or second press failed.
