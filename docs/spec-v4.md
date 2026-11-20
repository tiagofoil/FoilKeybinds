# Foil Keybinds v4: Guide tab and class templates (Group D)

Label: ready-for-agent
Source: docs/grill-decisions-v4.md (2026-11-20). In the grill Tiago picked "mockups first". Afterwards he asked
to run spec, tickets and build without stops unless strictly necessary, so the mockup step was skipped to keep the
flow moving. The Guide tab design below follows the Keys tab look (layout B, docs/mockups/keys-tab-B-columns.dc.html):
same colors, fonts, panels and buttons (Theme.lua widgets). Mockups can still come later if the tab misses.

## Problem Statement

A new player opens Foil Keybinds and sees an empty keyboard. They must know which spells matter for their
class and spec, and where to put them, before the addon helps at all. Tiago wanted from the start (2026-11-18):
"a class guide tab where the player chooses their spec and sees a guide of the main abilities and their
objectives in the rotation" and "ready-made templates for each class, each spec, at each level". The store
release (CurseForge, Wago) waits for this.

## Solution

A third tab in the main window: Keys | Guide | Settings.

- The Guide tab shows the player's class and its 3 specs (talent groups). The spec with the most talent points
  is preselected and marked "yours". The player can pick another one. With no points spent (below level 10),
  the class's suggested leveling spec is preselected.
- For the chosen spec, a priority list: the main abilities in rotation order. Each row has the spell icon, the
  spell name, one short line on what it is for, and the key it is on in the player's current layout (for example
  "Shift+Q"), or "not on a key". A spell the player cannot have yet shows the level it is learned at.
- Three bracket buttons, 1-19, 20-39, 40-60, with the player's current bracket preselected. Each bracket has a
  ready-made layout (template).
- "Preview layout" switches to the Keys tab and shows the template on the board and the columns, read-only, with
  a banner: "Preview: Affliction, levels 20-39" and two buttons, "Use this layout" and "Cancel". "Use this
  layout" replaces all keys. Undo takes it all back in one click. Nothing reaches the game until Apply.
- After a player used a template, the first time they level into a new bracket one chat line tells them a new
  layout is ready and how to open it (`/fkb guide`).
- Classes that Tiago did not test in game show a short note at the bottom of the Guide tab: written from
  guides, not tested in game yet, and where to report a wrong key (the GitHub issues page).
- All guide text exists in English and pt-BR.
- The guide data lives in a second addon folder, FoilKeybinds_Guides, in the same download. It is load on
  demand: the game loads it the first time the Guide tab opens. A player who never opens the Guide tab pays
  nothing for it.

## User Stories

1. As a player, I want a Guide tab next to Keys and Settings, so that the guide is one click away.
2. As a player, I want `/fkb guide` to open the window on the Guide tab, so that I can reach it from chat.
3. As a player, I want the Guide tab to show my class, so that I know the guide is for me.
4. As a player, I want the Guide tab to list the 3 specs of my class by their game names, so that I recognize them.
5. As a player, I want the spec where I put most talent points preselected, so that I do not have to pick it.
6. As a player, I want that spec marked "yours", so that I know why it was picked.
7. As a player, I want to pick another spec, so that I can read about a spec I plan to play.
8. As a player below level 10, I want the class's suggested leveling spec preselected, so that I get a useful
   guide before I have talent points.
9. As a player, I want the spec I picked kept while the window stays open, so that switching tabs does not lose it.
10. As a player, I want a priority list of the main abilities of the spec, in rotation order, so that I know what
    to press first.
11. As a player, I want each row to show the spell icon and name, so that I find it in my spellbook and on my keys.
12. As a player, I want one short line on what each ability is for, so that I understand its job in the rotation.
13. As a player, I want each row to show the key it is on in my layout, for example "Shift+Q", so that I connect
    the guide to my keys.
14. As a player, I want "not on a key" for an ability I have not placed, so that I see what is missing.
15. As a player, I want an ability I cannot have yet to show the level it comes at, so that I know it is coming.
16. As a player, I want a tooltip on the icon with the real game tooltip of the spell, so that I can read details.
17. As a player, I want three bracket buttons (1-19, 20-39, 40-60), so that I can pick a layout for a level range.
18. As a player, I want my current bracket preselected, so that the right layout is the default.
19. As a player, I want a "Preview layout" button, so that I can see the template before I change anything.
20. As a player, I want the preview on the Keys tab board and columns, so that I see it the same way I see my keys.
21. As a player, I want a clear banner during the preview with the spec and the bracket, so that I know I am not
    looking at my own keys.
22. As a player, I want the preview read-only, so that I cannot edit a template by mistake.
23. As a player, I want "Cancel" in the banner, so that I go back to my own keys with no change.
24. As a player, I want "Use this layout" in the banner, so that the template becomes my keys.
25. As a player, I want "Use this layout" to replace all my keys, so that I get the layout as the guide meant it.
26. As a player, I want Undo to bring back all my old keys in one click after "Use this layout", so that I can
    change my mind.
27. As a player, I want nothing in the game to change until I click Apply, so that using a template is safe.
28. As a player, I want a chat line after "Use this layout" that says to check the keys and press Apply, so that I
    know the next step.
29. As a player, I want template spells I have not learned yet to show faded on the keys, as today, so that I see
    they do not work yet.
30. As a player, I want template spells in my own game language, so that the macros work on my client.
31. As a player, I want the item slots of a template (potion, Healthstone, bandage, bomb) to use the best item in
    my bags, as today, so that the template works with what I carry.
32. As a player, I want every template macro to fit in 255 characters, so that "Use this layout" never fails.
33. As a player, I want a template to use at most 16 keys, so that it fits in my character's macro slots.
34. As a player, I want templates never to put a spell on W, A, S, D, so that my movement keys stay free.
35. As a player, I want templates to leave the plain Space press to the game, so that Space still jumps.
36. As a player who used a template, I want one chat line when I level into a new bracket, so that I know a new
    layout is ready.
37. As a player, I want that line only once per bracket, so that it does not spam me.
38. As a player who never used a template, I want no level-up line, so that the addon stays quiet.
39. As a player, I want the level-up line to name the spec, the new bracket and `/fkb guide`, so that I know what
    to do.
40. As a player of a class Tiago did not test, I want a short note that the guide is not tested in game yet, so
    that I trust it the right amount.
41. As a player, I want the note to say where to report a wrong key, so that I can help fix it.
42. As a pt-BR player, I want the guide text and the tab in pt-BR, so that I read it in my language.
43. As a player, I want the addon to stay light, so that the guide data loads only when I open the Guide tab.
44. As a player who never opens the Guide tab, I want no extra memory or load time, so that the guide costs me
    nothing.
45. As a player, I want the Guide tab to say so when the guide data is missing or disabled, so that I know why it
    is empty.
46. As a player, I want the Guide tab to work for all 9 classes, so that every character gets a guide.
47. As a player, I want the Guide tab to look like the rest of the window, so that it feels like one addon.
48. As Tiago, I want to check the Warlock guide in game before the release, so that at least my class is proven.
49. As a maintainer, I want the guide data checked by tests (structure, keys, fit, levels, both languages), so that
    a bad template never ships.
50. As a maintainer, I want the guide text in our own words, so that we do not copy other sites.

## Implementation Decisions

### Specs on WoW Forever (fact, from the installed EllesmereUI LibSpecialization)

- Forever has the vanilla talent trees, but the API shows them as one talent tree per class with 3 groups. A
  group is what players call a spec ("Affliction"). The retail spec ID is the same for every spec of a class, so
  it is useless here.
- Reading the points: active config from `C_ClassTalents.GetActiveConfigID()`, its first tree from
  `C_Traits.GetConfigInfo(config).treeIDs[1]`, the groups from `C_Traits.GetGroupDisplayInfoByTreeID(tree)`
  (each has `groupID`, `displayName`, an order), points spent per group from
  `C_Traits.GetGroupCurrencyInfo(config, { groupID })[1].currencyInfos[1].spent`. Every step can return nil;
  then the guess falls back to the suggested leveling spec.
- Forever group IDs (from that library's table): Mage 11582 Arcane, 11594 Fire, 11601 Frost. Druid 11328
  Balance, 11347 Feral Combat, 11340 Restoration. Hunter 11372 Beast Mastery, 11371 Marksmanship, 11370
  Survival. Paladin 11486 Holy, 11541 Protection, 11559 Retribution. Priest 11608 Discipline, 11615 Holy, 11622
  Shadow Magic. Rogue 11580 Assassination, 11573 Combat, 11572 Subtlety. Shaman 11326 Elemental Combat, 11363
  Enhancement, 11362 Restoration. Warlock 11629 Affliction, 11636 Demonology, 11637 Destruction. Warrior 11650
  Arms, 11657 Fury, 11670 Protection.
- Guide data is keyed by these group IDs. The spec name on screen is the game's `displayName` (already in the
  client language); the data carries an English name as a fallback.

### Guide data package

- A second addon folder, FoilKeybinds_Guides, next to FoilKeybinds in the repo and in the download. Its TOC has
  the same Interface line as the main addon, LoadOnDemand, and a dependency on FoilKeybinds. It has one data file
  per class.
- Each file adds one class to a global table (one table name, owned by this package). Shape per class:
  - suggested leveling spec (group ID), used when no points are spent
  - tested flag: false for every class at build time; the Warlock flips to true only after Tiago confirms it in game
  - per spec (group ID): English fallback name; priority list; three templates, one per bracket. A class may give
    one shared template for bracket 1 that all its specs use.
  - priority row: spell ID (the Forever ID of the first rank; the macro uses the name, so any rank works), the
    level the spell is learned at, and the short line in English and pt-BR.
  - template: key (one of the board keys) to slots; slot (normal, shift, ctrl, alt, altshift) to either a spell
    (spell ID plus English name) or an item category (the existing HS, POT, BAND, BOMB). No sequences, no "cast
    with", no pet commands. Mouseover follows the existing new-slot default (on for harmful and helpful spells).
- The main addon loads the package with the AddOns load API the first time the Guide tab opens. If loading fails
  (missing or disabled), the tab shows a short message instead of the guide.
- Packaging ships both folders. The local install script copies both.
- Spell IDs and learn levels come from a local source of truth, not from memory: the Forever trainer data of the
  installed What's Training addon (MIT license), folder WhatsTraining\Classes\Camelot (one file per class,
  `spellsByLevel`: level to a list of `{ id = ... }`; rank groups in `overriddenGroups`). A tool script turns it into
  a test-only fixture (spell ID to learn level per class). It never ships in the addon. Spells that come from talents
  are not in trainer data; the guide marks them as talent spells with the talent's minimum level.
- Guide text is written in our own words from public sources (Icy Veins, Wowhead Classic and Forever). Spell IDs
  and learn levels are checked on wowhead.com/forever; Classic IDs can be wrong on Forever. Existing Warlock notes:
  C:\Projetos\wow-keybinds\research_notes\icy_veins_affliction.md.

### Core (pure, tested)

- Bracket of a level: 1-19 is 1, 20-39 is 2, 40-60 is 3. One constant table of bracket ranges.
- Use safety: "Use this layout" runs the existing fit check on every key with the player's real names; a key that
  still does not fit is left out and named in chat. So Use never fails as a whole.
- Spec guess: from a list of groups with points spent and the class's suggested spec, returns the group with the
  most points; with no points (or no list) the suggested spec. Ties keep the game's group order.
- Template to keys: takes a template, a spell lookup (ID to localized name and kind) and returns a keys table in
  the same shape the addon stores today (slots with spell ID, name, kind, mouseover; or item slots). Unknown or
  unlearned spells keep their ID and English name (they show faded, as today). It never changes its input.
- Key of a spell: given the player's keys and a spell (ID and name, any rank), returns the key and slot it is on
  (first match in board order, plain press first), or nothing. Sequences and "cast with" count: a spell inside a
  sequence on Q normal is "Q". The UI formats it ("Shift+Q").
- Template for a spec and bracket: the spec's own template, or the class's shared bracket-1 template.
- Data check: one function that validates a whole class table and returns a list of problems: unknown keys, W/A/S/D,
  plain Space press used, more than 16 keys, unknown slot names, unknown item categories, sequences or "cast
  with", missing English or pt-BR text, missing learn level, a spec without all three templates (unless a shared
  bracket-1 template covers it), a macro over 255 characters (with the existing fit rules and no items in bags).

### Game layer

- Points per group read as described above, then the Core guess.
- Spell lookup for templates: localized name and kind from the spell ID (existing helpers).
- Using a template: the current keys are kept for Undo in the same pending-replace slot that Copy from uses, so
  Undo brings them back in one step, as Copy from does today. The Undo chat line says the template was undone (its
  own string, not the Copy from one). Every place that replaces the keys table clears the
  edit history (existing rule). The used template (group ID and bracket) and the last bracket we told the player
  about are saved per character.
- Level-up line: uses the new level from the level-up event argument (the player level API can still show the old
  level at that moment). The existing level-up event handler checks, only when a used template is saved, whether the new
  level's bracket is above the saved and the told bracket; then it prints one line and saves the told bracket. It
  does not load the guide package (it only needs the bracket table and the saved spec name).

### UI

- Tab bar: Keys | Guide | Settings. `/fkb guide` (and pt-BR alias `/fkb guia`) opens the window on the Guide tab.
- Guide tab layout: left column with the class name, the 3 spec buttons (the guessed one marked "yours"), and the
  3 bracket buttons; right side the priority list (rows: icon, name, purpose line, key chip or "not on a key",
  level tag when not learned yet); bottom bar with "Preview layout". The untested-class note sits under the list.
  Built from the existing Theme widgets and colors.
- Preview: the Keys tab draws a given keys table instead of the player's keys, read-only (clicks on keys and
  columns do nothing, Apply, Undo, Copy from and Refresh items are disabled), with a banner across the top of the
  tab: the spec and bracket, "Use this layout", "Cancel". Leaving the Keys tab or closing the window cancels the
  preview. The cheat sheet keeps showing the live keys. The preview must never write the live keys table (today the
  board's setup lookup creates missing keys, and the slot view writes spell IDs into the slot it reads): the live
  keys must be unchanged after preview and after Cancel.
- Locale: every new string in English and pt-BR.

## Testing Decisions

- A good test checks what goes in and what comes out of a Core function, never how it is built. Tests use the
  existing assert runner (tests/run.lua) and the load smoke test (tests/smoke.lua).
- Core tests: bracket of every edge level (1, 19, 20, 39, 40, 60); spec guess with clear winner, a tie, no
  points, no list; template to keys with a localized lookup, an unknown spell, an item slot, and input left
  unchanged; key of a spell for a plain slot, a modifier slot, a spell inside a sequence, a different rank, and a
  spell on no key; template for a spec falling back to the shared bracket-1 template; the data check catching each
  kind of problem with a small bad table.
- Data test: the runner loads every class file of the guide package and runs the data check on each. Zero
  problems for all 9 classes. It also checks every spell ID (priority rows and templates) against the trainer
  fixture: the ID must be a rank of that class's spell with the same learn level, unless the row is marked as a
  talent spell. Templates are checked with headroom (230 characters, not 255) because pt-BR spell names are longer. This is the gate that keeps a bad template from shipping.
- Smoke test: the stub loads the guide package too; opening the Guide tab, picking a spec and a bracket,
  previewing, cancelling and using a template run without errors.
- Prior art: the existing Core tests for macro text, fit, repair, sequence edits and the Grimorio import.
- In game (Tiago, Warlock): the tab opens, the guess picks the spec with most points, preview and Use work, Undo
  brings the old keys back, Apply places the macros, and the level-up line shows once.

## Out of Scope

- An AI job that updates the guides.
- Sequences, "cast with" and pet commands in templates.
- Essay-style guide text; text copied from other sites.
- Talent build advice (which talents to pick).
- Following stance or form bar paging (same limit as today).
- The mockup step (dropped at Tiago's request; the design follows the Keys tab).

## Further Notes

- Content is the biggest part: 9 classes, 27 specs, up to 81 templates, priority lists in two languages. Agents
  write it; the data test is the quality gate for structure, and Tiago checks the Warlock in game.
- Druid Feral Combat covers both cat and bear. Its template is the cat (damage) layout; the bear spells can sit on
  modifier slots.
- Report link for untested classes: https://github.com/tiagofoil/FoilKeybinds/issues
- After this ships, the release continues from docs/publishing.md (CurseForge and Wago projects, keys, tag).
