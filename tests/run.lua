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

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  print((ok and "ok   " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(("%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
