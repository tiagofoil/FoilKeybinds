-- Thin game layer: turns core output into macros on the bar slot each key presses.
local _, ns = ...
local L = ns.L
local QUESTION = 134400 -- question mark icon; #showtooltip swaps it for the real spell

function ns.Say(msg) print("|cff93d35aFoil Keybinds:|r " .. msg) end

local MODS = { "SHIFT-", "ALT-", "ALT-SHIFT-", "CTRL-" }

-- Backup grows per thing touched, first value wins, so Undo returns to the state before the first Apply.
local function keepBind(b, key) if b.binds[key] == nil then b.binds[key] = GetBindingAction(key) or "" end end
local function keepSlot(b, slot)
  if b.slots[slot] ~= nil then return end
  local kind, id = GetActionInfo(slot)
  if kind == "macro" then id = GetActionText(slot) or id end -- by name: creating macros shifts indexes
  b.slots[slot] = kind and { kind = kind, id = id } or false
end

local function upsertMacro(b, name, body)
  local i = GetMacroIndexByName(name)
  if b.macros[name] == nil then b.macros[name] = i > 0 and GetMacroBody(i) or false end
  if i > 0 then EditMacro(i, name, nil, body); return true end
  local ok, err = pcall(CreateMacro, name, QUESTION, body, true)
  if not ok then ns.Say(L.CREATE_FAILED:format(name, tostring(err))) end
  return ok
end

local function place(b, name, slot)
  keepSlot(b, slot)
  ClearCursor(); PickupMacro(name); PlaceAction(slot); ClearCursor()
end

-- Best item per category in the bags, refreshed by ScanBags (Apply, login, out-of-combat bag changes).
ns.best = {}
local itemName = C_Item and C_Item.GetItemNameByID or function(id) return (GetItemInfo(id)) end
local usable = C_Item and C_Item.IsUsableItem or IsUsableItem
function ns.ScanBags()
  local owned = {}
  for bag = 0, 5 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local id = C_Container.GetContainerItemID(bag, slot)
      local n = id and itemName(id)
      if n then owned[n] = id end
    end
  end
  ns.best = ns.BestItems(owned, usable and function(id) return (usable(id)) end)
end

function ns.ItemIcon(cat)
  local b = ns.best[cat]
  local icon = b and (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(b.id) or GetItemIcon and GetItemIcon(b.id))
  return icon or QUESTION
end

function ns.ItemLabel(cat)
  local b = ns.best[cat]
  return L["ITEM_" .. cat] .. ": " .. (b and b.name or L.ITEM_NONE)
end

-- Account index: class -> { "Name-Realm" = copy of keys }, for "copy from".
function ns.Me() return UnitName("player") .. "-" .. GetRealmName(), select(2, UnitClass("player")) end
function ns.SaveIndex()
  if not FoilKeybindsDB then return end
  local me, class = ns.Me()
  FoilKeybindsAccount[class] = FoilKeybindsAccount[class] or {}
  FoilKeybindsAccount[class][me] = ns.Copy(FoilKeybindsDB.keys)
end

-- Replaces this character's keys with another's. Not applied; Undo brings the old keys back.
function ns.CopyFrom(name)
  local me, class = ns.Me()
  local src = FoilKeybindsAccount[class] and FoilKeybindsAccount[class][name]
  if not src or name == me then return end
  FoilKeybindsDB.copyUndo = ns.Copy(FoilKeybindsDB.keys)
  FoilKeybindsDB.keys = ns.Copy(src)
  if ns.Refresh then ns.Refresh() end
  ns.Say(L.COPIED:format(name))
end

function ns.Apply()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  ns.ScanBags()
  local keys = FoilKeybindsDB.keys
  if not next(keys) then return ns.Say(L.NOTHING) end
  FoilKeybindsDB.backup = FoilKeybindsDB.backup or { binds = {}, slots = {}, macros = {} }
  local b = FoilKeybindsDB.backup
  FoilKeybindsDB.applied = FoilKeybindsDB.applied or {}
  local done = 0
  for key, setup in pairs(keys) do if next(setup.slots) then -- clicked but empty keys are skipped
    local name = "FKB " .. key
    local text, n, trimmed = ns.FitMacro(setup, ns.best)
    for _, id in ipairs(trimmed) do setup.slots[id].mouseover = false end
    if not text then ns.Say(L.SKIP_LONG:format(key, n, ns.MAX))
    elseif upsertMacro(b, name, text) then
      keepBind(b, key)
      for _, m in ipairs(MODS) do keepBind(b, m .. key); SetBinding(m .. key) end
      local slot = ns.SlotOf(GetBindingAction(key))
      if slot then place(b, name, slot)
      else
        ns.Say(L.NO_SLOT:format(key))
        local free, cmd = ns.FirstEmptySlot(function(s, c) return HasAction(s) or GetBindingKey(c) ~= nil end)
        if free then
          place(b, name, free); SetBinding(key, cmd)
          ns.Say(L.PLACED:format(key, cmd, free))
        else
          SetBindingMacro(key, name)
          ns.Say(L.BOUND_DIRECT:format(key))
        end
      end
      FoilKeybindsDB.applied[key] = ns.Copy(setup) -- what the macro holds now; swaps and repair rebuild from this
      done = done + 1
    end
  end end
  SaveBindings(GetCurrentBindingSet())
  FoilKeybindsDB.copyUndo = nil -- the copy is live now; Undo reverts the Apply instead
  ns.SaveIndex()
  ns.Say(L.DONE:format(done))
end

function ns.Undo()
  if FoilKeybindsDB.copyUndo then -- a pending copy is undone first, it touched nothing in game
    FoilKeybindsDB.keys, FoilKeybindsDB.copyUndo = FoilKeybindsDB.copyUndo, nil
    if ns.Refresh then ns.Refresh() end
    return ns.Say(L.COPY_UNDONE)
  end
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  local b = FoilKeybindsDB.backup
  if not b then return ns.Say(L.NOTHING_TO_UNDO) end
  for key, action in pairs(b.binds) do
    if action == "" then SetBinding(key) else SetBinding(key, action) end
  end
  for name, body in pairs(b.macros) do -- bodies first: slot restore below may pick up these macros
    local i = GetMacroIndexByName(name)
    if body and i > 0 then EditMacro(i, name, nil, body) end
  end
  for slot, prev in pairs(b.slots) do
    ClearCursor()
    if not prev then PickupAction(slot) -- slot was empty: lift our macro off
    else
      if prev.kind == "spell" then PickupSpell(prev.id)
      elseif prev.kind == "item" then PickupItem(prev.id)
      elseif prev.kind == "macro" then PickupMacro(prev.id)
      end -- ponytail: other kinds (flyout, equipment set) stay as Apply left them
      if GetCursorInfo() then PlaceAction(slot) end
    end
    ClearCursor()
  end
  for name, body in pairs(b.macros) do -- delete last so macro indexes above stay valid
    local i = GetMacroIndexByName(name)
    if body == false and i > 0 then DeleteMacro(i) end
  end
  SaveBindings(GetCurrentBindingSet())
  FoilKeybindsDB.backup = nil
  FoilKeybindsDB.applied = nil -- macros are back to their old bodies, nothing of ours is live
  ns.Say(L.UNDONE)
end

-- Harmful/helpful decides the mouseover clause. ponytail: unverified on Forever, guarded to "other".
function ns.SpellKind(spellID)
  if not (C_Spell and C_Spell.IsSpellHarmful) then return "other" end
  if C_Spell.IsSpellHarmful(spellID) then return "harm" end
  if C_Spell.IsSpellHelpful and C_Spell.IsSpellHelpful(spellID) then return "help" end
  return "other"
end

function ns.SpellIcon(spellID)
  if not spellID then return QUESTION end -- imported spell with unknown ID
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellID) end
  if GetSpellTexture then return GetSpellTexture(spellID) end
end

-- Stored spells the character does not know (yet) are faded on the canvas.
-- Unknown API answers true so nothing fades by mistake.
function ns.IsKnown(spellID)
  if not spellID then return false end
  if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(spellID) end
  if IsPlayerSpell then return IsPlayerSpell(spellID) end
  if IsSpellKnown then return IsSpellKnown(spellID) end
  return true
end

-- Learned, active (non passive, non future) spells from the player spellbook, sorted by name.
function ns.LearnedSpells()
  local list, seen = {}, {}
  local function add(id, name)
    if id and name and not seen[id] then seen[id] = true; list[#list + 1] = { spellID = id, name = name } end
  end
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then -- 11.0+ API
    local bank = Enum.SpellBookSpellBank.Player
    for t = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local line = C_SpellBook.GetSpellBookSkillLineInfo(t)
      for i = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
        local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
        if info and info.itemType == Enum.SpellBookItemType.Spell and not info.isPassive and not info.isOffSpec then
          add(info.spellID, info.name)
        end
      end
    end
  else -- older API
    for t = 1, GetNumSpellTabs() do
      local _, _, offset, num = GetSpellTabInfo(t)
      for i = offset + 1, offset + num do
        local kind, id = GetSpellBookItemInfo(i, "spell")
        if kind == "SPELL" and not IsPassiveSpell(i, "spell") then add(id, GetSpellBookItemName(i, "spell")) end
      end
    end
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

-- Rewrites the macro of a key from its applied snapshot, only when the text changed.
local function rebuild(key)
  local setup = FoilKeybindsDB.applied and FoilKeybindsDB.applied[key]
  local name = "FKB " .. key
  local i = GetMacroIndexByName(name)
  local text = setup and i > 0 and ns.FitMacro(setup, ns.best)
  if text and GetMacroBody(i) ~= text then EditMacro(i, name, nil, text) end
end

-- Out of combat item swap: only macros of keys with an item slot. Uses the applied
-- snapshot, so card edits not yet applied stay off the live macro.
local function hasItem(setup)
  for _, s in pairs(setup.slots) do if s.item then return true end end
end
function ns.SwapItems()
  if InCombatLockdown() or not FoilKeybindsDB then return end -- macros are locked in combat
  local old = ns.best
  ns.ScanBags()
  for key, setup in pairs(FoilKeybindsDB.applied or {}) do
    if hasItem(setup) then rebuild(key) end
  end
  for cat, b in pairs(ns.best) do
    if old[cat] and old[cat].id ~= b.id then ns.Say(L.ITEM_NOW:format(b.name)) end
  end
  if ns.Refresh then ns.Refresh() end
end

-- Current name of a spellID, nil when the client has no spell with that ID.
-- Assumption: spell names for valid IDs are in the client data at login (modern clients
-- ship the spell DB locally), so nil here means removed, not "not loaded yet".
local function spellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if C_Spell and C_Spell.GetSpellInfo then local info = C_Spell.GetSpellInfo(id); return info and info.name end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

-- Repair popup: one line per change, OK closes, Undo puts the pre-repair setups back.
local popup
local function changeLine(c)
  local where = ("%s %s"):format(c.key, L["SLOT_" .. c.slot])
  if c.kind == "renamed" then return L.REPAIR_RENAMED:format(where, c.old, c.new) end
  return L.REPAIR_REMOVED:format(where, c.old or "?")
end
local function showPopup(changes)
  if not popup then
    popup = CreateFrame("Frame", "FoilKeybindsRepair", UIParent, "BasicFrameTemplateWithInset")
    popup:SetPoint("CENTER"); popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true); popup:EnableMouse(true); popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving); popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.title:SetPoint("TOP", 0, -6); popup.title:SetText(L.REPAIR_TITLE)
    popup.text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    popup.text:SetPoint("TOPLEFT", 16, -34); popup.text:SetWidth(388); popup.text:SetJustifyH("LEFT")
    local ok = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    ok:SetSize(90, 24); ok:SetPoint("BOTTOMRIGHT", -14, 12); ok:SetText(OKAY or "OK")
    ok:SetScript("OnClick", function() popup:Hide() end)
    local undo = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    undo:SetSize(90, 24); undo:SetPoint("RIGHT", ok, "LEFT", -8, 0); undo:SetText(L.UNDO)
    undo:SetScript("OnClick", function() ns.UndoRepair() end)
  end
  local lines = {}
  for i, c in ipairs(changes) do lines[i] = changeLine(c) end
  popup.text:SetText(table.concat(lines, "\n"))
  popup:SetSize(420, popup.text:GetStringHeight() + 84)
  popup:Show()
end

-- Once per login, out of combat. Fixes both the live setups and the applied snapshots,
-- rebuilds the macros whose snapshot changed. Nothing changed: no popup, no macro edits.
function ns.RepairOnLogin()
  local db = FoilKeybindsDB
  local keys, keyChanges = ns.Repair(db.keys, spellName)
  local applied, appChanges = ns.Repair(db.applied or {}, spellName)
  if #keyChanges == 0 and #appChanges == 0 then return end
  db.repairUndo = { keys = ns.Copy(db.keys), applied = ns.Copy(db.applied) }
  db.keys, db.applied = keys, db.applied and applied
  local changes, seen, touched = {}, {}, {}
  for _, list in ipairs({ keyChanges, appChanges }) do
    for _, c in ipairs(list) do
      local id = c.key .. c.slot .. c.kind
      if not seen[id] then seen[id] = true; changes[#changes + 1] = c end
    end
  end
  for _, c in ipairs(appChanges) do touched[c.key] = true end
  db.repairUndo.touched = touched
  for key in pairs(touched) do rebuild(key) end
  if ns.Refresh then ns.Refresh() end
  showPopup(changes)
end

function ns.UndoRepair()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end -- popup stays open to try again
  if popup then popup:Hide() end
  local u = FoilKeybindsDB.repairUndo
  if not u then return end
  FoilKeybindsDB.keys, FoilKeybindsDB.applied = u.keys, u.applied
  for key in pairs(u.touched) do rebuild(key) end
  FoilKeybindsDB.repairUndo = nil
  if ns.Refresh then ns.Refresh() end
  ns.Say(L.REPAIR_UNDONE)
end

-- One-time GrimorioSetup import: Warlock, GrimorioSetup loaded, no keys yet, never imported.
local function spellOf(name)
  local id
  if C_Spell and C_Spell.GetSpellInfo then local info = C_Spell.GetSpellInfo(name); id = info and info.spellID
  elseif GetSpellInfo then id = select(7, GetSpellInfo(name)) end
  return id, id and ns.SpellKind(id) or nil
end
function ns.ImportOnLogin()
  local db = FoilKeybindsDB
  if not GrimorioSetupData or db.grimorioImported or next(db.keys) or select(2, UnitClass("player")) ~= "WARLOCK" then return end
  db.grimorioImported = true
  local keys, lost = ns.ImportGrimorio(GrimorioSetupData, spellOf)
  db.keys = keys
  local names = {}
  for k in pairs(keys) do names[#names + 1] = k end
  table.sort(names)
  ns.Say(L.GRIM_IMPORTED:format(table.concat(names, ", ")))
  for _, l in ipairs(lost) do
    if l.skipped then ns.Say(L.GRIM_SKIPPED:format(l.key))
    elseif l.jump then ns.Say(L.GRIM_JUMP)
    else ns.Say(L.GRIM_LOST:format(l.key, l.text)) end
  end
  ns.Say(L.GRIM_NEXT)
  if ns.Refresh then ns.Refresh() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN"); ev:RegisterEvent("PLAYER_LOGOUT"); ev:RegisterEvent("BAG_UPDATE_DELAYED"); ev:RegisterEvent("PLAYER_REGEN_ENABLED")
local repairPending
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGOUT" then return ns.SaveIndex() end
  if event == "PLAYER_LOGIN" then repairPending = true; ns.ImportOnLogin() end
  ns.SwapItems()
  if repairPending and not InCombatLockdown() then repairPending = false; ns.RepairOnLogin() end
end)
