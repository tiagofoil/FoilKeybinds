-- Pure core: no WoW API. Loads in game (addon namespace) and in plain Lua 5.1 (returns ns).
local ns = select(2, ...) or {}

-- Most specific first: WoW takes the first matching clause, so Alt+Shift must come
-- before the plain Alt and Shift clauses. Ctrl+Shift / Ctrl+Alt hit the Ctrl slot (out of scope).
ns.SLOTS = { "altshift", "ctrl", "shift", "alt", "normal" }
-- Display order of the Keys tab columns (the plain press first). Macro order stays ns.SLOTS.
ns.COLUMNS = { "normal", "shift", "ctrl", "alt", "altshift" }
-- Cheat sheet column for the held modifiers, in the order the macro checks its clauses
-- (ns.SLOTS): Alt+Shift first (so Ctrl+Alt+Shift fires it too), then Ctrl with anything, Shift, Alt.
function ns.ModColumn(shift, alt, ctrl)
  if alt and shift then return "altshift" end
  if ctrl then return "ctrl" end
  if shift then return "shift" end
  if alt then return "alt" end
  return "normal"
end
local COND = { altshift = "mod:alt,mod:shift", ctrl = "mod:ctrl", shift = "mod:shift", alt = "mod:alt" }

-- Items, best first: the first one in the bags (and usable) wins. Same lists as GrimorioSetup.
ns.ITEMS = { "HS", "POT", "BAND", "BOMB" }
ns.RANKS = {
  HS = { "Major Healthstone", "Greater Healthstone", "Healthstone", "Lesser Healthstone", "Minor Healthstone" },
  POT = { "Major Healing Potion", "Superior Healing Potion", "Greater Healing Potion", "Healing Potion",
    "Lesser Healing Potion", "Minor Healing Potion", "Major Discolored Healing Potion", "Superior Discolored Healing Potion",
    "Greater Discolored Healing Potion", "Discolored Healing Potion", "Lesser Discolored Healing Potion",
    "Minor Discolored Healing Potion" },
  BAND = { "Dense Runecloth Bandage", "Crystal Infused Bandage", "Heavy Runecloth Bandage", "Runecloth Bandage",
    "Heavy Mageweave Bandage", "Mageweave Bandage", "Heavy Silk Bandage", "Silk Bandage", "Heavy Wool Bandage",
    "Wool Bandage", "Heavy Linen Bandage", "Linen Bandage" },
  BOMB = { "Dark Iron Bomb", "EZ-Thro Dark Bomb", "Thorium Grenade", "EZ-Thro Thorium Grenade", "Hi-Explosive Bomb",
    "Mithril Frag Bomb", "Tru-Trigger Frag Bomb", "Big Iron Bomb", "SAF-T Bomb", "Iron Grenade", "Big Bronze Bomb",
    "Small Bronze Bomb", "SAF-T Bronze Bomb", "Large Copper Bomb", "EZ-Thro Copper Bomb XL", "Rough Copper Bomb",
    "SAF-T Copper Bomb" },
}
-- Same order by itemID, checked on wowhead.com/forever (2026-11-18). Bags match by ID first, so
-- non-English clients work; the names above stay as a fallback for IDs not listed here.
-- HS: on Forever each base stone heals like its best talented one, the middle one is lower.
-- POT: plain first; a Discolored potion deals 75% of its heal back over time.
-- BOMB: each Classic bomb (needs Engineering) next to its Forever copy anyone can use (EZ-Thro, SAF-T, Tru-Trigger).
ns.RANK_IDS = {
  HS = { 19013, 9421, 19012, 19011, 5510, 19010, 19009, 5509, 19008, 19007, 5511, 19006, 19005, 5512, 19004 },
  POT = { 13446, 3928, 1710, 929, 858, 118, 241650, 247242, 247241, 247240, 247239, 4596 },
  BAND = { 232433, 23684, 14530, 14529, 8545, 8544, 6451, 6450, 3531, 3530, 2581, 1251 },
  BOMB = { 16005, 260817, 15993, 260816, 10562, 10514, 260809, 4394, 260805, 4390, 4380, 4374, 260797, 4370, 260795,
    4360, 260793 },
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

-- With an item (or a sequence) on the key, /use, /castsequence and /cast all run on one press,
-- so every clause gets a condition that excludes the other slots (and normal loses its bare fallback).
local EXCL = { altshift = "mod:alt,mod:shift", ctrl = "mod:ctrl,nomod:alt", shift = "mod:shift,nomod:alt,nomod:ctrl",
  alt = "mod:alt,nomod:shift,nomod:ctrl", normal = "nomod" }

-- Pet command slots: { pet = "follow" } -> "/petfollow [cond]". moveto always goes to the cursor.
ns.PET_CMDS = { "follow", "moveto", "stay", "attack", "passive", "defensive" }
-- Pet special ability slot ({ petSpecial = true }): one /cast clause per pet, by class.
-- ponytail: no Felguard entry, its Intercept is not in Classic Era or retail; add a pair if a version has it.
ns.PET_SPECIAL = {
  WARLOCK = { { "Felhunter", "Spell Lock" }, { "Succubus/Incubus", "Seduction" }, { "Voidwalker", "Sacrifice" } },
}

-- One /castsequence line: s = { seq = { { spellID, name, kind }, ... }, reset = { target, combat, secs } }.
-- ponytail: syntax with conditions and reset= unverified on Forever, check in game.
local function seqLine(s, cond, compact)
  local r, list = {}, {}
  local reset = s.reset or {}
  if reset.target then r[#r + 1] = "target" end
  if reset.combat then r[#r + 1] = "combat" end
  if reset.secs then r[#r + 1] = tostring(reset.secs) end
  for i, x in ipairs(s.seq) do list[i] = x.name end
  local head = "/castsequence [" .. cond .. "]" .. (compact and "" or " ")
  if #r > 0 then head = head .. "reset=" .. table.concat(r, "/") .. " " end
  return head .. table.concat(list, compact and "," or ", ")
end

-- setup = { slots = { normal = { spellID, name, mouseover, kind } or { item = "HS" } or a sequence, ... }, targetEnemy, petAttack }
-- best = BestItems() output; an item missing from the bags falls back to its default name.
-- class picks the PET_SPECIAL table (default ns.playerClass, set in game).
function ns.MacroText(setup, best, class)
  best = best or {}
  local special = ns.PET_SPECIAL[class or ns.playerClass] or {}
  local lines, casts, uses, pets, seqs = { "#showtooltip" }, {}, {}, {}, {}
  if setup.targetEnemy then lines[#lines + 1] = "/targetenemy [noharm][dead]" end
  if setup.petAttack then lines[#lines + 1] = "/petattack [harm,nodead]" end
  local hasItem = false
  for _, s in pairs(setup.slots) do if s.item or s.pet or s.petSpecial or s.seq then hasItem = true end end
  local conds = hasItem and EXCL or COND
  local sl, sep, sp = setup.slots, "; ", " "
  if setup.compact then sep, sp = ";", "" end
  for _, id in ipairs(ns.SLOTS) do
    local s = setup.slots[id]
    local cond = conds[id]
    if setup.compact and hasItem and cond then -- drop exclusions no filled slot needs
      if not sl.ctrl then cond = cond:gsub(",nomod:ctrl", "") end
      if not sl.altshift then cond = cond:gsub(",nomod:shift", ""):gsub(",nomod:alt", "") end
    end
    if s and s.seq then
      seqs[#seqs + 1] = seqLine(s, cond, setup.compact)
    elseif s and s.pet then
      pets[#pets + 1] = "/pet" .. s.pet .. " [" .. cond .. (s.pet == "moveto" and ",@cursor" or "") .. "]"
    elseif s and s.petSpecial then
      for _, p in ipairs(special) do casts[#casts + 1] = "[" .. cond .. ",pet:" .. p[1] .. "]" .. sp .. p[2] end
    elseif s and s.item then
      local b = best[s.item]
      uses[#uses + 1] = "[" .. cond .. "]" .. sp .. (b and ("item:" .. b.id) or ns.ITEM_DEFAULT[s.item])
    elseif s and s.name then
      local mo = s.mouseover and (s.kind == "harm" or s.kind == "help")
      local c
      if mo then
        c = "[" .. (cond and cond .. "," or "") .. "@mouseover," .. s.kind .. ",nodead][" .. (cond or "") .. "]" .. sp
      elseif cond then c = "[" .. cond .. "]" .. sp
      else c = "" end
      casts[#casts + 1] = c .. s.name
    end
  end
  for _, l in ipairs(pets) do lines[#lines + 1] = l end
  if #uses > 0 then lines[#lines + 1] = "/use " .. table.concat(uses, sep) end
  for _, l in ipairs(seqs) do lines[#lines + 1] = l end
  if #casts > 0 or (#uses == 0 and #pets == 0 and #seqs == 0) then lines[#lines + 1] = "/cast " .. table.concat(casts, sep) end
  return table.concat(lines, "\n")
end

ns.MAX = 255

-- Name of the macro Apply writes for a key. Key first: macro window and bars show ~4 chars.
local SHORT = { SPACE = "Spc", BUTTON3 = "M3", BUTTON4 = "M4", BUTTON5 = "M5" }
function ns.ShortKey(key) return SHORT[key] or key end
function ns.MacroName(key) return (SHORT[key] or key) .. " FK" end
function ns.OldMacroName(key) return "FKB " .. key end

-- The game hands macro bodies back with its own line endings and trailing whitespace,
-- so a plain ~= reports a change that is not there.
local function norm(s) return ((s or ""):gsub("\r\n?", "\n"):gsub("[ \t]+\n", "\n"):gsub("%s+$", "")) end
function ns.SameMacro(a, b) return norm(a) == norm(b) end

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

-- Macro text that fits in 255 chars. Over the limit: first the compact form (no spaces
-- after ";" and "]", exclusions only for filled slots; ponytail: spacing trick unverified in game), then drop mouseover from the slot whose
-- removal saves the most chars (ties: SLOTS order), repeat until it fits.
-- Returns text, length, trimmed (slot ids that lost mouseover, apply them to saved data).
-- Still over with no mouseover left: returns nil, length, trimmed, errSlot, where errSlot
-- is the slot with the longest text (the one most worth changing; item slots never are).
-- A sequence counts with its whole spell list.
local function textLen(s)
  if s.seq then local n = 0; for _, x in ipairs(s.seq) do n = n + #x.name + 2 end; return n end
  return s.name and #s.name
end
function ns.FitMacro(setup, best, class)
  local slots = {}
  for id, s in pairs(setup.slots) do slots[id] = ns.Copy(s) end
  local copy = { slots = slots, targetEnemy = setup.targetEnemy, petAttack = setup.petAttack }
  local trimmed, text = {}, ns.MacroText(copy, best, class)
  if #text > ns.MAX then copy.compact = true; text = ns.MacroText(copy, best, class) end
  while #text > ns.MAX do
    local pick, pickText
    for _, id in ipairs(ns.SLOTS) do
      local s = slots[id]
      if s and s.mouseover and s.name then
        s.mouseover = false
        local t = ns.MacroText(copy, best, class)
        s.mouseover = true
        if t ~= text and (not pickText or #t < #pickText) then pick, pickText = id, t end
      end
    end
    if not pick then
      local errSlot
      for _, id in ipairs(ns.SLOTS) do
        local n = slots[id] and textLen(slots[id])
        if n and (not errSlot or n > textLen(slots[errSlot])) then errSlot = id end
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

-- Action slot -> binding command (inverse of SlotOf), nil for slots off the known bars.
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

-- Account-wide settings (FoilKeybindsAccount.settings). Numbers have a range { min, max, step },
-- strings a list of choices. Defaults match the look before settings existed.
ns.SETTING_DEFAULTS = {
  scale = 1, textSize = "normal", keyIcon = 26,
  cheatLayout = "rows", cheatScale = 1, cheatIcon = 24, cheatBg = 100, cheatBorder = true,
  cheatLabels = true, cheatHideEmpty = false, cheatHighlight = true, cheatLock = false,
  compartment = true, chat = true,
}
ns.SETTING_RANGES = {
  scale = { 0.7, 1.5, 0.05 }, keyIcon = { 18, 34, 2 },
  cheatScale = { 0.6, 1.6, 0.05 }, cheatIcon = { 16, 40, 2 }, cheatBg = { 0, 100, 5 },
}
ns.SETTING_CHOICES = { textSize = { "small", "normal", "large" }, cheatLayout = { "rows", "cols", "keyboard" } }

-- Clamps a number into r = { min, max, step } and snaps it to the step without float noise
-- (1.1 stays 1.1, never 1.1000000001).
function ns.Snap(v, r)
  local lo, hi, step = r[1], r[2], r[3]
  v = lo + math.floor((v - lo) / step + 0.5) * step
  return tonumber(("%.4f"):format(math.max(lo, math.min(hi, v))))
end

-- One setting checked against its default: wrong type or unknown choice gives the default.
function ns.CheckSetting(key, v)
  local d = ns.SETTING_DEFAULTS[key]
  if type(v) ~= type(d) then return d end
  if ns.SETTING_RANGES[key] then return ns.Snap(v, ns.SETTING_RANGES[key]) end
  if ns.SETTING_CHOICES[key] then
    for _, c in ipairs(ns.SETTING_CHOICES[key]) do if c == v then return v end end
    return d
  end
  return v
end

-- New table with every known key: saved values kept (checked), new keys get defaults, unknown keys dropped.
function ns.MergeSettings(saved)
  local out = {}
  for k in pairs(ns.SETTING_DEFAULTS) do out[k] = ns.CheckSetting(k, (saved or {})[k]) end
  return out
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
-- level of the first rank, spellID and icon of the highest rank (rank from subText, else level).
-- Returns { spellID, name, level, icon, future = true }, sorted by level then name.
function ns.FutureFrom(catalog, learned)
  local byName, out = {}, {}
  for _, e in ipairs(catalog or {}) do
    if (e.kind == "trainer" or e.kind == "quest") and not e.petAbility and e.name and type(e.id) == "number"
      and not learned[e.name] then
      local r = tonumber(e.subText and e.subText:match("(%d+)")) or e.level
      local o = byName[e.name]
      if not o then byName[e.name] = { spellID = e.id, name = e.name, level = e.level, icon = e.icon, r = r, future = true }
      else
        if r > o.r then o.spellID, o.icon, o.r = e.id, e.icon, r end
        o.level = math.min(o.level, e.level)
      end
    end
  end
  for _, s in pairs(byName) do s.r = nil; out[#out + 1] = s end
  table.sort(out, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.name < b.name end)
  return out
end

-- keys = key -> setup; lookup(spellID) -> current name, false (spell is gone) or nil (not loaded
-- yet: left as it is). byName(name) -> spellID or nil, fills slots stored without an ID (silent).
-- Returns a repaired copy and a change list { key, slot, kind = "renamed"|"removed", old, new, pos },
-- pos = place in a sequence. A sequence left with one spell becomes a plain slot, with none it is cleared.
-- Item and pet slots are never touched.
function ns.Repair(keys, lookup, byName)
  local out, changes = ns.Copy(keys), {}
  local function fix(key, slot, s, pos) -- false when the spell is gone
    if not s.spellID and byName then s.spellID = byName(s.name) end
    if not s.spellID then return true end
    local now = lookup(s.spellID)
    if now == false then
      changes[#changes + 1] = { key = key, slot = slot, kind = "removed", old = s.name, pos = pos }
      return false
    end
    if now and now ~= s.name then
      changes[#changes + 1] = { key = key, slot = slot, kind = "renamed", old = s.name, new = now, pos = pos }
      s.name = now
    end
    return true
  end
  for key, setup in pairs(out) do
    for _, id in ipairs(ns.SLOTS) do
      local s = setup.slots and setup.slots[id]
      if s and s.seq then
        local kept = {}
        for i, x in ipairs(s.seq) do if fix(key, id, x, i) then kept[#kept + 1] = x end end
        if #kept == 0 then setup.slots[id] = nil
        elseif #kept == 1 then setup.slots[id] = ns.Unseq(kept[1])
        else s.seq = kept end
      elseif s and s.name and not fix(key, id, s) then
        setup.slots[id] = nil
      end
    end
  end
  return out, changes
end

-- Sequence spell back to a plain slot (one spell left), mouseover off.
function ns.Unseq(x) return { spellID = x.spellID, name = x.name, kind = x.kind, mouseover = false } end

-- Sequence edits. Each returns a new slot value and never changes its input (the caller keeps it for undo).
-- entry = { spellID, name, kind }. A plain spell plus one entry becomes a sequence, reset on target and combat.
ns.MAXSEQ = 9
function ns.AddStep(s, entry)
  if not (s.seq or s.name) or (s.seq and #s.seq >= ns.MAXSEQ) then return ns.Copy(s) end -- item, pet, full
  if s.seq then
    local new = ns.Copy(s); new.seq[#new.seq + 1] = ns.Copy(entry); return new
  end
  return { seq = { { spellID = s.spellID, name = s.name, kind = s.kind }, ns.Copy(entry) }, reset = { target = true, combat = true } }
end
-- Swaps step i with step i + delta (delta -1 = up, 1 = down) when both exist.
function ns.MoveStep(s, i, delta)
  local new, j = ns.Copy(s), i + delta
  if new.seq[i] and new.seq[j] then new.seq[i], new.seq[j] = new.seq[j], new.seq[i] end
  return new
end
-- Removes step i; one step left gives the plain spell back.
function ns.RemoveStep(s, i)
  local new = ns.Copy(s)
  table.remove(new.seq, i)
  return #new.seq == 1 and ns.Unseq(new.seq[1]) or new
end

-- A stored spell counts as known when its ID is known or any spell with its name is learned
-- (picker stores the highest rank; the macro casts by name, so the learned rank fires).
-- knownID(spellID) -> bool, learned = name -> true.
function ns.Known(spellID, name, knownID, learned)
  return (spellID ~= nil and knownID(spellID)) or (name ~= nil and learned[name]) or false
end

-- Item swap chat lines: one entry per applied key and item slot whose best item changed.
-- old/new = BestItems() output. Returns { key, slot, from, to } (names, nil = none), sorted.
function ns.ItemChanges(old, new, applied)
  local out = {}
  for key, setup in pairs(applied or {}) do
    for _, id in ipairs(ns.SLOTS) do
      local s = setup.slots[id]
      local a, b = s and s.item and old[s.item], s and s.item and new[s.item]
      if s and s.item and (a and a.id) ~= (b and b.id) then
        out[#out + 1] = { key = key, slot = id, from = a and a.name, to = b and b.name }
      end
    end
  end
  table.sort(out, function(x, y) if x.key ~= y.key then return x.key < y.key end return x.slot < y.slot end)
  return out
end

-- Master switch start state: a saved value wins; first time, ON only for a character that
-- already has applied keys (an existing setup keeps working), OFF on a fresh install.
function ns.ManageStart(saved, applied)
  if saved ~= nil then return saved end
  return applied ~= nil and next(applied) ~= nil
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
