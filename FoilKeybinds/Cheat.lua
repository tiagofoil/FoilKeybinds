-- Cheat sheet: a small floating grid of what is live in game (FoilKeybindsDB.applied), one row per
-- key, one column per modifier. The column of the held modifier lights up. Only textures and font
-- strings, nothing protected, so it shows, hides and locks fine in combat.
local _, ns = ...
local L, T = ns.L, ns.T

local COLS = { "normal", "shift", "alt", "altshift", "ctrl" } -- left to right
local PAD, KEYW, COLW, ICON, TOP, HEAD, ROW = 8, 56, 34, 24, 32, 18, 30
local W = PAD * 2 + KEYW + #COLS * COLW
local QUESTION = 134400

local function db()
  FoilKeybindsDB.cheat = FoilKeybindsDB.cheat or {}
  return FoilKeybindsDB.cheat
end

local p = ns.Panel(nil, UIParent, L.CHEAT_TITLE)
p:SetWidth(W); p:SetPoint("CENTER", 300, 0); p:SetClampedToScreen(true); p:SetMovable(true)
p:SetFrameStrata("MEDIUM"); p:Hide()

local function startMove() p:StartMoving() end
local function stopMove()
  p:StopMovingOrSizing()
  local point, _, rel, x, y = p:GetPoint() -- never save the relativeTo frame itself
  local c = db()
  c.point, c.rel, c.x, c.y = point, rel, x, y
end
local function wheel(_, d)
  local c, old = db(), p:GetScale()
  local new = math.max(0.6, math.min(1.6, math.floor((old + d * 0.1) * 10 + 0.5) / 10))
  if new == old then return end
  local point, _, rel, x, y = p:GetPoint()
  x, y = x * old / new, y * old / new -- offsets are in the frame's own scale: keep it on the same spot
  p:SetScale(new); p:ClearAllPoints(); p:SetPoint(point, UIParent, rel, x, y)
  c.scale, c.point, c.rel, c.x, c.y = new, point, rel, x, y
end
p:RegisterForDrag("LeftButton")
p:SetScript("OnDragStart", startMove); p:SetScript("OnDragStop", stopMove)
p:SetScript("OnMouseWheel", wheel)

local lock = ns.Check(p, L.CHEAT_LOCK)
lock:SetPoint("RIGHT", p.close, "LEFT", -(lock.text:GetStringWidth() + 10), 0)

local heads, stripes = {}, {}
for c, id in ipairs(COLS) do
  local cx = PAD + KEYW + (c - 0.5) * COLW
  heads[id] = ns.Text(p, "mono", 10, T.muted)
  heads[id]:SetPoint("CENTER", p, "TOPLEFT", cx, -(TOP + HEAD / 2))
  heads[id]:SetText(L["CHEAT_COL_" .. id])
  stripes[id] = p:CreateTexture(nil, "BORDER", nil, 3)
  stripes[id]:SetColorTexture(T.void[1], T.void[2], T.void[3], 0.16)
  stripes[id]:SetPoint("TOPLEFT", p, "TOPLEFT", cx - COLW / 2 + 1, -TOP)
  stripes[id]:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", cx - COLW / 2 + 1, 6)
  stripes[id]:SetWidth(COLW - 2)
end
local empty = ns.Text(p, "body", 13, T.muted)
empty:SetPoint("TOPLEFT", PAD + 2, -(TOP + 4)); empty:SetWidth(W - PAD * 2 - 4)
empty:SetJustifyH("LEFT"); empty:SetText(L.CHEAT_EMPTY)

local function tip(self)
  if not self.name then return end
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(L["SLOT_" .. self.slot] .. ": " .. self.name)
  if not self.known then
    local lv = ns.FutureLevel(self.spellID)
    GameTooltip:AddLine(lv and L.NOT_KNOWN_LEVEL:format(lv) or L.NOT_KNOWN, 0.6, 0.6, 0.6)
  end
  GameTooltip:Show()
end

local rows, used = {}, 0
local function row(i)
  if rows[i] then return rows[i] end
  local r, cy = { cells = {} }, -(TOP + HEAD + (i - 0.5) * ROW)
  r.key = ns.Text(p, "mono", 11)
  r.key:SetPoint("LEFT", p, "TOPLEFT", PAD + 2, cy); r.key:SetWidth(KEYW - 4)
  r.key:SetJustifyH("LEFT"); r.key:SetWordWrap(false)
  for c, id in ipairs(COLS) do
    local cell = ns.IconFrame(p, ICON)
    cell:SetPoint("CENTER", p, "TOPLEFT", PAD + KEYW + (c - 0.5) * COLW, cy)
    cell.slot = id
    cell:RegisterForDrag("LeftButton") -- cells take the mouse for tooltips, so they pass drags on
    cell:SetScript("OnDragStart", startMove); cell:SetScript("OnDragStop", stopMove)
    cell:SetScript("OnMouseWheel", wheel)
    cell:SetScript("OnEnter", tip); cell:SetScript("OnLeave", GameTooltip_Hide)
    r.cells[id] = cell
  end
  rows[i] = r
  return r
end

-- Locked: click-through everywhere except the lock box, so it never eats a click in combat.
local function applyLock()
  local on = not db().locked
  lock:SetChecked(not on)
  p:EnableMouse(on); p:EnableMouseWheel(on); p.close:SetShown(on)
  for _, r in ipairs(rows) do
    for _, cell in pairs(r.cells) do cell:EnableMouse(on); cell:EnableMouseWheel(on) end
  end
  if not on and GameTooltip:GetOwner() and GameTooltip:GetOwner():GetParent() == p then GameTooltip:Hide() end
end

-- Lights up the column the held modifiers fire (same order as the macro), dims the rest.
local function paint()
  local hot = ns.ModColumn(IsShiftKeyDown(), IsAltKeyDown(), IsControlKeyDown())
  for _, id in ipairs(COLS) do
    local on = id == hot
    heads[id]:SetTextColor(unpack(on and T.brass or T.muted))
    stripes[id]:SetShown(on and used > 0)
    for i = 1, used do
      local cell = rows[i].cells[id]
      cell:SetAlpha(cell.base * (on and 1 or 0.5))
    end
  end
end

local function fill(cell, s)
  local tex, name, known, spellID
  if ns.IsPetSlot(s) then tex, name, known = ns.PetIcon(s), ns.PetLabel(s), true
  elseif s and s.item then tex, name, known = ns.ItemIcon(s.item), ns.ItemLabel(s.item), true
  elseif s and s.name then
    tex, name, known, spellID = ns.SpellIcon(s.spellID) or QUESTION, s.name, ns.IsKnown(s.spellID), s.spellID
  end
  cell.name, cell.known, cell.spellID = name, known, spellID
  cell.tex:SetTexture(tex); cell.tex:SetShown(tex ~= nil); cell.tex:SetDesaturated(name ~= nil and not known)
  local edge = name and { T.brass[1], T.brass[2], T.brass[3], 0.55 } or T.line
  cell:SetBackdropBorderColor(unpack(edge))
  cell:SetBackdropColor(unpack(name and T.keyEdge or T.well))
  cell.base = not name and 0.35 or known and 1 or 0.4
end

local function refresh()
  local applied = FoilKeybindsDB.applied or {}
  local list, seen, extra = {}, {}, {}
  for _, k in ipairs(ns.KEY_ORDER) do
    if applied[k] then list[#list + 1] = k; seen[k] = true end
  end
  for k in pairs(applied) do if not seen[k] then extra[#extra + 1] = k end end -- keys set with /fkb set
  table.sort(extra)
  for _, k in ipairs(extra) do list[#list + 1] = k end
  for i, key in ipairs(list) do
    local r = row(i)
    r.key:SetText(L["KEY_" .. key] or key); r.key:Show()
    for _, id in ipairs(COLS) do fill(r.cells[id], applied[key].slots[id]); r.cells[id]:Show() end
  end
  for i = #list + 1, #rows do
    rows[i].key:Hide()
    for _, cell in pairs(rows[i].cells) do cell.name = nil; cell:Hide() end
  end
  used = #list
  for _, id in ipairs(COLS) do heads[id]:SetShown(used > 0) end
  empty:SetShown(used == 0)
  p:SetHeight(used > 0 and TOP + HEAD + used * ROW + 6 or TOP + empty:GetStringHeight() + 16)
  applyLock(); paint()
end

function ns.RefreshCheat() if p:IsShown() then refresh() end end

-- show nil toggles. The saved flag is written only here, never from OnHide (Alt+Z and
-- cinematics hide UIParent and would clear it).
function ns.ToggleCheat(show)
  if show == nil then show = not p:IsShown() end
  db().shown = show
  p:SetShown(show)
end
p.close:SetScript("OnClick", function() ns.ToggleCheat(false) end)
lock:SetScript("OnClick", function(self) db().locked = self:GetChecked() and true or false; applyLock() end)

local LIVE = { "MODIFIER_STATE_CHANGED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP" }
p:SetScript("OnShow", function(self)
  for _, e in ipairs(LIVE) do self:RegisterEvent(e) end
  refresh()
end)
p:SetScript("OnHide", function(self)
  for _, e in ipairs(LIVE) do self:UnregisterEvent(e) end
end)
p:RegisterEvent("PLAYER_LOGIN")
p:SetScript("OnEvent", function(self, event)
  if event == "MODIFIER_STATE_CHANGED" then return paint() end
  if event == "PLAYER_LOGIN" then
    local c = db()
    self:SetScale(c.scale or 1) -- scale before the point: offsets are in the frame's scale
    if c.point then self:ClearAllPoints(); self:SetPoint(c.point, UIParent, c.rel, c.x, c.y) end
    applyLock()
    self:SetShown(c.shown or false)
    return
  end
  refresh() -- spells learned or level up: future spells stop fading
end)
