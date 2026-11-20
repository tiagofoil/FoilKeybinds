-- Druid guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Rip, Prowl and Maul come with Cat and Bear Form on Forever (granted in the trainer data): their rows carry the
-- real level from wowhead.com/forever. Claw is 3029: What's Training ties its ranks to a Feral talent.
-- Prowl's granted bound is 40, so it only fits the 40-60 templates. Templates assume the main bar page.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local POT, BAND = { item = "POT" }, { item = "BAND" }

local WRATH, MOONFIRE, REJUV, THORNS = S(5176, "Wrath"), S(8921, "Moonfire"), S(774, "Rejuvenation"), S(467, "Thorns")
local HT, ROOTS, MOTW, BEAR = S(5185, "Healing Touch"), S(339, "Entangling Roots"), S(1126, "Mark of the Wild"), S(5487, "Bear Form")
local DEMO, MAUL, GRASP, REGROWTH = S(99, "Demoralizing Roar"), S(6807, "Maul"), S(16689, "Nature's Grasp"), S(8936, "Regrowth")
local ENRAGE, BASH, SWIPE, FF = S(5229, "Enrage"), S(5211, "Bash"), S(779, "Swipe"), S(770, "Faerie Fire")
local HIBERNATE, CURE_POISON, AQUATIC, CAT = S(2637, "Hibernate"), S(8946, "Cure Poison"), S(1066, "Aquatic Form"), S(768, "Cat Form")
local SHRED, RIP, STARFIRE, REBIRTH = S(5221, "Shred"), S(1079, "Rip"), S(2912, "Starfire"), S(20484, "Rebirth")
local PROWL, RAKE, BITE, REMOVE_CURSE = S(5215, "Prowl"), S(1822, "Rake"), S(1328618, "Ferocious Bite"), S(2782, "Remove Curse")
local DASH, ABOLISH, CLAW, COWER = S(1850, "Dash"), S(2893, "Abolish Poison"), S(3029, "Claw"), S(8998, "Cower")
local TRANQ, TRAVEL, RAVAGE, POUNCE = S(740, "Tranquility"), S(783, "Travel Form"), S(6785, "Ravage"), S(9005, "Pounce")
local FRENZIED, HURRICANE, INNERVATE = S(22842, "Frenzied Regeneration"), S(16914, "Hurricane"), S(29166, "Innervate")
local DIRE_BEAR, BARKSKIN, CHALLENGING = S(9634, "Dire Bear Form"), S(22812, "Barkskin"), S(5209, "Challenging Roar")
local INSECT, MOONKIN = T(5570, "Insect Swarm"), T(24858, "Moonkin Form")
local PRIMAL_BITE, WILD_GROWTH = T(407995, "Primal Bite"), T(408120, "Wild Growth")

local ITEMS = { normal = POT, shift = BAND }

FoilKeybindsGuides.DRUID = {
  suggested = 11347, -- Feral levels best: cat damage with no mana to drink back, bear for the hard pulls
  tested = false,
  -- Levels 1-19, every spec: caster spells on plain keys, bear spells on Shift.
  shared = {
    ["1"] = { normal = WRATH, shift = MAUL },
    ["2"] = { normal = MOONFIRE, shift = SWIPE },
    ["3"] = { normal = ROOTS, shift = FF, alt = HIBERNATE },
    ["4"] = { normal = DEMO, shift = BASH },
    Q = { normal = HT, shift = REGROWTH },
    E = { normal = REJUV, shift = CURE_POISON },
    R = { normal = BEAR, shift = ENRAGE, alt = AQUATIC },
    F = { normal = MOTW, shift = THORNS, alt = GRASP },
    V = ITEMS,
  },
  specs = {
    [11328] = {
      name = "Balance",
      priority = {
        { spellID = 8921, level = 4, en = "Opening DoT. Put it on the target first, then cast your nukes.",
          ptBR = "DoT de abertura. Aplique primeiro no alvo e depois use seus ataques principais." },
        { spellID = 5570, level = 20, talent = true, en = "Nature DoT that also makes the target miss more. Keep it up on longer fights.",
          ptBR = "DoT de Natureza que também faz o alvo errar mais. Mantenha ativo em lutas mais longas." },
        { spellID = 2912, level = 20, en = "Slow, heavy nuke. Your main damage from 20 on.",
          ptBR = "Ataque lento e pesado. Seu dano principal a partir do nível 20." },
        { spellID = 5176, level = 1, en = "Fast nuke. Your main damage before 20, later a quick finisher.",
          ptBR = "Ataque rápido. Seu dano principal antes do nível 20 e, depois, um jeito rápido de finalizar." },
        { spellID = 24858, level = 40, talent = true, en = "Form that adds armor and crit for the group. Stay in it while you deal damage.",
          ptBR = "Forma que dá armadura e crítico para o grupo. Fique nela enquanto causa dano." },
        { spellID = 339, level = 8, en = "Roots a melee enemy so you can keep casting from range.",
          ptBR = "Prende um inimigo corpo a corpo no lugar para você continuar atacando de longe." },
        { spellID = 16914, level = 40, en = "Channeled area damage for packs of enemies.",
          ptBR = "Dano em área canalizado para grupos de inimigos." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = STARFIRE, shift = WRATH },
          ["2"] = { normal = MOONFIRE },
          ["3"] = { normal = INSECT },
          ["4"] = { normal = ROOTS, shift = HIBERNATE, alt = GRASP },
          ["5"] = { normal = FF },
          Q = { normal = HT, shift = REGROWTH },
          E = { normal = REJUV, shift = REMOVE_CURSE, alt = ABOLISH },
          R = { normal = BEAR, shift = CAT, alt = TRAVEL, altshift = AQUATIC },
          F = { normal = MOTW, shift = THORNS },
          G = { normal = REBIRTH },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = STARFIRE, shift = WRATH },
          ["2"] = { normal = MOONFIRE },
          ["3"] = { normal = INSECT },
          ["4"] = { normal = ROOTS, shift = HIBERNATE, alt = GRASP },
          ["5"] = { normal = FF },
          Q = { normal = HT, shift = REGROWTH },
          E = { normal = REJUV, shift = REMOVE_CURSE, alt = ABOLISH },
          R = { normal = MOONKIN, shift = DIRE_BEAR, alt = TRAVEL, altshift = CAT },
          T = { normal = HURRICANE },
          F = { normal = MOTW, shift = THORNS },
          G = { normal = INNERVATE, shift = REBIRTH },
          C = { normal = BARKSKIN },
          V = ITEMS,
        },
      },
    },
    [11347] = {
      name = "Feral Combat",
      priority = {
        { spellID = 5215, level = 20, en = "Stealth before the pull, then open from behind.",
          ptBR = "Furtividade antes do combate, para abrir pelas costas do alvo." },
        { spellID = 6785, level = 32, en = "Big opener from stealth, behind the target.",
          ptBR = "Abertura forte saindo da furtividade, pelas costas do alvo." },
        { spellID = 1822, level = 24, en = "Bleed plus a combo point. Put it on first.",
          ptBR = "Sangramento mais um ponto de combo. Aplique primeiro." },
        { spellID = 3029, level = 28, en = "Main combo builder. On Forever it needs a Feral talent.",
          ptBR = "Principal gerador de pontos de combo. No Forever, depende de um talento Feral." },
        { spellID = 5221, level = 20, en = "Stronger builder, only from behind the target.",
          ptBR = "Gerador mais forte, só funciona pelas costas do alvo." },
        { spellID = 1079, level = 20, en = "Bleed finisher. Use it at 3 to 5 combo points on targets that live a while.",
          ptBR = "Finalizador de sangramento. Use com 3 a 5 pontos de combo em alvos que vão durar." },
        { spellID = 1328618, level = 24, en = "Direct finisher. Use it when the target is about to die.",
          ptBR = "Finalizador direto. Use quando o alvo estiver quase morrendo." },
        { spellID = 407995, level = 40, talent = true, en = "Bear form: a strong hit that holds threat. Use it when you tank.",
          ptBR = "Na forma de urso: golpe forte que segura a ameaça. Use quando estiver tanqueando." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = CLAW, shift = MAUL },
          ["2"] = { normal = RAKE, shift = SWIPE },
          ["3"] = { normal = RIP, shift = DEMO },
          ["4"] = { normal = BITE, shift = BASH },
          ["5"] = { normal = SHRED },
          Q = { normal = HT, shift = REGROWTH, alt = REJUV },
          E = { normal = FF, shift = ENRAGE, alt = COWER, altshift = FRENZIED },
          R = { normal = CAT, shift = BEAR, alt = TRAVEL, altshift = AQUATIC },
          F = { normal = DASH, shift = ROOTS, alt = HIBERNATE },
          T = { normal = MOTW, shift = THORNS, alt = GRASP },
          G = { normal = REMOVE_CURSE, shift = ABOLISH, alt = REBIRTH },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = CLAW, shift = MAUL },
          ["2"] = { normal = RAKE, shift = SWIPE },
          ["3"] = { normal = RIP, shift = DEMO },
          ["4"] = { normal = BITE, shift = BASH, alt = PRIMAL_BITE },
          ["5"] = { normal = SHRED, shift = RAVAGE, alt = POUNCE },
          Q = { normal = HT, shift = REGROWTH, alt = REJUV },
          E = { normal = FF, shift = ENRAGE, alt = COWER, altshift = FRENZIED },
          R = { normal = CAT, shift = DIRE_BEAR, alt = TRAVEL, altshift = AQUATIC },
          F = { normal = PROWL, shift = DASH, alt = ROOTS, altshift = HIBERNATE },
          T = { normal = MOTW, shift = THORNS, alt = GRASP },
          G = { normal = REMOVE_CURSE, shift = ABOLISH, alt = REBIRTH, altshift = INNERVATE },
          C = { normal = BARKSKIN, shift = CHALLENGING },
          V = ITEMS,
        },
      },
    },
    [11340] = {
      name = "Restoration",
      priority = {
        { spellID = 774, level = 4, en = "Heal over time. Put it on whoever takes damage first.",
          ptBR = "Cura ao longo do tempo. Aplique primeiro em quem estiver tomando dano." },
        { spellID = 8936, level = 12, en = "Quick heal plus a heal over time. Your main heal on the tank.",
          ptBR = "Cura rápida mais uma cura ao longo do tempo. Sua cura principal no tanque." },
        { spellID = 5185, level = 1, en = "Big, slow heal. Use it when there is time to cast.",
          ptBR = "Cura grande e lenta. Use quando der tempo de conjurar." },
        { spellID = 408120, level = 40, talent = true, en = "Heals the whole party over time. Use it when several people take damage.",
          ptBR = "Cura o grupo todo ao longo do tempo. Use quando várias pessoas tomarem dano." },
        { spellID = 740, level = 30, en = "Channeled group heal for emergencies. Stand still while it runs.",
          ptBR = "Cura em grupo canalizada para emergências. Fique parado enquanto ela dura." },
        { spellID = 29166, level = 40, en = "Gives a lot of mana back. Use it on yourself when you run low.",
          ptBR = "Devolve bastante mana. Use em você quando a mana estiver acabando." },
        { spellID = 2893, level = 26, en = "Removes poison over a few seconds.", ptBR = "Remove veneno ao longo de alguns segundos." },
        { spellID = 8921, level = 4, en = "Solo damage: DoT first, then your nukes.",
          ptBR = "Dano sozinho: aplique o DoT primeiro e depois ataque." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = WRATH, shift = STARFIRE },
          ["2"] = { normal = MOONFIRE },
          ["3"] = { normal = ROOTS, shift = HIBERNATE },
          ["4"] = { normal = FF },
          Q = { normal = REJUV },
          E = { normal = REGROWTH },
          R = { normal = HT, shift = TRANQ },
          F = { normal = REMOVE_CURSE, shift = ABOLISH },
          T = { normal = MOTW, shift = THORNS, alt = GRASP },
          G = { normal = REBIRTH },
          C = { normal = BEAR, shift = CAT, alt = TRAVEL, altshift = AQUATIC },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = WRATH, shift = STARFIRE },
          ["2"] = { normal = MOONFIRE },
          ["3"] = { normal = ROOTS, shift = HIBERNATE },
          ["4"] = { normal = FF, shift = BARKSKIN },
          Q = { normal = REJUV },
          E = { normal = REGROWTH, shift = WILD_GROWTH },
          R = { normal = HT, shift = TRANQ },
          F = { normal = REMOVE_CURSE, shift = ABOLISH },
          T = { normal = MOTW, shift = THORNS, alt = GRASP },
          G = { normal = INNERVATE, shift = REBIRTH },
          C = { normal = DIRE_BEAR, shift = CAT, alt = TRAVEL, altshift = AQUATIC },
          V = ITEMS,
        },
      },
    },
  },
}
