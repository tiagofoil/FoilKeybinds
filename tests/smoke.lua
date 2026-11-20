-- Load smoke test: runs every addon file in TOC order against a stub WoW API, fires ADDON_LOADED,
-- opens the window, clicks a key and checks /fkb is registered. Catches load-time errors (a nil
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

-- The guide package (load on demand in game) loads in the same world, each file with its own namespace.
local gtoc = assert(io.open("FoilKeybinds_Guides/FoilKeybinds_Guides.toc")):read("*a")
for file in gtoc:gmatch("([%w_]+%.lua)") do
  local chunk = assert(loadfile("FoilKeybinds_Guides/" .. file))
  setfenv(chunk, G)
  local ok, err = pcall(chunk, "FoilKeybinds_Guides", {})
  assert(ok, file .. ": " .. tostring(err))
end
assert(rawget(G, "FoilKeybindsGuides") and G.FoilKeybindsGuides.WARLOCK, "guide data not loaded")

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
print("smoke ok")
