local _, ns = ...
local L = ns.L
local T = ns.T

local f = ns.Panel("FoilKeybindsFrame", UIParent, L.TITLE)
f:SetSize(940, 560); f:SetPoint("CENTER")
f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "FoilKeybindsFrame") -- Esc closes it
function ns.SetMainScale(v) f:SetScale(v) end

-- Gear in the title bar, left of the close button: opens the settings window.
do
  local gear = CreateFrame("Button", nil, f)
  gear:SetSize(26, 26); gear:SetPoint("RIGHT", f.close, "LEFT", 0, 0)
  local tex = gear:CreateTexture(nil, "ARTWORK"); tex:SetSize(16, 16); tex:SetPoint("CENTER")
  local atlas = C_Texture and C_Texture.GetAtlasInfo and (C_Texture.GetAtlasInfo("QuestLog-icon-setting") and "QuestLog-icon-setting"
    or C_Texture.GetAtlasInfo("GM-icon-settings") and "GM-icon-settings")
  if atlas then tex:SetAtlas(atlas) else tex:SetTexture("Interface\\Buttons\\UI-OptionsButton") end
  tex:SetDesaturated(true); tex:SetVertexColor(unpack(T.muted))
  gear:SetScript("OnEnter", function(self)
    tex:SetVertexColor(unpack(T.brass))
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText(L.SETTINGS); GameTooltip:Show()
  end)
  gear:SetScript("OnLeave", function() tex:SetVertexColor(unpack(T.muted)); GameTooltip:Hide() end)
  gear:SetScript("OnClick", function() ns.OpenSettings() end)
end

local applyBtn = ns.Button(f, 140, 26, L.APPLY, T.fel)
applyBtn:SetPoint("BOTTOMRIGHT", -16, 14)
applyBtn:SetScript("OnClick", function() ns.Apply() end)
local undoBtn = ns.Button(f, 100, 26, L.UNDO)
undoBtn:SetPoint("RIGHT", applyBtn, "LEFT", -8, 0)
undoBtn:SetScript("OnClick", function() ns.Undo() end)

local copyBtn = ns.Button(f, 120, 26, L.COPY_FROM)
copyBtn:SetPoint("RIGHT", undoBtn, "LEFT", -8, 0)
copyBtn:SetScript("OnClick", function(self)
  local me, class = ns.Me()
  local list = ns.SameClass(FoilKeybindsAccount, class, me)
  if #list == 0 then return ns.Say(L.COPY_NONE) end
  MenuUtil.CreateContextMenu(self, function(_, root)
    for _, name in ipairs(list) do root:CreateButton(name, function() ns.CopyFrom(name) end) end
  end)
end)

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
  local text, n, trimmed, errSlot = ns.FitMacro(setup, ns.best)
  card.msg:SetText("")
  if not text then
    undo()
    local where = slot or errSlot
    card.msg:SetText(where and L.TOO_LONG:format(n, ns.MAX, L["SLOT_" .. where]) or L.TOO_LONG_ANY:format(n, ns.MAX))
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
view:SetPoint("TOPLEFT", 12, -38); view:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", 572, 46)
ns.Skin(view, { T.panel[1], T.panel[2], T.panel[3], 0.7 }, T.line)
do -- inner shade at the top and bottom edges, like the page's inset shadow
  local top = ns.Gradient(view, { 0, 0, 0, 0.45 }, { 0, 0, 0, 0 })
  top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(40)
  local bot = ns.Gradient(view, { 0, 0, 0, 0 }, { 0, 0, 0, 0.45 })
  bot:SetPoint("BOTTOMLEFT", 1, 1); bot:SetPoint("BOTTOMRIGHT", -1, 1); bot:SetHeight(40)
end
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
local resetBtn = ns.Button(f, 110, 26, L.RESET_VIEW)
resetBtn:SetPoint("BOTTOMLEFT", 12, 14)
resetBtn:SetScript("OnClick", function() zoom, ox, oy = DEFAULT_ZOOM, DEFAULT_X, DEFAULT_Y; place() end)
local cheatBtn = ns.Button(f, 110, 26, L.CHEAT_TITLE)
cheatBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
cheatBtn:SetScript("OnClick", function() ns.ToggleCheat() end)

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
ns.LAYOUT = LAYOUT -- the cheat sheet's mini keyboard uses the same places
local mouse = CreateFrame("Frame", nil, board, "BackdropTemplate")
mouse:SetSize(2 * U + 10, 4 * U); mouse:SetPoint("TOPLEFT", 6.85 * U, -0.2 * U)
ns.Skin(mouse, T.keyTop, T.line, 2)
mouse:SetFrameLevel(board:GetFrameLevel())

-- Link from the selected key toward the card. Drawn above the keys and the mouse so nothing
-- hides it; the view still clips it at its right edge, so it never crosses the panel chrome.
local links = CreateFrame("Frame", nil, board)
links:SetAllPoints(); links:SetFrameLevel(mouse:GetFrameLevel() + 6)
local linkGlow, linkCore = links:CreateLine(nil, "ARTWORK"), links:CreateLine(nil, "OVERLAY")
linkGlow:SetThickness(9); linkGlow:SetColorTexture(T.brass[1], T.brass[2], T.brass[3], 0.12)
linkCore:SetThickness(2); linkCore:SetColorTexture(T.brass[1], T.brass[2], T.brass[3], 0.8)

-- Key face: border, top to bottom gradient, dark bottom edge (the page's 5px key-edge).
local function keyFace(b, top, bottom)
  ns.Skin(b, T.keyBot, T.line)
  b.face = ns.Gradient(b, top, bottom); b.face:SetPoint("TOPLEFT", 1, -1); b.face:SetPoint("BOTTOMRIGHT", -1, 5)
  local edge = b:CreateTexture(nil, "BORDER"); edge:SetColorTexture(unpack(T.keyEdge))
  edge:SetPoint("BOTTOMLEFT", 1, 1); edge:SetPoint("BOTTOMRIGHT", -1, 1); edge:SetHeight(4)
end

local keyButtons, refreshKeys = {}, nil
ns.KEY_ORDER = {} -- editable keys in canvas order, for the cheat sheet
for _, k in ipairs(LAYOUT) do
  local key = k[1]
  local b = CreateFrame("Button", nil, board, "BackdropTemplate")
  b:SetSize(K + ((k[4] or 1) - 1) * U, K)
  b:SetPoint("TOPLEFT", k[2] * U, -k[3] * U); b:SetFrameLevel(mouse:GetFrameLevel() + 2)
  b.label = ns.Text(b, "mono", 12)
  b.label:SetPoint("TOPLEFT", 6, -6); b.label:SetText(L["KEY_" .. key] or key)
  if k.move then
    keyFace(b, T.moveTop, T.moveBot)
    b.label:SetTextColor(0.44, 0.6, 0.46); b:EnableMouse(false)
  else
    keyFace(b, T.keyTop, T.keyBot)
    ns.KEY_ORDER[#ns.KEY_ORDER + 1] = key
    -- Selected glow: a brass ring just outside the key, softly pulsing.
    b.glow = b:CreateTexture(nil, "BACKGROUND", nil, -8)
    b.glow:SetPoint("TOPLEFT", -4, 4); b.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    b.glow:SetColorTexture(T.brass[1], T.brass[2], T.brass[3], 0.4); b.glow:Hide()
    b.pulse = b.glow:CreateAnimationGroup(); b.pulse:SetLooping("BOUNCE")
    local a = b.pulse:CreateAnimation("Alpha"); a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(1.1); a:SetSmoothing("IN_OUT")
    b:SetScript("OnClick", function() selectKey(key) end)
    b:SetScript("OnEnter", function(self) if key ~= current then self:SetBackdropBorderColor(unpack(T.brass)) end end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(self.idle or T.line)) end)
    b.icons = {}
    local j = 0
    for i, id in ipairs(ns.SLOTS) do
      local ic
      if id == "normal" then -- the plain press gets the big icon in the middle
        ic = ns.IconFrame(b, 26); ic:SetPoint("CENTER", 0, 1); b.big = ic
      else -- modifier slots: small icons along the bottom, card order
        j = j + 1
        ic = CreateFrame("Frame", nil, b); ic:SetSize(11, 11); ic:SetPoint("BOTTOM", (j - 2.5) * 12, 6)
        ic.tex = ic:CreateTexture(nil, "ARTWORK"); ic.tex:SetAllPoints(); ic.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      end
      ic:EnableMouse(true)
      ic:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["SLOT_" .. id] .. ": " .. self.name)
        if not self.known then
          local lv = ns.FutureLevel(self.spellID)
          GameTooltip:AddLine(lv and L.NOT_KNOWN_LEVEL:format(lv) or L.NOT_KNOWN, 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
      end)
      ic:SetScript("OnLeave", GameTooltip_Hide)
      ic:SetScript("OnMouseUp", function() selectKey(key) end) -- icon eats the click, forward it
      ic.slot = id; b.icons[i] = ic
    end
    keyButtons[key] = b
  end
end

function ns.SetKeyIconSize(n) for _, b in pairs(keyButtons) do b.big:SetSize(n, n) end end

-- Redraws every key: filled slots as icons (fixed spot per slot), selected key glows in brass.
refreshKeys = function()
  for key, b in pairs(keyButtons) do
    local setup = FoilKeybindsDB.keys[key]
    local filled = setup and next(setup.slots)
    local sel = key == current
    b.idle = sel and T.brass or filled and { T.void[1], T.void[2], T.void[3], 0.75 } or T.line
    b:SetBackdropBorderColor(unpack(b.idle))
    b.label:SetTextColor(unpack((filled or sel) and T.ink or T.muted))
    b.glow:SetShown(sel)
    if sel then if not b.pulse:IsPlaying() then b.pulse:Play() end else b.pulse:Stop() end
    for _, ic in ipairs(b.icons) do
      local s = setup and setup.slots[ic.slot]
      ic:SetShown(s ~= nil)
      if s then
        if ns.IsPetSlot(s) then
          ic.name, ic.known, ic.spellID = ns.PetLabel(s), true, nil
          ic.tex:SetTexture(ns.PetIcon(s))
        elseif s.item then
          ic.name, ic.known, ic.spellID = ns.ItemLabel(s.item), true, nil
          ic.tex:SetTexture(ns.ItemIcon(s.item))
        else
          ic.name, ic.known, ic.spellID = s.name, ns.IsKnown(s.spellID), s.spellID
          ic.tex:SetTexture(ns.SpellIcon(s.spellID))
        end
        ic.tex:SetDesaturated(not ic.known); ic:SetAlpha(ic.known and 1 or 0.4)
      end
    end
  end
  local b = current and keyButtons[current]
  linkGlow:SetShown(b ~= nil); linkCore:SetShown(b ~= nil)
  if b then
    for _, l in ipairs({ linkGlow, linkCore }) do
      l:ClearAllPoints(); l:SetStartPoint("RIGHT", b, 0, 0); l:SetEndPoint("TOPLEFT", card.bg, 0, -22)
    end
  end
end

-- Key card: 5 slots, each with a mouseover checkbox, plus the two key toggles.
card = CreateFrame("Frame", nil, f)
card:SetPoint("TOPLEFT", 588, -46); card:SetPoint("BOTTOMRIGHT", -14, 54)
card.bg = CreateFrame("Frame", nil, f, "BackdropTemplate")
card.bg:SetPoint("TOPLEFT", card, -8, 8); card.bg:SetPoint("BOTTOMRIGHT", card, 8, -8)
card:SetFrameLevel(card.bg:GetFrameLevel() + 2)
ns.Skin(card.bg, T.panel, { T.void[1], T.void[2], T.void[3], 0.45 })
do
  local g = ns.Gradient(card.bg, T.panel2, T.panel); g:SetPoint("TOPLEFT", 1, -1); g:SetPoint("BOTTOMRIGHT", -1, 1)
  local dot = card.bg:CreateTexture(nil, "OVERLAY"); dot:SetSize(6, 6); dot:SetColorTexture(unpack(T.brass))
  dot:SetPoint("CENTER", card.bg, "TOPLEFT", 0, -22) -- where the key link lands
end
card.label = ns.Text(card, "bold", 15)
card.label:SetPoint("TOPLEFT"); card.label:SetPoint("RIGHT", -60, 0); card.label:SetJustifyH("LEFT"); card.label:SetWordWrap(false)
card.count = ns.Text(card, "mono", 11, T.muted)
card.count:SetPoint("TOPRIGHT", 0, -2)
card.msg = ns.Text(card, "body", 13, T.blood)
card.msg:SetPoint("TOPLEFT", 0, -254); card.msg:SetPoint("RIGHT"); card.msg:SetJustifyH("LEFT")
local rows = {}
for i, id in ipairs(ns.SLOTS) do
  local r = {}
  local y = -24 - (i - 1) * 34
  r.mod = ns.Chip(card, "mono", 9); r.mod:SetPoint("LEFT", card, "TOPLEFT", 0, y - 13); r.mod:Set(L["SLOT_" .. id], 8)
  r.btn = ns.Button(card, 150, 26)
  r.btn:SetPoint("TOPLEFT", 62, y)
  r.btn:SetScript("OnClick", function() picker:Open(id) end)
  r.name = r.btn:GetFontString(); r.name:SetFontObject(ns.Font("body", 13))
  r.name:ClearAllPoints(); r.name:SetPoint("LEFT", 30, 0); r.name:SetPoint("RIGHT", -6, 0)
  r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
  r.iconF = ns.IconFrame(r.btn, 20); r.iconF:SetPoint("LEFT", 4, 0); r.icon = r.iconF.tex
  r.lv = ns.Chip(r.btn, "mono", 9, T.fel); r.lv:SetPoint("RIGHT", -4, 0)
  r.mo = ns.Check(card, L.MOUSEOVER)
  r.mo:SetPoint("LEFT", r.btn, "RIGHT", 8, 0) -- label ends ~70px later, trash sits at the far right
  r.mo:SetScript("OnClick", function(self)
    local s = setupOf(current).slots[id]
    if not s then return end
    local old = s.mouseover
    s.mouseover = self:GetChecked() and true or false
    commit(function() s.mouseover = old end, id)
  end)
  -- Trash button: same path as the picker's Clear slot.
  r.del = CreateFrame("Button", nil, card)
  r.del:SetSize(18, 18); r.del:SetPoint("TOPRIGHT", 0, y - 4)
  -- SetNormalAtlas does not error on a missing atlas, so check it exists first.
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("common-icon-delete") then
    r.del:SetNormalAtlas("common-icon-delete")
  else
    r.del:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
  end
  local trash = r.del:GetNormalTexture()
  trash:SetDesaturated(true); trash:SetVertexColor(unpack(T.muted))
  r.del:SetScript("OnClick", function() picker.slot = id; picker:Choose(nil) end)
  r.del:SetScript("OnEnter", function(self)
    trash:SetDesaturated(false); trash:SetVertexColor(unpack(T.blood))
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.CLEAR); GameTooltip:AddLine(L.CLEAR_HINT, 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  r.del:SetScript("OnLeave", function()
    trash:SetDesaturated(true); trash:SetVertexColor(unpack(T.muted)); GameTooltip:Hide()
  end)
  rows[id] = r
end
card.rule = card:CreateTexture(nil, "ARTWORK"); card.rule:SetColorTexture(unpack(T.line))
card.rule:SetPoint("TOPLEFT", 0, -192); card.rule:SetPoint("RIGHT"); card.rule:SetHeight(1)
local function toggle(field, text, y)
  local c = ns.Check(card, text)
  c:SetPoint("TOPLEFT", 0, y - 4)
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

-- Macro preview: side panel on the window's left edge (the picker uses the right one).
local preview = ns.Panel(nil, f, L.SHOW_MACRO)
preview:SetSize(340, 380); preview:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0); preview:Hide()
preview.well = CreateFrame("Frame", nil, preview, "BackdropTemplate")
preview.well:SetPoint("TOPLEFT", 10, -36); preview.well:SetPoint("BOTTOMRIGHT", -10, 30)
ns.Skin(preview.well, T.well, T.line)
preview.text = ns.Text(preview.well, "mono", 11, T.code)
preview.text:SetPoint("TOPLEFT", 8, -8); preview.text:SetPoint("BOTTOMRIGHT", -8, 8)
preview.text:SetJustifyH("LEFT"); preview.text:SetJustifyV("TOP"); preview.text:SetSpacing(3)
-- Conditions have no spaces, so without non-space wrap the line is cut to "[mo...".
preview.text:SetWordWrap(true); preview.text:SetNonSpaceWrap(true)
preview.warn = ns.Text(preview, "body", 12, T.blood)
preview.warn:SetPoint("BOTTOMLEFT", 14, 10); preview.warn:SetPoint("RIGHT", -14, 0); preview.warn:SetJustifyH("LEFT")
card.show = ns.Button(card, 130, 24)
card.show:SetPoint("TOPLEFT", 0, -280)
card.show:SetScript("OnClick", function() preview:SetShown(not preview:IsShown()); card:Refresh() end)

function card:Refresh()
  refreshKeys()
  if not current then
    self.label:SetText(L.PICK_KEY)
    for _, r in pairs(rows) do r.btn:Hide(); r.mo:Hide(); r.mod:Hide(); r.del:Hide() end
    self.count:SetText("")
    self.target:Hide(); self.pet:Hide(); self.show:Hide(); self.rule:Hide(); preview:Hide()
    return
  end
  local setup = setupOf(current)
  local name = ns.MacroName(current)
  self.label:SetText(L.KEY:format(L["KEY_" .. current] or current) .. "   |cffa99bb7" .. L.MACRO:format(name) .. "|r")
  local text, n = ns.FitMacro(setup, ns.best)
  self.count:SetText(n .. "/" .. ns.MAX)
  for id, r in pairs(rows) do
    local s = setup.slots[id]
    r.btn:Show(); r.mod:Show(); r.mo:Show()
    r.del:SetShown(s ~= nil)
    local item, pet = s and s.item, ns.IsPetSlot(s)
    r.btn:SetText(pet and ns.PetLabel(s) or item and ns.ItemLabel(item) or s and s.name or L.EMPTY)
    r.icon:SetTexture(pet and ns.PetIcon(s) or item and ns.ItemIcon(item) or s and ns.SpellIcon(s.spellID) or nil)
    r.iconF:SetShown(s ~= nil)
    r.name:SetTextColor(unpack(s and T.ink or T.muted))
    -- Spell not learned yet: faded row, grey icon, level chip when What's Training knows it.
    local future = s and not item and not pet and not ns.IsKnown(s.spellID)
    local lv = future and ns.FutureLevel(s.spellID)
    r.btn:SetAlpha(future and 0.5 or 1); r.icon:SetDesaturated(future or false)
    if lv then r.lv:Set(L.LEVEL:format(lv), 8) end
    r.lv:SetShown(lv and true or false)
    r.name:SetPoint("RIGHT", lv and -(r.lv:GetWidth() + 8) or -6, 0)
    r.mo:SetChecked(s and s.mouseover or false); r.mo:SetEnabled(s ~= nil and not item and not pet) -- no mouseover on items/pet
  end
  self.target:Show(); self.target:SetChecked(setup.targetEnemy or false)
  self.pet:Show(); self.pet:SetChecked(setup.petAttack or false)
  self.rule:Show()
  self.show:Show(); self.show:SetText(preview:IsShown() and L.HIDE_MACRO or L.SHOW_MACRO)
  if preview:IsShown() then
    -- One clause per line for reading; the real macro keeps "; " on one line.
    preview.text:SetText(text and ns.ColorMacro((text:gsub(";%s*", ";\n    "))) or "")
    local i = GetMacroIndexByName(name)
    preview.warn:SetText(text and i > 0 and not ns.SameMacro(GetMacroBody(i), text) and L.MACRO_DIFFERS or "")
  end
end

-- Picker: the 4 item categories on top, then pet commands, then learned spells, filtered by the search box, plus Clear.
local ROWS = 12
picker = ns.Panel("FoilKeybindsPicker", f, L.PICK_SPELL)
picker:SetSize(240, 380); picker:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0); picker:Hide()
picker.search = CreateFrame("EditBox", nil, picker, "SearchBoxTemplate")
picker.search:SetSize(200, 20); picker.search:SetPoint("TOP", 6, -34)
for _, k in ipairs({ "Left", "Middle", "Right" }) do if type(picker.search[k]) == "table" then picker.search[k]:Hide() end end
picker.search:SetFontObject(ns.Font("body", 13))
do -- flat field behind the stripped search box
  local w = CreateFrame("Frame", nil, picker, "BackdropTemplate")
  w:SetPoint("TOPLEFT", picker.search, -10, 2); w:SetPoint("BOTTOMRIGHT", picker.search, 2, -2)
  picker.search:SetFrameLevel(w:GetFrameLevel() + 2)
  ns.Skin(w, T.well, T.line)
end
picker.search:HookScript("OnTextChanged", function() picker.offset = 0; picker:Render() end)
picker.clear = ns.Button(picker, 200, 22, L.CLEAR, T.blood)
picker.clear:SetPoint("BOTTOM", 0, 10)
picker.clear:SetScript("OnClick", function() picker:Choose(nil) end)
picker.rows = {}
for i = 1, ROWS do
  local b = CreateFrame("Button", nil, picker)
  b:SetSize(204, 24); b:SetPoint("TOP", 0, -60 - (i - 1) * 24)
  b:SetHighlightTexture(ns.WHITE); b:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.06)
  b.iconF = ns.IconFrame(b, 20); b.iconF:SetPoint("LEFT", 2, 0); b.icon = b.iconF.tex
  b.text = ns.Text(b, "body", 13)
  b.text:SetPoint("LEFT", b.iconF, "RIGHT", 6, 0); b.text:SetPoint("RIGHT", -2, 0)
  b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
  b.head = ns.Text(b, "mono", 9, T.brass) -- section label, like the page's eyebrow
  b.head:SetPoint("LEFT", 2, -3); b.head:SetPoint("RIGHT", -2, -3); b.head:SetJustifyH("LEFT")
  b:SetScript("OnClick", function(self) if not self.spell.header then picker:Choose(self.spell) end end)
  picker.rows[i] = b
end
picker.offset, picker.shown = 0, {}
picker:EnableMouseWheel(true)
picker:SetScript("OnMouseWheel", function(self, d)
  self.offset = math.max(0, math.min(self.offset - d * 3, #self.shown - ROWS)); self:Render()
end)

function picker:Open(slot)
  ns.ScanBags() -- read only, fine in combat; icons show what is in the bags now
  self.slot, self.offset, self.all = slot, 0, {}
  for _, cat in ipairs(ns.ITEMS) do self.all[#self.all + 1] = { item = cat, name = ns.ItemLabel(cat) } end
  self.all[#self.all + 1] = { header = true, fixed = true, name = L.PET_HEADER }
  for _, p in ipairs(ns.PET_CMDS) do self.all[#self.all + 1] = { pet = p, name = ns.PetLabel({ pet = p }) } end
  if ns.PET_SPECIAL[ns.playerClass] then self.all[#self.all + 1] = { petSpecial = true, name = L.PET_SPECIAL } end
  for _, s in ipairs(ns.LearnedSpells()) do self.all[#self.all + 1] = s end
  self:AddFuture()
  self.search:SetText(""); self:Show(); self:Render()
end
-- Header rows always show (search skips them); future rows go grey with their level.
function picker:AddFuture()
  if not ns.HasWT() then self.all[#self.all + 1] = { header = true, name = L.FUTURE_HINT }; return end
  local future = ns.FutureSpells()
  if #future == 0 then return end
  self.all[#self.all + 1] = { header = true, name = L.FUTURE_HEADER }
  for _, s in ipairs(future) do self.all[#self.all + 1] = s end
end
function ns.RefreshPicker()
  if not picker:IsShown() then return end
  for i = #picker.all, 1, -1 do if (picker.all[i].header and not picker.all[i].fixed) or picker.all[i].future then table.remove(picker.all, i) end end
  picker:AddFuture(); picker:Render()
end
function picker:Render()
  local q = (self.search:GetText() or ""):lower()
  self.shown = {}
  for _, s in ipairs(self.all or {}) do
    if q == "" or s.header or s.name:lower():find(q, 1, true) then self.shown[#self.shown + 1] = s end
  end
  for i, b in ipairs(self.rows) do
    local s = self.shown[self.offset + i]
    b.spell = s; b:SetShown(s ~= nil)
    if s then
      b.head:SetShown(s.header or false); b.text:SetShown(not s.header); b.iconF:SetShown(not s.header)
      b:GetHighlightTexture():SetAlpha(s.header and 0 or 1)
      b:SetAlpha(s.future and 0.5 or 1)
      if s.header then
        b.head:SetText(s.name)
      else
        local extra = s.future and ("|cff93d35a" .. L.LEVEL:format(s.level) .. "|r") or s.sub and ("|cffa99bb7" .. s.sub .. "|r")
        b.text:SetText(extra and (s.name .. "  " .. extra) or s.name)
        b.icon:SetTexture(ns.IsPetSlot(s) and ns.PetIcon(s) or s.item and ns.ItemIcon(s.item) or ns.SpellIcon(s.spellID))
        b.icon:SetDesaturated(s.future or false)
      end
    end
  end
end
function picker:Choose(s)
  local slots, slot = setupOf(current).slots, self.slot
  local old = slots[slot]
  if s and (s.pet or s.petSpecial) then
    slots[slot] = { pet = s.pet, petSpecial = s.petSpecial }
  elseif s and s.item then
    slots[slot] = { item = s.item }
  elseif s then
    slots[slot] = ns.NewSlot(s.spellID, s.name, ns.SpellKind(s.spellID), old)
  else
    slots[slot] = nil
  end
  self:Hide()
  commit(function() slots[slot] = old end, slot)
end

f:SetScript("OnShow", function() ns.ScanBags(); card:Refresh() end)
function ns.Refresh()
  if f:IsShown() then card:Refresh() end
  if ns.RefreshCheat then ns.RefreshCheat() end -- the cheat sheet is often open with the window closed
end

function FoilKeybinds_Toggle() f:SetShown(not f:IsShown()) end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= "FoilKeybinds" then return end
  FoilKeybindsDB = FoilKeybindsDB or {}
  FoilKeybindsDB.keys = FoilKeybindsDB.keys or {}
  FoilKeybindsAccount = FoilKeybindsAccount or {}
  for key, setup in pairs(FoilKeybindsDB.keys) do -- ticket 01 stored { normal = "Name" }, drop it
    if not setup.slots then FoilKeybindsDB.keys[key] = { slots = {} } end
  end
  -- Account-wide settings. First run keeps this character's cheat sheet scale and lock.
  local c = FoilKeybindsDB.cheat or {}
  ns.S = ns.MergeSettings(FoilKeybindsAccount.settings or { cheatScale = c.scale, cheatLock = c.locked })
  FoilKeybindsAccount.settings = ns.S
  ns.ApplySettings()
end)

-- /fkb toggles the window. /fkb set <KEY> <Spell> fills a key's normal slot from the spellbook.
SLASH_FOILKEYBINDS1 = "/fkb"
local CONFIG = { config = true, settings = true, opcoes = true, ["opções"] = true }
SlashCmdList.FOILKEYBINDS = function(msg)
  msg = strtrim(msg or "")
  local key, spell = msg:match("^set%s+(%S+)%s+(.+)$")
  local word = msg:lower()
  if key then
    key = key:upper()
    for _, s in ipairs(ns.LearnedSpells()) do
      if s.name:lower() == spell:lower() then
        local slots = setupOf(key).slots
        slots.normal = ns.NewSlot(s.spellID, s.name, ns.SpellKind(s.spellID), slots.normal)
        if f:IsShown() then card:Refresh() end
        return ns.Say(L.SET:format(key, s.name))
      end
    end
    ns.Say(L.UNKNOWN_SPELL:format(spell))
  elseif word == "apply" then ns.Apply()
  elseif word == "undo" then ns.Undo()
  elseif word == "cheat" or word == "cola" then ns.ToggleCheat()
  elseif CONFIG[word] then ns.OpenSettings(true)
  else FoilKeybinds_Toggle() end
end
