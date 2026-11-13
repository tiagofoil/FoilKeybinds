# Foil Keybinds v1: spec

Label: ready-for-agent
Source: docs/grill-decisions.md (2026-11-13)

## Problem Statement

Setting up keybinds in WoW Forever is slow and fragile. A good layout puts every spell on the few keys near WASD, with Shift, Alt, Alt+Shift and Ctrl variants inside one macro per key. Building that by hand means writing macros under a 255-character limit, getting the conditionals right, clearing conflicting modifier bindings, and dragging each macro to the right bar slot. It took about 3 hours for one Warlock, and the player had to keep a reference page open on a second monitor. Doing it again for every character and class is not practical. When a patch renames or removes a spell, the macros break silently.

## Solution

Foil Keybinds is a public addon with an in-game canvas editor. The player sees the keys near WASD and the mouse. They click a key, see its 5 slots (normal, Shift, Alt, Alt+Shift, Ctrl), and pick a learned spell or a consumable for each slot. The addon writes one macro per key, puts it on the bar slot that key already presses, and clears the modifier bindings that would block it. On login it checks the macros once and repairs any spell that was renamed or removed, with a popup that lists what changed and can undo it. No checks run during play.

## User Stories

1. As a player, I want to open the editor with a slash command, so that I can reach it from chat.
2. As a player, I want a minimap / addon compartment button, so that I can find the editor without knowing the command.
3. As a player, I want to see a canvas with the keys near WASD (Q E R F G V T Z X C, 1 to 5, Space) and the mouse buttons, so that the layout looks like my hand.
4. As a player, I want to pan and zoom the canvas, so that I can see the whole layout or one key up close.
5. As a player, I want each key to show the icons of its 5 slots, so that I can read my whole setup at a glance.
6. As a player, I want to click a key and see a card with its 5 slots, so that I can edit that key.
7. As a player, I want to click a slot and see a list of the spells I have learned, so that I only pick spells I can cast.
8. As a player, I want to search the spell list by name, so that I can find a spell fast.
9. As a player, I want the picker to list consumables (healing potion, Healthstone, bomb, bandage), so that I can bind items too.
10. As a player, I want the addon to use the best item of a type in my bags, so that I do not edit macros when I get a better potion.
11. As a player, I want the best item to be picked again when I click Apply and on login, so that the macro stays current without constant checks.
12. As a player, I want the item swap to also happen out of combat after my bags change, so that a new Healthstone is used right away.
13. As a player, I want harmful spells to get mouseover casting automatically, so that I can DoT a pack without changing target.
14. As a player, I want helpful spells to get friendly mouseover automatically, so that I can heal a party member under the mouse.
15. As a player, I want an on/off switch for mouseover on each slot, so that I control which spells use it.
16. As a player, I want a "target enemy if none" switch per key, so that the key picks a target when I have none.
17. As a player, I want a "pet attacks" switch per key, so that my pet joins when I attack.
18. As a player, I want each card to show "used/255", so that I know how close the macro is to the limit.
19. As a player, I want the addon to drop mouseover from slots first when a macro is too long, so that my choice still fits.
20. As a player, I want a clear message when a choice still does not fit, so that I know why it was blocked.
21. As a player, I want one Apply button, so that all macros are created and placed in one click.
22. As a player, I want Apply to put each macro on the bar slot its key already presses, so that my existing bar layout and keys stay the same.
23. As a player, I want a warning when a key has no bar slot, and the macro placed on an empty slot of another bar with a message that says where, so that I still get a button with a cooldown.
24. As a player, I want the key bound straight to the macro when no empty slot exists, so that the key works anyway.
25. As a player, I want Apply to clear the Shift/Alt/Alt+Shift/Ctrl bindings on edited keys, so that the modifiers inside the macro work.
26. As a player, I want Apply to refuse to run in combat with a message, so that nothing breaks mid-fight.
27. As a player, I want an Undo that restores my previous bindings and macros, so that I can try the addon without risk.
28. As a player, I want my setup saved per character, so that each character has its own layout.
29. As a player, I want to copy the setup from another character of the same class, so that my alts start ready.
30. As a player, I want spells above my level shown faded in the picker or on the canvas when they are part of a setup, so that I can plan ahead.
31. As a player, I want the addon to check my macros once on login, so that a patch cannot break them silently.
32. As a player, I want a renamed spell to be updated to its new name automatically, so that the macro keeps working.
33. As a player, I want a removed spell to be taken out of its slot, so that the macro does not error.
34. As a player, I want a popup that lists every repair, so that I know what changed.
35. As a player, I want an Undo button on the repair popup, so that I can reverse a repair I do not agree with.
36. As a player, I want no popup when nothing changed, so that login stays quiet.
37. As a player, I want the UI in English or pt-BR based on my game language, so that I can read it.
38. As a player, I want a tooltip on every slot icon with the spell name and modifier, so that I can check a slot without opening it.
39. As a player, I want to drag a macro from the editor to any bar button by hand, so that I can place it where I want.
40. As the author (Tiago), I want my current Grimório Setup Warlock layout imported as my Warlock's first profile, so that I can retire the old addon without rebuilding.
41. As the author, I want the addon in a public MIT GitHub repo, so that others can fix bugs.
42. As the author, I want CurseForge and Wago to build from the GitHub repo, so that one push publishes to both.
43. As a player, I want the addon to do no work during normal play, so that it never causes lag.

## Implementation Decisions

- **Macro builder (pure core).** A module with no game API calls. Input: a key setup (5 slots, each with a spellID or item category, mouseover flag, spell kind harmful/helpful/other) plus the key toggles, resolved names, and best item ids. Output: macro text and its length, or an error. It owns:
  - Modifier conditions per slot. Order from most to least specific: Alt+Shift, Ctrl, Shift, Alt, normal. Normal is `nomod` only when other slots exist.
  - Mouseover: `[@mouseover,harm,nodead][]` for harmful, `[@mouseover,help,nodead][]` for helpful.
  - Extras: a target-enemy line (`/targetenemy [noharm][dead]`) and a pet-attack line (`/petattack [harm,nodead]`).
  - Items: written as `item:<id>` to keep the text short; with no item in the bags, the default item name of that category.
  - The 255 trim: when over, drop mouseover from slots (longest saving first) until it fits; if still over, return an error naming the slot.
  - `#showtooltip` first line.
- **Repair (pure core).** Input: stored setups (spellID + saved name per slot) and a lookup "spellID -> current name or nil". Output: the new setups and a change list (renamed, removed). The game layer supplies the lookup.
- **Item ranking (pure core).** Per category, an ordered best-first name list. Input: bag contents (name -> id) and a usable check. Output: best id per category. Same lists as GrimorioSetup (healthstones, healing potions, bandages, bombs).
- **Game layer (thin).** Reads learned spells from the spellbook, the bags, bindings, and bar slots. Writes macros, bindings, bar actions. Handles combat lockdown. Reuses the GrimorioSetup approach:
  - The bar slot is found from the key's base binding command (`ACTIONBUTTONn`, `MULTIACTIONBARxBUTTONn`), which works with EllesmereUI and other bar addons that keep native commands.
  - Empty slot search across all bars when the key has no slot, then direct `SetBindingMacro` as the last fallback.
  - Backup of bindings and macro bodies before the first Apply, for Undo.
  - Character macros (per character).
- **Saved data.** Per character: profile with keys -> slots (spellID or item category, mouseover flag), key toggles, the macro name per key, the backup, and the last repair change list for Undo. The account-wide store keeps an index of character profiles by class for "copy from".
- **Macro names.** One per key, prefixed so they are easy to find and never clash with the player's own macros.
- **Events.** Only `ADDON_LOADED`/`PLAYER_LOGIN` (repair + item pick), `BAG_UPDATE_DELAYED` and `PLAYER_REGEN_ENABLED` (out-of-combat item swap, only for macros that use items). No `OnUpdate` loops.
- **UI.** Canvas frame with pan and zoom, key buttons with slot icons, a key card with 5 slots, mouseover switches, extras switches and the length counter, a spell/item picker with search, Apply and Undo buttons, the repair popup. Opened by slash command and the addon compartment button. Strings in a locale table, English and pt-BR.
- **Migration.** A one-time import that reads the GrimorioSetup macro data and maps it into a Warlock profile, then tells the player to disable GrimorioSetup.
- **Client.** WoW Forever only. TOC Interface line taken from the current GrimorioSetup TOC.
- **Repo and publishing.** Public GitHub repo, MIT license. CurseForge and Wago packaging from the repo (packager metadata file + release tags).

## Testing Decisions

- One test seam: the pure core (macro builder, repair, item ranking). Tests call it with plain tables and check the returned text, length, error, or change list. They test behavior only (what text comes out for a given setup), not internal helpers.
- Key cases: every modifier combination; mouseover on/off; harmful vs helpful; extras on/off; item with and without bag stock; a setup that needs trimming; a setup that cannot fit; renamed spell; removed spell; no change (empty change list); best item order and the usable check.
- Tests run on the PC with a Lua 5.1 interpreter (WoW uses Lua 5.1). No interpreter is installed yet; setting one up is part of the first ticket.
- Prior art: none with tests. GrimorioSetup's macro text (C:\Projetos\wow-keybinds\addon) is the reference for expected output: real macros that already work in the game.
- The game layer and UI are tested by hand in the game with a short checklist: Apply, Undo, key without a slot, repair popup, item swap, copy from another character.

## Out of Scope

- Per-class starter setups for new players (v2).
- The AI cron job that checks the game version and spell changes (v2).
- Retail, Classic Era, or other clients.
- Keys outside the fixed set.
- Pet commands other than attack (follow, stay, move).
- Ctrl+Shift, Ctrl+Alt, and other three-key combos.
- Copying Icy Veins or other guide text into the addon.
- The YouTube video.

## Further Notes

- The name "Foil Keybinds" must be checked for clashes on CurseForge and Wago before the first release.
- Ctrl+key combos may have default game bindings. Apply clears them on edited keys, the same as Shift and Alt.
- The current page at C:\Projetos\wow-keybinds\index.html is the visual reference for the canvas.
