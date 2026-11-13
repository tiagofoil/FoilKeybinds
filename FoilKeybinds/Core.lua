-- Pure core: no WoW API. Loads in game (addon namespace) and in plain Lua 5.1 (returns ns).
local ns = select(2, ...) or {}

-- setup = { normal = "Spell Name" } -> macro body text.
function ns.MacroText(setup)
  return "#showtooltip\n/cast " .. setup.normal
end

return ns
