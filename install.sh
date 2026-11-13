#!/bin/sh
# Copy the addon into the WoW Forever AddOns folder for in-game testing.
set -e
DEST="/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/FoilKeybinds"
rm -rf "$DEST"; mkdir -p "$DEST"
cp "$(dirname "$0")"/FoilKeybinds/* "$DEST"/
echo "installed to $DEST"
