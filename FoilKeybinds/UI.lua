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
local undoBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
undoBtn:SetSize(100, 26); undoBtn:SetPoint("RIGHT", applyBtn, "LEFT", -8, 0); undoBtn:SetText(L.UNDO)
undoBtn:SetScript("OnClick", function() ns.Undo() end)

local function setupOf(key)
  local keys = FoilKeybindsDB.keys
  keys[key] = keys[key] or { slots = {} }
  return keys[key]
end

-- Runs after every card change: trims mouseover into saved data, or reverts the change
-- with undo() when the macro cannot fit. Then redraws the card.
local function commit(undo)
  local setup = setupOf(current)
  local text, n, trimmed, errSlot = ns.FitMacro(setup)
  card.msg:SetText("")
  if not text then
    undo()
    card.msg:SetText(L.TOO_LONG:format(n, ns.MAX, L["SLOT_" .. errSlot]))
  else
    for _, id in ipairs(trimmed) do setup.slots[id].mouseover = false end
    if #trimmed > 0 then card.msg:SetText(L.TRIMMED) end
  end
  card:Refresh()
end

-- Key list. ponytail: fixed keys near WASD; ticket 05 replaces this with the canvas.
local KEYS = { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "T", "G", "Z", "X", "C", "V", "B" }
local current, card, picker
for i, key in ipairs(KEYS) do
  local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  b:SetSize(36, 24); b:SetPoint("TOPLEFT", 14 + ((i - 1) % 4) * 38, -32 - math.floor((i - 1) / 4) * 26)
  b:SetText(key)
  b:SetScript("OnClick", function() current = key; picker:Hide(); card.msg:SetText(""); card:Refresh() end)
end

-- Key card: 5 slots, each with a mouseover checkbox, plus the two key toggles.
card = CreateFrame("Frame", nil, f)
card:SetPoint("TOPLEFT", 180, -30); card:SetPoint("BOTTOMRIGHT", -14, 46)
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
    commit(function() s.mouseover = old end)
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
  if not current then
    self.label:SetText(L.PICK_KEY)
    for _, r in pairs(rows) do r.btn:Hide(); r.mo:Hide(); r.mod:Hide() end
    self.count:SetText("")
    self.target:Hide(); self.pet:Hide()
    return
  end
  local setup = setupOf(current)
  self.label:SetText(L.KEY:format(current))
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
  commit(function() slots[slot] = old end)
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
