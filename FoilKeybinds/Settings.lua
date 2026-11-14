-- Settings: one themed page of options (account-wide, ns.S = FoilKeybindsAccount.settings), built twice:
-- in our own window (gear button, /fkb config) and on a canvas in the game's Options > AddOns list.
-- Every change goes through ns.SetSetting, which checks, saves and applies it live.
-- No Settings.OpenToCategory: on WoW Forever the client refuses that call from addon code.
local _, ns = ...
local L, T = ns.L, ns.T

-- What a setting refreshes when it changes; keys not listed redraw the cheat sheet.
local APPLY = {
  scale = function(v) ns.SetMainScale(v) end,
  textSize = function(v) ns.SetTextSize(v) end,
  keyIcon = function(v) ns.SetKeyIconSize(v) end,
  cheatScale = function(v) ns.SetCheatScale(v) end,
  compartment = function() ns.ApplyCompartment() end,
  chat = function() end,
}

local pages = {} -- refresh function of each built page
function ns.RefreshSettings() for _, r in ipairs(pages) do r() end end

function ns.SetSetting(key, v)
  ns.S[key] = ns.CheckSetting(key, v)
  ;(APPLY[key] or ns.RefreshCheat)(ns.S[key])
  ns.RefreshSettings()
end

-- At ADDON_LOADED (UI.lua), after the merge. The cheat sheet applies its own scale at login.
function ns.ApplySettings()
  for _, k in ipairs({ "scale", "textSize", "keyIcon", "compartment" }) do APPLY[k](ns.S[k]) end
end

function ns.ResetSettings()
  for k, v in pairs(ns.SETTING_DEFAULTS) do ns.SetSetting(k, v) end
end

-- Addon compartment entry, registered at runtime so it can be turned off (a TOC
-- AddonCompartmentFunc cannot). Left click opens the editor, right click the settings.
local entry = {
  text = L.TITLE, icon = "Interface\\Icons\\INV_Misc_Key_03", notCheckable = true, registerForAnyClick = true,
  func = function(_, input)
    if input and input.buttonName == "RightButton" then ns.OpenSettings() else FoilKeybinds_Toggle() end
  end,
}
function ns.HasCompartment()
  local a = AddonCompartmentFrame
  return a and a.RegisterAddon and type(a.registeredAddons) == "table" or false
end
function ns.ApplyCompartment()
  if not ns.HasCompartment() then return end
  local a = AddonCompartmentFrame
  -- ponytail: hiding edits Blizzard's registeredAddons list (same as LibDBIcon); breaks if Blizzard renames it.
  for i, e in ipairs(a.registeredAddons) do
    if e == entry then
      if not ns.S.compartment then table.remove(a.registeredAddons, i); a:UpdateDisplay() end
      return
    end
  end
  if ns.S.compartment then a:RegisterAddon(entry) end
end

local COLW, GAP = 280, 36
local function pct(v) return ("%d%%"):format(v) end
local function px(v) return ("%d px"):format(v) end
local function times(v) return ("%.2fx"):format(v) end
local function choices(key, prefix)
  local out = {}
  for _, c in ipairs(ns.SETTING_CHOICES[key]) do out[#out + 1] = { c, L[prefix .. c] } end
  return out
end

-- Builds the page inside parent at (x, y). Returns its refresh function (run it OnShow).
local function build(parent, x, y)
  local page = CreateFrame("Frame", nil, parent)
  page:SetPoint("TOPLEFT", x, y); page:SetSize(COLW * 2 + GAP, 360)
  local controls, cx, cy = {}, 0, 0
  local function place(r, h) r:SetPoint("TOPLEFT", page, "TOPLEFT", cx, -cy); cy = cy + h end
  local function column(n) cx, cy = (n - 1) * (COLW + GAP), 0 end
  local function header(text)
    if cy > 0 then cy = cy + 12 end
    local t = ns.Text(page, "bold", 14, T.brass); t:SetText(text); place(t, 18)
    local rule = page:CreateTexture(nil, "ARTWORK"); rule:SetColorTexture(T.brass[1], T.brass[2], T.brass[3], 0.35)
    rule:SetSize(COLW, 1); place(rule, 10)
  end
  local function slider(key, label, fmt)
    local s = ns.Slider(page, COLW, label, ns.SETTING_RANGES[key], fmt)
    s.onChange = function(v) ns.SetSetting(key, v) end
    place(s, 42); controls[#controls + 1] = { s, key }
  end
  local function check(key, label, get, set)
    local c = ns.Check(page, label)
    c.Set = c.SetChecked
    c:SetScript("OnClick", function(self)
      local on = self:GetChecked() and true or false
      if set then set(on) else ns.SetSetting(key, on) end
    end)
    place(c, 24); controls[#controls + 1] = { c, key, get }
  end
  local function dropdown(key, label, list)
    local t = ns.Text(page, "body", 13); t:SetText(label); t:SetPoint("TOPLEFT", page, "TOPLEFT", cx, -(cy + 4))
    local d = ns.Dropdown(page, 150, list)
    d:SetPoint("TOPRIGHT", page, "TOPLEFT", cx + COLW, -cy); cy = cy + 32
    d.onChange = function(v) ns.SetSetting(key, v) end
    controls[#controls + 1] = { d, key }
  end
  local function button(text, accent, fn)
    local b = ns.Button(page, COLW, 24, text, accent)
    b:SetScript("OnClick", fn); place(b, 30)
  end

  column(1)
  header(L.SET_MAIN)
  slider("scale", L.SET_SCALE, times)
  dropdown("textSize", L.SET_TEXT, choices("textSize", "TEXT_"))
  slider("keyIcon", L.SET_KEYICON, px)
  header(L.SET_GENERAL)
  if ns.HasCompartment() then check("compartment", L.SET_COMPARTMENT) end
  check("chat", L.SET_CHAT)
  cy = cy + 8
  button(L.SET_RESETPOS, nil, function() ns.ResetCheatPosition() end)
  button(L.SET_RESET, T.blood, function() ns.ResetSettings() end)

  column(2)
  header(L.CHEAT_TITLE)
  check(nil, L.SET_SHOWCHEAT, ns.CheatShown, function(on) ns.ToggleCheat(on) end)
  dropdown("cheatLayout", L.SET_LAYOUT, choices("cheatLayout", "LAYOUT_"))
  slider("cheatScale", L.SET_SCALE, times)
  slider("cheatIcon", L.SET_ICON, px)
  slider("cheatBg", L.SET_BG, pct)
  check("cheatBorder", L.SET_BORDER)
  check("cheatLabels", L.SET_LABELS)
  check("cheatHideEmpty", L.SET_HIDEEMPTY)
  check("cheatHighlight", L.SET_HIGHLIGHT)
  check("cheatLock", L.SET_LOCK)

  local hint = ns.Text(page, "body", 12, T.muted)
  hint:SetPoint("TOPLEFT", page, "BOTTOMLEFT", 0, 4); hint:SetText(L.SET_HINT)

  local function refresh()
    if not ns.S then return end
    for _, c in ipairs(controls) do c[1]:Set(c[3] and c[3]() or ns.S[c[2]] or false) end
  end
  pages[#pages + 1] = refresh
  return refresh
end

-- Own window: opens next to whatever is on screen, so the main window and the cheat sheet
-- stay visible for the live preview.
local win = ns.Panel("FoilKeybindsSettings", UIParent, L.SETTINGS_TITLE)
win:SetSize(COLW * 2 + GAP + 32, 430); win:SetPoint("RIGHT", -40, 0); win:SetFrameStrata("HIGH")
win:SetClampedToScreen(true); win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
win:SetScript("OnDragStart", win.StartMoving); win:SetScript("OnDragStop", win.StopMovingOrSizing)
win:Hide()
tinsert(UISpecialFrames, "FoilKeybindsSettings") -- Esc closes it
win:SetScript("OnShow", build(win, 16, -42))

-- show nil toggles.
function ns.OpenSettings(show)
  if show == nil then show = not win:IsShown() end
  win:SetShown(show)
  if show then win:Raise() end
end

-- Options > AddOns: the same page on a themed canvas.
if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
  local canvas = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  canvas:Hide()
  ns.Skin(canvas, T.bg, T.line)
  local title = ns.Text(canvas, "display", 20, T.brass)
  title:SetPoint("TOPLEFT", 16, -12); title:SetText(L.TITLE)
  canvas:SetScript("OnShow", build(canvas, 16, -48))
  canvas.OnCommit, canvas.OnRefresh = function() end, function() end
  canvas.OnDefault = function() ns.ResetSettings() end
  Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(canvas, L.TITLE))
end
