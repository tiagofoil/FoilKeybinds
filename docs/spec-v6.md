# Spec v6: guide layouts follow the home key rules

Source: Tiago's first wizard test (2026-11-20) and his rules in `docs/key-placement.md`.
Decisions (click cards, 2026-11-20): redo all 9 classes now; a castsequence only where it works;
wand on all 3 level ranges; no side buttons = one line on the step; the home key table below.

## Problem Statement

Tiago ran the wizard and found the key suggestions not useful. The guide layouts put spells on keys
by class habit, not by how easy the key is to reach. The wizard suggests exactly the guide keys, so a
new player gets a layout where the emergency crowd control sits on R, the main attack on 1, and the
wand is missing for casters.

## Solution

One home key table for every class. Each kind of spell (meaning) has its home key. All 27 guide
layouts (9 classes x 3 level ranges) are rebuilt on it, and the data test checks it. The wizard keeps
working the same way: it suggests the home key, and the player can move each group.

### Home key table

| Key | Meaning ID | Kind of spell | Why |
|---|---|---|---|
| BUTTON4 (Mouse 4) | `main` | One-button rotation (castsequence) or the main attack. Healers: main heal | Thumb, pressed all the time |
| BUTTON5 (Mouse 5) | `wand` (Mage, Priest, Warlock) / `second` (others) | Wand Shoot / second attack. Healers: second heal | Thumb, filler and no-mana fallback |
| E | `cc` | Crowd control, the emergency key | Easiest key for almost everyone |
| F | `dot` | Main DoT or the most pressed spell | Easy |
| Q | `dot` | Second DoT, curses, debuffs | Easy |
| R | `burst` | Big damage and procs; AoE on Shift and Alt. Healers: big heal, cooldowns | The "ultimate" key, like in MOBA games |
| V | `items` | Healthstone or potion, Heal button, Eat and drink (unchanged from v5) | Right under F |
| 1 | `interrupt` | Interrupts | Quick reach |
| 2 | `defense` | Shields, escapes, defensive cooldowns | |
| 3 | `heal` | Self heals, or group heals for hybrids | |
| 4, T | `buff` | Buffs, mostly out of combat | Far keys, rarely pressed |
| G | `pet` | Pet summons and pet control | |
| C | `form` | Forms, stances, auras | |
| X, Z | `utility` | Everything else | |

Keys not in the table (5, SPACE with modifiers, BUTTON3) stay free in the guide layouts.

## User Stories

1. As a new player, I want the wizard to suggest Mouse 4 for my rotation, so that my most pressed button is under my thumb.
2. As a new player without side mouse buttons, I want the Mouse 4 and Mouse 5 steps to tell me which key to click instead, so that I am not stuck.
3. As a caster, I want Wand Shoot on Mouse 5 in every level range, so that I always have a no-mana fallback.
4. As a Warlock or another DoT caster, I want one key with a castsequence of my DoTs and filler, so that one button plays my rotation.
5. As a Warrior or Rogue, I want my main attack as one plain spell on Mouse 4, so that a failed rage or energy step never blocks the key.
6. As any player, I want crowd control on E, so that I hit it fast in an emergency.
7. As any player, I want my big damage and procs on R, with AoE on Shift and Alt, so that the "ultimate" key does the big hits.
8. As any player, I want my main DoTs and most pressed spells on F and Q, so that they sit on easy keys.
9. As any player, I want rarely pressed buffs and utility on far keys (4, T, X, Z), so that they do not take my easy keys.
10. As a healer, I want my main heal on Mouse 4 and the big heal on R, so that the table works for heals too.
11. As a low-level player, I want a castsequence to skip the spells I have not learned yet, so that it does not get stuck on an unknown spell.
12. As a returning wizard user, I want my old picks dropped when the guide layouts change, so that an old pick does not move the wrong group.
13. As the maintainer, I want the data test to fail when a layout puts a meaning off its home key, so that the rules stay true in all 27 layouts.
14. As a player reading the wizard step, I want the "why" line to say why this key is good, so that I learn the idea, not only the key.

## Implementation Decisions

- **Meanings.** `ns.MEANINGS` (step order) becomes: `main`, `wand`, `second`, `cc`, `dot`, `burst`,
  `items`, `interrupt`, `defense`, `heal`, `buff`, `form`, `pet`, `utility`. `aoe` goes away (AoE lives
  on R's Shift and Alt). New locale strings in English and pt-BR: `MEANING_wand`, `MEANING_second`,
  `MEANING_burst` and `WHY_*` for each. Every `WHY_*` line says why its home key is good (for example
  "E is the easiest key for almost everyone").
- **Home table in Core, meanings come from it.** One table: guide key to meaning ID. Every key has one
  meaning, except BUTTON5: `wand` for Mage, Priest and Warlock, `second` for the other classes. So the
  per-spec `meanings` maps in the guide data go away: the meaning of a guide key is read from the table
  (one Core function, key and class in, meaning out). The wizard reads it from there.
  The data check (`ns.CheckGuide`) drops the "needs a meanings map" rule and adds: a guide layout may use
  only the keys in the table (not 5, not SPACE, not BUTTON3); a caster class (Mage, Priest, Warlock) has
  Wand Shoot (spell 5019) on BUTTON5 normal in every range of every spec.
- **Castsequence in guide layouts.** A template slot may now be `{ seq = { spell, spell, ... }, reset = { target = true, combat = true } }`.
  The data check stops refusing sequences in templates. `ns.TemplateKeys` builds the stored sequence
  shape (each step named through the lookup, like a plain spell). The 230-character fit test counts the
  sequence like the editor does.
- **Where a castsequence goes.** Only specs whose rotation is spells with no cooldown (DoTs, curses,
  filler): for example all Warlock specs, Shadow Priest, Balance Druid. A spell with a cooldown (Mind
  Blast, Arcane Shot) never goes in a sequence. Rage and energy specs (Warrior, Rogue, Feral) get one
  plain spell on BUTTON4. Each class agent decides per spec on this rule and writes why in the ticket.
- **Unknown steps.** A castsequence written to a macro leaves out the steps the player does not know
  yet (learned spells: the same check the canvas uses for faded icons). One known step left: a plain
  `/cast`. When the player learns a spell, the existing spell-learned refresh brings it into the macro.
  Check how Apply and the learned refresh work today before choosing where this filter goes; the stored
  keys keep the full sequence.
- **Wizard.** The `main` step and the `wand`/`second` step show one more line when the suggested key is
  BUTTON4 or BUTTON5: "No side buttons on your mouse? Click 1." (for Mouse 5: "Click 2."). The swap rule
  already moves the group on that key out of the way.
- **Old picks.** Saved wizard picks map old guide keys. They are dropped once when the guide version
  changes (a version number next to the picks), so an old pick never moves the wrong group.
- **Layouts.** All 27 layouts are rebuilt on the table. Warlock follows Tiago's real setup
  (`docs/key-placement.md`) as close as the table allows. The 1-19 shared template per class follows the
  table too. Keep v5's items on V. Keep `tested = true` only for Warlock.

## Testing Decisions

- Test only what a player sees or what the data holds, not private helpers.
- `tests/run.lua`: the home key rule (a good fixture passes; a meaning off its home key fails; a caster
  without the wand fails), sequences in templates (allowed, built by `TemplateKeys`, fit counted), the
  unknown-step filter (a sequence with one unknown step writes the other steps; one known step writes
  a plain cast), the picks version drop. The existing data test runs over all 9 classes.
- `tests/smoke.lua`: the wizard block follows the new Warlock keys (main attack on BUTTON4), the no
  side buttons line shows on the main step.
- Prior art: the v5 meanings tests and the wizard smoke block.

## Out of Scope

- A setting for "my mouse has no side buttons".
- Changing the editor or the Keys tab.
- In-game tests of the 8 classes other than Warlock (they stay `tested = false`).

## Further Notes

- The release (CurseForge, Wago) waits for this.
- Tiago remaps Mouse 4 and Mouse 5 to keys 2 and 3 on his own mouse. The guide uses BUTTON4 and
  BUTTON5 for everyone.
