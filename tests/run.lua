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

test("command of slot inverts SlotOf", function()
  eq(core.CommandOf(1), "ACTIONBUTTON1"); eq(core.CommandOf(72), "MULTIACTIONBAR1BUTTON12")
  eq(core.CommandOf(171), "MULTIACTIONBAR7BUTTON3"); eq(core.CommandOf(100), nil)
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
  local again = { slots = {}, compact = true } -- over the limit, so the compact form
  for id, s in pairs(setup.slots) do again.slots[id] = sp(s.name, s.mouseover) end
  for _, id in ipairs(trimmed) do again.slots[id].mouseover = false end
  eq(core.MacroText(again), text)
end)

test("impossible setup errors naming the slot with the longest name", function()
  local setup = { slots = { normal = sp(long), shift = sp(long), alt = sp(long), altshift = sp(long),
    ctrl = sp(("y"):rep(70), true) } }
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

test("Forever IDs: new items rank in place, base Major stone above the middle talented one", function()
  eq(core.BestItems({ [14530] = "", [232433] = "" }).BAND.id, 232433) -- Dense Runecloth over Heavy Runecloth
  eq(core.BestItems({ [19012] = "", [9421] = "" }).HS.id, 9421) -- 1440 over 1320 on Forever
  eq(core.BestItems({ [241650] = "", [929] = "" }).POT.id, 929) -- plain potion before Discolored
  local noEng = function(id) return id ~= 16005 end -- Classic bomb needs Engineering
  eq(core.BestItems({ [16005] = "", [260817] = "" }, noEng).BOMB.id, 260817)
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

-- Repair lookup: name, false = removed, nil = not loaded yet. Missing from t means removed.
local function names(t) return function(id) if t[id] == nil then return false end return t[id] end end
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
/petfollow [nomod]\n/petmoveto [mod:alt,nomod:shift,@cursor]\n/petstay [mod:alt,mod:shift]\n/stopmacro [mod:alt]
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

test("G key: pet follow/moveto/stay plus pet special fits as compact exclusive macro", function()
  local text, len = core.FitMacro({ slots = { normal = { pet = "follow" }, alt = { pet = "moveto" },
    altshift = { pet = "stay" }, shift = { petSpecial = true } } }, nil, "WARLOCK")
  eq(text, T .. "/petstay [mod:alt,mod:shift]\n/petmoveto [mod:alt,nomod:shift,@cursor]\n/petfollow [nomod]\n"
    .. "/cast [mod:shift,nomod:alt,pet:Felhunter]Spell Lock;[mod:shift,nomod:alt,pet:Succubus/Incubus]Seduction;"
    .. "[mod:shift,nomod:alt,pet:Voidwalker]Sacrifice")
  assert(len <= 255, len)
end)

test("compact keeps exclusions that filled slots need", function()
  local long = string.rep("y", 60)
  local text = core.FitMacro({ slots = { ctrl = { pet = "stay" }, shift = sp(long), altshift = sp(long), alt = sp("A") } })
  eq(text, T .. "/petstay [mod:ctrl,nomod:alt]\n/cast [mod:alt,mod:shift]" .. long .. ";[mod:shift,nomod:alt,nomod:ctrl]"
    .. long .. ";[mod:alt,nomod:shift,nomod:ctrl]A")
end)

for _, c in ipairs({ "follow", "stay", "attack", "passive", "defensive" }) do
  test("pet " .. c .. " on shift", function()
    eq(core.MacroText({ slots = { shift = { pet = c } } }), T .. "/pet" .. c .. " [mod:shift,nomod:alt,nomod:ctrl]")
  end)
end
test("pet moveto always at cursor", function()
  eq(core.MacroText({ slots = { normal = { pet = "moveto" } } }), T .. "/petmoveto [nomod,@cursor]")
end)
test("pet command with a spell: spell gets exclusive condition, no bare fallback", function()
  eq(core.MacroText({ slots = { normal = sp("Shadow Bolt"), alt = { pet = "attack" } } }),
    T .. "/petattack [mod:alt,nomod:shift,nomod:ctrl]\n/cast [nomod] Shadow Bolt")
end)
test("pet special without a class table casts nothing", function()
  eq(core.MacroText({ slots = { shift = { petSpecial = true } } }, nil, "MAGE"), T .. "/cast ")
end)
test("FitMacro keeps pet slots and trims spell mouseover", function()
  local long = string.rep("x", 30)
  local setup = { slots = { normal = { pet = "follow" }, ctrl = { pet = "moveto" }, shift = sp(long, true),
    alt = sp(long, true), altshift = sp(long, true) } }
  local text, n, trimmed = core.FitMacro(setup)
  assert(text and n <= 255, "fits, got " .. tostring(n))
  assert(#trimmed > 0); eq(setup.slots.altshift.mouseover, true)
  assert(text:find("/petfollow [nomod]", 1, true) and text:find("/petmoveto [mod:ctrl,nomod:alt,@cursor]", 1, true), text)
end)

test("Repair ignores pet slots", function()
  local keys = { G = { slots = { normal = { pet = "follow" }, shift = { petSpecial = true } } } }
  local out, ch = core.Repair(keys, function() return nil end)
  eq(#ch, 0); eq(out.G.slots.normal.pet, "follow"); eq(out.G.slots.shift.petSpecial, true)
end)

test("cheat sheet column follows the macro clause order for all 8 modifier combos", function()
  local cases = { -- shift, alt, ctrl -> column
    { false, false, false, "normal" }, { true, false, false, "shift" }, { false, true, false, "alt" },
    { true, true, false, "altshift" }, { false, false, true, "ctrl" }, { true, false, true, "ctrl" },
    { false, true, true, "ctrl" }, { true, true, true, "altshift" }, -- [mod:alt,mod:shift] comes first, no nomod:ctrl
  }
  for _, c in ipairs(cases) do eq(core.ModColumn(c[1], c[2], c[3]), c[4]) end
  eq(core.ModColumn(nil, nil, nil), "normal") -- IsShiftKeyDown() and friends return nil when up
end)

test("SameMacro ignores line endings and trailing whitespace only", function()
  local m = "#showtooltip\n/cast Fear"
  eq(core.SameMacro(m, "#showtooltip\r\n/cast Fear\n"), true)
  eq(core.SameMacro(m, "#showtooltip \n/cast Fear  "), true)
  eq(core.SameMacro(m, "#showtooltip\n/cast Banish"), false)
  eq(core.SameMacro(nil, ""), true)
end)

test("settings merge: defaults for missing keys, saved values kept, unknown keys dropped", function()
  local s = core.MergeSettings(nil)
  for k, v in pairs(core.SETTING_DEFAULTS) do eq(s[k], v) end
  s = core.MergeSettings({ scale = 1.2, cheatLayout = "keyboard", chat = false, oldKey = 5 })
  eq(s.scale, 1.2); eq(s.cheatLayout, "keyboard"); eq(s.chat, false); eq(s.oldKey, nil)
  eq(s.cheatIcon, 24) -- added later: gets its default
  eq(core.MergeSettings({ cheatLayout = "cols" }).cheatLayout, "cols")
end)

test("settings merge: clamp, snap to step, wrong type and unknown choice fall back", function()
  local s = core.MergeSettings({ scale = 9, cheatScale = 0.1, keyIcon = 27, cheatBg = 42,
    cheatLock = "yes", textSize = "huge", cheatIcon = "big" })
  eq(s.scale, 1.5); eq(s.cheatScale, 0.6); eq(s.keyIcon, 28); eq(s.cheatBg, 40)
  eq(s.cheatLock, false); eq(s.textSize, "normal"); eq(s.cheatIcon, 24)
end)

test("Snap gives clean step values for slider text", function()
  local r = core.SETTING_RANGES.scale
  eq(core.Snap(1.1000000001, r), 1.1); eq(core.Snap(0.7 + 0.05 * 8, r), 1.1); eq(core.Snap(1.124, r), 1.1)
  eq(("%.2fx"):format(core.Snap(1.126, r)), "1.15x")
end)


test("repair: not loaded yet leaves the slot, removed still removes", function()
  local keys = { Q = { slots = { normal = ids(1, "A"), shift = ids(2, "B") } } }
  local out, ch = core.Repair(keys, function(id) if id == 2 then return false end end)
  eq(out.Q.slots.normal.name, "A"); eq(out.Q.slots.shift, nil); eq(#ch, 1); eq(ch[1].kind, "removed")
end)
test("repair fills a nil spellID from the name lookup, silently", function()
  local keys = { Q = { slots = { normal = { name = "Fear", kind = "harm" }, shift = { name = "Nope" } } } }
  local out, ch = core.Repair(keys, names({ [41] = "Fear" }), function(n) return n == "Fear" and 41 or nil end)
  eq(out.Q.slots.normal.spellID, 41); eq(out.Q.slots.shift.spellID, nil); eq(out.Q.slots.shift.name, "Nope"); eq(#ch, 0)
end)

test("Known: same rank, other rank by name, not known", function()
  local function knownID(id) return id == 5 end
  local learned = { Immolate = true }
  eq(core.Known(5, "Shadow Bolt", knownID, learned), true)
  eq(core.Known(9, "Immolate", knownID, learned), true) -- stored highest rank, rank 1 learned
  eq(core.Known(9, "Fear", knownID, learned), false)
  eq(core.Known(nil, "Immolate", knownID, learned), true)
  eq(core.Known(nil, nil, knownID, learned), false)
end)

test("ItemChanges: one entry per key and item slot that changed, sorted", function()
  local applied = { Q = { slots = { normal = it("POT"), shift = sp("X") } }, E = { slots = { alt = it("POT"), ctrl = it("HS") } },
    R = { slots = { normal = sp("Y") } } }
  local old = { POT = { id = 929, name = "Healing Potion" }, HS = { id = 5512, name = "Healthstone" } }
  local new = { POT = { id = 1710, name = "Greater Healing Potion" }, HS = { id = 5512, name = "Healthstone" } }
  local ch = core.ItemChanges(old, new, applied)
  eq(#ch, 2)
  eq(ch[1].key .. ch[1].slot .. ch[1].from .. ">" .. ch[1].to, "EaltHealing Potion>Greater Healing Potion")
  eq(ch[2].key .. ch[2].slot, "Qnormal")
  eq(#core.ItemChanges(new, new, applied), 0)
  local gone = core.ItemChanges(old, {}, { Q = { slots = { normal = it("HS") } } })
  eq(#gone, 1); eq(gone[1].from, "Healthstone"); eq(gone[1].to, nil)
end)

test("ManageStart: saved value wins, else ON only with applied keys", function()
  eq(core.ManageStart(nil, nil), false); eq(core.ManageStart(nil, {}), false)
  eq(core.ManageStart(nil, { Q = {} }), true)
  eq(core.ManageStart(false, { Q = {} }), false); eq(core.ManageStart(true, nil), true)
end)

local function seq(reset, ...) local l = {}; for i, n in ipairs({ ... }) do l[i] = sp(n) end; return { seq = l, reset = reset } end
local TC = { target = true, combat = true }
test("sequence on normal alone", function()
  eq(core.MacroText({ slots = { normal = seq(TC, "A", "B", "C") } }), T .. "/castsequence [nomod] reset=target/combat A, B, C")
end)
for _, c in ipairs({ { "shift", "mod:shift,nomod:alt,nomod:ctrl" }, { "alt", "mod:alt,nomod:shift,nomod:ctrl" },
  { "altshift", "mod:alt,mod:shift" }, { "ctrl", "mod:ctrl,nomod:alt" } }) do
  test("sequence on " .. c[1] .. " alone", function()
    eq(core.MacroText({ slots = { [c[1]] = seq(TC, "A", "B") } }), T .. "/castsequence [" .. c[2] .. "] reset=target/combat A, B")
  end)
end
test("sequence with spell slots: exclusive conditions, no bare fallback", function()
  eq(core.MacroText({ slots = { normal = sp("N", true), shift = seq(TC, "A", "B") } }),
    T .. "/castsequence [mod:shift,nomod:alt,nomod:ctrl] reset=target/combat A, B\n/cast [nomod,@mouseover,harm,nodead][nomod] N")
end)
test("sequence with an item slot", function()
  eq(core.MacroText({ slots = { normal = it("HS"), alt = seq(nil, "A", "B") } }, { HS = { id = 5512 } }),
    T .. "/use [nomod] item:5512\n/castsequence [mod:alt,nomod:shift,nomod:ctrl] A, B")
end)
test("two sequences: one line each, clause order", function()
  eq(core.MacroText({ slots = { normal = seq(nil, "A", "B"), altshift = seq(nil, "C", "D") } }),
    T .. "/castsequence [mod:alt,mod:shift] C, D\n/castsequence [nomod] A, B")
end)
test("sequence reset options", function()
  local function r(reset) return core.MacroText({ slots = { normal = seq(reset, "A", "B") } }) end
  eq(r({ target = true }), T .. "/castsequence [nomod] reset=target A, B")
  eq(r({ combat = true }), T .. "/castsequence [nomod] reset=combat A, B")
  eq(r({}), T .. "/castsequence [nomod] A, B")
  eq(r({ secs = 12 }), T .. "/castsequence [nomod] reset=12 A, B")
  eq(r({ target = true, combat = true, secs = 8 }), T .. "/castsequence [nomod] reset=target/combat/8 A, B")
end)
test("sequence fits, fits after trim on other slots, or is blocked naming the sequence slot", function()
  local text, n = core.FitMacro({ slots = { normal = seq(TC, "A", "B") } })
  eq(text, T .. "/castsequence [nomod] reset=target/combat A, B"); eq(n, #text)
  local l30 = ("x"):rep(30)
  local setup = { slots = { shift = seq(TC, l30, l30, l30), alt = sp(l30, true), normal = sp(l30, true) } }
  local t2, n2, trimmed = core.FitMacro(setup)
  assert(t2 and n2 <= 255, "fits after trim, got " .. tostring(n2)); assert(#trimmed > 0)
  local t3, n3, _, errSlot = core.FitMacro({ slots = { ctrl = seq(TC, l30, l30, l30, l30, l30, l30, l30), normal = sp(l30) } })
  eq(t3, nil); assert(n3 > 255); eq(errSlot, "ctrl")
end)
test("compact sequence drops spaces", function()
  local l = ("z"):rep(55)
  local text = core.FitMacro({ slots = { normal = seq({ target = true }, l, l), shift = sp(l), alt = sp("A") } })
  assert(text and text:find("/castsequence [nomod]reset=target " .. l .. "," .. l, 1, true), text)
end)

test("repair inside sequences: rename, remove, shrink to one, shrink to none, not loaded stays", function()
  local s = { seq = { ids(1, "A"), ids(2, "B"), ids(3, "C") }, reset = TC }
  local out, ch = core.Repair({ Q = { slots = { normal = s } } }, function(id) if id == 1 then return "A2" elseif id == 2 then return false end end)
  local q = out.Q.slots.normal
  eq(#q.seq, 2); eq(q.seq[1].name, "A2"); eq(q.seq[2].name, "C"); eq(q.reset.target, true)
  eq(#ch, 2); eq(ch[1].kind .. ch[1].pos, "renamed1"); eq(ch[2].kind .. ch[2].pos .. ch[2].old, "removed2B")
  out = core.Repair({ Q = { slots = { normal = { seq = { ids(1, "A"), ids(2, "B") }, reset = TC } } } }, names({ [1] = "A" }))
  q = out.Q.slots.normal
  eq(q.seq, nil); eq(q.name, "A"); eq(q.spellID, 1); eq(q.mouseover, false)
  out, ch = core.Repair({ Q = { slots = { normal = { seq = { ids(1, "A"), ids(2, "B") } } } } }, names({}))
  eq(out.Q.slots.normal, nil); eq(#ch, 2)
  out, ch = core.Repair({ Q = { slots = { normal = { seq = { { name = "F" }, ids(2, "B") } } } } }, function() end,
    function(n) return n == "F" and 9 or nil end)
  eq(out.Q.slots.normal.seq[1].spellID, 9); eq(#ch, 0)
end)

local function step(id, name) return { spellID = id, name = name, kind = "harm" } end
test("add step: plain spell becomes a two-step sequence, reset on target and combat", function()
  local s = core.AddStep({ spellID = 1, name = "A", kind = "harm", mouseover = true }, step(2, "B"))
  eq(#s.seq, 2); eq(s.seq[1].name, "A"); eq(s.seq[1].spellID, 1); eq(s.seq[2].name, "B")
  eq(s.seq[1].mouseover, nil); eq(s.reset.target, true); eq(s.reset.combat, true); eq(s.name, nil)
end)
test("add step: a sequence gets the spell at the end, its reset kept, input untouched", function()
  local old = { seq = { step(1, "A"), step(2, "B") }, reset = { secs = 8 } }
  local s = core.AddStep(old, step(3, "C"))
  eq(#s.seq, 3); eq(s.seq[3].name, "C"); eq(s.reset.secs, 8); eq(s.reset.target, nil)
  eq(#old.seq, 2)
end)
test("add step: 9 steps, an item or a pet command come back unchanged", function()
  local nine = { seq = {} }
  for i = 1, 9 do nine.seq[i] = step(i, "S" .. i) end
  eq(#core.AddStep(nine, step(10, "X")).seq, 9); eq(core.MAXSEQ, 9)
  eq(core.AddStep({ item = "HS" }, step(1, "A")).item, "HS")
  eq(core.AddStep({ pet = "follow" }, step(1, "A")).pet, "follow")
  eq(core.AddStep({ petSpecial = true }, step(1, "A")).seq, nil)
end)
local function order(s) local l = {}; for i, x in ipairs(s.seq) do l[i] = x.name end; return table.concat(l) end
test("move step: swaps with the neighbor, past either end unchanged, input untouched", function()
  local old = { seq = { step(1, "A"), step(2, "B"), step(3, "C") }, reset = TC }
  eq(order(core.MoveStep(old, 2, -1)), "BAC"); eq(order(core.MoveStep(old, 2, 1)), "ACB")
  eq(order(core.MoveStep(old, 1, -1)), "ABC"); eq(order(core.MoveStep(old, 3, 1)), "ABC")
  eq(order(old), "ABC"); eq(core.MoveStep(old, 1, 1).reset.target, true)
end)
test("remove step: keeps the order, one step left is a plain spell with mouseover off, input untouched", function()
  local old = { seq = { step(1, "A"), step(2, "B"), step(3, "C") }, reset = TC }
  local s = core.RemoveStep(old, 2)
  eq(order(s), "AC"); eq(s.reset.combat, true); eq(order(old), "ABC")
  local p = core.RemoveStep(s, 1)
  eq(p.seq, nil); eq(p.name, "C"); eq(p.spellID, 3); eq(p.kind, "harm"); eq(p.mouseover, false)
end)
test("column order: Normal, Shift, Ctrl, Alt, Alt+Shift; macro order unchanged", function()
  eq(table.concat(core.COLUMNS, " "), "normal shift ctrl alt altshift")
  eq(table.concat(core.SLOTS, " "), "altshift ctrl shift alt normal")
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  print((ok and "ok   " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(("%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
