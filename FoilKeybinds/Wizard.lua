-- Wizard (v5): builds the first layout one group at a time. Step 1 is the Guide tab (spec and range,
-- "Build my layout"); then one step per group of the guide layout in meaning order (Core ns.WizardSteps),
-- in a step bar over the key card. The board shows the layout built so far through the Keys tab preview
-- (UI.lua ns.StartPreview) with the current group's key selected, and a canvas key click is the step's
-- pick. After the last step the bar hides and the preview banner stays (Use, Cancel). Only a Use that
-- went through saves the picks (per spec), the wizard mark and the cheat sheet once-flag. Clicks only.
local _, ns = ...
local L, T = ns.L, ns.T
local card = ns.keyCard

-- The running wizard (nil: none): t = guide template, meanings, steps, i = step, map = picks,
-- saved = picks came from an earlier run, tested, title, used = the used-template record for Use.
local wz
function ns.WizardState() return wz end

-- Step bar: covers the key card (and its read-only shield) while a step is open.
local bar = CreateFrame("Frame", nil, card)
bar:SetAllPoints(); bar:SetFrameLevel(card:GetFrameLevel() + 40); bar:EnableMouse(true); bar:Hide()
ns.RoundSkin(bar, T.panel, { T.brass[1], T.brass[2], T.brass[3], 0.6 })
bar.step = ns.Text(bar, "mono", 10, T.muted); bar.step:SetPoint("TOPLEFT", 14, -14)
bar.of = ns.Text(bar, "mono", 10, T.muted); bar.of:SetPoint("TOPRIGHT", -14, -14)
bar.name = ns.Text(bar, "display", 18, T.brass); bar.name:SetPoint("TOPLEFT", 14, -30)
bar.why = ns.Text(bar, "body", 13, T.ink)
bar.why:SetPoint("TOPLEFT", 14, -56); bar.why:SetPoint("RIGHT", -14, 0); bar.why:SetJustifyH("LEFT"); bar.why:SetJustifyV("TOP")
bar.icons = {}
for i in ipairs(ns.COLUMNS) do -- one per slot of the group, game tooltip on hover
  local b = ns.IconFrame(bar, 30)
  b:SetPoint("TOPLEFT", 14 + (i - 1) * 36, -98); b:EnableMouse(true)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.spellID then GameTooltip:SetSpellByID(self.spellID) else GameTooltip:SetText(self.label or "") end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  bar.icons[i] = b
end
bar.key = ns.Text(bar, "bold", 14, T.ink); bar.key:SetPoint("TOPLEFT", 14, -140)
bar.click = ns.Text(bar, "body", 12, T.muted); bar.click:SetPoint("LEFT", bar.key, "RIGHT", 8, 0)
bar.click:SetText(L.WIZARD_CLICK)
bar.msg = ns.Text(bar, "body", 12, T.blood) -- why a clicked key is blocked
bar.msg:SetPoint("TOPLEFT", 14, -162); bar.msg:SetPoint("RIGHT", -14, 0); bar.msg:SetJustifyH("LEFT")
bar.note = ns.Text(bar, "body", 11, T.muted) -- class not tested in game yet
bar.note:SetPoint("TOPLEFT", 14, -196); bar.note:SetPoint("RIGHT", -14, 0); bar.note:SetJustifyH("LEFT")
bar.note:SetText(L.WIZARD_UNTESTED)
bar.all = ns.Button(bar, 120, 24, L.WIZARD_ALL)
bar.all:SetPoint("BOTTOMLEFT", 14, 44); bar.all:SetPoint("BOTTOMRIGHT", -14, 44)
bar.back = ns.Button(bar, 80, 24, L.WIZARD_BACK); bar.back:SetPoint("BOTTOMLEFT", 14, 12)
bar.skip = ns.Button(bar, 80, 24, L.WIZARD_SKIP); bar.skip:SetPoint("LEFT", bar.back, "RIGHT", 8, 0)
bar.next = ns.Button(bar, 100, 24, L.WIZARD_NEXT, T.fel); bar.next:SetPoint("BOTTOMRIGHT", -14, 12)

local function keyName(k) return L["KEY_" .. k] or k end
local function nameOf(gk) local m = wz.meanings[gk]; return m and L["MEANING_" .. m] or keyName(gk) end

-- Preview end (Use, Cancel, leaving the Keys tab, closing the window): the wizard is gone, nothing saved here.
local function stop() wz = nil; bar:Hide() end

-- The preview's Use: same as the Guide's Use, on the built template. false = spell names still loading
-- (the preview stays, nothing saved).
local function use()
  local w = wz
  if ns.UseTemplate(ns.BuildTemplate(w.t, w.map), w.used) == false then return false end
  local db = FoilKeybindsDB
  db.guide.wizard = true -- the level-up line names /fkb wizard
  db.wizard = db.wizard or {}
  db.wizard.picks = db.wizard.picks or {}
  db.wizard.picks[w.used.groupID] = ns.MergePicks(db.wizard.picks[w.used.groupID], w.map)
  db.wizard.cheatOnce = true
end

local show, click
-- Redraws the board (built layout, current group selected) and the bar; past the last step the bar hides.
show = function()
  local st = wz.steps[wz.i]
  local k = st and wz.map[st.key]
  ns.StartPreview(ns.TemplateKeys(ns.BuildTemplate(wz.t, wz.map), ns.SpellLookup), wz.title, use,
    { click = click, stop = stop, sel = st and (k or false) or nil })
  bar:SetShown(st ~= nil)
  bar.msg:SetText("")
  if not st then return end
  bar.step:SetText(L.WIZARD_STEP:format(wz.i + 1, #wz.steps + 1)) -- step 1 is the Guide tab
  bar.of:SetText(st.of > 1 and L.WIZARD_OF:format(st.n, st.of) or "")
  bar.name:SetText(L["MEANING_" .. st.meaning]); bar.why:SetText(L["WHY_" .. st.meaning])
  local n, slots = 0, wz.t[st.key]
  for _, id in ipairs(ns.COLUMNS) do
    local s = slots[id]
    if s then
      n = n + 1
      local b = bar.icons[n]
      b.spellID, b.label = s.spellID, s.item and ns.ItemLabel(s.item)
      b.tex:SetTexture(s.item and ns.ItemIcon(s.item) or ns.SpellIcon(s.spellID))
      b:Show()
    end
  end
  for i = n + 1, #bar.icons do bar.icons[i]:Hide() end
  bar.key:SetText(k and L.WIZARD_KEY:format(keyName(k)) or L.WIZARD_KEY_OUT)
  bar.all:SetText(wz.saved and L.WIZARD_ALL_MINE or L.WIZARD_ALL)
  bar.note:SetShown(not wz.tested)
end

-- A canvas key click: the whole group goes there (a taken key: the two trade, one chat line).
click = function(key)
  local st = wz and wz.steps[wz.i]
  if not st then return end
  local moved, why = ns.Pick(wz.map, wz.t, st.key, key)
  if not moved then return bar.msg:SetText(L["WIZARD_BLOCKED_" .. why]) end
  if moved[2] then
    local l = {}
    for i, m in ipairs(moved) do
      l[i] = m[2] and L.WIZARD_MOVED:format(nameOf(m[1]), keyName(m[2])) or L.WIZARD_OUT:format(nameOf(m[1]))
    end
    ns.Say(table.concat(l, ", ") .. ".")
  end
  show()
end

bar.back:SetScript("OnClick", function()
  if wz.i == 1 then return ns.OpenWindow("guide") end -- back to step 1 (cancels the preview)
  wz.i = wz.i - 1; show()
end)
bar.skip:SetScript("OnClick", function() ns.Skip(wz.map, wz.steps[wz.i].key); wz.i = wz.i + 1; show() end)
bar.next:SetScript("OnClick", function() wz.i = wz.i + 1; show() end)
bar.all:SetScript("OnClick", function() wz.i = #wz.steps + 1; show() end)

-- "Build my layout" on the Guide tab. class = FoilKeybindsGuides[CLASS]; the spec needs a meanings map.
-- The saved picks of that spec preselect every step.
function ns.StartWizard(class, groupID, bracket, name)
  local t, spec = ns.TemplateFor(class, groupID, bracket), class.specs[groupID]
  if not (t and spec.meanings) then return end
  local picks = FoilKeybindsDB.wizard and FoilKeybindsDB.wizard.picks
  local saved = picks and picks[groupID]
  wz = { t = t, meanings = spec.meanings, steps = ns.WizardSteps(t, spec.meanings), map = ns.WizardMap(t, saved), i = 1,
    saved = saved ~= nil, tested = class.tested, title = L.WIZARD_TITLE:format(name, ns.BracketRange(bracket)),
    used = { groupID = groupID, bracket = bracket, name = name } }
  show()
end
