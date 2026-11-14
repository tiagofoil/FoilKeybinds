-- Plain assert-based runner. Run from repo root: luajit tests/run.lua
local core = dofile("FoilKeybinds/Core.lua")
local tests, failed = {}, 0
local function test(name, fn) tests[#tests + 1] = { name, fn } end
local function eq(got, want) assert(got == want, ("\n got  %q\n want %q"):format(got, want)) end
local function sp(name, mo, kind) return { spellID = 1, name = name, mouseover = mo, kind = kind or "harm" } end
local T = "#showtooltip\n"

test("normal only gives bare /cast", function()
  eq(core.MacroText({ slots = { normal = sp("Shadow Bolt") } }), T .. "/cast Shadow Bolt")
end)

test("all 5 slots, most specific first, normal is bare fallback", function()
  eq(core.MacroText({ slots = { normal = sp("N"), shift = sp("S"), alt = sp("A"), altshift = sp("AS"), ctrl = sp("C") } }),
    T .. "/cast [mod:alt,mod:shift] AS; [mod:ctrl] C; [mod:shift] S; [mod:alt] A; N")
end)

for _, c in ipairs({ { "shift", "mod:shift" }, { "alt", "mod:alt" }, { "altshift", "mod:alt,mod:shift" }, { "ctrl", "mod:ctrl" } }) do
  test(c[1] .. " alone, no mouseover", function()
    eq(core.MacroText({ slots = { [c[1]] = sp("X") } }), T .. "/cast [" .. c[2] .. "] X")
  end)
  test(c[1] .. " with harm mouseover", function()
    eq(core.MacroText({ slots = { [c[1]] = sp("X", true) } }),
      T .. "/cast [" .. c[2] .. ",@mouseover,harm,nodead][" .. c[2] .. "] X")
  end)
end

test("normal harm mouseover matches prior art", function()
  eq(core.MacroText({ slots = { normal = sp("Siphon Life", true), alt = sp("Immolate", true), shift = sp("Wrack") } }),
    T .. "/cast [mod:shift] Wrack; [mod:alt,@mouseover,harm,nodead][mod:alt] Immolate; [@mouseover,harm,nodead][] Siphon Life")
end)

test("help mouseover", function()
  eq(core.MacroText({ slots = { normal = sp("Heal", true, "help"), shift = sp("Renew", true, "help") } }),
    T .. "/cast [mod:shift,@mouseover,help,nodead][mod:shift] Renew; [@mouseover,help,nodead][] Heal")
end)

test("kind other ignores mouseover", function()
  eq(core.MacroText({ slots = { normal = sp("Soulstone", true, "other") } }), T .. "/cast Soulstone")
end)

test("both extras come before /cast", function()
  eq(core.MacroText({ targetEnemy = true, petAttack = true, slots = { normal = sp("Bane of Agony", true) } }),
    T .. "/targetenemy [noharm][dead]\n/petattack [harm,nodead]\n/cast [@mouseover,harm,nodead][] Bane of Agony")
end)

test("each extra alone", function()
  eq(core.MacroText({ targetEnemy = true, slots = { normal = sp("X") } }), T .. "/targetenemy [noharm][dead]\n/cast X")
  eq(core.MacroText({ petAttack = true, slots = { normal = sp("X") } }), T .. "/petattack [harm,nodead]\n/cast X")
end)

test("empty slots are skipped", function()
  eq(core.MacroText({ slots = { normal = {}, shift = sp("S") } }), T .. "/cast [mod:shift] S")
end)

test("command -> slot", function()
  eq(core.SlotOf("ACTIONBUTTON1"), 1); eq(core.SlotOf("MULTIACTIONBAR1BUTTON12"), 72)
  eq(core.SlotOf("MULTIACTIONBAR7BUTTON3"), 171); eq(core.SlotOf("MOVEFORWARD"), nil); eq(core.SlotOf(nil), nil)
end)

test("first empty slot skips used ones, bar by bar", function()
  local slot, cmd = core.FirstEmptySlot(function(s) return s < 3 end)
  eq(slot, 3); eq(cmd, "ACTIONBUTTON3")
  slot, cmd = core.FirstEmptySlot(function(s) return s <= 12 end) -- main bar full, bar 1 is next
  eq(slot, 61); eq(cmd, "MULTIACTIONBAR1BUTTON1")
  eq(core.FirstEmptySlot(function() return true end), nil)
end)

local long = ("x"):rep(30)
local function it(cat) return { item = cat } end
test("fitting setup is untouched", function()
  local text, n, trimmed = core.FitMacro({ slots = { normal = sp("X", true) } })
  eq(text, T .. "/cast [@mouseover,harm,nodead][] X"); eq(n, #text); eq(#trimmed, 0)
end)

test("over-limit setup drops mouseover, biggest saving first, until it fits", function()
  -- 5 x 30-char names with mouseover is ~370 chars; altshift has the longest clause, so it goes first.
  local setup = { slots = { normal = sp(long, true), shift = sp(long, true), alt = sp(long, true),
    altshift = sp(long, true), ctrl = sp(long, true) } }
  local text, n, trimmed = core.FitMacro(setup)
  assert(text and n <= 255 and n == #text, "should fit, got " .. tostring(n))
  eq(trimmed[1], "altshift")
  eq(setup.slots.altshift.mouseover, true) -- input is not mutated, caller applies trimmed
  local again = { slots = {} }
  for id, s in pairs(setup.slots) do again.slots[id] = sp(s.name, s.mouseover) end
  for _, id in ipairs(trimmed) do again.slots[id].mouseover = false end
  eq(core.MacroText(again), text)
end)

test("impossible setup errors naming the slot with the longest name", function()
  local setup = { slots = { normal = sp(long), shift = sp(long), alt = sp(long), altshift = sp(long),
    ctrl = sp(("y"):rep(60), true) } }
  local text, n, trimmed, errSlot = core.FitMacro(setup)
  eq(text, nil); assert(n > 255); eq(trimmed[1], "ctrl"); eq(errSlot, "ctrl")
end)

test("ranking picks the best usable item per category", function()
  local owned = { [5509] = "Healthstone", [19013] = "Major Healthstone", [118] = "Minor Healing Potion",
    [929] = "Healing Potion", [1251] = "Linen Bandage" }
  local best = core.BestItems(owned, function(id) return id ~= 19013 end) -- Major not usable yet
  eq(best.HS.id, 5509); eq(best.HS.name, "Healthstone")
  eq(best.POT.id, 929); eq(best.BAND.id, 1251); eq(best.BOMB, nil)
  eq(core.BestItems(owned).HS.id, 19013) -- no usable fn: rank order wins
end)

test("ranking matches by itemID on non-English clients, name as fallback", function()
  local best = core.BestItems({ [929] = "Pocion de curacion", [118] = "Pocion menor", [5512] = "" })
  eq(best.POT.id, 929); eq(best.POT.name, "Pocion de curacion"); eq(best.HS.name, "Healthstone")
  eq(core.BestItems({ [99999] = "Wool Bandage" }).BAND.id, 99999) -- unknown Forever ID, English name
end)

test("new spell slot: mouseover on for harm/help into an empty slot, kept when replacing", function()
  eq(core.NewSlot(1, "A", "harm").mouseover, true); eq(core.NewSlot(1, "A", "help").mouseover, true)
  eq(core.NewSlot(1, "A", "other").mouseover, false)
  eq(core.NewSlot(1, "A", "harm", sp("B", false)).mouseover, false)
  eq(core.NewSlot(1, "A", "other", sp("B", true)).mouseover, true)
  eq(core.NewSlot(1, "A", "harm", it("HS")).mouseover, true) -- item was there: no spell value to keep
end)

test("trimming keeps item:<id> of the best item", function()
  local text = core.FitMacro({ slots = { normal = sp(long, true), shift = sp(long, true), alt = sp(long, true),
    ctrl = it("POT") } }, { POT = { id = 929 } })
  assert(text and text:find("item:929", 1, true), "lost item id: " .. tostring(text))
end)

test("grimorio /use with conditions on a kept item is reported lost", function()
  local _, lost = core.ImportGrimorio({ { name = "V", keys = { "V" }, body = "#showtooltip\n/use [nocombat] {HS}",
    spells = { { mod = "", name = "Healthstone", item = "HS" } } } }, function() end)
  eq(#lost, 1); eq(lost[1].text, "/use [nocombat] {HS}")
end)

test("key with no normal slot has no bare fallback", function()
  local text = core.MacroText({ slots = { shift = sp("S"), alt = sp("A", true) } })
  eq(text, T .. "/cast [mod:shift] S; [mod:alt,@mouseover,harm,nodead][mod:alt] A")
end)

test("empty bags fall back to the default item name", function()
  local best = core.BestItems({}, function() return true end)
  eq(next(best), nil)
  eq(core.MacroText({ slots = { normal = it("HS") } }, best), T .. "/use [nomod] Healthstone")
end)

test("item slot uses item:<id> of the best item", function()
  eq(core.MacroText({ slots = { shift = it("POT") } }, { POT = { id = 929, name = "Healing Potion" } }),
    T .. "/use [mod:shift,nomod:alt,nomod:ctrl] item:929")
end)

test("mixed spell and item key: exclusive conditions, no bare fallback", function()
  local best = { HS = { id = 5511, name = "Healthstone" } }
  eq(core.MacroText({ slots = { normal = sp("Fear", true), alt = it("BOMB"), shift = it("HS"),
    altshift = sp("Banish") } }, best),
    T .. "/use [mod:shift,nomod:alt,nomod:ctrl] item:5511; [mod:alt,nomod:shift,nomod:ctrl] Rough Copper Bomb\n"
      .. "/cast [mod:alt,mod:shift] Banish; [nomod,@mouseover,harm,nodead][nomod] Fear")
end)

test("FitMacro keeps item slots and passes best through", function()
  local text = core.FitMacro({ slots = { normal = it("BAND"), ctrl = sp("X") } }, { BAND = { id = 14530 } })
  eq(text, T .. "/use [nomod] item:14530\n/cast [mod:ctrl,nomod:alt] X")
end)

local function names(t) return function(id) return t[id] end end
local function ids(id, name) return { spellID = id, name = name, mouseover = true, kind = "harm" } end
test("repair renames a spell by spellID and keeps the other fields", function()
  local keys = { Q = { targetEnemy = true, slots = { normal = ids(1, "Old"), shift = it("HS") } } }
  local out, ch = core.Repair(keys, names({ [1] = "New" }))
  eq(out.Q.slots.normal.name, "New"); eq(out.Q.slots.normal.mouseover, true); eq(out.Q.targetEnemy, true)
  eq(out.Q.slots.shift.item, "HS"); eq(keys.Q.slots.normal.name, "Old") -- input untouched
  eq(#ch, 1); eq(ch[1].key, "Q"); eq(ch[1].slot, "normal"); eq(ch[1].kind, "renamed"); eq(ch[1].old, "Old"); eq(ch[1].new, "New")
end)
test("repair empties the slot of a removed spell", function()
  local out, ch = core.Repair({ E = { slots = { alt = ids(2, "Gone") } } }, names({}))
  eq(out.E.slots.alt, nil); eq(#ch, 1); eq(ch[1].kind, "removed"); eq(ch[1].old, "Gone"); eq(ch[1].new, nil)
end)
test("repair with nothing to change gives an empty list", function()
  local _, ch = core.Repair({ Q = { slots = { normal = ids(1, "A"), alt = it("POT") } } }, names({ [1] = "A" }))
  eq(#ch, 0)
end)
test("repair mixed: rename, removal and untouched slots across keys", function()
  local keys = { Q = { slots = { normal = ids(1, "A"), shift = ids(2, "B") } }, E = { slots = { ctrl = ids(3, "C") } } }
  local out, ch = core.Repair(keys, names({ [1] = "A", [2] = "B2" }))
  eq(out.Q.slots.normal.name, "A"); eq(out.Q.slots.shift.name, "B2"); eq(out.E.slots.ctrl, nil); eq(#ch, 2)
  local kinds = {}
  for _, c in ipairs(ch) do kinds[c.key .. c.slot] = c.kind end
  eq(kinds.Qshift, "renamed"); eq(kinds.Ectrl, "removed")
end)

test("SameClass lists other characters of the class, sorted, without me", function()
  local idx = { WARLOCK = { ["Me-R"] = {}, ["Zed-R"] = {}, ["Abe-R"] = {} }, MAGE = { ["Mia-R"] = {} } }
  local l = core.SameClass(idx, "WARLOCK", "Me-R")
  eq(#l, 2); eq(l[1], "Abe-R"); eq(l[2], "Zed-R")
  eq(#core.SameClass(idx, "PRIEST", "Me-R"), 0)
end)

test("ptBR keys exist in English with the same placeholders", function()
  local function load(loc)
    GetLocale = function() return loc end
    local ns = {}; assert(loadfile("FoilKeybinds/Locale.lua"))(nil, ns); return ns.L
  end
  local en, pt = load("enUS"), load("ptBR")
  eq(pt.TITLE, en.TITLE)
  local function ph(s) local t = {}; for p in s:gmatch("%%[sd]") do t[#t + 1] = p end; return table.concat(t) end
  for k, v in pairs(pt) do
    assert(en[k], "ptBR key missing in English: " .. k)
    eq(ph(v), ph(en[k]))
  end
  assert(pt.APPLY ~= en.APPLY)
  GetLocale = nil
end)

-- Fixture copied from GrimorioSetup Data.lua (Q, R, V, G, M3, Escape).
local GRIM = {
  { name = "Q Curses", keys = { "Q" }, body = [==[#showtooltip
/cast [mod:alt,mod:shift,@mouseover,harm][mod:alt,mod:shift] Curse of Tongues; [mod:shift,@mouseover,harm][mod:shift] Curse of Recklessness; [mod:alt,@mouseover,harm][mod:alt] Curse of the Elements; [@mouseover,harm][] Curse of Weakness]==], spells = { { mod = "", name = "Curse of Weakness", lvl = 4 }, { mod = "Shift", name = "Curse of Recklessness", lvl = 14 }, { mod = "Alt", name = "Curse of the Elements", lvl = 20 }, { mod = "Alt+Shift", name = "Curse of Tongues", lvl = 26 } } },
  { name = "R Dano", keys = { "R" }, body = [==[#showtooltip Shadow Bolt
/cast [nomod] Eureka!
/cast [mod:alt,mod:shift] Searing Pain; [mod:shift,@cursor] Rain of Fire; [mod:alt] Hellfire; Shadow Bolt]==], spells = { { mod = "Shift", name = "Rain of Fire", lvl = 20 }, { mod = "Alt", name = "Hellfire", lvl = 30 }, { mod = "Alt+Shift", name = "Searing Pain", lvl = 18 } } },
  { name = "G Pet", keys = { "G" }, body = [==[#showtooltip
/petfollow [nomod]
/petmoveto [mod:alt,nomod:shift,@cursor]
/petstay [mod:alt,mod:shift]
/stopmacro [mod:alt]
/cast [mod:shift,pet:Felhunter] Spell Lock; [mod:shift,pet:Succubus/Incubus] Seduction; [mod:shift,pet:Voidwalker] Sacrifice]==], spells = { { mod = "Shift", name = "Spell Lock", lvl = 10 } } },
  { name = "V Cura", keys = { "V" }, body = [==[#showtooltip
/cast [mod:alt,mod:shift,@mouseover,harm,nodead][mod:alt,mod:shift] Death Coil; [mod:shift] Life Tap; [mod:alt] Health Funnel
/stopmacro [mod]
/use [nocombat,@player] {BAND}
/stopmacro [nocombat]
/use {HS}
/use {POT}
/use Hearthstone]==], spells = { { mod = "", name = "Healthstone", lvl = 1, item = "HS" }, { mod = "Shift", name = "Life Tap", lvl = 6 }, { mod = "Alt", name = "Health Funnel", lvl = 12 }, { mod = "Alt+Shift", name = "Death Coil", lvl = 42 } } },
  { name = "M3 DoT", keys = { "3" }, body = [==[#showtooltip
/targetenemy [noharm][dead]
/petattack [harm,nodead]
/cast [mod:alt,mod:shift] Shadow Ward; [mod:shift] !Shoot; [mod:alt] Drain Life; [@mouseover,harm,nodead][] Corruption]==], spells = { { mod = "", name = "Corruption", lvl = 4 }, { mod = "Shift", name = "Shoot", lvl = 1 }, { mod = "Alt", name = "Drain Life", lvl = 14 }, { mod = "Alt+Shift", name = "Shadow Ward", lvl = 32 } } },
  { name = "Escape", keys = { "SHIFT-SPACE", "ALT-SPACE" }, body = [==[#showtooltip
/cast [mod:alt,@mouseover,harm,nodead][mod:alt] Curse of Exhaustion; Escape Artist]==], spells = { { mod = "Shift", name = "Escape Artist", lvl = 1 }, { mod = "Alt", name = "Curse of Exhaustion", lvl = 54 } } },
}
test("grimorio import maps spells, mouseover, extras, items and lists every loss", function()
  local known = { ["Curse of Weakness"] = 702, ["Shadow Bolt"] = 686 }
  local keys, lost = core.ImportGrimorio(GRIM, function(n) return known[n] end)
  eq(keys.G, nil)
  eq(core.MacroText(keys.Q), T .. "/cast [mod:alt,mod:shift,@mouseover,harm,nodead][mod:alt,mod:shift] Curse of Tongues; "
    .. "[mod:shift,@mouseover,harm,nodead][mod:shift] Curse of Recklessness; [mod:alt,@mouseover,harm,nodead][mod:alt] Curse of the Elements; "
    .. "[@mouseover,harm,nodead][] Curse of Weakness")
  eq(keys.Q.slots.normal.spellID, 702); eq(keys.Q.slots.shift.spellID, nil) -- unknown id keeps the name
  eq(core.MacroText(keys.R), T .. "/cast [mod:alt,mod:shift] Searing Pain; [mod:shift] Rain of Fire; [mod:alt] Hellfire; Shadow Bolt")
  eq(core.MacroText(keys.V, {}), T .. "/use [nomod] Healthstone\n"
    .. "/cast [mod:alt,mod:shift,@mouseover,harm,nodead][mod:alt,mod:shift] Death Coil; [mod:shift,nomod:alt,nomod:ctrl] Life Tap; [mod:alt,nomod:shift,nomod:ctrl] Health Funnel")
  eq(core.MacroText(keys["3"]), T .. "/targetenemy [noharm][dead]\n/petattack [harm,nodead]\n"
    .. "/cast [mod:alt,mod:shift] Shadow Ward; [mod:shift] Shoot; [mod:alt] Drain Life; [@mouseover,harm,nodead][] Corruption")
  eq(core.MacroText(keys.SPACE), T .. "/cast [mod:shift] Escape Artist; [mod:alt,@mouseover,harm,nodead][mod:alt] Curse of Exhaustion")
  for k, setup in pairs(keys) do assert(core.FitMacro(setup, {}), k .. " does not fit") end
  local got = {}
  for _, l in ipairs(lost) do got[#got + 1] = l.key .. ":" .. (l.skipped and "skipped" or l.text) end
  eq(table.concat(got, "|"), table.concat({ "R:[nomod] Eureka!", "R:[mod:shift,@cursor] Rain of Fire", "G Pet:skipped",
    "V:/stopmacro [mod]", "V:/use [nocombat,@player] {BAND}", "V:/stopmacro [nocombat]", "V:/use {POT}",
    "V:/use Hearthstone", "3:[mod:shift] !Shoot" }, "|"))
end)

test("DedupeSpells keeps one entry per name, highest rank, sorted", function()
  local out = core.DedupeSpells({
    { name = "Immolate", spellID = 3, rank = 3 }, { name = "Immolate", spellID = 1, rank = 1 },
    { name = "Corruption", spellID = 10 }, { name = "Corruption", spellID = 11 },
    { name = "Immolate", spellID = 2, rank = 2 }, { name = "Shadow Bolt", spellID = 20, rank = 1 },
  })
  eq(#out, 3)
  eq(out[1].name .. out[1].spellID, "Corruption11")
  eq(out[2].name .. out[2].spellID, "Immolate3")
  eq(out[3].name .. out[3].spellID, "Shadow Bolt20")
end)

test("FutureFrom: one entry per name, first-rank level, highest-rank id, learned and non-spells out", function()
  local out = core.FutureFrom({
    { id = 30, kind = "trainer", name = "Immolate", subText = "Rank 2", level = 10 },
    { id = 31, kind = "trainer", name = "Immolate", subText = "Rank 3", level = 20 },
    { id = 40, kind = "trainer", name = "Fear", subText = "Rank 1", level = 8 },
    { id = 41, kind = "trainer", name = "Fear", subText = "Rank 2", level = 32 },
    { id = 50, kind = "quest", name = "Summon Felhunter", level = 30 },
    { id = 60, kind = "trainer", name = "Shadow Bolt", subText = "Rank 5", level = 22 },
    { id = 70, kind = "trainer", name = "Torment", level = 10, petAbility = true },
    { id = 80, kind = "item", name = "Grimoire", level = 10 },
    { id = 90, kind = "weaponMaster", name = "Swords", level = 1 },
    { id = 99, kind = "trainer", level = 4 }, -- name not resolved
  }, { ["Shadow Bolt"] = true })
  local got = {}
  for _, s in ipairs(out) do got[#got + 1] = s.name .. ":" .. s.level .. ":" .. s.spellID end
  eq(table.concat(got, " "), "Fear:8:41 Immolate:10:31 Summon Felhunter:30:50")
  eq(out[1].future, true)
  eq(#core.FutureFrom(nil, {}), 0)
end)

test("repair keeps a future (unlearned) spell whose ID still has a name", function()
  local _, ch = core.Repair({ Q = { slots = { normal = ids(41, "Fear") } } }, names({ [41] = "Fear" }))
  eq(#ch, 0)
end)

test("macro name and colorized preview", function()
  eq(core.MacroName("Q"), "Q FK"); eq(core.MacroName("SPACE"), "Spc FK"); eq(core.MacroName("BUTTON4"), "M4 FK")
  eq(core.OldMacroName("Q"), "FKB Q")
  eq(core.ColorMacro("#showtooltip\n/cast [mod:shift] Wrack; Siphon Life"),
    "|cffffd100#showtooltip|r\n|cffffd100/cast|r |cff7fb8ff[mod:shift]|r Wrack; Siphon Life")
end)

test("rename plan: rename, keep new and drop our old, keep player's old, move backup keys", function()
  local exists = { ["FKB Q"] = true, ["FKB E"] = true, ["E FK"] = true, ["FKB R"] = true, ["R FK"] = true }
  local r, d, m = core.RenamePlan({ "Q", "E", "R", "SPACE" }, exists,
    { ["FKB Q"] = false, ["FKB E"] = false, ["FKB R"] = "old body", other = "x" })
  eq(#r, 1); eq(r[1].from, "FKB Q"); eq(r[1].to, "Q FK")
  eq(#d, 1); eq(d[1], "FKB E")
  eq(m["Q FK"], false); eq(m["E FK"], false); eq(m["R FK"], nil); eq(m["FKB R"], "old body"); eq(m.other, "x")
  eq(m["FKB Q"], nil); eq(m["FKB E"], nil)
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  print((ok and "ok   " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(("%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
