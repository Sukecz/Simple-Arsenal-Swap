# Compatibility status

## Version 0.2.0 targets

| Client | Interface | Offline checks | Live test |
| --- | ---: | --- | --- |
| Classic Era | 11509 | Passed | User testing in progress |
| Classic Hardcore | 11509 | Passed | Not separately tested |
| TBC Classic Anniversary | 20506 | Passed | Not separately tested |
| Forever beta 1.60.1 (69913) | 16001 | Passed | Maintainer confirmed, 2026-09-19 |

### Forever evidence, checked 2026-09-19

The installed Windows `_classic_beta_` client's `.build.info` and `WowB.exe`
version both report `1.60.1.69913`. Forever uses the Camelot flavor; the added
`SimpleArsenalSwap_Camelot.toc` targets interface `16001` and game type `camelot`.
The existing Era/TBC TOCs, addon namespace, and per-character database are preserved.

Blizzard UI source mirrored at pinned commit
[`70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e` (1.60.1, build 69913)](https://github.com/Gethe/wow-ui-source/commit/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e)
provides the technical basis:

- [Item API documentation](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
  contains `C_Item.GetItemInfo`, `GetItemInfoInstant`, `GetItemCount`, and
  `EquipItemByName`. SAS now prefers these per function, retaining global fallbacks.
- [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
  still handles `type="macro"` / `macrotext` through `C_Macro.RunMacroText`, and
  reads `ActionButtonUseKeyDown` when no per-button override is set.

The maintainer confirmed live testing of this Forever update on 2026-09-19
and approved a full release. Individual character classes and weapon combinations
were not itemized in that confirmation; it does not extend the recorded test
coverage for Era, Hardcore, or TBC. Source inspection and deployment are separate
from the maintainer-reported live result.

Hardcore shares the Era client but still needs a normal non-dangerous UI and
binding check. Do not test combat behavior on a Hardcore character when a safer
Era character is available.

## Live regression checklist

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
11. Start binding capture, then enter combat: the capture overlay disappears,
    normal gameplay keys work, and any pending replacement cannot change bindings.
12. Change the game's key-down activation setting; each physical press still
    performs one action without requiring `/reload`.

For each client, repeat both directions for 1H+shield / 2H, 2H / 2H, dual-wield
pairs, and two sets sharing a main hand with different off hands. Wait for the
weapon-swap cooldown between presses and also test a press during the cooldown.
Record actual equipped slots, Blizzard errors, and the success overlay separately.

## Combat mechanism

The secure button contains one out-of-combat hardware-event bridge plus
precomputed `/equipslot [combat]` lines. Arsenal A is listed before Arsenal B.
In combat, lines for the already-equipped arsenal are no-ops and the first real
weapon change selects the opposite arsenal; Blizzard's weapon-swap cooldown is
expected to prevent the later reverse lines from undoing it.

That sequencing still needs broader live-client coverage. If repeated single-key
toggling is not reliable, capture the first Lua error, the exact item combination,
combat state, and whether the first or second press failed.

## Full-addon audit, 2026-09-19

Reviewed all runtime Lua modules, locales, both original TOCs, database handling,
secure actions, UI and input capture, tests, packaging, and CI/release workflows.

Fixed during the audit:

- Modern item API support and an accidental write to global `_` during cursor capture.
- `/sas status` used nonexistent `ACTIVE_A` / `ACTIVE_B` strings and otherwise
  printed an unexpanded `%s`; it now uses the configured arsenal names.
- Full-screen input capture could persist into combat; combat entry now cancels it
  and invalidates pending replacement confirmation. Name editing releases focus
  before capture starts.
- A main-hand-only A could mask the more specific main-hand/off-hand B match.
- The secure button copied the key-down preference only at creation. It now uses
  the secure template's current CVar value.
- Setting a new binding cleared and saved the old one before checking whether
  replacement succeeded. Replacement now preserves/restores bindings on failure.

Remaining limitations and useful next steps:

1. **Combat sequencing remains client-dependent.** The maintainer confirmed live
   testing of the Forever update. Both arsenals are present in one static
   macro; reliability depends on no-op equips and the weapon-swap cooldown. No
   event or timer equips items, and secure attributes/bindings remain unchanged
   during lockdown, but these facts alone do not prove correct game behavior.
2. **Item copies are matched by ID.** Combat macros cannot distinguish two copies
   with different enchants; the active-set check also uses IDs. A dual-wield setup
   requesting the same ID twice does not preflight the required count of two.
   Blizzard errors remain visible. Exact-copy selection/count checks would improve this.
3. **Empty off hand means leave unchanged.** Identical or overlapping arsenals can
   be ineffective toggles. Warn about those configurations rather than silently
   changing the meaning of an empty slot.
4. **Item availability is mostly checked on activation.** Compact tooltip status
   for equipped / in bags / missing would expose banked or missing items sooner.
5. **Uncached metadata is provisional.** Instant item information permits slot
   assignment, but a stored fallback name/icon is not hydrated later. Refreshing
   saved display metadata after item data arrives would improve rare cache misses.

Automated checks cover both item API shapes, cached/uncached cursor data, direct
combat equip rejection, secure-attribute deferral, input capture cancellation,
binding replacement failures, custom status strings, database validation, macro
construction, and identical load order across all three TOCs. UI/API mocks cannot
detect actual taint or protected-action behavior. The live result above is based
on the maintainer's confirmation, not an automated or agent-observed game test.
