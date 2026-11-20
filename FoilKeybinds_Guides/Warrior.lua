-- Warrior guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Heroic Strike is granted at level 1 on Forever (trainer data bound 8). Battle Stance (2457) is innate, so it
-- is not in the trainer data: tests/run.lua lists it in GENERAL.
-- Templates assume the main bar page (bar paging is not followed). Rage spec: no castsequence (a step that
-- fails for lack of rage blocks the key), so Mouse 4 holds one plain main attack.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HSPOT, HEAL, EAT = { item = "HSPOT" }, { item = "HEAL" }, { item = "EAT" }

local HS, BATTLE_SHOUT, CHARGE, REND = S(78, "Heroic Strike"), S(6673, "Battle Shout"), S(100, "Charge"), S(772, "Rend")
local THUNDER_CLAP, HAMSTRING, BLOODRAGE, SHIELD_BASH = S(6343, "Thunder Clap"), S(1715, "Hamstring"), S(2687, "Bloodrage"), S(72, "Shield Bash")
local OVERPOWER, DEMO_SHOUT, MOCKING, TAUNT = S(7384, "Overpower"), S(1160, "Demoralizing Shout"), S(694, "Mocking Blow"), S(355, "Taunt")
local DEFENSIVE, SUNDER, REVENGE, SHIELD_BLOCK = S(71, "Defensive Stance"), S(7386, "Sunder Armor"), S(6572, "Revenge"), S(2565, "Shield Block")
local DISARM, SLAM, RETALIATION, VICTORY_RUSH = S(676, "Disarm"), S(1240193, "Slam"), S(20230, "Retaliation"), S(402927, "Victory Rush")
local CLEAVE, INTIMIDATING, EXECUTE, CHALLENGING = S(845, "Cleave"), S(5246, "Intimidating Shout"), S(5308, "Execute"), S(1161, "Challenging Shout")
local SHIELD_WALL, BERSERKER_RAGE, INTERCEPT, BERSERKER = S(871, "Shield Wall"), S(18499, "Berserker Rage"), S(20252, "Intercept"), S(2458, "Berserker Stance")
local WHIRLWIND, PUMMEL, RECKLESSNESS, BATTLE = S(1680, "Whirlwind"), S(6552, "Pummel"), S(1719, "Recklessness"), S(2457, "Battle Stance")
local SWEEPING, MORTAL_STRIKE = T(12292, "Sweeping Strikes"), T(12294, "Mortal Strike")
local PIERCING_HOWL, BLOODTHIRST = T(12323, "Piercing Howl"), T(23881, "Bloodthirst")
local CONCUSSION, SHIELD_SLAM = T(12809, "Concussion Blow"), T(23922, "Shield Slam")

-- Home keys (docs/spec-v6.md): main attack on Mouse 4, second attack on Mouse 5, crowd control on E, Rend on F,
-- debuffs on Q, Execute and area on R, stances on C.
-- Keys every spec shares from 20 on: interrupts, shouts, rage, stances, consumables, Victory Rush.
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local INTERRUPT = { normal = PUMMEL, shift = SHIELD_BASH }
local DEFENSE = { normal = RETALIATION, shift = DISARM }
local HEALS = { normal = VICTORY_RUSH }
local SHOUT = { normal = BATTLE_SHOUT }
local RAGE = { normal = BLOODRAGE, shift = BERSERKER_RAGE }
local STANCES = { normal = BATTLE, shift = DEFENSIVE, alt = BERSERKER }
local CLOSERS = { normal = CHARGE, shift = INTERCEPT }
local TAUNTS = { normal = TAUNT, shift = MOCKING, alt = CHALLENGING }
local DEBUFFS = { normal = SUNDER, shift = DEMO_SHOUT, alt = THUNDER_CLAP }
local SLOWS = { normal = HAMSTRING, shift = INTIMIDATING }
local RENDS = { normal = REND }

FoilKeybindsGuides.WARRIOR = {
  suggested = 11650, -- Arms levels best: big two-handed hits and the most healing from Victory Rush per kill
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    BUTTON4 = { normal = HS },
    BUTTON5 = { normal = OVERPOWER, shift = REVENGE },
    E = { normal = HAMSTRING },
    F = RENDS,
    Q = DEBUFFS,
    V = ITEMS,
    ["1"] = { normal = SHIELD_BASH },
    ["2"] = { normal = SHIELD_BLOCK, shift = DISARM },
    ["4"] = SHOUT,
    T = { normal = BLOODRAGE },
    C = { normal = BATTLE, shift = DEFENSIVE },
    X = { normal = CHARGE },
    Z = { normal = TAUNT, shift = MOCKING },
  },
  specs = {
    [11650] = {
      name = "Arms",
      priority = {
        { spellID = 100, level = 4, en = "Opener: rush to the target and gain rage.",
          ptBR = "Abertura: avance até o alvo e ganhe raiva." },
        { spellID = 772, level = 4, en = "Bleed at the start of the fight. Skip it on targets that die fast.",
          ptBR = "Sangramento no começo da luta. Pule em alvos que morrem rápido." },
        { spellID = 12294, level = 40, talent = true, en = "Your strongest hit. Use it on cooldown.",
          ptBR = "Seu golpe mais forte. Use sempre que estiver disponível." },
        { spellID = 7384, level = 12, en = "Cheap, hard hit after the target dodges. Press it when it lights up.",
          ptBR = "Golpe barato e forte depois que o alvo se esquiva. Aperte quando ele acender." },
        { spellID = 12292, level = 30, talent = true, en = "Your next hits also strike a second enemy. Use it on packs.",
          ptBR = "Seus próximos golpes também atingem um segundo inimigo. Use em grupos." },
        { spellID = 5308, level = 24, en = "Finisher for a target at low health.", ptBR = "Finalizador para um alvo com pouca vida." },
        { spellID = 78, level = 1, en = "Rage dump on your next swing when you have rage to spare.",
          ptBR = "Gasta a raiva que sobrar no seu próximo golpe." },
        { spellID = 402927, level = 20, en = "Hit that heals you, only right after a kill.",
          ptBR = "Golpe que cura você, só logo depois de matar um inimigo." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HS },
          BUTTON5 = { normal = OVERPOWER, shift = SLAM },
          E = SLOWS,
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = CLEAVE, alt = WHIRLWIND, altshift = SWEEPING },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = STANCES,
          X = CLOSERS,
          Z = TAUNTS,
        },
        [3] = {
          BUTTON4 = { normal = MORTAL_STRIKE },
          BUTTON5 = { normal = HS, shift = OVERPOWER, alt = SLAM },
          E = SLOWS,
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = CLEAVE, alt = WHIRLWIND, altshift = SWEEPING, ctrl = RECKLESSNESS },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = STANCES,
          X = CLOSERS,
          Z = TAUNTS,
        },
      },
    },
    [11657] = {
      name = "Fury",
      priority = {
        { spellID = 100, level = 4, en = "Opener: rush to the target and gain rage.",
          ptBR = "Abertura: avance até o alvo e ganhe raiva." },
        { spellID = 2687, level = 10, en = "Trades a bit of health for rage. Use it at the start of a fight.",
          ptBR = "Troca um pouco de vida por raiva. Use no começo da luta." },
        { spellID = 23881, level = 40, talent = true, en = "Your strongest hit. Use it on cooldown.",
          ptBR = "Seu golpe mais forte. Use sempre que estiver disponível." },
        { spellID = 1680, level = 36, en = "Hits every enemy close to you. Berserker Stance only.",
          ptBR = "Atinge todos os inimigos perto de você. Só funciona na postura que você aprende no nível 30." },
        { spellID = 78, level = 1, en = "Rage dump on your next swing when you have rage to spare.",
          ptBR = "Gasta a raiva que sobrar no seu próximo golpe." },
        { spellID = 5308, level = 24, en = "Finisher for a target at low health.", ptBR = "Finalizador para um alvo com pouca vida." },
        { spellID = 12323, level = 20, talent = true, en = "Slows every enemy around you. Use it on runners and packs.",
          ptBR = "Deixa lentos todos os inimigos à sua volta. Use em quem foge e em grupos." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HS },
          BUTTON5 = { normal = OVERPOWER, shift = SLAM },
          E = { normal = HAMSTRING, shift = INTIMIDATING, alt = PIERCING_HOWL },
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = WHIRLWIND, alt = CLEAVE },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = STANCES,
          X = CLOSERS,
          Z = TAUNTS,
        },
        [3] = {
          BUTTON4 = { normal = BLOODTHIRST },
          BUTTON5 = { normal = HS, shift = OVERPOWER, alt = SLAM },
          E = { normal = HAMSTRING, shift = INTIMIDATING, alt = PIERCING_HOWL },
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = WHIRLWIND, alt = CLEAVE, ctrl = RECKLESSNESS },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = STANCES,
          X = CLOSERS,
          Z = TAUNTS,
        },
      },
    },
    [11670] = {
      name = "Protection",
      priority = {
        { spellID = 2565, level = 16, en = "Blocks the next hits. A block also lets you use Revenge.",
          ptBR = "Bloqueia os próximos golpes. Um bloqueio também libera o seu contra-ataque." },
        { spellID = 6572, level = 14, en = "Cheap counterattack with high threat after a block, dodge or parry.",
          ptBR = "Contra-ataque barato com muita ameaça depois de um bloqueio, esquiva ou aparo." },
        { spellID = 23922, level = 40, talent = true, en = "Strong shield hit with high threat. Use it on cooldown.",
          ptBR = "Golpe de escudo forte com muita ameaça. Use sempre que estiver disponível." },
        { spellID = 7386, level = 10, en = "Lowers armor and builds threat. Stack it up to 5 times.",
          ptBR = "Reduz a armadura e gera ameaça. Acumule até 5 vezes." },
        { spellID = 6343, level = 6, en = "Hits up to 4 enemies near you and makes them attack more slowly. Use it on packs.",
          ptBR = "Atinge até 4 inimigos perto de você e faz eles atacarem mais devagar. Use em grupos." },
        { spellID = 12809, level = 30, talent = true, en = "Stuns the target for a few seconds.", ptBR = "Atordoa o alvo por alguns segundos." },
        { spellID = 355, level = 10, en = "Forces the target to attack you. Use it when an enemy turns to someone else.",
          ptBR = "Força o alvo a atacar você. Use quando um inimigo largar você e for atrás de outra pessoa." },
        { spellID = 72, level = 12, en = "Interrupts a spell cast. Needs a shield.", ptBR = "Interrompe uma conjuração. Precisa de escudo." },
      },
      -- Tank: Sunder is the main press, taunts sit on X (the closer utility key), Charge on Z.
      templates = {
        [2] = {
          BUTTON4 = { normal = SUNDER },
          BUTTON5 = { normal = REVENGE, shift = HS },
          E = SLOWS,
          F = RENDS,
          Q = { normal = DEMO_SHOUT, shift = THUNDER_CLAP },
          R = { normal = EXECUTE, shift = CLEAVE },
          V = ITEMS,
          ["1"] = { normal = SHIELD_BASH, shift = PUMMEL },
          ["2"] = { normal = SHIELD_BLOCK, shift = SHIELD_WALL, alt = DISARM, altshift = RETALIATION },
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = STANCES,
          X = TAUNTS,
          Z = CLOSERS,
        },
        [3] = {
          BUTTON4 = { normal = SUNDER },
          BUTTON5 = { normal = REVENGE, shift = HS },
          E = { normal = HAMSTRING, shift = INTIMIDATING, alt = CONCUSSION },
          F = RENDS,
          Q = { normal = DEMO_SHOUT, shift = THUNDER_CLAP },
          R = { normal = SHIELD_SLAM, shift = CLEAVE, altshift = EXECUTE },
          V = ITEMS,
          ["1"] = { normal = SHIELD_BASH, shift = PUMMEL },
          ["2"] = { normal = SHIELD_BLOCK, shift = SHIELD_WALL, alt = DISARM, altshift = RETALIATION },
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = STANCES,
          X = TAUNTS,
          Z = CLOSERS,
        },
      },
    },
  },
}
