-- Warlock guide. Shape: see docs/spec-v4.md "Guide data package"; checked by tests/run.lua (data test).
-- Spell IDs: Forever first rank (the macro casts by name, so the best known rank fires), levels from the
-- What's Training Forever trainer data. talent = true: a talent spell, level = the talent's minimum level
-- (wowhead.com/forever). Templates: key -> slot -> spell or { item = "HS" | "POT" | "BAND" | "BOMB" | "HEAL" | "EAT" | "HSPOT" }.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HSPOT, HEAL, EAT, BOMB = { item = "HSPOT" }, { item = "HEAL" }, { item = "EAT" }, { item = "BOMB" }
-- One-button rotation: a castsequence that starts over on a new target and after combat.
local function SEQ(...) return { seq = { ... }, reset = { target = true, combat = true } } end

local IMMOLATE, SHADOW_BOLT, DEMON_SKIN, SUMMON_IMP = S(348, "Immolate"), S(686, "Shadow Bolt"), S(687, "Demon Skin"), S(688, "Summon Imp")
local CORRUPTION, WEAKNESS, LIFE_TAP = S(172, "Corruption"), S(702, "Curse of Weakness"), S(1454, "Life Tap")
local AGONY, FEAR, DRAIN_SOUL = S(980, "Bane of Agony"), S(5782, "Fear"), S(1120, "Drain Soul")
local HEALTHSTONE, VOIDWALKER, HEALTH_FUNNEL = S(6201, "Create Healthstone"), S(697, "Summon Voidwalker"), S(755, "Health Funnel")
local DRAIN_LIFE, RECKLESSNESS, BREATH = S(689, "Drain Life"), S(704, "Curse of Recklessness"), S(5697, "Unending Breath")
local SEARING_PAIN, SOULSTONE = S(5676, "Searing Pain"), S(693, "Create Soulstone")
local DEMON_ARMOR, RAIN, ELEMENTS, SUCCUBUS = S(706, "Demon Armor"), S(5740, "Rain of Fire"), S(440892, "Curse of the Elements"), S(712, "Summon Succubus")
local DRAIN_MANA, TONGUES, BANISH = S(5138, "Drain Mana"), S(1714, "Curse of Tongues"), S(710, "Banish")
local HELLFIRE, FELHUNTER, SHADOW_WARD, SPELLSTONE = S(1949, "Hellfire"), S(691, "Summon Felhunter"), S(6229, "Shadow Ward"), S(2362, "Create Spellstone")
local HOWL, DEATH_COIL, SOUL_FIRE, DOOM = S(5484, "Howl of Terror"), S(6789, "Death Coil"), S(6353, "Soul Fire"), S(603, "Bane of Doom")
local SHADOWBURN, CONFLAGRATE, SIPHON_LIFE = T(17877, "Shadowburn"), T(1293817, "Conflagrate"), T(18265, "Siphon Life")
local WRACK, INCINERATE = T(1316697, "Wrack"), T(412758, "Incinerate")
local SHOOT = S(5019, "Shoot")

-- Home keys (docs/spec-v6.md), close to Tiago's own setup (docs/key-placement.md): rotation on Mouse 4,
-- wand on Mouse 5, crowd control on E, DoTs on F, curses on Q, Shadow Bolt and area on R.
-- Keys every bracket shares from 20 on: wand, curses, demons, consumables, mana.
local WAND = { normal = SHOOT, shift = CORRUPTION, alt = DRAIN_LIFE, altshift = SHADOW_WARD }
local CURSES = { normal = WEAKNESS, shift = RECKLESSNESS, alt = ELEMENTS, ctrl = TONGUES }
local NUKES = { normal = SHADOW_BOLT, shift = HELLFIRE, alt = RAIN, altshift = SEARING_PAIN }
local NUKES3 = { normal = SHADOW_BOLT, shift = HELLFIRE, alt = RAIN, altshift = SEARING_PAIN, ctrl = SOUL_FIRE }
local FEAR2 = { normal = FEAR, alt = BOMB, altshift = BANISH }
local FEAR3 = { normal = FEAR, shift = HOWL, alt = BOMB, altshift = BANISH }
local ARMOR2 = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = BREATH }
local ARMOR3 = { normal = DEMON_ARMOR, shift = HEALTHSTONE, alt = SOULSTONE, altshift = SPELLSTONE, ctrl = BREATH }
local DEMONS = { normal = VOIDWALKER, shift = SUCCUBUS, alt = FELHUNTER, altshift = SUMMON_IMP, ctrl = HEALTH_FUNNEL } -- pet key: Health Funnel heals the demon
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local TAP = { normal = LIFE_TAP, shift = DRAIN_SOUL, alt = DRAIN_MANA }

FoilKeybindsGuides.WARLOCK = {
  suggested = 11629, -- Affliction levels best: DoTs and drains, little downtime
  tested = true,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three.
  -- Immolate (level 1) starts the sequence, so Mouse 4 casts from the first level.
  shared = {
    BUTTON4 = { normal = SEQ(IMMOLATE, CORRUPTION, AGONY), shift = RECKLESSNESS },
    BUTTON5 = { normal = SHOOT, shift = CORRUPTION, alt = DRAIN_LIFE },
    E = { normal = FEAR },
    F = { normal = AGONY, alt = IMMOLATE },
    Q = { normal = WEAKNESS, shift = RECKLESSNESS },
    R = { normal = SHADOW_BOLT, altshift = SEARING_PAIN },
    V = ITEMS,
    ["4"] = { normal = DEMON_SKIN, shift = HEALTHSTONE, alt = SOULSTONE, altshift = BREATH },
    G = { normal = VOIDWALKER, shift = SUMMON_IMP, ctrl = HEALTH_FUNNEL },
    X = { normal = LIFE_TAP, shift = DRAIN_SOUL },
  },
  specs = {
    [11629] = {
      name = "Affliction",
      priority = {
        { spellID = 172, level = 4, en = "Main DoT. Keep it on every target.", ptBR = "DoT principal. Mantenha em todos os alvos." },
        { spellID = 980, level = 8, en = "Long Shadow DoT that grows over time. Let it run out before you cast it again.",
          ptBR = "DoT de Sombra longo que cresce com o tempo. Deixe acabar antes de lançar de novo." },
        { spellID = 18265, level = 30, talent = true, en = "DoT that heals you each tick. Worth it on longer fights.",
          ptBR = "DoT que cura você a cada tique. Vale a pena em lutas mais longas." },
        { spellID = 440892, level = 20, en = "Your curse: the target takes more spell damage. It stays up next to your Bane.",
          ptBR = "Sua maldição: o alvo sofre mais dano mágico. Fica ativa junto com o seu DoT de Sombra longo." },
        { spellID = 348, level = 1, en = "Fire DoT with a cast. Good while leveling and on long fights.",
          ptBR = "DoT de Fogo com tempo de conjuração. Bom para subir de nível e em lutas longas." },
        { spellID = 686, level = 1, en = "Filler at low level. Later, cast it when Nightfall makes it instant.",
          ptBR = "Preenchimento no começo. Depois, use quando um talento deixar ela instantânea." },
        { spellID = 1316697, level = 40, talent = true, en = "Channeled filler: your DoTs on the target tick faster while it runs.",
          ptBR = "Preenchimento canalizado: seus DoTs no alvo causam dano mais rápido enquanto dura." },
        { spellID = 689, level = 14, en = "Channel that heals you. Use it instead of sitting to eat.",
          ptBR = "Canalização que cura você. Use no lugar de parar para comer." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Tap, then heal back with Drain Life.",
          ptBR = "Troca vida por mana. Use e depois recupere a vida drenando o alvo." },
        { spellID = 5782, level = 8, en = "Sends a second enemy running. Damage breaks it.",
          ptBR = "Faz um segundo inimigo fugir. Dano quebra o efeito." },
        { spellID = 1120, level = 10, en = "Channel on a dying target to get a Soul Shard.",
          ptBR = "Canalize num alvo quase morto para ganhar um Fragmento de Alma." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = SEQ(AGONY, SIPHON_LIFE, CORRUPTION, ELEMENTS), shift = RECKLESSNESS },
          BUTTON5 = WAND,
          E = FEAR2,
          F = { normal = SIPHON_LIFE, alt = IMMOLATE },
          Q = CURSES,
          R = NUKES,
          V = ITEMS,
          ["4"] = ARMOR2,
          G = DEMONS,
          X = TAP,
        },
        [3] = {
          BUTTON4 = { normal = SEQ(AGONY, SIPHON_LIFE, CORRUPTION, ELEMENTS), shift = RECKLESSNESS },
          BUTTON5 = WAND,
          E = FEAR3,
          F = { normal = SIPHON_LIFE, shift = WRACK, alt = IMMOLATE, altshift = DOOM },
          Q = CURSES,
          R = NUKES3,
          V = ITEMS,
          ["2"] = { normal = DEATH_COIL },
          ["4"] = ARMOR3,
          G = DEMONS,
          X = TAP,
        },
      },
    },
    [11636] = {
      name = "Demonology",
      priority = {
        { spellID = 172, level = 4, en = "Main DoT. Put it up first while your demon holds the target.",
          ptBR = "DoT principal. Aplique primeiro enquanto o seu demônio segura o alvo." },
        { spellID = 980, level = 8, en = "Long Shadow DoT that grows over time. One cast per target.",
          ptBR = "DoT de Sombra longo que cresce com o tempo. Uma vez por alvo." },
        { spellID = 348, level = 1, en = "Fire DoT with a cast. Cast it before the pull.",
          ptBR = "DoT de Fogo com tempo de conjuração. Lance antes de puxar." },
        { spellID = 686, level = 1, en = "Main nuke while the demon tanks.", ptBR = "Dano principal enquanto o demônio segura o alvo." },
        { spellID = 755, level = 12, en = "Heals your demon so it keeps the enemy off you.",
          ptBR = "Cura o seu demônio para ele manter o inimigo longe de você." },
        { spellID = 702, level = 4, en = "Your curse while a pet tanks: the target hits softer.",
          ptBR = "Sua maldição enquanto o pet segura: o alvo bate mais fraco." },
        { spellID = 689, level = 14, en = "Channel that heals you. Use it between Life Taps.",
          ptBR = "Canalização que cura você. Use entre uma troca de vida por mana e outra." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Your demon covers you while you tap.",
          ptBR = "Troca vida por mana. O seu demônio protege você enquanto isso." },
        { spellID = 5782, level = 8, en = "Sends a second enemy running. Damage breaks it.",
          ptBR = "Faz um segundo inimigo fugir. Dano quebra o efeito." },
        { spellID = 1120, level = 10, en = "Channel on a dying target to get a Soul Shard.",
          ptBR = "Canalize num alvo quase morto para ganhar um Fragmento de Alma." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = SEQ(CORRUPTION, AGONY, IMMOLATE, WEAKNESS), shift = RECKLESSNESS },
          BUTTON5 = WAND,
          E = FEAR2,
          F = { normal = AGONY, alt = IMMOLATE },
          Q = CURSES,
          R = NUKES,
          V = ITEMS,
          ["4"] = ARMOR2,
          G = DEMONS,
          X = TAP,
        },
        [3] = {
          BUTTON4 = { normal = SEQ(CORRUPTION, AGONY, IMMOLATE, WEAKNESS), shift = RECKLESSNESS },
          BUTTON5 = WAND,
          E = FEAR3,
          F = { normal = AGONY, alt = IMMOLATE, altshift = DOOM },
          Q = CURSES,
          R = NUKES3,
          V = ITEMS,
          ["2"] = { normal = DEATH_COIL },
          ["4"] = ARMOR3,
          G = DEMONS,
          X = TAP,
        },
      },
    },
    [11637] = {
      name = "Destruction",
      priority = {
        { spellID = 348, level = 1, en = "Fire DoT. Keep it up: your Fire spells hit harder with it.",
          ptBR = "DoT de Fogo. Mantenha ativo: seus feitiços de Fogo batem mais forte com ele." },
        { spellID = 1293817, level = 25, talent = true, en = "Instant Fire hit that eats your Immolate. Cast Immolate again after.",
          ptBR = "Dano de Fogo instantâneo que consome o DoT de Fogo do alvo. Reaplique o DoT depois." },
        { spellID = 686, level = 1, en = "Main nuke.", ptBR = "Dano principal." },
        { spellID = 412758, level = 40, talent = true, en = "Fire nuke, stronger on a target with Immolate.",
          ptBR = "Dano de Fogo, mais forte num alvo com o seu DoT de Fogo." },
        { spellID = 17877, level = 20, talent = true, en = "Instant finisher for a Soul Shard. Gives the shard back if the target dies soon.",
          ptBR = "Finalizador instantâneo que gasta um Fragmento de Alma. Devolve o fragmento se o alvo morrer logo." },
        { spellID = 172, level = 4, en = "Cheap Shadow DoT. Put it up on long fights.",
          ptBR = "DoT de Sombra barato. Aplique em lutas longas." },
        { spellID = 6353, level = 48, en = "Huge Fire hit with a long cast. Costs a Soul Shard.",
          ptBR = "Dano de Fogo enorme com conjuração longa. Gasta um Fragmento de Alma." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Nukes burn mana fast.",
          ptBR = "Troca vida por mana. Seus ataques gastam mana rápido." },
        { spellID = 689, level = 14, en = "Channel that heals you between pulls.", ptBR = "Canalização que cura você entre um combate e outro." },
        { spellID = 5782, level = 8, en = "Sends a second enemy running. Damage breaks it.",
          ptBR = "Faz um segundo inimigo fugir. Dano quebra o efeito." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = SEQ(IMMOLATE, CORRUPTION, ELEMENTS), shift = RECKLESSNESS },
          BUTTON5 = WAND,
          E = FEAR2,
          F = { normal = CONFLAGRATE, shift = SHADOWBURN, alt = IMMOLATE },
          Q = CURSES,
          R = NUKES,
          V = ITEMS,
          ["4"] = ARMOR2,
          G = DEMONS,
          X = TAP,
        },
        [3] = {
          BUTTON4 = { normal = SEQ(IMMOLATE, CORRUPTION, ELEMENTS), shift = RECKLESSNESS },
          BUTTON5 = WAND,
          E = FEAR3,
          F = { normal = CONFLAGRATE, shift = SHADOWBURN, alt = IMMOLATE, altshift = INCINERATE },
          Q = CURSES,
          R = NUKES3,
          V = ITEMS,
          ["2"] = { normal = DEATH_COIL },
          ["4"] = ARMOR3,
          G = DEMONS,
          X = TAP,
        },
      },
    },
  },
}
