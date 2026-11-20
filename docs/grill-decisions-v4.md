# Foil Keybinds: grill decisions, round 4 (2026-11-20)

Group D, postponed in grill-decisions-v2.md (line 3) and spec-v2.md (Out of Scope, line 291).
Tiago's own words for it (2026-11-18): "a class guide tab where the player chooses their spec and
sees a guide of the main abilities and their objectives in the rotation" and "ready-made templates
for each class, each spec, at each level".

Publishing waits for this work. State on 2026-11-20: public repo github.com/tiagofoil/FoilKeybinds
is up (README with screenshots and logo); CurseForge and Wago projects not made yet
(docs/publishing.md). Order now: mockups, spec, tickets, implement, then publish.

Hard requirement from v2 still holds: the addon stays extremely lightweight. Work only on game
events and clicks. No OnUpdate loops, no timers, no polling.

## Facts found

- WoW Forever uses the vanilla talent window: 3 talent trees per class, points on a grid
  (installed addon EllesmereUIForeverEssentials_ClassicTalents.lua, line 4 to 6; EllesmereUI
  exposes `EllesmereUI.ForeverTalentTrees`). So a "spec" is the tree with the most points.
  The retail `C_SpecializationInfo` API is also on the client (used by EllesmereUI); whether it
  returns anything useful on Forever is not checked. The spec step must check how to read talent
  points per tree on this client.
- The window already has tabs (Keys | Settings), and v2 reserved a Guide tab (grill-decisions-v2.md
  line 75, spec-v2.md line 189).
- Spells the player has not learned yet already show faded when WhatsTraining is installed.
- Item slots already resolve to the best item in the bags (Core.lua line 20).
- spec.md line 100 lists "Copying Icy Veins or other guide text into the addon" as out of scope.
  Guide text is written in our own words.
- Research notes for the Warlock already exist: C:\Projetos\wow-keybinds\research_notes\icy_veins_affliction.md
  (abilities, rotation, talent builds, Forever changes, macros, with source URLs).
- Forever item and spell data: wowhead.com/forever (Classic IDs can be wrong on Forever).

## Decisions

| Topic | Decision |
|---|---|
| Classes | All 9 classes and their specs ship in the first public version. Agents research and write them. Tiago checks the Warlock in game. The other classes carry a short "tell us if a key is wrong" note. |
| Levels | 3 brackets for every class: 1-19, 20-39, 40-60. One template per spec per bracket (about 81). At 1-19 the specs of a class may share one template. |
| Guide text | Per spec: the main abilities in rotation priority order. Each line: icon, one short line on what it is for, and the key it is on in the player's layout. No essays. Own words. |
| Language | English and pt-BR, same as the rest of the addon. |
| Spec pick | The addon preselects the tree with the most talent points; the player can change it in a list. Below level 10 (no points) it shows the leveling spec we suggest for the class. |
| Use a template | The canvas first shows the template as a preview. "Use this layout" replaces all keys. Undo takes it all back in one step. Nothing reaches the game until Apply, as today. |
| Next bracket | Only for a player who used a template: one chat line on the level-up event when they enter a new bracket, e.g. "Level 20: a new Affliction layout is ready. /fkb guide". No popup. |
| Template content | Spells and items (potions, Healthstone, bandages and the other consumables the addon already ranks). No sequences and no "cast with". |
| Weight | Guide and template data live in a second addon folder, FoilKeybinds_Guides, shipped in the same download and marked LoadOnDemand. It loads only when the Guide tab opens (and for the level-up check, only the bracket table it needs, or a tiny index in the main addon). .pkgmeta must package both folders. |
| Design | 2 or 3 HTML mockups of the Guide tab in the addon colors first (like docs/mockups/keys-tab-*.dc.html). Tiago picks one before the spec. |
| AI cron job | Out of scope. Guide text is updated by hand with new versions. |

## Out of scope

- AI job that updates guides.
- Sequences and "cast with" in templates.
- Essay-style guide text.
- Copying text from Icy Veins or other sites.
