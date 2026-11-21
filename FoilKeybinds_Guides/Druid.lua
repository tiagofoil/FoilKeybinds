-- Druid guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Source: Icy Veins WoW Forever Balance, Feral and Restoration guides (leveling and rotation pages, read 2026-11-20).
-- Talent levels from the Wowhead Forever talent grid: 10 + 5 per tier.
-- Rip, Prowl and Maul come with Cat and Bear Form on Forever (granted in the trainer data): their rows carry the
-- real level from wowhead.com/forever. Prowl's granted bound is 40, so it only fits the 40-60 templates.
-- Claw is 3029 (rank 2, level 28 in the trainer data): What's Training ties Claw to the Sharpened Claws talent, but
-- rank 1 (1082) is a plain Cat spell at 20 on Wowhead. Macros cast by name, so the key works from 20.
-- Templates assume the main bar page.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end

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
local LACERATE, SHIFTING, CHARGE = T(1328617, "Lacerate"), T(1322605, "Shifting Power"), T(1238122, "Feral Charge")
local SWIFTMEND, SWIFTNESS = T(18562, "Swiftmend"), T(17116, "Nature's Swiftness")

-- One-button rotation: a castsequence that starts over on a new target and after combat.
local function SEQ(...) return { seq = { ... }, reset = { target = true, combat = true } } end
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }

-- Home keys (docs/spec-v6.md). Balance: DoTs then nukes as a castsequence on Mouse 4 (Moonfire, Insect Swarm, Wrath
-- and Starfire have no cooldown). Feral: one plain builder on Mouse 4 (energy and rage can stall a sequence), Cat on
-- the plain press and Bear on Shift. Restoration: main heal on Mouse 4, big heal on R. Every spec: Bash on 1 (the
-- bear stun interrupts), forms on C, Mark on 4. Self heals: Rejuvenation before the pull, Regrowth mid fight.
local CC = { normal = ROOTS, shift = HIBERNATE }
local HEALS = { normal = REJUV, shift = REGROWTH, alt = HT }
local BUFFS = { normal = MOTW, shift = THORNS }
local CURES2 = { normal = REMOVE_CURSE, shift = ABOLISH, alt = REBIRTH }
local CURES3 = { normal = REMOVE_CURSE, shift = ABOLISH, alt = REBIRTH, altshift = INNERVATE }

FoilKeybindsGuides.DRUID = {
  suggested = 11347, -- Icy Veins: Feral is one of the best leveling specs; Restoration says level Balance or Feral
  tested = false,
  -- Levels 1-19, every spec: no Cat Form yet. Moonfire to tag, Wrath as filler, Bear Form from 10 with Maul as its
  -- only spender. No big hit exists before Starfire (20), so R holds only Swipe on Shift.
  shared = {
    BUTTON4 = { normal = SEQ(MOONFIRE, WRATH, WRATH) },
    BUTTON5 = { normal = WRATH, shift = MAUL },
    E = CC,
    F = { normal = MOONFIRE },
    Q = { normal = FF, shift = DEMO },
    R = { shift = SWIPE },
    V = ITEMS,
    ["1"] = { normal = BASH },
    ["2"] = { normal = GRASP },
    ["3"] = HEALS,
    ["4"] = BUFFS,
    C = { normal = BEAR, shift = AQUATIC },
    X = { normal = CURE_POISON },
    Z = { normal = ENRAGE },
  },
  specs = {
    [11328] = {
      name = "Balance",
      priority = {
        { spellID = 8921, level = 4, en = "DoT. Open with it in crowded areas: it is instant, so you tag the enemy first.",
          ptBR = "DoT. Abra com ele em áreas cheias: é instantâneo, então você marca o inimigo primeiro." },
        { spellID = 5570, level = 25, talent = true, en = "Second DoT. Keep it up with Moonfire and do not refresh it early.",
          ptBR = "Segundo DoT. Mantenha junto com o Moonfire e não renove antes da hora." },
        { spellID = 5176, level = 1, en = "Main filler. Each cast also charges Eclipse for your Starfires.",
          ptBR = "Ataque principal de preenchimento. Cada conjuração também carrega o Eclipse para os seus Starfires." },
        { spellID = 2912, level = 20, en = "Heavy nuke. Use it after Wrath, while Eclipse charges make it fast.",
          ptBR = "Ataque pesado. Use depois do Wrath, enquanto as cargas de Eclipse deixam ele rápido." },
        { spellID = 24858, level = 40, talent = true, en = "Your main form from 40: more armor and crit for the group.",
          ptBR = "Sua forma principal a partir do 40: mais armadura e crítico para o grupo." },
        { spellID = 16914, level = 40, en = "Channeled area damage for 3 or more enemies. Cast Barkskin first so hits do not cut it.",
          ptBR = "Dano em área canalizado para 3 ou mais inimigos. Use Barkskin antes para os golpes não interromperem." },
        { spellID = 16689, level = 10, en = "Roots the next enemy that hits you. Use it when a pull goes bad.",
          ptBR = "Prende o próximo inimigo que bater em você. Use quando o combate sair do controle." },
        { spellID = 339, level = 8, en = "Roots one enemy so you can keep casting. Damage can break it.",
          ptBR = "Prende um inimigo para você continuar conjurando. Dano pode quebrar o efeito." },
      },
      templates = {
        -- 20-39: Starfire waits for Eclipse (late in the leveling build), so Wrath is the filler and Starfire sits on R.
        [2] = {
          BUTTON4 = { normal = SEQ(MOONFIRE, INSECT, WRATH, WRATH) },
          BUTTON5 = { normal = WRATH },
          E = CC,
          F = { normal = MOONFIRE },
          Q = { normal = INSECT, shift = FF },
          R = { normal = STARFIRE },
          V = ITEMS,
          ["1"] = { normal = BASH },
          ["2"] = { normal = GRASP },
          ["3"] = HEALS,
          ["4"] = BUFFS,
          C = { normal = BEAR, shift = CAT, alt = TRAVEL, altshift = AQUATIC },
          X = CURES2,
        },
        -- 40-60: the level 60 rotation, Insect Swarm, Moonfire, then Wrath and two Starfires.
        [3] = {
          BUTTON4 = { normal = SEQ(INSECT, MOONFIRE, WRATH, STARFIRE, STARFIRE) },
          BUTTON5 = { normal = WRATH },
          E = CC,
          F = { normal = MOONFIRE },
          Q = { normal = INSECT, shift = FF },
          R = { normal = STARFIRE, shift = HURRICANE },
          V = ITEMS,
          ["1"] = { normal = BASH },
          ["2"] = { normal = BARKSKIN, shift = GRASP },
          ["3"] = HEALS,
          ["4"] = BUFFS,
          C = { normal = MOONKIN, shift = DIRE_BEAR, alt = TRAVEL, altshift = CAT, ctrl = AQUATIC },
          X = CURES3,
        },
      },
    },
    [11347] = {
      name = "Feral Combat",
      priority = {
        { spellID = 5215, level = 20, en = "Stealth before the pull, so you can open from behind.",
          ptBR = "Furtividade antes do combate, para abrir pelas costas do alvo." },
        { spellID = 6785, level = 32, en = "Big opener from stealth, behind the target. Before 32, open with Shred.",
          ptBR = "Abertura forte saindo da furtividade, pelas costas do alvo. Antes do 32, abra com Shred." },
        { spellID = 1322605, level = 40, talent = true, en = "Turns mana into energy. Use it on cooldown when you have less than 50 energy.",
          ptBR = "Transforma mana em energia. Use sempre que puder, com menos de 50 de energia." },
        { spellID = 1079, level = 20, en = "Main finisher: a bleed. Use it at 4 or more combo points on a target that lives a while.",
          ptBR = "Finalizador principal: um sangramento. Use com 4 ou mais pontos de combo em alvos que vão durar." },
        { spellID = 1822, level = 24, en = "Bleed plus a combo point. Put it on when it is not up and the target lives 9 seconds more.",
          ptBR = "Sangramento mais um ponto de combo. Aplique quando não estiver ativo e o alvo for durar mais 9 segundos." },
        { spellID = 5221, level = 20, en = "Strong builder, only from behind. Use it when someone else holds the enemy.",
          ptBR = "Gerador forte, só pelas costas. Use quando outra pessoa estiver segurando o inimigo." },
        { spellID = 3029, level = 28, en = "Builder when you cannot get behind, so your main one when solo.",
          ptBR = "Gerador para quando você não consegue ficar nas costas, então o principal quando está sozinho." },
        { spellID = 407995, level = 40, talent = true, en = "Bear form: your main hit and threat. Use it on cooldown.",
          ptBR = "Na forma de urso: seu golpe principal e de ameaça. Use sempre que estiver disponível." },
        { spellID = 1328617, level = 25, talent = true, en = "Bear form filler on one enemy. On packs, use Swipe instead.",
          ptBR = "Ataque de preenchimento do urso contra um inimigo. Em grupos de inimigos, use Swipe." },
        { spellID = 1238122, level = 20, talent = true, en = "Charge an enemy. In bear form it also interrupts a spell.",
          ptBR = "Investe contra um inimigo. Na forma de urso, também interrompe uma magia." },
      },
      templates = {
        -- Cat on the plain press, bear on Shift: Claw and Lacerate on Mouse 4, Shred and Maul on Mouse 5.
        [2] = {
          BUTTON4 = { normal = CLAW, shift = LACERATE },
          BUTTON5 = { normal = SHRED, shift = MAUL },
          E = CC,
          F = { normal = RAKE },
          Q = { normal = RIP, shift = FF, alt = DEMO },
          R = { normal = RAVAGE, shift = SWIPE, alt = BITE },
          V = ITEMS,
          ["1"] = { normal = CHARGE, shift = BASH },
          ["2"] = { normal = DASH, shift = COWER, alt = FRENZIED },
          ["3"] = HEALS,
          ["4"] = { normal = MOTW, shift = THORNS, alt = GRASP },
          C = { normal = CAT, shift = BEAR, alt = TRAVEL, altshift = AQUATIC },
          X = CURES2,
          Z = { normal = ENRAGE },
        },
        [3] = {
          BUTTON4 = { normal = CLAW, shift = LACERATE },
          BUTTON5 = { normal = SHRED, shift = MAUL },
          E = { normal = ROOTS, shift = HIBERNATE, alt = POUNCE },
          F = { normal = RAKE, shift = PRIMAL_BITE },
          Q = { normal = RIP, shift = FF, alt = DEMO },
          R = { normal = RAVAGE, shift = SWIPE, alt = BITE, ctrl = SHIFTING },
          V = ITEMS,
          ["1"] = { normal = CHARGE, shift = BASH },
          ["2"] = { normal = BARKSKIN, shift = DASH, alt = FRENZIED, altshift = COWER },
          ["3"] = HEALS,
          ["4"] = { normal = MOTW, shift = THORNS, alt = GRASP },
          C = { normal = CAT, shift = PROWL, alt = DIRE_BEAR, altshift = TRAVEL, ctrl = AQUATIC },
          X = CURES3,
          Z = { normal = ENRAGE, shift = CHALLENGING },
        },
      },
    },
    [11340] = {
      name = "Restoration",
      priority = {
        { spellID = 774, level = 4, en = "Heal over time. Keep it on the tank and add it on anyone about to take damage.",
          ptBR = "Cura ao longo do tempo. Mantenha no tanque e aplique em quem estiver para tomar dano." },
        { spellID = 8936, level = 12, en = "Your main heal: strong and mana efficient. Use it on anyone who took real damage.",
          ptBR = "Sua cura principal: forte e econômica. Use em quem tomou bastante dano." },
        { spellID = 18562, level = 25, talent = true, en = "Fast big heal on a target with your HoT. Use it often, not only in emergencies.",
          ptBR = "Cura grande e rápida em um alvo com a sua cura ao longo do tempo. Use sempre, não só em emergências." },
        { spellID = 408120, level = 40, talent = true, en = "Heals the whole party over time. Use it when the full party is hurt.",
          ptBR = "Cura o grupo todo ao longo do tempo. Use quando o grupo inteiro estiver ferido." },
        { spellID = 740, level = 30, en = "Mana efficient group heal, but slow. In a real emergency, Regrowth is faster.",
          ptBR = "Cura em grupo econômica, mas lenta. Numa emergência de verdade, o Regrowth é mais rápido." },
        { spellID = 29166, level = 40, en = "Gives a lot of mana back. Use it on yourself on cooldown.",
          ptBR = "Devolve bastante mana. Use em você sempre que estiver disponível." },
        { spellID = 17116, level = 30, talent = true, en = "Emergency: your next heal is instant.",
          ptBR = "Emergência: a sua próxima cura sai instantânea." },
        { spellID = 5185, level = 1, en = "Slow heal. Only when the tank takes steady damage and your HoTs are already up.",
          ptBR = "Cura lenta. Só quando o tanque tomar dano constante e as suas curas ao longo do tempo já estiverem ativas." },
        { spellID = 8921, level = 4, en = "Solo damage: DoT first, then Wrath.",
          ptBR = "Dano sozinho: aplique o DoT primeiro e depois use Wrath." },
      },
      templates = {
        -- Heals on the plain press, solo damage on Shift (Wrath on Mouse 4). Big heals and cooldowns on R.
        [2] = {
          BUTTON4 = { normal = REGROWTH, shift = WRATH },
          BUTTON5 = { normal = REJUV },
          E = CC,
          F = { normal = MOONFIRE },
          Q = { normal = FF },
          R = { normal = SWIFTMEND, shift = TRANQ, altshift = SWIFTNESS },
          V = ITEMS,
          ["1"] = { normal = BASH },
          ["2"] = { normal = GRASP },
          ["3"] = { normal = HT },
          ["4"] = BUFFS,
          C = { normal = BEAR, shift = CAT, alt = TRAVEL, altshift = AQUATIC },
          X = CURES2,
        },
        [3] = {
          BUTTON4 = { normal = REGROWTH, shift = WRATH },
          BUTTON5 = { normal = REJUV },
          E = CC,
          F = { normal = MOONFIRE },
          Q = { normal = FF, shift = INSECT },
          R = { normal = SWIFTMEND, shift = WILD_GROWTH, alt = TRANQ, altshift = SWIFTNESS, ctrl = INNERVATE },
          V = ITEMS,
          ["1"] = { normal = BASH },
          ["2"] = { normal = BARKSKIN, shift = GRASP },
          ["3"] = { normal = HT },
          ["4"] = BUFFS,
          C = { normal = DIRE_BEAR, shift = CAT, alt = TRAVEL, altshift = AQUATIC },
          X = CURES2,
        },
      },
    },
  },
}
