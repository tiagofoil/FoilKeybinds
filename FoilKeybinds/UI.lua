local _, ns = ...
local L = ns.L

local f = CreateFrame("Frame", "FoilKeybindsFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(940, 560); f:SetPoint("CENTER")
f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "FoilKeybindsFrame") -- Esc closes it
f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.title:SetPoint("TOP", 0, -6); f.title:SetText(L.TITLE)

local applyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
applyBtn:SetSize(140, 26); applyBtn:SetPoint("BOTTOMRIGHT", -16, 14); applyBtn:SetText(L.APPLY)
applyBtn:SetScript("OnClick", function() ns.Apply() end)
local undoBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
undoBtn:SetSize(100, 26); undoBtn:SetPoint("RIGHT", applyBtn, "LEFT", -8, 0); undoBtn:SetText(L.UNDO)
undoBtn:SetScript("OnClick", function() ns.Undo() end)

local current, card, picker

local function setupOf(key)
  local keys = FoilKeybindsDB.keys
  keys[key] = keys[key] or { slots = {} }
  return keys[key]
end

-- Runs after every card change: trims mouseover into saved data, or reverts the change
-- with undo() when the macro cannot fit. Then redraws the card. slot = the slot the player
-- just changed (nil for key toggles): the error names it, falling back to the core's pick.
local function commit(undo, slot)
  local setup = setupOf(current)
  local text, n, trimmed, errSlot = ns.FitMacro(setup)
  card.msg:SetText("")
  if not text then
    undo()
    card.msg:SetText(L.TOO_LONG:format(n, ns.MAX, L["SLOT_" .. (slot or errSlot)]))
  else
    for _, id in ipairs(trimmed) do setup.slots[id].mouseover = false end
    if #trimmed > 0 then card.msg:SetText(L.TRIMMED) end
  end
  card:Refresh()
end

local function selectKey(key) current = key; picker:Hide(); card.msg:SetText(""); card:Refresh() end

-- Canvas: keys near WASD plus the mouse on a board inside a clipping view.
-- Drag empty space to pan, wheel to zoom. Board offset is kept in view units.
local view = CreateFrame("Frame", nil, f, "BackdropTemplate")
view:SetPoint("TOPLEFT", 12, -30); view:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", 572, 46)
view:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
view:SetBackdropColor(0.06, 0.04, 0.08, 1); view:SetBackdropBorderColor(0.3, 0.22, 0.38, 1)
view:SetClipsChildren(true); view:EnableMouse(true); view:EnableMouseWheel(true)
local board = CreateFrame("Frame", nil, view)
board:SetSize(640, 360)
local DEFAULT_ZOOM, DEFAULT_X, DEFAULT_Y = 0.85, 10, -12
local zoom, ox, oy = DEFAULT_ZOOM, DEFAULT_X, DEFAULT_Y
local function place()
  board:SetScale(zoom); board:ClearAllPoints(); board:SetPoint("TOPLEFT", view, "TOPLEFT", ox / zoom, oy / zoom)
end
place()
view:SetScript("OnMouseWheel", function(_, d) zoom = math.max(0.5, math.min(2, zoom + d * 0.1)); place() end)
view:SetScript("OnMouseDown", function(self)
  local x, y = GetCursorPosition(); local sc = self:GetEffectiveScale()
  local sx, sy, bx, by = x / sc, y / sc, ox, oy
  self:SetScript("OnUpdate", function()
    local cx, cy = GetCursorPosition()
    ox, oy = bx + cx / sc - sx, by + cy / sc - sy; place()
  end)
end)
view:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
view:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
resetBtn:SetSize(110, 26); resetBtn:SetPoint("BOTTOMLEFT", 12, 14); resetBtn:SetText(L.RESET_VIEW)
resetBtn:SetScript("OnClick", function() zoom, ox, oy = DEFAULT_ZOOM, DEFAULT_X, DEFAULT_Y; place() end)

local K, U = 64, 70 -- key size and grid step
-- { binding key, column, row [, width in units] }. move = shown but not editable (movement keys).
local LAYOUT = {
  { "1", 0, 0 }, { "2", 1, 0 }, { "3", 2, 0 }, { "4", 3, 0 }, { "5", 4, 0 },
  { "Q", 0.5, 1 }, { "W", 1.5, 1, move = true }, { "E", 2.5, 1 }, { "R", 3.5, 1 }, { "T", 4.5, 1 },
  { "A", 0.75, 2, move = true }, { "S", 1.75, 2, move = true }, { "D", 2.75, 2, move = true },
  { "F", 3.75, 2 }, { "G", 4.75, 2 },
  { "Z", 1.25, 3 }, { "X", 2.25, 3 }, { "C", 3.25, 3 }, { "V", 4.25, 3 },
  { "SPACE", 2, 4, 4 },
  -- mouse buttons (left/right click stay with the game)
  { "BUTTON3", 7.4, 0.6 }, { "BUTTON4", 6.6, 2.1 }, { "BUTTON5", 6.6, 3.1 },
}
local mouse = CreateFrame("Frame", nil, board, "BackdropTemplate")
mouse:SetSize(2 * U + 10, 4 * U); mouse:SetPoint("TOPLEFT", 6.85 * U, -0.2 * U)
mouse:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
mouse:SetBackdropColor(0.1, 0.07, 0.13, 1); mouse:SetBackdropBorderColor(0.3, 0.22, 0.38, 1)
mouse:SetFrameLevel(board:GetFrameLevel())

local keyButtons = {}
for _, k in ipairs(LAYOUT) do
  local key = k[1]
  local b = CreateFrame("Button", nil, board, "BackdropTemplate")
  b:SetSize(K + ((k[4] or 1) - 1) * U, K)
  b:SetPoint("TOPLEFT", k[2] * U, -k[3] * U); b:SetFrameLevel(mouse:GetFrameLevel() + 2)
  b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("TOP", 0, -8); b.label:SetText(L["KEY_" .. key] or key)
  if k.move then
    b:SetBackdropColor(0.09, 0.13, 0.11, 1); b:SetBackdropBorderColor(0.2, 0.3, 0.24, 1)
    b.label:SetTextColor(0.45, 0.6, 0.48); b:EnableMouse(false)
  else
    b:SetScript("OnClick", function() selectKey(key) end)
    b.icons = {}
    for i, id in ipairs(ns.SLOTS) do
      local ic = CreateFrame("Frame", nil, b)
      ic:SetSize(11, 11); ic:SetPoint("BOTTOMLEFT", 2 + (i - 1) * 12, 4); ic:EnableMouse(true)
      ic.tex = ic:CreateTexture(nil, "ARTWORK"); ic.tex:SetAllPoints()
      ic:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["SLOT_" .. id] .. ": " .. self.name)
        if not self.known then GameTooltip:AddLine(L.NOT_KNOWN, 0.6, 0.6, 0.6) end
        GameTooltip:Show()
      end)
      ic:SetScript("OnLeave", GameTooltip_Hide)
      ic:SetScript("OnMouseUp", function() selectKey(key) end) -- icon eats the click, forward it
      ic.slot = id; b.icons[i] = ic
    end
    keyButtons[key] = b
  end
end

-- Redraws every key: filled slots as icons (left to right, card order), selected key outlined.
local function refreshKeys()
  for key, b in pairs(keyButtons) do
    local setup = FoilKeybindsDB.keys[key]
    local filled = setup and next(setup.slots)
    b:SetBackdropColor(filled and 0.16 or 0.11, filled and 0.11 or 0.08, filled and 0.21 or 0.14, 1)
    if key == current then b:SetBackdropBorderColor(0.85, 0.68, 0.35, 1)
    else b:SetBackdropBorderColor(0.3, 0.22, 0.38, 1) end
    for _, ic in ipairs(b.icons) do -- fixed position per slot, same order as the card
      local s = setup and setup.slots[ic.slot]
      ic:SetShown(s ~= nil)
      if s then
        ic.name, ic.known = s.name, ns.IsKnown(s.spellID)
        ic.tex:SetTexture(ns.SpellIcon(s.spellID))
        ic.tex:SetDesaturated(not ic.known); ic:SetAlpha(ic.known and 1 or 0.4)
      end
    end
  end
end

-- Key card: 5 slots, each with a mouseover checkbox, plus the two key toggles.
card = CreateFrame("Frame", nil, f)
card:SetPoint("TOPLEFT", 588, -30); card:SetPoint("BOTTOMRIGHT", -14, 46)
card.label = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
card.label:SetPoint("TOPLEFT")
card.count = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
card.count:SetPoint("TOPRIGHT")
card.msg = card:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
card.msg:SetPoint("TOPLEFT", 0, -254); card.msg:SetPoint("RIGHT"); card.msg:SetJustifyH("LEFT")
local rows = {}
for i, id in ipairs(ns.SLOTS) do
  local r = {}
  local y = -24 - (i - 1) * 34
  r.mod = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.mod:SetPoint("TOPLEFT", 0, y - 8); r.mod:SetText(L["SLOT_" .. id])
  r.btn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
  r.btn:SetSize(170, 26); r.btn:SetPoint("TOPLEFT", 62, y)
  r.btn:SetScript("OnClick", function() picker:Open(id) end)
  r.icon = r.btn:CreateTexture(nil, "OVERLAY"); r.icon:SetSize(20, 20); r.icon:SetPoint("LEFT", 4, 0)
  r.mo = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
  r.mo:SetPoint("LEFT", r.btn, "RIGHT", 4, 0)
  r.mo.text:SetText(L.MOUSEOVER)
  r.mo:SetScript("OnClick", function(self)
    local s = setupOf(current).slots[id]
    if not s then return end
    local old = s.mouseover
    s.mouseover = self:GetChecked() and true or false
    commit(function() s.mouseover = old end, id)
  end)
  rows[id] = r
end
local function toggle(field, text, y)
  local c = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
  c:SetPoint("TOPLEFT", 0, y); c.text:SetText(text)
  c:SetScript("OnClick", function(self)
    local setup = setupOf(current)
    local old = setup[field]
    setup[field] = self:GetChecked() and true or false
    commit(function() setup[field] = old end)
  end)
  return c
end
card.target = toggle("targetEnemy", L.TARGET_ENEMY, -200)
card.pet = toggle("petAttack", L.PET_ATTACK, -226)

function card:Refresh()
  refreshKeys()
  if not current then
    self.label:SetText(L.PICK_KEY)
    for _, r in pairs(rows) do r.btn:Hide(); r.mo:Hide(); r.mod:Hide() end
    self.count:SetText("")
    self.target:Hide(); self.pet:Hide()
    return
  end
  local setup = setupOf(current)
  self.label:SetText(L.KEY:format(L["KEY_" .. current] or current))
  local _, n = ns.FitMacro(setup)
  self.count:SetText(n .. "/" .. ns.MAX)
  for id, r in pairs(rows) do
    local s = setup.slots[id]
    r.btn:Show(); r.mod:Show(); r.mo:Show()
    r.btn:SetText(s and s.name or L.EMPTY)
    r.icon:SetTexture(s and ns.SpellIcon(s.spellID) or nil)
    r.mo:SetChecked(s and s.mouseover or false); r.mo:SetEnabled(s ~= nil)
  end
  self.target:Show(); self.target:SetChecked(setup.targetEnemy or false)
  self.pet:Show(); self.pet:SetChecked(setup.petAttack or false)
end

-- Spell picker: learned spells, filtered by the search box, plus Clear.
local ROWS = 12
picker = CreateFrame("Frame", "FoilKeybindsPicker", f, "BasicFrameTemplateWithInset")
picker:SetSize(240, 380); picker:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0); picker:Hide()
picker.title = picker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
picker.title:SetPoint("TOP", 0, -6); picker.title:SetText(L.PICK_SPELL)
picker.search = CreateFrame("EditBox", nil, picker, "SearchBoxTemplate")
picker.search:SetSize(200, 20); picker.search:SetPoint("TOP", 0, -30)
picker.search:HookScript("OnTextChanged", function() picker.offset = 0; picker:Render() end)
picker.clear = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
picker.clear:SetSize(200, 22); picker.clear:SetPoint("BOTTOM", 0, 10); picker.clear:SetText(L.CLEAR)
picker.clear:SetScript("OnClick", function() picker:Choose(nil) end)
picker.rows = {}
for i = 1, ROWS do
  local b = CreateFrame("Button", nil, picker)
  b:SetSize(200, 24); b:SetPoint("TOP", 0, -56 - (i - 1) * 24)
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(20, 20); b.icon:SetPoint("LEFT")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("LEFT", b.icon, "RIGHT", 4, 0); b.text:SetJustifyH("LEFT")
  b:SetScript("OnClick", function(self) picker:Choose(self.spell) end)
  picker.rows[i] = b
end
picker.offset, picker.shown = 0, {}
picker:EnableMouseWheel(true)
picker:SetScript("OnMouseWheel", function(self, d)
  self.offset = math.max(0, math.min(self.offset - d * 3, #self.shown - ROWS)); self:Render()
end)

function picker:Open(slot)
  self.slot, self.offset, self.all = slot, 0, ns.LearnedSpells()
  self.search:SetText(""); self:Show(); self:Render()
end
function picker:Render()
  local q = (self.search:GetText() or ""):lower()
  self.shown = {}
  for _, s in ipairs(self.all or {}) do
    if q == "" or s.name:lower():find(q, 1, true) then self.shown[#self.shown + 1] = s end
  end
  for i, b in ipairs(self.rows) do
    local s = self.shown[self.offset + i]
    b.spell = s; b:SetShown(s ~= nil)
    if s then b.text:SetText(s.name); b.icon:SetTexture(ns.SpellIcon(s.spellID)) end
  end
end
function picker:Choose(s)
  local slots, slot = setupOf(current).slots, self.slot
  local old = slots[slot]
  if s then
    slots[slot] = { spellID = s.spellID, name = s.name, kind = ns.SpellKind(s.spellID),
      mouseover = old and old.mouseover or false }
  else
    slots[slot] = nil
  end
  self:Hide()
  commit(function() slots[slot] = old end, slot)
end

f:SetScript("OnShow", function() card:Refresh() end)

function FoilKeybinds_Toggle() f:SetShown(not f:IsShown()) end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= "FoilKeybinds" then return end
  FoilKeybindsDB = FoilKeybindsDB or {}
  FoilKeybindsDB.keys = FoilKeybindsDB.keys or {}
  for key, setup in pairs(FoilKeybindsDB.keys) do -- ticket 01 stored { normal = "Name" }, drop it
    if not setup.slots then FoilKeybindsDB.keys[key] = { slots = {} } end
  end
end)

-- /fkb toggles the window. /fkb set <KEY> <Spell> fills a key's normal slot from the spellbook.
SLASH_FOILKEYBINDS1 = "/fkb"
SlashCmdList.FOILKEYBINDS = function(msg)
  local key, spell = (msg or ""):match("^set%s+(%S+)%s+(.+)$")
  if key then
    key = key:upper()
    for _, s in ipairs(ns.LearnedSpells()) do
      if s.name:lower() == spell:lower() then
        setupOf(key).slots.normal = { spellID = s.spellID, name = s.name, kind = ns.SpellKind(s.spellID), mouseover = false }
        if f:IsShown() then card:Refresh() end
        return ns.Say(L.SET:format(key, s.name))
      end
    end
    ns.Say(L.UNKNOWN_SPELL:format(spell))
  elseif msg == "apply" then ns.Apply()
  elseif msg == "undo" then ns.Undo()
  else FoilKeybinds_Toggle() end
end
