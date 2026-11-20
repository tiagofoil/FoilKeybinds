-- Mage guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Fireball and Frost Armor are granted at level 1 on Forever (trainer data bound 6 and 10).
-- Ice Lance, Arcane Blast and Arcane Wrath are talents on Forever; the trainer sells their higher ranks.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HSPOT, HEAL, EAT = { item = "HSPOT" }, { item = "HEAL" }, { item = "EAT" }

local FIREBALL, FROSTBOLT, FIRE_BLAST, MISSILES = S(133, "Fireball"), S(116, "Frostbolt"), S(2136, "Fire Blast"), S(5143, "Arcane Missiles")
local NOVA, POLY, EXPLOSION, FLAMESTRIKE = S(122, "Frost Nova"), S(118, "Polymorph"), S(1449, "Arcane Explosion"), S(2120, "Flamestrike")
local FROST_ARMOR, INTELLECT, WATER, FOOD = S(168, "Frost Armor"), S(1459, "Arcane Intellect"), S(5504, "Conjure Water"), S(587, "Conjure Food")
local SLOW_FALL, DECURSE, DAMPEN, AMPLIFY = S(130, "Slow Fall"), S(475, "Remove Lesser Curse"), S(604, "Dampen Magic"), S(1008, "Amplify Magic")
local BLIZZARD, EVOCATION, MANA_SHIELD, BLINK = S(10, "Blizzard"), S(12051, "Evocation"), S(1463, "Mana Shield"), S(1953, "Blink")
local FIRE_WARD, FROST_WARD, SCORCH, COUNTER = S(543, "Fire Ward"), S(6143, "Frost Ward"), S(2948, "Scorch"), S(2139, "Counterspell")
local CONE, AGATE, ICE_ARMOR, MAGE_ARMOR = S(120, "Cone of Cold"), S(759, "Conjure Mana Agate"), S(7302, "Ice Armor"), S(6117, "Mage Armor")
local JADE, FROSTFIRE = S(3552, "Conjure Mana Jade"), S(401502, "Frostfire Bolt")
local PYRO, BLAST_WAVE, COMBUSTION = T(11366, "Pyroblast"), T(11113, "Blast Wave"), T(11129, "Combustion")
local ICE_LANCE, BARRIER = T(1312002, "Ice Lance"), T(11426, "Ice Barrier")
local ARCANE_BLAST, ARCANE_WRATH = T(400574, "Arcane Blast"), T(1326079, "Arcane Wrath")

-- Keys every spec shares from 20 on: defense on Q, control on E, wards on R, armor on F, conjures on G.
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local CONTROL = { normal = POLY, shift = DECURSE }
local ESCAPE = { normal = NOVA, shift = BLINK }
local WARDS = { normal = MANA_SHIELD, shift = FIRE_WARD, alt = FROST_WARD }
local ARMOR = { normal = FROST_ARMOR, shift = ICE_ARMOR, alt = MAGE_ARMOR }
local CONJURE2 = { normal = WATER, shift = FOOD, alt = INTELLECT, altshift = AGATE }
local CONJURE3 = { normal = WATER, shift = FOOD, alt = INTELLECT, altshift = JADE }
local EVOKE = { normal = EVOCATION, shift = SLOW_FALL }

FoilKeybindsGuides.MAGE = {
  suggested = 11601, -- Frost levels best: slows and Frost Nova keep enemies off you, so you rest less
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    ["1"] = { normal = FROSTBOLT, shift = FIREBALL },
    ["2"] = { normal = FIRE_BLAST },
    ["3"] = { normal = MISSILES },
    ["4"] = { normal = EXPLOSION, shift = FLAMESTRIKE },
    Q = { normal = NOVA },
    E = { normal = POLY, shift = DECURSE },
    T = { normal = DAMPEN, shift = AMPLIFY, alt = SLOW_FALL },
    F = { normal = FROST_ARMOR, shift = INTELLECT },
    G = { normal = WATER, shift = FOOD },
    V = ITEMS,
  },
  specs = {
    [11582] = {
      name = "Arcane",
      priority = {
        { spellID = 400574, level = 20, talent = true, en = "Main nuke. Each cast hits harder and costs more mana. Stop when mana runs low.",
          ptBR = "Ataque principal. Cada conjuração bate mais forte e custa mais mana. Pare quando a mana estiver baixa." },
        { spellID = 1326079, level = 25, talent = true, en = "Arcane nuke that grows with your maximum mana.",
          ptBR = "Ataque Arcano que fica mais forte quanto maior for a sua mana máxima." },
        { spellID = 5143, level = 8, en = "Channeled missiles. A cheaper nuke for when Arcane Blast gets too costly.",
          ptBR = "Mísseis canalizados. Ataque mais barato para quando o seu ataque principal ficar caro demais." },
        { spellID = 2136, level = 6, en = "Instant hit to finish a target or to cast on the move.",
          ptBR = "Golpe instantâneo para finalizar um alvo ou atacar andando." },
        { spellID = 122, level = 10, en = "Freezes enemies around you. Step back and keep casting.",
          ptBR = "Congela os inimigos à sua volta. Afaste-se e continue conjurando." },
        { spellID = 1449, level = 14, en = "Area damage around you for packs of weak enemies.",
          ptBR = "Dano em área à sua volta para grupos de inimigos fracos." },
        { spellID = 12051, level = 20, en = "Channel that brings back a lot of mana. Use it after a hard fight.",
          ptBR = "Canalização que devolve bastante mana. Use depois de uma luta difícil." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = ARCANE_BLAST, shift = FROSTBOLT },
          ["2"] = { normal = MISSILES, shift = FIREBALL },
          ["3"] = { normal = ARCANE_WRATH, shift = FIRE_BLAST },
          ["4"] = { normal = EXPLOSION, shift = FLAMESTRIKE, alt = BLIZZARD, altshift = CONE },
          ["5"] = { normal = COUNTER },
          Q = ESCAPE,
          E = CONTROL,
          R = WARDS,
          T = EVOKE,
          F = ARMOR,
          G = CONJURE2,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = ARCANE_BLAST, shift = FROSTBOLT, alt = FROSTFIRE },
          ["2"] = { normal = MISSILES, shift = FIREBALL },
          ["3"] = { normal = ARCANE_WRATH, shift = FIRE_BLAST },
          ["4"] = { normal = EXPLOSION, shift = FLAMESTRIKE, alt = BLIZZARD, altshift = CONE },
          ["5"] = { normal = COUNTER },
          Q = ESCAPE,
          E = CONTROL,
          R = WARDS,
          T = EVOKE,
          F = ARMOR,
          G = CONJURE3,
          V = ITEMS,
        },
      },
    },
    [11594] = {
      name = "Fire",
      priority = {
        { spellID = 11366, level = 20, talent = true, en = "Slow, heavy opener. Cast it before the enemy reaches you.",
          ptBR = "Abertura lenta e pesada. Lance antes de o inimigo chegar até você." },
        { spellID = 11129, level = 40, talent = true, en = "Cooldown that raises your Fire crit until you land a few crits. Use it on hard targets.",
          ptBR = "Recarga que aumenta o seu crítico de Fogo até você acertar alguns críticos. Use em alvos difíceis." },
        { spellID = 133, level = 1, en = "Main nuke.", ptBR = "Ataque principal." },
        { spellID = 2948, level = 22, en = "Short Fire cast. Use it when the target is almost dead.",
          ptBR = "Feitiço de Fogo de conjuração curta. Use quando o alvo estiver quase morto." },
        { spellID = 2136, level = 6, en = "Instant hit to finish a target or to cast on the move.",
          ptBR = "Golpe instantâneo para finalizar um alvo ou atacar andando." },
        { spellID = 11113, level = 30, talent = true, en = "Fire burst around you that also slows. Use it when enemies reach you.",
          ptBR = "Explosão de Fogo à sua volta que também deixa os inimigos lentos. Use quando eles chegarem perto." },
        { spellID = 2120, level = 16, en = "Area damage on the ground for packs.", ptBR = "Dano em área no chão para grupos de inimigos." },
        { spellID = 122, level = 10, en = "Freezes enemies around you. Step back and keep casting.",
          ptBR = "Congela os inimigos à sua volta. Afaste-se e continue conjurando." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = FIREBALL, shift = FROSTBOLT },
          ["2"] = { normal = FIRE_BLAST, shift = SCORCH },
          ["3"] = { normal = PYRO, shift = MISSILES },
          ["4"] = { normal = BLAST_WAVE, shift = FLAMESTRIKE, alt = EXPLOSION, altshift = CONE },
          ["5"] = { normal = COUNTER },
          Q = ESCAPE,
          E = CONTROL,
          R = WARDS,
          T = EVOKE,
          F = ARMOR,
          G = CONJURE2,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = FIREBALL, shift = FROSTBOLT, alt = FROSTFIRE },
          ["2"] = { normal = FIRE_BLAST, shift = SCORCH },
          ["3"] = { normal = PYRO, shift = COMBUSTION, alt = MISSILES },
          ["4"] = { normal = BLAST_WAVE, shift = FLAMESTRIKE, alt = EXPLOSION, altshift = CONE },
          ["5"] = { normal = COUNTER },
          Q = ESCAPE,
          E = CONTROL,
          R = WARDS,
          T = EVOKE,
          F = ARMOR,
          G = CONJURE3,
          V = ITEMS,
        },
      },
    },
    [11601] = {
      name = "Frost",
      priority = {
        { spellID = 11426, level = 40, talent = true, en = "Shield that absorbs damage. Put it up before the pull.",
          ptBR = "Escudo que absorve dano. Aplique antes de puxar." },
        { spellID = 116, level = 4, en = "Main nuke. It also slows the target.", ptBR = "Ataque principal. Também deixa o alvo lento." },
        { spellID = 122, level = 10, en = "Freezes enemies around you. Step back and keep casting.",
          ptBR = "Congela os inimigos à sua volta. Afaste-se e continue conjurando." },
        { spellID = 1312002, level = 20, talent = true, en = "Instant Frost hit that deals far more damage to a frozen target. Use it right after a freeze.",
          ptBR = "Golpe de Gelo instantâneo que causa muito mais dano num alvo congelado. Use logo depois de congelar." },
        { spellID = 2136, level = 6, en = "Instant hit to finish a target or to cast on the move.",
          ptBR = "Golpe instantâneo para finalizar um alvo ou atacar andando." },
        { spellID = 120, level = 26, en = "Frost cone in front of you that slows. Good when enemies get close.",
          ptBR = "Rajada de frio em cone à sua frente que deixa os inimigos lentos. Boa quando eles chegam perto." },
        { spellID = 10, level = 20, en = "Channeled area damage for packs.", ptBR = "Dano em área canalizado para grupos de inimigos." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = FROSTBOLT, shift = FIREBALL },
          ["2"] = { normal = ICE_LANCE, shift = FIRE_BLAST },
          ["3"] = { normal = CONE, shift = MISSILES },
          ["4"] = { normal = BLIZZARD, shift = EXPLOSION, alt = FLAMESTRIKE },
          ["5"] = { normal = COUNTER },
          Q = ESCAPE,
          E = CONTROL,
          R = WARDS,
          T = EVOKE,
          F = ARMOR,
          G = CONJURE2,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = FROSTBOLT, shift = FROSTFIRE, alt = FIREBALL },
          ["2"] = { normal = ICE_LANCE, shift = FIRE_BLAST },
          ["3"] = { normal = CONE, shift = MISSILES },
          ["4"] = { normal = BLIZZARD, shift = EXPLOSION, alt = FLAMESTRIKE },
          ["5"] = { normal = COUNTER },
          Q = ESCAPE,
          E = CONTROL,
          R = { normal = BARRIER, shift = MANA_SHIELD, alt = FIRE_WARD, altshift = FROST_WARD },
          T = EVOKE,
          F = ARMOR,
          G = CONJURE3,
          V = ITEMS,
        },
      },
    },
  },
}
