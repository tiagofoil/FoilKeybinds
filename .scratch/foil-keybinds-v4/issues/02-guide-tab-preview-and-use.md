# 02: Guide tab, preview, Use this layout and the level-up line

**What to build:** A player opens the Guide tab (tab bar Keys | Guide | Settings, or `/fkb guide`, `/fkb guia`) and sees their class, the 3 specs by their game names with the one with most talent points preselected and marked "yours" (suggested leveling spec when no points), the priority list for that spec (icon with game tooltip, name, purpose line, the key it is on as "Shift+Q" or "not on a key", the learn level when not learned yet) and three bracket buttons with the current bracket preselected. "Preview layout" shows the template on the Keys tab, read-only, under a banner with the spec, the bracket, "Use this layout" and "Cancel". Use replaces all keys, Undo brings all old keys back in one click, nothing reaches the game until Apply. After a used template, one chat line on entering a new bracket. Works end to end with the Warlock data from ticket 01; a class without data shows a short message.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Guide tab in the window, built with the existing Theme widgets and colors, same look as the Keys tab; tab choice and spec pick survive switching tabs while the window stays open
- [ ] The guide package loads on the first Guide tab open through the AddOns load API; a missing or disabled package shows a short message, no error
- [ ] Spec points read through the Forever talent API path in spec-v4 ("Specs on WoW Forever"); every nil step falls back to the suggested spec
- [ ] Spec names from the game's group display name, English fallback from the data
- [ ] Untested-class note with the report link (https://github.com/tiagofoil/FoilKeybinds/issues) under the list when the class's tested flag is false
- [ ] Preview never writes the live keys table: the board setup lookup and the slot view must not create keys or write spell IDs into the live data; a check proves the live keys are unchanged after preview and after Cancel
- [ ] During preview: key and column clicks do nothing; Apply, Undo, Copy from and Refresh items are disabled; leaving the Keys tab or closing the window cancels; the cheat sheet keeps the live keys
- [ ] Use: old keys saved in the same pending-replace slot as Copy from; edit history cleared; fit check per key with real names, a key that does not fit is left out and named in chat; chat line to check the keys and press Apply
- [ ] Undo after Use prints its own "template undone" line, not the Copy from line
- [ ] Used template (group ID, bracket) and the last told bracket saved per character
- [ ] Level-up line uses the new level from the level-up event argument; only when a used template is saved; once per bracket; names the spec, the bracket and `/fkb guide`; does not load the guide package
- [ ] Every new string in English and pt-BR
- [ ] Smoke test loads the guide package (stubbed load API), opens the Guide tab, picks a spec and a bracket, previews, cancels and uses a template without errors
- [ ] All tests pass

Spec: docs/spec-v4.md (stories 1 to 28, 36 to 42, 45 to 47; sections "Game layer", "UI")
