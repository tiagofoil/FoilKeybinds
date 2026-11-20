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

test("HEAL: potion in combat, bandage out, in one /use line", function()
  eq(core.MacroText({ slots = { normal = it("HEAL") } }, {}), T .. "/use [nomod,combat] Healing Potion; [nomod] Linen Bandage")
  local best = core.BestItems({ [929] = "Healing Potion", [3530] = "Wool Bandage" })
  eq(core.MacroText({ slots = { shift = it("HEAL") } }, best),
    T .. "/use [mod:shift,nomod:alt,nomod:ctrl,combat] item:929; [mod:shift,nomod:alt,nomod:ctrl] item:3530")
end)

test("EAT: food and drink out of combat, the drink on its own /use line", function()
  eq(core.MacroText({ slots = { normal = it("EAT") } }, {}), T .. "/use [nomod,nocombat] Tough Jerky\n/use [nomod,nocombat] Ice Cold Milk")
  local best = core.BestItems({ [4540] = "", [8079] = "", [159] = "" })
  eq(core.MacroText({ slots = { alt = it("EAT"), normal = sp("X") } }, best),
    T .. "/use [mod:alt,nomod:shift,nomod:ctrl,nocombat] item:4540\n/use [mod:alt,nomod:shift,nomod:ctrl,nocombat] item:8079\n/cast [nomod] X")
end)

test("HSPOT: the Healthstone when the bags hold one, else the best potion, else the default", function()
  local best = core.BestItems({ [5512] = "", [929] = "" })
  eq(best.HSPOT.id, 5512)
  eq(core.MacroText({ slots = { normal = it("HSPOT") } }, best), T .. "/use [nomod] item:5512")
  eq(core.MacroText({ slots = { ctrl = it("HSPOT") } }, core.BestItems({ [929] = "" })), T .. "/use [mod:ctrl,nomod:alt] item:929")
  eq(core.MacroText({ slots = { normal = it("HSPOT") } }, {}), T .. "/use [nomod] Healing Potion")
end)

test("FOOD and DRINK: IDs and names, best first, matched by ID", function()
  for _, c in ipairs({ "FOOD", "DRINK" }) do
    eq(#core.RANK_IDS[c], #core.RANKS[c]); assert(core.ITEM_DEFAULT[c], c)
  end
  eq(core.BestItems({ [159] = "", [8079] = "" }).DRINK.id, 8079) -- Crystal Water over Spring Water
  eq(core.BestItems({ [117] = "", [8950] = "Torta" }).FOOD.name, "Torta")
  local eat = core.BestItems({ [117] = "Tough Jerky", [159] = "Refreshing Spring Water" }).EAT
  eq(eat.id, 117); eq(eat.name, "Tough Jerky / Refreshing Spring Water")
end)

test("ItemChanges: a key with HEAL or EAT changes when a better part appears", function()
  local applied = { V = { slots = { shift = it("HEAL"), alt = it("EAT") } } }
  local old = core.BestItems({ [929] = "Healing Potion", [1251] = "Linen Bandage", [117] = "Tough Jerky" })
  local new = core.BestItems({ [1710] = "Greater Healing Potion", [929] = "Healing Potion", [1251] = "Linen Bandage",
    [117] = "Tough Jerky" })
  local ch = core.ItemChanges(old, new, applied)
  eq(#ch, 1); eq(ch[1].slot, "shift")
  eq(ch[1].from .. ">" .. ch[1].to, "Healing Potion / Linen Bandage>Greater Healing Potion / Linen Bandage")
  ch = core.ItemChanges(old, core.BestItems({ [929] = "", [1251] = "", [117] = "", [159] = "Refreshing Spring Water" }), applied)
  eq(#ch, 1); eq(ch[1].slot, "alt"); eq(ch[1].to, "Tough Jerky / Refreshing Spring Water")
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
test("can add step: a spell or a sequence under 9 steps; not empty, items, pet commands or a full sequence", function()
  local nine = { seq = {} }
  for i = 1, 9 do nine.seq[i] = step(i, "S" .. i) end
  eq(core.CanAddStep(step(1, "A")), true); eq(core.CanAddStep({ seq = { step(1, "A"), step(2, "B") } }), true)
  eq(core.CanAddStep(nil), false); eq(core.CanAddStep({ item = "HS" }), false)
  eq(core.CanAddStep({ pet = "follow" }), false); eq(core.CanAddStep(nine), false)
end)
test("cast with: extra spells fire first on their own line, only on that press", function()
  local sb = sp("Shadow Bolt"); sb.with = { step(9, "Eureka!") }
  eq(core.MacroText({ slots = { normal = sb } }), T .. "/cast [nomod] Eureka!\n/cast Shadow Bolt")
  local w = sp("Wrack"); w.with = { step(9, "Eureka!"), step(8, "Blood Fury") }
  eq(core.MacroText({ targetEnemy = true, slots = { normal = sp("N"), shift = w } }),
    T .. "/targetenemy [noharm][dead]\n/cast [mod:shift,nomod:alt,nomod:ctrl] Eureka!\n/cast [mod:shift,nomod:alt,nomod:ctrl] Blood Fury\n/cast [mod:shift] Wrack; N")
end)
test("cast with: up to 2 per spell or sequence, removed by place, kept through step edits and a new spell", function()
  local a = step(1, "A")
  eq(core.CanAddWith(a), true); eq(core.CanAddWith(nil), false); eq(core.CanAddWith({ item = "HS" }), false)
  local s = core.AddWith(core.AddWith(a, step(9, "E")), step(8, "F"))
  eq(#s.with, 2); eq(s.with[1].name, "E"); eq(a.with, nil); eq(core.CanAddWith(s), false)
  eq(#core.AddWith(s, step(7, "G")).with, 2)
  eq(core.RemoveWith(s, 1).with[1].name, "F"); eq(core.RemoveWith(core.RemoveWith(s, 1), 1).with, nil)
  local q = core.AddStep(s, step(2, "B"))
  eq(#q.with, 2); eq(core.CanAddWith(q), false)
  eq(#core.RemoveStep(q, 2).with, 2)
  eq(#core.NewSlot(3, "C", "harm", s).with, 2)
end)
test("repair: cast with spells are renamed or dropped, the slot stays", function()
  local s = ids(1, "A"); s.with = { ids(2, "E"), ids(3, "F") }
  local out, ch = core.Repair({ Q = { slots = { normal = s } } }, names({ [1] = "A", [2] = "E2", [3] = false }))
  local q = out.Q.slots.normal
  eq(q.name, "A"); eq(#q.with, 1); eq(q.with[1].name, "E2"); eq(#ch, 2)
  s = ids(1, "A"); s.with = { ids(3, "F") }
  eq(core.Repair({ Q = { slots = { normal = s } } }, names({ [1] = "A", [3] = false })).Q.slots.normal.with, nil)
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

-- Guide rules (v4).
test("bracket of a level: 1-19, 20-39, 40-60", function()
  for _, c in ipairs({ { 1, 1 }, { 19, 1 }, { 20, 2 }, { 39, 2 }, { 40, 3 }, { 60, 3 } }) do eq(core.BracketOf(c[1]), c[2]) end
  eq(#core.BRACKETS, 3); eq(core.BRACKETS[2][1], 20); eq(core.BRACKETS[2][2], 39)
end)

local function g(id, spent) return { groupID = id, spent = spent } end
test("spec guess: most points wins, ties keep game order, no points or no list gives the suggested spec", function()
  local id, mine = core.GuessSpec({ g(1, 5), g(2, 21), g(3, 0) }, 3)
  eq(id, 2); eq(mine, true)
  eq(core.GuessSpec({ g(1, 0), g(2, 7), g(3, 7) }, 1), 2)
  id, mine = core.GuessSpec({ g(1, 0), g(2, 0), g(3, 0) }, 3)
  eq(id, 3); eq(mine, false)
  eq(core.GuessSpec(nil, 3), 3); eq(core.GuessSpec({}, 3), 3)
  eq(core.GuessSpec({ g(1, nil), g(2, 4) }, 1), 2) -- a group the API answered nothing for counts 0
end)

local TPL = { Q = { normal = { spellID = 172, name = "Corruption" }, shift = { item = "POT" },
  alt = { spellID = 18265, name = "Siphon Life", talent = true } }, E = { ctrl = { spellID = 1454, name = "Life Tap" } } }
test("template to keys: localized names and kinds, unknown spells keep ID and English name, items stay, input unchanged", function()
  local pt = { [172] = { "Corrupção", "harm" }, [1454] = { "Toque da Vida", "other" } }
  local keys, missing = core.TemplateKeys(TPL, function(id) local s = pt[id]; if s then return s[1], s[2] end end)
  eq(#missing, 1); eq(missing[1], 18265) -- no name yet: the Use waits for the spell data
  local q = keys.Q.slots
  eq(q.normal.name, "Corrupção"); eq(q.normal.spellID, 172); eq(q.normal.kind, "harm"); eq(q.normal.mouseover, true)
  eq(q.shift.item, "POT"); eq(q.shift.spellID, nil)
  eq(q.alt.name, "Siphon Life"); eq(q.alt.spellID, 18265); eq(q.alt.kind, "other"); eq(q.alt.mouseover, false)
  eq(q.alt.talent, nil) -- data only, not a stored slot field
  eq(keys.E.slots.ctrl.name, "Toque da Vida"); eq(keys.E.slots.ctrl.mouseover, false)
  eq(TPL.Q.normal.name, "Corruption"); eq(TPL.Q.normal.kind, nil); eq(TPL.Q.alt.talent, true)
  q.shift.item = "HS"; eq(TPL.Q.shift.item, "POT") -- no shared tables
  eq(core.MacroText(keys.E), T .. "/cast [mod:ctrl] Toque da Vida")
end)

test("key of a spell: plain press first, then board order; any rank by name; sequences and cast with count", function()
  local keys = { Q = { slots = { shift = ids(172, "Corruption") } }, E = { slots = { normal = ids(7648, "Corruption") } } }
  local key, slot = core.KeyOf(keys, 172, "Corruption")
  eq(key, "E"); eq(slot, "normal") -- other rank on a plain press beats the same ID on Shift
  key, slot = core.KeyOf({ Q = keys.Q, ["1"] = { slots = { shift = ids(1, "Corruption") } } }, 172, "Corruption")
  eq(key, "1"); eq(slot, "shift") -- same slot: board order, the number row comes first
  key, slot = core.KeyOf({ R = { slots = { alt = { seq = { ids(1, "Shadow Bolt"), ids(172, "Corruption") } } } } }, 172, "Corruption")
  eq(key .. slot, "Ralt")
  local w = ids(686, "Shadow Bolt"); w.with = { ids(1454, "Life Tap") }
  key, slot = core.KeyOf({ ["3"] = { slots = { ctrl = w } } }, 1455, "Life Tap")
  eq(key .. slot, "3ctrl")
  eq(core.KeyOf({ Q = { slots = { normal = it("POT"), shift = { pet = "follow" } } } }, 172, "Corruption"), nil)
  eq(core.KeyOf({}, 172, "Corruption"), nil)
  eq(core.KeyOf({ Q = { slots = { normal = { name = "Fear" } } } }, nil, "Banish"), nil) -- no ID on either side is no match
  eq(core.KeyOf({ Q = { slots = { normal = ids(172, "Corrupção") } } }, 172, nil), "Q") -- by ID alone
end)

test("template for a spec and bracket: own template, shared bracket-1 fallback, nothing else", function()
  local own1, shared, own2 = { Q = {} }, { E = {} }, { R = {} }
  local class = { shared = shared, specs = { [10] = { templates = { [1] = own1, [2] = own2 } }, [11] = { templates = { [2] = own2 } } } }
  eq(core.TemplateFor(class, 10, 1), own1); eq(core.TemplateFor(class, 11, 1), shared)
  eq(core.TemplateFor(class, 11, 2), own2); eq(core.TemplateFor(class, 11, 3), nil)
  eq(core.TemplateFor({ specs = { [11] = { templates = {} } } }, 11, 1), nil); eq(core.TemplateFor(class, 99, 1), nil)
end)

-- A small valid class; each bad case changes one thing and expects exactly one problem naming it.
local function goodClass()
  local row = { spellID = 172, level = 4, en = "DoT.", ptBR = "DoT." }
  local function spec() return { name = "Affliction", priority = { core.Copy(row) },
    templates = { [2] = { Q = { normal = { spellID = 172, name = "Corruption" } } }, [3] = { Q = { shift = { item = "POT" } } } } } end
  return { suggested = 1, tested = false, shared = { E = { normal = { spellID = 686, name = "Shadow Bolt" } } },
    specs = { [1] = spec(), [2] = spec() } }
end
test("data check: a valid class has no problems", function()
  local p = core.CheckGuide(goodClass()); eq(#p, 0)
end)
local BAD = {
  { "key P: not a home key", function(c) c.specs[1].templates[2].P = { normal = { spellID = 1, name = "X" } } end },
  { "key 5: not a home key", function(c) c.specs[1].templates[2]["5"] = { normal = { spellID = 1, name = "X" } } end },
  { "key SPACE: not a home key", function(c) c.specs[1].templates[2].SPACE = { shift = { spellID = 1, name = "X" } } end },
  { "key BUTTON3: not a home key", function(c) c.specs[1].templates[3].BUTTON3 = { normal = { spellID = 1, name = "X" } } end },
  { "movement key", function(c) c.specs[1].templates[2].W = { shift = { spellID = 1, name = "X" } } end },
  { "unknown slot", function(c) c.specs[1].templates[2].Q.meta = { spellID = 1, name = "X" } end },
  { "unknown item", function(c) c.specs[1].templates[3].Q.shift.item = "FOOD" end },
  { "step 2: needs a spell ID and a name", function(c) c.specs[1].templates[2].Q.normal = { seq = { { spellID = 1, name = "A" }, { name = "B" } } } end },
  { "cast with", function(c) c.specs[1].templates[2].Q.normal.with = { { spellID = 9, name = "Blood Fury" } } end },
  { "pet command", function(c) c.specs[1].templates[2].Q.alt = { pet = "follow" } end },
  { "pet command", function(c) c.shared.E.alt = { petSpecial = true } end },
  { "needs a spell ID and a name", function(c) c.specs[1].templates[2].Q.normal.spellID = nil end },
  { "no en text", function(c) c.specs[2].priority[1].en = "" end },
  { "no ptBR text", function(c) c.specs[2].priority[1].ptBR = nil end },
  { "no learn level", function(c) c.specs[2].priority[1].level = nil end },
  { "no spell ID", function(c) c.specs[2].priority[1].spellID = nil end },
  { "no priority list", function(c) c.specs[2].priority = {} end },
  { "no template for bracket 3", function(c) c.specs[2].templates[3] = nil end },
  { "no template for bracket 1", function(c) c.shared = nil end }, -- both specs lose it: two problems
  { "no English name", function(c) c.specs[1].name = nil end },
  { "suggested spec", function(c) c.suggested = 99 end },
  { "macro over 230", function(c)
    local n = ("n"):rep(35) -- fits 255 after trims, not 230
    c.specs[1].templates[2].Q = { normal = { spellID = 1, name = n }, shift = { spellID = 2, name = n },
      ctrl = { spellID = 3, name = n }, alt = { spellID = 4, name = n }, altshift = { spellID = 5, name = n .. "nnn" } }
  end },
}
for _, b in ipairs(BAD) do
  test("data check catches: " .. b[1], function()
    local c = goodClass(); b[2](c)
    local p = core.CheckGuide(c)
    local want = b[1] == "no template for bracket 1" and 2 or 1
    assert(#p == want, ("want %d problem(s), got %d: %s"):format(want, #p, table.concat(p, " | ")))
    for _, s in ipairs(p) do assert(s:find(b[1], 1, true), s) end
  end)
end
test("macro over 230 is still a valid 255 macro (the check keeps headroom for pt-BR names)", function()
  local n = ("n"):rep(35)
  local setup = { slots = {} }
  for i, id in ipairs(core.SLOTS) do setup.slots[id] = sp(n .. (id == "altshift" and "nnn" or ""), true) end
  assert(core.FitMacro(setup, {}), "fits 255"); eq(core.FitMacro(setup, {}, nil, 230), nil)
end)

-- Data test: the gate that keeps a bad guide from shipping. Loads every class file the guide TOC lists,
-- runs the data check, then checks spell IDs against the Forever trainer fixture (tests/trainer_fixture.lua,
-- built by tools/make_trainer_fixture.lua). A priority row: its ID is a trainer spell of the class learned
-- at its level (a granted spell: at or below its bound). A template spell: learned by the bracket's top level.
-- Talent spells (talent = true) are not trainer spells: their level comes from a talent row of the class.
-- GENERAL: spells every class has from level 1, or an innate class spell, not in the trainer data
-- (Wand Shoot, Battle Stance).
-- PENDING (v6): classes not rebuilt on the home keys yet (tickets 02 to 04). Their data check problems are
-- counted, not failed; the trainer check still runs on them. Each ticket takes its classes out.
local GENERAL = { [5019] = 1, [2457] = 1 }
local PENDING = { DRUID = true, MAGE = true, PALADIN = true, PRIEST = true, SHAMAN = true }
local pending = 0
test("guide data: TOC matches the main addon, every class passes the data check and the trainer fixture", function()
  local toc = assert(io.open("FoilKeybinds_Guides/FoilKeybinds_Guides.toc")):read("*a")
  local main = assert(io.open("FoilKeybinds/FoilKeybinds.toc")):read("*a")
  eq(toc:match("## Interface:[^\n]*"), main:match("## Interface:[^\n]*"))
  assert(toc:find("## LoadOnDemand: 1", 1, true) and toc:find("## Dependencies: FoilKeybinds", 1, true), "TOC flags")
  FoilKeybindsGuides = nil
  local files = 0
  for file in toc:gmatch("([%w_]+%.lua)") do assert(loadfile("FoilKeybinds_Guides/" .. file))("FoilKeybinds_Guides", {}); files = files + 1 end
  assert(files > 0 and FoilKeybindsGuides, "no class files loaded")
  local fixture, p = dofile("tests/trainer_fixture.lua"), {}
  for CLASS, c in pairs(FoilKeybindsGuides) do
    local found = core.CheckGuide(c, CLASS)
    if PENDING[CLASS] then -- known misses until its v6 ticket lands; a class that passes must leave the list
      if #found == 0 then p[#p + 1] = CLASS .. " passes the data check now: take it out of PENDING" end
      pending = pending + #found
    else
      for _, s in ipairs(found) do p[#p + 1] = CLASS .. " " .. s end
    end
    local fx, talents = assert(fixture[CLASS], "unknown class " .. CLASS), {}
    local function bad(where, what) p[#p + 1] = CLASS .. " " .. where .. ": " .. what end
    for gid, spec in pairs(c.specs) do
      for i, r in ipairs(spec.priority) do
        local where = "spec " .. gid .. " row " .. i .. " (" .. tostring(r.spellID) .. ")"
        if r.talent then talents[r.spellID] = r.level
        elseif fx.granted[r.spellID] then
          if r.level > fx.granted[r.spellID] then bad(where, "granted spell is learned by " .. fx.granted[r.spellID]) end
        elseif fx.levels[r.spellID] ~= r.level then bad(where, "trainer level is " .. tostring(fx.levels[r.spellID])) end
      end
    end
    local function checkTemplate(where, t, b)
      local top = core.BRACKETS[b][2]
      for key, slots in pairs(t) do
        for id, slot in pairs(slots) do
          for _, s in ipairs(slot.seq or { slot }) do
            if s.spellID then
              local lvl = s.talent and talents[s.spellID]
                or not s.talent and (fx.levels[s.spellID] or fx.granted[s.spellID] or GENERAL[s.spellID])
              local at = where .. " key " .. key .. " " .. id .. " (" .. s.spellID .. ")"
              if not lvl then bad(at, s.talent and "talent spell with no talent row" or "not a trainer spell of the class")
              elseif lvl > top then bad(at, "learned at " .. lvl .. ", after the bracket") end
            end
          end
        end
      end
    end
    if c.shared then checkTemplate("shared bracket 1", c.shared, 1) end
    for gid, spec in pairs(c.specs) do
      for b, t in pairs(spec.templates) do checkTemplate("spec " .. gid .. " bracket " .. b, t, b) end
    end
  end
  table.sort(p)
  assert(#p == 0, #p .. " problem(s):\n     " .. table.concat(p, "\n     "))
  if pending > 0 then print(("note %d data check problem(s) in the classes still pending v6"):format(pending)) end
end)

-- Guide tab rules (v4 ticket 02).
local GCLASS = { suggested = 20, specs = { [10] = { name = "Ten" }, [20] = { name = "Twenty" }, [30] = { name = "Thirty" } } }
test("guide specs: game order and names, unknown groups dropped, no talent answer gives the data's specs", function()
  local l = core.GuideSpecs({
    { groupID = 30, displayName = "Trinta", orderIndex = 1, spent = 5 },
    { groupID = 99, displayName = "Other", orderIndex = 0, spent = 9 },
    { groupID = 10, orderIndex = 2 },
    { groupID = 20, displayName = "Vinte", orderIndex = 3, spent = 2 },
  }, GCLASS)
  eq(#l, 3)
  eq(l[1].groupID, 30); eq(l[1].name, "Trinta"); eq(l[1].spent, 5)
  eq(l[2].groupID, 10); eq(l[2].name, "Ten"); eq(l[2].spent, 0)
  eq(l[3].groupID, 20); eq(l[3].name, "Vinte")
  for _, groups in ipairs({ {}, { { groupID = 99, orderIndex = 0 } } }) do
    local f = core.GuideSpecs(groups, GCLASS)
    eq(#f, 3); eq(f[1].name, "Ten"); eq(f[2].name, "Twenty"); eq(f[3].groupID, 30); eq(f[3].spent, 0)
  end
  eq(#core.GuideSpecs(nil, GCLASS), 3)
end)

test("level-up line: only with a used template, only above the used and the told bracket", function()
  eq(core.LevelUpBracket(nil, 20), nil)
  eq(core.LevelUpBracket({ bracket = 1, told = 1 }, 19), nil)
  eq(core.LevelUpBracket({ bracket = 1, told = 1 }, 20), 2)
  eq(core.LevelUpBracket({ bracket = 1, told = 2 }, 21), nil) -- already told
  eq(core.LevelUpBracket({ bracket = 1, told = 2 }, 40), 3)
  eq(core.LevelUpBracket({ bracket = 3, told = 1 }, 45), nil) -- used the 40-60 layout already
  eq(core.LevelUpBracket({ bracket = 2 }, 40), 3)
end)

test("fit keys: a key that fits only without mouseover keeps it off, a key that never fits is left out", function()
  local long = ("x"):rep(56)
  local function big(n) local s = {}; for _, id in ipairs(core.SLOTS) do s[id] = sp(long .. id .. n, true) end; return { slots = s } end
  local tight = { slots = {} }
  for _, id in ipairs({ "normal", "shift", "alt" }) do tight.slots[id] = sp(("y"):rep(48) .. id, true) end
  local keys = { Q = { slots = { normal = sp("Corruption", true) } }, E = tight, R = big(1), ["1"] = big(2) }
  local dropped = core.FitKeys(keys, {})
  eq(#dropped, 2); eq(dropped[1], "1"); eq(dropped[2], "R")
  eq(keys.R, nil); eq(keys["1"], nil)
  eq(keys.Q.slots.normal.mouseover, true)
  local off = 0
  for _, s in pairs(keys.E.slots) do if not s.mouseover then off = off + 1 end end
  assert(off > 0, "no mouseover trimmed on E")
  assert(core.FitMacro(keys.E, {}), "E does not fit")
end)

test("key label: plain press is the key, a modifier goes first, key names from the locale", function()
  local labels = { SLOT_shift = "Shift", SLOT_altshift = "Alt+Shift", KEY_SPACE = "Espaço" }
  eq(core.KeyLabel("Q", "normal", labels), "Q")
  eq(core.KeyLabel("Q", "shift", labels), "Shift+Q")
  eq(core.KeyLabel("SPACE", "altshift", labels), "Alt+Shift+Espaço")
end)

test("saved keys: newest first, auto set skipped when already saved, only the newest autos stay", function()
  local list, k1, k2 = {}, { Q = { slots = { normal = sp("A") } } }, { Q = { slots = { normal = sp("B") } } }
  assert(core.PushSaved(list, { name = "mine", keys = k1 }))
  assert(not core.PushSaved(list, { name = "a", keys = core.Copy(k1), auto = true }), "auto copy of a saved set")
  assert(not core.PushSaved(list, { name = "e", keys = {}, auto = true }), "empty keys saved")
  for i = 1, core.MAX_AUTO + 2 do
    assert(core.PushSaved(list, { name = "auto" .. i, keys = { Q = { slots = { normal = sp("X" .. i) } } }, auto = true }))
  end
  assert(core.PushSaved(list, { name = "mine2", keys = k1 }), "a manual save always goes in")
  eq(list[1].name, "mine2"); eq(list[2].name, "auto" .. (core.MAX_AUTO + 2)); eq(list[#list].name, "mine")
  eq(#list, core.MAX_AUTO + 2)
  assert(core.Same(k2, { Q = { slots = { normal = sp("B") } } }) and not core.Same(k1, k2) and not core.Same(k1, {}))
end)

-- Wizard (v5).
test("meanings: the shared list in step order, a name and a why line in English and pt-BR", function()
  eq(table.concat(core.MEANINGS, " "), "main wand second cc dot burst items interrupt defense heal buff form pet utility")
  for _, loc in ipairs({ "enUS", "ptBR" }) do
    GetLocale = function() return loc end
    local ns = {}; assert(loadfile("FoilKeybinds/Locale.lua"))(nil, ns)
    for _, m in ipairs(core.MEANINGS) do -- rawget: pt-BR falls back to English, a missing one must fail
      assert(rawget(ns.L, "MEANING_" .. m) and rawget(ns.L, "WHY_" .. m), loc .. " misses " .. m)
    end
  end
  GetLocale = nil
end)

local sl = function(name) return { spellID = 1, name = name } end
local WT = { -- guide keys: two "dot" keys, an items group, a Shift-only group (may go on Space), a key off the home table
  ["1"] = { normal = sl("Kick") }, ["2"] = { normal = sl("Ward"), shift = sl("Ward2") }, Q = { normal = sl("Dot") },
  R = { normal = sl("Bolt"), shift = sl("Fire"), alt = sl("Rain") }, V = { normal = { item = "HSPOT" }, shift = { item = "HEAL" } },
  F = { shift = sl("Dot2") }, Z = { normal = sl("Extra") }, BUTTON5 = { normal = sl("Shoot") }, ["5"] = { normal = sl("Off") } }
test("wizard steps: meaning order, board order inside a meaning, n of a meaning, keys off the home table left out", function()
  local function steps(class)
    local l = {}
    for i, x in ipairs(core.WizardSteps(WT, class)) do l[i] = x.key .. ":" .. x.meaning .. ":" .. x.n .. "/" .. x.of end
    return table.concat(l, " ")
  end
  eq(steps("WARLOCK"), "BUTTON5:wand:1/1 Q:dot:1/2 F:dot:2/2 R:burst:1/1 V:items:1/1 1:interrupt:1/1 2:defense:1/1 Z:utility:1/1")
  eq(steps("WARRIOR"):sub(1, 22), "BUTTON5:second:1/1 Q:d")
end)

test("allowed keys: no W A S D, no plain Space for a group with a plain press, mouse buttons and Shift-only Space fine", function()
  for _, k in ipairs({ "W", "A", "S", "D" }) do local ok, why = core.Allowed(k, WT.F); eq(ok, false); eq(why, "move") end
  local ok, why = core.Allowed("SPACE", WT.R); eq(ok, false); eq(why, "space")
  eq(core.Allowed("SPACE", WT.F), true)
  eq(core.Allowed("BUTTON4", WT.R), true); eq(core.Allowed("E", WT.R), true)
  eq(select(2, core.Allowed("P", WT.R)), "board")
end)

test("pick: a free key moves the group, a taken key makes the two trade, blocked picks change nothing", function()
  local map = core.WizardMap(WT)
  for gk in pairs(WT) do eq(map[gk], gk) end
  local m = core.Pick(map, WT, "R", "E")
  eq(#m, 1); eq(m[1][1], "R"); eq(m[1][2], "E"); eq(map.R, "E")
  m = core.Pick(map, WT, "V", "E") -- R holds E: R goes to V's key
  eq(#m, 2); eq(m[1][1] .. m[1][2], "VE"); eq(m[2][1] .. m[2][2], "RV"); eq(map.V, "E"); eq(map.R, "V")
  eq(#core.Pick(map, WT, "V", "E"), 0) -- already there
  local before = core.Copy(map)
  local r, why = core.Pick(map, WT, "R", "SPACE"); eq(r, nil); eq(why, "space")
  core.Pick(map, WT, "F", "SPACE") -- Shift only: fine on Space
  r, why = core.Pick(map, WT, "F", "1") -- would push Main (plain press) onto Space
  eq(r, nil); eq(why, "space"); eq(map.F, "SPACE"); eq(map["1"], "1")
  eq(before.R, map.R)
end)

test("skip leaves a group out; picking it back onto a taken key leaves the holder out; build moves whole groups", function()
  local map = core.WizardMap(WT)
  core.Skip(map, "V"); eq(map.V, false)
  core.Pick(map, WT, "R", "E")
  local t = core.BuildTemplate(WT, map)
  eq(t.V, nil); eq(t.R, nil); eq(t.E, WT.R); eq(t["1"], WT["1"]); eq(t.Z, WT.Z)
  local n = 0; for _ in pairs(t.E) do n = n + 1 end; eq(n, 3) -- all of the group's slots
  local m = core.Pick(map, WT, "V", "E")
  eq(m[2][1], "R"); eq(m[2][2], false); eq(map.V, "E"); eq(map.R, false)
  eq(core.BuildTemplate(WT, {}).R, WT.R) -- no map entry: the guide's key
  eq(WT.R.normal.name, "Bolt")
end)

test("first pick map: saved picks replayed through Pick, one group per key even when a new range adds a group on a picked key", function()
  local old = { ["1"] = { normal = sl("Main") }, R = { normal = sl("Fear") } }
  local saved = core.WizardMap(old)
  core.Pick(saved, old, "R", "E") -- the 1-19 run moved crowd control to E (free there)
  local map = core.WizardMap(WT, saved) -- the new range has no E group... and one adds it:
  eq(map.R, "E")
  local WT2 = core.Copy(WT); WT2.E = { normal = sl("Tap") }
  map = core.WizardMap(WT2, saved)
  eq(map.R, "E"); eq(map.E, "R") -- the new E group took R's old key
  local seen = {}
  for gk, k in pairs(map) do if k then assert(not seen[k], "two groups on " .. k); seen[k] = gk end end
  map = core.WizardMap(WT, { V = false, Q = "SPACE", P = "E", F = "P" }) -- skip kept; Space with a plain press, unknown keys dropped
  eq(map.V, false); eq(map.Q, "Q"); eq(map.P, nil); eq(map.F, "F")
end)

test("saved picks merge: this run wins, older picks of other keys stay unless their key is taken now", function()
  local out = core.MergePicks({ T = "E", C = "BUTTON4", R = "Q" }, { R = "R", E = "E", ["1"] = false })
  eq(out.R, "R"); eq(out.E, "E"); eq(out["1"], false); eq(out.T, nil); eq(out.C, "BUTTON4")
  eq(core.MergePicks(nil, { R = "E" }).R, "E")
end)

-- Home keys (v6).
test("home keys: one meaning per key, BUTTON5 is the wand for casters only, keys off the table have none", function()
  eq(core.MeaningOf("BUTTON4", "WARRIOR"), "main"); eq(core.MeaningOf("E", "MAGE"), "cc"); eq(core.MeaningOf("R"), "burst")
  for _, c in ipairs({ "MAGE", "PRIEST", "WARLOCK" }) do eq(core.MeaningOf("BUTTON5", c), "wand") end
  for _, c in ipairs({ "WARRIOR", "ROGUE", "DRUID", "HUNTER", "PALADIN", "SHAMAN" }) do eq(core.MeaningOf("BUTTON5", c), "second") end
  for _, k in ipairs({ "5", "SPACE", "BUTTON3", "W" }) do eq(core.MeaningOf(k, "WARLOCK"), nil) end
  local n, MEANING = 0, {}
  for _, m in ipairs(core.MEANINGS) do MEANING[m] = true end
  for _, k in ipairs(core.BOARD) do
    local m = core.MeaningOf(k, "WARLOCK")
    if m then n = n + 1; assert(MEANING[m], k .. " has an unknown meaning " .. m) end
  end
  eq(n, 16)
end)

local SHOOT = { normal = { spellID = 5019, name = "Shoot" } }
test("data check: a caster needs Wand Shoot on BUTTON5 normal in every range, others do not", function()
  local c = goodClass()
  eq(#core.CheckGuide(c, "WARRIOR"), 0)
  local p = core.CheckGuide(c, "WARLOCK")
  eq(#p, 6) -- 2 specs x 3 ranges
  for _, x in ipairs(p) do assert(x:find("no Wand Shoot on BUTTON5", 1, true), x) end
  c.shared.BUTTON5, c.specs[1].templates[2].BUTTON5, c.specs[2].templates[2].BUTTON5 = SHOOT, SHOOT, SHOOT
  c.specs[1].templates[3].BUTTON5, c.specs[2].templates[3].BUTTON5 = SHOOT, SHOOT
  eq(#core.CheckGuide(c, "WARLOCK"), 0)
  c.specs[2].templates[3].BUTTON5 = { normal = { spellID = 1, name = "Fireball" }, shift = SHOOT.normal }
  p = core.CheckGuide(c, "PRIEST")
  eq(#p, 1); assert(p[1]:find("spec 2 bracket 3: no Wand Shoot", 1, true), p[1])
end)

local function step(id, name) return { spellID = id, name = name } end
local SEQ = { seq = { step(980, "Bane of Agony"), step(18265, "Siphon Life"), step(172, "Corruption") }, reset = { target = true, combat = true } }
test("sequences in templates: allowed, built in the stored shape with looked-up names, fit counted like the editor", function()
  local c = goodClass()
  c.specs[1].templates[2].BUTTON4 = { normal = SEQ, shift = step(704, "Curse of Recklessness") }
  eq(#core.CheckGuide(c), 0)
  local pt = { [980] = { "Agonia", "harm" }, [172] = { "Corrupção", "harm" } }
  local keys, missing = core.TemplateKeys({ BUTTON4 = { normal = SEQ } }, function(id) local s = pt[id]; if s then return s[1], s[2] end end)
  eq(#missing, 1); eq(missing[1], 18265)
  local s = keys.BUTTON4.slots.normal
  eq(#s.seq, 3); eq(s.seq[1].name, "Agonia"); eq(s.seq[1].spellID, 980); eq(s.seq[1].kind, "harm")
  eq(s.seq[2].name, "Siphon Life"); eq(s.seq[2].kind, "other"); eq(s.reset.target, true); eq(s.reset.combat, true)
  eq(core.MacroText(keys.BUTTON4), T .. "/castsequence [nomod] reset=target/combat Agonia, Siphon Life, Corrupção")
  s.reset.target = false; s.seq[1].name = "X"; eq(SEQ.reset.target, true); eq(SEQ.seq[1].name, "Bane of Agony") -- no shared tables
  local long = { seq = {}, reset = { target = true, combat = true } } -- 9 steps of 24 chars: over 230 as a sequence
  for i = 1, 9 do long.seq[i] = step(i, ("s"):rep(23) .. i) end
  c.specs[1].templates[2].BUTTON4 = { normal = long }
  local p = core.CheckGuide(c)
  eq(#p, 1); assert(p[1]:find("key BUTTON4: macro over 230", 1, true), p[1])
end)

test("macro steps: unknown sequence steps left out, one known step is a plain cast, none known keeps it all", function()
  local setup = { slots = { normal = core.Copy(SEQ), shift = sp("Fear") } }
  setup.slots.normal.with = { step(9, "Blood Fury") }
  local function knows(ids) return function(x) return ids[x.spellID] == true end end
  local out = core.KnownSteps(setup, knows({ [980] = true, [172] = true }))
  eq(#out.slots.normal.seq, 2); eq(out.slots.normal.seq[2].name, "Corruption"); eq(#setup.slots.normal.seq, 3)
  eq(out.slots.shift.name, "Fear")
  out = core.KnownSteps(setup, knows({ [172] = true }))
  eq(out.slots.normal.seq, nil); eq(out.slots.normal.name, "Corruption"); eq(out.slots.normal.with[1].name, "Blood Fury")
  out.slots.normal.with = nil
  eq(core.MacroText(out), T .. "/cast [mod:shift] Fear; Corruption")
  out = core.KnownSteps(setup, knows({}))
  eq(#out.slots.normal.seq, 3)
  eq(core.KnownSteps({ slots = { normal = sp("Fear") } }, knows({})).slots.normal.name, "Fear") -- plain spells untouched
end)

test("saved picks: dropped once when the version is old, kept after", function()
  eq(core.WizardPicks(nil), nil)
  local w = { seen = true, picks = { [11629] = { ["1"] = "2" } } } -- v5 save: no version
  eq(core.WizardPicks(w), nil); eq(w.picksVersion, core.PICKS_VERSION); eq(w.seen, true)
  w.picks = { [11629] = { BUTTON4 = "1" } }
  eq(core.WizardPicks(w)[11629].BUTTON4, "1")
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  print((ok and "ok   " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(("%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
