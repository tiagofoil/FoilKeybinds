-- Rogue guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Spells and their order: Icy Veins WoW Forever Rogue guides (leveling and rotation pages, read 2026-11-20).
-- Sinister Strike and Eviscerate are granted at level 1 on Forever (trainer data bound 6 and 8).
-- Talent levels: the Icy Veins talent calculator (10 + points needed in the tree).
-- Mutilate is the Assassination capstone (40). Its ID is 1310706, the talent rank the trainer ranks
-- (1241582 at 50, 1241584 at 60) require in the What's Training data.
-- Death Mark is the Subtlety capstone (40), so it sits only in Subtlety.
-- Templates assume the main bar page (bar paging is not followed), so the openers cast from the same keys
-- in and out of stealth. Energy spec: no castsequence (a step that fails for lack of energy blocks the key),
-- so Mouse 4 holds one plain combo builder and Mouse 5 the finisher.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HSPOT, HEAL, EAT = { item = "HSPOT" }, { item = "HEAL" }, { item = "EAT" }

local SINISTER, EVISCERATE, STEALTH, BACKSTAB = S(1752, "Sinister Strike"), S(2098, "Eviscerate"), S(1784, "Stealth"), S(53, "Backstab")
local PICK_POCKET, GOUGE, EVASION, SPRINT = S(921, "Pick Pocket"), S(1776, "Gouge"), S(5277, "Evasion"), S(2983, "Sprint")
local SND, SAP, KICK, GARROTE = S(5171, "Slice and Dice"), S(6770, "Sap"), S(1766, "Kick"), S(703, "Garrote")
local EXPOSE, FEINT, AMBUSH, RUPTURE = S(8647, "Expose Armor"), S(1966, "Feint"), S(8676, "Ambush"), S(1943, "Rupture")
local DISTRACT, VANISH, SHANK, CHEAP_SHOT = S(1725, "Distract"), S(1856, "Vanish"), S(1329283, "Shank"), S(1833, "Cheap Shot")
local KIDNEY, BLIND, PICK_LOCK = S(408, "Kidney Shot"), S(2094, "Blind"), S(1804, "Pick Lock")
local RIPOSTE, BLADE_FLURRY, ADRENALINE = T(14251, "Riposte"), T(13877, "Blade Flurry"), T(13750, "Adrenaline Rush")
local COLD_BLOOD, MUTILATE = T(14177, "Cold Blood"), T(1310706, "Mutilate")
local PREMEDITATION, GHOSTLY, PREPARATION = T(14183, "Premeditation"), T(14278, "Ghostly Strike"), T(14185, "Preparation")
local HEMORRHAGE, DEATH_MARK = T(16511, "Hemorrhage"), T(1316709, "Death Mark")

-- Home keys (docs/spec-v6.md): builder on Mouse 4 (Shank, used on cooldown, on its Shift), finisher on
-- Mouse 5, stuns and Blind on E, Slice and Dice and Rupture on F, Garrote and Expose Armor on Q, burst and
-- procs on R (Blade Flurry, the only cleave, on Shift), Stealth on C.
-- Keys every spec shares from 20 on: crowd control, buffs, interrupt, defense, stealth, consumables.
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local CC = { normal = GOUGE, shift = SAP, alt = CHEAP_SHOT, altshift = KIDNEY, ctrl = BLIND }
local FINISH = { normal = EVISCERATE }
local BUFFS = { normal = SND, shift = RUPTURE }
local BLEEDS = { normal = GARROTE, shift = EXPOSE }
local INTERRUPT = { normal = KICK }
local DEFENSE = { normal = EVASION, shift = SPRINT, alt = FEINT, altshift = VANISH }
local STEALTHY = { normal = STEALTH }
local UTILITY = { normal = PICK_POCKET, shift = DISTRACT, alt = PICK_LOCK }

local function layout(main, burst, extra)
  local t = { BUTTON4 = main, BUTTON5 = FINISH, E = CC, F = BUFFS, Q = BLEEDS, R = burst, V = ITEMS,
    ["1"] = INTERRUPT, ["2"] = DEFENSE, C = STEALTHY, X = UTILITY }
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

FoilKeybindsGuides.ROGUE = {
  suggested = 11573, -- Combat levels best: steady damage with any weapon and the only cleave (judgment: no page says it)
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    BUTTON4 = { normal = SINISTER, shift = BACKSTAB },
    BUTTON5 = FINISH,
    E = { normal = GOUGE, shift = SAP },
    F = { normal = SND },
    Q = BLEEDS,
    R = { normal = AMBUSH },
    V = ITEMS,
    ["1"] = INTERRUPT,
    ["2"] = { normal = EVASION, shift = SPRINT, alt = FEINT },
    C = STEALTHY,
    X = { normal = PICK_POCKET, alt = PICK_LOCK },
  },
  specs = {
    [11580] = {
      name = "Assassination",
      priority = {
        { spellID = 703, level = 14, en = "Opener from stealth: a bleed and a combo point. Cheap Shot instead when the mob can be stunned.",
          ptBR = "Abertura saindo da furtividade: um sangramento e um ponto de combo. Se o alvo puder ser atordoado, prefira a abertura com atordoamento." },
        { spellID = 1833, level = 26, en = "Stun opener from stealth: two combo points before the mob can hit back.",
          ptBR = "Abertura com atordoamento saindo da furtividade: dois pontos de combo antes do alvo reagir." },
        { spellID = 53, level = 4, en = "Main combo builder before 40. Needs a dagger and you behind the target.",
          ptBR = "Principal gerador de pontos de combo antes do 40. Precisa de adaga e de você atrás do alvo." },
        { spellID = 1752, level = 1, en = "Builder when you can't get behind the target.",
          ptBR = "Gerador quando você não consegue ficar atrás do alvo." },
        { spellID = 1310706, level = 40, talent = true, en = "Your builder from 40: hits with both daggers, harder on a poisoned target.",
          ptBR = "Seu gerador a partir do 40: bate com as duas adagas, mais forte num alvo envenenado." },
        { spellID = 5171, level = 10, en = "Finisher that speeds up your attacks. Use it when the fight will last.",
          ptBR = "Finalizador que acelera seus ataques. Use quando a luta for durar." },
        { spellID = 2098, level = 1, en = "Damage finisher at 5 combo points.", ptBR = "Finalizador de dano com 5 pontos de combo." },
        { spellID = 1329283, level = 24, en = "Off-hand strike that gives Energy back. Use it on cooldown, not at full Energy.",
          ptBR = "Golpe com a mão secundária que devolve Energia. Use sempre que puder, mas não com a Energia cheia." },
        { spellID = 1943, level = 20, en = "Bleed finisher for targets that will live a while.",
          ptBR = "Finalizador de sangramento para alvos que vão durar." },
        { spellID = 14177, level = 25, talent = true, en = "Your next attack is a sure critical. Use it before a 5 point Eviscerate.",
          ptBR = "Seu próximo ataque é crítico garantido. Use antes de um finalizador de dano com 5 pontos." },
        { spellID = 5277, level = 8, en = "You dodge far more for a short time. Use it often while solo.",
          ptBR = "Você se esquiva muito mais por pouco tempo. Use bastante jogando sozinho." },
        { spellID = 1766, level = 12, en = "Interrupts a spell cast.", ptBR = "Interrompe uma conjuração." },
      },
      templates = {
        [2] = layout({ normal = BACKSTAB, shift = SHANK, alt = SINISTER }, { normal = COLD_BLOOD, altshift = AMBUSH }),
        [3] = layout({ normal = MUTILATE, shift = SHANK, alt = SINISTER, altshift = BACKSTAB }, { normal = COLD_BLOOD, altshift = AMBUSH }),
      },
    },
    [11573] = {
      name = "Combat",
      priority = {
        { spellID = 1833, level = 26, en = "Stun opener from stealth: two combo points before the mob can hit back. Garrote if it can't be stunned.",
          ptBR = "Abertura com atordoamento saindo da furtividade: dois pontos de combo antes do alvo reagir. Garrote se ele não puder ser atordoado." },
        { spellID = 703, level = 14, en = "Damage opener from stealth: a bleed and a combo point.",
          ptBR = "Abertura de dano saindo da furtividade: um sangramento e um ponto de combo." },
        { spellID = 14251, level = 20, talent = true, en = "Hard hit after you parry. Use it every time it lights up.",
          ptBR = "Golpe forte depois de você aparar um ataque. Use toda vez que acender." },
        { spellID = 1752, level = 1, en = "Main combo builder.", ptBR = "Principal gerador de pontos de combo." },
        { spellID = 5171, level = 10, en = "Finisher that speeds up your attacks. Keep it up when the fight will last.",
          ptBR = "Finalizador que acelera seus ataques. Mantenha ativo quando a luta for durar." },
        { spellID = 2098, level = 1, en = "Damage finisher at 5 combo points.", ptBR = "Finalizador de dano com 5 pontos de combo." },
        { spellID = 1329283, level = 24, en = "Off-hand strike that gives Energy back. Use it on cooldown, not at full Energy.",
          ptBR = "Golpe com a mão secundária que devolve Energia. Use sempre que puder, mas não com a Energia cheia." },
        { spellID = 1943, level = 20, en = "Bleed finisher for targets that will live a while.",
          ptBR = "Finalizador de sangramento para alvos que vão durar." },
        { spellID = 13877, level = 30, talent = true, en = "Your attacks also hit a second enemy. Use it when two are close.",
          ptBR = "Seus ataques também acertam um segundo inimigo. Use quando houver dois perto." },
        { spellID = 13750, level = 40, talent = true, en = "Energy comes back much faster for 15 seconds. Use it once the fight starts.",
          ptBR = "A Energia volta bem mais rápido por 15 segundos. Use logo no começo da luta." },
        { spellID = 14177, level = 25, talent = true, en = "Sure critical on your next attack. Pair it with a 5 point Eviscerate.",
          ptBR = "Crítico garantido no próximo ataque. Combine com um finalizador de dano de 5 pontos." },
        { spellID = 5277, level = 8, en = "You dodge far more for a short time. Use it when two enemies hit you.",
          ptBR = "Você se esquiva muito mais por pouco tempo. Use quando dois inimigos baterem em você." },
        { spellID = 1766, level = 12, en = "Interrupts a spell cast.", ptBR = "Interrompe uma conjuração." },
      },
      templates = {
        [2] = layout({ normal = SINISTER, shift = SHANK, alt = BACKSTAB }, { normal = RIPOSTE, shift = BLADE_FLURRY }),
        [3] = layout({ normal = SINISTER, shift = SHANK, alt = BACKSTAB },
          { normal = RIPOSTE, shift = BLADE_FLURRY, ctrl = ADRENALINE, altshift = COLD_BLOOD }),
      },
    },
    [11572] = {
      name = "Subtlety",
      priority = {
        { spellID = 703, level = 14, en = "Your opener from stealth. Better than Ambush while leveling: no dagger, no need to be behind.",
          ptBR = "Sua abertura saindo da furtividade. Melhor que Emboscada (Ambush) para upar: sem adaga e sem ficar atrás." },
        { spellID = 16511, level = 30, talent = true, en = "Cheap builder with any weapon, from any side. Your only builder from 30.",
          ptBR = "Gerador barato com qualquer arma, de qualquer lado. Seu único gerador a partir do 30." },
        { spellID = 1752, level = 1, en = "Combo builder before 30.", ptBR = "Gerador de pontos de combo antes do 30." },
        { spellID = 53, level = 4, en = "Builder from behind with a dagger. Gouge first to get behind.",
          ptBR = "Gerador pelas costas com adaga. Incapacite o alvo antes para ficar atrás dele." },
        { spellID = 5171, level = 10, en = "Your go-to finisher before 30.", ptBR = "Seu finalizador principal antes do 30." },
        { spellID = 1943, level = 20, en = "Main finisher from 30 on targets that will live.",
          ptBR = "Finalizador principal a partir do 30 em alvos que vão durar." },
        { spellID = 1316709, level = 40, talent = true, en = "Main finisher from 40: stores your damage while it is up, then deals it.",
          ptBR = "Finalizador principal a partir do 40: guarda seu dano enquanto ativo e depois causa tudo." },
        { spellID = 1329283, level = 24, en = "Off-hand strike that gives Energy back. Use it on cooldown.",
          ptBR = "Golpe com a mão secundária que devolve Energia. Use sempre que puder." },
        { spellID = 14278, level = 25, talent = true, en = "Strong hit on cooldown, then Garrote right after.",
          ptBR = "Golpe forte sempre que puder, e logo depois o Garrote." },
        { spellID = 14183, level = 20, talent = true, en = "From stealth: adds 2 combo points before your opener.",
          ptBR = "Na furtividade: soma 2 pontos de combo antes da sua abertura." },
        { spellID = 2098, level = 1, en = "Burst finisher when the target is about to die.",
          ptBR = "Finalizador de dano rápido quando o alvo estiver quase morrendo." },
        { spellID = 14185, level = 30, talent = true, en = "Resets your cooldowns, Evasion and Vanish too. Save it for a bad pull.",
          ptBR = "Reinicia suas recargas, inclusive as de defesa e fuga. Guarde para um pull ruim." },
      },
      templates = {
        -- Hemorrhage (30) leads Mouse 4: from 20 to 29 Alt+Mouse 4 (Sinister Strike) builds.
        [2] = layout({ normal = HEMORRHAGE, shift = SHANK, alt = SINISTER, altshift = BACKSTAB },
          { normal = GHOSTLY, shift = PREMEDITATION, altshift = AMBUSH },
          { ["2"] = { normal = EVASION, shift = SPRINT, alt = FEINT, altshift = VANISH, ctrl = PREPARATION } }),
        [3] = layout({ normal = HEMORRHAGE, shift = SHANK, alt = SINISTER, altshift = BACKSTAB },
          { normal = DEATH_MARK, shift = GHOSTLY, alt = PREMEDITATION, altshift = AMBUSH },
          { F = { normal = RUPTURE, shift = SND },
            ["2"] = { normal = EVASION, shift = SPRINT, alt = FEINT, altshift = VANISH, ctrl = PREPARATION } }),
      },
    },
  },
}
