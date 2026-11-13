local _, ns = ...
local L = ns.L

local f = CreateFrame("Frame", "FoilKeybindsFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(520, 360); f:SetPoint("CENTER")
f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "FoilKeybindsFrame") -- Esc closes it
f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.title:SetPoint("TOP", 0, -6); f.title:SetText(L.TITLE)

local applyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
applyBtn:SetSize(140, 26); applyBtn:SetPoint("BOTTOMRIGHT", -16, 14); applyBtn:SetText(L.APPLY)
applyBtn:SetScript("OnClick", function() ns.Apply() end)

function FoilKeybinds_Toggle() f:SetShown(not f:IsShown()) end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= "FoilKeybinds" then return end
  FoilKeybindsDB = FoilKeybindsDB or {}
  FoilKeybindsDB.keys = FoilKeybindsDB.keys or {}
end)

-- /fkb toggles the window. /fkb set <KEY> <Spell> fills a key's normal slot until the editor exists.
SLASH_FOILKEYBINDS1 = "/fkb"
SlashCmdList.FOILKEYBINDS = function(msg)
  local key, spell = (msg or ""):match("^set%s+(%S+)%s+(.+)$")
  if key then
    key = key:upper()
    FoilKeybindsDB.keys[key] = { normal = spell }
    ns.Say(L.SET:format(key, spell))
  elseif msg == "apply" then ns.Apply()
  else FoilKeybinds_Toggle() end
end
