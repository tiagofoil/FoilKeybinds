local _, ns = ...
local L = ns.L
local T = ns.T

local f = ns.Panel("FoilKeybindsFrame", UIParent, L.TITLE)
f:SetSize(960, 744); f:SetPoint("CENTER")
f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
f:SetFrameStrata("HIGH"); f:SetToplevel(true) -- above quest arrows and other addons; popups use DIALOG
tinsert(UISpecialFrames, "FoilKeybindsFrame") -- Esc closes it
function ns.SetMainScale(v) f:SetScale(v) end

-- Tabs at the top: Keys | Guide | Settings. One window, so closing it closes all.
local keysPane = CreateFrame("Frame", nil, f); keysPane:SetAllPoints()
ns.settingsPane = CreateFrame("Frame", nil, f) -- Settings.lua builds the page in it
ns.settingsPane:SetPoint("TOPLEFT", 0, -28); ns.settingsPane:SetPoint("BOTTOMRIGHT"); ns.settingsPane:Hide()
ns.guidePane = CreateFrame("Frame", nil, f) -- Guide.lua builds the tab in it
ns.guidePane:SetPoint("TOPLEFT", 0, -28); ns.guidePane:SetPoint("BOTTOMRIGHT"); ns.guidePane:Hide()
local tabs = {}
local function showTab(name)
  if name ~= "keys" and ns.CancelPreview then ns.CancelPreview() end -- leaving the Keys tab cancels a preview
  f.tab = name
  keysPane:SetShown(name == "keys"); ns.settingsPane:SetShown(name == "settings"); ns.guidePane:SetShown(name == "guide")
  for n, b in pairs(tabs) do b:GetFontString():SetTextColor(unpack(n == name and T.brass or T.muted)) end
  if name == "guide" and ns.ShowGuide then ns.ShowGuide() end -- loads the guide package on the first open
end
for i, t in ipairs({ { "keys", L.TAB_KEYS }, { "guide", L.TAB_GUIDE }, { "settings", L.SETTINGS } }) do
  local b = ns.Button(f, 90, 20, t[2])
  b:SetPoint("LEFT", f.title, "RIGHT", 18 + (i - 1) * 96, 0)
  b:SetScript("OnClick", function() showTab(t[1]) end)
  tabs[t[1]] = b
end
showTab("keys")
-- Opens the window on a tab (keys, guide or settings).
function ns.OpenWindow(tab) f:Show(); showTab(tab) end

local applyBtn = ns.Button(keysPane, 140, 26, L.APPLY, T.fel)
applyBtn:SetPoint("BOTTOMRIGHT", -16, 14)
applyBtn:SetScript("OnClick", function() ns.Apply() end)
local undoBtn = ns.Button(keysPane, 100, 26, L.UNDO)
undoBtn:SetPoint("RIGHT", applyBtn, "LEFT", -8, 0)
undoBtn:SetScript("OnClick", function() ns.UndoStep() end)

-- Layouts menu: save the keys, load or delete a saved set, copy another character's keys.
local copyBtn = ns.Button(keysPane, 120, 26, L.LAYOUTS)
copyBtn:SetPoint("RIGHT", undoBtn, "LEFT", -8, 0)
copyBtn:SetScript("OnClick", function(self)
  local me, class = ns.Me()
  local list = ns.SameClass(FoilKeybindsAccount, class, me)
  MenuUtil.CreateContextMenu(self, function(_, root)
    root:CreateButton(L.SAVE_KEYS, ns.SaveCurrent)
    local saved = FoilKeybindsDB.saved or {}
    if #saved > 0 then root:CreateTitle(L.SAVED_TITLE) end
    for _, set in ipairs(saved) do
      local sub = root:CreateButton(set.name)
      sub:CreateButton(L.LOAD, function() ns.LoadSaved(set) end)
      sub:CreateButton(L.DELETE, function() ns.DeleteSaved(set) end)
    end
    root:CreateTitle(L.COPY_FROM)
    if #list == 0 then root:CreateTitle(L.COPY_NONE_SHORT) end
    for _, name in ipairs(list) do root:CreateButton(name, function() ns.CopyFrom(name) end) end
  end)
end)

local itemsBtn = ns.Button(keysPane, 120, 26, L.REFRESH_ITEMS)
itemsBtn:SetPoint("RIGHT", copyBtn, "LEFT", -8, 0)
itemsBtn:SetScript("OnClick", function() ns.SwapItems(true) end)

-- Master switch: bars and keybinds ON/OFF, always in sight next to Apply.
local manageBtn = ns.Button(keysPane, 176, 26)
manageBtn:SetPoint("RIGHT", itemsBtn, "LEFT", -8, 0)
manageBtn:GetFontString():ClearAllPoints(); manageBtn:GetFontString():SetPoint("LEFT", 42, 0)
manageBtn.track = ns.Shape(manageBtn, "Pill", "ARTWORK"); manageBtn.track:SetSize(26, 14); manageBtn.track:SetPoint("LEFT", 9, 0)
manageBtn.knob = ns.Shape(manageBtn, "Dot", "OVERLAY"); manageBtn.knob:SetSize(12, 12); manageBtn.knob:SetVertexColor(unpack(T.ink))
manageBtn:SetScript("OnClick", function() ns.SetManage(not ns.Manages()) end)
manageBtn:HookScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.SET_MANAGE)
  GameTooltip:AddLine(L.MANAGE_TIP, 0.8, 0.8, 0.8, true); GameTooltip:Show()
end)
manageBtn:HookScript("OnLeave", GameTooltip_Hide)

local current, card, picker

local function setupOf(key)
  local keys = FoilKeybindsDB.keys
  keys[key] = keys[key] or { slots = {} }
  return keys[key]
end
-- Template preview (pv, see ns.StartPreview): the board draws pv.keys instead of the live keys.
-- Drawing reads through viewKeys, never setupOf, so a preview creates no live key.
local pv
local function viewKeys() return pv and pv.keys or FoilKeybindsDB.keys end

-- Runs after every card change: trims mouseover into saved data, or reverts the change
-- with undo() when the macro cannot fit. Then redraws the card. slot = the slot the player
-- just changed (nil for key toggles): the error names it, falling back to the core's pick.
-- Edit history for Undo: the key's setup before each saved edit, newest last, this session only.
-- card:Refresh keeps "before" = the setup on screen, so it is the state from before the next edit.
local history, before, beforeKey, MAXHIST = {}, nil, nil, 30
function ns.ClearHistory() wipe(history) end
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
    if before and beforeKey == current then
      history[#history + 1] = { key = current, setup = before }
      if #history > MAXHIST then table.remove(history, 1) end
    end
  end
  card:Refresh()
end

-- A seconds box with focus commits on focus loss, so it must lose focus while current is still its key.
local function selectKey(key)
  if pv then -- preview is read-only; the wizard takes a key click as its pick
    if pv.wiz and pv.wiz.click then pv.wiz.click(key) end
    return
  end
  local box = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if box then box:ClearFocus() end
  current = key; picker:Hide(); card.msg:SetText(""); card:Refresh()
end

-- Undo: one edit back (like Ctrl+Z). Then a pending Copy from. Never touches the game.
function ns.UndoStep()
  local box = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if box then box:ClearFocus() end -- a seconds box commits first, so its edit is undone too
  local h = table.remove(history)
  if not h then
    if not ns.UndoCopy() then ns.Say(L.NOTHING_TO_UNDO) end
    return
  end
  FoilKeybindsDB.keys[h.key] = h.setup
  current = h.key; picker:Hide(); card.msg:SetText("")
  if f:IsShown() then card:Refresh() end
end

-- Board: keys near WASD plus the mouse, fixed in the top strip at one scale (no pan, no zoom).
local BOARD_SCALE = 0.8
local view = CreateFrame("Frame", nil, keysPane)
view:SetPoint("TOPLEFT", 12, -38); view:SetSize(568, 300)
ns.RoundSkin(view, { T.panel[1], T.panel[2], T.panel[3], 0.7 }, T.line)
local board = CreateFrame("Frame", nil, view)
board:SetSize(680, 350); board:SetScale(BOARD_SCALE)
board:SetPoint("TOPLEFT", view, "TOPLEFT", 12 / BOARD_SCALE, -10 / BOARD_SCALE)
local cheatBtn = ns.Button(keysPane, 110, 26, L.CHEAT_TITLE)
cheatBtn:SetPoint("BOTTOMLEFT", 12, 14)
cheatBtn:SetScript("OnClick", function() ns.ToggleCheat() end)
local resetBtn = ns.Button(keysPane, 110, 26, L.RESET_ALL, T.blood)
resetBtn:SetPoint("LEFT", cheatBtn, "RIGHT", 8, 0)
resetBtn:SetScript("OnClick", function()
  ns.Popup(L.RESET_ALL, L.RESET_CONFIRM, { { L.RESET_ALL, ns.ResetAll, T.blood }, { CANCEL or "Cancel" } })
end)

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
  { "BUTTON3", 7.75, 0.6 }, { "BUTTON4", 6.6, 2.1 }, { "BUTTON5", 6.6, 3.1 },
}
ns.LAYOUT = LAYOUT -- the cheat sheet's mini keyboard uses the same places
-- Mouse: a real mouse shape. Left and right buttons stay with the game (grey, GAME, no click);
-- M3 sits on the wheel, M4 and M5 stick out on the left side as thumb buttons.
local mouse = CreateFrame("Frame", nil, board)
mouse:SetSize(190, 4 * U); mouse:SetPoint("TOPLEFT", 6.85 * U, -0.2 * U)
mouse:SetFrameLevel(board:GetFrameLevel())
do
  local line = ns.Shape(mouse, "Mouse", "BACKGROUND", -7); line:SetAllPoints(); line:SetVertexColor(unpack(T.line))
  local body = ns.Shape(mouse, "Mouse", "BACKGROUND", -6); body:SetVertexColor(unpack(T.keyTop))
  body:SetPoint("TOPLEFT", 2, -2); body:SetPoint("BOTTOMRIGHT", -2, 2)
  local split = mouse:CreateTexture(nil, "BORDER"); split:SetColorTexture(unpack(T.line))
  split:SetPoint("TOPLEFT", 8, -118); split:SetPoint("TOPRIGHT", -8, -118); split:SetHeight(2)
  local mid = mouse:CreateTexture(nil, "BORDER"); mid:SetColorTexture(unpack(T.line))
  mid:SetPoint("TOP", 0, -2); mid:SetSize(2, 116)
  for _, side in ipairs({ { "LEFT", 34 }, { "RIGHT", -34 } }) do
    local g = ns.Text(mouse, "mono", 13, T.muted); g:SetPoint("CENTER", mouse, "TOP" .. side[1], side[2], -62)
    g:SetText(L.GAME)
  end
end

-- Keycap: rounded outline, dark bottom edge, top to bottom gradient face (the page's 5px key-edge).
-- b.line is the outline: idle, hover and selected colors all go through it.
local function keyFace(b, top, bottom)
  b.line = ns.Shape(b, "Round", "BACKGROUND", -6); b.line:SetAllPoints()
  local edge = ns.Shape(b, "Round", "BACKGROUND", -5); edge:SetVertexColor(unpack(T.keyEdge))
  edge:SetPoint("TOPLEFT", 1, -1); edge:SetPoint("BOTTOMRIGHT", -1, 1)
  b.face = ns.Shape(b, "Round", "BACKGROUND", -4)
  b.face:SetGradient("VERTICAL", CreateColor(unpack(bottom)), CreateColor(unpack(top)))
  b.face:SetPoint("TOPLEFT", 1, -1); b.face:SetPoint("BOTTOMRIGHT", -1, 5)
  b.line:SetVertexColor(unpack(T.line))
end

-- Keycap tooltip: all five slots in column order, with the not-learned line as before.
local function keyTooltip(b, key)
  GameTooltip:SetOwner(b, "ANCHOR_TOP")
  GameTooltip:SetText(L.KEY:format(L["KEY_" .. key] or key))
  local setup = viewKeys()[key]
  for _, id in ipairs(ns.COLUMNS) do
    local s = setup and setup.slots[id]
    if s then
      local _, name, known, spellID = ns.SlotView(s)
      GameTooltip:AddDoubleLine(L["SLOT_" .. id], name, 0.84, 0.69, 0.4, 1, 1, 1)
      for _, w in ipairs(s.with or {}) do GameTooltip:AddDoubleLine(" ", "+ " .. w.name, 1, 1, 1, 0.7, 0.6, 0.8) end
      if not known then
        local lv = ns.FutureLevel(spellID)
        GameTooltip:AddLine(lv and L.NOT_KNOWN_LEVEL:format(lv) or L.NOT_KNOWN, 0.6, 0.6, 0.6)
      end
    else
      GameTooltip:AddDoubleLine(L["SLOT_" .. id], L.EMPTY, 0.84, 0.69, 0.4, 0.5, 0.5, 0.5)
    end
  end
  GameTooltip:Show()
end

local keyButtons, refreshKeys = {}, nil
local DOTS = { "shift", "ctrl", "alt", "altshift" } -- ns.COLUMNS without normal
ns.KEY_ORDER = {} -- editable keys in canvas order, for the cheat sheet. Same list as Core's ns.BOARD (the smoke test checks it).
for _, k in ipairs(LAYOUT) do
  local key = k[1]
  local b = CreateFrame("Button", nil, board)
  b:SetSize(K + ((k[4] or 1) - 1) * U, K)
  b:SetPoint("TOPLEFT", k[2] * U, -k[3] * U); b:SetFrameLevel(mouse:GetFrameLevel() + 2)
  b.label = ns.Text(b, "mono", 14)
  b.label:SetPoint("TOPLEFT", 8, -6); b.label:SetText(L["KEY_" .. key] or key)
  if k.move then
    keyFace(b, T.moveTop, T.moveBot)
    b.label:SetTextColor(0.44, 0.6, 0.46); b:EnableMouse(false)
  else
    keyFace(b, T.keyTop, T.keyBot)
    ns.KEY_ORDER[#ns.KEY_ORDER + 1] = key
    -- Selected glow: a brass ring just outside the key, softly pulsing.
    b.glow = ns.Shape(b, "Round", "BACKGROUND", -8)
    b.glow:SetPoint("TOPLEFT", -4, 4); b.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    b.glow:SetVertexColor(T.brass[1], T.brass[2], T.brass[3], 0.4); b.glow:Hide()
    b.pulse = b.glow:CreateAnimationGroup(); b.pulse:SetLooping("BOUNCE")
    local a = b.pulse:CreateAnimation("Alpha"); a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(1.1); a:SetSmoothing("IN_OUT")
    b:SetScript("OnClick", function() selectKey(key) end)
    b:SetScript("OnEnter", function(self)
      if key ~= current then self.line:SetVertexColor(unpack(T.brass)) end
      keyTooltip(self, key)
    end)
    b:SetScript("OnLeave", function(self) self.line:SetVertexColor(unpack(self.idle or T.line)); GameTooltip:Hide() end)
    -- The plain press: big icon in the middle (the key takes the clicks), count badge for a sequence.
    b.big = ns.IconFrame(b, 26); b.big:SetPoint("CENTER", 0, 3); b.big:EnableMouse(false)
    b.big.stack = ns.IconFrame(b, 26); b.big.stack:SetPoint("CENTER", b.big, "CENTER", 5, 5)
    b.big.stack:SetFrameLevel(b.big:GetFrameLevel() - 1); b.big.stack:SetAlpha(0.55); b.big.stack:EnableMouse(false)
    b.withF = ns.IconFrame(b, 18); b.withF:SetPoint("TOPRIGHT", -6, -6); b.withF:EnableMouse(false)
    b.withF.plus = ns.Text(b.withF, "mono", 12, T.brass); b.withF.plus:SetPoint("RIGHT", b.withF, "LEFT", -1, 0)
    b.withF.plus:SetText("+")
    b.big.badge = ns.Text(b.big, "mono", 10)
    b.big.badge:SetPoint("BOTTOMRIGHT", 2, -1); b.big.badge:SetShadowColor(0, 0, 0, 1); b.big.badge:SetShadowOffset(1, -1)
    -- Modifier slots: four dots along the bottom, filled when the slot is used.
    b.dots = {}
    for j, id in ipairs(DOTS) do
      local d = ns.Shape(b, "Dot", "ARTWORK"); d:SetSize(10, 10); d:SetPoint("BOTTOM", (j - 2.5) * 14, 9)
      d.slot = id; b.dots[j] = d
    end
    keyButtons[key] = b
  end
end

function ns.SetKeyIconSize(n) for _, b in pairs(keyButtons) do b.big:SetSize(n, n); b.big.stack:SetSize(n, n) end end

-- Redraws every key: plain press icon, filled dots, selected key glows in brass.
refreshKeys = function()
  for key, b in pairs(keyButtons) do
    local setup = viewKeys()[key]
    local filled = setup and next(setup.slots)
    local sel = key == current
    b.idle = sel and T.brass or filled and { T.void[1], T.void[2], T.void[3], 0.75 } or T.line
    b.line:SetVertexColor(unpack(b.idle))
    b.label:SetTextColor(unpack((filled or sel) and T.ink or T.muted))
    b.glow:SetShown(sel)
    if sel then if not b.pulse:IsPlaying() then b.pulse:Play() end else b.pulse:Stop() end
    local s = setup and setup.slots.normal
    b.big:SetShown(s ~= nil); b.big.spellID = nil
    if s then
      local tex, _, known, spellID, count = ns.SlotView(s)
      b.big.tex:SetTexture(tex); b.big.spellID = spellID
      b.big.tex:SetDesaturated(not known); b.big:SetAlpha(known and 1 or 0.4)
      b.big.badge:SetText(count or ""); b.big.badge:SetShown(count ~= nil)
    end
    local second = s and s.seq and s.seq[2]
    b.big.stack:SetShown(second ~= nil)
    if second then b.big.stack.tex:SetTexture(ns.SpellIcon(second.spellID)) end
    local w = s and s.with and s.with[1]
    b.withF:SetShown(w ~= nil); b.withF.spellID = w and w.spellID
    if w then b.withF.tex:SetTexture(ns.SpellIcon(w.spellID)) end
    for _, d in ipairs(b.dots) do
      local used = setup and setup.slots[d.slot]
      if not used then d:SetVertexColor(T.line[1], T.line[2], T.line[3], 0.9)
      elseif used.seq or used.with then d:SetVertexColor(unpack(T.brass))
      else d:SetVertexColor(unpack(T.void)) end
    end
  end
end

-- Key panel: right of the board. Key and macro name, size meter, the two key toggles, Show macro,
-- the dot legend, the fit messages and the switch OFF hint.
card = CreateFrame("Frame", nil, keysPane)
ns.keyCard = card -- the wizard's step bar sits in its space (Wizard.lua)
card:SetPoint("TOPLEFT", view, "TOPRIGHT", 12, 0); card:SetPoint("BOTTOMRIGHT", keysPane, "TOPRIGHT", -12, -338)
ns.RoundSkin(card, T.panel, { T.void[1], T.void[2], T.void[3], 0.45 })
card.label = ns.Text(card, "bold", 15)
card.label:SetPoint("TOPLEFT", 14, -12); card.label:SetPoint("RIGHT", -80, 0); card.label:SetJustifyH("LEFT"); card.label:SetWordWrap(false)
card.count = ns.Text(card, "mono", 11, T.muted)
card.count:SetPoint("TOPRIGHT", -14, -14)
card.meter = CreateFrame("Frame", nil, card)
card.meter:SetPoint("TOPLEFT", 14, -34); card.meter:SetPoint("RIGHT", -14, 0); card.meter:SetHeight(4)
card.meter.bg = card.meter:CreateTexture(nil, "BACKGROUND"); card.meter.bg:SetAllPoints(); card.meter.bg:SetColorTexture(unpack(T.well))
card.meter.fill = card.meter:CreateTexture(nil, "ARTWORK"); card.meter.fill:SetPoint("TOPLEFT"); card.meter.fill:SetPoint("BOTTOMLEFT")
local function toggle(field, text, y)
  local c = ns.Check(card, text)
  c:SetPoint("TOPLEFT", 14, y)
  c:SetScript("OnClick", function(self)
    local setup = setupOf(current)
    local old = setup[field]
    setup[field] = self:GetChecked() and true or false
    commit(function() setup[field] = old end)
  end)
  return c
end
card.target = toggle("targetEnemy", L.TARGET_ENEMY, -50)
card.pet = toggle("petAttack", L.PET_ATTACK, -74)
card.show = ns.Button(card, 130, 24)
card.show:SetPoint("TOPLEFT", 14, -98)
card.clear = ns.Button(card, 120, 24, L.CLEAR_KEY, T.blood)
card.clear:SetPoint("LEFT", card.show, "RIGHT", 8, 0)
card.clear:SetScript("OnClick", function() -- all five slots; Apply then removes the macro and keybind
  local setup = setupOf(current)
  local old = setup.slots
  setup.slots = {}
  commit(function() setup.slots = old end)
end)
card.clear:HookScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.CLEAR_KEY); GameTooltip:AddLine(L.CLEAR_HINT, 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)
card.clear:HookScript("OnLeave", GameTooltip_Hide)
-- Dot legend: what the four dots on a key mean.
card.legend = CreateFrame("Frame", nil, card)
card.legend:SetPoint("TOPLEFT", 14, -132); card.legend:SetSize(320, 32)
do
  local function dot(x, y, color, text, kind)
    local d = ns.Shape(card.legend, "Dot", "ARTWORK"); d:SetSize(9, 9); d:SetPoint("TOPLEFT", x, y); d:SetVertexColor(unpack(color))
    local t = ns.Text(card.legend, kind, kind == "mono" and 10 or 12, T.muted); t:SetPoint("LEFT", d, "RIGHT", 4, 0); t:SetText(text)
    return x + 9 + 4 + t:GetStringWidth() + 12
  end
  local x = 0
  for _, id in ipairs(DOTS) do x = dot(x, -2, T.void, L["SLOT_" .. id], "mono") end
  x = dot(0, -20, T.void, L.DOT_SPELL, "body")
  dot(x, -20, T.brass, L.DOT_SPECIAL, "body")
end
card.msg = ns.Text(card, "body", 13, T.blood)
card.swapTip = ns.Text(card, "body", 12, T.muted)
card.swapTip:SetPoint("TOPLEFT", 14, -172); card.swapTip:SetText(L.SWAP_TIP)
card.msg:SetPoint("TOPLEFT", 14, -192); card.msg:SetPoint("RIGHT", -14, 0); card.msg:SetJustifyH("LEFT")
card.hint = ns.Text(card, "body", 12, T.muted) -- switch OFF: Apply only writes the macro
card.hint:SetPoint("BOTTOMLEFT", 14, 12); card.hint:SetPoint("RIGHT", -14, 0); card.hint:SetJustifyH("LEFT")

-- Edits slot id with fn(old copy) -> new value, then the usual commit (undo = copy from before).
local function changeSlot(id, fn)
  local slots = setupOf(current).slots
  local old = ns.Copy(slots[id])
  slots[id] = fn(ns.Copy(old))
  commit(function() slots[id] = old end, id)
end

-- Small square tool button with an icon texture or a text glyph.
local function tool(parent, tex, glyph, tip)
  local b = ns.Button(parent, 18, 18, glyph)
  if tex then
    local t = b:CreateTexture(nil, "OVERLAY"); t:SetSize(12, 12); t:SetPoint("CENTER"); t:SetTexture(tex)
    t:SetVertexColor(unpack(T.muted)); b.tex = t
  end
  b:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(tip); GameTooltip:Show()
  end)
  b:HookScript("OnLeave", GameTooltip_Hide)
  return b
end

-- Columns: one per modifier, Normal first (ns.COLUMNS). Each column edits its slot in place:
-- header (chip, key, trash, mouseover), the steps (one for a plain slot), or a big Choose button.
local STEP = 22
local cols = {}
-- Drag a column onto another: the two slots trade places (Shift's spell to Normal, Normal's to Shift).
-- The drop target is the column under the mouse on release; no OnUpdate while dragging.
local dragFrom
local function swapSlots(a, b)
  local slots = setupOf(current).slots
  if not (slots[a] or slots[b]) then return end
  slots[a], slots[b] = slots[b], slots[a]
  commit(function() slots[a], slots[b] = slots[b], slots[a] end)
end
local ghost = CreateFrame("Frame", nil, UIParent)
ghost:SetFrameStrata("TOOLTIP"); ghost:SetSize(170, 30); ghost:Hide()
ns.RoundSkin(ghost, T.panel2, T.brass)
ghost.iconF = ns.IconFrame(ghost, 20); ghost.iconF:SetPoint("LEFT", 6, 0)
ghost.text = ns.Text(ghost, "body", 13); ghost.text:SetPoint("LEFT", ghost.iconF, "RIGHT", 6, 0)
ghost.text:SetPoint("RIGHT", -8, 0); ghost.text:SetJustifyH("LEFT"); ghost.text:SetWordWrap(false)
ghost:SetScript("OnUpdate", function(self)
  local x, y = GetCursorPosition()
  local sc = self:GetEffectiveScale()
  self:ClearAllPoints(); self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / sc + 14, y / sc - 10)
end)
local MOVE_CURSOR = "Interface\\CURSOR\\UI-Cursor-Move"
local function dragStart(c)
  if not current then return end
  dragFrom = c.id
  SetCursor(MOVE_CURSOR)
  c.rLine:SetVertexColor(unpack(T.brass))
  local s = setupOf(current).slots[c.id]
  local tex, label = ns.SlotView(s)
  ghost.iconF:SetShown(tex ~= nil); if tex then ghost.iconF.tex:SetTexture(tex) end
  ghost.text:SetText(L["SLOT_" .. c.id] .. ": " .. (label or L.EMPTY))
  ghost:Show()
end
local function dragStop(c)
  if not dragFrom then return end
  local from = dragFrom
  dragFrom = nil
  ghost:Hide(); ResetCursor()
  for _, t in pairs(cols) do t.rLine:SetVertexColor(unpack(T.line)) end
  for id, t in pairs(cols) do
    if id ~= from and t:IsMouseOver() then return swapSlots(from, id) end
  end
end
for i, id in ipairs(ns.COLUMNS) do
  local c = CreateFrame("Frame", nil, keysPane)
  c:SetSize(180, 340); c:SetPoint("TOPLEFT", 12 + (i - 1) * 189, -348)
  ns.RoundSkin(c, T.panel, T.line)
  c:EnableMouse(true); c:RegisterForDrag("LeftButton") -- drag from the header or any empty spot
  c:SetScript("OnDragStart", dragStart); c:SetScript("OnDragStop", dragStop)
  c:SetScript("OnHide", dragStop) -- window closed mid-drag: cursor back, no swap
  c.band = ns.Shape(c, "Round", "BACKGROUND", -5); c.band:SetVertexColor(unpack(T.panel2))
  c.band:SetPoint("TOPLEFT", 2, -2); c.band:SetPoint("TOPRIGHT", -2, -2); c.band:SetHeight(28)
  c.grip = {}
  for g = 0, 5 do
    local d = ns.Shape(c, "Dot", "ARTWORK"); d:SetSize(4, 4); d:SetVertexColor(unpack(T.muted))
    d:SetPoint("TOPLEFT", 9 + (g % 2) * 5, -9 - math.floor(g / 2) * 5); c.grip[#c.grip + 1] = d
  end
  local function lit(self, on)
    self.band:SetVertexColor(unpack(on and T.keyTop or T.panel2))
    for _, d in ipairs(self.grip) do d:SetVertexColor(unpack(on and T.brass or T.muted)) end
  end
  c:SetScript("OnEnter", function(self)
    if dragFrom then
      if dragFrom ~= self.id then self.rLine:SetVertexColor(unpack(T.fel)) end
    elseif current then lit(self, true); SetCursor(MOVE_CURSOR) end
  end)
  c:SetScript("OnLeave", function(self)
    if dragFrom then
      if dragFrom ~= self.id then self.rLine:SetVertexColor(unpack(T.line)) end
    else lit(self, false); ResetCursor() end
  end)
  c.id = id
  c.mod = ns.Chip(c, "mono", 9); c.mod:SetPoint("TOPLEFT", 22, -8); c.mod:Set(L["SLOT_" .. id], 8)
  c.key = ns.Text(c, "mono", 11, T.muted); c.key:SetPoint("LEFT", c.mod, "RIGHT", 6, 0)
  c.key:SetWidth(40); c.key:SetJustifyH("LEFT"); c.key:SetWordWrap(false)
  -- Clear: same path as the picker's Clear slot.
  c.del = ns.Button(c, 54, 18, L.CLEAR_SHORT, T.blood)
  c.del:SetPoint("TOPRIGHT", -8, -8)
  c.del:SetScript("OnClick", function() picker.slot = id; picker:Choose(nil) end)
  c.del:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.CLEAR); GameTooltip:AddLine(L.CLEAR_HINT, 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  c.del:HookScript("OnLeave", GameTooltip_Hide)
  -- Cast with: up to 2 spells that fire first on the same press (racials with no global cooldown).
  -- Their icons sit left of the "+ Cast with" button; click an icon to remove it.
  c.with = {}
  for k = 1, ns.MAXWITH do
    local w = CreateFrame("Button", nil, c)
    w:SetSize(20, 20); w:SetPoint("TOPLEFT", 8 + (k - 1) * 24, -34)
    w.iconF = ns.IconFrame(w, 20); w.iconF:SetAllPoints()
    w:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(self.name or "")
      GameTooltip:AddLine(L.WITH_REMOVE, 0.8, 0.8, 0.8); GameTooltip:Show()
    end)
    w:SetScript("OnLeave", GameTooltip_Hide)
    w:SetScript("OnClick", function() changeSlot(id, function(x) return ns.RemoveWith(x, k) end) end)
    c.with[k] = w
  end
  c.withAdd = CreateFrame("Button", nil, c)
  c.withAdd:SetSize(100, 20)
  c.withAdd.dash = ns.Shape(c.withAdd, "Dash", "ARTWORK"); c.withAdd.dash:SetAllPoints(); c.withAdd.dash:SetVertexColor(unpack(T.muted))
  c.withAdd.text = ns.Text(c.withAdd, "mono", 10, T.muted); c.withAdd.text:SetPoint("CENTER"); c.withAdd.text:SetText(L.WITH_ADD)
  c.withAdd:SetScript("OnEnter", function(self)
    self.dash:SetVertexColor(unpack(T.brass)); self.text:SetTextColor(unpack(T.ink))
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.WITH_ADD)
    GameTooltip:AddLine(L.WITH_HINT, 0.8, 0.8, 0.8, true); GameTooltip:Show()
  end)
  c.withAdd:SetScript("OnLeave", function(self)
    self.dash:SetVertexColor(unpack(T.muted)); self.text:SetTextColor(unpack(T.muted)); GameTooltip:Hide()
  end)
  c.withAdd:SetScript("OnClick", function() picker:Open(id, "with") end)
  c.mo = ns.Check(c, L.MOUSEOVER)
  c.mo:SetPoint("TOPLEFT", 10, -60)
  c.mo:SetScript("OnClick", function(self)
    local s = setupOf(current).slots[id]
    if not s then return end
    local old = s.mouseover
    s.mouseover = self:GetChecked() and true or false
    commit(function() s.mouseover = old end, id)
  end)
  -- Empty slot: one big dashed button.
  c.choose = CreateFrame("Button", nil, c)
  c.choose:SetPoint("TOPLEFT", 8, -40); c.choose:SetPoint("TOPRIGHT", -8, -40); c.choose:SetHeight(110)
  c.choose.dash = ns.Shape(c.choose, "Dash", "ARTWORK"); c.choose.dash:SetAllPoints()
  c.choose.dash:SetVertexColor(unpack(T.muted))
  c.choose.text = ns.Text(c.choose, "body", 13, T.muted); c.choose.text:SetPoint("LEFT", 10, 0); c.choose.text:SetPoint("RIGHT", -10, 0)
  c.choose.text:SetText(L.CHOOSE)
  c.choose:SetScript("OnEnter", function(self) self.dash:SetVertexColor(unpack(T.brass)); self.text:SetTextColor(unpack(T.ink)) end)
  c.choose:SetScript("OnLeave", function(self) self.dash:SetVertexColor(unpack(T.muted)); self.text:SetTextColor(unpack(T.muted)) end)
  c.choose:SetScript("OnClick", function() picker:Open(id) end)
  -- Steps: one row per spell of a sequence, or the single spell, item or pet command.
  c.steps = {}
  for j = 1, ns.MAXSEQ do
    local r = CreateFrame("Button", nil, c)
    r:SetSize(164, STEP)
    r:SetHighlightTexture(ns.WHITE); r:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.06)
    r.num = ns.Text(r, "mono", 10, T.muted); r.num:SetPoint("LEFT", 2, 0); r.num:SetText(j .. ".")
    r.iconF = ns.IconFrame(r, 18); r.icon = r.iconF.tex
    r.name = ns.Text(r, "body", 13); r.name:SetPoint("LEFT", r.iconF, "RIGHT", 6, 0); r.name:SetPoint("RIGHT", -4, 0)
    r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.lv = ns.Chip(r, "mono", 9, T.fel); r.lv:SetPoint("RIGHT", -2, 0)
    -- Plain slot: click to replace it. Sequence step: hover shows move up, move down, remove.
    r:SetScript("OnClick", function()
      local s = setupOf(current).slots[id]
      if not (s and s.seq) then picker:Open(id) end
    end)
    r.tools = CreateFrame("Frame", nil, r); r.tools:SetAllPoints(); r.tools:Hide()
    r.up = tool(r.tools, "Interface\\Buttons\\Arrow-Up-Up", nil, L.SEQ_UP)
    r.down = tool(r.tools, "Interface\\Buttons\\Arrow-Down-Up", nil, L.SEQ_DOWN)
    r.del = tool(r.tools, nil, "x", L.SEQ_REMOVE)
    r.del:SetPoint("RIGHT", -1, 0); r.down:SetPoint("RIGHT", r.del, "LEFT", -2, 0); r.up:SetPoint("RIGHT", r.down, "LEFT", -2, 0)
    r.up:SetScript("OnClick", function() changeSlot(id, function(x) return ns.MoveStep(x, j, -1) end) end)
    r.down:SetScript("OnClick", function() changeSlot(id, function(x) return ns.MoveStep(x, j, 1) end) end)
    r.del:SetScript("OnClick", function() changeSlot(id, function(x) return ns.RemoveStep(x, j) end) end)
    local function hover() r.tools:SetShown(r.inSeq and r:IsMouseOver() or false) end
    r:SetScript("OnEnter", hover); r:SetScript("OnLeave", hover)
    for _, b in ipairs({ r.up, r.down, r.del }) do b:HookScript("OnLeave", hover) end
    c.steps[j] = r
  end
  -- "+ Add spell": always there under a spell; one spell plus one added makes a cast sequence.
  c.add = CreateFrame("Button", nil, c)
  c.add:SetSize(164, 24)
  c.add.dash = ns.Shape(c.add, "Dash", "ARTWORK"); c.add.dash:SetAllPoints(); c.add.dash:SetVertexColor(unpack(T.void))
  c.add.text = ns.Text(c.add, "mono", 11, T.void); c.add.text:SetPoint("CENTER"); c.add.text:SetText(L.SEQ_ADD)
  c.add:SetScript("OnEnter", function(self) self.dash:SetVertexColor(unpack(T.brass)); self.text:SetTextColor(unpack(T.ink)) end)
  c.add:SetScript("OnLeave", function(self) self.dash:SetVertexColor(unpack(T.void)); self.text:SetTextColor(unpack(T.void)) end)
  c.add:SetScript("OnClick", function() picker:Open(id, true) end)
  c.hint = ns.Text(c, "body", 12, T.muted)
  c.hint:SetPoint("TOPLEFT", c.add, "BOTTOMLEFT", 2, -6); c.hint:SetWidth(160); c.hint:SetJustifyH("LEFT")
  c.hint:SetText(L.SEQ_HINT)
  -- Start over footer (sequences): new target, leave combat, seconds (empty or 0 = off).
  c.foot = CreateFrame("Frame", nil, c)
  c.foot:SetPoint("BOTTOMLEFT", 8, 8); c.foot:SetPoint("BOTTOMRIGHT", -8, 8); c.foot:SetHeight(66)
  local rule = c.foot:CreateTexture(nil, "ARTWORK"); rule:SetColorTexture(unpack(T.line))
  rule:SetPoint("TOPLEFT"); rule:SetPoint("TOPRIGHT"); rule:SetHeight(1)
  c.foot.label = ns.Text(c.foot, "mono", 10, T.brass); c.foot.label:SetPoint("TOPLEFT", 2, -8); c.foot.label:SetText(L.SEQ_START_OVER)
  c.secs = CreateFrame("EditBox", nil, c.foot, "BackdropTemplate")
  c.secs:SetSize(34, 18); c.secs:SetPoint("TOPRIGHT", -16, -4)
  ns.Skin(c.secs, T.well, T.line); c.secs:SetFontObject(ns.Font("mono", 11)); c.secs:SetTextInsets(5, 5, 0, 0)
  c.secs:SetAutoFocus(false); c.secs:SetNumeric(true); c.secs:SetMaxLetters(3)
  local unit = ns.Text(c.foot, "mono", 10, T.muted); unit:SetPoint("LEFT", c.secs, "RIGHT", 3, 0); unit:SetText(L.SEQ_SECS)
  local function seqOf() local s = current and setupOf(current).slots[id]; return s and s.seq and s end
  c.secs:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  c.secs:SetScript("OnEscapePressed", function(self)
    local s = seqOf()
    self:SetText(s and s.reset and s.reset.secs and tostring(s.reset.secs) or ""); self:ClearFocus()
  end)
  c.secs:SetScript("OnEditFocusLost", function(self)
    local v = tonumber(self:GetText())
    if v == 0 then v = nil end
    local s = seqOf()
    if s and (s.reset and s.reset.secs) ~= v then
      changeSlot(id, function(x) x.reset = x.reset or {}; x.reset.secs = v; return x end)
    end
  end)
  c.target, c.combat = ns.Check(c.foot, L.SEQ_NEW_TARGET), ns.Check(c.foot, L.SEQ_LEAVE_COMBAT)
  c.target:SetPoint("TOPLEFT", 2, -30); c.combat:SetPoint("TOPLEFT", 2, -50)
  for field, box in pairs({ target = c.target, combat = c.combat }) do
    box:SetScript("OnClick", function(self)
      local on = self:GetChecked() and true or false
      changeSlot(id, function(x) x.reset = x.reset or {}; x.reset[field] = on; return x end)
    end)
  end
  cols[id] = c
end

-- One column from the slot it edits.
local function drawColumn(c, setup)
  local s = setup.slots[c.id]
  local item, pet, seq = s and s.item, ns.IsPetSlot(s), s and s.seq
  c.key:SetText(ns.ShortKey(current))
  c.del:SetShown(s ~= nil)
  c.mo:SetShown(s ~= nil and not seq)
  c.mo:SetChecked(s and s.mouseover or false); c.mo:SetEnabled(s ~= nil and not item and not pet) -- no mouseover on items/pet
  c.choose:SetShown(s == nil)
  local with = s and s.with or {}
  for k, w in ipairs(c.with) do
    local x = with[k]
    w:SetShown(x ~= nil)
    if x then w.iconF.tex:SetTexture(ns.SpellIcon(x.spellID)); w.name = x.name; w.spellID = x.spellID end
  end
  c.withAdd:SetShown(ns.CanAddWith(s))
  c.withAdd:ClearAllPoints(); c.withAdd:SetPoint("TOPLEFT", 8 + #with * 24, -34)
  local list = seq or (s and { s }) or {}
  local top = seq and -60 or -82
  for j, r in ipairs(c.steps) do
    local x = list[j]
    r:SetShown(x ~= nil)
    if x then
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", 8, top - (j - 1) * STEP)
      local tex, label, known, spellID = ns.SlotView(x)
      r.iconF:ClearAllPoints(); r.iconF:SetPoint("LEFT", 18, 0)
      r.icon:SetTexture(tex); r.spellID = spellID
      r.name:SetText(label)
      -- Spell not learned yet: faded row, grey icon, level chip when What's Training knows it.
      local future = not x.item and not ns.IsPetSlot(x) and not known
      local lv = future and ns.FutureLevel(spellID)
      r:SetAlpha(future and 0.5 or 1); r.icon:SetDesaturated(future or false)
      if lv then r.lv:Set(L.LEVEL:format(lv), 8) end
      r.lv:SetShown(lv and true or false)
      r.name:SetPoint("RIGHT", lv and -(r.lv:GetWidth() + 6) or -4, 0)
      r.inSeq = seq ~= nil
      r.up:SetEnabled(j > 1); r.up:SetAlpha(j > 1 and 1 or 0.3)
      r.down:SetEnabled(j < #list); r.down:SetAlpha(j < #list and 1 or 0.3)
    end
    r.tools:SetShown(x ~= nil and r.inSeq and r:IsMouseOver() or false)
  end
  -- Add under a spell (plain or sequence) while there is room; never for items or pet commands.
  local canAdd = ns.CanAddStep(s)
  c.add:SetShown(canAdd)
  if canAdd then c.add:ClearAllPoints(); c.add:SetPoint("TOPLEFT", 8, top - #list * STEP - 4) end
  c.hint:SetShown(canAdd and not seq)
  c.foot:SetShown(seq ~= nil)
  if seq then
    local reset = s.reset or {}
    c.target:SetChecked(reset.target or false); c.combat:SetChecked(reset.combat or false)
    if not c.secs:HasFocus() then c.secs:SetText(reset.secs and tostring(reset.secs) or "") end
  end
end

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
card.show:SetScript("OnClick", function() preview:SetShown(not preview:IsShown()); card:Refresh() end)

function card:Refresh()
  ns.ResetLearned()
  refreshKeys()
  local on = ns.Manages()
  manageBtn:SetText(L.MANAGE_BTN)
  manageBtn:GetFontString():SetTextColor(unpack(on and T.fel or T.muted))
  manageBtn.track:SetVertexColor(unpack(on and T.fel or T.line))
  manageBtn.knob:ClearAllPoints(); manageBtn.knob:SetPoint("CENTER", manageBtn.track, on and "RIGHT" or "LEFT", on and -7 or 7, 0)
  self.hint:SetText(current and not on and L.DRAG_HINT:format(ns.MacroName(current)) or "")
  for _, w in ipairs({ self.count, self.meter, self.target, self.pet, self.show, self.clear, self.legend, self.swapTip }) do w:SetShown(current ~= nil) end
  for _, c in pairs(cols) do c:SetShown(current ~= nil) end
  if not current then
    self.label:SetText(L.PICK_KEY)
    preview:Hide()
    return
  end
  local setup = pv and (pv.keys[current] or { slots = {} }) or setupOf(current)
  if not pv then before, beforeKey = ns.Copy(setup), current end
  local name = ns.MacroName(current)
  self.label:SetText(L.KEY:format(L["KEY_" .. current] or current) .. "   |cffa99bb7" .. L.MACRO:format(name) .. "|r")
  local text, n = ns.FitMacro(setup, ns.best)
  self.count:SetText(n .. "/" .. ns.MAX)
  local full = math.min(n / ns.MAX, 1)
  self.meter.fill:SetWidth(math.max(1, self.meter:GetWidth() * full))
  self.meter.fill:SetColorTexture(unpack(full > 0.9 and T.brass or T.fel))
  for _, c in pairs(cols) do drawColumn(c, setup) end
  self.target:SetChecked(setup.targetEnemy or false)
  self.pet:SetChecked(setup.petAttack or false)
  self.show:SetText(preview:IsShown() and L.HIDE_MACRO or L.SHOW_MACRO)
  if preview:IsShown() then
    -- One clause per line for reading; the real macro keeps "; " on one line.
    preview.text:SetText(text and ns.ColorMacro((text:gsub(";%s*", ";\n    "))) or "")
    local i = GetMacroIndexByName(name)
    preview.warn:SetText(text and i > 0 and not ns.SameMacro(GetMacroBody(i), text) and L.MACRO_DIFFERS or "")
  end
end

-- Picker: the 4 item categories on top, then pet commands, then learned spells, filtered by the search box, plus Clear.
local ROWS = 12
picker = ns.Panel("FoilKeybindsPicker", keysPane, L.PICK_SPELL)
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

-- append: true adds a sequence step, "with" a cast-with spell; both spells only (no items, no pet commands), no Clear.
function picker:Open(slot, append)
  ns.ScanBags() -- read only, fine in combat; icons show what is in the bags now
  self.slot, self.append, self.offset, self.all = slot, append, 0, {}
  if not append then
    for _, cat in ipairs(ns.ITEMS) do self.all[#self.all + 1] = { item = cat, name = ns.ItemLabel(cat) } end
    self.all[#self.all + 1] = { header = true, fixed = true, name = L.PET_HEADER }
    for _, p in ipairs(ns.PET_CMDS) do self.all[#self.all + 1] = { pet = p, name = ns.PetLabel({ pet = p }) } end
    if ns.PET_SPECIAL[ns.playerClass] then self.all[#self.all + 1] = { petSpecial = true, name = L.PET_SPECIAL } end
  end
  self.clear:SetShown(not append)
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
        b.icon:SetTexture(ns.IsPetSlot(s) and ns.PetIcon(s) or s.item and ns.ItemIcon(s.item) or ns.SpellIcon(s.spellID, s.icon))
        b.icon:SetDesaturated(s.future or false)
      end
    end
  end
end
function picker:Choose(s)
  local slots, slot = setupOf(current).slots, self.slot
  local old = slots[slot]
  if s and self.append == "with" and old then -- cast with: fires first on the same press
    slots[slot] = ns.AddWith(old, { spellID = s.spellID, name = s.name })
  elseif s and self.append and old then -- append: spell goes to the end (AddStep keeps a slot that cannot grow)
    slots[slot] = ns.AddStep(old, { spellID = s.spellID, name = s.name, kind = ns.SpellKind(s.spellID) })
  elseif s and (s.pet or s.petSpecial) then
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

-- Preview of a guide template on this tab: banner in the title bar strip (spec, bracket, Use, Cancel),
-- board and columns show the template, card and columns take no clicks, Apply/Undo/Copy/Refresh items
-- are off. The cheat sheet keeps showing the live (applied) keys. Nothing here writes FoilKeybindsDB.keys.
local banner = CreateFrame("Frame", nil, keysPane)
banner:SetHeight(22); banner:Hide()
banner:SetPoint("LEFT", tabs.settings, "RIGHT", 14, 0); banner:SetPoint("RIGHT", f.close, "LEFT", -6, 0)
ns.RoundSkin(banner, { T.brass[1], T.brass[2], T.brass[3], 0.16 }, T.brass)
banner.cancel = ns.Button(banner, 80, 18, L.PREVIEW_CANCEL)
banner.cancel:SetWidth(math.max(80, banner.cancel:GetFontString():GetStringWidth() + 20)); banner.cancel:SetPoint("RIGHT", -2, 0)
banner.use = ns.Button(banner, 120, 18, L.PREVIEW_USE, T.fel)
banner.use:SetWidth(math.max(120, banner.use:GetFontString():GetStringWidth() + 20)); banner.use:SetPoint("RIGHT", banner.cancel, "LEFT", -6, 0)
banner.text = ns.Text(banner, "bold", 13, T.brass)
banner.text:SetPoint("LEFT", 10, 0); banner.text:SetPoint("RIGHT", banner.use, "LEFT", -8, 0)
banner.text:SetJustifyH("LEFT"); banner.text:SetWordWrap(false)
local cardShield = CreateFrame("Frame", nil, card) -- covers the card: nothing to edit in a preview
cardShield:SetAllPoints(); cardShield:SetFrameLevel(card:GetFrameLevel() + 30); cardShield:EnableMouse(true); cardShield:Hide()
ns.RoundSkin(cardShield, T.panel, { T.brass[1], T.brass[2], T.brass[3], 0.6 })
cardShield.text = ns.Text(cardShield, "body", 14, T.muted)
cardShield.text:SetPoint("LEFT", 28, 0); cardShield.text:SetPoint("RIGHT", -28, 0); cardShield.text:SetText(L.PREVIEW_READONLY)
local colShield = CreateFrame("Frame", nil, keysPane) -- see-through: the columns show, clicks and drags stop here
colShield:SetPoint("TOPLEFT", cols.normal, "TOPLEFT"); colShield:SetPoint("BOTTOMRIGHT", cols.altshift, "BOTTOMRIGHT")
colShield:SetFrameLevel(cols.normal:GetFrameLevel() + 30); colShield:EnableMouse(true); colShield:Hide()
local function previewLook(on)
  for _, b in ipairs({ applyBtn, undoBtn, copyBtn, itemsBtn, manageBtn, resetBtn }) do b:SetEnabled(not on); b:SetAlpha(on and 0.4 or 1) end
  banner:SetShown(on); cardShield:SetShown(on); colShield:SetShown(on)
  view.rLine:SetVertexColor(unpack(on and T.brass or T.line))
end
-- keys: a fresh table (ns.TemplateKeys output), never the guide data. use(keys) runs on "Use this layout";
-- false keeps the preview open (spell data still loading).
-- The columns show the selected key when the template has it, else its first key in board order.
-- wiz (Wizard.lua, called again on every step): sel = the key to select (false: none), click(key) gets
-- the canvas clicks, stop() runs when the preview ends (Use, Cancel, leaving the tab, closing the window).
function ns.StartPreview(keys, title, use, wiz)
  local box = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if box then box:ClearFocus() end -- a seconds box commits to the live keys first
  picker:Hide(); preview:Hide() -- the macro panel would say "Live macro differs" about a template key
  showTab("keys")
  local was = pv and pv.was or current
  pv = { keys = keys, use = use, was = was, wiz = wiz }
  if wiz and wiz.sel ~= nil then current = wiz.sel or nil
  elseif not (current and keys[current]) then
    current = nil
    for _, k in ipairs(ns.BOARD) do if keys[k] then current = k; break end end
  end
  banner.text:SetText(title)
  previewLook(true)
  card:Refresh()
end
-- Back to the live keys and the key selected before (no live key is created for the preview's pick).
function ns.CancelPreview()
  if not pv then return end
  local wiz = pv.wiz
  current, pv = pv.was, nil
  previewLook(false)
  if wiz then wiz.stop() end
  card:Refresh()
end
function ns.InPreview() return pv ~= nil end
banner.cancel:SetScript("OnClick", ns.CancelPreview)
banner.use:SetScript("OnClick", function()
  if pv.use(pv.keys) ~= false then ns.CancelPreview() end
end)

-- While shown: spells learned redraw the window, loaded spell data updates the icons of that spell,
-- talent changes redraw the Guide tab ("yours" follows the points).
local LIVE = { "SPELLS_CHANGED", "SPELL_DATA_LOAD_RESULT", "TRAIT_CONFIG_UPDATED" }
f:SetScript("OnShow", function(self)
  for _, e in ipairs(LIVE) do self:RegisterEvent(e) end
  self:Raise() -- on top of other HIGH frames (SetToplevel only raises on click)
  ns.ScanBags(); card:Refresh()
end)
f:SetScript("OnHide", function(self)
  for _, e in ipairs(LIVE) do self:UnregisterEvent(e) end
  ns.CancelPreview() -- closing the window cancels a preview
end)
local function loaded(id)
  for _, b in pairs(keyButtons) do
    if b.big.spellID == id then b.big.tex:SetTexture(ns.SpellIcon(id)) end
    if b.withF.spellID == id then b.withF.tex:SetTexture(ns.SpellIcon(id)) end
  end
  for _, c in pairs(cols) do
    for _, r in ipairs(c.steps) do if r:IsShown() and r.spellID == id then r.icon:SetTexture(ns.SpellIcon(id)) end end
    for _, w in ipairs(c.with) do if w:IsShown() and w.spellID == id then w.iconF.tex:SetTexture(ns.SpellIcon(id)) end end
  end
  for _, b in ipairs(picker.rows) do
    if b:IsShown() and b.spell and b.spell.spellID == id then b.icon:SetTexture(ns.SpellIcon(id, b.spell.icon)) end
  end
  if ns.GuideSpellLoaded then ns.GuideSpellLoaded(id) end
end
function ns.Refresh()
  if f:IsShown() then card:Refresh() end
  if ns.RefreshCheat then ns.RefreshCheat() end -- the cheat sheet is often open with the window closed
end

function FoilKeybinds_Toggle()
  if f:IsShown() and f.tab == "keys" then f:Hide() else ns.OpenWindow("keys") end
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, name, ok)
  if event == "SPELLS_CHANGED" then if ns.RefreshGuide then ns.RefreshGuide() end; return card:Refresh() end
  if event == "SPELL_DATA_LOAD_RESULT" then if ok then loaded(name) end; return end
  if event == "TRAIT_CONFIG_UPDATED" then if ns.RefreshGuide then ns.RefreshGuide() end; return end
  if name ~= "FoilKeybinds" then return end
  FoilKeybindsDB = FoilKeybindsDB or {}
  FoilKeybindsDB.keys = FoilKeybindsDB.keys or {}
  FoilKeybindsAccount = FoilKeybindsAccount or {}
  FoilKeybindsDB.manage = ns.ManageStart(FoilKeybindsDB.manage, FoilKeybindsDB.applied)
  for key, setup in pairs(FoilKeybindsDB.keys) do -- ticket 01 stored { normal = "Name" }, drop it
    if not setup.slots then FoilKeybindsDB.keys[key] = { slots = {} } end
  end
  -- Account-wide settings. First run keeps this character's cheat sheet scale and lock.
  local c = FoilKeybindsDB.cheat or {}
  ns.S = ns.MergeSettings(FoilKeybindsAccount.settings or { cheatScale = c.scale, cheatLock = c.locked })
  FoilKeybindsAccount.settings = ns.S
  ns.ApplySettings()
end)

-- /fkb toggles the window. /fkb set <KEY> <Spell> fills a key's normal slot from the spellbook (live keys,
-- even during a preview). /fkb guide (guia) opens the Guide tab, /fkb wizard (assistente) too, with the
-- wizard's step 1 line. The first /fkb of a character with no keys opens it with the new-player hint, once.
SLASH_FOILKEYBINDS1 = "/fkb"
local function hasKeys() for _, setup in pairs(FoilKeybindsDB.keys) do if next(setup.slots) then return true end end end
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
  elseif (word == "apply" or word == "undo" or word == "reset") and ns.InPreview() then ns.Say(L.PREVIEW_BUSY)
  elseif word == "apply" then ns.Apply()
  elseif word == "undo" then ns.UndoStep()
  elseif word == "reset" then ns.ResetAll()
  elseif word == "items" or word == "itens" then ns.SwapItems(true)
  elseif word == "cheat" or word == "cola" then ns.ToggleCheat()
  elseif CONFIG[word] then ns.OpenWindow("settings")
  elseif word == "guide" or word == "guia" then ns.OpenWindow("guide")
  elseif word == "wizard" or word == "assistente" then ns.guide.hint = L.WIZARD_STEP1; ns.OpenWindow("guide")
  elseif not (FoilKeybindsDB.wizard and FoilKeybindsDB.wizard.seen) and not hasKeys() then
    FoilKeybindsDB.wizard = FoilKeybindsDB.wizard or {}
    FoilKeybindsDB.wizard.seen = true
    ns.guide.hint = L.WIZARD_HINT; ns.OpenWindow("guide")
  else FoilKeybinds_Toggle() end
end
