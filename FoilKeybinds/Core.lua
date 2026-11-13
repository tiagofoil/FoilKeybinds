-- Pure core: no WoW API. Loads in game (addon namespace) and in plain Lua 5.1 (returns ns).
local ns = select(2, ...) or {}

-- Most specific first: WoW takes the first matching clause, so Alt+Shift must come
-- before the plain Alt and Shift clauses. Ctrl+Shift / Ctrl+Alt hit the Ctrl slot (out of scope).
ns.SLOTS = { "altshift", "ctrl", "shift", "alt", "normal" }
local COND = { altshift = "mod:alt,mod:shift", ctrl = "mod:ctrl", shift = "mod:shift", alt = "mod:alt" }

-- Items, best first: the first one in the bags (and usable) wins. Same lists as GrimorioSetup.
ns.ITEMS = { "HS", "POT", "BAND", "BOMB" }
ns.RANKS = {
  HS = { "Major Healthstone", "Greater Healthstone", "Healthstone", "Lesser Healthstone", "Minor Healthstone" },
  POT = { "Major Healing Potion", "Superior Healing Potion", "Greater Healing Potion", "Healing Potion",
    "Discolored Healing Potion", "Lesser Healing Potion", "Minor Healing Potion" },
  BAND = { "Heavy Runecloth Bandage", "Runecloth Bandage", "Heavy Mageweave Bandage", "Mageweave Bandage",
    "Heavy Silk Bandage", "Silk Bandage", "Heavy Wool Bandage", "Wool Bandage", "Heavy Linen Bandage", "Linen Bandage" },
  BOMB = { "Dark Iron Bomb", "Thorium Grenade", "Hi-Explosive Bomb", "Mithril Frag Bomb", "Big Iron Bomb", "Iron Grenade",
    "Big Bronze Bomb", "Small Bronze Bomb", "Large Copper Bomb", "Rough Copper Bomb" },
}
ns.ITEM_DEFAULT = { HS = "Healthstone", POT = "Healing Potion", BAND = "Linen Bandage", BOMB = "Rough Copper Bomb" }

-- owned = bag contents name -> itemID, usable(id) -> bool (nil = all usable).
-- Returns category -> { id, name } for categories with something in the bags.
function ns.BestItems(owned, usable)
  local best = {}
  for cat, list in pairs(ns.RANKS) do
    for _, n in ipairs(list) do
      local id = owned[n]
      if id and (not usable or usable(id)) then best[cat] = { id = id, name = n }; break end
    end
  end
  return best
end

-- With an item on the key, /use and /cast both run on one press, so every clause gets a
-- condition that excludes the other slots (and normal loses its bare fallback).
local EXCL = { altshift = "mod:alt,mod:shift", ctrl = "mod:ctrl,nomod:alt", shift = "mod:shift,nomod:alt,nomod:ctrl",
  alt = "mod:alt,nomod:shift,nomod:ctrl", normal = "nomod" }

-- setup = { slots = { normal = { spellID, name, mouseover, kind } or { item = "HS" }, ... }, targetEnemy, petAttack }
-- best = BestItems() output; an item missing from the bags falls back to its default name.
function ns.MacroText(setup, best)
  best = best or {}
  local lines, casts, uses = { "#showtooltip" }, {}, {}
  if setup.targetEnemy then lines[#lines + 1] = "/targetenemy [noharm][dead]" end
  if setup.petAttack then lines[#lines + 1] = "/petattack [harm,nodead]" end
  local hasItem = false
  for _, s in pairs(setup.slots) do if s.item then hasItem = true end end
  local conds = hasItem and EXCL or COND
  for _, id in ipairs(ns.SLOTS) do
    local s = setup.slots[id]
    local cond = conds[id]
    if s and s.item then
      local b = best[s.item]
      uses[#uses + 1] = "[" .. cond .. "] " .. (b and ("item:" .. b.id) or ns.ITEM_DEFAULT[s.item])
    elseif s and s.name then
      local mo = s.mouseover and (s.kind == "harm" or s.kind == "help")
      local c
      if mo then
        c = "[" .. (cond and cond .. "," or "") .. "@mouseover," .. s.kind .. ",nodead][" .. (cond or "") .. "] "
      elseif cond then c = "[" .. cond .. "] "
      else c = "" end
      casts[#casts + 1] = c .. s.name
    end
  end
  if #uses > 0 then lines[#lines + 1] = "/use " .. table.concat(uses, "; ") end
  if #casts > 0 or #uses == 0 then lines[#lines + 1] = "/cast " .. table.concat(casts, "; ") end
  return table.concat(lines, "\n")
end

ns.MAX = 255

-- Macro text that fits in 255 chars. Over the limit: drop mouseover from the slot whose
-- removal saves the most chars (ties: SLOTS order), repeat until it fits.
-- Returns text, length, trimmed (slot ids that lost mouseover, apply them to saved data).
-- Still over with no mouseover left: returns nil, length, trimmed, errSlot, where errSlot
-- is the slot with the longest spell name (the one most worth changing; item slots never are).
function ns.FitMacro(setup, best)
  local slots = {}
  for id, s in pairs(setup.slots) do slots[id] = { name = s.name, item = s.item, mouseover = s.mouseover, kind = s.kind } end
  local copy = { slots = slots, targetEnemy = setup.targetEnemy, petAttack = setup.petAttack }
  local trimmed, text = {}, ns.MacroText(copy, best)
  while #text > ns.MAX do
    local best, bestText
    for _, id in ipairs(ns.SLOTS) do
      local s = slots[id]
      if s and s.mouseover and s.name then
        s.mouseover = false
        local t = ns.MacroText(copy, best)
        s.mouseover = true
        if t ~= text and (not bestText or #t < #bestText) then best, bestText = id, t end
      end
    end
    if not best then
      local errSlot
      for _, id in ipairs(ns.SLOTS) do
        local s = slots[id]
        if s and s.name and (not errSlot or #s.name > #slots[errSlot].name) then errSlot = id end
      end
      return nil, #text, trimmed, errSlot
    end
    slots[best].mouseover = false
    trimmed[#trimmed + 1] = best
    text = bestText
  end
  return text, #text, trimmed
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

-- Deep copy of plain tables (setups, snapshots).
function ns.Copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = ns.Copy(v) end
  return c
end

-- index = class -> { "Name-Realm" = keys }. Other characters of that class, sorted, without me.
function ns.SameClass(index, class, me)
  local out = {}
  for name in pairs(index[class] or {}) do if name ~= me then out[#out + 1] = name end end
  table.sort(out)
  return out
end

-- keys = key -> setup; lookup(spellID) -> current name or nil (nil = spell is gone).
-- Returns a repaired copy and a change list { key, slot, kind = "renamed"|"removed", old, new }.
-- Item slots are never touched.
function ns.Repair(keys, lookup)
  local out, changes = ns.Copy(keys), {}
  for key, setup in pairs(out) do
    for _, id in ipairs(ns.SLOTS) do
      local s = setup.slots and setup.slots[id]
      if s and s.spellID then
        local now = lookup(s.spellID)
        if not now then
          setup.slots[id] = nil
          changes[#changes + 1] = { key = key, slot = id, kind = "removed", old = s.name }
        elseif now ~= s.name then
          changes[#changes + 1] = { key = key, slot = id, kind = "renamed", old = s.name, new = now }
          s.name = now
        end
      end
    end
  end
  return out, changes
end

-- GrimorioSetup import. data = GrimorioSetupData; lookup(name) -> spellID, kind (both may be nil).
-- Returns keys (key -> setup) and lost = list of { key, text } (macro parts not kept),
-- { key, skipped = true } (whole macro left out) or { key, jump = true } (Space with no normal slot).
local MODSLOT = { [""] = "normal", Shift = "shift", Alt = "alt", ["Alt+Shift"] = "altshift" }
function ns.ImportGrimorio(data, lookup)
  local keys, lost = {}, {}
  for _, m in ipairs(data) do
    local key
    for _, k in ipairs(m.keys) do
      local base = k:match("[^-]+$")
      if key and base ~= key then key = false; break end
      key = key == nil and base or key
    end
    local pet = false
    for line in m.body:gmatch("[^\n]+") do if line:find("^/pet") and not line:find("^/petattack") then pet = true end end
    if not key or pet then lost[#lost + 1] = { key = m.name, skipped = true }
    else
      local setup, byName, items = { slots = {} }, {}, {}
      for _, s in ipairs(m.spells) do
        local slot = MODSLOT[s.mod]
        if s.item then setup.slots[slot] = { item = s.item }; items[s.item] = true
        else
          local id, kind = lookup(s.name)
          setup.slots[slot] = { spellID = id, name = s.name, kind = kind or "other", mouseover = false }
          byName[s.name] = setup.slots[slot]
        end
      end
      local function lose(t) lost[#lost + 1] = { key = key, text = t } end
      for line in m.body:gmatch("[^\n]+") do
        if line:find("^#showtooltip") then -- same tooltip either way
        elseif line:find("^/targetenemy") then setup.targetEnemy = true
        elseif line:find("^/petattack") then setup.petAttack = true
        elseif line:find("^/use") then
          for tok in line:gmatch("{(%u+)}") do if not items[tok] then lose(line); break end end
        elseif line:find("^/cast") then
          for seg in line:sub(6):gmatch("[^;]+") do
            seg = seg:match("^%s*(.-)%s*$")
            local name = seg:match("%]%s*([^%]]+)$") or seg
            local bang = name:sub(1, 1) == "!"
            if bang then name = name:sub(2) end
            local s = byName[name]
            if not s and not seg:find("%[") and not setup.slots.normal then -- bare fallback, e.g. R Shadow Bolt
              local id, kind = lookup(name)
              s = { spellID = id, name = name, kind = kind or "other", mouseover = false }
              setup.slots.normal, byName[name] = s, s
            end
            if not s or bang or seg:find("@cursor") or seg:find("pet:") then lose(seg) end
            if s and seg:find("@mouseover") then s.mouseover, s.kind = true, seg:find(",help") and "help" or "harm" end
          end
        else lose(line) end
      end
      if key == "SPACE" and not setup.slots.normal then lost[#lost + 1] = { key = key, jump = true } end
      keys[key] = setup
    end
  end
  return keys, lost
end

return ns
