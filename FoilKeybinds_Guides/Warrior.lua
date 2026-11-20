-- Warrior guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Heroic Strike is granted at level 1 on Forever (trainer data bound 8).
-- Templates assume the main bar page (bar paging is not followed). Defensive and Berserker Stance sit on F.
-- Battle Stance (2457) is innate, so it is not in the trainer data and no template can hold it: switch back
-- to it from the game's stance bar.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local POT, BAND = { item = "POT" }, { item = "BAND" }

local HS, BATTLE_SHOUT, CHARGE, REND = S(78, "Heroic Strike"), S(6673, "Battle Shout"), S(100, "Charge"), S(772, "Rend")
local THUNDER_CLAP, HAMSTRING, BLOODRAGE, SHIELD_BASH = S(6343, "Thunder Clap"), S(1715, "Hamstring"), S(2687, "Bloodrage"), S(72, "Shield Bash")
local OVERPOWER, DEMO_SHOUT, MOCKING, TAUNT = S(7384, "Overpower"), S(1160, "Demoralizing Shout"), S(694, "Mocking Blow"), S(355, "Taunt")
local DEFENSIVE, SUNDER, REVENGE, SHIELD_BLOCK = S(71, "Defensive Stance"), S(7386, "Sunder Armor"), S(6572, "Revenge"), S(2565, "Shield Block")
local DISARM, SLAM, RETALIATION, VICTORY_RUSH = S(676, "Disarm"), S(1240193, "Slam"), S(20230, "Retaliation"), S(402927, "Victory Rush")
local CLEAVE, INTIMIDATING, EXECUTE, CHALLENGING = S(845, "Cleave"), S(5246, "Intimidating Shout"), S(5308, "Execute"), S(1161, "Challenging Shout")
local SHIELD_WALL, BERSERKER_RAGE, INTERCEPT, BERSERKER = S(871, "Shield Wall"), S(18499, "Berserker Rage"), S(20252, "Intercept"), S(2458, "Berserker Stance")
local WHIRLWIND, PUMMEL, RECKLESSNESS = S(1680, "Whirlwind"), S(6552, "Pummel"), S(1719, "Recklessness")
local SWEEPING, MORTAL_STRIKE = T(12292, "Sweeping Strikes"), T(12294, "Mortal Strike")
local PIERCING_HOWL, BLOODTHIRST = T(12323, "Piercing Howl"), T(23881, "Bloodthirst")
local CONCUSSION, SHIELD_SLAM = T(12809, "Concussion Blow"), T(23922, "Shield Slam")

-- Keys every spec shares from 20 on: gap closers on Q, shouts on E, rage on R, stances on F.
local ITEMS = { normal = POT, shift = BAND }
local CLOSERS = { normal = CHARGE, shift = INTERCEPT, alt = PUMMEL }
local SHOUTS = { normal = BATTLE_SHOUT, shift = DEMO_SHOUT, alt = INTIMIDATING, altshift = CHALLENGING }
local RAGE2 = { normal = BLOODRAGE, shift = BERSERKER_RAGE, alt = RETALIATION }
local RAGE3 = { normal = BLOODRAGE, shift = BERSERKER_RAGE, alt = RETALIATION, altshift = RECKLESSNESS }
local STANCES = { normal = DEFENSIVE, shift = BERSERKER, alt = DISARM, altshift = SHIELD_BLOCK }
local THREAT = { normal = SUNDER, shift = TAUNT, alt = SHIELD_BASH }
local FINISH = { normal = EXECUTE, shift = VICTORY_RUSH }

FoilKeybindsGuides.WARRIOR = {
  suggested = 11650, -- Arms levels best: big two-handed hits and the most healing from Victory Rush per kill
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    ["1"] = { normal = HS, shift = SUNDER },
    ["2"] = { normal = REND, shift = REVENGE },
    ["3"] = { normal = OVERPOWER, shift = SHIELD_BASH },
    ["4"] = { normal = THUNDER_CLAP, shift = TAUNT },
    ["5"] = { normal = HAMSTRING, shift = MOCKING },
    Q = { normal = CHARGE },
    E = { normal = BATTLE_SHOUT, shift = DEMO_SHOUT },
    R = { normal = BLOODRAGE },
    F = { normal = DEFENSIVE, shift = SHIELD_BLOCK, alt = DISARM },
    V = ITEMS,
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
          ["1"] = { normal = HS, shift = CLEAVE },
          ["2"] = { normal = REND, shift = HAMSTRING },
          ["3"] = { normal = OVERPOWER, shift = SLAM },
          ["4"] = FINISH,
          ["5"] = { normal = SWEEPING, shift = THUNDER_CLAP },
          Q = CLOSERS,
          E = SHOUTS,
          R = RAGE2,
          T = THREAT,
          F = STANCES,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = MORTAL_STRIKE, shift = SLAM },
          ["2"] = { normal = HS, shift = CLEAVE },
          ["3"] = { normal = OVERPOWER, shift = REND, alt = HAMSTRING },
          ["4"] = FINISH,
          ["5"] = { normal = SWEEPING, shift = THUNDER_CLAP, alt = WHIRLWIND },
          Q = CLOSERS,
          E = SHOUTS,
          R = RAGE3,
          T = THREAT,
          F = STANCES,
          V = ITEMS,
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
          ["1"] = { normal = HS, shift = CLEAVE },
          ["2"] = { normal = REND, shift = HAMSTRING },
          ["3"] = { normal = OVERPOWER, shift = SLAM },
          ["4"] = FINISH,
          ["5"] = { normal = WHIRLWIND, shift = THUNDER_CLAP, alt = PIERCING_HOWL },
          Q = CLOSERS,
          E = SHOUTS,
          R = RAGE2,
          T = THREAT,
          F = STANCES,
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = BLOODTHIRST, shift = SLAM },
          ["2"] = { normal = HS, shift = CLEAVE },
          ["3"] = { normal = WHIRLWIND, shift = OVERPOWER },
          ["4"] = FINISH,
          ["5"] = { normal = PIERCING_HOWL, shift = THUNDER_CLAP, alt = HAMSTRING },
          Q = CLOSERS,
          E = SHOUTS,
          R = RAGE3,
          T = THREAT,
          F = STANCES,
          V = ITEMS,
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
        { spellID = 6343, level = 6, en = "Hits and slows every enemy near you. Use it on packs.",
          ptBR = "Atinge e deixa lentos os inimigos perto de você. Use em grupos." },
        { spellID = 12809, level = 30, talent = true, en = "Stuns the target for a few seconds.", ptBR = "Atordoa o alvo por alguns segundos." },
        { spellID = 355, level = 10, en = "Forces the target to attack you. Use it when an enemy turns to someone else.",
          ptBR = "Força o alvo a atacar você. Use quando um inimigo largar você e for atrás de outra pessoa." },
        { spellID = 72, level = 12, en = "Interrupts a spell cast. Needs a shield.", ptBR = "Interrompe uma conjuração. Precisa de escudo." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = SUNDER, shift = HS },
          ["2"] = { normal = REVENGE, shift = CLEAVE },
          ["3"] = { normal = SHIELD_BLOCK, shift = SHIELD_BASH },
          ["4"] = { normal = THUNDER_CLAP, shift = DEMO_SHOUT },
          ["5"] = { normal = CONCUSSION, shift = REND, alt = HAMSTRING },
          Q = CLOSERS,
          E = { normal = BATTLE_SHOUT, shift = INTIMIDATING, alt = CHALLENGING },
          R = { normal = TAUNT, shift = MOCKING },
          T = RAGE2,
          F = { normal = DEFENSIVE, shift = BERSERKER, alt = DISARM, altshift = SHIELD_WALL },
          G = { normal = VICTORY_RUSH, shift = EXECUTE, alt = OVERPOWER },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = SUNDER, shift = HS },
          ["2"] = { normal = SHIELD_SLAM, shift = CLEAVE },
          ["3"] = { normal = REVENGE, shift = SHIELD_BASH },
          ["4"] = { normal = SHIELD_BLOCK, shift = CONCUSSION },
          ["5"] = { normal = THUNDER_CLAP, shift = DEMO_SHOUT },
          Q = CLOSERS,
          E = { normal = BATTLE_SHOUT, shift = INTIMIDATING, alt = CHALLENGING },
          R = { normal = TAUNT, shift = MOCKING },
          T = RAGE3,
          F = { normal = DEFENSIVE, shift = BERSERKER, alt = DISARM, altshift = SHIELD_WALL },
          G = { normal = VICTORY_RUSH, shift = EXECUTE, alt = OVERPOWER },
          V = ITEMS,
        },
      },
    },
  },
}
