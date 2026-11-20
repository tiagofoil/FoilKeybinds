-- Wizard (v5): builds the first layout one group at a time. Step 1 is the Guide tab (spec and range,
-- "Build my layout"); then one step per group of the guide layout in meaning order (Core ns.WizardSteps),
-- in a wide panel over the lower half of the Keys tab (the rest goes dark, the board stays clickable).
-- The board shows the layout built so far through the Keys tab preview (UI.lua ns.StartPreview) with the
-- current group's key selected, and a canvas key click is the step's pick. After the last step the panel
-- lists every key with the macro Apply will write, and offers Use (the preview banner keeps Use, Cancel).
-- Only a Use that went through saves the picks (per spec), the wizard mark and the cheat sheet once-flag.
local _, ns = ...
local L, T = ns.L, ns.T
local card, pane = ns.keyCard, ns.keysPane

-- The running wizard (nil: none): t = guide template, class = class token, steps, i = step, map = picks,
-- saved = picks came from an earlier run, tested, title, used = the used-template record for Use.
local wz
function ns.WizardState() return wz end

-- Dark layer over everything under the board, and over the key card; it takes the clicks there.
local dim = CreateFrame("Frame", nil, pane)
dim:SetPoint("TOPLEFT", 1, -342); dim:SetPoint("BOTTOMRIGHT", -1, 1)
dim:SetFrameLevel(pane:GetFrameLevel() + 80); dim:EnableMouse(true); dim:Hide()
dim.tex = dim:CreateTexture(nil, "BACKGROUND"); dim.tex:SetAllPoints(); dim.tex:SetColorTexture(0, 0, 0, 0.6)
dim.card = dim:CreateTexture(nil, "BACKGROUND"); dim.card:SetAllPoints(card); dim.card:SetColorTexture(0, 0, 0, 0.6)

-- The panel: step page (one group) or done page (the macros), Back on both.
local W = 640
local bar = CreateFrame("Frame", nil, dim)
bar:SetSize(W, 376); bar:SetPoint("CENTER"); bar:EnableMouse(true)
ns.RoundSkin(bar, T.panel, T.brass)
bar.step = ns.Text(bar, "mono", 10, T.muted); bar.step:SetPoint("TOPLEFT", 18, -16)
bar.of = ns.Text(bar, "mono", 10, T.muted); bar.of:SetPoint("TOPRIGHT", -18, -16)
bar.track = bar:CreateTexture(nil, "ARTWORK"); bar.track:SetColorTexture(unpack(T.line))
bar.track:SetPoint("TOPLEFT", 18, -32); bar.track:SetPoint("TOPRIGHT", -18, -32); bar.track:SetHeight(4)
bar.fill = bar:CreateTexture(nil, "OVERLAY"); bar.fill:SetColorTexture(unpack(T.brass))
bar.fill:SetPoint("TOPLEFT", bar.track); bar.fill:SetHeight(4)
bar.back = ns.Button(bar, 90, 26, L.WIZARD_BACK); bar.back:SetPoint("BOTTOMLEFT", 18, 16)

local page = CreateFrame("Frame", nil, bar); page:SetAllPoints()
page.name = ns.Text(page, "display", 24, T.brass); page.name:SetPoint("TOPLEFT", 18, -48)
page.why = ns.Text(page, "body", 14, T.ink)
page.why:SetPoint("TOPLEFT", 18, -84); page.why:SetPoint("RIGHT", -18, 0); page.why:SetJustifyH("LEFT"); page.why:SetJustifyV("TOP")
page.icons = {}
for i in ipairs(ns.COLUMNS) do -- one per slot of the group with its modifier under it, game tooltip on hover
  local b = ns.IconFrame(page, 44)
  b:SetPoint("TOPLEFT", 18 + (i - 1) * 64, -130); b:EnableMouse(true)
  b.mod = ns.Text(b, "mono", 9, T.muted); b.mod:SetPoint("TOP", b, "BOTTOM", 0, -4)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.spellID then GameTooltip:SetSpellByID(self.spellID) else GameTooltip:SetText(self.label or "") end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  page.icons[i] = b
end
page.key = ns.Text(page, "bold", 18, T.ink); page.key:SetPoint("TOPLEFT", 18, -208)
page.click = ns.Text(page, "body", 13, T.muted); page.click:SetPoint("LEFT", page.key, "RIGHT", 10, 0)
page.click:SetText(L.WIZARD_CLICK)
page.side = ns.Text(page, "body", 13, T.muted) -- Mouse 4 or 5 suggested: the key to click without side buttons
page.side:SetPoint("TOPLEFT", 18, -236)
page.msg = ns.Text(page, "body", 13, T.blood) -- why a clicked key is blocked
page.msg:SetPoint("TOPLEFT", 18, -260); page.msg:SetPoint("RIGHT", -18, 0); page.msg:SetJustifyH("LEFT")
page.note = ns.Text(page, "body", 11, T.muted) -- class not tested in game yet
page.note:SetPoint("BOTTOMLEFT", 18, 54); page.note:SetPoint("RIGHT", -18, 0); page.note:SetJustifyH("LEFT")
page.note:SetText(L.WIZARD_UNTESTED)
page.skip = ns.Button(page, 90, 26, L.WIZARD_SKIP); page.skip:SetPoint("LEFT", bar.back, "RIGHT", 8, 0)
page.next = ns.Button(page, 120, 26, L.WIZARD_NEXT, T.fel); page.next:SetPoint("BOTTOMRIGHT", -18, 16)
page.all = ns.Button(page, 200, 26, L.WIZARD_ALL); page.all:SetPoint("RIGHT", page.next, "LEFT", -8, 0)

local done = CreateFrame("Frame", nil, bar); done:SetAllPoints(); done:Hide()
done.name = ns.Text(done, "display", 22, T.brass); done.name:SetPoint("TOPLEFT", 18, -48); done.name:SetText(L.WIZARD_DONE)
done.sub = ns.Text(done, "body", 12, T.muted)
done.sub:SetPoint("TOPLEFT", 18, -78); done.sub:SetPoint("RIGHT", -18, 0); done.sub:SetJustifyH("LEFT")
done.sub:SetText(L.WIZARD_DONE_SUB)
done.scroll = CreateFrame("ScrollFrame", nil, done, "UIPanelScrollFrameTemplate")
done.scroll:SetPoint("TOPLEFT", 18, -112); done.scroll:SetPoint("BOTTOMRIGHT", -36, 54)
local LIST_W = W - 18 - 36
done.body = CreateFrame("Frame", nil, done.scroll); done.body:SetSize(LIST_W, 10); done.scroll:SetScrollChild(done.body)
done.out = ns.Text(done.body, "body", 12, T.muted); done.out:SetWidth(LIST_W); done.out:SetJustifyH("LEFT")
done.use = ns.Button(done, 160, 26, L.PREVIEW_USE, T.fel); done.use:SetPoint("BOTTOMRIGHT", -18, 16)
done.use:SetWidth(math.max(160, done.use:GetFontString():GetStringWidth() + 24))
done.use:SetScript("OnClick", function() ns.UsePreview() end)

-- A done-page row: key, group name, the macro text one clause per line (like Show macro).
local rows = {}
local function row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Frame", nil, done.body)
  r.key = ns.Chip(r, "mono", 13, T.brass); r.key:SetPoint("TOPLEFT", 0, 0)
  r.name = ns.Text(r, "bold", 15, T.ink); r.name:SetPoint("LEFT", r.key, "RIGHT", 10, 0)
  r.macro = ns.Text(r, "mono", 13, T.code); r.macro:SetPoint("TOPLEFT", 0, -30); r.macro:SetWidth(LIST_W)
  r.macro:SetJustifyH("LEFT"); r.macro:SetSpacing(2); r.macro:SetWordWrap(true); r.macro:SetNonSpaceWrap(true)
  rows[i] = r
  return r
end

local function keyName(k) return L["KEY_" .. k] or k end
local function nameOf(gk) local m = ns.MeaningOf(gk, wz.class); return m and L["MEANING_" .. m] or keyName(gk) end

-- Preview end (Use, Cancel, leaving the Keys tab, closing the window): the wizard is gone, nothing saved here.
local function stop() wz = nil; dim:Hide() end

-- The preview's Use: same as the Guide's Use, on the built template. false = spell names still loading
-- (the preview stays, nothing saved).
local function use()
  local w = wz
  if ns.UseTemplate(ns.BuildTemplate(w.t, w.map), w.used) == false then return false end
  local db = FoilKeybindsDB
  db.guide.wizard = true -- the level-up line names /fkb wizard
  db.wizard = db.wizard or {}
  db.wizard.picks = ns.WizardPicks(db.wizard) or {}
  db.wizard.picks[w.used.groupID] = ns.MergePicks(db.wizard.picks[w.used.groupID], w.map)
  db.wizard.cheatOnce = true
  ns.guide.hint = nil -- the "Step 1" or new-player line is done
end

local show, click
-- The done page: every kept group with its key and macro, then the left-out groups.
local function fillDone(keys)
  local y, n, out = 0, 0, {}
  ns.ResetLearned()
  for _, st in ipairs(wz.steps) do
    local k = wz.map[st.key]
    if k then
      n = n + 1
      local r = row(n)
      local text = ns.FitMacro(ns.MacroSetup(keys[k]), ns.best)
      r.key:Set(keyName(k), 12)
      r.name:SetText(L["MEANING_" .. st.meaning] .. (st.of > 1 and "  " .. L.WIZARD_OF:format(st.n, st.of) or ""))
      r.macro:SetText(text and ns.ColorMacro((text:gsub(";%s*", ";\n    "))) or L.WIZARD_TOO_LONG)
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetWidth(LIST_W)
      local h = 32 + r.macro:GetStringHeight()
      r:SetHeight(h); r:Show()
      y = y + h + 14
    else
      out[#out + 1] = nameOf(st.key)
    end
  end
  for i = n + 1, #rows do rows[i]:Hide() end
  done.out:ClearAllPoints(); done.out:SetPoint("TOPLEFT", 0, -y)
  done.out:SetText(#out > 0 and L.WIZARD_LEFT_OUT:format(table.concat(out, ", ")) or "")
  done.body:SetHeight(y + done.out:GetStringHeight() + 4); done.scroll:SetVerticalScroll(0)
end

-- Redraws the board (built layout, current group selected) and the panel: a step, or past the last
-- step the done page.
show = function()
  local st = wz.steps[wz.i]
  local k = st and wz.map[st.key]
  local keys = ns.TemplateKeys(ns.BuildTemplate(wz.t, wz.map), ns.SpellLookup)
  ns.StartPreview(keys, wz.title, use,
    { click = click, stop = stop, sel = st and (k or false) }) -- nil past the last step, false when left out
  dim:Show(); page:SetShown(st ~= nil); done:SetShown(st == nil)
  local total = #wz.steps + 1 -- step 1 is the Guide tab
  bar.fill:SetWidth(math.max(1, (W - 36) * math.min(wz.i, total) / total))
  page.msg:SetText("")
  if not st then
    bar.step:SetText(L.WIZARD_DONE_STEP); bar.of:SetText("")
    return fillDone(keys)
  end
  bar.step:SetText(L.WIZARD_STEP:format(wz.i + 1, total))
  bar.of:SetText(st.of > 1 and L.WIZARD_OF:format(st.n, st.of) or "")
  page.name:SetText(L["MEANING_" .. st.meaning]); page.why:SetText(L["WHY_" .. st.meaning])
  local n, slots = 0, wz.t[st.key]
  for _, id in ipairs(ns.COLUMNS) do
    local s = slots[id]
    if s then
      n = n + 1
      local b = page.icons[n]
      b.spellID, b.label = s.spellID, s.item and ns.ItemLabel(s.item)
      b.tex:SetTexture(s.item and ns.ItemIcon(s.item) or ns.SpellIcon(s.spellID))
      b.mod:SetText(L["SLOT_" .. id])
      b:Show()
    end
  end
  for i = n + 1, #page.icons do page.icons[i]:Hide() end
  page.key:SetText(k and L.WIZARD_KEY:format(keyName(k)) or L.WIZARD_KEY_OUT)
  local side = ({ BUTTON4 = "1", BUTTON5 = "2" })[k] -- the key this step suggests now (a saved pick may differ)
  page.side:SetText(side and L.WIZARD_NO_SIDE:format(side) or "")
  page.all:SetText(wz.saved and L.WIZARD_ALL_MINE or L.WIZARD_ALL)
  page.all:SetWidth(math.max(200, page.all:GetFontString():GetStringWidth() + 24))
  page.note:SetShown(not wz.tested)
end

-- A canvas key click: the whole group goes there (a taken key: the two trade, one chat line).
click = function(key)
  local st = wz and wz.steps[wz.i]
  if not st then return end
  local moved, why = ns.Pick(wz.map, wz.t, st.key, key)
  if not moved then return page.msg:SetText(L["WIZARD_BLOCKED_" .. why]) end
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
  wz.i = math.min(wz.i, #wz.steps + 1) - 1; show()
end)
page.skip:SetScript("OnClick", function() ns.Skip(wz.map, wz.steps[wz.i].key); wz.i = wz.i + 1; show() end)
page.next:SetScript("OnClick", function() wz.i = wz.i + 1; show() end)
page.all:SetScript("OnClick", function() wz.i = #wz.steps + 1; show() end)

-- "Build my layout" on the Guide tab. class = FoilKeybindsGuides[CLASS]; meanings come from the home keys
-- (Core ns.MeaningOf). The saved picks of that spec preselect every step.
function ns.StartWizard(class, groupID, bracket, name)
  local t = ns.TemplateFor(class, groupID, bracket)
  if not t then return end
  local picks = ns.WizardPicks(FoilKeybindsDB.wizard)
  local saved = picks and picks[groupID]
  wz = { t = t, class = ns.playerClass, steps = ns.WizardSteps(t, ns.playerClass), map = ns.WizardMap(t, saved), i = 1,
    saved = saved ~= nil, tested = class.tested, title = L.WIZARD_TITLE:format(name, ns.BracketRange(bracket)),
    used = { groupID = groupID, bracket = bracket, name = name } }
  show()
end
