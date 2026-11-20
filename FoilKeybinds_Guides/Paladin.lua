-- Paladin guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Seal of Righteousness rank 1 (20154) is a starting spell (granted in the trainer data), learned at level 1.
-- Holy Shock, Seal of Command and Holy Shield use the talent's own spell ID (their trainer ranks need the talent).
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end

local SEAL_RIGHT, HOLY_LIGHT, DEVOTION = S(20154, "Seal of Righteousness"), S(635, "Holy Light"), S(465, "Devotion Aura")
local JUDGEMENT, MIGHT, HOLY_STRIKE = S(20271, "Judgement"), S(19740, "Blessing of Might"), S(679, "Holy Strike")
local CRUSADER, DIV_PROT, HOJ = S(21082, "Seal of the Crusader"), S(498, "Divine Protection"), S(853, "Hammer of Justice")
local PURIFY, SEAL_FURY, LOH = S(1152, "Purify"), S(1311649, "Seal of Fury"), S(633, "Lay on Hands")
local RF, BOP, REDEMPTION = S(25780, "Righteous Fury"), S(1022, "Blessing of Protection"), S(7328, "Redemption")
local WISDOM, RET_AURA, FREEDOM = S(19742, "Blessing of Wisdom"), S(7294, "Retribution Aura"), S(1044, "Blessing of Freedom")
local FOL, EXORCISM, CONSECRATION = S(19750, "Flash of Light"), S(879, "Exorcism"), S(26573, "Consecration")
local KINGS, SEAL_JUSTICE, CONCENTRATION = S(20217, "Blessing of Kings"), S(20164, "Seal of Justice"), S(19746, "Concentration Aura")
local TURN_UNDEAD, SEAL_LIGHT, DIVINE_SHIELD = S(2878, "Turn Undead"), S(20165, "Seal of Light"), S(642, "Divine Shield")
local SEAL_WISDOM, CLEANSE, HOW = S(20166, "Seal of Wisdom"), S(4987, "Cleanse"), S(24275, "Hammer of Wrath")
local COMMAND, REPENTANCE, HOLY_SHIELD = T(20375, "Seal of Command"), T(20066, "Repentance"), T(20925, "Holy Shield")
local HOLY_SHOCK, VIGIL = T(1311606, "Holy Shock"), T(1310911, "Light's Vigil")

-- Home keys (docs/spec-v6.md). No castsequence: Judgement and Holy Strike have cooldowns. Main attack on
-- Mouse 4, Judgement on Mouse 5 (Holy: heals there, attacks on Shift), Hammer of Justice on E, your damage seal
-- on F, the seals you judge for a debuff on Q, auras on C, blessings on 4. No interrupt spell, so 1 stays free.
local DEFENSIVE = { normal = DIV_PROT, shift = BOP, alt = DIVINE_SHIELD }
local HEALS = { normal = FOL, shift = HOLY_LIGHT, alt = LOH }
local UTILITY2 = { normal = PURIFY, shift = FREEDOM, alt = REDEMPTION }
local UTILITY3 = { normal = CLEANSE, shift = FREEDOM, alt = REDEMPTION }
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }

FoilKeybindsGuides.PALADIN = {
  suggested = 11559, -- Retribution levels best: more damage per swing, heals itself between pulls
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same seals and blessings for all three.
  shared = {
    BUTTON4 = { normal = HOLY_STRIKE },
    BUTTON5 = { normal = JUDGEMENT },
    E = { normal = HOJ },
    F = { normal = SEAL_RIGHT, shift = SEAL_FURY },
    Q = { normal = CRUSADER },
    V = ITEMS,
    ["2"] = { normal = DIV_PROT, shift = BOP },
    ["3"] = { normal = HOLY_LIGHT, shift = LOH },
    ["4"] = { normal = MIGHT, shift = WISDOM },
    T = { normal = RF },
    C = { normal = DEVOTION, shift = RET_AURA },
    X = UTILITY2,
  },
  specs = {
    [11486] = {
      name = "Holy",
      priority = {
        { spellID = 19750, level = 20, en = "Main heal: fast and cheap.", ptBR = "Cura principal: rápida e barata." },
        { spellID = 635, level = 2, en = "Big heal for heavy damage. Slower and costs more.",
          ptBR = "Cura grande para dano pesado. Mais lenta e mais cara." },
        { spellID = 1311606, level = 30, talent = true, en = "Instant heal on an ally or Holy hit on an enemy. Use it on cooldown.",
          ptBR = "Cura instantânea num aliado ou dano Sagrado num inimigo. Use sempre que estiver disponível." },
        { spellID = 1310911, level = 40, talent = true, en = "Put it on the tank: your next Holy Shock there has no cooldown and heals the party.",
          ptBR = "Aplique no tanque: a próxima cura instantânea do seu talento nele não tem recarga e cura o grupo." },
        { spellID = 1152, level = 8, en = "Removes poison and disease.", ptBR = "Remove veneno e doença." },
        { spellID = 633, level = 10, en = "Full heal on a long cooldown. Save it for emergencies.",
          ptBR = "Cura total com recarga longa. Guarde para emergências." },
        { spellID = 20271, level = 4, en = "Solo damage: unleash your seal on the target on cooldown.",
          ptBR = "Dano sozinho: libere o seu selo no alvo sempre que estiver disponível." },
      },
      templates = {
        -- Heals on the plain press, solo damage on Shift (Holy Strike on Mouse 4, Judgement on Mouse 5).
        [2] = {
          BUTTON4 = { normal = FOL, shift = HOLY_STRIKE },
          BUTTON5 = { normal = HOLY_SHOCK, shift = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_RIGHT },
          Q = { normal = CRUSADER, shift = SEAL_LIGHT },
          R = { normal = HOLY_LIGHT, shift = LOH, alt = CONSECRATION, altshift = EXORCISM },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["4"] = { normal = WISDOM, shift = KINGS, alt = MIGHT },
          C = { normal = CONCENTRATION, shift = DEVOTION },
          X = UTILITY2,
        },
        [3] = {
          BUTTON4 = { normal = FOL, shift = HOLY_STRIKE },
          BUTTON5 = { normal = HOLY_SHOCK, shift = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_RIGHT },
          Q = { normal = CRUSADER, shift = SEAL_LIGHT, alt = SEAL_WISDOM },
          R = { normal = HOLY_LIGHT, shift = LOH, alt = CONSECRATION, altshift = EXORCISM, ctrl = HOW },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["3"] = { normal = VIGIL },
          ["4"] = { normal = WISDOM, shift = KINGS, alt = MIGHT },
          C = { normal = CONCENTRATION, shift = DEVOTION },
          X = UTILITY3,
        },
      },
    },
    [11541] = {
      name = "Protection",
      priority = {
        { spellID = 25780, level = 10, en = "More threat from Holy damage. Keep it on while you tank.",
          ptBR = "Mais ameaça com dano Sagrado. Mantenha ativo enquanto tanqueia." },
        { spellID = 1311649, level = 10, en = "Tank seal: Holy damage on each swing, and a small absorb while you hold a shield.",
          ptBR = "Selo de tanque: dano Sagrado a cada golpe e uma pequena absorção quando você usa escudo." },
        { spellID = 20925, level = 30, talent = true, en = "More block, and Holy damage on each block. Keep it up while you tank.",
          ptBR = "Mais bloqueio e dano Sagrado a cada bloqueio. Mantenha ativo enquanto tanqueia." },
        { spellID = 26573, level = 20, en = "Holy damage on the ground. Holds threat on every enemy around you.",
          ptBR = "Dano Sagrado no chão. Segura a ameaça de todos os inimigos ao seu redor." },
        { spellID = 20271, level = 4, en = "Unleash your seal for extra damage and threat.",
          ptBR = "Libera o seu selo no alvo para mais dano e mais ameaça." },
        { spellID = 679, level = 6, en = "Instant Holy strike. Use it on cooldown.", ptBR = "Golpe Sagrado instantâneo. Use sempre que estiver disponível." },
        { spellID = 853, level = 8, en = "Stuns a caster or an enemy that runs.", ptBR = "Atordoa um conjurador ou um inimigo que tenta fugir." },
        { spellID = 465, level = 1, en = "Armor aura for you and the group.", ptBR = "Aura de armadura para você e o grupo." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_FURY, shift = SEAL_RIGHT },
          Q = { normal = SEAL_JUSTICE },
          R = { normal = EXORCISM, shift = CONSECRATION },
          V = ITEMS,
          ["2"] = { normal = HOLY_SHIELD, shift = DIV_PROT, alt = DIVINE_SHIELD, altshift = BOP },
          ["3"] = HEALS,
          ["4"] = { normal = KINGS, shift = MIGHT, alt = WISDOM },
          T = { normal = RF },
          C = { normal = DEVOTION, shift = RET_AURA },
          X = UTILITY2,
        },
        [3] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_FURY, shift = SEAL_RIGHT },
          Q = { normal = SEAL_JUSTICE },
          R = { normal = EXORCISM, shift = CONSECRATION, altshift = HOW },
          V = ITEMS,
          ["2"] = { normal = HOLY_SHIELD, shift = DIV_PROT, alt = DIVINE_SHIELD, altshift = BOP },
          ["3"] = HEALS,
          ["4"] = { normal = KINGS, shift = MIGHT, alt = WISDOM },
          T = { normal = RF },
          C = { normal = DEVOTION, shift = RET_AURA },
          X = UTILITY3,
        },
      },
    },
    [11559] = {
      name = "Retribution",
      priority = {
        { spellID = 20375, level = 20, talent = true, en = "Your seal while leveling: extra Holy hits on your swings. Keep it up.",
          ptBR = "Seu selo para subir de nível: golpes extras de dano Sagrado. Mantenha ativo." },
        { spellID = 20271, level = 4, en = "Unleash your seal on the target. Use it on cooldown.",
          ptBR = "Libera o seu selo no alvo. Use sempre que estiver disponível." },
        { spellID = 679, level = 6, en = "Instant strike with Holy damage. Use it on cooldown.",
          ptBR = "Golpe instantâneo com dano Sagrado. Use sempre que estiver disponível." },
        { spellID = 26573, level = 20, en = "Holy damage on the ground around you. Worth it on two or more enemies.",
          ptBR = "Dano Sagrado no chão ao seu redor. Vale a pena contra dois ou mais inimigos." },
        { spellID = 879, level = 20, en = "Instant Holy hit, only on undead and demons.",
          ptBR = "Dano Sagrado instantâneo, só em mortos-vivos e demônios." },
        { spellID = 24275, level = 44, en = "Ranged finisher on targets under 20% health.",
          ptBR = "Finalizador à distância em alvos com menos de 20% de vida." },
        { spellID = 20066, level = 20, talent = true, en = "Takes one enemy out of the fight for a while. Damage breaks it.",
          ptBR = "Tira um inimigo da luta por um tempo. Dano quebra o efeito." },
        { spellID = 19750, level = 20, en = "Fast, cheap self heal between pulls.",
          ptBR = "Cura rápida e barata em você entre um combate e outro." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ, shift = REPENTANCE, alt = TURN_UNDEAD },
          F = { normal = COMMAND, shift = SEAL_RIGHT },
          Q = { normal = CRUSADER, shift = SEAL_JUSTICE },
          R = { normal = EXORCISM, shift = CONSECRATION },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["3"] = HEALS,
          ["4"] = { normal = MIGHT, shift = KINGS, alt = WISDOM },
          C = { normal = RET_AURA, shift = DEVOTION, alt = CONCENTRATION },
          X = UTILITY2,
        },
        [3] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ, shift = REPENTANCE, alt = TURN_UNDEAD },
          F = { normal = COMMAND, shift = SEAL_RIGHT },
          Q = { normal = CRUSADER, shift = SEAL_JUSTICE },
          R = { normal = EXORCISM, shift = CONSECRATION, altshift = HOW },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["3"] = HEALS,
          ["4"] = { normal = MIGHT, shift = KINGS, alt = WISDOM },
          C = { normal = RET_AURA, shift = DEVOTION, alt = CONCENTRATION },
          X = UTILITY3,
        },
      },
    },
  },
}
