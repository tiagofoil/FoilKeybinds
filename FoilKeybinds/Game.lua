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
  for key, setup in pairs(keys) do
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
  end
  SaveBindings(GetCurrentBindingSet())
  ns.Say(L.DONE:format(done))
end
