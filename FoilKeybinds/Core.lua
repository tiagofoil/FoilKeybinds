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
-- Same order by itemID (Classic-era IDs; talented Healthstones above the plain one). Bags match by ID
-- first, so non-English clients work; the names above stay as a fallback for IDs not listed here.
ns.RANK_IDS = {
  HS = { 19013, 19012, 9421, 19011, 19010, 5510, 19009, 19008, 5509, 19007, 19006, 5511, 19005, 19004, 5512 },
  POT = { 13446, 3928, 1710, 929, 4596, 858, 118 },
  BAND = { 14530, 14529, 8545, 8544, 6451, 6450, 3531, 3530, 2581, 1251 },
  BOMB = { 16005, 15993, 10562, 10514, 4394, 4390, 4380, 4374, 4370, 4360 },
}
-- Shown with no item in the bags. ponytail: English names, so a non-English client gets a /use that fails until an item is in the bags.
ns.ITEM_DEFAULT = { HS = "Healthstone", POT = "Healing Potion", BAND = "Linen Bandage", BOMB = "Rough Copper Bomb" }

-- owned = bag contents itemID -> name ("" when not loaded), usable(id) -> bool (nil = all usable).
-- Returns category -> { id, name } for categories with something in the bags.
function ns.BestItems(owned, usable)
  local best, byName = {}, {}
  for id, n in pairs(owned) do byName[n] = id end
  local function ok(id) return id and owned[id] and (not usable or usable(id)) end
  for cat, list in pairs(ns.RANK_IDS) do
    for _, id in ipairs(list) do
      if ok(id) then best[cat] = { id = id, name = owned[id] ~= "" and owned[id] or ns.ITEM_DEFAULT[cat] }; break end
    end
    if not best[cat] then
      for _, n in ipairs(ns.RANKS[cat]) do
        if ok(byName[n]) then best[cat] = { id = byName[n], name = n }; break end
      end
    end
  end
  return best
end

-- New spell slot. Mouseover: kept from a replaced spell, on by default for harm/help when the slot was empty.
function ns.NewSlot(spellID, name, kind, old)
  local mo = kind == "harm" or kind == "help"
  if old and old.name then mo = old.mouseover or false end
  return { spellID = spellID, name = name, kind = kind, mouseover = mo }
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

-- Name of the macro Apply writes for a key. Key first: macro window and bars show ~4 chars.
local SHORT = { SPACE = "Spc", BUTTON3 = "M3", BUTTON4 = "M4", BUTTON5 = "M5" }
function ns.MacroName(key) return (SHORT[key] or key) .. " FK" end
function ns.OldMacroName(key) return "FKB " .. key end

-- Plan to move macros from old names to new ones. keys: list of keys; exists: set of macro
-- names in game; macros: backup.macros. Returns renames {from,to}, old names to delete, new backup map.
function ns.RenamePlan(keys, exists, macros)
  local renames, deletes, out = {}, {}, ns.Copy(macros or {})
  for _, key in ipairs(keys) do
    local old, new = ns.OldMacroName(key), ns.MacroName(key)
    if exists[old] and not exists[new] then renames[#renames + 1] = { from = old, to = new }
    elseif exists[old] and out[old] == false then deletes[#deletes + 1] = old end
    local keepOld = exists[old] and exists[new] and out[old] ~= false -- player's own macro stays
    if out[old] ~= nil and not keepOld then
      if out[new] == nil then out[new] = out[old] end
      out[old] = nil
    end
  end
  return renames, deletes, out
end

-- Light color for the macro preview: command words gold, [conditions] blue, the rest as is.
function ns.ColorMacro(text)
  local out = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    local cmd, rest = line:match("^([/#]%S+)(.*)$")
    rest = (rest or line):gsub("%[[^%]]*%]", "|cff7fb8ff%0|r")
    out[#out + 1] = (cmd and ("|cffffd100" .. cmd .. "|r") or "") .. rest
  end
  return table.concat(out, "\n")
end

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
    local pick, pickText
    for _, id in ipairs(ns.SLOTS) do
      local s = slots[id]
      if s and s.mouseover and s.name then
        s.mouseover = false
        local t = ns.MacroText(copy, best)
        s.mouseover = true
        if t ~= text and (not pickText or #t < #pickText) then pick, pickText = id, t end
      end
    end
    if not pick then
      local errSlot
      for _, id in ipairs(ns.SLOTS) do
        local s = slots[id]
        if s and s.name and (not errSlot or #s.name > #slots[errSlot].name) then errSlot = id end
      end
      return nil, #text, trimmed, errSlot
    end
    slots[pick].mouseover = false
    trimmed[#trimmed + 1] = pick
    text = pickText
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

-- Spellbooks list every rank; macros cast by name (highest known rank), so keep one entry
-- per name. list = { name, spellID, rank (number or nil), sub }. Higher rank wins; without
-- ranks the later entry wins (spellbooks list ranks in ascending order). Sorted by name.
function ns.DedupeSpells(list)
  local byName, out = {}, {}
  for _, s in ipairs(list) do
    local old = byName[s.name]
    if not old or not (old.rank and s.rank and old.rank > s.rank) then byName[s.name] = s end
  end
  for _, s in pairs(byName) do out[#out + 1] = s end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- What's Training catalog -> future spells. Keeps trainer/quest spells (no pet tomes, weapon
-- skills or pet abilities) with a name not in learned (name -> true). One entry per name:
-- level of the first rank, spellID of the highest rank (rank from subText, else level).
-- Returns { spellID, name, level, future = true }, sorted by level then name.
function ns.FutureFrom(catalog, learned)
  local byName, out = {}, {}
  for _, e in ipairs(catalog or {}) do
    if (e.kind == "trainer" or e.kind == "quest") and not e.petAbility and e.name and type(e.id) == "number"
      and not learned[e.name] then
      local r = tonumber(e.subText and e.subText:match("(%d+)")) or e.level
      local o = byName[e.name]
      if not o then byName[e.name] = { spellID = e.id, name = e.name, level = e.level, r = r, future = true }
      else
        if r > o.r then o.spellID, o.r = e.id, r end
        o.level = math.min(o.level, e.level)
      end
    end
  end
  for _, s in pairs(byName) do s.r = nil; out[#out + 1] = s end
  table.sort(out, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.name < b.name end)
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
-- Returns keys (key -> setup) and lost = list of { key, text } (macro parts not kept) or
-- { key, skipped = true } (whole macro left out).
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
          -- kept only as the item slot itself: no token, unknown token or conditions are lost
          local keep = line:find("{%u+}") and not line:find("%[")
          for tok in line:gmatch("{(%u+)}") do if not items[tok] then keep = false end end
          if not keep then lose(line) end
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
      keys[key] = setup
    end
  end
  return keys, lost
end

return ns
