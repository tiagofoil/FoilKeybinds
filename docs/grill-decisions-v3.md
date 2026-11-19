# Grill decisions v3: Keys tab redesign (layout B, columns)

Date: 2026-11-19. Input: `docs/keys-tab-redesign-handoff.md` (layout B, mockup `docs/mockups/keys-tab-B-columns.dc.html`).
Everything in the handoff "What layout B is" section holds, with the decisions below.

## Decisions

1. **Shapes: own textures.** Ship small white TGA files in `FoilKeybinds/Media/` (rounded box, mouse body, dashed line)
   and tint them in code with `SetVertexColor`. No game atlases for these shapes; square corners are not the target.
2. **Fixed board.** Remove pan, zoom and the Reset view button (`UI.lua:112-147`). The window Scale setting
   (`Settings.lua:111`) stays the way to make it bigger or smaller.
3. **Step reorder: hover buttons.** Hover a step row: move up, move down, remove. No drag.
4. **Picker and macro preview stay where they are today:** picker outside the window on the right, macro preview
   outside on the left. "Show macro" moves into the key panel of the top strip.
5. **Modifier dots on keycaps** replace today's 11 px slot icons (`UI.lua:212-215`). Four dots along the bottom for
   Shift, Ctrl, Alt, Alt+Shift, filled when the slot has a spell. Hover a key: tooltip lists all 5 slots.
6. **Mouseover toggle: checkbox with a label** in the column header (not an eye icon). Hidden for sequences.
7. **Cheat sheet: no change** in this round. It keeps using the shared `ns.LAYOUT` and `ns.KEY_ORDER`.
8. **Spell icon in a keycap: real game icon, square, trimmed** (standard tex coord trim, like action bars), centered in
   the rounded keycap. Keep `ns.SlotView` and `ns.SpellIcon`. Mockup letter squares are placeholders only.
9. **Sequence length stays at 9 steps** (`MAXSEQ`, `UI.lua:383`). Step rows 22 px high. If a full column still does not
   fit, the window grows taller (no scroll code).
10. **"Start over" footer: labelled checkboxes** "New target" and "Leave combat", then the seconds box. No icons.

## Settled facts (not user decisions)

- Window 960 x 640 is fine; the existing Scale setting covers small screens.
- TGA is the texture format: every WoW client loads it.
- Removing steps down to one turns the sequence back into a plain spell (existing behavior, `UI.lua:410`).

## Out of scope

- Drag and drop from a spellbook (mockup C).
- Cheat sheet restyle.
- Any release or publishing work.

Next step: `/to-spec docs/grill-decisions-v3.md`.
