# 04: Guide content for Mage, Rogue, Shaman and Warrior

**What to build:** Players of these four classes get a full guide: for each class the suggested leveling spec, and for each of its 3 specs (by Forever talent group ID) a priority list and three templates (1-19, 20-39, 40-60; a shared 1-19 template is allowed), in the data shape from ticket 01. Each class passes the data test with zero problems.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] One data file per class in the guide package: Mage (11582, 11594, 11601), Rogue (11580, 11573, 11572), Shaman (11326, 11363, 11362), Warrior (11650, 11657, 11670)
- [ ] Spell IDs and learn levels taken from the trainer fixture, never from memory; talent spells marked as talent spells with the talent's minimum level, checked on wowhead.com/forever
- [ ] Priority lists in rotation order, 4 to 8 rows each, one short purpose line per row in English and in natural pt-BR (never pt-PT), own words, nothing copied from other sites
- [ ] Templates: the most used spells on the easiest keys (1-5, Q, E, R, F and their modifiers); at most 16 keys; no W/A/S/D; plain Space press left to the game; potions, Healthstone, bandages where they make sense; no sequences, "cast with" or pet commands
- [ ] Rogue and Warrior stance or form spells: templates assume the main bar page (bar paging is not followed, same limit as today)
- [ ] tested flag false for all four classes
- [ ] Data test passes with zero problems for all four classes; all old tests pass

Spec: docs/spec-v4.md (stories 46, 49, 50; section "Guide data package")
