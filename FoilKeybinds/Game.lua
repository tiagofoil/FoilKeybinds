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

function ns.Apply()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  local keys = FoilKeybindsDB.keys
  if not next(keys) then return ns.Say(L.NOTHING) end
  FoilKeybindsDB.backup = FoilKeybindsDB.backup or { binds = {}, slots = {}, macros = {} }
  local b = FoilKeybindsDB.backup
  local done = 0
  for key, setup in pairs(keys) do if next(setup.slots) then -- clicked but empty keys are skipped
    local name = "FKB " .. key
    local text, n, trimmed = ns.FitMacro(setup)
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
      done = done + 1
    end
  end end
  SaveBindings(GetCurrentBindingSet())
  ns.Say(L.DONE:format(done))
end

function ns.Undo()
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
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellID) end
  if GetSpellTexture then return GetSpellTexture(spellID) end
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
