-- Rogue guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Sinister Strike and Eviscerate are granted at level 1 on Forever (trainer data bound 6 and 8).
-- Mutilate is 1241582, the rank the trainer sells at 50: the talent rank (1310706) has no Forever page, so
-- the row carries the trainer level, as Druid.lua does for Claw.
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
local KIDNEY, BLIND, MUTILATE = S(408, "Kidney Shot"), S(2094, "Blind"), S(1241582, "Mutilate")
local PREMEDITATION, HEMORRHAGE, DEATH_MARK = T(14183, "Premeditation"), T(16511, "Hemorrhage"), T(1316709, "Death Mark")

-- Home keys (docs/spec-v6.md): builder on Mouse 4, finisher on Mouse 5, stuns and Blind on E, Slice and Dice
-- on F, Garrote and Expose Armor on Q, Ambush on R, Stealth on C.
-- Keys every spec shares from 20 on: crowd control, buffs, interrupt, defense, stealth, consumables.
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local CC = { normal = GOUGE, shift = SAP, alt = CHEAP_SHOT, altshift = KIDNEY, ctrl = BLIND }
local SND_KEY = { normal = SND }
local BLEEDS = { normal = GARROTE, shift = EXPOSE }
local INTERRUPT = { normal = KICK }
local DEFENSE = { normal = EVASION, shift = SPRINT, alt = FEINT, altshift = VANISH }
local STEALTHY = { normal = STEALTH }
local UTILITY = { normal = PICK_POCKET, shift = DISTRACT }

-- Combat and Subtlety get no new verified spell after 39, so one layout covers 20-60.
local COMBAT = {
  BUTTON4 = { normal = SINISTER, shift = BACKSTAB, alt = SHANK },
  BUTTON5 = { normal = EVISCERATE, shift = RUPTURE },
  E = CC,
  F = SND_KEY,
  Q = BLEEDS,
  R = { normal = AMBUSH },
  V = ITEMS,
  ["1"] = INTERRUPT,
  ["2"] = DEFENSE,
  C = STEALTHY,
  X = UTILITY,
}
local SUBTLETY = {
  BUTTON4 = { normal = HEMORRHAGE, shift = SINISTER, alt = BACKSTAB, altshift = SHANK },
  BUTTON5 = { normal = EVISCERATE, shift = RUPTURE },
  E = CC,
  F = SND_KEY,
  Q = BLEEDS,
  R = { normal = AMBUSH, shift = PREMEDITATION },
  V = ITEMS,
  ["1"] = INTERRUPT,
  ["2"] = DEFENSE,
  C = STEALTHY,
  X = UTILITY,
}

FoilKeybindsGuides.ROGUE = {
  suggested = 11573, -- Combat levels best: steady damage with any weapon and fewer misses
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  shared = {
    BUTTON4 = { normal = SINISTER, shift = BACKSTAB },
    BUTTON5 = { normal = EVISCERATE },
    E = { normal = GOUGE, shift = SAP },
    F = SND_KEY,
    Q = { normal = GARROTE },
    R = { normal = AMBUSH },
    V = ITEMS,
    ["1"] = INTERRUPT,
    ["2"] = { normal = EVASION, shift = SPRINT, alt = FEINT },
    C = STEALTHY,
    X = { normal = PICK_POCKET },
  },
  specs = {
    [11580] = {
      name = "Assassination",
      priority = {
        { spellID = 703, level = 14, en = "Opener from stealth, behind the target: a long bleed and a combo point.",
          ptBR = "Abertura saindo da furtividade, pelas costas do alvo: um sangramento longo e um ponto de combo." },
        { spellID = 1752, level = 1, en = "Main combo builder. Works from any side.",
          ptBR = "Principal gerador de pontos de combo. Funciona de qualquer lado do alvo." },
        { spellID = 1241582, level = 50, en = "Strong builder with both weapons, better on a poisoned target. It comes from a talent.",
          ptBR = "Gerador forte com as duas armas, melhor num alvo envenenado. Vem de um talento." },
        { spellID = 5171, level = 10, en = "Short finisher that speeds up your attacks. Keep it up.",
          ptBR = "Finalizador curto que acelera seus ataques. Mantenha ativo." },
        { spellID = 1943, level = 20, en = "Bleed finisher for targets that will live a while.",
          ptBR = "Finalizador de sangramento para alvos que vão durar." },
        { spellID = 1316709, level = 40, talent = true, en = "Finisher that stores part of your damage and deals it later. Bleeds count double.",
          ptBR = "Finalizador que guarda parte do seu dano e causa tudo depois. Sangramentos contam em dobro." },
        { spellID = 2098, level = 1, en = "Direct finisher. Use it when the target is about to die.",
          ptBR = "Finalizador direto. Use quando o alvo estiver quase morrendo." },
        { spellID = 1766, level = 12, en = "Interrupts a spell cast.", ptBR = "Interrompe uma conjuração." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = SINISTER, shift = BACKSTAB, alt = SHANK },
          BUTTON5 = { normal = RUPTURE, shift = EVISCERATE },
          E = CC,
          F = SND_KEY,
          Q = BLEEDS,
          R = { normal = AMBUSH },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          C = STEALTHY,
          X = UTILITY,
        },
        [3] = {
          BUTTON4 = { normal = SINISTER, shift = MUTILATE, alt = BACKSTAB, altshift = SHANK },
          BUTTON5 = { normal = RUPTURE, shift = EVISCERATE },
          E = CC,
          F = SND_KEY,
          Q = BLEEDS,
          R = { normal = DEATH_MARK, shift = AMBUSH },
          V = ITEMS,
          ["1"] = INTERRUPT,
          ["2"] = DEFENSE,
          C = STEALTHY,
          X = UTILITY,
        },
      },
    },
    [11573] = {
      name = "Combat",
      priority = {
        { spellID = 1833, level = 26, en = "Opener from stealth: stuns the target and gives combo points.",
          ptBR = "Abertura saindo da furtividade: atordoa o alvo e dá pontos de combo." },
        { spellID = 1752, level = 1, en = "Main combo builder.", ptBR = "Principal gerador de pontos de combo." },
        { spellID = 5171, level = 10, en = "Finisher that speeds up your attacks. Put it up first, even at 1 or 2 points.",
          ptBR = "Finalizador que acelera seus ataques. Aplique primeiro, mesmo com 1 ou 2 pontos." },
        { spellID = 2098, level = 1, en = "Damage finisher. Spend your points here while Slice and Dice is up.",
          ptBR = "Finalizador de dano. Gaste seus pontos aqui enquanto o bônus de velocidade estiver ativo." },
        { spellID = 1329283, level = 24, en = "Off-hand strike that gives Energy back. Use it when it is ready.",
          ptBR = "Golpe com a mão secundária que devolve Energia. Use sempre que estiver disponível." },
        { spellID = 1766, level = 12, en = "Interrupts a spell cast.", ptBR = "Interrompe uma conjuração." },
        { spellID = 5277, level = 8, en = "You dodge far more for a short time. Use it when two enemies hit you.",
          ptBR = "Você se esquiva muito mais por pouco tempo. Use quando dois inimigos baterem em você." },
      },
      templates = { [2] = COMBAT, [3] = COMBAT },
    },
    [11572] = {
      name = "Subtlety",
      priority = {
        { spellID = 14183, level = 20, talent = true, en = "From stealth: adds 2 combo points before your opener.",
          ptBR = "Na furtividade: soma 2 pontos de combo antes da sua abertura." },
        { spellID = 8676, level = 18, en = "Big opener from stealth, behind the target. Needs a dagger.",
          ptBR = "Abertura forte saindo da furtividade, pelas costas do alvo. Precisa de adaga." },
        { spellID = 16511, level = 30, talent = true, en = "Main combo builder from 30 on. Your bleeds hurt more after it.",
          ptBR = "Principal gerador de pontos de combo a partir do nível 30. Seus sangramentos causam mais dano depois dele." },
        { spellID = 1752, level = 1, en = "Combo builder before 30.", ptBR = "Gerador de pontos de combo antes do nível 30." },
        { spellID = 5171, level = 10, en = "Finisher that speeds up your attacks. Keep it up.",
          ptBR = "Finalizador que acelera seus ataques. Mantenha ativo." },
        { spellID = 1943, level = 20, en = "Bleed finisher for targets that will live a while.",
          ptBR = "Finalizador de sangramento para alvos que vão durar." },
        { spellID = 2098, level = 1, en = "Direct finisher. Use it when the target is about to die.",
          ptBR = "Finalizador direto. Use quando o alvo estiver quase morrendo." },
      },
      templates = { [2] = SUBTLETY, [3] = SUBTLETY },
    },
  },
}
