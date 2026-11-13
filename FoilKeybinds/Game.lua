-- Thin game layer: turns core output into macros on the bar slot each key presses.
local _, ns = ...
local L = ns.L
local QUESTION = 134400 -- question mark icon; #showtooltip swaps it for the real spell

function ns.Say(msg) print("|cff93d35aFoil Keybinds:|r " .. msg) end

-- Binding command -> action slot (same native commands EllesmereUI bars use).
local BAR_BASE = { ACTIONBUTTON = 0, MULTIACTIONBAR3BUTTON = 24, MULTIACTIONBAR4BUTTON = 36,
  MULTIACTIONBAR2BUTTON = 48, MULTIACTIONBAR1BUTTON = 60, MULTIACTIONBAR5BUTTON = 144,
  MULTIACTIONBAR6BUTTON = 156, MULTIACTIONBAR7BUTTON = 168 }
local function slotOf(cmd)
  if not cmd then return end
  local bar, n = cmd:match("^(%u+%d*BUTTON)(%d+)$")
  if bar and BAR_BASE[bar] then return BAR_BASE[bar] + tonumber(n) end
end

local function upsertMacro(name, body)
  local i = GetMacroIndexByName(name)
  if i > 0 then EditMacro(i, name, nil, body); return true end
  local ok, err = pcall(CreateMacro, name, QUESTION, body, true)
  if not ok then ns.Say(L.CREATE_FAILED:format(name, tostring(err))) end
  return ok
end

function ns.Apply()
  if InCombatLockdown() then return ns.Say(L.IN_COMBAT) end
  local keys = FoilKeybindsDB.keys
  if not next(keys) then return ns.Say(L.NOTHING) end
  local done = 0
  for key, setup in pairs(keys) do if next(setup.slots) then -- clicked but empty keys are skipped
    local name = "FKB " .. key
    if upsertMacro(name, ns.MacroText(setup)) then
      local slot = slotOf(GetBindingAction(key))
      if slot then
        ClearCursor(); PickupMacro(name); PlaceAction(slot); ClearCursor()
      else -- ponytail: ticket 06 adds the empty-slot search on other bars
        SetBindingMacro(key, name)
        ns.Say(L.NO_SLOT:format(key))
      end
      done = done + 1
    end
  end end
  SaveBindings(GetCurrentBindingSet())
  ns.Say(L.DONE:format(done))
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
