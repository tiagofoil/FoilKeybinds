-- Paladin guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Spell order and use from the Icy Veins WoW Forever Paladin guides (leveling and rotation pages, read 2026-11-20).
-- Seal of Righteousness rank 1 (20154) is a starting spell (granted in the trainer data), learned at level 1.
-- Talent spells use the talent's own spell ID. Levels: the talent's minimum, one tier before the trainer's rank 2
-- (Seal of Command 20, Holy Shield 30, Holy Shock 30, Light's Vigil 40); Repentance 30 from the Icy Veins milestones.
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
local HOLY_WRATH, DIV_INT = S(2812, "Holy Wrath"), S(19752, "Divine Intervention")
local COMMAND, REPENTANCE, HOLY_SHIELD = T(20375, "Seal of Command"), T(20066, "Repentance"), T(20925, "Holy Shield")
local HOLY_SHOCK, VIGIL = T(1311606, "Holy Shock"), T(1310911, "Light's Vigil")

-- Home keys (docs/spec-v6.md). No castsequence: Judgement and Holy Strike have cooldowns. Main attack on
-- Mouse 4, Judgement on Mouse 5 (Holy: heals there, attacks on Shift), Hammer of Justice on E, your damage seal
-- on F, the seals you judge for a debuff on Q, auras on C, blessings on 4. No interrupt spell, so 1 stays free.
local DEFENSIVE = { normal = DIV_PROT, shift = BOP, alt = DIVINE_SHIELD }
local HEALS = { normal = HOLY_LIGHT, shift = FOL, alt = LOH } -- Holy Light is the self heal while leveling
local UTILITY1 = { normal = PURIFY, shift = FREEDOM, alt = REDEMPTION }
local UTILITY2 = { normal = PURIFY, shift = FREEDOM, alt = REDEMPTION, altshift = DIV_INT }
local UTILITY3 = { normal = CLEANSE, shift = FREEDOM, alt = REDEMPTION, altshift = DIV_INT }
local BLESSINGS = { normal = KINGS, shift = MIGHT, alt = WISDOM } -- Kings from 20, Might before
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }

FoilKeybindsGuides.PALADIN = {
  suggested = 11559, -- Retribution levels best: good damage, heals itself, many ways out of trouble
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
    X = UTILITY1,
  },
  specs = {
    [11486] = {
      name = "Holy",
      priority = {
        { spellID = 19750, level = 20, en = "Main heal: the best healing for your mana. Cast it most of the time.",
          ptBR = "Cura principal: a que mais cura pela mana gasta. Use na maior parte do tempo." },
        { spellID = 635, level = 2, en = "Big heal for heavy damage, and when a proc makes it fast.",
          ptBR = "Cura grande para dano pesado, e quando um efeito deixa ela rápida." },
        { spellID = 1311606, level = 30, talent = true, en = "Instant heal, but costly. For emergencies or while you move.",
          ptBR = "Cura instantânea, mas cara. Para emergências ou enquanto você se move." },
        { spellID = 1310911, level = 40, talent = true, en = "Cast it before group damage, then Holy Shock the same ally to heal the party.",
          ptBR = "Lance antes do dano no grupo e depois a cura instantânea no mesmo aliado para curar o grupo todo." },
        { spellID = 633, level = 10, en = "Full heal for all your mana. Last resort.",
          ptBR = "Cura total que gasta toda a sua mana. Último recurso." },
        { spellID = 20165, level = 30, en = "Your seal in a group. Use Seal of Wisdom if another Paladin keeps Light up.",
          ptBR = "Seu selo em grupo. Use o selo de sabedoria se outro Paladino já mantém este." },
        { spellID = 20154, level = 1, en = "Damage seal while you quest alone.", ptBR = "Selo de dano enquanto você faz missões sozinho." },
        { spellID = 20271, level = 4, en = "Unleash your seal on the target on cooldown.",
          ptBR = "Libere o seu selo no alvo sempre que estiver disponível." },
        { spellID = 26573, level = 20, en = "Holy damage on the ground. Strong but costs a lot of mana.",
          ptBR = "Dano Sagrado no chão. Forte, mas gasta muita mana." },
        { spellID = 679, level = 6, en = "Instant Holy strike. Use it on cooldown.", ptBR = "Golpe Sagrado instantâneo. Use sempre que estiver disponível." },
      },
      templates = {
        -- Heals on the plain press, solo damage on Shift (Holy Strike on Mouse 4, Judgement on Mouse 5).
        -- Holy Shock only from 40: the leveling build takes it at 41.
        [2] = {
          BUTTON4 = { normal = FOL, shift = HOLY_STRIKE },
          BUTTON5 = { normal = HOLY_LIGHT, shift = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_RIGHT },
          Q = { normal = CRUSADER, shift = SEAL_LIGHT },
          R = { normal = LOH, shift = CONSECRATION, alt = EXORCISM },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["4"] = BLESSINGS,
          C = { normal = DEVOTION, shift = CONCENTRATION },
          X = UTILITY2,
        },
        [3] = {
          BUTTON4 = { normal = FOL, shift = HOLY_STRIKE },
          BUTTON5 = { normal = HOLY_LIGHT, shift = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_RIGHT },
          Q = { normal = SEAL_LIGHT, shift = SEAL_WISDOM, alt = CRUSADER },
          R = { normal = HOLY_SHOCK, shift = CONSECRATION, alt = EXORCISM, altshift = LOH, ctrl = HOW },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["3"] = { normal = VIGIL },
          ["4"] = { normal = KINGS, shift = WISDOM, alt = MIGHT },
          C = { normal = DEVOTION, shift = CONCENTRATION },
          X = UTILITY3,
        },
      },
    },
    [11541] = {
      name = "Protection",
      priority = {
        { spellID = 25780, level = 10, en = "More threat from Holy damage. Keep it on at all times.",
          ptBR = "Mais ameaça com dano Sagrado. Mantenha ativo o tempo todo." },
        { spellID = 1311649, level = 10, en = "Tank seal: more survival, and your Judgement taunts.",
          ptBR = "Selo de tanque: mais resistência, e o seu julgamento provoca o alvo." },
        { spellID = 26573, level = 20, en = "Holy damage on the ground: your threat on every enemy around. Keep mana for it.",
          ptBR = "Dano Sagrado no chão: sua ameaça em todos os inimigos ao redor. Guarde mana para ele." },
        { spellID = 20271, level = 4, en = "Damage, and a taunt with Seal of Fury. Use it to win back an enemy.",
          ptBR = "Dano e provocação com o selo de tanque. Use para recuperar um inimigo." },
        { spellID = 20925, level = 30, talent = true, en = "More block, and Holy damage on each block. Cast it as often as you can.",
          ptBR = "Mais bloqueio e dano Sagrado a cada bloqueio. Use sempre que puder." },
        { spellID = 679, level = 6, en = "Instant Holy strike. Use it on cooldown.", ptBR = "Golpe Sagrado instantâneo. Use sempre que estiver disponível." },
        { spellID = 879, level = 20, en = "Instant Holy hit, only on undead and demons.",
          ptBR = "Dano Sagrado instantâneo, só em mortos-vivos e demônios." },
        { spellID = 2812, level = 50, en = "Holy damage around you on undead and demons. Cast it when you are not tanking.",
          ptBR = "Dano Sagrado ao seu redor em mortos-vivos e demônios. Use quando não estiver tanqueando." },
        { spellID = 633, level = 10, en = "Full heal for all your mana. Saves a pull.",
          ptBR = "Cura total que gasta toda a sua mana. Salva um combate." },
        { spellID = 1022, level = 10, en = "Physical immunity on an ally who has aggro. They cannot attack while it lasts.",
          ptBR = "Imunidade a dano físico num aliado que puxou o inimigo. Ele não ataca enquanto dura." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_FURY, shift = SEAL_RIGHT },
          Q = { normal = SEAL_JUSTICE, shift = SEAL_LIGHT },
          R = { normal = CONSECRATION, shift = EXORCISM },
          V = ITEMS,
          ["2"] = { normal = HOLY_SHIELD, shift = DIV_PROT, alt = DIVINE_SHIELD, altshift = BOP },
          ["3"] = HEALS,
          ["4"] = BLESSINGS,
          T = { normal = RF },
          C = { normal = DEVOTION, shift = RET_AURA },
          X = UTILITY2,
        },
        [3] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ },
          F = { normal = SEAL_FURY, shift = SEAL_RIGHT },
          Q = { normal = SEAL_LIGHT, shift = SEAL_WISDOM, alt = SEAL_JUSTICE },
          R = { normal = CONSECRATION, shift = EXORCISM, alt = HOLY_WRATH, altshift = HOW },
          V = ITEMS,
          ["2"] = { normal = HOLY_SHIELD, shift = DIV_PROT, alt = DIVINE_SHIELD, altshift = BOP },
          ["3"] = HEALS,
          ["4"] = BLESSINGS,
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
        { spellID = 21082, level = 6, en = "Judge it once on a target that lives long: it takes more Holy damage. Then switch seal.",
          ptBR = "Julgue uma vez num alvo que dura: ele sofre mais dano Sagrado. Depois troque de selo." },
        { spellID = 20271, level = 4, en = "Unleash your seal on the target. Use it on cooldown, it does not take a global cooldown.",
          ptBR = "Libera o seu selo no alvo. Use sempre que estiver disponível, não ocupa a recarga global." },
        { spellID = 679, level = 6, en = "Instant strike with Holy damage. Use it on cooldown.",
          ptBR = "Golpe instantâneo com dano Sagrado. Use sempre que estiver disponível." },
        { spellID = 26573, level = 20, en = "Holy damage on the ground. Costs a lot of mana: use it on two or more enemies.",
          ptBR = "Dano Sagrado no chão. Gasta muita mana: use contra dois ou mais inimigos." },
        { spellID = 879, level = 20, en = "Instant Holy hit, only on undead and demons. Also pulls from range.",
          ptBR = "Dano Sagrado instantâneo, só em mortos-vivos e demônios. Também puxa de longe." },
        { spellID = 24275, level = 44, en = "Ranged finisher on targets under 20% health. Good on enemies that run.",
          ptBR = "Finalizador à distância em alvos com menos de 20% de vida. Bom contra inimigos que fogem." },
        { spellID = 20154, level = 1, en = "Seal for a fast weapon or lots of spell power. From 40, swap it with Command.",
          ptBR = "Selo para arma rápida ou muito poder mágico. A partir do 40, alterne com o selo de comando." },
        { spellID = 20217, level = 20, en = "Your blessing from 20. Before that, Blessing of Might.",
          ptBR = "Sua bênção a partir do 20. Antes disso, a bênção de poder." },
        { spellID = 853, level = 8, en = "Stuns one enemy: time to heal, or more Judgement damage with Command.",
          ptBR = "Atordoa um inimigo: tempo para se curar, ou mais dano no julgamento com o selo de comando." },
        { spellID = 20066, level = 30, talent = true, en = "Takes one enemy out of the fight for a while. Damage breaks it.",
          ptBR = "Tira um inimigo da luta por um tempo. Dano quebra o efeito." },
        { spellID = 635, level = 2, en = "Your self heal: turn spare mana into health after a kill.",
          ptBR = "Sua cura própria: troque a mana que sobrou por vida depois de matar." },
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
          ["4"] = BLESSINGS,
          C = { normal = DEVOTION, shift = RET_AURA, alt = CONCENTRATION },
          X = UTILITY2,
        },
        [3] = {
          BUTTON4 = { normal = HOLY_STRIKE },
          BUTTON5 = { normal = JUDGEMENT },
          E = { normal = HOJ, shift = REPENTANCE, alt = TURN_UNDEAD },
          F = { normal = COMMAND, shift = SEAL_RIGHT },
          Q = { normal = CRUSADER, shift = SEAL_WISDOM, alt = SEAL_JUSTICE },
          R = { normal = EXORCISM, shift = CONSECRATION, alt = HOLY_WRATH, altshift = HOW },
          V = ITEMS,
          ["2"] = DEFENSIVE,
          ["3"] = HEALS,
          ["4"] = BLESSINGS,
          C = { normal = DEVOTION, shift = RET_AURA, alt = CONCENTRATION },
          X = UTILITY3,
        },
      },
    },
  },
}
