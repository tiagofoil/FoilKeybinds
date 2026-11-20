# Spec v5: the new-player Wizard and QoL item buttons

Source: docs/grill-decisions-v5.md (all recommended options, 2026-11-20). Input: docs/wizard-idea.md.

## Problem Statement

A new player opens Foil Keybinds and sees an empty keyboard. They do not know which spell goes on which key, which keys are easy to reach, or what the modifiers are for. The Guide tab gives a ready layout, but it is the guide's layout, not theirs: if they want crowd control on E instead of R, they must move every spell by hand. And the item keys are plain: one slot for a potion, one for a bandage, one for Healthstone, while a smart player uses one button that does the right thing in and out of combat.

## Solution

A wizard builds the first layout with the player, one meaning at a time. It starts from the guide layout of their spec and level range. Each step names one group of the layout by its meaning ("crowd control", "main attack", "items"), says why it matters in one line, suggests the guide's key and lets the player click another key on the keyboard canvas. The whole group moves there. At the end the result shows in the preview the player already knows: Use puts it on the keys (old keys auto-saved, Undo works), Apply puts it in the game, and the cheat sheet opens once so the player can learn the keys. The wizard remembers the picks, so at the next level range one click builds the new layout on the same keys.

Three new item buttons come with it, for every player, in the slot picker and in every guide layout: a Heal button (health potion in combat, bandage out of combat), Eat and drink (best food and best water in one click, out of combat) and Healthstone or potion.

## User Stories

1. As a new player, I want the wizard to open by itself the first time I type /fkb with no keys, so that I do not face an empty keyboard.
2. As a player, I want the wizard to open by itself only once per character, so that it never gets in my way later.
3. As a player, I want a "Build my layout" button on the Guide tab, so that I can run the wizard again.
4. As a player, I want `/fkb wizard` (and `/fkb assistente`), so that I can start it from chat.
5. As a player, I want the first step to show my class, my 3 specs with mine preselected and my level range preselected, so that I can start with one click.
6. As a player with no talent points, I want the guide's suggested leveling spec preselected, so that I still start with one click.
7. As a player, I want to change the spec or the range in the first step, so that I can build a layout for another spec or a later level.
8. As a player, I want one step per group of the layout, so that I decide one thing at a time.
9. As a player, I want each step to name the group's meaning (main attack, crowd control...), so that I know what the key is for.
10. As a player, I want a one-line "why" under the meaning, so that I learn why the guide put it on an easy key.
11. As a player, I want to see the group's spells (icons, with the game tooltip) in the step, so that I know what will move.
12. As a player, I want the guide's key preselected as the suggestion, so that Next accepts it.
13. As a player, I want to click any allowed key on the canvas to put the group there, so that the layout fits my hands.
14. As a player, I want the board to show the layout as it is now (with my picks so far), so that I see the result grow.
15. As a player, I want the group of the current step highlighted on the board, so that I see where it is.
16. As a player, I want W, A, S and D blocked, so that I cannot break my movement.
17. As a player, I want plain Space blocked for a group with a plain-press spell, so that Space still jumps.
18. As a player, I want mouse buttons allowed, so that I can use my mouse's side buttons.
19. As a player, when I click a key another group holds, I want the two groups to trade keys with a short line, so that there is no dead end.
20. As a player, I want a Back button, so that I can change an earlier pick.
21. As a player, I want a Skip button that leaves the group out of my layout, so that I can drop what I do not want.
22. As a player, I want "Use all suggestions" on every step, so that I can stop reading and take the rest as suggested.
23. As a player, I want steps in meaning order (main attack first, items last), so that the most important keys come first.
24. As a player, when two keys share a meaning, I want "1 of 2" in the step, so that I know there is another.
25. As a player, I want the wizard to show the step number ("Step 3 of 11"), so that I know how long it is.
26. As a player, I want the end of the wizard to be the preview banner with "Use this layout" and "Cancel", so that I check the result before anything changes.
27. As a player, I want Use to replace all my keys, so that the layout is clean.
28. As a player, I want my old keys auto-saved in Layouts before Use, so that I never lose them.
29. As a player, I want Undo after Use (and after Apply) to bring my old keys back, so that the wizard is safe to try.
30. As a player, I want a chat line after Use that says to check the keys and press Apply, so that I know the next step.
31. As a player, I want the cheat sheet to open once after the first Apply that follows a wizard Use, so that I can learn my new keys.
32. As a player, I want Cancel or closing the window to leave my keys as they were, so that the wizard changes nothing by itself.
33. As a player, I want my picks remembered per character and spec, so that the next run preselects my keys.
34. As a player who reached a new level range, I want the level-up line to point to /fkb wizard when I used the wizard, so that I know how to get the new layout.
35. As a player, I want "Use all my picks" when I ran the wizard before, so that the new range lands on my keys in one click.
36. As a player, I want a key that does not fit the macro limit left out and named in chat, same as Use on the Guide tab, so that nothing breaks.
37. As a player of a class whose guide is not tested yet, I want the same "not tested" note in the wizard, so that I know to report a wrong key.
38. As a player, I want every wizard text in English and pt-BR, so that I can read it.
39. As a player, I want a Heal button item: the best health potion in combat, the best bandage out of combat, so that one key heals me in both cases.
40. As a player, I want an Eat and drink item: the best food and the best water in one click, out of combat, so that I rest with one key.
41. As a player, I want a Healthstone or potion item: the Healthstone when I have one, else the best health potion, so that one key is my emergency heal.
42. As a player, I want the three new items in the slot picker next to the old ones, so that I can put them on any key.
43. As a player, I want the new items to follow my bags like the old ones (best item, refresh on bag change), so that they stay right.
44. As a player, I want the guide layouts to use the new items on V (V, Shift+V, Alt+V), so that the wizard and the Guide tab give me the good buttons.
45. As a player on a non-English client, I want the new items to match by item ID, so that they work in pt-BR.
46. As a player, I want the cheat sheet and the editor to show the new items with a clear label and icon, so that I know what the key does.

## Implementation Decisions

**Guide data: meanings.** Each spec in the guide package gets a `meanings` map: guide key -> meaning ID. One map per spec covers every template the spec uses, the shared 1-19 template included; so a key has the same meaning in every range of a spec (needed for remembered picks). The data test fails when a template key has no meaning or an unknown one.

**Meaning list (Core, shared by all classes), in step order:** `main` (main attack), `dot` (second attack, DoT or filler), `aoe`, `cc` (crowd control), `interrupt`, `defense`, `heal` (self heal), `buff`, `form` (forms, stances, stealth), `pet`, `utility`, `items`. Each has a name and a one-line "why" in English and pt-BR (Locale). Several keys with one meaning: one step each, board order inside the meaning.

**Wizard model (Core, pure):**
- Steps from a template and its meanings: ordered list of guide keys.
- A pick map: guide key -> chosen key. It starts from the remembered picks for that spec, else identity (the guide's key).
- Pick(map, guideKey, key): if another guide key holds that key, the two trade keys; returns what moved, for the chat line.
- Allowed(key, slots): false for W, A, S, D and for SPACE when the group has a plain-press slot; any other board key, mouse buttons included.
- Skip: the guide key maps to nothing (left out).
- Build(template, map): a new template with each group on its chosen key (skipped ones out). Then the existing TemplateKeys, FitKeys and the Use path take over, unchanged.

**Wizard flow (UI):**
- Step 1 is the Guide tab itself: its spec and range buttons are the picks, with "Build my layout" next to "Preview layout". The first /fkb of a character with no keys and no wizard flag opens the Guide tab with a one-line hint ("New here? Pick your spec and range, then Build my layout."). The flag is saved, so this happens once.
- "Build my layout" starts a preview of the wizard result (the existing preview mode, read-only for normal edits) plus a step bar on the Keys tab, over the canvas, in the space of the key card: step number, meaning name, the why line, the group's spell icons, the chosen key, and Back, Skip, Next, "Use all suggestions" (or "Use all my picks" when remembered picks exist).
- While the wizard runs, a click on a canvas key is a pick for the current step (not a key selection). A blocked key does nothing and the step bar shows why.
- The board highlights the current group's key.
- After the last step (or "Use all ..."), the step bar goes away and the normal preview banner stays: "Use this layout" and "Cancel". Use runs the same Use as the Guide tab (fit check, auto-save, Undo, chat line) and then saves the picks and sets a once-flag for the cheat sheet.
- Leaving the Keys tab, closing the window, or Cancel ends the wizard with nothing changed (same as preview today). Picks are saved only on Use.
- Apply: after a successful (not quiet) Apply with the cheat sheet once-flag set, the cheat sheet shows and the flag clears.
- Level-up line: when the used template came from the wizard, it names `/fkb wizard` instead of `/fkb guide`.

Mockup of a step (Keys tab, wizard running; the board above keeps its place):

```
+----------------------------------------------------------------+
| [ keyboard canvas: the layout so far, current group glowing ]  |
+----------------------------------------------------------------+
| Step 4 of 11                                  Crowd control 1/1 |
| Stops a mob for a while. Put it on a key you reach without     |
| looking.                                                       |
| [Fear] [Howl of Terror]           Key: R   (click a key above) |
| [Back]  [Skip]         [Use all suggestions]        [Next]     |
+----------------------------------------------------------------+
```

**QoL items (Core + Game + picker):**
- New item categories next to HS, POT, BAND, BOMB: `HEAL`, `EAT`, `HSPOT`. They are virtual: they have no rank list of their own.
- New ranked lists with item IDs (checked on wowhead.com/forever) and English fallback names: `FOOD` (plain food, no buff food) and `DRINK` (plain water, conjured water included). They are not offered in the picker on their own.
- Macro text: HEAL is one clause pair `[cond,combat] <best POT>; [cond] <best BAND>` inside the key's /use line. EAT adds `[cond,nocombat]` clauses for the best FOOD and the best DRINK; the drink goes on a second /use line, because one /use line uses one item. HSPOT resolves at bag-scan time to the best HS when the bags hold one, else the best POT (no double use in one click). With nothing in the bags, the English fallback names, same as today.
- The existing bag refresh (item swap on bag change, Refresh items button) covers the new categories through the same best-items table.
- Picker: the three new items listed after the old four, with a label ("Heal button: potion in combat, bandage out") and the icon of the item it would use now.
- Guide layouts: all 27 specs' items group becomes V = HSPOT, Shift+V = HEAL, Alt+V = EAT. The data test's fit check (230 with English names and no items) still passes.

**Saved per character (FoilKeybindsDB):** `wizard = { seen = true, picks = { [groupID] = { [guideKey] = key | false } }, cheatOnce = true|nil }`, and the used template record gets `wizard = true` when it came from the wizard.

**Locale:** every new string in English and pt-BR (pt-BR, never pt-PT).

**Lightness:** events and clicks only. No OnUpdate, no timers. The wizard builds nothing until "Build my layout".

## Testing Decisions

- A good test checks behavior through the highest seam: the pure Core functions (tests/run.lua) and the stubbed end-to-end world (tests/smoke.lua). No tests of private UI layout.
- run.lua (Core): meaning list and the data test for meanings (every template key has a known meaning, per spec); steps order; Pick with a swap; Allowed (W/A/S/D, Space with a plain press, mouse buttons); Skip; Build keeps every slot of a group; macro text for HEAL, EAT, HSPOT with and without modifiers and with nothing in the bags; HSPOT picks HS over POT; the new ranked lists hold IDs and names; all 9 guide classes pass the data test with the new items group.
- smoke.lua (end to end): first /fkb with no keys opens the Guide tab with the hint, once; Build my layout opens the step bar; a pick, a swap, Back, Skip; a blocked key does nothing; "Use all suggestions"; Use puts the built keys live, old keys auto-saved; Undo brings them back; picks saved only on Use; a second run preselects the picks; Cancel changes nothing; the cheat sheet once-flag after Apply.
- Prior art: the Guide tests in tests/run.lua (CheckGuide, TemplateKeys, FitKeys) and the Guide block in tests/smoke.lua.

## Out of Scope

- Per-spell role tags and picking single spells in the wizard (groups move whole; the editor changes single slots).
- Per-class meaning lists.
- Buff food, elixirs, flasks, mana potions, a Mana button.
- Workarounds if "Healthstone or potion" or "Eat and drink" misbehave in game (see Further Notes).
- Stance and bonus bar paging (same limit as today).
- The store release itself (after this feature, docs/publishing.md).

## Further Notes

- In-game checks after the build (Tiago): "Eat and drink" must use both items in one click; if it uses only one, split it into Eat and Drink (two slots in the items group). "Healthstone or potion" must use one item per click; with the bag-scan design it should, and if it does not, drop it from v1.
- The 8 classes other than Warlock stay `tested = false`; the wizard shows the same note.
- The mockup above is the only design pass; the build copies the Guide and Keys tab look (decision 16).
