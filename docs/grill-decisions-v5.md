# Grill decisions v5: the new-player Wizard

Date: 2026-11-20. Input: docs/wizard-idea.md. The store release waits for this feature (Tiago's choice).

## Core

1. **Model: move guide groups.** Each key of a guide layout gets one meaning (tag per layout key, not per spell). A step asks where the group goes ("Where do you want your crowd control? Suggestion: R"). The whole group moves to the clicked key. Spells stay as the tested guide has them.
2. **Place: in the main window.** A step bar over the keyboard canvas on the Keys tab: question, the meaning's one-line "why", the suggestion, Back, Skip, "Use all suggestions". The player clicks the key on the canvas. Reuses the board and the preview mode.
3. **Opens:** once by itself, on the first /fkb of a character with no keys. Then only from a "Build my layout" button on the Guide tab (next to "Preview layout") and `/fkb wizard`. Never again by itself.

## Steps

4. **Step 1: spec and range, preselected.** Class, the 3 specs with "yours" preselected (most talent points), the level range preselected. Same logic as the Guide tab. One click on Next.
5. **Meanings: one shared list** of about 10 for every class: main attack, second attack/DoT, AoE, crowd control, interrupt, defense, self heal, buffs, pet, items. Name and one-line "why" in English and pt-BR. A step shows only when the layout has a key with that meaning. Several keys with one meaning: one step each ("1 of 2").
6. **Conflict: swap.** Clicking a key that an earlier step took makes the two groups trade keys, with a short line ("Crowd control moved to E, items moved to R").
7. **Keys: same rules as guides.** Any canvas key, mouse buttons too. W, A, S, D blocked. Plain Space stays jump; Space only with Shift, Ctrl, Alt.
8. **Groups move whole** (all 5 slots). Single-slot changes happen later in the editor.
9. **Remember picks** per character (key per meaning). The level-up line points to `/fkb wizard`. Every step preselects the last key, so "Use all my picks" builds the new range on the player's keys.

## End

10. **Preview, Use, Apply.** The result shows in the preview banner (Use, Cancel). Use replaces all keys (old keys auto-saved in Layouts, Undo works), chat says press Apply. After that Apply, the cheat sheet opens once.
11. **Old keys: replace all**, same as "Use this layout".

## QoL macros

12. **Available everywhere:** new item choices in the slot picker (next to POT, BAND, HS), used by the wizard and the guide layouts.
13. **First version:**
    - Heal button: best health potion in combat, best bandage out of combat.
    - Eat and drink: best food and best water in one click, out of combat only.
    - Healthstone or potion: Healthstone when there is one, else a health potion.
14. **All 27 guide layouts switch** their items group: V = Healthstone or potion, Shift+V = Heal button, Alt+V = Eat and drink.
15. **In-game checks (Tiago, after the build):**
    - If "Healthstone or potion" uses both items in one click: drop it from v1.
    - If "Eat and drink" uses only one item: split it into Eat and Drink (two slots in the items group).

## Process

16. **Mockup in the spec:** one ASCII mockup of a step, built with the Guide/Keys look. No stop before the build.
17. Every new string in English and pt-BR. The 8 untested classes keep their "not tested" note in the wizard too.
