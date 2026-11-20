-- Load smoke test: runs every addon file in TOC order against a stub WoW API, fires ADDON_LOADED,
-- opens the window, clicks a key and checks /fkb is registered, then runs the Guide tab end to end. Catches load-time errors (a nil
-- field, a missing local) that the syntax check and the Core tests cannot see.
-- Run from repo root: luajit tests/smoke.lua
-- ponytail: the stub answers every unknown call with a stub or 0, so it only proves the code runs.

local frames = {}
local function stub(kind)
  local t = { __kind = kind, __scripts = {} }
  frames[#frames + 1] = t
  return setmetatable(t, { __index = function(_, k)
    if k:find("^Create") or k:find("^Get%u%l*Texture$") or k == "GetFontString" or k == "GetParent" then
      return function() return stub(k) end
    elseif k == "SetScript" or k == "HookScript" then
      return function(self, name, fn) self.__scripts[name] = fn end
    elseif k == "SetText" then
      return function(self, v) rawset(self, "__text", v) end
    elseif k == "GetText" then return function(self) return rawget(self, "__text") or "" end
    elseif k == "GetEffectiveScale" or k == "GetScale" then return function() return 1 end
    elseif k:find("^Get") then return function() return 0 end
    elseif k:find("^Is") or k:find("^Has") then return function() return false end
    end
    return function() end
  end })
end

local G = setmetatable({}, { __index = function(_, k) return _G[k] end })
local env = {
  CreateFrame = function(kind, name) local f = stub(kind); if name then G[name] = f end; return f end,
  CreateFont = function() return stub("Font") end, CreateColor = function() return stub("Color") end,
  UIParent = stub("UIParent"), GameTooltip = stub("GameTooltip"), MenuUtil = stub("MenuUtil"),
  Enum = { UITextureSliceMode = { Stretched = 0, Tiled = 1 } },
  UISpecialFrames = {}, SlashCmdList = {}, tinsert = table.insert, wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
  strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end,
  GetCursorPosition = function() return 0, 0 end, InCombatLockdown = function() return false end,
  GetMacroIndexByName = function() return 0 end, UnitClass = function() return "Warlock", "WARLOCK" end,
  UnitName = function() return "Tester" end, GetRealmName = function() return "Realm" end,
  GetLocale = function() return "enUS" end, GameTooltip_Hide = function() end,
  SetCursor = function() end, ResetCursor = function() end, print = function() end,
}
-- Game API namespaces: every function exists and answers nothing.
local function api() return setmetatable({}, { __index = function() return function() end end }) end
for _, n in ipairs({ "C_Container", "C_Spell", "C_SpellBook", "C_Item", "C_Texture", "C_AddOns", "C_Timer" }) do env[n] = api() end
env.C_SpellBook.GetNumSpellBookSkillLines = function() return 0 end -- empty spellbook
env.Enum.SpellBookSpellBank = { Player = 0 }; env.Enum.SpellBookItemType = { Spell = 1 }
for k, v in pairs(env) do G[k] = v end
-- Any other global is nil, like an API this client does not have (the addon guards those).

local ns = {}
local toc = assert(io.open("FoilKeybinds/FoilKeybinds.toc")):read("*a")
for file in toc:gmatch("([%w_]+%.lua)") do
  local chunk = assert(loadfile("FoilKeybinds/" .. file))
  setfenv(chunk, G)
  local ok, err = pcall(chunk, "FoilKeybinds", ns)
  assert(ok, file .. ": " .. tostring(err))
end

-- The guide package is load on demand: nothing of it at login. The stub load API (loadGuides) runs its
-- files in the same world, each file with its own namespace, like the game does.
assert(rawget(G, "FoilKeybindsGuides") == nil, "guide data loaded at login")
local function loadGuides(name)
  assert(name == "FoilKeybinds_Guides", "loads " .. tostring(name))
  local gtoc = assert(io.open("FoilKeybinds_Guides/FoilKeybinds_Guides.toc")):read("*a")
  for file in gtoc:gmatch("([%w_]+%.lua)") do
    local chunk = assert(loadfile("FoilKeybinds_Guides/" .. file))
    setfenv(chunk, G)
    local ok, err = pcall(chunk, "FoilKeybinds_Guides", {})
    assert(ok, file .. ": " .. tostring(err))
  end
  return true
end

local f = assert(rawget(G, "FoilKeybindsFrame"), "main window not created")
f.__scripts.OnEvent(f, "ADDON_LOADED", "FoilKeybinds")
assert(rawget(G, "SlashCmdList").FOILKEYBINDS, "/fkb not registered")
-- A key with a cast-with spell on the plain press and a sequence on Shift.
G.FoilKeybindsDB.keys["3"] = { slots = {
  normal = { spellID = 1, name = "Corruption", kind = "harm", mouseover = true, with = { { spellID = 2, name = "Eureka!" } } },
  shift = { seq = { { spellID = 3, name = "A" }, { spellID = 4, name = "B" } }, reset = { target = true } },
} }
f.__scripts.OnShow(f)
local clicked
for _, t in ipairs(frames) do
  local label = rawget(t, "label")
  if label and rawget(label, "__text") == "3" and t.__scripts.OnClick then t.__scripts.OnClick(t); clicked = true end
end
assert(clicked, "key 3 not found")
G.SlashCmdList.FOILKEYBINDS("")
G.SlashCmdList.FOILKEYBINDS("undo")

-- Guide tab (v4): load, spec guess, picks, preview, cancel, use, undo, level-up line.
local L = ns.L
local said = {}
G.print = function(s) said[#said + 1] = s end
local function lastSaid() return said[#said] or "" end
local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local function click(text) -- the frame showing text that takes clicks
  for _, t in ipairs(frames) do
    if rawget(t, "__text") == text and t.__scripts.OnClick then return t.__scripts.OnClick(t) end
  end
  error("no button " .. text)
end
local function clickKey(k)
  for _, t in ipairs(frames) do
    local label = rawget(t, "label")
    if label and rawget(label, "__text") == k and t.__scripts.OnClick then return t.__scripts.OnClick(t) end
  end
  error("no key " .. k)
end
assert(same(ns.KEY_ORDER, ns.BOARD), "UI.lua LAYOUT and Core ns.BOARD drifted apart")

-- Missing package: a message, no error, tried again on the next open.
G.C_AddOns.LoadAddOn = function() return false, "MISSING" end
G.SlashCmdList.FOILKEYBINDS("guide")
assert(rawget(ns.guidePane.msg, "__text") == L.GUIDE_MISSING, "no missing-package message")
assert(ns.guide.specs == nil)

-- Talent points: Destruction has the most, so it is picked and "yours". Level 25: bracket 20-39.
G.UnitLevel = function() return 25 end
G.C_ClassTalents = { GetActiveConfigID = function() return 7 end }
local POINTS = { [11629] = 5, [11636] = 0, [11637] = 11 }
G.C_Traits = {
  GetConfigInfo = function(c) assert(c == 7); return { treeIDs = { 3 } } end,
  GetGroupDisplayInfoByTreeID = function(t)
    assert(t == 3)
    return { { groupID = 11637, displayName = "Destruction", orderIndex = 2 }, { groupID = 11629, displayName = "Affliction", orderIndex = 0 },
      { groupID = 11636, displayName = "Demonology", orderIndex = 1 } }
  end,
  GetGroupCurrencyInfo = function(c, ids) return { { currencyInfos = { { spent = POINTS[ids[1]] } } } } end,
}
G.C_AddOns.LoadAddOn = loadGuides
G.SlashCmdList.FOILKEYBINDS("guia")
assert(G.FoilKeybindsGuides and G.FoilKeybindsGuides.WARLOCK, "guide data not loaded on open")
assert(ns.guide.spec == 11637 and ns.guide.mine == 11637 and ns.guide.hasPoints, "spec guess")
assert(ns.guide.bracket == 2, "bracket guess")
assert(ns.guide.specs[1].groupID == 11629 and ns.guide.specs[3].groupID == 11637, "game order")

-- Pick Affliction 40-60. A key off the template is selected, so the preview picks its own first key.
click("Affliction")
click("40-60")
assert(ns.guide.spec == 11629 and ns.guide.bracket == 3, "picks")
clickKey("Z")
G.FoilKeybindsDB.keys.E = { slots = { normal = { name = "Life Tap", kind = "other" } } } -- no spell ID yet
local live = ns.Copy(G.FoilKeybindsDB.keys)
local data = ns.Copy(G.FoilKeybindsGuides.WARLOCK)
local liveTable = G.FoilKeybindsDB.keys

-- Preview: draws the template, writes nothing live (the slot view would fill E's ID if it read it).
G.C_Spell.GetSpellInfo = function() return { spellID = 999 } end
click(L.GUIDE_PREVIEW)
assert(ns.InPreview(), "no preview")
f.__scripts.OnShow(f)
for _, t in ipairs(frames) do if rawget(t, "label") and t.__scripts.OnEnter then t.__scripts.OnEnter(t) end end
clickKey("Q") -- read-only: no selection, no edit
assert(G.FoilKeybindsDB.keys == liveTable and same(live, G.FoilKeybindsDB.keys), "preview wrote the live keys")
assert(G.FoilKeybindsDB.keys["1"] == nil, "preview created a live key")
G.C_Spell.GetSpellInfo = function() end
click(L.PREVIEW_CANCEL)
assert(not ns.InPreview(), "cancel")
assert(same(live, G.FoilKeybindsDB.keys) and G.FoilKeybindsDB.keys["1"] == nil, "cancel changed the live keys")

-- Leaving the Keys tab cancels.
click(L.GUIDE_PREVIEW)
G.SlashCmdList.FOILKEYBINDS("config")
assert(not ns.InPreview(), "leaving the tab did not cancel")

-- Preview open: master switch and Reset all are off, /fkb apply, undo and reset do nothing.
G.SlashCmdList.FOILKEYBINDS("guide")
click(L.GUIDE_PREVIEW)
local db = G.FoilKeybindsDB
for _, cmd in ipairs({ "apply", "undo", "reset" }) do
  G.SlashCmdList.FOILKEYBINDS(cmd)
  assert(lastSaid() == L.PREVIEW_BUSY or lastSaid():find(L.PREVIEW_BUSY, 1, true), "/fkb " .. cmd .. " ran in a preview")
end
assert(ns.InPreview() and same(live, db.keys), "a slash command changed the preview or the keys")

-- Use with spell names not loaded yet: data requested, nothing saved, the preview stays for the next click.
local asked = {}
G.C_Spell.RequestLoadSpellData = function(id) asked[#asked + 1] = id end
click(L.PREVIEW_USE)
assert(lastSaid():find(L.TEMPLATE_LOADING, 1, true), "no loading line")
assert(#asked > 0 and ns.InPreview() and same(live, db.keys) and db.guide == nil, "used a layout without its names")

-- Names loaded (the client answers them, here upper case): template keys live with the names of now,
-- old keys in the undo slot, used template saved; Undo has its own line.
local names = {}
local function collect(t)
  if t.spellID and t.name then names[t.spellID] = t.name:upper() end
  for _, v in pairs(t) do if type(v) == "table" then collect(v) end end
end
collect(G.FoilKeybindsGuides.WARLOCK)
G.C_Spell.GetSpellName = function(id) return names[id] end
click(L.PREVIEW_USE)
assert(not ns.InPreview())
assert(db.keys["1"] and db.keys["1"].slots.normal.name == "CORRUPTION", "template not used with the loaded names")
assert(db.guide.groupID == 11629 and db.guide.bracket == 3 and db.guide.told == 3 and db.guide.name == "Affliction")
assert(lastSaid():find(L.TEMPLATE_USED:format("Affliction", "40-60"), 1, true), "no use line")
assert(same(data, G.FoilKeybindsGuides.WARLOCK), "the guide data changed")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(lastSaid():find(L.TEMPLATE_UNDONE, 1, true), "undo line")
assert(same(live, db.keys) and db.guide == nil and db.copyUndo == nil, "undo did not bring the old keys back")

-- Two layouts used before Apply: Undo still brings the player's own keys back, not the first layout.
click(L.GUIDE_PREVIEW); click(L.PREVIEW_USE)
click("20-39"); click(L.GUIDE_PREVIEW); click(L.PREVIEW_USE)
assert(db.guide.bracket == 2, "second layout not used")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(same(live, db.keys) and db.guide == nil and db.copyUndo == nil, "undo after two layouts lost the own keys")

-- Respec with the window open: the points are read again on SPELLS_CHANGED, the picks stay.
POINTS[11629], POINTS[11637] = 20, 0
f.__scripts.OnEvent(f, "SPELLS_CHANGED")
click("40-60")
assert(ns.guide.mine == 11629 and ns.guide.spec == 11629 and ns.guide.bracket == 3, "yours did not follow the respec")
-- One group's points failing keeps the list, names and order.
local cur = G.C_Traits.GetGroupCurrencyInfo
G.C_Traits.GetGroupCurrencyInfo = function(c, ids) if ids[1] == 11636 then error("no points") end return cur(c, ids) end
local specs = ns.ReadSpecs(G.FoilKeybindsGuides.WARLOCK)
assert(#specs == 3 and specs[1].groupID == 11629 and specs[1].spent == 20 and specs[2].spent == 0, "one failing group dropped the specs")
G.C_Traits.GetGroupCurrencyInfo = cur

-- Level-up line: 1-19 layout used at level 25 (bracket 2 already reached), told once at 40.
local ev
for _, t in ipairs(frames) do
  local fn = t.__scripts.OnEvent
  if fn and debug.getinfo(fn).source:find("Game.lua", 1, true) then ev = t end
end
click("1-19")
click(L.GUIDE_PREVIEW)
click(L.PREVIEW_USE)
assert(db.guide.bracket == 1 and db.guide.told == 2)
local n = #said
ev.__scripts.OnEvent(ev, "PLAYER_LEVEL_UP", 39)
assert(#said == n, "level-up line inside the bracket")
ev.__scripts.OnEvent(ev, "PLAYER_LEVEL_UP", 40)
assert(#said == n + 1 and lastSaid():find(L.GUIDE_LEVELUP:format(40, "Affliction", "40-60"), 1, true), "no level-up line")
ev.__scripts.OnEvent(ev, "PLAYER_LEVEL_UP", 41)
assert(#said == n + 1, "level-up line twice")

-- Copy from after the layout went live (Apply cleared the undo slot): the level-up line stops,
-- Undo brings the layout's keys and its used template back.
db.copyUndo, db.copyUndoGuide = nil, nil
local used, mine = db.guide, ns.Copy(db.keys)
G.FoilKeybindsAccount.WARLOCK = { ["Other-Realm"] = { V = { slots = {} } } }
ns.CopyFrom("Other-Realm")
assert(db.guide == nil and db.keys.V, "copy kept the used template")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(db.guide == used and same(mine, db.keys) and lastSaid():find(L.COPY_UNDONE, 1, true), "copy undo")
print("smoke ok")
