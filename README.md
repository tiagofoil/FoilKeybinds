# Foil Keybinds

WoW addon: one macro per key with Shift, Alt, Alt+Shift and Ctrl variants, placed on the bar slot the key already presses.

## Tests

Needs LuaJIT (Lua 5.1): `winget install --id DEVCOM.LuaJIT -e`

    luajit tests/run.lua

## Install for testing

    sh install.sh

In game: `/fkb` opens the window, `/fkb set Q Shadow Bolt` sets a key, Apply (or `/fkb apply`) creates the macros, Undo (or `/fkb undo`) puts back what the first Apply changed.
