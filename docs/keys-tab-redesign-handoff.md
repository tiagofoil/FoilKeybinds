# Handoff: Keys tab redesign (layout B, columns)

Date: 2026-11-19. Status: decided on a direction, nothing built. Next step: `/grill-me` with this file.

## Why

Tiago tested cast sequences (v2, commit 7c82be0) and reported:

1. The green "+" that turns a slot into a cast sequence is too hard to see. Players need an obvious way to add a next spell.
2. Editing a finished sequence is hidden. Clicking the slot button of a sequence already opens the editor
   (`FoilKeybinds/UI.lua:296-300`), but nothing on screen says so, so he added a spell to reach it.
3. The mouse and the keyboard drawings need a better design.
4. He wants a modern, polished layout for the whole Keys tab.

## Decision

Layout **B, columns** was picked from three mockups (A side card, B columns, C spellbook with drag and drop).

- Mockup page (private to Tiago): https://claude.ai/artifact/1qU7hfeKCqv7XqG1q9L5PM
- Local copies, plain HTML (Design canvas format, open in a text editor):
  `docs/mockups/keys-tab-B-columns.dc.html` (chosen), `keys-tab-A-side-card.dc.html`, `keys-tab-C-spellbook.dc.html`.

**Icons in the mockups are placeholders** (colored squares with two letters). Tiago dislikes them. The addon must keep
using the real game icons it already shows (`ns.SlotView`, `FoilKeybinds/Game.lua:472`; `ns.SpellIcon`, `Game.lua:429`).
Judge icon look in game, not from the mockup.

## What layout B is

Window 960 x 640 (today 940 x 560, `UI.lua:6`). Title bar with Keys | Settings tabs, close button, no gear.

- **Top strip, full width:** the keyboard and mouse on a board (keys near WASD, same places as `LAYOUT`, `UI.lua:150`).
  At the right of the strip, a key panel: "Key 2", macro name, macro size meter (142/255), the two key toggles
  (Target enemy if none, Pet attacks), Show macro, and a legend for the modifier dots.
- **Keycaps:** rounded keycap look with a dark bottom edge, legend top left, big icon of the plain press in the middle,
  four small dots along the bottom for Shift, Ctrl, Alt, Alt+Shift (filled when that slot is used), a count badge on the
  icon when the plain press is a sequence. Movement keys (W A S D) stay green and not clickable. Selected key: brass ring.
- **Mouse:** drawn as a real mouse. Left and right buttons are grey and say GAME. M3 is the wheel, M4 and M5 are thumb
  buttons on the left side. Each bindable button shows its icon and a small dot when a modifier slot is used.
- **Bottom: 5 columns, one per modifier**, in this order: Normal, Shift, Ctrl, Alt, Alt+Shift (today the card order is
  `ns.SLOTS`, `Core.lua:6`, Alt+Shift first and Normal last; the display order can differ from the macro order).
  Each column:
  - header: modifier chip, key name, mouseover toggle (eye icon; hidden for sequences), clear button (trash);
  - the spell list top to bottom with step numbers (1 entry for a plain spell);
  - hover a step: move up, move down, remove;
  - a purple dashed **"+ Add spell"** button, always visible when the slot has a spell. One spell plus one added makes
    a cast sequence. Under a single spell a hint says "Two spells or more make a cast sequence.";
  - for a sequence, a footer "Start over" with three controls: new target (crosshair icon), leave combat (shield icon),
    seconds box;
  - empty column: one big dashed button "Choose a spell or item" that opens the picker.
- **No side panel for sequences any more**: the column is the editor. The `seqp` side panel (`UI.lua:383-466`) and the
  small "+" on each row (`UI.lua:337`) go away.
- **Bottom bar:** Cheat sheet on the left; on the right Bars & keybinds switch (toggle look), Refresh items, Copy from,
  Undo, Apply (green).
- C's drag and drop (spellbook on the left, drop a spell on "+") is a possible later step on top of B, not part of this.

## Code map (what the redesign touches)

All in `FoilKeybinds/UI.lua` (701 lines) unless noted:

- window and tabs: lines 5-31; gear: 33-48; bottom bar buttons: 50-80
- canvas view with pan and zoom: 112-147 (pan uses OnUpdate only while the mouse button is down)
- `LAYOUT` and the mouse frame: 150-165; key buttons and their slot icons: 184-238; `refreshKeys`: 241
- key card and its 5 rows: 273-363 (row "+" at 337, trash, mouseover check)
- macro preview side panel: 365; sequence side panel `seqp`: 383-466
- `card:Refresh`: 468; picker panel: 521, `picker:Open(slot, append)`: 558, `picker:Choose`: 609
- widgets: `ns.Panel`, `ns.Button`, `ns.IconFrame` in `FoilKeybinds/Theme.lua` (70, 94, 137); colors `T` at the top of Theme.lua
- the cheat sheet uses `ns.LAYOUT` and `ns.KEY_ORDER` (Cheat.lua), so the key list must stay shared
- locale strings in `FoilKeybinds/Locale.lua` (en and ptBR; a test checks ptBR keys exist in en with the same placeholders)

Core logic (macro text, sequences, repair) does not change. Tests: `luajit tests/run.lua` (79 pass at 7c82be0).

## Constraints that still hold

- Extremely lightweight: game events and clicks only. No idle OnUpdate, no timers, no polling.
- Code and comments in English. No em dash or en dash anywhere (code, comments, docs, commit messages).
- WoW frames have no border-radius. Rounded keycaps, the mouse body and dashed borders need textures (files in
  `FoilKeybinds/Media/`) or existing atlases. This is the main feasibility question.
- Publishing is on hold; no release work.

## Open questions for the grill

1. Rounded shapes and dashed borders: ship our own textures in Media, use game atlases, or accept square corners?
2. Keep pan and zoom on the board, or a fixed keyboard (B fits without pan)? The Reset view button depends on it.
3. Window size 960 x 640: fine with the existing scale setting?
4. Modifier dots on keycaps vs today's tiny icons (11 px, `UI.lua:212-215`)?
5. Step reorder: hover up/down buttons (mockup) or drag?
6. Where do the picker and the macro preview open now (today side panels right and left of the window)?
7. Mouseover toggle as an eye icon in the column header: clear enough, or keep a labelled checkbox?
8. Does the cheat sheet get the same keycap and mouse look?
