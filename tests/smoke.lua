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
  SetCursor = function() end, ResetCursor = function() end, print = function() end, date = os.date,
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

-- Use, Apply, fight, then Undo (the bug of 2026-11-20): the own keys come back, and they were auto-saved.
click(L.GUIDE_PREVIEW); click(L.PREVIEW_USE)
local tpl = ns.Copy(db.keys)
local function isSaved(keys) for _, s in ipairs(db.saved or {}) do if same(keys, s.keys) then return true end end end
assert(isSaved(live), "own keys not auto-saved before Use")
for _, n in ipairs({ "GetNumMacros", "CreateMacro", "EditMacro", "GetBindingAction", "SetBinding", "SaveBindings",
  "GetCurrentBindingSet", "GetActionInfo", "GetActionText", "PickupAction", "PickupMacro", "PlaceAction", "ClearCursor",
  "GetBindingKey", "GetMacroInfo", "GetBindingName", "DeleteMacro", "GetCursorInfo", "PickupSpell", "PickupItem" }) do
  if not rawget(G, n) then G[n] = function() return 0 end end
end
G.GetNumMacros = function() return 0, 0 end
G.GetBindingAction, G.GetActionInfo, G.GetActionText, G.GetMacroInfo, G.GetCursorInfo = function() return "" end,
  function() end, function() end, function() end, function() end
G.CreateMacro = function() return 1 end
ns.Apply()
click(OKAY or "OK")
assert(db.copyUndoLive, "Apply did not run")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(same(live, db.keys) and db.copyUndo == nil, "undo after Apply lost the own keys")
assert(isSaved(tpl), "keys replaced by Undo not auto-saved")
-- After Apply the next replace starts a fresh backup: Undo goes one step back, not to older keys.
click(L.GUIDE_PREVIEW); click(L.PREVIEW_USE)
db.copyUndoLive = true -- as after an Apply
click("20-39"); click(L.GUIDE_PREVIEW); click(L.PREVIEW_USE)
G.SlashCmdList.FOILKEYBINDS("undo")
assert(same(tpl, db.keys), "undo after Apply then Use did not bring the applied keys back")
G.SlashCmdList.FOILKEYBINDS("undo") -- no backup left: keys stay
assert(same(tpl, db.keys))
-- Save, load, delete.
db.keys = ns.Copy(live)
local n0 = #db.saved
ns.SaveCurrent()
local mineSet = db.saved[1]
assert(#db.saved == n0 + 1 and not mineSet.auto and same(live, mineSet.keys), "save")
db.keys = ns.Copy(tpl)
ns.LoadSaved(mineSet)
assert(same(live, db.keys) and db.keys ~= mineSet.keys, "load")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(same(tpl, db.keys), "undo after load")
-- Named save, rename, overwrite; an empty name falls back to the date name.
ns.SaveCurrent("  Raid keys ")
assert(db.saved[1].name == "Raid keys" and not db.saved[1].auto, "named save")
ns.RenameSaved(db.saved[1], "")
assert(db.saved[1].name:find(L.SAVED_NAME:format(""), 1, true) == 1, "empty rename keeps a name")
ns.DeleteSaved(db.saved[1])
db.keys = ns.Copy(tpl)
ns.OverwriteSaved(mineSet)
assert(same(tpl, mineSet.keys) and mineSet.keys ~= db.keys, "overwrite")
-- A renamed auto set is the player's own: 11 more auto-saves do not drop it.
local auto = { name = "auto", keys = { Q = { slots = { normal = { spellID = 9 } } } }, auto = true }
table.insert(db.saved, 1, auto)
ns.RenameSaved(auto, "Keep me")
for i = 1, ns.MAX_AUTO + 1 do ns.PushSaved(db.saved, { name = "a" .. i, keys = { [tostring(i)] = { slots = { normal = { spellID = i } } } }, auto = true }) end
local kept
for _, s in ipairs(db.saved) do kept = kept or s == auto end
assert(kept and auto.name == "Keep me" and not auto.auto, "renamed auto set dropped")
ns.DeleteSaved(auto)
ns.DeleteSaved(mineSet)
for _, s in ipairs(db.saved) do assert(s ~= mineSet, "delete") end
db.keys, db.guide, db.applied = ns.Copy(live), nil, {} -- the stub Apply's macros are not in this world

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

-- Copy from with no pending undo: the level-up line stops,
-- Undo brings the layout's keys and its used template back.
db.copyUndo, db.copyUndoGuide = nil, nil
local used, mine = db.guide, ns.Copy(db.keys)
G.FoilKeybindsAccount.WARLOCK = { ["Other-Realm"] = { V = { slots = {} } } }
ns.CopyFrom("Other-Realm")
assert(db.guide == nil and db.keys.V, "copy kept the used template")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(db.guide == used and same(mine, db.keys) and lastSaid():find(L.COPY_UNDONE, 1, true), "copy undo")

-- Wizard (v5): first-open hint once, Build my layout, pick, swap, Back, Skip, blocked key, Use all
-- suggestions, Use (only a Use that went through saves), Undo, second run preselects, Cancel, cheat once.
local function showing(text) -- a frame was given exactly this text
  for _, t in ipairs(frames) do if rawget(t, "__text") == text then return true end end
end
local function label() return rawget(ns.keyCard.label, "__text") or "" end
local function sameKeys(a, b) -- empty setups do not count (the selected key gets one when the preview ends)
  local function filled(k) local o = {}; for key, s in pairs(k) do if next(s.slots) then o[key] = s end end; return o end
  return same(filled(a), filled(b))
end
local backup0 = ns.Copy(db.backup)
db.keys, db.guide, db.applied, db.wizard, db.copyUndo, db.copyUndoGuide, db.copyUndoLive, db.saved = {}, nil, {}, nil, nil, nil, nil, nil
ns.guide.hint = nil
G.SlashCmdList.FOILKEYBINDS("")
assert(f.tab == "guide" and ns.guide.hint == L.WIZARD_HINT and showing(L.WIZARD_HINT), "first /fkb: no Guide tab with the hint")
assert(db.wizard.seen, "seen flag not saved")
ns.guide.hint = nil -- the window closed (the stub does not run the Guide's OnHide hook)
G.SlashCmdList.FOILKEYBINDS("")
assert(f.tab == "keys" and ns.guide.hint == nil, "the hint came twice")
G.SlashCmdList.FOILKEYBINDS("assistente")
assert(f.tab == "guide" and ns.guide.hint == L.WIZARD_STEP1, "/fkb assistente")

-- A spec with no meanings map: the button does nothing, the note says why.
local aff = G.FoilKeybindsGuides.WARLOCK.specs[11629]
local meanings = aff.meanings
click("Affliction"); click("20-39")
aff.meanings = nil; ns.ShowGuide()
assert(showing(L.WIZARD_NO_MEANINGS), "no note for a spec without meanings")
click(L.WIZARD_BUILD)
assert(not ns.InPreview() and ns.WizardState() == nil, "wizard ran without meanings")
aff.meanings = meanings; ns.ShowGuide()

-- Affliction 20-39: 12 groups, step 1 is the Guide tab. The first step is the main attack on 1, selected.
db.keys = { Q = { slots = { normal = { spellID = 686, name = "Shadow Bolt", kind = "harm" } } } }
local own = ns.Copy(db.keys)
click(L.WIZARD_BUILD)
local w = ns.WizardState()
assert(w and ns.InPreview() and f.tab == "keys", "Build my layout did not start the wizard")
assert(#w.steps == 12 and w.steps[1].key == "1" and showing(L.WIZARD_STEP:format(2, 13)), "steps")
assert(showing(L.MEANING_main) and showing(L.WHY_main) and showing(L.WIZARD_ALL), "step bar texts")
assert(label():find(L.KEY:format("1"), 1, true), "current group not selected")
-- Pick a free key: the group moves, the board shows it, nothing live.
clickKey("Z")
assert(w.map["1"] == "Z" and showing(L.WIZARD_KEY:format("Z")) and label():find(L.KEY:format("Z"), 1, true), "pick")
assert(sameKeys(own, db.keys), "a pick wrote the live keys")
-- Next: the second attack 1 of 3 on 2. A taken key: the two trade, one chat line.
click(L.WIZARD_NEXT)
assert(w.i == 2 and showing(L.WIZARD_OF:format(1, 3)), "next")
clickKey("Z")
assert(w.map["2"] == "Z" and w.map["1"] == "2", "swap")
assert(lastSaid():find(L.WIZARD_MOVED:format(L.MEANING_dot, "Z") .. ", " .. L.WIZARD_MOVED:format(L.MEANING_main, "2"), 1, true), "swap line")
-- Back shows the main attack on its new key; Skip leaves the second attack out.
click(L.WIZARD_BACK)
assert(w.i == 1 and showing(L.WIZARD_KEY:format("2")), "back")
click(L.WIZARD_NEXT); click(L.WIZARD_SKIP)
assert(w.i == 3 and w.map["2"] == false, "skip")
click(L.WIZARD_BACK) -- a left-out group: no key selected on the board
assert(w.i == 2 and label() == L.PICK_KEY and showing(L.WIZARD_KEY_OUT), "skipped step highlights a key")
click(L.WIZARD_NEXT)
clickKey("W") -- movement keys: blocked, the bar says why
assert(w.map["3"] == "3" and showing(L.WIZARD_BLOCKED_move), "W not blocked")
-- Plain Space for a group with a plain press: nothing moves, the bar says why.
clickKey(L.KEY_SPACE)
assert(w.map["3"] == "3" and showing(L.WIZARD_BLOCKED_space), "blocked key")
click(L.WIZARD_ALL)
assert(w.i == 13 and ns.InPreview(), "use all suggestions ended the preview")
-- The done page lists the macros Apply will write, and the left-out group.
local function showingPart(part)
  for _, t in ipairs(frames) do local v = rawget(t, "__text"); if type(v) == "string" and v:find(part, 1, true) then return true end end
end
assert(showing(L.WIZARD_DONE) and showing(L.WIZARD_DONE_STEP) and showingPart("#showtooltip"), "no macros on the done page")
assert(showing(L.WIZARD_LEFT_OUT:format(L.MEANING_dot)), "left-out group not listed")
clickKey("T") -- past the last step: read only
assert(w.map.T == "T" and sameKeys(own, db.keys))
click(L.WIZARD_BACK); assert(w.i == 12 and showing(L.WIZARD_STEP:format(13, 13)), "back from the done page")
click(L.WIZARD_NEXT); assert(w.i == 13)
-- Use while spell names load: nothing saved, the preview stays.
local nameFn = G.C_Spell.GetSpellName
G.C_Spell.GetSpellName = function() end
click(L.PREVIEW_USE)
assert(ns.InPreview() and sameKeys(own, db.keys) and not db.wizard.picks and not db.wizard.cheatOnce, "a loading Use saved")
G.C_Spell.GetSpellName = nameFn
-- Use: the built layout is live (main attack on 2, second attack out), old keys auto-saved, picks saved.
click(L.PREVIEW_USE)
assert(not ns.InPreview() and ns.WizardState() == nil, "Use did not end the wizard")
assert(db.keys["2"].slots.normal.name == "CORRUPTION" and db.keys["1"] == nil
  and sameKeys({}, { Z = db.keys.Z }), "built layout not used")
assert(db.keys.Q.slots.normal.name == "DRAIN LIFE" and db.keys.V.slots.normal.item == "HSPOT", "a group lost its key")
assert(isSaved(own), "own keys not auto-saved")
assert(db.guide.wizard and db.guide.groupID == 11629 and db.guide.bracket == 2, "used template not marked")
local picks = db.wizard.picks[11629]
assert(picks["1"] == "2" and picks["2"] == false and picks.R == "R" and db.wizard.cheatOnce, "picks not saved")
assert(lastSaid():find(L.TEMPLATE_USED:format("Affliction", "20-39"), 1, true), "no use line")
G.SlashCmdList.FOILKEYBINDS("undo")
assert(sameKeys(own, db.keys), "undo after the wizard")
assert(db.wizard.cheatOnce == nil and ns.guide.hint == nil, "undo kept the cheat sheet flag, or Use kept the step 1 hint")

-- Second run, 40-60: the saved picks preselect every step. Cancel, leaving the tab and closing change nothing.
click("40-60"); click(L.WIZARD_BUILD)
w = ns.WizardState()
assert(w.saved and w.map["1"] == "2" and w.map["2"] == false and showing(L.WIZARD_ALL_MINE), "no preselected picks")
assert(showing(L.WIZARD_KEY:format("2")), "first step does not show the saved key")
clickKey("X")
click(L.PREVIEW_CANCEL)
assert(not ns.InPreview() and ns.WizardState() == nil and sameKeys(own, db.keys) and db.wizard.picks[11629]["1"] == "2", "cancel")
G.SlashCmdList.FOILKEYBINDS("guide"); click(L.WIZARD_BUILD); G.SlashCmdList.FOILKEYBINDS("config")
assert(ns.WizardState() == nil and not ns.InPreview(), "leaving the tab did not end the wizard")
G.SlashCmdList.FOILKEYBINDS("guide"); click(L.WIZARD_BUILD); f.__scripts.OnHide(f)
assert(ns.WizardState() == nil and not ns.InPreview() and sameKeys(own, db.keys), "closing the window did not end the wizard")

-- Use from the second run, then Apply: the cheat sheet opens once, the flag clears.
local cheat = {}
local toggle = ns.ToggleCheat
ns.ToggleCheat = function(v) cheat[#cheat + 1] = v end
G.SlashCmdList.FOILKEYBINDS("guide"); click(L.WIZARD_BUILD); click(L.WIZARD_ALL_MINE); click(L.PREVIEW_USE)
assert(db.keys["2"] and db.guide.bracket == 3 and db.wizard.cheatOnce, "second Use")
ns.Apply(); click(OKAY or "OK")
assert(#cheat == 1 and cheat[1] == true and db.wizard.cheatOnce == nil, "cheat sheet not shown once after Apply")
ns.Apply(); click(OKAY or "OK")
assert(#cheat == 1, "cheat sheet shown twice")
ns.ToggleCheat = toggle
-- Level-up line names /fkb wizard for a wizard layout (used 1-19 at level 25, told at 40).
click("1-19"); click(L.WIZARD_BUILD); click(L.WIZARD_ALL_MINE); click(L.PREVIEW_USE)
local n0 = #said
ev.__scripts.OnEvent(ev, "PLAYER_LEVEL_UP", 40) -- the item swap may add its own line after it
assert((said[n0 + 1] or ""):find(L.WIZARD_LEVELUP:format(40, "Affliction", "40-60"), 1, true), "no wizard level-up line")
db.keys, db.guide, db.applied, db.wizard, db.copyUndo, db.copyUndoGuide, db.copyUndoLive, db.saved = ns.Copy(live), nil, {}, nil, nil, nil, nil, nil
db.backup, ns.guide.hint = backup0, nil
print("smoke ok")
