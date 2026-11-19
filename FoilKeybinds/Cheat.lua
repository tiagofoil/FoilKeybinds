-- Cheat sheet: a small floating view of what is live in game (FoilKeybindsDB.applied). Layouts:
-- "rows" (one row per key, one column per modifier), "cols" (the same turned sideways) and "keyboard" (keys placed like the canvas, big
-- normal icon plus 4 small modifier icons). What the held modifier fires lights up. Only textures and
-- font strings, nothing protected, so it shows, hides and locks fine in combat.
-- Saved: position and shown per character (FoilKeybindsDB.cheat); scale, lock and look account-wide
-- (ns.S, see Settings.lua). Layout is computed on every refresh from the settings.
local _, ns = ...
local L, T = ns.L, ns.T

local COLS = { "normal", "shift", "alt", "altshift", "ctrl" } -- left to right
local MODS = { "shift", "alt", "altshift", "ctrl" } -- small icons on a keyboard key, same order
local PAD, TOP, HEAD = 8, 32, 18

local function db()
  FoilKeybindsDB.cheat = FoilKeybindsDB.cheat or {}
  return FoilKeybindsDB.cheat
end

local p = ns.Panel(nil, UIParent, L.CHEAT_TITLE)
p:SetSize(242, 60); p:SetPoint("CENTER", 300, 0); p:SetClampedToScreen(true); p:SetMovable(true)
p:SetFrameStrata("MEDIUM"); p:Hide()

local function savePoint()
  local point, _, rel, x, y = p:GetPoint() -- never save the relativeTo frame itself
  local c = db()
  c.point, c.rel, c.x, c.y, c.pscale = point, rel, x, y, p:GetScale()
end
local function startMove() p:StartMoving() end
local function stopMove() p:StopMovingOrSizing(); savePoint() end

-- New scale with the sheet kept on the same spot: offsets are in the frame's own scale.
function ns.SetCheatScale(new)
  local old = p:GetScale()
  if new == old then return end
  local point, _, rel, x, y = p:GetPoint()
  p:SetScale(new); p:ClearAllPoints(); p:SetPoint(point, UIParent, rel, x * old / new, y * old / new)
  savePoint()
end
local function wheel(_, d) ns.SetSetting("cheatScale", ns.S.cheatScale + d * 0.1) end

p:RegisterForDrag("LeftButton")
p:SetScript("OnDragStart", startMove); p:SetScript("OnDragStop", stopMove)
p:SetScript("OnMouseWheel", wheel)

local lock = ns.Check(p, L.CHEAT_LOCK)
lock:SetPoint("RIGHT", p.close, "LEFT", -(lock.text:GetStringWidth() + 10), 0)

-- Title bar (title, lock box, x): always on when unlocked; when locked only while the mouse is
-- over the sheet. Called from the enter/leave of the sheet and of its two buttons, so no polling.
local function chrome()
  local s = ns.S
  local on = s.cheatBg > 0 and (not s.cheatLock or p:IsMouseOver())
  p.title:SetShown(on); lock:SetShown(on); p.close:SetShown(on); p.bar:SetShown(on); p.rule:SetShown(on)
end
p:SetScript("OnEnter", chrome); p:SetScript("OnLeave", chrome)
lock:HookScript("OnLeave", chrome); p.close:HookScript("OnLeave", chrome)

-- Labels sit on the game world when the background is faint: a shadow keeps them readable.
local function shade(fs) fs:SetShadowColor(0, 0, 0, 1); fs:SetShadowOffset(1, -1); return fs end

local heads, stripes = {}, {}
for _, id in ipairs(COLS) do
  heads[id] = shade(ns.Text(p, "mono", 10, T.muted))
  heads[id]:SetText(L["CHEAT_COL_" .. id])
  stripes[id] = p:CreateTexture(nil, "BORDER", nil, 3)
  stripes[id]:SetColorTexture(T.void[1], T.void[2], T.void[3], 0.16)
end
local empty = ns.Text(p, "body", 13, T.muted)
empty:SetWidth(226); empty:SetJustifyH("LEFT"); empty:SetText(L.CHEAT_EMPTY)

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

local cells, live = {}, {} -- every icon cell (for the lock); cells shown by the last refresh (for paint)
local function newCell(parent, slot)
  local cell = ns.IconFrame(parent, 24)
  cell.slot, cell.cheat = slot, true
  cell.badge = shade(ns.Text(cell, "mono", 10)) -- sequence length
  cell.badge:SetPoint("BOTTOMRIGHT", 1, 0)
  cell:RegisterForDrag("LeftButton") -- cells take the mouse for tooltips, so they pass drags on
  cell:SetScript("OnDragStart", startMove); cell:SetScript("OnDragStop", stopMove)
  cell:SetScript("OnMouseWheel", wheel)
  cell:SetScript("OnEnter", tip); cell:SetScript("OnLeave", GameTooltip_Hide)
  cells[#cells + 1] = cell
  return cell
end

local rows, caps = {}, {}
local function row(i)
  if rows[i] then return rows[i] end
  local r = { cells = {} }
  r.key = shade(ns.Text(p, "mono", 11)); r.key:SetJustifyH("LEFT"); r.key:SetWordWrap(false)
  for _, id in ipairs(COLS) do r.cells[id] = newCell(p, id) end
  rows[i] = r
  return r
end
local function cap(key) -- one keyboard key: a key-cap frame holding its 5 cells
  if caps[key] then return caps[key] end
  local k = { cells = {} }
  k.frame = CreateFrame("Frame", nil, p, "BackdropTemplate")
  ns.Skin(k.frame, T.keyBot, T.line)
  k.label = shade(ns.Text(k.frame, "mono", 9, T.muted)); k.label:SetPoint("TOPLEFT", 4, -3)
  for _, id in ipairs(COLS) do k.cells[id] = newCell(k.frame, id) end
  caps[key] = k
  return k
end

-- Locked: clicks and wheel pass through, so it never eats a click in combat. The sheet still
-- sees the mouse move over it, to show the title bar on hover.
local function applyLock()
  local on = not ns.S.cheatLock
  lock:SetChecked(not on)
  p:EnableMouse(true); p:SetMouseClickEnabled(on); p:EnableMouseWheel(on)
  for _, cell in ipairs(cells) do cell:EnableMouse(on); cell:EnableMouseWheel(on) end
  local owner = GameTooltip:GetOwner()
  if not on and owner and owner.cheat then GameTooltip:Hide() end
  chrome()
end

-- Lights up what the held modifiers fire (same order as the macro), dims the rest.
local rowsMode, used = true, 0
local function paint()
  local glow = ns.S.cheatHighlight
  local hot = ns.ModColumn(IsShiftKeyDown(), IsAltKeyDown(), IsControlKeyDown())
  for _, id in ipairs(COLS) do
    local on = id == hot
    heads[id]:SetTextColor(unpack(on and glow and T.brass or T.muted))
    stripes[id]:SetShown(rowsMode and glow and on and used > 0 and heads[id].visible or false)
  end
  for _, cell in ipairs(live) do cell:SetAlpha(cell.base * ((not glow or cell.slot == hot) and 1 or 0.5)) end
end

local function fill(cell, s)
  local tex, name, known, spellID, count = ns.SlotView(s)
  cell.name, cell.known, cell.spellID = name, known, spellID
  cell.badge:SetFontObject(ns.Font("mono", cell:GetWidth() < 18 and 8 or 10))
  cell.badge:SetText(count or ""); cell.badge:SetShown(count ~= nil)
  cell.tex:SetTexture(tex); cell.tex:SetShown(tex ~= nil); cell.tex:SetDesaturated(name ~= nil and not known)
  local edge = name and { T.brass[1], T.brass[2], T.brass[3], 0.55 } or T.line
  cell:SetBackdropBorderColor(unpack(edge))
  cell:SetBackdropColor(unpack(name and T.keyEdge or T.well))
  cell.base = not name and 0.35 or known and 1 or 0.4
  cell:Show(); live[#live + 1] = cell
end

local function at(region, parent, point, x, y)
  region:ClearAllPoints(); region:SetPoint(point, parent, point == "CENTER" and "TOPLEFT" or point, x, y)
end

-- Rows: key label column (width of the longest label), then the visible modifier columns.
local function layoutRows(list, applied, top, cols)
  local s = ns.S
  local icon = s.cheatIcon
  local colw, rowh, keyw = math.max(icon + 8, 34), icon + 6, 0
  if s.cheatLabels then
    for i, key in ipairs(list) do
      local r = row(i)
      r.key:SetText(L["KEY_" .. key] or key); keyw = math.max(keyw, r.key:GetStringWidth())
    end
    keyw = keyw + 10
  end
  local y0 = top + HEAD
  for c, id in ipairs(cols) do
    local cx = PAD + keyw + (c - 0.5) * colw
    at(heads[id], p, "CENTER", cx, -(top + HEAD / 2)); heads[id]:SetShown(#list > 0)
    stripes[id]:ClearAllPoints()
    stripes[id]:SetPoint("TOPLEFT", p, "TOPLEFT", cx - colw / 2 + 1, -top)
    stripes[id]:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", cx - colw / 2 + 1, 6)
    stripes[id]:SetWidth(colw - 2)
  end
  for i, key in ipairs(list) do
    local r, cy = row(i), -(y0 + (i - 0.5) * rowh)
    r.key:ClearAllPoints(); r.key:SetPoint("LEFT", p, "TOPLEFT", PAD + 2, cy); r.key:SetShown(s.cheatLabels)
    for c, id in ipairs(cols) do
      local cell = r.cells[id]
      cell:SetSize(icon, icon); at(cell, p, "CENTER", PAD + keyw + (c - 0.5) * colw, cy)
      fill(cell, applied[key].slots[id])
    end
  end
  return PAD * 2 + keyw + #cols * colw, y0 + #list * rowh + 6
end

-- Horizontal: one row per modifier (label on the left), one column per key (short key name on top).
local function layoutCols(list, applied, top, cols)
  local s = ns.S
  local icon, labw, keyw = s.cheatIcon, 0, 0
  for _, id in ipairs(cols) do labw = math.max(labw, heads[id]:GetStringWidth()) end
  labw = labw + 10
  if s.cheatLabels then
    for i, key in ipairs(list) do
      local r = row(i)
      r.key:SetText(ns.ShortKey(key)); keyw = math.max(keyw, r.key:GetStringWidth())
    end
  end
  local colw, rowh = math.max(icon + 8, keyw + 8), icon + 6
  local y0 = top + (s.cheatLabels and HEAD or 0)
  for c, id in ipairs(cols) do
    local cy = -(y0 + (c - 0.5) * rowh)
    heads[id]:ClearAllPoints(); heads[id]:SetPoint("LEFT", p, "TOPLEFT", PAD + 2, cy); heads[id]:SetShown(#list > 0)
    stripes[id]:ClearAllPoints()
    stripes[id]:SetPoint("TOPLEFT", p, "TOPLEFT", 6, cy + rowh / 2 - 1)
    stripes[id]:SetPoint("TOPRIGHT", p, "TOPRIGHT", -6, cy + rowh / 2 - 1)
    stripes[id]:SetHeight(rowh - 2)
  end
  for i, key in ipairs(list) do
    local r, cx = row(i), PAD + labw + (i - 0.5) * colw
    r.key:ClearAllPoints(); r.key:SetPoint("CENTER", p, "TOPLEFT", cx, -(top + HEAD / 2)); r.key:SetShown(s.cheatLabels)
    for c, id in ipairs(cols) do
      local cell = r.cells[id]
      cell:SetSize(icon, icon); at(cell, p, "CENTER", cx, -(y0 + (c - 0.5) * rowh))
      fill(cell, applied[key].slots[id])
    end
  end
  return PAD * 2 + labw + #list * colw, y0 + #cols * rowh + 6
end

-- Keyboard: keys where the canvas has them (ns.LAYOUT from UI.lua), trimmed to the used area.
-- Keys outside the canvas set (bound with /fkb set) go on a row below.
local where
local function layoutKeyboard(list, applied, top, shown)
  local s = ns.S
  if not where then
    where = {}
    for _, e in ipairs(ns.LAYOUT) do if not e.move then where[e[1]] = e end end
  end
  local icon = s.cheatIcon
  local sm = math.max(8, math.floor(icon * 0.5 + 0.5))
  local cw = math.max(icon, 4 * sm + 3) + 8
  local lab = s.cheatLabels and 12 or 0
  local ch = 4 + lab + icon + 3 + sm + 4
  local pos, minX, minY, maxY, extra = {}, math.huge, math.huge, -math.huge, 0
  for i, key in ipairs(list) do
    local e = where[key]
    if e then
      pos[i] = { e[2], e[3], e[4] or 1 }
      minX, minY, maxY = math.min(minX, e[2]), math.min(minY, e[3]), math.max(maxY, e[3])
    end
  end
  if minX == math.huge then minX, minY, maxY = 0, 0, -1 end
  for i in ipairs(list) do
    if not pos[i] then pos[i] = { minX + extra, maxY + 1, 1 }; extra = extra + 1 end
  end
  local a, w, h = s.cheatBg / 100, 0, 0
  for i, key in ipairs(list) do
    local k = cap(key)
    local x, y = PAD + (pos[i][1] - minX) * (cw + 4), top + (pos[i][2] - minY) * (ch + 4)
    local kw = cw + (pos[i][3] - 1) * (cw + 4)
    k.frame:ClearAllPoints(); k.frame:SetPoint("TOPLEFT", p, "TOPLEFT", x, -y); k.frame:SetSize(kw, ch); k.frame:Show()
    k.frame:SetBackdropColor(T.keyBot[1], T.keyBot[2], T.keyBot[3], a)
    k.frame:SetBackdropBorderColor(T.line[1], T.line[2], T.line[3], a)
    k.label:SetText(L["KEY_" .. key] or key); k.label:SetShown(s.cheatLabels)
    local big = k.cells.normal
    big:SetSize(icon, icon); big:ClearAllPoints(); big:SetPoint("TOP", k.frame, "TOP", 0, -(4 + lab))
    fill(big, applied[key].slots.normal)
    for j, id in ipairs(MODS) do
      local c = k.cells[id]
      c:SetSize(sm, sm); c:ClearAllPoints(); c:SetPoint("BOTTOM", k.frame, "BOTTOM", (j - 2.5) * (sm + 1), 4)
      if shown[id] then fill(c, applied[key].slots[id]) end
    end
    w, h = math.max(w, x + kw), math.max(h, y + ch)
  end
  return w + PAD, h + PAD
end

local function refresh()
  local s = ns.S
  local applied = FoilKeybindsDB.applied or {}
  ns.ResetLearned()
  local list, seen, extra = {}, {}, {}
  for _, k in ipairs(ns.KEY_ORDER) do
    if applied[k] then list[#list + 1] = k; seen[k] = true end
  end
  for k in pairs(applied) do if not seen[k] then extra[#extra + 1] = k end end -- keys set with /fkb set
  table.sort(extra)
  for _, k in ipairs(extra) do list[#list + 1] = k end
  used = #list

  -- Chrome: background opacity fades the body, wash and title bar; 0 leaves only icons and labels.
  local a, bare = s.cheatBg / 100, s.cheatBg == 0
  p:SetBackdropColor(T.bg[1], T.bg[2], T.bg[3], a)
  p:SetBackdropBorderColor(T.line[1], T.line[2], T.line[3], s.cheatBorder and 1 or 0)
  p.wash:SetAlpha(a); p.bar:SetAlpha(a); p.rule:SetAlpha(a)
  local top = bare and PAD or TOP

  local cols, shown = {}, {}
  for _, id in ipairs(COLS) do
    local any = not s.cheatHideEmpty or used == 0
    for _, k in ipairs(list) do if applied[k].slots[id] then any = true end end
    if any then cols[#cols + 1] = id end
    shown[id], heads[id].visible = any, any
  end

  for _, cell in ipairs(cells) do cell:Hide(); cell.name = nil end
  for _, r in ipairs(rows) do r.key:Hide() end
  for _, k in pairs(caps) do k.frame:Hide() end
  for _, id in ipairs(COLS) do heads[id]:Hide(); stripes[id]:Hide() end
  live = {}
  rowsMode = s.cheatLayout ~= "keyboard"
  local w, h
  if s.cheatLayout == "cols" then w, h = layoutCols(list, applied, top, cols)
  elseif rowsMode then w, h = layoutRows(list, applied, top, cols)
  else w, h = layoutKeyboard(list, applied, top, shown) end
  empty:SetShown(used == 0)
  if used == 0 then
    empty:ClearAllPoints(); empty:SetPoint("TOPLEFT", PAD + 2, -(top + 4))
    w, h = 242, top + empty:GetStringHeight() + 16
  end
  p:SetSize(bare and w or math.max(w, 220), h) -- room for the title, lock box and x
  applyLock(); paint()
end

function ns.RefreshCheat() if p:IsShown() then refresh() end end
function ns.CheatShown() return p:IsShown() end
function ns.ResetCheatPosition()
  p:ClearAllPoints(); p:SetPoint("CENTER", 300, 0)
  local c = db()
  c.point, c.rel, c.x, c.y, c.pscale = nil, nil, nil, nil, nil
end

-- show nil toggles. The saved flag is written only here, never from OnHide (Alt+Z and
-- cinematics hide UIParent and would clear it).
function ns.ToggleCheat(show)
  if show == nil then show = not p:IsShown() end
  db().shown = show
  p:SetShown(show)
  if ns.RefreshSettings then ns.RefreshSettings() end
end
p.close:SetScript("OnClick", function() ns.ToggleCheat(false) end)
lock:SetScript("OnClick", function(self) ns.SetSetting("cheatLock", self:GetChecked() and true or false) end)

local LIVE = { "MODIFIER_STATE_CHANGED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP", "SPELL_DATA_LOAD_RESULT" }
p:SetScript("OnShow", function(self)
  for _, e in ipairs(LIVE) do self:RegisterEvent(e) end
  refresh()
end)
p:SetScript("OnHide", function(self)
  for _, e in ipairs(LIVE) do self:UnregisterEvent(e) end
end)
p:RegisterEvent("PLAYER_LOGIN")
p:SetScript("OnEvent", function(self, event, id)
  if event == "MODIFIER_STATE_CHANGED" then return paint() end
  if event == "SPELL_DATA_LOAD_RESULT" then -- only the cells showing that spell
    for _, cell in ipairs(live) do if cell.spellID == id then cell.tex:SetTexture(ns.SpellIcon(id)) end end
    return
  end
  if event == "PLAYER_LOGIN" then
    local c, scale = db(), ns.S.cheatScale
    self:SetScale(scale) -- scale before the point: offsets are in the frame's scale
    if c.point then -- saved at another scale (another character, old save): keep the same spot
      local k = (c.pscale or c.scale or 1) / scale
      self:ClearAllPoints(); self:SetPoint(c.point, UIParent, c.rel, c.x * k, c.y * k)
    end
    applyLock()
    self:SetShown(c.shown or false)
    return
  end
  refresh() -- spells learned or level up: future spells stop fading
end)
