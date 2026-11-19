-- Thin game layer: turns core output into macros on the bar slot each key presses.
local _, ns = ...
local L = ns.L
local QUESTION = 134400 -- question mark icon; #showtooltip swaps it for the real spell

function ns.Say(msg) print("|cff93d35aFoil Keybinds:|r " .. msg) end
-- Info lines (Apply summary, placements, item swaps) obey the chat setting; errors use ns.Say.
function ns.Info(msg) if not ns.S or ns.S.chat then ns.Say(msg) end end

local MODS = { "SHIFT-", "ALT-", "ALT-SHIFT-", "CTRL-" }
local MODKEY = { shift = "SHIFT-", alt = "ALT-", altshift = "ALT-SHIFT-", ctrl = "CTRL-" }

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
  local _, nChar = GetNumMacros()
  if nChar >= (MAX_CHARACTER_MACROS or 18) then ns.Say(L.MACRO_LIMIT:format(name)); return false end
  local ok, idx = pcall(CreateMacro, name, QUESTION, body, true)
  if not ok or not idx or idx == 0 then ns.Say(L.CREATE_FAILED:format(name, tostring(idx))); return false end
  return true
end

-- Puts back what a bar slot held before the first Apply (empty: lifts our macro off).
local function restoreSlot(prev, slot)
  ClearCursor()
  if not prev then PickupAction(slot)
  else
    if prev.kind == "spell" then PickupSpell(prev.id)
    elseif prev.kind == "item" then PickupItem(prev.id)
    elseif prev.kind == "macro" then PickupMacro(prev.id)
    end -- ponytail: other kinds (flyout, equipment set) stay as Apply left them
    if GetCursorInfo() then PlaceAction(slot) end
  end
  ClearCursor()
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
      if id then owned[id] = itemName(id) or "" end
    end
  end
  ns.best = ns.BestItems(owned, usable and function(id) return (usable(id)) end)
  ns.scanned = true
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

-- Pet slots: built-in pet action textures (FrameXML globals), Interface\Icons fallbacks.
ns.playerClass = select(2, UnitClass("player"))
local PET_ICON = {
  follow = PET_FOLLOW_TEXTURE or "Interface\\Icons\\Ability_Tracking",
  moveto = PET_MOVE_TO_TEXTURE or "Interface\\Icons\\Ability_Hunter_Pet_Goto",
  stay = PET_WAIT_TEXTURE or "Interface\\Icons\\Spell_Nature_TimeStop",
  attack = PET_ATTACK_TEXTURE or "Interface\\Icons\\Ability_GhoulFrenzy",
  passive = PET_PASSIVE_TEXTURE or "Interface\\Icons\\Ability_Seal",
  defensive = PET_DEFENSIVE_TEXTURE or "Interface\\Icons\\Ability_Defend",
}
function ns.IsPetSlot(s) return s and (s.pet or s.petSpecial) and true or false end
function ns.PetLabel(s) return s.pet and L["PET_" .. s.pet:upper()] or L.PET_SPECIAL end
function ns.PetIcon(s)
  if s.pet then return PET_ICON[s.pet] end
  local first = (ns.PET_SPECIAL[ns.playerClass] or {})[1]
  return first and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(first[2]) or QUESTION
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

-- Puts one key back as it was before the first Apply: bindings, bar slot, macro body (or no macro).
-- Moves macros from the old "FKB <key>" names to the new ones. Same macro index, so bar slots keep it.
-- Out of combat only (macro API is locked in combat).
function ns.MigrateNames()
  local db = FoilKeybindsDB
  if InCombatLockdown() or not db then return end
  local list, seen, exists = {}, {}, {}
  for _, t in ipairs({ db.keys or {}, db.applied or {} }) do
    for key in pairs(t) do if not seen[key] then seen[key] = true; list[#list + 1] = key end end
  end
  for _, key in ipairs(list) do
    for _, n in ipairs({ ns.OldMacroName(key), ns.MacroName(key) }) do exists[n] = GetMacroIndexByName(n) > 0 end
  end
  local renames, deletes, macros = ns.RenamePlan(list, exists, db.backup and db.backup.macros)
  for _, r in ipairs(renames) do
    local i = GetMacroIndexByName(r.from)
    local _, icon, body = GetMacroInfo(i)
    EditMacro(i, r.to, icon, body) -- pass icon and body: some clients wipe nil fields
  end
  for _, n in ipairs(deletes) do DeleteMacro(GetMacroIndexByName(n)) end
  if db.backup then db.backup.macros = macros end
  if #renames + #deletes == 0 then return end
  for _, key in ipairs(list) do -- modifier binds point at the macro by name
    local old = "MACRO " .. ns.OldMacroName(key)
    for _, m in ipairs({ "", "SHIFT-", "ALT-", "ALT-SHIFT-", "CTRL-" }) do
      if GetBindingAction(m .. key) == old then SetBindingMacro(m .. key, ns.MacroName(key)) end
    end
  end
  SaveBindings(GetCurrentBindingSet())
end

local function unapply(b, key, snap)
  for _, k in ipairs({ key, "SHIFT-" .. key, "ALT-" .. key, "ALT-SHIFT-" .. key, "CTRL-" .. key }) do
    local action = b.binds[k]
    if action == "" then SetBinding(k) elseif action then SetBinding(k, action) end
  end
  local name = ns.MacroName(key)
  local i, body = GetMacroIndexByName(name), b.macros[name]
  if body and i > 0 then EditMacro(i, name, nil, body) end
  if snap.barSlot and b.slots[snap.barSlot] ~= nil then restoreSlot(b.slots[snap.barSlot], snap.barSlot) end
  if body == false and i > 0 then DeleteMacro(i) end
  FoilKeybindsDB.applied[key] = nil
end

function ns.Apply()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  ns.MigrateNames()
  ns.ScanBags()
  local keys = FoilKeybindsDB.keys
  if not next(keys) and not next(FoilKeybindsDB.applied or {}) then return ns.Say(L.NOTHING) end
  FoilKeybindsDB.backup = FoilKeybindsDB.backup or { binds = {}, slots = {}, macros = {} }
  local b = FoilKeybindsDB.backup
  FoilKeybindsDB.applied = FoilKeybindsDB.applied or {}
  local done = 0
  for key, snap in pairs(FoilKeybindsDB.applied) do -- keys cleared since the last Apply go back
    if not (keys[key] and next(keys[key].slots)) then unapply(b, key, snap) end
  end
  for key, setup in pairs(keys) do if next(setup.slots) then -- clicked but empty keys are skipped
    local name = ns.MacroName(key)
    local placed
    local text, n, trimmed = ns.FitMacro(setup, ns.best)
    for _, id in ipairs(trimmed) do setup.slots[id].mouseover = false end
    if not text then ns.Say(L.SKIP_LONG:format(key, n, ns.MAX))
    elseif upsertMacro(b, name, text) then
      keepBind(b, key)
      for _, m in ipairs(MODS) do keepBind(b, m .. key); SetBinding(m .. key) end
      -- ponytail: two keys on the same bar command share one slot, the last key applied wins it
      local slot = ns.SlotOf(GetBindingAction(key))
      local prev = FoilKeybindsDB.applied[key]
      local modSlot
      if not setup.slots.normal then -- base key stays as it is (Jump on Space); modifiers press a bar slot with the macro
        if b.binds[key] == "" then SetBinding(key) else SetBinding(key, b.binds[key]) end
        local free = prev and prev.modSlot and prev.barSlot
        if free and GetActionText(free) ~= name then free = nil end -- reuse our old slot while it still holds the macro
        if not free then free = ns.FirstEmptySlot(function(s, c) return HasAction(s) or GetBindingKey(c) ~= nil end) end
        if free then
          local cmd = ns.CommandOf(free)
          place(b, name, free); placed, modSlot = free, true
          for id, m in pairs(MODKEY) do if setup.slots[id] then SetBinding(m .. key, cmd) end end
          ns.Info(L.MODS_PLACED:format(key, cmd, free))
        else -- no free slot: modifiers go straight to the macro (no cooldown on a bar)
          for id, m in pairs(MODKEY) do if setup.slots[id] then SetBindingMacro(m .. key, name) end end
          ns.Info(L.BOUND_DIRECT:format(key))
        end
      elseif slot then place(b, name, slot); placed = slot
      else
        ns.Say(L.NO_SLOT:format(key))
        local free, cmd = ns.FirstEmptySlot(function(s, c) return HasAction(s) or GetBindingKey(c) ~= nil end)
        if free then
          place(b, name, free); SetBinding(key, cmd); placed = free
          ns.Info(L.PLACED:format(key, cmd, free))
        else
          SetBindingMacro(key, name)
          ns.Info(L.BOUND_DIRECT:format(key))
        end
      end
      -- the slot an earlier Apply used is no longer ours: put back what it held
      if prev and prev.barSlot and prev.barSlot ~= placed and b.slots[prev.barSlot] ~= nil then
        restoreSlot(b.slots[prev.barSlot], prev.barSlot)
      end
      FoilKeybindsDB.applied[key] = ns.Copy(setup) -- what the macro holds now; swaps and repair rebuild from this
      FoilKeybindsDB.applied[key].barSlot = placed
      FoilKeybindsDB.applied[key].modSlot = modSlot
      done = done + 1
    end
  end end
  SaveBindings(GetCurrentBindingSet())
  FoilKeybindsDB.copyUndo = nil -- the copy is live now; Undo reverts the Apply instead
  ns.SaveIndex()
  ns.Info(L.DONE:format(done))
  if ns.Refresh then ns.Refresh() end
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
  for slot, prev in pairs(b.slots) do restoreSlot(prev, slot) end
  for name, body in pairs(b.macros) do -- delete last so macro indexes above stay valid
    local i = GetMacroIndexByName(name)
    if body == false and i > 0 then DeleteMacro(i) end
  end
  SaveBindings(GetCurrentBindingSet())
  FoilKeybindsDB.backup = nil
  FoilKeybindsDB.applied = nil -- macros are back to their old bodies, nothing of ours is live
  ns.Say(L.UNDONE)
  if ns.Refresh then ns.Refresh() end
end

-- Harmful/helpful decides the mouseover clause. ponytail: unverified on Forever, guarded to "other".
function ns.SpellKind(spellID)
  if not (C_Spell and C_Spell.IsSpellHarmful) then return "other" end
  if C_Spell.IsSpellHarmful(spellID) then return "harm" end
  if C_Spell.IsSpellHelpful and C_Spell.IsSpellHelpful(spellID) then return "help" end
  return "other"
end

-- Spell data may not be loaded yet (texture nil): ask for it, show fallback (What's Training's
-- icon) or "?" for now. SPELL_DATA_LOAD_RESULT then updates the cells that show this spellID.
function ns.SpellIcon(spellID, fallback)
  if not spellID then return fallback or QUESTION end -- imported spell with unknown ID
  if C_Spell and C_Spell.IsSpellDataCached and not C_Spell.IsSpellDataCached(spellID) and C_Spell.RequestLoadSpellData then
    C_Spell.RequestLoadSpellData(spellID)
  end
  local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    or GetSpellTexture and GetSpellTexture(spellID)
  return tex or fallback or QUESTION
end

-- Spell by name in the player's spellbook: id and harmful/helpful kind (both nil when unknown).
local function spellOf(name)
  local id
  if not name then return end
  if C_Spell and C_Spell.GetSpellInfo then local info = C_Spell.GetSpellInfo(name); id = info and info.spellID
  elseif GetSpellInfo then id = select(7, GetSpellInfo(name)) end
  return id, id and ns.SpellKind(id) or nil
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

-- Learned names (any rank), built once per refresh pass: frames call ResetLearned before drawing.
local learnedNames
function ns.ResetLearned() learnedNames = nil end
local function learned()
  if not learnedNames then
    learnedNames = {}
    for _, s in ipairs(ns.LearnedSpells()) do learnedNames[s.name] = true end
  end
  return learnedNames
end
function ns.IsKnownSlot(s) return ns.Known(s.spellID, s.name, ns.IsKnown, learned()) end

-- What a slot shows: texture, name (tooltip), known, spellID, sequence length. A spell stored
-- without an ID (GrimorioSetup import) gets it here once the spellbook has it.
function ns.SlotView(s)
  if not s then return end
  if ns.IsPetSlot(s) then return ns.PetIcon(s), ns.PetLabel(s), true end
  if s.item then return ns.ItemIcon(s.item), ns.ItemLabel(s.item), true end
  local first = s.seq and s.seq[1] or s
  if not first.spellID then first.spellID = (spellOf(first.name)) end
  local name = first.name
  if s.seq then
    local l = {}
    for i, x in ipairs(s.seq) do l[i] = x.name end
    name = table.concat(l, " > ")
  end
  return ns.SpellIcon(first.spellID), name, ns.IsKnownSlot(first), first.spellID, s.seq and #s.seq
end

-- Learned, active (non passive, non future) spells from the player spellbook, sorted by name.
function ns.LearnedSpells()
  local list, seen = {}, {}
  local function add(id, name)
    if not (id and name) or seen[id] then return end
    seen[id] = true
    local sub = C_Spell and C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(id)
      or GetSpellSubtext and GetSpellSubtext(id)
    if sub == "" then sub = nil end
    list[#list + 1] = { spellID = id, name = name, sub = sub, rank = sub and tonumber(sub:match("(%d+)")) }
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
  return ns.DedupeSpells(list)
end

-- Future spells from What's Training (optional). [] when it is missing or not ready yet; then
-- asks it to load the class and refreshes an open picker when it is ready (callbacks, no polling).
-- ponytail: faction filter only; WT's race filter takes a race tag whose format is unverified.
ns.futureLevel = {} -- spellID -> level, for the canvas tooltip
local wtHooked
function ns.HasWT() return WT_API ~= nil end
function ns.FutureSpells()
  local api = WT_API
  if not api then return {} end
  local class = select(2, UnitClass("player"))
  if not (api.IsReady() and api.IsClassReady(class)) then
    if not wtHooked then
      wtHooked = true
      local function again() if ns.RefreshPicker then ns.RefreshPicker() end; if ns.Refresh then ns.Refresh() end end
      api.RegisterCallback(ns, "Ready", again)
      api.RegisterCallback(ns, "ClassReady", again)
    end
    if api.IsReady() then pcall(api.LoadClass, class) end
    return {}
  end
  local learned = {}
  for _, s in ipairs(ns.LearnedSpells()) do learned[s.name] = true end
  local out = ns.FutureFrom(api.GetCatalog(class, { faction = UnitFactionGroup("player") }), learned)
  for _, s in ipairs(out) do ns.futureLevel[s.spellID] = s.level end
  return out
end
function ns.FutureLevel(id)
  if id and not ns.futureLevel[id] and WT_API then ns.FutureSpells() end
  return id and ns.futureLevel[id]
end

-- Rewrites the macro of a key from its applied snapshot, only when the text changed.
-- Returns why it could not write: "missing" (no macro) or "long" (over 255).
local function rebuild(key)
  local setup = FoilKeybindsDB.applied and FoilKeybindsDB.applied[key]
  if not setup then return end
  local name = ns.MacroName(key)
  local i = GetMacroIndexByName(name)
  if i == 0 then return "missing" end
  local text = ns.FitMacro(setup, ns.best)
  if not text then return "long" end
  if not ns.SameMacro(GetMacroBody(i), text) then EditMacro(i, name, nil, text) end
end

-- Out of combat item swap: only macros of keys with an item slot. Uses the applied
-- snapshot, so card edits not yet applied stay off the live macro.
-- manual (Refresh items button, /fkb items): always says what happened. Automatic swaps
-- (login, bags, combat end, level-up) warn once per key and reason per session.
local function hasItem(setup)
  for _, s in pairs(setup.slots) do if s.item then return true end end
end
local warned = {}
function ns.SwapItems(manual)
  if not FoilKeybindsDB then return end
  if InCombatLockdown() then if manual then ns.Say(L.IN_COMBAT) end; return end -- macros are locked in combat
  local any
  for _, setup in pairs(FoilKeybindsDB.applied or {}) do if hasItem(setup) then any = true; break end end
  if not any then if manual then ns.Say(L.ITEMS_NONE) end; return end
  local old, first = ns.best, not ns.scanned -- first scan of the session: no "before" to compare with
  ns.ScanBags()
  for key, setup in pairs(FoilKeybindsDB.applied) do
    local why = hasItem(setup) and rebuild(key)
    if why and (manual or not warned[key .. why]) then
      warned[key .. why] = true
      ns.Say(L["SWAP_" .. why]:format(key))
    end
  end
  local changes = first and {} or ns.ItemChanges(old, ns.best, FoilKeybindsDB.applied)
  local say = manual and ns.Say or ns.Info
  for _, c in ipairs(changes) do say(L.ITEM_CHANGE:format(c.key, c.from or L.ITEM_NONE, c.to or L.ITEM_NONE)) end
  if manual and #changes == 0 then ns.Say(L.ITEMS_UP_TO_DATE) end
  if ns.Refresh then ns.Refresh() end
end

-- Repair lookup: current name of a spellID, false when the client has no such spell, nil when
-- it cannot tell (data not loaded yet, or no DoesSpellExist): nil never removes anything.
local function spellName(id)
  local n
  if C_Spell and C_Spell.GetSpellName then n = C_Spell.GetSpellName(id)
  elseif C_Spell and C_Spell.GetSpellInfo then local info = C_Spell.GetSpellInfo(id); n = info and info.name
  elseif GetSpellInfo then n = GetSpellInfo(id) end
  if n then return n end
  if C_Spell and C_Spell.DoesSpellExist and not C_Spell.DoesSpellExist(id) then return false end
  if C_Spell and C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(id) end
end

-- Repair popup: one line per change, OK closes, Undo puts the pre-repair setups back.
local popup
local function changeLine(c)
  local where = ("%s %s"):format(c.key, L["SLOT_" .. c.slot]) .. (c.pos and (" #" .. c.pos) or "")
  if c.kind == "renamed" then return L.REPAIR_RENAMED:format(where, c.old, c.new) end
  return L.REPAIR_REMOVED:format(where, c.old or "?")
end
local function showPopup(changes)
  if not popup then
    popup = ns.Panel("FoilKeybindsRepair", UIParent, L.REPAIR_TITLE)
    popup:SetPoint("CENTER"); popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true); popup:EnableMouse(true); popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving); popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup.text = ns.Text(popup, "body", 13)
    popup.text:SetPoint("TOPLEFT", 16, -38); popup.text:SetWidth(388); popup.text:SetJustifyH("LEFT"); popup.text:SetSpacing(2)
    local ok = ns.Button(popup, 90, 24, OKAY or "OK", ns.T.fel)
    ok:SetPoint("BOTTOMRIGHT", -14, 12)
    ok:SetScript("OnClick", function() popup:Hide() end)
    local undo = ns.Button(popup, 90, 24, L.UNDO)
    undo:SetPoint("RIGHT", ok, "LEFT", -8, 0)
    undo:SetScript("OnClick", function() ns.UndoRepair() end)
  end
  local lines = {}
  for i, c in ipairs(changes) do lines[i] = changeLine(c) end
  popup.text:SetText(table.concat(lines, "\n"))
  popup:SetSize(420, popup.text:GetStringHeight() + 90)
  popup:Show()
end

-- Once per login, out of combat. Fixes both the live setups and the applied snapshots,
-- rebuilds the macros whose snapshot changed. Nothing changed: no popup, no macro edits.
function ns.RepairOnLogin()
  local db = FoilKeybindsDB
  local function idOf(name) return (spellOf(name)) end
  local keys, keyChanges = ns.Repair(db.keys, spellName, idOf)
  local applied, appChanges = ns.Repair(db.applied or {}, spellName, idOf)
  local undo = { keys = db.keys, applied = db.applied }
  db.keys, db.applied = keys, db.applied and applied -- filled IDs are kept even with no change to show
  if #keyChanges == 0 and #appChanges == 0 then return end
  db.repairUndo = undo
  local changes, seen, touched = {}, {}, {}
  for _, list in ipairs({ keyChanges, appChanges }) do
    for _, c in ipairs(list) do
      local id = c.key .. c.slot .. c.kind .. (c.pos or "")
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
    else ns.Say(L.GRIM_LOST:format(l.key, l.text)) end
  end
  ns.Say(L.GRIM_NEXT)
  if ns.Refresh then ns.Refresh() end
end

local ev = CreateFrame("Frame")
-- PLAYER_LEVEL_UP: a potion can become usable. ponytail: if the usable check still sees the old
-- level at this event, the swap waits for the next bag change or the Refresh items button.
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_LOGOUT", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED", "PLAYER_LEVEL_UP" }) do
  ev:RegisterEvent(e)
end
local repairPending
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGOUT" then return ns.SaveIndex() end
  if event == "PLAYER_LOGIN" then repairPending = true; ns.ImportOnLogin() end
  ns.SwapItems()
  if repairPending and not InCombatLockdown() then repairPending = false; ns.MigrateNames(); ns.RepairOnLogin() end
end)
