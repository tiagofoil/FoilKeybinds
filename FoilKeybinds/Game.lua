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
local built -- best items the item macros were last written with (Apply or swap); nil until then
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

-- Replaces this character's keys with another's. Not applied; Undo brings the old keys back
-- (edit steps made after the copy come back first; the ones before it are dropped).
function ns.CopyFrom(name)
  local me, class = ns.Me()
  local src = FoilKeybindsAccount[class] and FoilKeybindsAccount[class][name]
  if not src or name == me then return end
  FoilKeybindsDB.copyUndo = ns.Copy(FoilKeybindsDB.keys)
  FoilKeybindsDB.keys = ns.Copy(src)
  if ns.ClearHistory then ns.ClearHistory() end
  if ns.Refresh then ns.Refresh() end
  ns.Say(L.COPIED:format(name))
end

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

-- Apply in two steps: plan() reads the game and writes nothing, run(p) does what the plan says.
-- The preview lists the plan and OK plans again and runs it, so the preview is what Apply does.
-- Bars and keybinds only while the master switch is ON (ns.Manages); OFF writes macros only.
local KEYBINDS = { "", "SHIFT-", "ALT-", "ALT-SHIFT-", "CTRL-" }
function ns.Manages() return FoilKeybindsDB and FoilKeybindsDB.manage and true or false end

local function sorted(t)
  local l = {}
  for k in pairs(t) do l[#l + 1] = k end
  table.sort(l)
  return l
end

local function plan()
  local db = FoilKeybindsDB
  local keys, applied = db.keys, db.applied or {}
  local b = db.backup or { binds = {}, slots = {}, macros = {} }
  local manage = ns.Manages()
  -- binds: binding -> final value ("" cleared, a command, or "MACRO <name>"); owner: the key it is for
  local p = { manage = manage, binds = {}, owner = {}, order = {}, keys = {}, drops = {}, notes = {} }
  local function bind(k, v, key)
    if p.binds[k] == nil then p.order[#p.order + 1] = k end
    p.binds[k], p.owner[k] = v, key
  end
  local taken = {}
  local function free()
    local slot, cmd = ns.FirstEmptySlot(function(s, c) return taken[s] or HasAction(s) or GetBindingKey(c) ~= nil end)
    if slot then taken[slot] = true end
    return slot, cmd
  end
  for _, key in ipairs(sorted(applied)) do -- keys cleared since the last Apply go back
    if not (keys[key] and next(keys[key].slots)) then
      local snap, d = applied[key], { key = key, name = ns.MacroName(key) }
      if manage then
        for _, m in ipairs(KEYBINDS) do if b.binds[m .. key] then bind(m .. key, b.binds[m .. key], key) end end
        if snap.barSlot and b.slots[snap.barSlot] ~= nil then d.restore = snap.barSlot end
      end
      p.drops[#p.drops + 1] = d
    end
  end
  local _, nChar = GetNumMacros()
  for _, key in ipairs(sorted(keys)) do
    local setup = keys[key]
    if next(setup.slots) then -- clicked but empty keys are skipped
      local name = ns.MacroName(key)
      local text, n, trimmed = ns.FitMacro(setup, ns.best)
      local i = GetMacroIndexByName(name)
      if not text then p.notes[#p.notes + 1] = L.SKIP_LONG:format(key, n, ns.MAX)
      elseif i == 0 and nChar >= (MAX_CHARACTER_MACROS or 18) then p.notes[#p.notes + 1] = L.MACRO_LIMIT:format(name)
      else
        if i == 0 then nChar = nChar + 1 end
        local prev = applied[key]
        local k = { key = key, setup = setup, name = name, text = text, trimmed = trimmed, new = i == 0,
          changed = i == 0 or not ns.SameMacro(GetMacroBody(i), text) }
        if not manage then -- macros only: whatever an earlier Apply placed stays where it is
          k.place, k.modSlot, k.keep = prev and prev.barSlot, prev and prev.modSlot, true
        else
          for _, m in ipairs(MODS) do bind(m .. key, "", key) end
          -- ponytail: two keys on the same bar command share one slot, the last key applied wins it
          local slot = ns.SlotOf(GetBindingAction(key))
          if not setup.slots.normal then -- base key stays as it is (Jump on Space); modifiers press a bar slot with the macro
            local base = b.binds[key]
            if base == nil then base = GetBindingAction(key) or "" end
            bind(key, base, key)
            local f = prev and prev.modSlot and prev.barSlot
            if f and GetActionText(f) ~= name then f = nil end -- reuse our old slot while it still holds the macro
            if f then taken[f] = true else f = free() end
            if f then
              local cmd = ns.CommandOf(f)
              k.place, k.modSlot = f, true
              for id, m in pairs(MODKEY) do if setup.slots[id] then bind(m .. key, cmd, key) end end
              k.msg = L.MODS_PLACED:format(key, cmd, f)
            else -- no free slot: modifiers go straight to the macro (no cooldown on a bar)
              for id, m in pairs(MODKEY) do if setup.slots[id] then bind(m .. key, "MACRO " .. name, key) end end
              k.msg = L.BOUND_DIRECT:format(key)
            end
          elseif slot then k.place = slot; taken[slot] = true
          else
            k.say = L.NO_SLOT:format(key)
            local f, cmd = free()
            if f then k.place = f; bind(key, cmd, key); k.msg = L.PLACED:format(key, cmd, f)
            else bind(key, "MACRO " .. name, key); k.msg = L.BOUND_DIRECT:format(key) end
          end
          -- the slot an earlier Apply used is no longer ours: put back what it held
          if prev and prev.barSlot and prev.barSlot ~= k.place and b.slots[prev.barSlot] ~= nil then k.restore = prev.barSlot end
        end
        p.keys[#p.keys + 1] = k
      end
    end
  end
  return p
end

local function setBind(k, v)
  if v == "" then SetBinding(k)
  elseif v:find("^MACRO ") then SetBindingMacro(k, v:sub(7))
  else SetBinding(k, v) end
end

-- quiet: the preview had nothing to show; snapshots still follow the card, a pending Copy stays undoable.
local function run(p, quiet)
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  local db = FoilKeybindsDB
  db.backup = db.backup or { binds = {}, slots = {}, macros = {} }
  db.applied = db.applied or {}
  local b, failed, done = db.backup, {}, 0
  for _, d in ipairs(p.drops) do -- macro back to its old body (or gone), bar slot back to what it held
    local i, body = GetMacroIndexByName(d.name), b.macros[d.name]
    if body and i > 0 then EditMacro(i, d.name, nil, body) end
    if d.restore then restoreSlot(b.slots[d.restore], d.restore) end
    if body == false and i > 0 then DeleteMacro(i) end
    db.applied[d.key] = nil
  end
  for _, k in ipairs(p.keys) do
    for _, id in ipairs(k.trimmed) do k.setup.slots[id].mouseover = false end
    if upsertMacro(b, k.name, k.text) then
      if k.say then ns.Say(k.say) end
      if k.place and not k.keep then place(b, k.name, k.place) end
      if k.restore then restoreSlot(b.slots[k.restore], k.restore) end
      if k.msg and not quiet then ns.Info(k.msg) end
      local snap = ns.Copy(k.setup) -- what the macro holds now; swaps and repair rebuild from this
      snap.barSlot, snap.modSlot = k.place, k.modSlot
      db.applied[k.key] = snap
      done = done + 1
    else failed[k.key] = true end -- no macro: leave that key's bindings alone
  end
  for _, k in ipairs(p.order) do
    if not failed[p.owner[k]] then keepBind(b, k); setBind(k, p.binds[k]) end
  end
  for _, n in ipairs(p.notes) do ns.Say(n) end
  SaveBindings(GetCurrentBindingSet())
  built = ns.best
  if not quiet then db.copyUndo = nil end -- the copy is live now; Undo reverts the Apply instead
  ns.SaveIndex()
  if quiet then ns.Say(L.NOTHING_TO_CHANGE) else ns.Info((p.manage and L.DONE or L.DONE_MACROS):format(done)) end
  if ns.Refresh then ns.Refresh() end
end

-- Preview text: one line per change the player would see in game.
local spellNameOf = C_Spell and C_Spell.GetSpellName or function(id) return (GetSpellInfo(id)) end
local function bindLabel(k)
  local mods, base = k:match("^(.-)([^%-]+)$")
  mods = mods:gsub("ALT%-", "Alt-"):gsub("SHIFT%-", "Shift-"):gsub("CTRL%-", "Ctrl-")
  return mods .. (L["KEY_" .. base] or base)
end
local function cmdLabel(v)
  if v == "" then return nil end
  if v:find("^MACRO ") then return L.PV_MACRO:format(v:sub(7)) end
  return GetBindingName and GetBindingName(v) or v
end
local function slotLabel(slot) -- what a bar slot holds now
  local kind, id = GetActionInfo(slot)
  if not kind then return L.PV_EMPTY end
  if kind == "macro" then return GetActionText(slot) or kind end
  if kind == "spell" then return spellNameOf(id) or kind end
  if kind == "item" then return itemName(id) or kind end
  return kind
end
local function backupLabel(prev) -- what the backup holds for a bar slot
  if not prev then return L.PV_EMPTY end
  if prev.kind == "spell" then return spellNameOf(prev.id) or prev.kind end
  if prev.kind == "item" then return itemName(prev.id) or prev.kind end
  return tostring(prev.id)
end
local function describe(p)
  local out, b = {}, FoilKeybindsDB.backup or { slots = {}, macros = {} }
  for _, d in ipairs(p.drops) do
    local body = b.macros[d.name]
    if GetMacroIndexByName(d.name) > 0 then
      if body == false then out[#out + 1] = L.PV_DELETE:format(d.key, d.name)
      elseif body then out[#out + 1] = L.PV_RESTORE_MACRO:format(d.key, d.name) end
    end
    if d.restore then out[#out + 1] = L.PV_PUT_BACK:format(d.restore, backupLabel(b.slots[d.restore])) end
  end
  for _, k in ipairs(p.keys) do
    if k.new then out[#out + 1] = L.PV_CREATE:format(k.key, k.name)
    elseif k.changed then out[#out + 1] = L.PV_UPDATE:format(k.key, k.name) end
    if k.place and not k.keep and GetActionText(k.place) ~= k.name then
      out[#out + 1] = L.PV_PLACE:format(k.key, k.name, k.place, slotLabel(k.place))
    end
    if k.restore then out[#out + 1] = L.PV_PUT_BACK:format(k.restore, backupLabel(b.slots[k.restore])) end
  end
  for _, k in ipairs(p.order) do
    local was, now = GetBindingAction(k) or "", p.binds[k]
    if was ~= now then
      local wl, nl = cmdLabel(was), cmdLabel(now)
      if not nl then out[#out + 1] = L.PV_CLEARED:format(bindLabel(k), wl)
      elseif not wl then out[#out + 1] = L.PV_BOUND:format(bindLabel(k), nl)
      else out[#out + 1] = L.PV_REBOUND:format(bindLabel(k), wl, nl) end
    end
  end
  return out
end

function ns.Apply()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  ns.MigrateNames()
  ns.ScanBags()
  if not next(FoilKeybindsDB.keys) and not next(FoilKeybindsDB.applied or {}) then return ns.Say(L.NOTHING) end
  local p = plan()
  local lines = describe(p)
  if #lines == 0 then return run(p, true) end
  local text = table.concat(lines, "\n")
  if #p.notes > 0 then text = "|cffef5d55" .. table.concat(p.notes, "\n") .. "|r\n\n" .. text end
  ns.Popup(L.PV_TITLE, text, { { OKAY or "OK", function() run(plan()) end, ns.T.fel }, { CANCEL or "Cancel" } }, true)
end

-- Master switch. ON asks first (what Apply will do). OFF after an Apply asks what happens to the
-- bars and keybinds it changed. The controls are redrawn first, so a cancelled click springs back.
function ns.SetManage(on)
  local db = FoilKeybindsDB
  local function redraw()
    if ns.Refresh then ns.Refresh() end
    if ns.RefreshSettings then ns.RefreshSettings() end
  end
  local function set(v) db.manage = v; redraw() end
  redraw()
  if on == ns.Manages() then return end
  if on then
    return ns.Popup(L.MANAGE_ON_TITLE, L.MANAGE_ON_TEXT, { { OKAY or "OK", function() set(true) end, ns.T.fel }, { CANCEL or "Cancel" } })
  end
  local b = db.backup
  if not (b and (next(b.binds) or next(b.slots))) then return set(false) end
  ns.Popup(L.MANAGE_OFF_TITLE, L.MANAGE_OFF_TEXT, {
    { L.MANAGE_UNDO, function() if not ns.UndoBars() then return true end; set(false) end, ns.T.blood },
    { L.MANAGE_KEEP, function() set(false) end },
  }, true)
end

-- Switch turned OFF with "Undo them": bindings and bar slots go back, the macros stay.
-- Returns false in combat (the popup stays open to try again).
function ns.UndoBars()
  if InCombatLockdown() then ns.Say(L.IN_COMBAT); return false end
  local b = FoilKeybindsDB.backup
  for k, action in pairs(b.binds) do setBind(k, action) end
  for slot, prev in pairs(b.slots) do restoreSlot(prev, slot) end
  SaveBindings(GetCurrentBindingSet())
  b.binds, b.slots = {}, {}
  for _, snap in pairs(FoilKeybindsDB.applied or {}) do snap.barSlot, snap.modSlot = nil, nil end
  ns.Say(L.BARS_UNDONE)
  return true
end

-- A pending Copy from: its old keys come back. It touched nothing in game. False when none.
function ns.UndoCopy()
  if not FoilKeybindsDB.copyUndo then return false end
  FoilKeybindsDB.keys, FoilKeybindsDB.copyUndo = FoilKeybindsDB.copyUndo, nil
  if ns.Refresh then ns.Refresh() end
  ns.Say(L.COPY_UNDONE)
  return true
end

-- Reset all: bindings, bar slots and macros go back to how they were before Apply. Key setups stay.
function ns.ResetAll()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  local b = FoilKeybindsDB.backup
  if not b then return ns.Say(L.NOTHING_TO_RESET) end
  local manage = ns.Manages() -- OFF: macros only, bars and keybinds stay as they are
  if manage then for key, action in pairs(b.binds) do setBind(key, action) end end
  for name, body in pairs(b.macros) do -- bodies first: slot restore below may pick up these macros
    local i = GetMacroIndexByName(name)
    if body and i > 0 then EditMacro(i, name, nil, body) end
  end
  if manage then for slot, prev in pairs(b.slots) do restoreSlot(prev, slot) end end
  for name, body in pairs(b.macros) do -- delete last so macro indexes above stay valid
    local i = GetMacroIndexByName(name)
    if body == false and i > 0 then DeleteMacro(i) end
  end
  SaveBindings(GetCurrentBindingSet())
  b.macros = {}
  if manage or not (next(b.binds) or next(b.slots)) then FoilKeybindsDB.backup = nil end
  FoilKeybindsDB.applied = nil -- macros are back to their old bodies, nothing of ours is live
  ns.Say(manage and L.UNDONE or L.UNDONE_MACROS)
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
  local old = built -- nil on the first swap of the session: no "before" to compare with
  ns.ScanBags()
  local failed = {}
  for key, setup in pairs(FoilKeybindsDB.applied) do
    local why = hasItem(setup) and rebuild(key)
    if why then
      failed[key] = true
      if manual or not warned[key .. why] then warned[key .. why] = true; ns.Say(L["SWAP_" .. why]:format(key)) end
    end
  end
  built = ns.best
  local changes = old and ns.ItemChanges(old, ns.best, FoilKeybindsDB.applied) or {}
  local say = manual and ns.Say or ns.Info
  for i = #changes, 1, -1 do if failed[changes[i].key] then table.remove(changes, i) end end -- no swap happened there
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
local function changeLine(c)
  local where = ("%s %s"):format(c.key, L["SLOT_" .. c.slot]) .. (c.pos and (" #" .. c.pos) or "")
  if c.kind == "renamed" then return L.REPAIR_RENAMED:format(where, c.old, c.new) end
  return L.REPAIR_REMOVED:format(where, c.old or "?")
end
local function showPopup(changes)
  local lines = {}
  for i, c in ipairs(changes) do lines[i] = changeLine(c) end
  ns.Popup(L.REPAIR_TITLE, table.concat(lines, "\n"), { { OKAY or "OK", nil, ns.T.fel }, { L.UNDO, ns.UndoRepair } })
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
  if InCombatLockdown() then ns.Say(L.IN_COMBAT); return true end -- popup stays open to try again
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
