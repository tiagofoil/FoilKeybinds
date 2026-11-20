-- Guide tab: the player's class, its specs (the one with most talent points picked and marked "yours"),
-- the spec's priority list with the key each spell is on, the 3 level brackets, and "Preview layout"
-- (shows the template on the Keys tab, UI.lua ns.StartPreview). The guide data (FoilKeybinds_Guides,
-- load on demand) loads on the first open. Redraws on clicks and events only.
local _, ns = ...
local L, T = ns.L, ns.T
local pane = ns.guidePane
local PT = GetLocale() == "ptBR"
local URL = "https://github.com/tiagofoil/FoilKeybinds/issues"

-- Spec and bracket picked; kept while the window stays open (the smoke test reads it too).
local state = {}
ns.guide = state
pane:GetParent():HookScript("OnHide", function() wipe(state) end)

-- True once the guide data is in. A missing or disabled package just stays false (tried again next open).
local function load()
  if not FoilKeybindsGuides then
    local fn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    if fn then pcall(fn, "FoilKeybinds_Guides") end
  end
  return FoilKeybindsGuides ~= nil
end

pane.msg = ns.Text(pane, "body", 15, T.muted)
pane.msg:SetPoint("CENTER", 0, 40); pane.msg:SetWidth(520)

-- Left column: class, specs, brackets.
local left = CreateFrame("Frame", nil, pane)
left:SetPoint("TOPLEFT", 12, -10); left:SetPoint("BOTTOMLEFT", 12, 54); left:SetWidth(236)
ns.RoundSkin(left, T.panel, T.line)
left.class = ns.Text(left, "display", 20, T.brass); left.class:SetPoint("TOPLEFT", 14, -14)
local function eyebrow(text, y)
  local t = ns.Text(left, "mono", 10, T.brass); t:SetPoint("TOPLEFT", 14, y); t:SetText(text)
end
eyebrow(L.GUIDE_SPEC, -52)
eyebrow(L.GUIDE_LEVELS, -196)

local draw
-- A pick button: brass text and a brass bar when selected (on the left for specs, under it for brackets).
local function pick(w, h, bar)
  local b = ns.Button(left, w, h)
  b.mark = b:CreateTexture(nil, "OVERLAY"); b.mark:SetColorTexture(unpack(T.brass)); b.mark:Hide()
  if bar == "left" then b.mark:SetPoint("TOPLEFT", 1, -1); b.mark:SetPoint("BOTTOMLEFT", 1, 1); b.mark:SetWidth(3)
  else b.mark:SetPoint("BOTTOMLEFT", 1, 1); b.mark:SetPoint("BOTTOMRIGHT", -1, 1); b.mark:SetHeight(2) end
  function b:Pick(on) self.mark:SetShown(on); self:GetFontString():SetTextColor(unpack(on and T.brass or T.ink)) end
  return b
end
local specBtns, bracketBtns = {}, {}
for i = 1, 3 do
  local b = pick(208, 32, "left")
  b:SetPoint("TOPLEFT", 14, -68 - (i - 1) * 38)
  b:GetFontString():ClearAllPoints(); b:GetFontString():SetPoint("LEFT", 14, 0)
  b.yours = ns.Chip(b, "mono", 9, T.fel); b.yours:SetPoint("RIGHT", -8, 0)
  b:SetScript("OnClick", function(self) state.spec = self.id; draw() end)
  specBtns[i] = b
end
for i in ipairs(ns.BRACKETS) do
  local b = pick(64, 28, "bottom")
  b:SetPoint("TOPLEFT", 14 + (i - 1) * 72, -212)
  b:SetText(ns.BracketRange(i))
  b:SetScript("OnClick", function() state.bracket = i; draw() end)
  bracketBtns[i] = b
end

-- Right side: the priority list, then the untested-class note.
local list = CreateFrame("Frame", nil, pane)
list:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0); list:SetPoint("BOTTOMRIGHT", -12, 54)
ns.RoundSkin(list, T.panel, T.line)
list.title = ns.Text(list, "display", 17, T.ink); list.title:SetPoint("TOPLEFT", 16, -14)
list.sub = ns.Text(list, "mono", 10, T.muted); list.sub:SetPoint("LEFT", list.title, "RIGHT", 12, -1)
list.sub:SetText(L.GUIDE_PRIORITY)

-- ponytail: no scroll; 12 rows fit, a longer priority list runs into the note. Add a scroll frame if a class needs it.
local ROW = 46
local rows = {}
local function row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Frame", nil, list)
  r:SetHeight(ROW - 2); r:SetPoint("TOPLEFT", 16, -46 - (i - 1) * ROW); r:SetPoint("RIGHT", -16, 0)
  r.num = ns.Text(r, "mono", 10, T.muted); r.num:SetPoint("TOPLEFT", 0, -10); r.num:SetText(i .. ".")
  r.icon = ns.IconFrame(r, 32); r.icon:SetPoint("TOPLEFT", 22, -2); r.icon:EnableMouse(true)
  r.icon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetSpellByID(r.spellID); GameTooltip:Show()
  end)
  r.icon:SetScript("OnLeave", GameTooltip_Hide)
  r.key = ns.Chip(r, "mono", 10); r.key:SetPoint("TOPRIGHT", 0, -6)
  r.name = ns.Text(r, "bold", 14); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, 1)
  r.lv = ns.Chip(r, "mono", 9, T.fel); r.lv:SetPoint("LEFT", r.name, "RIGHT", 8, 0)
  r.what = ns.Text(r, "body", 12, T.muted)
  r.what:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3); r.what:SetPoint("RIGHT", -140, 0)
  r.what:SetJustifyH("LEFT"); r.what:SetJustifyV("TOP"); r.what:SetMaxLines(2)
  rows[i] = r
  return r
end

list.note = ns.Text(list, "body", 12, T.muted)
list.note:SetPoint("BOTTOMLEFT", 16, 36); list.note:SetPoint("RIGHT", -16, 0); list.note:SetJustifyH("LEFT")
list.note:SetText(L.GUIDE_UNTESTED)
-- The link as a read-only box: chat and frames cannot open a browser, so the player copies it.
list.url = CreateFrame("EditBox", nil, list, "BackdropTemplate")
list.url:SetSize(360, 20); list.url:SetPoint("BOTTOMLEFT", 16, 10)
ns.Skin(list.url, T.well, T.line); list.url:SetFontObject(ns.Font("mono", 11)); list.url:SetTextInsets(6, 6, 0, 0)
list.url:SetAutoFocus(false); list.url:SetText(URL)
list.url:SetScript("OnTextChanged", function(self) if self:GetText() ~= URL then self:SetText(URL) end end)
list.url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
list.url:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
list.url:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

-- Bottom bar: Preview layout, where Apply sits on the Keys tab. The hint line: the new-player or step 1
-- line (state.hint, set by /fkb), else what the buttons do.
local previewBtn = ns.Button(pane, 160, 26, L.GUIDE_PREVIEW)
previewBtn:SetPoint("BOTTOMRIGHT", -16, 14)
local hint = ns.Text(pane, "body", 12, T.muted)
hint:SetPoint("RIGHT", previewBtn, "LEFT", -12, 0); hint:SetWidth(640); hint:SetJustifyH("RIGHT") -- a long pt-BR line wraps

-- Build my layout (the wizard, Wizard.lua): the big tile under the level ranges, icon, name and one line.
local buildBtn = CreateFrame("Button", nil, left)
buildBtn:SetPoint("TOPLEFT", 14, -262); buildBtn:SetSize(208, 124)
ns.RoundSkin(buildBtn, T.well, T.fel) -- dark face: the white line reads on it
buildBtn.icon = ns.IconFrame(buildBtn, 40); buildBtn.icon:SetPoint("TOPLEFT", 12, -12)
buildBtn.icon.tex:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
local buildText = ns.Text(buildBtn, "display", 16, T.fel)
buildBtn:SetFontString(buildText); buildBtn:SetText(L.WIZARD_BUILD)
buildText:ClearAllPoints(); buildText:SetPoint("LEFT", buildBtn.icon, "RIGHT", 10, 0); buildText:SetPoint("RIGHT", -10, 0)
buildText:SetJustifyH("LEFT")
buildBtn.sub = ns.Text(buildBtn, "body", 13, T.ink)
buildBtn.sub:SetPoint("TOPLEFT", 12, -60); buildBtn.sub:SetPoint("RIGHT", -12, 0); buildBtn.sub:SetJustifyH("LEFT")
buildBtn.sub:SetText(L.WIZARD_BUILD_SUB)
buildBtn:SetScript("OnEnter", function(self) self.rLine:SetVertexColor(unpack(T.brass)); buildText:SetTextColor(unpack(T.brass)) end)
buildBtn:SetScript("OnLeave", function(self) self.rLine:SetVertexColor(unpack(T.fel)); buildText:SetTextColor(unpack(T.fel)) end)

local function specOf(gid)
  for _, s in ipairs(state.specs) do if s.groupID == gid then return s end end
end

draw = function()
  local ok = load()
  local class = ok and FoilKeybindsGuides[ns.playerClass]
  local msg = (not ok and L.GUIDE_MISSING) or (not class and L.GUIDE_NO_CLASS) or nil
  pane.msg:SetText(msg or ""); pane.msg:SetShown(msg ~= nil)
  for _, w in ipairs({ left, list, previewBtn, buildBtn, hint }) do w:SetShown(msg == nil) end
  if msg then return end
  if not state.specs then -- first draw since the window opened or the spells/talents changed: read the points
    state.specs = ns.ReadSpecs(class)
    state.mine, state.hasPoints = ns.GuessSpec(state.specs, class.suggested)
    if not specOf(state.mine) then state.mine = state.specs[1].groupID end
  end
  if not state.spec then -- the picks stay until the window closes
    state.spec = state.mine
    state.bracket = ns.BracketOf(UnitLevel("player") or 1)
  end
  left.class:SetText((UnitClass("player")))
  for i, b in ipairs(specBtns) do
    local s = state.specs[i]
    b:SetShown(s ~= nil)
    if s then
      b.id = s.groupID; b:SetText(s.name); b:Pick(s.groupID == state.spec)
      b.yours:SetShown(s.groupID == state.mine)
      b.yours:Set(state.hasPoints and L.GUIDE_YOURS or L.GUIDE_SUGGESTED, 8)
    end
  end
  for i, b in ipairs(bracketBtns) do b:Pick(i == state.bracket) end
  list.title:SetText(specOf(state.spec).name)
  ns.ResetLearned()
  local keys = FoilKeybindsDB.keys -- read only: KeyOf and IsKnownSlot never write
  local prio = class.specs[state.spec].priority
  for i, p in ipairs(prio) do
    local r = row(i)
    local name = ns.SpellLookup(p.spellID)
    r.spellID = p.spellID
    r.icon.tex:SetTexture(ns.SpellIcon(p.spellID))
    r.name:SetText(name or "...") -- spell data not loaded yet: GuideSpellLoaded redraws
    r.what:SetText(PT and p.ptBR or p.en)
    local key, slot = ns.KeyOf(keys, p.spellID, name)
    r.key:Set(key and ns.KeyLabel(key, slot, L) or L.GUIDE_NO_KEY, 12)
    r.key.text:SetTextColor(unpack(key and T.ink or T.muted))
    local known = ns.IsKnownSlot({ spellID = p.spellID, name = name })
    r.icon.tex:SetDesaturated(not known)
    r.lv:SetShown(not known); if not known then r.lv:Set(L.LEVEL:format(p.level), 8) end
    r:Show()
  end
  for i = #prio + 1, #rows do rows[i]:Hide() end
  list.note:SetShown(not class.tested); list.url:SetShown(not class.tested)
  hint:SetText(state.hint or L.GUIDE_PREVIEW_HINT)
  hint:SetTextColor(unpack(state.hint and T.brass or T.muted))
end

previewBtn:SetScript("OnClick", function()
  local class = FoilKeybindsGuides[ns.playerClass]
  local t = ns.TemplateFor(class, state.spec, state.bracket)
  if not t then return end
  local used = { groupID = state.spec, bracket = state.bracket, name = specOf(state.spec).name }
  ns.StartPreview(ns.TemplateKeys(t, ns.SpellLookup), L.PREVIEW_TITLE:format(used.name, ns.BracketRange(used.bracket)),
    function() return ns.UseTemplate(t, used) end)
end)

buildBtn:SetScript("OnClick", function()
  ns.StartWizard(FoilKeybindsGuides[ns.playerClass], state.spec, state.bracket, specOf(state.spec).name)
end)

ns.ShowGuide = draw
-- SPELLS_CHANGED, TRAIT_CONFIG_UPDATED: a respec moves the "yours" mark, so the points are read again.
function ns.RefreshGuide() state.specs = nil; if pane:IsShown() then draw() end end
function ns.GuideSpellLoaded(id)
  if not pane:IsShown() then return end
  for _, r in ipairs(rows) do if r:IsShown() and r.spellID == id then return draw() end end
end
