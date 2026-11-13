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

test("slot <-> command round trip", function()
  eq(core.SlotOf("ACTIONBUTTON1"), 1); eq(core.SlotOf("MULTIACTIONBAR1BUTTON12"), 72)
  eq(core.SlotOf("MULTIACTIONBAR7BUTTON3"), 171); eq(core.SlotOf("MOVEFORWARD"), nil); eq(core.SlotOf(nil), nil)
  for bar, base in pairs(core.BAR_BASE) do for n = 1, 12 do eq(core.CommandOf(base + n), bar .. n) end end
  eq(core.CommandOf(100), nil)
end)

test("first empty slot skips used ones, bar by bar", function()
  local slot, cmd = core.FirstEmptySlot(function(s) return s < 3 end)
  eq(slot, 3); eq(cmd, "ACTIONBUTTON3")
  slot, cmd = core.FirstEmptySlot(function(s) return s <= 12 end) -- main bar full, bar 1 is next
  eq(slot, 61); eq(cmd, "MULTIACTIONBAR1BUTTON1")
  eq(core.FirstEmptySlot(function() return true end), nil)
end)

local long = ("x"):rep(30)
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

local function it(cat) return { item = cat } end
test("ranking picks the best usable item per category", function()
  local owned = { ["Healthstone"] = 5511, ["Major Healthstone"] = 19013, ["Minor Healing Potion"] = 118,
    ["Healing Potion"] = 929, ["Linen Bandage"] = 1251 }
  local best = core.BestItems(owned, function(id) return id ~= 19013 end) -- Major not usable yet
  eq(best.HS.id, 5511); eq(best.HS.name, "Healthstone")
  eq(best.POT.id, 929); eq(best.BAND.id, 1251); eq(best.BOMB, nil)
  eq(core.BestItems(owned).HS.id, 19013) -- no usable fn: rank order wins
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

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  print((ok and "ok   " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(("%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
