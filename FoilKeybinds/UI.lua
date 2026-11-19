local _, ns = ...
local L = ns.L
local T = ns.T

local f = ns.Panel("FoilKeybindsFrame", UIParent, L.TITLE)
f:SetSize(960, 700); f:SetPoint("CENTER")
f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "FoilKeybindsFrame") -- Esc closes it
function ns.SetMainScale(v) f:SetScale(v) end

-- Tabs at the top: Keys | Settings. One window, so closing it closes both.
local keysPane = CreateFrame("Frame", nil, f); keysPane:SetAllPoints()
ns.settingsPane = CreateFrame("Frame", nil, f) -- Settings.lua builds the page in it
ns.settingsPane:SetPoint("TOPLEFT", 0, -28); ns.settingsPane:SetPoint("BOTTOMRIGHT"); ns.settingsPane:Hide()
local tabs = {}
local function showTab(name)
  f.tab = name
  keysPane:SetShown(name == "keys"); ns.settingsPane:SetShown(name == "settings")
  for n, b in pairs(tabs) do b:GetFontString():SetTextColor(unpack(n == name and T.brass or T.muted)) end
end
for i, t in ipairs({ { "keys", L.TAB_KEYS }, { "settings", L.SETTINGS } }) do
  local b = ns.Button(f, 90, 20, t[2])
  b:SetPoint("LEFT", f.title, "RIGHT", 18 + (i - 1) * 96, 0)
  b:SetScript("OnClick", function() showTab(t[1]) end)
  tabs[t[1]] = b
end
showTab("keys")
-- Opens the window on a tab (keys or settings).
function ns.OpenWindow(tab) f:Show(); showTab(tab) end

local applyBtn = ns.Button(keysPane, 140, 26, L.APPLY, T.fel)
applyBtn:SetPoint("BOTTOMRIGHT", -16, 14)
applyBtn:SetScript("OnClick", function() ns.Apply() end)
local undoBtn = ns.Button(keysPane, 100, 26, L.UNDO)
undoBtn:SetPoint("RIGHT", applyBtn, "LEFT", -8, 0)
undoBtn:SetScript("OnClick", function() ns.Undo() end)

local copyBtn = ns.Button(keysPane, 120, 26, L.COPY_FROM)
copyBtn:SetPoint("RIGHT", undoBtn, "LEFT", -8, 0)
copyBtn:SetScript("OnClick", function(self)
  local me, class = ns.Me()
  local list = ns.SameClass(FoilKeybindsAccount, class, me)
  if #list == 0 then return ns.Say(L.COPY_NONE) end
  MenuUtil.CreateContextMenu(self, function(_, root)
    for _, name in ipairs(list) do root:CreateButton(name, function() ns.CopyFrom(name) end) end
  end)
end)

local itemsBtn = ns.Button(keysPane, 120, 26, L.REFRESH_ITEMS)
itemsBtn:SetPoint("RIGHT", copyBtn, "LEFT", -8, 0)
itemsBtn:SetScript("OnClick", function() ns.SwapItems(true) end)

-- Master switch: bars and keybinds ON/OFF, always in sight next to Apply.
local manageBtn = ns.Button(keysPane, 236, 26)
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

-- A seconds box with focus commits on focus loss, so it must lose focus while current is still its key.
local function selectKey(key)
  local box = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if box then box:ClearFocus() end
  current = key; picker:Hide(); card.msg:SetText(""); card:Refresh()
end

-- Board: keys near WASD plus the mouse, fixed in the top strip at one scale (no pan, no zoom).
local BOARD_SCALE = 0.66
local view = CreateFrame("Frame", nil, keysPane)
view:SetPoint("TOPLEFT", 12, -38); view:SetSize(468, 248)
ns.RoundSkin(view, { T.panel[1], T.panel[2], T.panel[3], 0.7 }, T.line)
local board = CreateFrame("Frame", nil, view)
board:SetSize(680, 350); board:SetScale(BOARD_SCALE)
board:SetPoint("TOPLEFT", view, "TOPLEFT", 12 / BOARD_SCALE, -10 / BOARD_SCALE)
local cheatBtn = ns.Button(keysPane, 110, 26, L.CHEAT_TITLE)
cheatBtn:SetPoint("BOTTOMLEFT", 12, 14)
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
  local setup = FoilKeybindsDB.keys[key]
  for _, id in ipairs(ns.COLUMNS) do
    local s = setup and setup.slots[id]
    if s then
      local _, name, known, spellID = ns.SlotView(s)
      GameTooltip:AddDoubleLine(L["SLOT_" .. id], name, 0.84, 0.69, 0.4, 1, 1, 1)
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
ns.KEY_ORDER = {} -- editable keys in canvas order, for the cheat sheet
for _, k in ipairs(LAYOUT) do
  local key = k[1]
  local b = CreateFrame("Button", nil, board)
  b:SetSize(K + ((k[4] or 1) - 1) * U, K)
  b:SetPoint("TOPLEFT", k[2] * U, -k[3] * U); b:SetFrameLevel(mouse:GetFrameLevel() + 2)
  b.label = ns.Text(b, "mono", 12)
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
    b.big.badge = ns.Text(b.big, "mono", 10)
    b.big.badge:SetPoint("BOTTOMRIGHT", 2, -1); b.big.badge:SetShadowColor(0, 0, 0, 1); b.big.badge:SetShadowOffset(1, -1)
    -- Modifier slots: four dots along the bottom, filled when the slot is used.
    b.dots = {}
    for j, id in ipairs(DOTS) do
      local d = ns.Shape(b, "Dot", "ARTWORK"); d:SetSize(9, 9); d:SetPoint("BOTTOM", (j - 2.5) * 13, 9)
      d.slot = id; b.dots[j] = d
    end
    keyButtons[key] = b
  end
end

function ns.SetKeyIconSize(n) for _, b in pairs(keyButtons) do b.big:SetSize(n, n) end end

-- Redraws every key: plain press icon, filled dots, selected key glows in brass.
refreshKeys = function()
  for key, b in pairs(keyButtons) do
    local setup = FoilKeybindsDB.keys[key]
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
    for _, d in ipairs(b.dots) do
      local used = setup and setup.slots[d.slot]
      if used then d:SetVertexColor(unpack(T.void)) else d:SetVertexColor(T.line[1], T.line[2], T.line[3], 0.9) end
    end
  end
end

-- Key panel: right of the board. Key and macro name, size meter, the two key toggles, Show macro,
-- the dot legend, the fit messages and the switch OFF hint.
card = CreateFrame("Frame", nil, keysPane)
card:SetPoint("TOPLEFT", view, "TOPRIGHT", 12, 0); card:SetPoint("BOTTOMRIGHT", keysPane, "TOPRIGHT", -12, -286)
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
-- Dot legend: what the four dots on a key mean.
card.legend = CreateFrame("Frame", nil, card)
card.legend:SetPoint("TOPLEFT", 14, -134); card.legend:SetSize(420, 14)
do
  local x = 0
  for _, id in ipairs(DOTS) do
    local d = ns.Shape(card.legend, "Dot", "ARTWORK"); d:SetSize(9, 9); d:SetPoint("LEFT", x, 0); d:SetVertexColor(unpack(T.void))
    local t = ns.Text(card.legend, "mono", 10, T.muted); t:SetPoint("LEFT", d, "RIGHT", 4, 0); t:SetText(L["SLOT_" .. id])
    x = x + 9 + 4 + t:GetStringWidth() + 12
  end
  local t = ns.Text(card.legend, "body", 12, T.muted); t:SetPoint("LEFT", x, 0); t:SetText(L.DOT_LEGEND)
end
card.msg = ns.Text(card, "body", 13, T.blood)
card.msg:SetPoint("TOPLEFT", 14, -156); card.msg:SetPoint("RIGHT", -14, 0); card.msg:SetJustifyH("LEFT")
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
for i, id in ipairs(ns.COLUMNS) do
  local c = CreateFrame("Frame", nil, keysPane)
  c:SetSize(180, 350); c:SetPoint("TOPLEFT", 12 + (i - 1) * 189, -296)
  ns.RoundSkin(c, T.panel, T.line)
  c.id = id
  c.mod = ns.Chip(c, "mono", 9); c.mod:SetPoint("TOPLEFT", 8, -8); c.mod:Set(L["SLOT_" .. id], 8)
  c.key = ns.Text(c, "mono", 11, T.muted); c.key:SetPoint("LEFT", c.mod, "RIGHT", 6, 0)
  c.key:SetWidth(90); c.key:SetJustifyH("LEFT"); c.key:SetWordWrap(false)
  -- Trash: same path as the picker's Clear slot.
  c.del = CreateFrame("Button", nil, c)
  c.del:SetSize(18, 18); c.del:SetPoint("TOPRIGHT", -8, -8)
  -- SetNormalAtlas does not error on a missing atlas, so check it exists first.
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("common-icon-delete") then
    c.del:SetNormalAtlas("common-icon-delete")
  else
    c.del:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
  end
  local trash = c.del:GetNormalTexture()
  trash:SetDesaturated(true); trash:SetVertexColor(unpack(T.muted))
  c.del:SetScript("OnClick", function() picker.slot = id; picker:Choose(nil) end)
  c.del:SetScript("OnEnter", function(self)
    trash:SetDesaturated(false); trash:SetVertexColor(unpack(T.blood))
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.CLEAR); GameTooltip:AddLine(L.CLEAR_HINT, 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  c.del:SetScript("OnLeave", function()
    trash:SetDesaturated(true); trash:SetVertexColor(unpack(T.muted)); GameTooltip:Hide()
  end)
  c.mo = ns.Check(c, L.MOUSEOVER)
  c.mo:SetPoint("TOPLEFT", 10, -34)
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
  c.key:SetText(L["KEY_" .. current] or current)
  c.del:SetShown(s ~= nil)
  c.mo:SetShown(s ~= nil and not seq)
  c.mo:SetChecked(s and s.mouseover or false); c.mo:SetEnabled(s ~= nil and not item and not pet) -- no mouseover on items/pet
  c.choose:SetShown(s == nil)
  local list = seq or (s and { s }) or {}
  local top = seq and -40 or -58
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
  manageBtn:SetText(L.MANAGE_BTN:format(on and L.ON or L.OFF))
  manageBtn:GetFontString():SetTextColor(unpack(on and T.fel or T.muted))
  manageBtn.track:SetVertexColor(unpack(on and T.fel or T.line))
  manageBtn.knob:ClearAllPoints(); manageBtn.knob:SetPoint("CENTER", manageBtn.track, on and "RIGHT" or "LEFT", on and -7 or 7, 0)
  self.hint:SetText(current and not on and L.DRAG_HINT:format(ns.MacroName(current)) or "")
  for _, w in ipairs({ self.count, self.meter, self.target, self.pet, self.show, self.legend }) do w:SetShown(current ~= nil) end
  for _, c in pairs(cols) do c:SetShown(current ~= nil) end
  if not current then
    self.label:SetText(L.PICK_KEY)
    preview:Hide()
    return
  end
  local setup = setupOf(current)
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

-- append: adding to a cast sequence, so spells only (no items, no pet commands) and no Clear.
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
  if s and self.append and old then -- append: spell goes to the end (AddStep keeps a slot that cannot grow)
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

-- While shown: spells learned redraw the window, loaded spell data updates the icons of that spell.
local LIVE = { "SPELLS_CHANGED", "SPELL_DATA_LOAD_RESULT" }
f:SetScript("OnShow", function(self)
  for _, e in ipairs(LIVE) do self:RegisterEvent(e) end
  ns.ScanBags(); card:Refresh()
end)
f:SetScript("OnHide", function(self) for _, e in ipairs(LIVE) do self:UnregisterEvent(e) end end)
local function loaded(id)
  for _, b in pairs(keyButtons) do if b.big.spellID == id then b.big.tex:SetTexture(ns.SpellIcon(id)) end end
  for _, c in pairs(cols) do
    for _, r in ipairs(c.steps) do if r:IsShown() and r.spellID == id then r.icon:SetTexture(ns.SpellIcon(id)) end end
  end
  for _, b in ipairs(picker.rows) do
    if b:IsShown() and b.spell and b.spell.spellID == id then b.icon:SetTexture(ns.SpellIcon(id, b.spell.icon)) end
  end
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
  if event == "SPELLS_CHANGED" then return card:Refresh() end
  if event == "SPELL_DATA_LOAD_RESULT" then if ok then loaded(name) end; return end
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
  elseif word == "items" or word == "itens" then ns.SwapItems(true)
  elseif word == "cheat" or word == "cola" then ns.ToggleCheat()
  elseif CONFIG[word] then ns.OpenWindow("settings")
  else FoilKeybinds_Toggle() end
end
