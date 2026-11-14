# Foil Keybinds

A WoW Forever addon that puts your whole layout on the keys near WASD. Each key gets one macro with five slots: normal, Shift, Alt, Alt+Shift and Ctrl. The modifiers live inside the macro, so one bar slot does it all.

## What it does

- One macro per key, with the Shift, Alt, Alt+Shift and Ctrl variants inside it.
- Canvas editor: click a key, pick a learned spell or a consumable for each slot.
- Items: potions, Healthstone, bombs and bandages use the best one in your bags.
- Places each macro on the bar slot the key already presses and clears the modifier bindings that would block it.
- Future spells: with [What's Training](https://github.com/fusionpit/WhatsTraining) installed, the picker also lists spells you have not learned yet, with the level you get them.
- Cheat sheet: a small floating grid of what is live (one row per applied key, one column per modifier). The column of the modifier you hold lights up. Drag it, scroll to resize, lock it to make it click-through in combat.
- Login repair: renamed or removed spells are fixed once on login, with a popup that lists the changes and can undo them.

## How to use

Type `/fkb` (or use the addon compartment button) to open the editor. Set your keys, then click Apply. Undo puts back what the first Apply changed.

Commands: `/fkb`, `/fkb set Q Shadow Bolt`, `/fkb apply`, `/fkb undo`, `/fkb cheat` (or `/fkb cola`) to show or hide the cheat sheet.

## Limits

- WoW Forever (retail) only.
- A macro holds at most 255 characters, so very long spell names on all five slots may not fit.
- Apply works out of combat only (WoW blocks macro and binding changes in combat).
- Bindings follow the game's binding mode (account-wide or per character), whichever is active when you Apply.
- Bar slots are found from the main bar page; stance and bonus bar paging (forms, stealth) is not followed.
- A key with no normal slot keeps its own binding (Space still jumps). The macro goes on a free bar slot (empty, no key bound) so its cooldown shows, and the used Shift/Alt/Alt+Shift/Ctrl variants press that slot. With no free slot, they are bound to the macro directly (no cooldown on a bar).
- Items are matched by item ID. With none in your bags the macro falls back to the English item name, which only works on English clients.
- Characters have a limited number of macro slots (about 18); keys that do not fit are skipped with a chat message.

## Development

Tests need LuaJIT (Lua 5.1): `winget install --id DEVCOM.LuaJIT -e`

    luajit tests/run.lua

Install for in-game testing:

    sh install.sh

Releases are built by `.github/workflows/release.yml` on a `v*` tag. See `docs/publishing.md`.

## License

MIT, see `LICENSE`. Future spell data comes from the optional addon What's Training (MIT, by fusionpit) through its public `WT_API`.
