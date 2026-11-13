# Foil Keybinds: grill decisions (2026-11-13)

Public WoW addon. An in-game canvas keybind editor, like the Warlock page in
C:\Projetos\wow-keybinds\index.html, for any class. Reuses the approach of
C:\Projetos\wow-keybinds\addon\GrimorioSetup (macro create/edit, bar slot from the key's binding).

## Decisions

| Topic | Decision |
|---|---|
| Name | Foil Keybinds (check that it is free on CurseForge before publishing) |
| Client | WoW Forever only in v1 |
| Slots per key | 5: normal, Shift, Alt, Alt+Shift, Ctrl |
| Keys on canvas | Fixed set near WASD + mouse: Q E R F G V T Z X C, 1 to 5, Space, mouse buttons |
| v1 scope | Editor + login repair. Class starter setups and the AI cron are v2 |
| Picker | Learned spells + items (potion, Healthstone, bomb, bandage); best item in bags picked on Apply and on login |
| Mouseover | Automatic per spell type ([@mouseover,harm,nodead][] harmful, [@mouseover,help][] heals), on/off toggle per slot |
| Key without bar slot | Warn, look for an empty slot on another bar, place it there and say where. If none, bind the key to the macro directly |
| 255-char limit | Card shows used/255. Over the limit: drop mouseover from slots first, then block the last choice with a message |
| Profiles | Per character, with "copy from another character of the same class" |
| Languages | English + pt-BR, picked by game locale |
| Login repair | Runs once on login, no polling. Spell stored by spellID; renamed spell gets the new name. Removed spell: slot emptied, popup lists changes, Undo button |
| Extras per key | 2 toggles: "target enemy if none" and "pet attacks". No pet follow/stay in v1 |
| Migration | Import the current GrimorioSetup Warlock setup as the first profile, then retire GrimorioSetup |
| Open editor | Slash command + minimap button (addon compartment, no extra library) |
| Code home | Public GitHub repo, MIT license, folder C:\Projetos\keybind-addon |
| Publish | CurseForge + Wago, both built from GitHub |
| Performance | No constant checks. Work only on Apply, login, and out-of-combat item swap after bag changes |

## v2 (not now)
- Per-class starter setups for new players.
- AI cron (about 4 times a day): check game version; only if it changed, check spell changes; only then update suggestions.
- Do not copy Icy Veins text into the addon. Use game data and own suggestions.
- YouTube video.
