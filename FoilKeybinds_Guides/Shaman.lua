-- Shaman guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Lightning Bolt and Healing Wave are granted at level 1 on Forever (trainer data bound 8 and 6).
-- Mana Tide Totem is 17354, the rank the trainer sells at 38: the talent rank's Forever page shows no real
-- level, so the row carries the trainer level, as Druid.lua does for Claw.
-- Totems by element: fire on 4, earth on 5, water on F, air on G; Call of the Elements on C.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local POT, BAND = { item = "POT" }, { item = "BAND" }

local BOLT, EARTH_SHOCK, FLAME_SHOCK, FROST_SHOCK = S(403, "Lightning Bolt"), S(8042, "Earth Shock"), S(8050, "Flame Shock"), S(8056, "Frost Shock")
local HW, LHW, SHIELD, PURGE = S(331, "Healing Wave"), S(8004, "Lesser Healing Wave"), S(324, "Lightning Shield"), S(370, "Purge")
local ROCKBITER, FLAMETONGUE, FROSTBRAND, WINDFURY = S(8017, "Rockbiter Weapon"), S(8024, "Flametongue Weapon"), S(8033, "Frostbrand Weapon"), S(8232, "Windfury Weapon")
local STONESKIN, EARTHBIND, STONECLAW, STRENGTH = S(8071, "Stoneskin Totem"), S(2484, "Earthbind Totem"), S(5730, "Stoneclaw Totem"), S(8075, "Strength of Earth Totem")
local SEARING, FIRE_NOVA, MAGMA, FT_TOTEM = S(3599, "Searing Totem"), S(408341, "Fire Nova"), S(8190, "Magma Totem"), S(8227, "Flametongue Totem")
local STREAM, SPRING, POISON_TOTEM, TREMOR = S(5394, "Healing Stream Totem"), S(5675, "Mana Spring Totem"), S(8166, "Poison Cleansing Totem"), S(8143, "Tremor Totem")
local GROUNDING, WF_TOTEM, CALL, RECALL = S(8177, "Grounding Totem"), S(8512, "Windfury Totem"), S(66842, "Call of the Elements"), S(36936, "Totemic Recall")
local CURE_POISON, CURE_DISEASE, SPIRIT, WOLF = S(526, "Cure Poison"), S(2870, "Cure Disease"), S(2008, "Ancestral Spirit"), S(2645, "Ghost Wolf")
local CHAIN_LIGHTNING, CHAIN_HEAL, MANA_TIDE = S(421, "Chain Lightning"), S(1064, "Chain Heal"), S(17354, "Mana Tide Totem")
local STORMSTRIKE, RIPTIDE = T(17364, "Stormstrike"), T(408521, "Riptide")

-- Keys every spec shares from 20 on: totems by element, cures on T, totem bar on C.
local ITEMS = { normal = POT, shift = BAND }
local FIRE = { normal = SEARING, shift = MAGMA, alt = FT_TOTEM }
local EARTH = { normal = STRENGTH, shift = STONESKIN, alt = EARTHBIND, altshift = TREMOR }
local WATER = { normal = STREAM, shift = SPRING, alt = POISON_TOTEM }
local AIR = { normal = GROUNDING, shift = WF_TOTEM }
local CURES = { normal = CURE_POISON, shift = CURE_DISEASE, alt = SPIRIT }
local TOTEM_BAR = { normal = CALL, shift = RECALL }
local SELF = { normal = SHIELD, shift = WOLF }
local IMBUES = { normal = FLAMETONGUE, shift = ROCKBITER, alt = FROSTBRAND, altshift = WINDFURY }

FoilKeybindsGuides.SHAMAN = {
  suggested = 11363, -- Enhancement levels best: melee with totems and shocks, little mana to drink back
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    ["1"] = { normal = BOLT },
    ["2"] = { normal = EARTH_SHOCK, shift = PURGE },
    ["3"] = { normal = FLAME_SHOCK },
    ["4"] = { normal = SEARING, shift = FIRE_NOVA },
    ["5"] = { normal = STRENGTH, shift = STONESKIN, alt = EARTHBIND, altshift = STONECLAW },
    Q = { normal = HW },
    E = { normal = ROCKBITER, shift = FLAMETONGUE },
    R = { normal = SHIELD },
    T = { normal = CURE_POISON, shift = SPIRIT },
    V = ITEMS,
  },
  specs = {
    [11326] = {
      name = "Elemental Combat",
      priority = {
        { spellID = 3599, level = 10, en = "Drop it before the pull. It shoots your target while you cast.",
          ptBR = "Coloque antes de puxar. Ele ataca o seu alvo enquanto você conjura." },
        { spellID = 8050, level = 10, en = "Instant Fire hit plus a DoT. Open with it.",
          ptBR = "Dano de Fogo instantâneo mais um DoT. Abra o combate com ele." },
        { spellID = 403, level = 1, en = "Main nuke.", ptBR = "Ataque principal." },
        { spellID = 421, level = 32, en = "Hits your target and jumps to enemies nearby. Use it on packs.",
          ptBR = "Atinge o seu alvo e pula para inimigos próximos. Use em grupos." },
        { spellID = 8042, level = 4, en = "Instant Nature hit that also interrupts a cast.",
          ptBR = "Dano de Natureza instantâneo que também interrompe uma conjuração." },
        { spellID = 8056, level = 20, en = "Instant Frost hit that slows. Use it on an enemy that runs or chases you.",
          ptBR = "Dano de Gelo instantâneo que deixa o alvo lento. Use num inimigo que foge ou persegue você." },
        { spellID = 8004, level = 20, en = "Fast heal for yourself in the middle of a fight.",
          ptBR = "Cura rápida para você no meio da luta." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = BOLT, shift = CHAIN_LIGHTNING },
          ["2"] = { normal = FLAME_SHOCK, shift = FROST_SHOCK },
          ["3"] = { normal = EARTH_SHOCK, shift = PURGE, alt = FIRE_NOVA },
          ["4"] = FIRE,
          ["5"] = EARTH,
          Q = { normal = LHW, shift = HW },
          E = IMBUES,
          R = SELF,
          T = CURES,
          F = WATER,
          G = AIR,
          C = TOTEM_BAR,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = BOLT, shift = CHAIN_LIGHTNING },
          ["2"] = { normal = FLAME_SHOCK, shift = FROST_SHOCK },
          ["3"] = { normal = EARTH_SHOCK, shift = PURGE, alt = FIRE_NOVA },
          ["4"] = FIRE,
          ["5"] = EARTH,
          Q = { normal = LHW, shift = HW, alt = CHAIN_HEAL },
          E = IMBUES,
          R = SELF,
          T = CURES,
          F = WATER,
          G = AIR,
          C = TOTEM_BAR,
          V = ITEMS,
        },
      },
    },
    [11363] = {
      name = "Enhancement",
      priority = {
        { spellID = 8232, level = 30, en = "Weapon buff that adds extra attacks. Before 30, use the one you have.",
          ptBR = "Bônus de arma que dá ataques extras. Antes do nível 30, use o bônus de arma que você tiver." },
        { spellID = 324, level = 8, en = "Shield that hits back whoever strikes you. Keep it up.",
          ptBR = "Escudo que causa dano em quem bate em você. Mantenha ativo." },
        { spellID = 8075, level = 10, en = "Earth totem that raises your Strength. Drop it before the pull.",
          ptBR = "Totem de terra que aumenta a sua Força. Coloque antes de puxar." },
        { spellID = 17364, level = 40, talent = true, en = "Weapon strike that makes your next shock hit harder. Use it on cooldown.",
          ptBR = "Golpe de arma que deixa o seu próximo choque mais forte. Use sempre que estiver disponível." },
        { spellID = 8042, level = 4, en = "Instant Nature hit that also interrupts a cast.",
          ptBR = "Dano de Natureza instantâneo que também interrompe uma conjuração." },
        { spellID = 8050, level = 10, en = "Fire hit plus a DoT on targets that live a while.",
          ptBR = "Dano de Fogo mais um DoT em alvos que vão durar." },
        { spellID = 3599, level = 10, en = "Extra damage on long fights. Drop it next to the target.",
          ptBR = "Dano extra em lutas longas. Coloque perto do alvo." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = EARTH_SHOCK, shift = BOLT },
          ["2"] = { normal = FLAME_SHOCK, shift = FROST_SHOCK },
          ["3"] = { normal = FIRE_NOVA, shift = PURGE },
          ["4"] = FIRE,
          ["5"] = EARTH,
          Q = { normal = LHW, shift = HW },
          E = { normal = WINDFURY, shift = ROCKBITER, alt = FLAMETONGUE, altshift = FROSTBRAND },
          R = SELF,
          T = CURES,
          F = WATER,
          G = AIR,
          C = TOTEM_BAR,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = STORMSTRIKE, shift = BOLT },
          ["2"] = { normal = EARTH_SHOCK, shift = FLAME_SHOCK, alt = FROST_SHOCK },
          ["3"] = { normal = FIRE_NOVA, shift = PURGE },
          ["4"] = FIRE,
          ["5"] = EARTH,
          Q = { normal = LHW, shift = HW },
          E = { normal = WINDFURY, shift = ROCKBITER, alt = FLAMETONGUE, altshift = FROSTBRAND },
          R = SELF,
          T = CURES,
          F = WATER,
          G = AIR,
          C = TOTEM_BAR,
          V = ITEMS,
        },
      },
    },
    [11362] = {
      name = "Restoration",
      priority = {
        { spellID = 5675, level = 26, en = "Water totem that gives mana back over time. Drop it before the pull.",
          ptBR = "Totem de água que devolve mana aos poucos. Coloque antes de puxar." },
        { spellID = 408521, level = 40, talent = true, en = "Heal over time. It also makes your Chain Heal stronger on that target.",
          ptBR = "Cura ao longo do tempo. Também deixa a sua cura em cadeia mais forte nesse alvo." },
        { spellID = 1064, level = 40, en = "Heal that jumps to hurt allies nearby. Your main group heal.",
          ptBR = "Cura que pula para aliados feridos por perto. Sua cura principal em grupo." },
        { spellID = 8004, level = 20, en = "Fast heal for when damage spikes.", ptBR = "Cura rápida para quando o dano aperta." },
        { spellID = 331, level = 1, en = "Big, slow heal. Use it when there is time to cast.",
          ptBR = "Cura grande e lenta. Use quando der tempo de conjurar." },
        { spellID = 17354, level = 38, en = "Totem that gives the party a lot of mana. It comes from a talent.",
          ptBR = "Totem que devolve bastante mana ao grupo. Vem de um talento." },
        { spellID = 526, level = 16, en = "Removes a poison.", ptBR = "Remove um veneno." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = BOLT, shift = CHAIN_LIGHTNING },
          ["2"] = { normal = FLAME_SHOCK, shift = FROST_SHOCK },
          ["3"] = { normal = EARTH_SHOCK, shift = PURGE },
          ["4"] = FIRE,
          ["5"] = EARTH,
          Q = { normal = LHW },
          E = { normal = HW },
          R = SELF,
          T = CURES,
          F = { normal = SPRING, shift = STREAM, alt = POISON_TOTEM, altshift = MANA_TIDE },
          G = AIR,
          C = TOTEM_BAR,
          X = IMBUES,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = BOLT, shift = CHAIN_LIGHTNING },
          ["2"] = { normal = FLAME_SHOCK, shift = FROST_SHOCK },
          ["3"] = { normal = EARTH_SHOCK, shift = PURGE },
          ["4"] = FIRE,
          ["5"] = EARTH,
          Q = { normal = LHW, shift = RIPTIDE },
          E = { normal = CHAIN_HEAL, shift = HW },
          R = SELF,
          T = CURES,
          F = { normal = SPRING, shift = STREAM, alt = POISON_TOTEM, altshift = MANA_TIDE },
          G = AIR,
          C = TOTEM_BAR,
          X = IMBUES,
          V = ITEMS,
        },
      },
    },
  },
}
