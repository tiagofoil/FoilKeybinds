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

return ns
