# Foil Keybinds v2: spec

Label: ready-for-agent
Source: docs/grill-decisions-v2.md (2026-11-18)

## Problem Statement

Foil Keybinds v1 works for Tiago's Warlock, but daily use shows gaps.

- After the player learns a spell, the cheat sheet and the main window show a "?" icon or keep the
  key faded. The setup looks broken even when the macro works.
- Heal items are swapped only on some events. When a better potion becomes usable at a level-up,
  nothing happens until the bags change. When a swap cannot write a macro, it fails silently. Items
  outside the Classic-era lists match only by name, and that fails while the item name is not
  loaded.
- Settings live in a second window. The player must close two windows, and the settings window is
  hard to reach.
- Apply always changes bars and keybinds. A player who places macros by hand, or who uses another
  bar addon, has no way to say "only write the macros". Apply also changes things without showing
  what it will change first.
- A slot can hold only one spell. Players who use `/castsequence` macros (for example a DoT
  rotation on one key) must write those macros by hand, outside the addon.

## Solution

- Icons and known state are correct right after a spell is learned. The addon loads spell data
  before it reads icons or names. A slot counts as known when any rank of that spell is known.
  Login repair never removes a spell only because its data is not loaded yet.
- A "Refresh items" button (and `/fkb items`) swaps heal items now and prints one chat line per
  change. Level-ups also trigger the swap. A swap that cannot write a macro says why in chat. The
  item lists cover this client's item IDs.
- One window with tabs: Keys | Settings. Closing the window closes both.
- A master switch "Manage bars and keybinds". OFF: Apply writes macros only. ON: Apply works as in
  v1. Before each Apply, a preview lists the exact changes, with OK and Cancel.
- Any slot can hold a cast sequence. The player adds spells one by one, orders them, and picks the
  reset rules. The canvas and cheat sheet show the first spell with a small count badge.

The addon stays extremely lightweight. It works only on game events and clicks. No OnUpdate loops,
no timers, no polling.

## User Stories

### Spell icons and known state

1. As a player, I want the cheat sheet to show the real icon of a spell I just learned, so that my setup does not look broken.
2. As a player, I want the main window to show the real icon of a spell I just learned, so that the canvas and key card are correct.
3. As a player, I want the main window to update while it is open when I learn a spell, so that I do not have to close and open it.
4. As a player, I want icons of future spells (not learned yet) to show their real icon, so that I can recognize them when I plan ahead.
5. As a player, I want a slot to stop being faded when I learn Rank 1 of a spell I picked as a future spell, so that the key shows it is ready.
6. As a player, I want a slot to count as known when I know any rank of its spell, so that the macro (which casts by name) and the canvas agree.
7. As a player, I want a spell imported from GrimorioSetup without an ID to get its ID when I learn it, so that it gets an icon and repair can track it.
8. As a player, I want login repair to leave a spell alone when its data is not loaded yet, so that a slow load never deletes a spell from my setup.
9. As a player, I want login repair to still remove a spell that is really gone, so that the macro does not error.
10. As a player, I want icon fixes to happen on game events only, so that the addon causes no lag.

### Heal items

11. As a player, I want a "Refresh items" button next to Apply on the Keys tab, so that I can swap to my best items now.
12. As a player, I want `/fkb items` to do the same as the button, so that I can use it from chat or a macro.
13. As a player, I want one chat line per change, for example `Q: Healing Potion -> Greater Healing Potion`, so that I know what changed.
14. As a player, I want a chat line that says the items are already up to date when nothing changed, so that I know the button worked.
15. As a player, I want the refresh to refuse to run in combat with a message, so that nothing breaks mid-fight.
16. As a player, I want items to swap when I level up, so that a potion that just became usable is used right away.
17. As a player, I want a chat message when a swap cannot write a macro because the macro is missing, so that I know to Apply again.
18. As a player, I want a chat message when a swap cannot write a macro because it would go over 255, so that I know which key to fix.
19. As a player, I want these warnings only once per key and reason per session from automatic swaps, so that bag changes do not spam my chat.
20. As a player, I want the button to always print the warnings, so that I see every problem when I ask.
21. As a player, I want healthstones, potions, bandages and bombs of this client matched by item ID, so that items work even when their name is not loaded and on non-English clients.
22. As a player, I want the name match to stay as a fallback, so that an item missing from the ID lists still works.

### One window with tabs

23. As a player, I want one window with Keys and Settings tabs at the top, so that everything is in one place.
24. As a player, I want closing the window to close both tabs, so that I close one thing, not two.
25. As a player, I want `/fkb config` to open the window on the Settings tab, so that I can reach settings from chat.
26. As a player, I want the gear in the title bar to switch to the Settings tab, so that I find settings where I expect them.
27. As a player, I want a right click on the addon compartment entry to open the window on the Settings tab, so that I can reach settings from the minimap.
28. As a player, I want a left click on the compartment entry to open the window on the Keys tab, so that the main use stays one click.
29. As a player, I want the Options > AddOns page to keep working, so that I can also change settings from the game's own options.
30. As a player, I want the cheat sheet to stay a separate floating frame, so that it stays on screen when I close the window.

### Master switch for bars and keybinds

31. As a player, I want a switch "Manage bars and keybinds", so that I decide if Apply may touch my bars and keybinds.
32. As a player with the switch OFF, I want Apply to write macros only, so that my bars and keybinds never change.
33. As a player with the switch OFF, I want the key card to tell me to drag the macro to a bar, so that I know the next step.
34. As a player with the switch OFF, I want item swap and login repair to keep my macros current, so that the macros still work.
35. As a player with the switch OFF, I want Apply to not touch bars or keybinds for keys I cleared since the last Apply, so that the switch means the same thing for every key.
36. As a new player, I want the switch OFF on a fresh install, so that the addon never changes my bars by surprise.
37. As Tiago, I want the switch ON for a character that already has applied keys, so that my current setup keeps working after the update.
38. As a player turning the switch OFF after an Apply, I want a popup with "Keep bars and keybinds as they are" and "Undo them", so that I choose what happens to what Apply already did.
39. As a player turning the switch ON, I want a popup that explains in plain words what Apply will do, so that I agree before anything changes.
40. As a player, I want the popup to say that Apply clears Shift/Alt/Ctrl bindings on edited keys, puts macros on bar slots, may bind a key to a free slot, and that Undo brings it all back, so that nothing is a surprise.
41. As a player, I want the switch always visible next to Apply with a clear ON/OFF state, so that I know what Apply will do before I click.
42. As a player, I want the same switch on the Settings tab and on the Options > AddOns page, so that I find it with the other settings.
43. As a player, I want the switch saved per character, so that each character can manage bars or not.
44. As a player copying a setup from another character, I want my own switch to stay as it is, so that a copy never turns on bar changes.

### Apply preview

45. As a player, I want a preview of the exact changes before each Apply, so that I can check them first.
46. As a player, I want each change on its own line, for example `Shift-Q: was Mount, now cleared`, so that I can read the list fast.
47. As a player, I want OK to run the changes and Cancel to change nothing, so that I stay in control.
48. As a player with the switch OFF, I want the preview to list only macro changes, so that it matches what Apply will do.
49. As a player, I want a message instead of a preview when there is nothing to change, so that I do not click OK on an empty list.
50. As a player, I want the preview to match exactly what Apply does, so that I can trust it.
51. As a player, I want the preview to close if combat starts, so that Apply never runs in combat.

### Cast sequences

52. As a player, I want any of the 5 slots (normal, Shift, Alt, Alt+Shift, Ctrl) to hold a cast sequence, so that I can put a rotation on any modifier.
53. As a player, I want to add spells to a slot one by one, each going to the end of the list, so that I build the sequence in order.
54. As a player, I want an x on each spell to remove it, so that I can fix a mistake.
55. As a player, I want left and right arrows on each spell to move it, so that I can change the order.
56. As a player, I want a slot with one spell to stay a plain spell slot, so that simple keys stay simple.
57. As a player, I want a "reset on new target" checkbox, ON by default, so that the sequence starts over on a new target.
58. As a player, I want a "reset when I leave combat" checkbox, ON by default, so that the sequence starts over after a fight.
59. As a player, I want an optional seconds box for the reset, so that the sequence starts over after a pause.
60. As a player, I want the reset options per sequence, so that each slot can work its own way.
61. As a player, I want no mouseover option on a sequence, so that the card shows only what works.
62. As a player, I want the canvas key to show the first spell's icon with a small number badge, so that I see it is a sequence and how long it is.
63. As a player, I want the cheat sheet to show the same icon and badge, so that both views agree.
64. As a player, I want to add spells I have not learned yet to a sequence, shown faded, so that I can plan ahead.
65. As a player, I want items and pet commands kept out of sequences, so that the picker offers only what a sequence can hold.
66. As a player, I want login repair to rename spells inside a sequence, so that a patch cannot break it.
67. As a player, I want login repair to drop removed spells from a sequence, so that the macro does not error.
68. As a player, I want the repair popup to say which spell in the sequence changed, so that I know what happened.
69. As a player, I want a clear message when a sequence makes the macro go over 255, so that I know to shorten it.
70. As a player, I want the used/255 counter to include the sequence, so that I see how close I am to the limit.
71. As a player, I want a key with a sequence and other slots to fire only one of them per press, so that a modifier press never runs two lines.
72. As a player, I want sequences copied when I copy a setup from another character, so that my alts get them too.

## Implementation Decisions

### Modules

- **Pure core** (no game API, tested). Gets: cast sequence slots in the macro builder and the fit
  step, a three-state repair contract with ID fill and sequence repair, the known-by-any-rank rule,
  the item change list for chat lines, and the master switch start state.
- **Game layer** (thin, hand-tested). Gets: spell data loading, a split Apply (plan, then run),
  the master switch checks in Apply, Undo and un-apply, the item refresh entry point and warnings,
  the level-up event, and the researched item IDs.
- **Main window** (key card, canvas, picker). Gets: tabs, the sequence editor on the key card, the
  count badge on the canvas, the master switch next to Apply, the Refresh items button, the drag
  hint, the preview popup, the switch popups, and event-driven refresh while shown.
- **Settings page.** Today it is built twice: in its own window and on the Options > AddOns canvas.
  The own window goes away; the page is built in the Settings tab and on the Options canvas. It
  gets the master switch.
- **Cheat sheet.** Gets: the count badge and the icon fixes. Stays a separate floating frame.

### Spell data and known state (item 1)

- Before the addon reads a spell's icon or name, the game layer checks if the spell data is cached.
  If not, it requests the load and shows the "?" for now. The spell load result event updates only
  the cells that show that spellID. The event is listened to only while a frame that needs it is
  shown.
- The future-spell list keeps What's Training's own icon and uses it when the game returns no
  texture yet.
- Known rule: a slot (or one spell inside a sequence) counts as known when the player knows any
  spell with the same name. The game layer supplies the set of learned names; the pure core
  decides.
- The main window listens to spell changes and the load result while shown, and refreshes. It
  stops listening when hidden.
- Repair lookup contract changes from "name or nil" to three answers per spellID: current name,
  removed, or not loaded yet. "Not loaded yet" leaves the slot as it is and adds no change. Only
  "removed" removes. The game layer must not report "removed" for a spell whose data it could not
  read.
- ID fill: a slot (or sequence spell) with a name but no spellID gets its ID from a second lookup
  (name to learned spellID). The fill is silent: it is not a repair the player must review, so it
  is not in the popup.

### Heal items (item 2)

- `/fkb items` and the Refresh items button on the Keys tab bottom bar (next to Apply) both call
  the item swap. Out of combat only, with the in-combat message.
- The pure core builds the change list from the old best items, the new best items and the applied
  setups: one entry per key and item slot whose item changed. The game layer prints one line per
  entry, in the form `Q: Healing Potion -> Greater Healing Potion`. With no entries, the button
  prints an "items up to date" line; automatic swaps print nothing.
- The level-up event joins the existing swap events (login, bag change, leaving combat).
- Swap warnings: missing macro, or new text over 255. Automatic swaps warn once per key and reason
  per session. The button and the slash command always warn.
- Item ID research: an agent finds the healthstone, healing potion, bandage and bomb item IDs for
  this client and adds them to the ranked ID lists, best first, checked against at least one
  primary source. The name lists stay as the fallback.

### One window with tabs (items 3 and 4)

- The main window gets a tab bar at the top: Keys | Settings. A later Guide tab (Group D) is not
  built now.
- `/fkb config` (and its aliases), the title-bar gear, and a right click on the compartment entry
  open the window on the Settings tab. `/fkb` and a left click open it on the Keys tab.
- The separate settings window and its open function are removed. The Options > AddOns canvas
  stays.

### Master switch (item 8)

- A per-character setting stored in the character's saved data, not in the account-wide settings.
  "Copy from" never copies it.
- Start state, decided once when the setting has no saved value: ON when the character has applied
  keys, OFF otherwise. The pure core owns this rule. The value is then saved.
- Switch OFF:
  - Apply writes and updates macros only. It never sets bindings and never places actions on bars.
  - The un-apply path for keys cleared since the last Apply follows the same rule: it deletes or
    restores the macro body only. Deleting a macro removes it from any bar button that holds it;
    the preview says so.
  - Item swap and login repair keep rewriting macro bodies, as today.
  - The key card shows a hint to drag the macro to a bar.
- Turning OFF after an Apply shows a popup: "Keep bars and keybinds as they are" or "Undo them".
  "Undo them" restores bindings and bar slots from the backup, keeps the macros as they are, and
  forgets the bar slot and binding parts of the backup and the applied snapshots. "Keep" changes
  nothing in game.
- Turning ON shows a popup that explains what Apply does: clears Shift/Alt/Ctrl bindings on edited
  keys, puts macros on bar slots, may bind a key to a free slot, Undo brings it back. Cancel leaves
  the switch OFF.
- The switch sits next to Apply on the Keys tab, with a clear ON/OFF look, and on the Settings page
  (so also on the Options canvas).

### Apply preview (item 8)

- Apply is split in the game layer into a plan step and a run step. The plan step reads game state
  and returns a list of actions; it writes nothing. The run step performs a list of actions. The
  preview shows the plan's list; OK builds the plan again and runs it. Preview and Apply come from
  the same code, so they cannot drift.
- One line per action: macro created, updated or deleted; binding cleared (with what it was);
  binding set; macro placed on a bar slot (with what the slot held).
- With the switch OFF, the plan holds macro actions only.
- An empty plan prints a "nothing to change" message and shows no preview.
- The preview closes on combat start. The run step keeps its own combat check.

### Cast sequences (item 5)

- Slot shape: a slot holds either one spell (v1 shape) or a sequence: an ordered list of spells
  (each with spellID, name, kind) plus reset options (new target, leave combat, optional seconds).
  New sequences start with both reset checkboxes ON and no seconds.
- A slot becomes a sequence when a second spell is added. When the player removes spells down to
  one, it goes back to a plain spell slot with mouseover OFF.
- Only spells go in a sequence: no items, no pet commands, no pet special ability.
- Macro text: one `/castsequence` line per sequence slot, with that slot's condition and its reset
  rule. When any slot holds a sequence, every clause on the key uses the exclusive conditions (as
  with items today), because a `/castsequence` line and a `/cast` line both run on one press.
- No mouseover in sequences. The 255 fit step keeps its order: compact form first, then drop
  mouseover from the other (non-sequence) slots. If still over, the result is blocked, and the error
  names the slot with the longest text (a sequence counts with its whole spell list).
- Repair walks sequence spells too. Renamed spells get the new name. Removed spells are dropped.
  One spell left turns the slot back into a plain spell slot; none left clears the slot. Each change
  in the list carries the spell's position in the sequence, so the popup can say which one.
- Key card: each slot lists its spells in order. Each spell has an x and left/right arrows. An add
  button appends a spell from the picker. The reset controls show only for a sequence. The
  mouseover switch hides for a sequence.
- Canvas and cheat sheet: the first spell's icon with a small badge showing the spell count. Each
  spell in a sequence fades on its own on the key card; the key icon fades when the first spell is
  not known.
- Copy from another character copies sequences with the rest of the setup.

## Testing Decisions

- One test seam, the same as v1: the pure core, run by the plain assert runner with a Lua 5.1
  interpreter (LuaJIT). Tests call the core with plain tables and check what comes out (macro text,
  length, error slot, change list, start state). They test behavior, not internal helpers.
- No new seam. The Apply plan step reads the game, so it is hand-tested in the game.
- Core cases to cover:
  - Sequence on each slot alone; sequence with other spell slots; sequence with an item slot;
    exclusive conditions whenever a sequence is present.
  - Reset rule: each checkbox alone, both, none, seconds alone, seconds with checkboxes.
  - Fit: a sequence that fits; one that fits only after compact form or mouseover trim on other
    slots; one still over (blocked, error names the sequence slot).
  - Repair: renamed and removed spell inside a sequence; sequence shrinking to one (plain slot) and
    to none (cleared); "not loaded yet" leaves the slot and adds no change; "removed" still
    removes; nil spellID filled by the name lookup, with no change entry.
  - Known rule: known by the same rank, by another rank, and not known.
  - Item change list: one entry per key and item slot that changed; no entry when nothing changed;
    keys without items ignored.
  - Master switch start state: no saved value with and without applied keys; a saved value wins.
- Prior art: the existing tests for the macro builder, the fit step, repair, item ranking, and
  settings merge. The v1 working macros are the reference for expected text.
- In-game checklist (game layer and UI):
  - Learn a new spell with the cheat sheet and the main window open: real icon, no fade.
  - Fresh install starts with the switch OFF; Tiago's Warlock starts with it ON.
  - Switch OFF: Apply writes macros only; clearing a key and applying again touches no binding.
  - Switch OFF after Apply: both popup choices; switch ON popup and Cancel.
  - Preview lines match what Apply did; Cancel changes nothing; empty plan message.
  - Refresh items: change lines, up-to-date line, missing-macro and over-255 warnings, level-up swap.
  - Tabs: every way to open each tab; closing closes both; Options canvas still works.
  - A sequence fires in order and resets on new target, leaving combat, and after the seconds.
  - Diagnostic for icon issues (replace Q with a real key):
    `/run local s=FoilKeybindsDB.applied["Q"].slots.normal local i=C_Spell.GetSpellInfo(s.name) print(s.spellID,C_Spell.IsSpellDataCached(s.spellID),C_Spell.GetSpellTexture(s.spellID),C_SpellBook.IsSpellKnown(s.spellID),i and i.spellID)`

## Out of Scope

- Group D: the Guide tab, class templates, spec and level. It gets its own grill.
- All publishing and release work. Publishing is on hold.
- Mouseover inside sequences.
- Items, pet commands and the pet special ability inside sequences.
- Ctrl+Shift, Ctrl+Alt and other three-key combos (same as v1).

## Further Notes

- Verify in game: the exact `/castsequence` syntax with conditions and `reset=` (target, combat,
  seconds), and whether one line can hold several `;`-separated sequences. The spec uses one line
  per sequence slot, so the single-line form is not needed.
- Verify in game: `#showtooltip` with no argument follows the current step of the sequence.
- Unverified cause of the "?" icon: What's Training strips rank numerals from names. If the
  spellbook name differs, `/cast <name>` never resolves. Check with the diagnostic line; fix only if
  it shows up.
- Unverified: bombs may fail the usable check without Engineering. Check while testing items.
- Lightweight rule: every new listener (spell load result, spell changes for the main window) is
  active only while its frame is shown. The level-up event is the only new always-on event.
