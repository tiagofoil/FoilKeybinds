-- Shaman guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Lightning Bolt and Healing Wave are granted at level 1 on Forever (trainer data bound 8 and 6).
-- Mana Tide Totem is 17354, the rank the trainer sells at 38: the talent rank's Forever page shows no real
-- level, so the row carries the trainer level, as Druid.lua does for Claw.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HSPOT, HEAL, EAT = { item = "HSPOT" }, { item = "HEAL" }, { item = "EAT" }

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

-- Home keys (docs/spec-v6.md). No castsequence: the shocks share a cooldown and the totems are dropped once
-- per pull. Earth Shock on 1 (it interrupts) and on a mouse button when it is also an attack; Frost Shock and
-- Earthbind on E, Flame Shock and Searing Totem on F, Purge on Q, Ghost Wolf on C.
-- Totems by job, not by element: buff totems go on T (a far buff key: dropped before the pull, rarely pressed
-- again), damage totems on F and R (Fire Nova and Magma are the area damage), Stoneclaw and Grounding on 2
-- (they take hits and spells for you), Healing Stream on 3 (a heal), Tremor, Poison Cleansing and Totemic
-- Recall on X (situational). Lightning Shield and the weapon buffs on 4.
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local CC = { normal = FROST_SHOCK, shift = EARTHBIND }
local SHOCKS = { normal = FLAME_SHOCK, shift = SEARING }
local DEBUFF = { normal = PURGE }
local KICK = { normal = EARTH_SHOCK }
local GUARD = { normal = STONECLAW, shift = GROUNDING }
local SELF_HEALS2 = { normal = LHW, shift = HW, alt = STREAM }
local SELF_HEALS3 = { normal = LHW, shift = HW, alt = STREAM, altshift = CHAIN_HEAL }
local SELF = { normal = SHIELD, shift = FLAMETONGUE, alt = ROCKBITER, altshift = FROSTBRAND }
local TOTEMS = { normal = CALL, shift = STRENGTH, alt = STONESKIN, altshift = SPRING }
local SITUATIONAL = { normal = TREMOR, shift = POISON_TOTEM, alt = RECALL }
local CURES = { normal = CURE_POISON, shift = CURE_DISEASE, alt = SPIRIT }
local FORM = { normal = WOLF }
local AREA = { shift = FIRE_NOVA, alt = MAGMA }

FoilKeybindsGuides.SHAMAN = {
  suggested = 11363, -- Enhancement levels best: melee with totems and shocks, little mana to drink back
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    BUTTON4 = { normal = BOLT },
    BUTTON5 = { normal = EARTH_SHOCK },
    E = { normal = EARTHBIND },
    F = SHOCKS,
    Q = DEBUFF,
    R = { shift = FIRE_NOVA },
    V = ITEMS,
    ["1"] = KICK,
    ["2"] = { normal = STONECLAW },
    ["3"] = { normal = HW },
    ["4"] = { normal = SHIELD, shift = ROCKBITER, alt = FLAMETONGUE },
    T = { normal = STRENGTH, shift = STONESKIN },
    X = { normal = TREMOR },
    Z = { normal = CURE_POISON, shift = SPIRIT },
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
          BUTTON4 = { normal = BOLT },
          BUTTON5 = { normal = EARTH_SHOCK },
          E = CC,
          F = SHOCKS,
          Q = DEBUFF,
          R = { normal = CHAIN_LIGHTNING, shift = FIRE_NOVA, alt = MAGMA },
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS2,
          ["4"] = SELF,
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
        [3] = {
          BUTTON4 = { normal = BOLT },
          BUTTON5 = { normal = EARTH_SHOCK },
          E = CC,
          F = SHOCKS,
          Q = DEBUFF,
          R = { normal = CHAIN_LIGHTNING, shift = FIRE_NOVA, alt = MAGMA },
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS3,
          ["4"] = SELF,
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
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
        -- Melee: Earth Shock, later Stormstrike, as the main attack; Lightning Bolt to pull.
        [2] = {
          BUTTON4 = { normal = EARTH_SHOCK },
          BUTTON5 = { normal = BOLT },
          E = CC,
          F = SHOCKS,
          Q = DEBUFF,
          R = AREA,
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS2,
          ["4"] = { normal = SHIELD, shift = WINDFURY, alt = FLAMETONGUE, altshift = ROCKBITER, ctrl = FROSTBRAND },
          T = { normal = CALL, shift = STRENGTH, alt = STONESKIN, altshift = WF_TOTEM, ctrl = FT_TOTEM },
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
        [3] = {
          BUTTON4 = { normal = STORMSTRIKE },
          BUTTON5 = { normal = EARTH_SHOCK, shift = BOLT },
          E = CC,
          F = SHOCKS,
          Q = DEBUFF,
          R = AREA,
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS2,
          ["4"] = { normal = SHIELD, shift = WINDFURY, alt = FLAMETONGUE, altshift = ROCKBITER, ctrl = FROSTBRAND },
          T = { normal = CALL, shift = STRENGTH, alt = STONESKIN, altshift = WF_TOTEM, ctrl = FT_TOTEM },
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
      },
    },
    [11362] = {
      name = "Restoration",
      priority = {
        { spellID = 5675, level = 26, en = "Water totem that gives mana back over time. Drop it before the pull.",
          ptBR = "Totem de água que devolve mana aos poucos. Coloque antes de puxar." },
        { spellID = 408521, level = 40, talent = true, en = "Heal over time. It also makes your Chain Heal stronger on that target.",
          ptBR = "Cura ao longo do tempo. Também deixa mais forte, nesse alvo, a sua cura que pula entre aliados." },
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
        -- Heals on the plain press, solo damage on Shift (Lightning Bolt on Mouse 4, Chain Lightning on Mouse 5).
        -- From 40 Chain Heal is the main heal on Mouse 4 and Lesser Healing Wave moves to 3.
        [2] = {
          BUTTON4 = { normal = LHW, shift = BOLT },
          BUTTON5 = { normal = STREAM, shift = CHAIN_LIGHTNING },
          E = CC,
          F = SHOCKS,
          Q = DEBUFF,
          R = { normal = HW, shift = MANA_TIDE, alt = MAGMA },
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["4"] = SELF,
          T = { normal = CALL, shift = SPRING, alt = STRENGTH, altshift = STONESKIN },
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
        [3] = {
          BUTTON4 = { normal = CHAIN_HEAL, shift = BOLT },
          BUTTON5 = { normal = RIPTIDE, shift = CHAIN_LIGHTNING },
          E = CC,
          F = SHOCKS,
          Q = DEBUFF,
          R = { normal = HW, shift = MANA_TIDE, alt = MAGMA },
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = { normal = LHW, shift = STREAM },
          ["4"] = SELF,
          T = { normal = CALL, shift = SPRING, alt = STRENGTH, altshift = STONESKIN },
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
      },
    },
  },
}
