# Foil Keybinds: grill decisions, round 2 (2026-11-18)

Groups A to C of Tiago's feature list. Group D (class guide tab, templates per class, spec and
level) is out of scope and gets its own grill later. Publishing is on hold until Tiago is proud of
the addon; do not plan release work.

Hard requirement for everything below: the addon must stay extremely lightweight. Work only on
game events and clicks. No OnUpdate loops, no timers, no polling.

## Item 1: cheat sheet shows "?" after learning a spell (bug)

Facts found in the code:

- The cheat sheet already refreshes on events: `SPELLS_CHANGED` and `PLAYER_LEVEL_UP` while shown,
  and a full refresh on show (Cheat.lua:340-363). Icons are read live on each refresh, no cache.
  Event timing is not the cause.
- Likely cause 1: spell data is not loaded. `ns.SpellIcon` calls `C_Spell.GetSpellTexture` directly
  (Game.lua:266-270); on this client it returns nil until the data is loaded. Cheat.lua:145 turns
  nil into the "?" texture (134400). What's Training loads data first with
  `C_Spell.IsSpellDataCached` and `C_Spell.RequestLoadSpellData` (WhatsTraining/Cache.lua:44-54,
  183-194). `ns.FutureFrom` throws away What's Training's own `icon` field (Core.lua:314).
- Likely cause 2: the picker stores the highest rank's spellID for future spells
  (Core.lua:312-316). After learning Rank 1, `ns.IsKnown(RankN)` stays false (Game.lua:274-279) and
  the cell stays faded.
- Possible cause 3: GrimorioSetup import stores a nil spellID for spells not learned yet
  (`spellOf`, Game.lua:451-455); `ns.Repair` skips nil IDs (Core.lua:334), so it is never filled.
- Possible cause 4 (bar macro only, unverified): What's Training strips rank numerals from names
  (Cache.lua:191, Utils.lua:192). If the spellbook name differs, `/cast <name>` never resolves.
- Side risk: `RepairOnLogin` treats a nil `GetSpellName` as "spell removed"
  (Game.lua:377-381, Core.lua:336-338). An unloaded spell could be wrongly removed.
- The main window has the same problem (UI.lua:226, 357) and does not update while open; it only
  registers `ADDON_LOADED` (UI.lua:491).

Decisions:

- Load spell data before reading icons or names (request on demand, refresh on the load event).
- A slot counts as known when any rank of that spell name is known. The macro casts by name, so
  the learned rank is what fires.
- Fill a nil spellID when the spell can be resolved later.
- Login repair must not treat "not loaded yet" as "removed".
- The main window gets the same fix and refreshes on `SPELLS_CHANGED` while shown.
- In-game check to tell the causes apart, if needed (replace Q with a real key):
  `/run local s=FoilKeybindsDB.applied["Q"].slots.normal local i=C_Spell.GetSpellInfo(s.name) print(s.spellID,C_Spell.IsSpellDataCached(s.spellID),C_Spell.GetSpellTexture(s.spellID),C_SpellBook.IsSpellKnown(s.spellID),i and i.spellID)`

## Item 2: refresh heal items button

Facts found in the code:

- `ns.SwapItems` (Game.lua:361-375) runs on `PLAYER_LOGIN`, `BAG_UPDATE_DELAYED` and
  `PLAYER_REGEN_ENABLED` (Game.lua:476-483). It compares the macro body to the new text
  (Game.lua:353), so it rewrites only when needed.
- It touches only applied keys with an item slot (Game.lua:364, 369).
- It writes nothing, silently, when the macro is missing (`GetMacroIndexByName` returns 0) or the
  text is over 255 (`FitMacro` returns nil, Game.lua:352).
- `PLAYER_LEVEL_UP` is not registered, but `usable()` filters items above the player's level
  (Game.lua:65, Core.lua:45). A potion that becomes usable at a level-up waits for the next bag
  change.
- The best-item lists are Classic-era only (Core.lua:20-36). Other items match only by the name
  fallback, which fails while the item name is not cached (Game.lua:62, Core.lua:44).
- Bombs may fail `IsUsableItem` without Engineering (unverified).

Decisions:

- A "Refresh items" button on the bottom bar of the Keys tab, next to Apply, plus `/fkb items`.
  It calls `ns.SwapItems()`, out of combat only.
- It prints one chat line per change, for example `Q: Healing Potion -> Greater Healing Potion`.
- Register `PLAYER_LEVEL_UP` for the item swap (event only).
- Print a chat message when a swap cannot write a macro (missing macro, over 255), instead of
  failing silently.
- The agent researches the healthstone, potion, bandage and bomb item IDs for this client and adds
  them to the lists. The name fallback stays.

## Items 3 and 4: settings button, windows close together

- One window with tabs at the top: Keys | Settings. Group D will add a Guide tab later.
- Closing the window closes everything, so item 4 is solved by the tabs.
- `/fkb config`, the title-bar gear and a right click on the compartment entry open the window on
  the Settings tab.
- The separate settings window (Settings.lua, `ns.OpenSettings` at Settings.lua:156) goes away.
  The Options > AddOns canvas stays.

## Item 8: master switch for bars and keybinds

What Apply touches today (Game.lua:161-228): it writes macros (`upsertMacro`), clears the
Shift/Alt/Ctrl bindings on edited keys (Game.lua:182), rebinds keys (Game.lua:188-209), and places
macros on bar slots (`place`, Game.lua:47-49). Undo restores from `FoilKeybindsDB.backup`
(Game.lua:230-256).

Decisions:

- Switch OFF: Apply writes macros only. It never changes bars or keybinds. Item swap and login
  repair still update macro bodies. The key card shows a hint to drag the macro to a bar.
- Start state: OFF on a fresh install. ON for a character that already has applied keys
  (`FoilKeybindsDB.applied` not empty), so Tiago's setup keeps working.
- Turning it OFF after an Apply: a popup asks "Keep bars and keybinds as they are" or "Undo them".
- Turning it ON: a popup explains in plain words what Apply does (clears Shift/Alt/Ctrl bindings on
  the edited keys, puts macros on bar slots, may bind a key to a free slot, Undo brings it back).
- Before each Apply: a preview list of the exact changes, for example
  `Shift-Q: was Mount, now cleared`, with OK and Cancel. With the switch OFF, the preview lists only
  macro changes.
- The switch is always visible on the Keys tab next to Apply, with a clear ON/OFF state, and also
  on the Settings tab.

## Item 5: castsequence

Macro builder today: `ns.MacroText` (Core.lua:82-121) writes one `/cast` line for spells and one
`/use` line for items. With items it uses the exclusive conditions table `EXCL` (Core.lua:68-69),
because both lines run on one press. `ns.FitMacro` (Core.lua:170) handles the 255 limit.

Decisions:

- Any of the 5 slots (normal, Shift, Alt, Alt+Shift, Ctrl) can hold one spell or a sequence.
- Reset per sequence: two checkboxes, "new target" and "leave combat" (both ON by default), and an
  optional seconds box.
- No mouseover on sequences.
- Card UI: each spell picked goes to the end of the list; each spell has an x to remove it and
  left/right arrows to move it.
- The key on the canvas and the cheat sheet show the first spell's icon with a small number badge
  (how many spells).
- A sequence holds spells only: no items, no pet commands.
- Spells not learned yet are allowed in a sequence and show faded.
- Login repair renames spells inside sequences and drops removed spells from the list.
- Over 255: blocked with a message (there is no mouseover to drop first).
- Lines with a sequence need exclusive conditions like `EXCL`, because `/castsequence` and `/cast`
  both run on one press.
