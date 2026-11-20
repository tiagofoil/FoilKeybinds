-- Builds tests/trainer_fixture.lua (test only, never packaged) from the What's Training Forever data.
-- Run from the repo root: luajit tools/make_trainer_fixture.lua [AddOns folder]
-- Per class: spell ID -> learn level (trainer, or the lowest class quest level), granted spells (a trainer
-- rank requires them but no trainer or quest teaches them: starting spells like Shadow Bolt, or spells that
-- come with another one like Rip with Cat Form) with the lowest level of a rank that needs them (an upper
-- bound for their learn level), and the rank groups What's Training lists (overriddenGroups).
-- Talent spells are not here.
local dir = (arg[1] or "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns") .. "/WhatsTraining/Classes/Camelot/"
local CLASSES = { "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }

local classes = {}
local wt = { forClass = function(c) classes[c] = classes[c] or {}; return classes[c] end }
local function load(file) assert(loadfile(dir .. file .. ".lua"))(nil, wt) end
for _, c in ipairs(CLASSES) do load(c) end
load("QuestSpells")
local copyright = assert(io.open(dir .. "../../LICENSE")):read("*a"):match("(Copyright[^%c]*)")

local out = { "-- Forever trainer spells per class: spell ID -> learn level, granted spells -> highest possible level, rank groups.",
  "-- Built by tools/make_trainer_fixture.lua from What's Training (Classes/Camelot), MIT License,",
  "-- " .. copyright .. " the What's Training authors. Their full license text is in WhatsTraining/LICENSE.",
  "-- Test only: never packaged. Do not edit by hand, run the tool again.", "return {" }
for _, c in ipairs(CLASSES) do
  local CLASS = c:upper()
  local data, levels, talent, granted = classes[CLASS], {}, {}, {}
  for level, list in pairs(data.spellsByLevel) do
    for _, s in ipairs(list) do
      levels[s.id], s.level = level, level
      if s.requiredTalentId then talent[s.requiredTalentId] = true end
    end
  end
  for id, entries in pairs(wt.QuestSpells[CLASS] or {}) do
    local min
    for _, e in ipairs(entries) do min = math.min(min or e.level, e.level) end
    levels[id] = levels[id] or min
  end
  for _, list in pairs(data.spellsByLevel) do
    for _, s in ipairs(list) do
      for _, r in ipairs(s.requiredIds or {}) do
        if not levels[r] and not talent[r] then granted[r] = math.min(granted[r] or s.level, s.level) end
      end
    end
  end
  local ids, gids = {}, {}
  for id in pairs(levels) do ids[#ids + 1] = id end
  for id in pairs(granted) do gids[#gids + 1] = id end
  table.sort(ids); table.sort(gids)
  out[#out + 1] = "  " .. CLASS .. " = {"
  out[#out + 1] = "    levels = {"
  for i = 1, #ids, 8 do
    local row = {}
    for j = i, math.min(i + 7, #ids) do row[#row + 1] = ("[%d] = %d,"):format(ids[j], levels[ids[j]]) end
    out[#out + 1] = "      " .. table.concat(row, " ")
  end
  out[#out + 1] = "    },"
  local g = {}
  for i, id in ipairs(gids) do g[i] = ("[%d] = %d"):format(id, granted[id]) end
  out[#out + 1] = "    granted = { " .. table.concat(g, ", ") .. (#g > 0 and " }," or "},")
  out[#out + 1] = "    ranks = {"
  for _, g in ipairs(data.overriddenGroups or {}) do out[#out + 1] = "      { " .. table.concat(g, ", ") .. " }," end
  out[#out + 1] = "    },"
  out[#out + 1] = "  },"
end
out[#out + 1] = "}"
local f = assert(io.open("tests/trainer_fixture.lua", "w"))
f:write(table.concat(out, "\n"), "\n")
f:close()
print("wrote tests/trainer_fixture.lua")
