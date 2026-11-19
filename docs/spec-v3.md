# Foil Keybinds v3: Keys tab redesign (layout B, columns)

Label: ready-for-agent
Source: docs/grill-decisions-v3.md (2026-11-19), docs/keys-tab-redesign-handoff.md, mockup docs/mockups/keys-tab-B-columns.dc.html

## Problem Statement

Tiago tested cast sequences (v2) and found the Keys tab hard to use.

- The small green "+" that turns a slot into a cast sequence is hard to see. A player does not find the way to add a
  next spell.
- Editing a finished sequence is hidden. Clicking the slot button of a sequence opens the editor, but nothing on screen
  says so. Tiago added a spell only to reach the editor.
- The sequence editor is a side panel outside the window. The player must look in two places to edit one key.
- The keyboard and the mouse drawings look plain: square keys, a box for the mouse, tiny 11 px modifier icons.
- Pan and zoom on the board is extra work for a layout that fits on screen.
- The whole tab does not look modern or polished.

## Solution

A new Keys tab layout with the keyboard on top and one column per modifier below.

- **Top strip:** the keyboard and a real mouse drawing on a fixed board (no pan, no zoom). Keys look like rounded
  keycaps with the real spell icon of the plain press, and four small dots for the modifier slots. At the right of the
  strip, a key panel shows the selected key, the macro name, the macro size, the two key toggles and Show macro.
- **Bottom: five columns**, Normal, Shift, Ctrl, Alt, Alt+Shift. Each column is the full editor for that slot: the
  spell, or the steps of a cast sequence, with an always visible "+ Add spell" button. A sequence is edited in its
  column; the side panel for sequences goes away.
- **Bottom bar:** Cheat sheet on the left; Bars & keybinds switch, Refresh items, Copy from, Undo and Apply on the
  right.
- Shapes (rounded keycaps, mouse body, dashed borders) come from small white textures that the addon ships and tints.

## User Stories

1. As a player, I want the keyboard and the mouse on top of the Keys tab, so that I see all my keys at once.
2. As a player, I want the board to stay still, so that I never lose my keys by a wrong drag or wheel turn.
3. As a player, I want keys drawn as rounded keycaps, so that the board looks like a real keyboard.
4. As a player, I want each keycap to show the real game icon of its plain press, so that I know the key at a glance.
5. As a player, I want the icon trimmed like on the action bars, so that it looks clean inside the keycap.
6. As a player, I want four small dots at the bottom of a keycap for Shift, Ctrl, Alt and Alt+Shift, so that I see
   which modifier slots are used without clutter.
7. As a player, I want a filled dot for a used slot and an empty dot for a free slot, so that I can tell them apart.
8. As a player, I want a tooltip on a keycap that lists all five slots, so that I can read the spells without a click.
9. As a player, I want a count badge on the keycap icon when the plain press is a cast sequence, so that I know it
   holds more than one spell.
10. As a player, I want a faded, grey icon for a spell I have not learned yet, so that I know it does not work yet.
11. As a player, I want W, A, S and D shown in green and not clickable, so that I do not bind my movement keys.
12. As a player, I want the selected key marked with a brass ring, so that I know which key the columns edit.
13. As a player, I want the mouse drawn like a real mouse, so that I find M3, M4 and M5 fast.
14. As a player, I want the left and right mouse buttons grey with the word GAME, so that I know the addon leaves them
    to the game.
15. As a player, I want M3 on the wheel and M4, M5 on the left side as thumb buttons, so that the drawing matches my
    hand.
16. As a player, I want each bindable mouse button to show its icon and its modifier dots, so that it works like a key.
17. As a player, I want a key panel at the right of the top strip with the key name and the macro name, so that I know
    what I edit.
18. As a player, I want a macro size meter (for example 142/255), so that I see how close I am to the limit.
19. As a player, I want the "Target enemy if none" and "Pet attacks" toggles in the key panel, so that key options sit
    with the key.
20. As a player, I want a Show macro button in the key panel, so that I can open the macro preview.
21. As a player, I want a legend for the modifier dots in the key panel, so that a new player learns what the dots mean.
22. As a player, I want the "macro too long" and "mouseover trimmed" messages in the key panel, so that I see them next
    to the meter.
23. As a player, I want a hint in the key panel when no key is selected, so that I know to click a key first.
24. As a player, I want five columns below the board, one per modifier, so that I edit every slot of a key in one view.
25. As a player, I want the columns in the order Normal, Shift, Ctrl, Alt, Alt+Shift, so that the plain press comes
    first.
26. As a player, I want a column header with the modifier chip and the key name, so that I know which press it is.
27. As a player, I want a Mouseover checkbox with a label in the column header, so that I can turn mouseover on and
    off and know what the box does.
28. As a player, I want no Mouseover checkbox on a sequence column, so that I do not see an option that does nothing.
29. As a player, I want the Mouseover checkbox off and disabled for items and pet commands, so that I do not set a
    condition they ignore.
30. As a player, I want a trash button in the column header, so that I can clear the slot.
31. As a player, I want an empty column to show one big "Choose a spell or item" button, so that I know how to fill it.
32. As a player, I want that button to open the spell picker for that slot, so that I fill the slot in one click.
33. As a player, I want a slot with one spell to show that spell as step 1, so that a plain spell and a sequence look
    alike.
34. As a player, I want to click the spell in a column to change it in the picker, so that I can swap a spell.
35. As a player, I want a purple dashed "+ Add spell" button under the spell list whenever the slot has a spell, so
    that I always see how to add the next spell.
36. As a player, I want a hint under a single spell, "Two spells or more make a cast sequence.", so that I understand
    what "+ Add spell" does.
37. As a player, I want "+ Add spell" to open the picker and append the chosen spell at the end, so that my sequence
    grows in order.
38. As a player, I want a plain spell plus one added spell to become a cast sequence, so that I do not need a separate
    mode.
39. As a player, I want a new sequence to start over on a new target and on leaving combat by default, so that it works
    well without setup.
40. As a player, I want "+ Add spell" hidden when the sequence has 9 steps, so that I do not go past the limit.
41. As a player, I want step numbers next to each step, so that I see the cast order.
42. As a player, I want move up, move down and remove buttons when I hover a step, so that I can change the order
    without clutter.
43. As a player, I want move up disabled on the first step and move down disabled on the last step, so that I cannot
    click a button that does nothing.
44. As a player, I want a sequence with one step left to turn back into a plain spell, so that the key stays simple.
45. As a player, I want a plain spell that came from a sequence to have mouseover off, so that its macro does not
    change by surprise.
46. As a player, I want the "Start over" footer on a sequence column with "New target" and "Leave combat" checkboxes
    and a seconds box, so that I can set when the sequence restarts.
47. As a player, I want an empty or zero seconds box to mean "no time reset", so that I do not need a special value.
48. As a player, I want Escape in the seconds box to put back the saved value, so that I can cancel a typo.
49. As a player, I want every column edit to go through the same macro fit check as today, so that an edit that makes
    the macro too long is undone with a message.
50. As a player, I want all nine steps, "+ Add spell" and the footer to fit in a column, so that I never scroll.
51. As a player, I want the spell picker to open at the right side of the window as today, so that I find it where I
    know it.
52. As a player, I want the macro preview to open at the left side of the window as today, so that it does not cover
    the columns.
53. As a player, I want the window title bar with only the Keys | Settings tabs and the close button, so that there is
    one clear way to switch tabs.
54. As a player, I want the Cheat sheet button at the left of the bottom bar, so that it is easy to find.
55. As a player, I want the Bars & keybinds switch with a toggle look next to Apply, so that I see its state before I
    apply.
56. As a player, I want Refresh items, Copy from, Undo and Apply in the bottom bar as today, so that my habits still
    work.
57. As a player, I want the window Scale setting to make the new window bigger or smaller, so that it fits my screen.
58. As a player, I want the cheat sheet to keep working as today, so that the redesign does not break it.
59. As a player who plays in Brazilian Portuguese, I want every new label in ptBR, so that the tab is in my language.
60. As a player, I want icons for spells that load late to update in the keycaps and the columns, so that I never see a
    "?" icon after the data loads.
61. As a player, I want the tab to cost nothing while I play, so that the addon stays light.

## Implementation Decisions

### Window and layout

- Window grows from 940 x 560 to 960 x 640. If a full sequence column (9 steps, "+ Add spell", footer) does not fit,
  the window grows taller. No scroll frame in columns.
- Title bar keeps the Keys | Settings tabs and the close button. The gear button is removed.
- The Keys tab has three regions: top strip (board plus key panel), five columns, bottom bar.

### Board

- Pan, zoom and the Reset view button are removed. The board is placed once at a fixed scale. The mouse-drag OnUpdate
  goes away with pan.
- The shared key list (`LAYOUT` places and `KEY_ORDER`) stays the single source for both the board and the cheat sheet.
  Places may be retuned to fit the new strip, but the list stays shared and the cheat sheet must still render.
- Keycap: rounded box texture tinted with the key colors, a dark bottom edge, the key legend top left, the plain press
  icon in the middle, four modifier dots along the bottom, a count badge on the icon for a sequence.
- Dot order on the keycap: Shift, Ctrl, Alt, Alt+Shift. Filled dot = slot has a spell, item or pet command.
- The keycap tooltip lists all five slots in column order, with "not learned" lines as today. It replaces the per-icon
  tooltips of the old small icons.
- The icon is the real game texture from the existing slot view helper, with the standard trim, desaturated and faded
  when not known. No placeholder icons anywhere.
- Movement keys keep their green look and stay not clickable. Selected key: brass ring (the existing pulse may stay).
- Mouse: one mouse body texture. Left and right buttons drawn grey with a GAME label and not clickable. M3 sits on the
  wheel, M4 and M5 on the left side. Each bindable button shows its icon and dots like a keycap.
- The link line from the selected key to the old card is removed (the columns are always in the same place).

### Key panel (right of the top strip)

- Shows: "Key N", macro name, size meter (n/255), the two key toggles (Target enemy if none, Pet attacks), Show macro,
  the dot legend, the error or trim message, and the switch OFF hint (drag the macro by hand).
- No key selected: the panel shows the "pick a key" hint and the columns are hidden or empty.

### Columns

- Display order Normal, Shift, Ctrl, Alt, Alt+Shift. This is a new display order list; the macro clause order
  (`SLOTS` in Core) does not change.
- Header: modifier chip, key name, Mouseover checkbox with label (hidden for a sequence, disabled for items and pet
  commands), trash button (same clear path as the picker's Clear).
- Body: the steps top to bottom with step numbers, icon and name; one step for a plain spell, item or pet command.
  Clicking a step of a plain slot opens the picker to replace it.
- Step hover shows up, down, remove buttons. Hover is plain OnEnter and OnLeave, no polling.
- "+ Add spell": purple dashed button (dashed line texture), shown when the slot holds a spell (plain or sequence) and
  the sequence has fewer than 9 steps. Not shown for items and pet commands (same rule as today's "+").
- Hint under a single spell: "Two spells or more make a cast sequence."
- Footer for a sequence: "Start over" with "New target" and "Leave combat" checkboxes and the seconds box (numeric,
  3 digits, empty or 0 = none, Enter commits, Escape restores, focus loss commits).
- Empty column: one big dashed "Choose a spell or item" button that opens the picker for that slot.
- Step rows are 22 px high.

### Removed parts

- The sequence side panel and its row buttons.
- The small "+" button on each card row.
- The old key card with five rows.
- Pan, zoom, Reset view, gear, the key-to-card link line.

### Kept parts

- Picker: same panel, same place (right of the window), same `Open(slot, append)` entry point.
- Macro preview: same panel, same place (left of the window). It no longer shares that place with the sequence panel.
- The commit path: every edit runs the macro fit check, undoes on failure with the "too long" message, and trims
  mouseover with the "trimmed" message.
- Bottom bar buttons and their behavior. The Bars & keybinds switch gets a toggle look; its behavior does not change.
- Late spell data refresh: the hooks that refresh icons when spell data loads now update keycaps and column steps.

### Sequence edits move to Core (the one test seam)

The edit rules that now live in UI click handlers move into small pure Core functions. The UI calls them and then runs
the usual commit. Proposed shape (names may change, behavior may not):

- `AddStep(slot, entry)` returns the new slot value. Plain spell plus entry gives a sequence of two with reset target
  and combat on. A sequence gets the entry appended. At 9 steps the slot is returned unchanged. Items and pet commands
  are returned unchanged.
- `MoveStep(slot, i, delta)` swaps step i with step i + delta when both exist; otherwise unchanged.
- `RemoveStep(slot, i)` removes step i; with one step left it returns the plain spell form (`Unseq`, mouseover off).
- `MAXSEQ` (9) moves to Core so UI and tests share it.
- A display order list for the columns lives in Core next to `SLOTS`.
- The functions copy their input, so the caller keeps the old value for undo.

### Textures

- New files in the Media folder: a white rounded box (keycaps, column cards, buttons), a mouse body, a dashed line or
  dashed box. TGA format. Tinted in code with vertex color.
- Rounded boxes must keep round corners at any size: use the client's texture slice margins when the client has them;
  confirm this on WoW Forever before relying on it, else ship fixed-size variants.
- No game atlases for these shapes.

### Locale

- New strings in en and ptBR: "+ Add spell", the two-spells hint, "Choose a spell or item", "Start over", "New target",
  "Leave combat", "GAME", the dot legend, the keycap tooltip lines. Strings that lose their last user are removed.

### Constraints

- No idle OnUpdate, no timers, no polling. Events and clicks only.
- Code and comments in English. No em dash or en dash in code, comments, docs or commit messages.

## Testing Decisions

- A good test checks behavior through a public function: given a slot value, the result value. It never checks frames,
  sizes or private locals.
- One seam: the Core sequence edit functions, tested in `tests/run.lua` (plain assert runner, `luajit tests/run.lua`).
  Prior art: the repair tests that check `Unseq` and sequence handling, and the "new spell slot" tests for `NewSlot`.
- Cases to cover:
  - add to a plain spell gives a two-step sequence with reset target and combat on;
  - add to a sequence appends at the end;
  - add at 9 steps leaves the slot unchanged;
  - add to an item or a pet command leaves it unchanged;
  - move up and move down swap neighbors; move past either end leaves the slot unchanged;
  - remove a middle step keeps the order of the rest;
  - remove down to one step gives a plain spell with mouseover off;
  - the input slot is not changed (undo needs the old value);
  - the column display order lists all five slots once, Normal first.
- Existing tests must still pass (79 at 7c82be0), including the ptBR locale key check for the new strings.
- In-game check (by Tiago, no automation): board fits without pan; keycaps round at every size, SPACE included; dots
  match slots; tooltip lists five slots; mouse buttons placed right and GAME buttons not clickable; a 9-step sequence
  fits; up, down, remove, add, clear, mouseover, Start over all work and undo on a too-long macro; picker and preview
  open in their old places; cheat sheet still renders; Scale setting resizes the window; ptBR labels fit.

## Out of Scope

- Drag and drop from a spellbook (mockup C). Possible later on top of this layout.
- Drag to reorder steps.
- Cheat sheet restyle (it keeps its current look).
- Moving the picker or the macro preview inside the window.
- Any change to macro text, sequence macro output, repair, items or Apply.
- Release and publishing work.

## Further Notes

- The mockup icons are placeholders. Judge the icon look in game only.
- The main feasibility risk is the rounded textures on WoW Forever (slice margins). Check it first, in the first ticket.
- Existing saved data does not change shape: a sequence slot is still `{ seq = {...}, reset = {...} }`.
