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
        { spellID = 5676, level = 18, en = "From 25 it brands the enemy your demon hits: its next attacks there hit harder. Cast again when the brand is gone.",
          ptBR = "A partir do 25 marca o inimigo que o seu demônio ataca: os próximos golpes dele ali batem mais forte. Lance de novo quando a marca sumir." },
        { spellID = 440892, level = 20, en = "Your curse on tough enemies: they take more spell damage. Curse of Weakness instead when their melee hurts more.",
          ptBR = "Sua maldição em inimigos resistentes: eles sofrem mais dano mágico. Use a que enfraquece quando o golpe deles pesar mais." },
        { spellID = 980, level = 8, en = "Long Shadow DoT that grows over time. Let it run out before you cast it again.",
          ptBR = "DoT de Sombra longo que cresce com o tempo. Deixe acabar antes de lançar de novo." },
        { spellID = 172, level = 4, en = "Shadow DoT on enemies that live long enough. It has a cast time until talents make it instant at 49.",
          ptBR = "DoT de Sombra em inimigos que vivem o bastante. Tem tempo de conjuração até os talentos deixarem instantâneo no 49." },
        { spellID = 686, level = 1, en = "Your nuke between DoTs and brands. From 56, cast it right away when Nightfall makes it instant.",
          ptBR = "Seu dano direto entre os DoTs e as marcas. A partir do 56, use logo quando um talento deixar ela instantânea." },
        { spellID = 348, level = 1, en = "Fire DoT with a long cast. Only a filler when nothing better is left to cast.",
          ptBR = "DoT de Fogo com conjuração longa. Só um preenchimento quando não sobrar nada melhor para lançar." },
        { spellID = 689, level = 14, en = "Channel that heals you while your demon and DoTs keep hitting.",
          ptBR = "Canalização que cura você enquanto o seu demônio e os DoTs continuam causando dano." },
        { spellID = 755, level = 12, en = "Heals your demon when your talents cannot keep it alive fast enough.",
          ptBR = "Cura o seu demônio quando os talentos não conseguem mantê-lo vivo rápido o bastante." },
        { spellID = 1454, level = 6, en = "Turns health into mana. With your talents it fills your demon's mana too.",
          ptBR = "Troca vida por mana. Com os talentos, enche a mana do seu demônio também." },
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
        { spellID = 440892, level = 20, en = "Your curse on tough enemies: they take more spell damage. Curse of Weakness instead when their melee hurts more.",
          ptBR = "Sua maldição em inimigos resistentes: eles sofrem mais dano mágico. Use a que enfraquece quando o golpe deles pesar mais." },
        { spellID = 686, level = 1, en = "Main nuke before 40. Open from max range, then cast Immolate while the bolt flies.",
          ptBR = "Dano principal antes do 40. Abra do alcance máximo e lance o DoT de Fogo enquanto o projétil voa." },
        { spellID = 348, level = 1, en = "Fire DoT. Keep it up: it unlocks your instant Fire hit and boosts your main nuke from 40.",
          ptBR = "DoT de Fogo. Mantenha ativo: libera o seu dano de Fogo instantâneo e fortalece o seu dano principal a partir do 40." },
        { spellID = 980, level = 8, en = "Long Shadow DoT that grows over time. Use it on enemies that live long enough.",
          ptBR = "DoT de Sombra longo que cresce com o tempo. Use em inimigos que vivem o bastante." },
        { spellID = 1293817, level = 25, talent = true, en = "Instant Fire hit on a target with Immolate. Before 39 it eats the DoT, so use it near its end. From 39, on cooldown.",
          ptBR = "Dano de Fogo instantâneo num alvo com o seu DoT de Fogo. Antes do 39 consome o DoT, então use perto do fim dele. A partir do 39, sempre que estiver pronto." },
        { spellID = 17877, level = 20, talent = true, en = "Instant finisher for a Soul Shard, given back if the target dies soon. From 39 it also keeps your Fire damage buff up.",
          ptBR = "Finalizador instantâneo que gasta um Fragmento de Alma, devolvido se o alvo morrer logo. A partir do 39 também mantém o seu bônus de dano de Fogo." },
        { spellID = 412758, level = 40, talent = true, en = "Main nuke from 40, stronger on a target with Immolate.",
          ptBR = "Dano principal a partir do 40, mais forte num alvo com o seu DoT de Fogo." },
        { spellID = 689, level = 14, en = "Channel that heals you while your DoTs keep ticking.",
          ptBR = "Canalização que cura você enquanto os seus DoTs continuam causando dano." },
        { spellID = 1454, level = 6, en = "Turns health into mana. Your nukes burn mana fast.",
          ptBR = "Troca vida por mana. Seus ataques gastam mana rápido." },
        { spellID = 172, level = 4, en = "Shadow DoT with a cast time in this spec. Only on enemies that live long.",
          ptBR = "DoT de Sombra com tempo de conjuração nesta especialização. Só em inimigos que vivem bastante." },
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
