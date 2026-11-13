-- Pure core: no WoW API. Loads in game (addon namespace) and in plain Lua 5.1 (returns ns).
local ns = select(2, ...) or {}

-- Most specific first: WoW takes the first matching clause, so Alt+Shift must come
-- before the plain Alt and Shift clauses. Ctrl+Shift / Ctrl+Alt hit the Ctrl slot (out of scope).
ns.SLOTS = { "altshift", "ctrl", "shift", "alt", "normal" }
local COND = { altshift = "mod:alt,mod:shift", ctrl = "mod:ctrl", shift = "mod:shift", alt = "mod:alt" }

-- setup = { slots = { normal = { spellID, name, mouseover, kind }, ... }, targetEnemy, petAttack }
function ns.MacroText(setup)
  local lines, parts = { "#showtooltip" }, {}
  if setup.targetEnemy then lines[#lines + 1] = "/targetenemy [noharm][dead]" end
  if setup.petAttack then lines[#lines + 1] = "/petattack [harm,nodead]" end
  for _, id in ipairs(ns.SLOTS) do
    local s = setup.slots[id]
    if s and s.name then
      local cond = COND[id]
      local mo = s.mouseover and (s.kind == "harm" or s.kind == "help")
      local c
      if mo then
        c = "[" .. (cond and cond .. "," or "") .. "@mouseover," .. s.kind .. ",nodead][" .. (cond or "") .. "] "
      elseif cond then c = "[" .. cond .. "] "
      else c = "" end
      parts[#parts + 1] = c .. s.name
    end
  end
  lines[#lines + 1] = "/cast " .. table.concat(parts, "; ")
  return table.concat(lines, "\n")
end

-- Binding command -> first action slot - 1 (native commands EllesmereUI bars use too).
ns.BAR_BASE = { ACTIONBUTTON = 0, MULTIACTIONBAR3BUTTON = 24, MULTIACTIONBAR4BUTTON = 36,
  MULTIACTIONBAR2BUTTON = 48, MULTIACTIONBAR1BUTTON = 60, MULTIACTIONBAR5BUTTON = 144,
  MULTIACTIONBAR6BUTTON = 156, MULTIACTIONBAR7BUTTON = 168 }
local BAR_ORDER = { "ACTIONBUTTON", "MULTIACTIONBAR1BUTTON", "MULTIACTIONBAR2BUTTON", "MULTIACTIONBAR3BUTTON",
  "MULTIACTIONBAR4BUTTON", "MULTIACTIONBAR5BUTTON", "MULTIACTIONBAR6BUTTON", "MULTIACTIONBAR7BUTTON" }

function ns.SlotOf(cmd)
  if not cmd then return end
  local bar, n = cmd:match("^(%u+%d*BUTTON)(%d+)$")
  if bar and ns.BAR_BASE[bar] then return ns.BAR_BASE[bar] + tonumber(n) end
end

function ns.CommandOf(slot)
  for bar, base in pairs(ns.BAR_BASE) do
    if slot > base and slot <= base + 12 then return bar .. (slot - base) end
  end
end

-- First slot, bar by bar, for which used(slot, command) is false. Returns slot, command.
function ns.FirstEmptySlot(used)
  for _, bar in ipairs(BAR_ORDER) do
    for n = 1, 12 do
      local slot, cmd = ns.BAR_BASE[bar] + n, bar .. n
      if not used(slot, cmd) then return slot, cmd end
    end
  end
end

return ns
