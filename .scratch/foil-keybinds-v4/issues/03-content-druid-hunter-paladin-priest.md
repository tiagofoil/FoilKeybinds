# 03: Guide content for Druid, Hunter, Paladin and Priest

**What to build:** Players of these four classes get a full guide: for each class the suggested leveling spec, and for each of its 3 specs (by Forever talent group ID) a priority list and three templates (1-19, 20-39, 40-60; a shared 1-19 template is allowed), in the data shape from ticket 01. Each class passes the data test with zero problems.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] One data file per class in the guide package: Druid (11328, 11347, 11340), Hunter (11372, 11371, 11370), Paladin (11486, 11541, 11559), Priest (11608, 11615, 11622)
- [ ] Spell IDs and learn levels taken from the trainer fixture, never from memory; talent spells marked as talent spells with the talent's minimum level, checked on wowhead.com/forever
- [ ] Priority lists in rotation order, 4 to 8 rows each, one short purpose line per row in English and in natural pt-BR (never pt-PT), own words, nothing copied from other sites
- [ ] Templates: the most used spells on the easiest keys (1-5, Q, E, R, F and their modifiers); at most 16 keys; no W/A/S/D; plain Space press left to the game; potions, Healthstone, bandages where they make sense; no sequences, "cast with" or pet commands
- [ ] Druid Feral Combat template is the cat (damage) layout; bear spells may sit on modifier slots
- [ ] Hunter templates leave pet commands out (out of scope)
- [ ] tested flag false for all four classes
- [ ] Data test passes with zero problems for all four classes; all old tests pass

Spec: docs/spec-v4.md (stories 46, 49, 50; section "Guide data package")
