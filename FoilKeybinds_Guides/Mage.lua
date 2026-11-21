-- Mage guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Spells and their order come from the Icy Veins WoW Forever Mage guides (leveling and rotation pages per spec).
-- Fireball and Frost Armor are granted at level 1 on Forever (trainer data bound 6 and 10).
-- Ice Lance, Arcane Blast and Arcane Wrath are talents on Forever; the trainer sells their higher ranks.
-- Talent levels: wowhead.com/forever (talent tree row r = level 10 + 5r).
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
local ICE_LANCE, BARRIER, ICE_BLOCK, COLD_SNAP = T(1312002, "Ice Lance"), T(11426, "Ice Barrier"), T(11958, "Ice Block"), T(12472, "Cold Snap")
local ARCANE_BLAST, ARCANE_WRATH = T(400574, "Arcane Blast"), T(1326079, "Arcane Wrath")
local PRESENCE, ARCANE_POWER = T(12043, "Presence of Mind"), T(12042, "Arcane Power")
local SHOOT = S(5019, "Shoot")

-- Home keys (docs/spec-v6.md): main nuke on Mouse 4, wand on Mouse 5, Frost Nova and Polymorph on E,
-- the most pressed spells on F and Q, big damage and procs on R with area on Shift and Alt.
-- No castsequence: every spec spams one nuke, and the spells around it (Fire Blast, Arcane Wrath, Ice Lance
-- on a freeze, Pyroblast at 3 Heating Up, Cone of Cold) have a cooldown or wait for a proc.
-- Fire Blast sits on F for Fire and Arcane: both cast it on cooldown to build Heating Up.
-- Frost presses Ice Lance far more (every freeze or Fingers of Frost proc), so from 20 on Ice Lance takes F
-- and Fire Blast, only a finisher for Frost, moves to Q.
-- Keys every spec shares from 20 on: wand, control, interrupt, defense, buffs, conjures, consumables.
local WAND = { normal = SHOOT }
local CONTROL = { normal = NOVA, shift = POLY }
local COUNTERSPELL = { normal = COUNTER }
local DEFENSE2 = { normal = BLINK, shift = MANA_SHIELD, alt = FIRE_WARD, altshift = FROST_WARD }
local ARMOR = { normal = FROST_ARMOR, shift = ICE_ARMOR, alt = MAGE_ARMOR, altshift = INTELLECT }
local MAGIC = { normal = DAMPEN, shift = AMPLIFY, alt = SLOW_FALL }
local CONJURE2 = { normal = WATER, shift = FOOD, alt = AGATE }
local CONJURE3 = { normal = WATER, shift = FOOD, alt = AGATE, altshift = JADE }
local EVOKE = { normal = EVOCATION, shift = DECURSE }
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
-- Fire: Scorch is the leveling filler and later keeps the Improved Scorch debuff; Arcane Blast and Missiles
-- come from the Arcane talents the Fire build takes first. Cone of Cold is area only for Fire and Arcane.
local FIRE_Q = { normal = SCORCH, shift = ARCANE_BLAST, alt = MISSILES }
local FIRE_R = { normal = PYRO, shift = FLAMESTRIKE, alt = BLAST_WAVE, altshift = CONE, ctrl = EXPLOSION }
local ARCANE_R = { normal = ARCANE_WRATH, shift = EXPLOSION, alt = FLAMESTRIKE, altshift = CONE, ctrl = BLIZZARD }
-- Frost: Cone of Cold is the area opener from 26 and, with Winter's Chill (40+), the 5-stack burst on one
-- target too, so it keeps one home on R in both ranges.
local FROST_R = { normal = CONE, shift = BLIZZARD, alt = EXPLOSION, ctrl = COLD_SNAP }

FoilKeybindsGuides.MAGE = {
  suggested = 11601, -- Frost levels best: slows and Frost Nova keep enemies off you, so you rest less
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  -- Fireball (level 1) on Mouse 4, so the main key casts from the first level; Frostbolt (level 4) on Shift.
  shared = {
    BUTTON4 = { normal = FIREBALL, shift = FROSTBOLT },
    BUTTON5 = WAND,
    E = CONTROL,
    F = { normal = FIRE_BLAST },
    R = { normal = MISSILES, shift = EXPLOSION, alt = FLAMESTRIKE },
    V = ITEMS,
    ["4"] = { normal = FROST_ARMOR, shift = INTELLECT },
    T = MAGIC,
    X = { normal = WATER, shift = FOOD },
    Z = { normal = DECURSE },
  },
  specs = {
    [11582] = {
      name = "Arcane",
      priority = {
        { spellID = 400574, level = 20, talent = true, en = "Filler. Each stack adds spell damage and costs more mana. While leveling, let the stacks drop before you run dry.",
          ptBR = "Preenchimento. Cada acúmulo soma dano mágico e custa mais mana. Subindo de nível, deixe os acúmulos caírem antes de ficar sem mana." },
        { spellID = 1326079, level = 25, talent = true, en = "Big Arcane hit on a short cooldown. Cast it every time it is ready.",
          ptBR = "Golpe Arcano forte com recarga curta. Lance toda vez que estiver pronto." },
        { spellID = 2136, level = 6, en = "Instant hit on cooldown. It builds Heating Up for Pyroblast later on.",
          ptBR = "Golpe instantâneo sempre que voltar. Mais tarde, ele acumula Aquecendo para o Pyroblast." },
        { spellID = 5143, level = 8, en = "Fire it when Missile Barrage procs: fast and free.",
          ptBR = "Use quando o talento de mísseis ativar: canaliza rápido e não gasta mana." },
        { spellID = 11366, level = 20, talent = true, en = "From the Fire dip: open the fight with it, and cast it again at 3 Heating Up stacks.",
          ptBR = "Vem dos pontos em Fogo: abra a luta com ele e lance de novo com 3 acúmulos de Aquecendo." },
        { spellID = 12042, level = 40, talent = true, en = "Burst cooldown: more damage for a short time. Use it on hard targets.",
          ptBR = "Recarga de dano: mais dano por pouco tempo. Use em alvos difíceis." },
        { spellID = 1449, level = 14, en = "Your area spell. Freeze the pack with Frost Nova first, or stand by the tank in a group.",
          ptBR = "Seu feitiço em área. Congele os inimigos com a Nova Congelante antes, ou fique perto do tanque em grupo." },
        { spellID = 12043, level = 30, talent = true, en = "Makes the next spell instant. Good for a quick Flamestrike on a pack.",
          ptBR = "Deixa o próximo feitiço instantâneo. Bom para um Flamestrike rápido num grupo de inimigos." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = ARCANE_BLAST, shift = FROSTBOLT },
          BUTTON5 = WAND,
          E = CONTROL,
          F = { normal = FIRE_BLAST },
          Q = { normal = MISSILES, shift = PRESENCE },
          R = ARCANE_R,
          V = ITEMS,
          ["1"] = COUNTERSPELL,
          ["2"] = DEFENSE2,
          ["4"] = ARMOR,
          T = MAGIC,
          X = CONJURE2,
          Z = EVOKE,
        },
        [3] = {
          BUTTON4 = { normal = ARCANE_BLAST, shift = FROSTBOLT, alt = PYRO },
          BUTTON5 = WAND,
          E = CONTROL,
          F = { normal = FIRE_BLAST, shift = ARCANE_POWER },
          Q = { normal = MISSILES, shift = PRESENCE },
          R = ARCANE_R,
          V = ITEMS,
          ["1"] = COUNTERSPELL,
          ["2"] = DEFENSE2,
          ["4"] = ARMOR,
          T = MAGIC,
          X = CONJURE3,
          Z = EVOKE,
        },
      },
    },
    [11594] = {
      name = "Fire",
      priority = {
        { spellID = 11366, level = 20, talent = true, en = "Your big hit. Cast it at 3 Heating Up stacks, when it is fast.",
          ptBR = "Seu golpe forte. Lance com 3 acúmulos de Aquecendo, quando ele fica rápido." },
        { spellID = 2136, level = 6, en = "Cast it on cooldown: each cast adds Heating Up, two on a crit.",
          ptBR = "Use sempre que voltar: cada lançamento soma Aquecendo, dois num crítico." },
        { spellID = 401502, level = 40, en = "Main cast from 40. It slows the target and still counts for your Fire talents.",
          ptBR = "Feitiço principal a partir do 40. Deixa o alvo lento e ainda conta para os seus talentos de Fogo." },
        { spellID = 133, level = 1, en = "Main nuke before 40, and the filler of the Combustion build.",
          ptBR = "Ataque principal antes do 40 e preenchimento da versão com Combustão." },
        { spellID = 2948, level = 22, en = "Quick filler while leveling. Later, keep its debuff on the target.",
          ptBR = "Preenchimento rápido para subir de nível. Depois, mantenha o efeito dele no alvo." },
        { spellID = 400574, level = 20, talent = true, en = "Arcane talent the Fire build takes first. Cast it 1-2 times to fish for Missile Barrage.",
          ptBR = "Talento Arcano que o Fogo pega primeiro. Lance 1 ou 2 vezes esperando o talento de mísseis ativar." },
        { spellID = 5143, level = 8, en = "Fire it when Missile Barrage procs.", ptBR = "Use quando o talento de mísseis ativar." },
        { spellID = 11129, level = 40, talent = true, en = "Cooldown that raises your Fire crit until you land a few crits. Use it on hard targets.",
          ptBR = "Recarga que aumenta o seu crítico de Fogo até você acertar alguns críticos. Use em alvos difíceis." },
        { spellID = 2120, level = 16, en = "Area opener: drop it under a frozen pack.", ptBR = "Abertura em área: lance embaixo de um grupo congelado." },
        { spellID = 11113, level = 30, talent = true, en = "Fire burst around you that also slows. Cast it right after Flamestrike.",
          ptBR = "Explosão de Fogo à sua volta que também deixa os inimigos lentos. Use logo depois do Flamestrike." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = FIREBALL, shift = FROSTBOLT },
          BUTTON5 = WAND,
          E = CONTROL,
          F = { normal = FIRE_BLAST },
          Q = FIRE_Q,
          R = FIRE_R,
          V = ITEMS,
          ["1"] = COUNTERSPELL,
          ["2"] = DEFENSE2,
          ["4"] = ARMOR,
          T = MAGIC,
          X = CONJURE2,
          Z = EVOKE,
        },
        [3] = {
          BUTTON4 = { normal = FROSTFIRE, shift = FIREBALL, alt = FROSTBOLT },
          BUTTON5 = WAND,
          E = CONTROL,
          F = { normal = FIRE_BLAST, shift = COMBUSTION },
          Q = FIRE_Q,
          R = FIRE_R,
          V = ITEMS,
          ["1"] = COUNTERSPELL,
          ["2"] = DEFENSE2,
          ["4"] = ARMOR,
          T = MAGIC,
          X = CONJURE3,
          Z = EVOKE,
        },
      },
    },
    [11601] = {
      name = "Frost",
      priority = {
        { spellID = 116, level = 4, en = "Main nuke. Open from max range and keep casting it. It also slows the target.",
          ptBR = "Ataque principal. Abra da distância máxima e continue lançando. Também deixa o alvo lento." },
        { spellID = 1312002, level = 20, talent = true, en = "Cast it on a frozen target or a Fingers of Frost proc, just before your next Frostbolt lands.",
          ptBR = "Lance num alvo congelado ou quando Dedos de Gelo ativar, logo antes do próximo Frostbolt chegar." },
        { spellID = 122, level = 10, en = "Freezes enemies around you. Step back, then Frostbolt and Ice Lance.",
          ptBR = "Congela os inimigos à sua volta. Afaste-se e use Frostbolt e Ice Lance." },
        { spellID = 120, level = 26, en = "Area opener on a pack. From 40, with Winter's Chill at 5 stacks, cast it on a single target too.",
          ptBR = "Abertura em área num grupo. A partir do 40, com 5 acúmulos de Frio Invernal, use também em um alvo só." },
        { spellID = 11426, level = 40, talent = true, en = "Shield that also raises your damage. Cast it before the pull and keep it up.",
          ptBR = "Escudo que também aumenta o seu dano. Lance antes de puxar e mantenha ativo." },
        { spellID = 10, level = 20, en = "Channeled area filler between Cones of Cold.", ptBR = "Dano em área canalizado entre um Cone de Frio e outro." },
        { spellID = 12472, level = 30, talent = true, en = "Resets your Frost cooldowns: a second Cone of Cold, or Frost Nova in an emergency.",
          ptBR = "Zera as recargas de Gelo: um segundo Cone de Frio, ou a Nova Congelante numa emergência." },
        { spellID = 2136, level = 6, en = "Instant hit to finish a low target that is not frozen, or to cast on the move.",
          ptBR = "Golpe instantâneo para finalizar um alvo com pouca vida que não está congelado, ou atacar andando." },
        { spellID = 11958, level = 25, talent = true, en = "Immune for a few seconds. Use it when a pull goes wrong.",
          ptBR = "Imune por alguns segundos. Use quando uma puxada der errado." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = FROSTBOLT, shift = FIREBALL },
          BUTTON5 = WAND,
          E = CONTROL,
          F = { normal = ICE_LANCE },
          Q = { normal = FIRE_BLAST },
          R = FROST_R,
          V = ITEMS,
          ["1"] = COUNTERSPELL,
          ["2"] = { normal = BLINK, shift = MANA_SHIELD, alt = FIRE_WARD, altshift = FROST_WARD, ctrl = ICE_BLOCK },
          ["4"] = ARMOR,
          T = MAGIC,
          X = CONJURE2,
          Z = EVOKE,
        },
        [3] = {
          BUTTON4 = { normal = FROSTBOLT, shift = FIREBALL },
          BUTTON5 = WAND,
          E = CONTROL,
          F = { normal = ICE_LANCE },
          Q = { normal = FIRE_BLAST },
          R = FROST_R,
          V = ITEMS,
          ["1"] = COUNTERSPELL,
          ["2"] = { normal = BARRIER, shift = BLINK, alt = MANA_SHIELD, altshift = ICE_BLOCK, ctrl = FROST_WARD },
          ["4"] = ARMOR,
          T = MAGIC,
          X = CONJURE3,
          Z = EVOKE,
        },
      },
    },
  },
}
