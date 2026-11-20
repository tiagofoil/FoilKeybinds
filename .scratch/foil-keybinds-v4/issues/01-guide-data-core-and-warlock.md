# 01: Guide data package, Core rules and the Warlock guide

**What to build:** The guide data exists and is proven correct by tests, end to end for one class. A second addon folder, FoilKeybinds_Guides (load on demand, depends on FoilKeybinds, same Interface line), ships in the same download and holds the Warlock guide: suggested leveling spec, and for Affliction, Demonology and Destruction a priority list (spell, learn level, purpose line in English and pt-BR) and three templates (1-19, 20-39, 40-60; a shared 1-19 template is allowed). The pure Core rules the rest of the feature needs exist with tests: bracket of a level, spec guess from points per talent group, template to keys, key of a spell in the player's keys, template for a spec and bracket, and the data check. A test-only fixture of Forever trainer spells (spell ID to learn level per class, all 9 classes) is built by a tool script from the installed What's Training Forever data, and the data test checks the Warlock data against it. Packaging and the local install script carry both folders.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] FoilKeybinds_Guides folder with its TOC (LoadOnDemand, dependency on FoilKeybinds, same Interface line as the main addon) and one Warlock data file; the data shape matches spec-v4 "Guide data package" and is keyed by Forever talent group IDs (Warlock 11629, 11636, 11637)
- [ ] Packaging config ships both folders; the install script copies both
- [ ] Tool script reads WhatsTraining\Classes\Camelot\<Class>.lua (spellsByLevel and overriddenGroups) from the installed addon (C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns) and writes a test-only fixture for all 9 classes; the fixture is never packaged; What's Training (MIT) is credited in the fixture header
- [ ] Core: bracket of a level (1-19, 20-39, 40-60) from one constant table
- [ ] Core: spec guess (most points wins; ties keep game order; no points or no list gives the suggested spec)
- [ ] Core: template to keys with a spell lookup (localized name and kind); unknown spells keep ID and English name; item slots stay item slots; mouseover follows the existing new-slot default; input never changed
- [ ] Core: key of a spell (any rank, by ID or name; plain press first, board order; inside sequences and "cast with" counts), nothing when not on a key
- [ ] Core: template for a spec and bracket, with the class's shared 1-19 fallback
- [ ] Core: data check returns a list of problems for: unknown key, W/A/S/D, plain Space press, more than 16 keys, unknown slot, unknown item category, sequence or "cast with" or pet command, missing en or pt-BR text, missing learn level, missing bracket template, macro over 230 characters with the existing fit rules and no items in bags
- [ ] Data test in the main runner (CI runs it): every class file present passes the data check with zero problems, and every spell ID is a rank of a trainer spell of that class with the same learn level, unless marked as a talent spell
- [ ] Warlock content: spell IDs and levels taken from the fixture, not from memory; text in our own words (sources: C:\Projetos\wow-keybinds\research_notes\icy_veins_affliction.md, Icy Veins, wowhead.com/forever); tested flag false
- [ ] Core tests for every rule above (edge levels 1, 19, 20, 39, 40, 60; tie; no points; localized lookup; unknown spell; rank match; sequence match; shared fallback; each data check problem with a small bad table); all old tests pass; smoke test passes

Spec: docs/spec-v4.md (stories 8, 13 to 15, 29 to 35, 43, 44, 49, 50; sections "Specs on WoW Forever", "Guide data package", "Core", "Testing Decisions")
