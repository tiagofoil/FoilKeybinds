# Wizard idea (input for the v5 grill)

Date: 2026-11-20. Tiago chose to build the wizard BEFORE the CurseForge and Wago release (beta held).

## Tiago's idea

- A wizard that guides a new player through the first setup and makes a first personal template.
- Multi-step, one key per meaning: "Select a key for crowd control, suggestion E", then "a key for your main single-target damage rotation, suggestion F", and so on.
- Generic QoL macros that improve the player experience: one button for food and potions; potions in combat, bandages out of combat; and so on.
- At the end the player has a good template: based on our guides, shaped by personal preference, guided by the meaning of each key, ready to use.

## What we already have (reuse)

- Guide data per class and spec (FoilKeybinds_Guides): priority list in rotation order, learn levels, templates per bracket.
- Preview, Use this layout, Undo, the Layouts menu and the auto-save before every replace (7c8a415).
- Item slots that pick the best item in the bags: POT, Healthstone, BOMB, BAND.
- Level-up line per bracket, cheat sheet, fit check per key (FitMacro, 255 characters).

## Open points found before the grill

1. Roles in the guide data: each spell needs a role tag (CC, main attack, AoE, interrupt, defense, heal, move, pet...). Data work for 9 classes and 27 specs.
2. One key has 5 slots: the wizard suggests the key AND the slot, or players fill only plain presses.
3. Fast path: "use all suggestions", plus Back and Skip.
4. Conflicts: a key already picked in the wizard, W/A/S/D, Space (jump).
5. Spells not learned yet: low-level players have empty roles; fill later (level-up line?).
6. When it opens: once on the first /fkb with no keys, then from a button; never again by itself.
7. Limits: about 18 macro slots per character, 255 characters per macro; combined item macros are long.
8. QoL macros are their own feature: heal button ([combat] potion; bandage), food and drink on one button (out of combat only), Healthstone then potion. Uses [combat] / [nocombat] conditions.
9. End: after Apply, show the cheat sheet so the player learns the keys.
10. Every new string in English and pt-BR.
