-- Warlock guide. Shape: see docs/spec-v4.md "Guide data package"; checked by tests/run.lua (data test).
-- Spell IDs: Forever first rank (the macro casts by name, so the best known rank fires), levels from the
-- What's Training Forever trainer data. talent = true: a talent spell, level = the talent's minimum level
-- (wowhead.com/forever). Templates: key -> slot -> spell or { item = "HS" | "POT" | "BAND" | "BOMB" }.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HS, POT, BAND = { item = "HS" }, { item = "POT" }, { item = "BAND" }

local IMMOLATE, SHADOW_BOLT, DEMON_SKIN, SUMMON_IMP = S(348, "Immolate"), S(686, "Shadow Bolt"), S(687, "Demon Skin"), S(688, "Summon Imp")
local CORRUPTION, WEAKNESS, LIFE_TAP = S(172, "Corruption"), S(702, "Curse of Weakness"), S(1454, "Life Tap")
local AGONY, FEAR, DRAIN_SOUL = S(980, "Bane of Agony"), S(5782, "Fear"), S(1120, "Drain Soul")
local HEALTHSTONE, VOIDWALKER, HEALTH_FUNNEL = S(6201, "Create Healthstone"), S(697, "Summon Voidwalker"), S(755, "Health Funnel")
local DRAIN_LIFE, RECKLESSNESS, BREATH = S(689, "Drain Life"), S(704, "Curse of Recklessness"), S(5697, "Unending Breath")
local SEARING_PAIN, SOULSTONE = S(5676, "Searing Pain"), S(693, "Create Soulstone")
local DEMON_ARMOR, RAIN, ELEMENTS, SUCCUBUS = S(706, "Demon Armor"), S(5740, "Rain of Fire"), S(440892, "Curse of the Elements"), S(712, "Summon Succubus")
local DRAIN_MANA, TONGUES, BANISH = S(5138, "Drain Mana"), S(1714, "Curse of Tongues"), S(710, "Banish")
local HELLFIRE, FELHUNTER, SHADOW_WARD, SPELLSTONE = S(1949, "Hellfire"), S(691, "Summon Felhunter"), S(6229, "Shadow Ward"), S(2362, "Create Spellstone")
local HOWL, DEATH_COIL, SOUL_FIRE, DOOM = S(5484, "Howl of Terror"), S(6789, "Death Coil"), S(6353, "Soul Fire"), S(603, "Bane of Doom")
local SHADOWBURN, CONFLAGRATE, SIPHON_LIFE = T(17877, "Shadowburn"), T(1293817, "Conflagrate"), T(18265, "Siphon Life")
local WRACK, INCINERATE = T(1316697, "Wrack"), T(412758, "Incinerate")

-- Keys every bracket shares from 20 on: curses on 3, demons on G, consumables on V.
local CURSES = { normal = ELEMENTS, shift = WEAKNESS, alt = RECKLESSNESS, altshift = TONGUES }
local DEMONS = { normal = VOIDWALKER, shift = SUCCUBUS, alt = FELHUNTER, altshift = SUMMON_IMP }
local ITEMS = { normal = HS, shift = POT, alt = BAND }

FoilKeybindsGuides.WARLOCK = {
  suggested = 11629, -- Affliction levels best: DoTs and drains, little downtime
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    ["1"] = { normal = IMMOLATE },
    ["2"] = { normal = CORRUPTION },
    ["3"] = { normal = AGONY, shift = WEAKNESS, alt = RECKLESSNESS },
    ["4"] = { normal = SHADOW_BOLT, shift = SEARING_PAIN },
    Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL },
    E = { normal = LIFE_TAP, shift = HEALTH_FUNNEL },
    R = { normal = FEAR },
    F = { normal = DEMON_SKIN, shift = HEALTHSTONE, alt = SOULSTONE },
    G = { normal = VOIDWALKER, shift = SUMMON_IMP, alt = BREATH },
    V = ITEMS,
  },
  specs = {
    [11629] = {
      name = "Affliction",
      priority = {
        { spellID = 172, level = 4, en = "Main DoT. Keep it on every target.", ptBR = "DoT principal. Mantenha em todos os alvos." },
        { spellID = 980, level = 8, en = "Long Shadow DoT that grows over time. Let it run out before you cast it again.",
          ptBR = "DoT de Sombra longo que cresce com o tempo. Deixe acabar antes de lançar de novo." },
        { spellID = 18265, level = 30, talent = true, en = "DoT that heals you each tick. Worth it on longer fights.",
          ptBR = "DoT que cura você a cada tique. Vale a pena em lutas mais longas." },
        { spellID = 440892, level = 20, en = "Your curse: the target takes more spell damage. It stays up next to your Bane.",
          ptBR = "Sua maldição: o alvo sofre mais dano mágico. Fica ativa junto com a sua Perdição." },
        { spellID = 348, level = 1, en = "Fire DoT with a cast. Good while leveling and on long fights.",
          ptBR = "DoT de Fogo com tempo de conjuração. Bom para subir de nível e em lutas longas." },
        { spellID = 686, level = 1, en = "Filler at low level. Later, cast it when Nightfall makes it instant.",
          ptBR = "Preenchimento no começo. Depois, use quando o Anoitecer deixar ela instantânea." },
        { spellID = 1316697, level = 40, talent = true, en = "Channeled filler: your DoTs on the target tick faster while it runs.",
          ptBR = "Preenchimento canalizado: seus DoTs no alvo causam dano mais rápido enquanto dura." },
        { spellID = 689, level = 14, en = "Channel that heals you. Use it instead of sitting to eat.",
          ptBR = "Canalização que cura você. Use no lugar de parar para comer." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Tap, then heal back with Drain Life.",
          ptBR = "Troca vida por mana. Use e depois recupere a vida drenando o alvo." },
        { spellID = 5782, level = 8, en = "Sends a second enemy running. Damage breaks it.",
          ptBR = "Faz um segundo inimigo fugir. Dano quebra o efeito." },
        { spellID = 1120, level = 10, en = "Channel on a dying target to get a Soul Shard.",
          ptBR = "Canalize num alvo quase morto para ganhar um Fragmento de Alma." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = CORRUPTION, shift = IMMOLATE },
          ["2"] = { normal = AGONY, shift = SIPHON_LIFE },
          ["3"] = CURSES,
          ["4"] = { normal = SHADOW_BOLT, shift = SEARING_PAIN },
          Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL, alt = DRAIN_MANA },
          E = { normal = LIFE_TAP, shift = HEALTH_FUNNEL },
          R = { normal = FEAR, shift = BANISH },
          T = { normal = RAIN, shift = HELLFIRE },
          F = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = BREATH },
          G = DEMONS,
          V = ITEMS,
          C = { normal = SHADOW_WARD },
        },
        [3] = {
          ["1"] = { normal = CORRUPTION, shift = IMMOLATE },
          ["2"] = { normal = AGONY, shift = SIPHON_LIFE, alt = DOOM },
          ["3"] = CURSES,
          ["4"] = { normal = WRACK, shift = SHADOW_BOLT },
          Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL, alt = DRAIN_MANA },
          E = { normal = LIFE_TAP, shift = HEALTH_FUNNEL },
          R = { normal = FEAR, shift = BANISH, alt = HOWL },
          T = { normal = RAIN, shift = HELLFIRE },
          F = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = SPELLSTONE },
          G = DEMONS,
          V = ITEMS,
          C = { normal = DEATH_COIL, shift = SHADOW_WARD },
        },
      },
    },
    [11636] = {
      name = "Demonology",
      priority = {
        { spellID = 172, level = 4, en = "Main DoT. Put it up first while your demon holds the target.",
          ptBR = "DoT principal. Aplique primeiro enquanto o seu demônio segura o alvo." },
        { spellID = 980, level = 8, en = "Long Shadow DoT that grows over time. One cast per target.",
          ptBR = "DoT de Sombra longo que cresce com o tempo. Uma vez por alvo." },
        { spellID = 348, level = 1, en = "Fire DoT with a cast. Cast it before the pull.",
          ptBR = "DoT de Fogo com tempo de conjuração. Lance antes de puxar." },
        { spellID = 686, level = 1, en = "Main nuke while the demon tanks.", ptBR = "Dano principal enquanto o demônio segura o alvo." },
        { spellID = 755, level = 12, en = "Heals your demon so it keeps the enemy off you.",
          ptBR = "Cura o seu demônio para ele manter o inimigo longe de você." },
        { spellID = 702, level = 4, en = "Your curse while a pet tanks: the target hits softer.",
          ptBR = "Sua maldição enquanto o pet segura: o alvo bate mais fraco." },
        { spellID = 689, level = 14, en = "Channel that heals you. Use it between Life Taps.",
          ptBR = "Canalização que cura você. Use entre um toque de vida e outro." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Your demon covers you while you tap.",
          ptBR = "Troca vida por mana. O seu demônio protege você enquanto isso." },
        { spellID = 5782, level = 8, en = "Sends a second enemy running. Damage breaks it.",
          ptBR = "Faz um segundo inimigo fugir. Dano quebra o efeito." },
        { spellID = 1120, level = 10, en = "Channel on a dying target to get a Soul Shard.",
          ptBR = "Canalize num alvo quase morto para ganhar um Fragmento de Alma." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = CORRUPTION, shift = IMMOLATE },
          ["2"] = { normal = AGONY },
          ["3"] = { normal = WEAKNESS, shift = ELEMENTS, alt = RECKLESSNESS, altshift = TONGUES },
          ["4"] = { normal = SHADOW_BOLT, shift = SEARING_PAIN },
          Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL, alt = DRAIN_MANA },
          E = { normal = HEALTH_FUNNEL, shift = LIFE_TAP },
          R = { normal = FEAR, shift = BANISH },
          T = { normal = RAIN, shift = HELLFIRE },
          F = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = BREATH },
          G = DEMONS,
          V = ITEMS,
          C = { normal = SHADOW_WARD },
        },
        [3] = {
          ["1"] = { normal = CORRUPTION, shift = IMMOLATE },
          ["2"] = { normal = AGONY, alt = DOOM },
          ["3"] = { normal = WEAKNESS, shift = ELEMENTS, alt = RECKLESSNESS, altshift = TONGUES },
          ["4"] = { normal = SHADOW_BOLT, shift = SEARING_PAIN, alt = SOUL_FIRE },
          Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL, alt = DRAIN_MANA },
          E = { normal = HEALTH_FUNNEL, shift = LIFE_TAP },
          R = { normal = FEAR, shift = BANISH, alt = HOWL },
          T = { normal = RAIN, shift = HELLFIRE },
          F = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = SPELLSTONE },
          G = DEMONS,
          V = ITEMS,
          C = { normal = DEATH_COIL, shift = SHADOW_WARD },
        },
      },
    },
    [11637] = {
      name = "Destruction",
      priority = {
        { spellID = 348, level = 1, en = "Fire DoT. Keep it up: your Fire spells hit harder with it.",
          ptBR = "DoT de Fogo. Mantenha ativo: seus feitiços de Fogo batem mais forte com ele." },
        { spellID = 1293817, level = 25, talent = true, en = "Instant Fire hit that eats your Immolate. Cast Immolate again after.",
          ptBR = "Dano de Fogo instantâneo que consome o DoT de Fogo do alvo. Reaplique o DoT depois." },
        { spellID = 686, level = 1, en = "Main nuke.", ptBR = "Dano principal." },
        { spellID = 412758, level = 40, talent = true, en = "Fire nuke, stronger on a target with Immolate.",
          ptBR = "Dano de Fogo, mais forte num alvo com o seu DoT de Fogo." },
        { spellID = 17877, level = 20, talent = true, en = "Instant finisher for a Soul Shard. Gives the shard back if the target dies soon.",
          ptBR = "Finalizador instantâneo que gasta um Fragmento de Alma. Devolve o fragmento se o alvo morrer logo." },
        { spellID = 172, level = 4, en = "Cheap Shadow DoT. Put it up on long fights.",
          ptBR = "DoT de Sombra barato. Aplique em lutas longas." },
        { spellID = 6353, level = 48, en = "Huge Fire hit with a long cast. Costs a Soul Shard.",
          ptBR = "Dano de Fogo enorme com conjuração longa. Gasta um Fragmento de Alma." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Nukes burn mana fast.",
          ptBR = "Troca vida por mana. Seus ataques gastam mana rápido." },
        { spellID = 689, level = 14, en = "Channel that heals you between pulls.", ptBR = "Canalização que cura você entre um combate e outro." },
        { spellID = 5782, level = 8, en = "Sends a second enemy running. Damage breaks it.",
          ptBR = "Faz um segundo inimigo fugir. Dano quebra o efeito." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = IMMOLATE, shift = CORRUPTION },
          ["2"] = { normal = CONFLAGRATE, shift = SHADOWBURN },
          ["3"] = CURSES,
          ["4"] = { normal = SHADOW_BOLT, shift = SEARING_PAIN },
          ["5"] = { normal = AGONY },
          Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL },
          E = { normal = LIFE_TAP, shift = HEALTH_FUNNEL },
          R = { normal = FEAR, shift = BANISH },
          T = { normal = RAIN, shift = HELLFIRE },
          F = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = BREATH },
          G = DEMONS,
          V = ITEMS,
          C = { normal = SHADOW_WARD },
        },
        [3] = {
          ["1"] = { normal = IMMOLATE, shift = CORRUPTION },
          ["2"] = { normal = CONFLAGRATE, shift = SHADOWBURN },
          ["3"] = CURSES,
          ["4"] = { normal = SHADOW_BOLT, shift = INCINERATE, alt = SOUL_FIRE },
          ["5"] = { normal = AGONY, shift = SEARING_PAIN },
          Q = { normal = DRAIN_LIFE, shift = DRAIN_SOUL },
          E = { normal = LIFE_TAP, shift = HEALTH_FUNNEL },
          R = { normal = FEAR, shift = BANISH, alt = HOWL },
          T = { normal = RAIN, shift = HELLFIRE },
          F = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = SPELLSTONE },
          G = DEMONS,
          V = ITEMS,
          C = { normal = DEATH_COIL, shift = SHADOW_WARD },
        },
      },
    },
  },
}
