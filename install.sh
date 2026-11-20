#!/bin/sh
# Copy the addon and its guide package into the WoW Forever AddOns folder for in-game testing.
set -e
ADDONS="/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns"
for name in FoilKeybinds FoilKeybinds_Guides; do
  rm -rf "$ADDONS/$name"; mkdir -p "$ADDONS/$name"
  cp -r "$(dirname "$0")/$name"/* "$ADDONS/$name"/
  echo "installed to $ADDONS/$name"
done
