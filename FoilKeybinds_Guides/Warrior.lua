-- Warrior guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Content: Icy Veins WoW Forever leveling and rotation pages (read 2026-11-20). Talent spell IDs: the Forever
-- Warrior talent tree; talent level = the talent row's minimum level.
-- Heroic Strike is granted at level 1 on Forever (trainer data bound 8). Battle Stance (2457) is innate, so it
-- is not in the trainer data: tests/run.lua lists it in GENERAL.
-- Templates assume the main bar page (bar paging is not followed). Rage spec: no castsequence (a step that
-- fails for lack of rage blocks the key), so Mouse 4 holds one plain main attack. Overpower and Revenge are
-- procs, but the source makes them the spec's main press, so they sit on the thumb keys, not on R.
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
local SWEEPING, MORTAL_STRIKE, SPEARING = T(12292, "Sweeping Strikes"), T(12294, "Mortal Strike"), T(1310222, "Spearing Strike")
local DEATH_WISH, BLOODTHIRST = T(12328, "Death Wish"), T(23881, "Bloodthirst")
local CONCUSSION, SHIELD_SLAM, LAST_STAND = T(12809, "Concussion Blow"), T(23922, "Shield Slam"), T(12975, "Last Stand")

-- Home keys (docs/spec-v6.md): main attack on Mouse 4, second attack on Mouse 5, crowd control on E, Rend on F,
-- debuffs on Q, Execute and area on R, stances on C (the spec's main stance on the plain press).
-- Keys every spec shares from 20 on: interrupts, shouts, rage, consumables, Victory Rush.
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
  suggested = 11670, -- Protection levels best on Forever (Icy Veins): buffed Revenge, a shield and much more rage
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  -- Heroic Strike is the only attack at level 1, so it holds Mouse 4 until the spec's main attack arrives.
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
        { spellID = 12294, level = 40, talent = true, en = "Your main attack from 40. Save rage so you can use it on cooldown.",
          ptBR = "Seu ataque principal a partir do 40. Guarde raiva para usar sempre que voltar." },
        { spellID = 7384, level = 12, en = "Cheap hit that lights up after a dodge, and often on a target with your Rend. Use it before it fades.",
          ptBR = "Golpe barato que acende depois de uma esquiva, e com frequência num alvo com o seu sangramento. Use antes de apagar." },
        { spellID = 772, level = 4, en = "Bleed early in the fight. From 31 it also makes your Overpower light up more.",
          ptBR = "Sangramento no começo da luta. A partir do 31 ele também faz o seu golpe de esquiva acender mais vezes." },
        { spellID = 1240193, level = 20, en = "Weapon hit with a short cast. Use it when rage is left after the attacks above.",
          ptBR = "Golpe de arma com conjuração curta. Use quando sobrar raiva depois dos ataques acima." },
        { spellID = 12292, level = 30, talent = true, en = "Your next hits also strike a second enemy. Save rage and pull two at a time.",
          ptBR = "Seus próximos golpes também atingem um segundo inimigo. Guarde raiva e puxe dois de cada vez." },
        { spellID = 1310222, level = 25, talent = true, en = "Cheap hit, strongest against giants, dragonkin and mounted enemies.",
          ptBR = "Golpe barato, mais forte contra gigantes, dracônicos e inimigos montados." },
        { spellID = 5308, level = 24, en = "Finisher at low health. Do not empty your rage on a mob that dies anyway.",
          ptBR = "Finalizador com pouca vida. Não gaste toda a raiva num inimigo que já vai morrer." },
        { spellID = 402927, level = 20, en = "Free hit that heals you, only right after a kill. Use it before it fades.",
          ptBR = "Golpe grátis que cura você, só logo depois de matar um inimigo. Use antes de acabar." },
        { spellID = 100, level = 4, en = "Opener: rush to the target and gain rage.", ptBR = "Abertura: avance até o alvo e ganhe raiva." },
        { spellID = 78, level = 1, en = "Only with spare rage: it eats the rage your next swing would give.",
          ptBR = "Só com raiva sobrando: ele consome a raiva que o seu próximo golpe daria." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = OVERPOWER },
          BUTTON5 = { normal = SLAM, alt = HS, altshift = SPEARING },
          E = SLOWS,
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = SWEEPING, alt = CLEAVE, altshift = WHIRLWIND },
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
          BUTTON5 = { normal = OVERPOWER, shift = SLAM, alt = HS, altshift = SPEARING },
          E = SLOWS,
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = SWEEPING, alt = CLEAVE, altshift = WHIRLWIND, ctrl = RECKLESSNESS },
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
        { spellID = 1680, level = 36, en = "Your main attack from 36, even on one target. Berserker Stance only.",
          ptBR = "Seu ataque principal a partir do 36, mesmo contra um alvo só. Só na postura que você aprende no nível 30." },
        { spellID = 23881, level = 40, talent = true, en = "Second attack: use it between Whirlwinds, keeping rage for the next one.",
          ptBR = "Segundo ataque: use entre um giro e outro, guardando raiva para o próximo." },
        { spellID = 12328, level = 30, talent = true, en = "More damage for a while, but you take a bit more too. Use it on tough enemies.",
          ptBR = "Mais dano por um tempo, mas você também sofre um pouco mais. Use em inimigos difíceis." },
        { spellID = 5308, level = 24, en = "Finisher at low health. It spends all your rage.",
          ptBR = "Finalizador com pouca vida. Gasta toda a sua raiva." },
        { spellID = 18499, level = 30, en = "Breaks fear. With your talents it also gives rage and healing swings.",
          ptBR = "Quebra o medo. Com os seus talentos também dá raiva e golpes que curam." },
        { spellID = 2687, level = 10, en = "Health for rage. Space it out from your other rage buttons.",
          ptBR = "Troca vida por raiva. Use separado dos outros botões de raiva." },
        { spellID = 402927, level = 20, en = "Free hit that heals you, only right after a kill. Use it before it fades.",
          ptBR = "Golpe grátis que cura você, só logo depois de matar um inimigo. Use antes de acabar." },
        { spellID = 772, level = 4, en = "Bleed before 36, in Battle Stance. Stop using it once you learn Whirlwind.",
          ptBR = "Sangramento antes do 36, na postura inicial. Pare de usar quando aprender o giro." },
        { spellID = 7384, level = 12, en = "Before 36: use it when it lights up and you are low on rage.",
          ptBR = "Antes do 36: use quando acender e você estiver com pouca raiva." },
        { spellID = 78, level = 1, en = "Only with spare rage: keep enough for Whirlwind and Bloodthirst.",
          ptBR = "Só com raiva sobrando: guarde o bastante para os seus dois ataques principais." },
      },
      -- 20-39: Overpower on Mouse 4 (Whirlwind only comes at 36, on Mouse 5). From 40 Whirlwind takes Mouse 4.
      templates = {
        [2] = {
          BUTTON4 = { normal = OVERPOWER },
          BUTTON5 = { normal = WHIRLWIND, alt = HS },
          E = SLOWS,
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = CLEAVE, altshift = DEATH_WISH },
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
          BUTTON4 = { normal = WHIRLWIND },
          BUTTON5 = { normal = BLOODTHIRST, alt = HS },
          E = SLOWS,
          F = RENDS,
          Q = DEBUFFS,
          R = { normal = EXECUTE, shift = CLEAVE, altshift = DEATH_WISH, ctrl = RECKLESSNESS },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = { normal = BERSERKER, shift = BATTLE, alt = DEFENSIVE },
          X = CLOSERS,
          Z = TAUNTS,
        },
      },
    },
    [11670] = {
      name = "Protection",
      priority = {
        { spellID = 6572, level = 14, en = "Your main attack: cheap and strong after a block, dodge or parry. Defensive Stance.",
          ptBR = "Seu ataque principal: barato e forte depois de um bloqueio, esquiva ou aparo. Na postura defensiva." },
        { spellID = 23922, level = 40, talent = true, en = "Big shield hit from 40. Use it first, unless rage is low.",
          ptBR = "Golpe de escudo forte a partir do 40. Use primeiro, a não ser que falte raiva." },
        { spellID = 2565, level = 16, en = "Use it on cooldown against melee: less damage, more rage and more Revenge.",
          ptBR = "Use sempre que voltar contra inimigos corpo a corpo: menos dano, mais raiva e mais contra-ataques." },
        { spellID = 6343, level = 6, en = "Hits up to 4 enemies near you and slows their attacks. Your main area attack.",
          ptBR = "Atinge até 4 inimigos perto de você e deixa os ataques deles mais lentos. Seu principal ataque em área." },
        { spellID = 772, level = 4, en = "Bleed early in the fight, not on a target about to die.",
          ptBR = "Sangramento no começo da luta, não num alvo que está para morrer." },
        { spellID = 7386, level = 10, en = "Filler that lowers armor and builds threat. Full stacks only on elites and bosses.",
          ptBR = "Preenchimento que reduz a armadura e gera ameaça. Acumule tudo só em elites e chefes." },
        { spellID = 1160, level = 14, en = "Use it early in each fight: enemies hit you softer.",
          ptBR = "Use no começo de cada luta: os inimigos batem mais fraco em você." },
        { spellID = 402927, level = 20, en = "Free hit that heals you, only right after a kill. Use it before it fades.",
          ptBR = "Golpe grátis que cura você, só logo depois de matar um inimigo. Use antes de acabar." },
        { spellID = 12809, level = 30, talent = true, en = "Stuns the target for a few seconds.", ptBR = "Atordoa o alvo por alguns segundos." },
        { spellID = 12975, level = 20, talent = true, en = "Emergency: extra health for a while when a pull goes wrong.",
          ptBR = "Emergência: vida extra por um tempo quando a luta sai do controle." },
        { spellID = 355, level = 10, en = "Pulls an enemy back onto you when it turns away.",
          ptBR = "Traz de volta para você um inimigo que foi atrás de outra pessoa." },
        { spellID = 72, level = 12, en = "Interrupts a spell cast. Needs a shield.", ptBR = "Interrompe uma conjuração. Precisa de escudo." },
      },
      -- Tank: Revenge on Mouse 4 (Shield Slam from 40), Thunder Clap leads R, taunts on X, Charge on Z.
      templates = {
        [2] = {
          BUTTON4 = { normal = REVENGE },
          BUTTON5 = { normal = SUNDER, shift = HS },
          E = { normal = HAMSTRING, shift = INTIMIDATING, alt = CONCUSSION },
          F = RENDS,
          Q = { normal = DEMO_SHOUT },
          R = { normal = THUNDER_CLAP, shift = CLEAVE, altshift = EXECUTE },
          V = ITEMS,
          ["1"] = { normal = SHIELD_BASH, shift = PUMMEL },
          ["2"] = { normal = SHIELD_BLOCK, shift = SHIELD_WALL, alt = DISARM, altshift = RETALIATION, ctrl = LAST_STAND },
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = { normal = DEFENSIVE, shift = BATTLE, alt = BERSERKER },
          X = TAUNTS,
          Z = CLOSERS,
        },
        [3] = {
          BUTTON4 = { normal = SHIELD_SLAM },
          BUTTON5 = { normal = REVENGE, shift = SUNDER, alt = HS },
          E = { normal = HAMSTRING, shift = INTIMIDATING, alt = CONCUSSION },
          F = RENDS,
          Q = { normal = DEMO_SHOUT },
          R = { normal = THUNDER_CLAP, shift = CLEAVE, altshift = EXECUTE },
          V = ITEMS,
          ["1"] = { normal = SHIELD_BASH, shift = PUMMEL },
          ["2"] = { normal = SHIELD_BLOCK, shift = SHIELD_WALL, alt = DISARM, altshift = RETALIATION, ctrl = LAST_STAND },
          ["3"] = HEALS,
          ["4"] = SHOUT,
          T = RAGE,
          C = { normal = DEFENSIVE, shift = BATTLE, alt = BERSERKER },
          X = TAUNTS,
          Z = CLOSERS,
        },
      },
    },
  },
}
