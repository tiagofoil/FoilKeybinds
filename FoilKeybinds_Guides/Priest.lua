-- Priest guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Source: the Icy Veins WoW Forever Priest guides (leveling, rotation, talents), read 2026-11-20.
-- Smite and Lesser Heal rank 1 are starting spells (granted in the trainer data), learned at level 1.
-- Racial priest spells (Starshards, Feedback, Shadowguard and the like) stay out: most players never get them.
-- Talent levels: the earliest level for the talent's tree row (row N: 10 + (N-1)*5), as on the Icy Veins
-- leveling milestones.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end

local SMITE, LESSER_HEAL, PWF = S(585, "Smite"), S(2050, "Lesser Heal"), S(1243, "Power Word: Fortitude")
local SWP, PWS, RENEW, FADE = S(589, "Shadow Word: Pain"), S(17, "Power Word: Shield"), S(139, "Renew"), S(586, "Fade")
local MIND_BLAST, INNER_FIRE, SCREAM = S(8092, "Mind Blast"), S(588, "Inner Fire"), S(8122, "Psychic Scream")
local CURE_DISEASE, HEAL, DISPEL = S(528, "Cure Disease"), S(2054, "Heal"), S(527, "Dispel Magic")
local FLASH_HEAL, HOLY_FIRE, PLAGUE = S(2061, "Flash Heal"), S(14914, "Holy Fire"), S(2944, "Devouring Plague")
local FEAR_WARD, SHACKLE, MANA_BURN = S(6346, "Fear Ward"), S(9484, "Shackle Undead"), S(8129, "Mana Burn")
local POH, SHADOW_PROT, DIVINE_SPIRIT = S(596, "Prayer of Healing"), S(976, "Shadow Protection"), S(14752, "Divine Spirit")
local SWD, ABOLISH, GREATER_HEAL = S(1309595, "Shadow Word: Death"), S(552, "Abolish Disease"), S(2060, "Greater Heal")
local MIND_FLAY, HOLY_NOVA, VE = T(15407, "Mind Flay"), T(15237, "Holy Nova"), T(15286, "Vampiric Embrace")
local PENANCE, PI, POM = T(402174, "Penance"), T(10060, "Power Infusion"), T(401859, "Prayer of Mending")
local SILENCE, SHADOWFORM = T(15487, "Silence"), T(15473, "Shadowform")
local SHOOT = S(5019, "Shoot")
-- One-button rotation: a castsequence that starts over on a new target and after combat.
local function SEQ(...) return { seq = { ... }, reset = { target = true, combat = true } } end

-- Home keys (docs/spec-v6.md): Mouse 4 is the rotation (Shadow, leveling) or the main heal (Holy,
-- Discipline), wand on Mouse 5, Psychic Scream on E, DoTs and the most pressed spell on F and Q,
-- Mind Blast or the big heal on R, Silence on 1. Sequences hold only spells with no cooldown (Smite,
-- Shadow Word: Pain, Mind Flay): Mind Blast, Devouring Plague, Shadow Word: Death and Penance stay on
-- their own keys. Vampiric Embrace stays out too (its Forever rules changed on 2026-11-17).
-- Keys every spec shares from 20 on: wand, control, defense, buffs, dispels, consumables.
local CONTROL = { normal = SCREAM, shift = SHACKLE }
local DEFENSE = { normal = FADE }
local BUFFS = { normal = PWF, shift = INNER_FIRE, alt = DIVINE_SPIRIT, altshift = FEAR_WARD }
local DISPELS2 = { normal = DISPEL, shift = CURE_DISEASE }
local DISPELS3 = { normal = DISPEL, shift = ABOLISH }
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }
local HEALER_DAMAGE = { normal = SWP, shift = HOLY_FIRE, alt = MIND_BLAST } -- solo leveling script on Q

FoilKeybindsGuides.PRIEST = {
  suggested = 11622, -- Shadow: the Holy and Discipline guides say solo priests level faster as Shadow
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, all three level with the same damage script: Smite to
  -- open, Mind Blast, Shadow Word: Pain, then the wand. Smite (level 1) starts the sequence.
  shared = {
    BUTTON4 = { normal = SEQ(SMITE, SWP) },
    BUTTON5 = { normal = SHOOT, shift = SMITE },
    E = { normal = SCREAM },
    F = { normal = SWP },
    R = { normal = MIND_BLAST },
    V = ITEMS,
    ["2"] = { normal = PWS, shift = FADE },
    ["3"] = { normal = LESSER_HEAL, shift = HEAL, alt = RENEW },
    ["4"] = { normal = PWF, shift = INNER_FIRE },
    X = DISPELS2,
  },
  specs = {
    [11608] = {
      name = "Discipline",
      priority = {
        { spellID = 17, level = 6, en = "Your first tool. Shield whoever is about to take hits, before they land.",
          ptBR = "Sua primeira ferramenta. Proteja quem vai apanhar, antes do golpe chegar." },
        { spellID = 402174, level = 30, talent = true, en = "Channel that heals an ally or hurts an enemy. The first tick is instant, so it saves people.",
          ptBR = "Canalização que cura um aliado ou causa dano num inimigo. O primeiro tique é instantâneo e salva quem está mal." },
        { spellID = 2054, level = 16, en = "Your standard heal for steady damage.", ptBR = "Sua cura padrão para dano constante." },
        { spellID = 139, level = 8, en = "Heal over time for chip damage and while you move.",
          ptBR = "Cura ao longo do tempo para dano leve e para usar em movimento." },
        { spellID = 2061, level = 20, en = "Fast heal for emergencies only: it costs a lot of mana.",
          ptBR = "Cura rápida só para emergências: gasta muita mana." },
        { spellID = 596, level = 30, en = "Group heal when several allies are hurt.", ptBR = "Cura em grupo quando vários aliados estão feridos." },
        { spellID = 14914, level = 20, en = "Solo opener: cast it on the enemy before it reaches you.",
          ptBR = "Abertura sozinho: lance no inimigo antes de ele chegar até você." },
        { spellID = 589, level = 4, en = "Shadow DoT for solo leveling. Then finish the enemy with the wand.",
          ptBR = "DoT de Sombra para subir de nível sozinho. Depois termine o inimigo com a varinha." },
        { spellID = 585, level = 1, en = "Holy nuke while the enemy runs at you.",
          ptBR = "Ataque Sagrado enquanto o inimigo corre até você." },
        { spellID = 10060, level = 40, talent = true, en = "Speeds up an ally's spells. Save it for hard fights.",
          ptBR = "Acelera os feitiços de um aliado. Guarde para lutas difíceis." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HEAL, shift = FLASH_HEAL, alt = LESSER_HEAL },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = PWS, shift = RENEW },
          Q = HEALER_DAMAGE,
          R = { normal = PENANCE },
          V = ITEMS,
          ["2"] = DEFENSE,
          ["3"] = { normal = POH },
          ["4"] = BUFFS,
          X = DISPELS2,
        },
        [3] = {
          BUTTON4 = { normal = HEAL, shift = FLASH_HEAL, alt = LESSER_HEAL },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = PWS, shift = RENEW },
          Q = HEALER_DAMAGE,
          R = { normal = PENANCE, shift = GREATER_HEAL, ctrl = PI },
          V = ITEMS,
          ["2"] = DEFENSE,
          ["3"] = { normal = POH },
          ["4"] = BUFFS,
          X = DISPELS3,
        },
      },
    },
    [11615] = {
      name = "Holy",
      priority = {
        { spellID = 17, level = 6, en = "Shield an ally to buy time for your heal casts.",
          ptBR = "Escudo num aliado para ganhar tempo enquanto você conjura as curas." },
        { spellID = 2050, level = 1, en = "Quick, small heal for light damage.", ptBR = "Cura rápida e pequena para dano leve." },
        { spellID = 2054, level = 16, en = "Your standard heal for steady damage.", ptBR = "Sua cura padrão para dano constante." },
        { spellID = 139, level = 8, en = "Heal over time. Keeps up with chip damage while you wand.",
          ptBR = "Cura ao longo do tempo. Cobre o dano leve enquanto você usa a varinha." },
        { spellID = 2061, level = 20, en = "Fast heal for emergencies only: it costs a lot of mana.",
          ptBR = "Cura rápida só para emergências: gasta muita mana." },
        { spellID = 596, level = 30, en = "Group heal when several allies are hurt.", ptBR = "Cura em grupo quando vários aliados estão feridos." },
        { spellID = 15237, level = 20, talent = true, en = "Instant Holy damage and healing around you. Cast it when Searing Light procs.",
          ptBR = "Dano Sagrado e cura instantâneos ao seu redor. Use quando o talento de proc ativar." },
        { spellID = 14914, level = 20, en = "Solo opener: cast it on the farthest enemy.",
          ptBR = "Abertura sozinho: lance no inimigo mais distante." },
        { spellID = 585, level = 1, en = "Holy nuke while the enemy runs at you. Then Mind Blast, Shadow Word: Pain and the wand.",
          ptBR = "Ataque Sagrado enquanto o inimigo corre até você. Depois Explosão Mental, Palavra Sombria: Dor e a varinha." },
        { spellID = 2060, level = 40, en = "Biggest heal. Slow cast: use it on a tank taking heavy hits.",
          ptBR = "Maior cura. Conjuração lenta: use num tanque que está apanhando muito." },
        { spellID = 401859, level = 40, talent = true, en = "Heal that jumps to the next hurt ally when its target takes a hit.",
          ptBR = "Cura que pula para o próximo aliado ferido quando o alvo leva um golpe." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = HEAL, shift = LESSER_HEAL },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = PWS, shift = RENEW },
          Q = HEALER_DAMAGE,
          R = { normal = FLASH_HEAL, shift = HOLY_NOVA },
          V = ITEMS,
          ["2"] = DEFENSE,
          ["3"] = { normal = POH },
          ["4"] = BUFFS,
          X = DISPELS2,
        },
        [3] = {
          BUTTON4 = { normal = HEAL, shift = LESSER_HEAL },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = PWS, shift = RENEW, alt = POM },
          Q = HEALER_DAMAGE,
          R = { normal = GREATER_HEAL, shift = HOLY_NOVA, alt = FLASH_HEAL },
          V = ITEMS,
          ["2"] = DEFENSE,
          ["3"] = { normal = POH },
          ["4"] = BUFFS,
          X = DISPELS3,
        },
      },
    },
    [11622] = {
      name = "Shadow Magic",
      priority = {
        { spellID = 589, level = 4, en = "Main DoT. Keep it on every target.", ptBR = "DoT principal. Mantenha em todos os alvos." },
        { spellID = 2944, level = 20, en = "Second DoT that heals you. Strong but costly, with a cooldown: keep it up on longer fights.",
          ptBR = "Segundo DoT que cura você. Forte mas caro, com recarga: mantenha em lutas mais longas." },
        { spellID = 8092, level = 10, en = "Big Shadow hit with a short cooldown. Use it to pull and whenever it is ready.",
          ptBR = "Dano de Sombra forte com recarga curta. Use para puxar e sempre que estiver pronta." },
        { spellID = 1309595, level = 32, en = "Instant hit with a cooldown. If the target lives, you lose 30% of your health.",
          ptBR = "Dano instantâneo com recarga. Se o alvo sobreviver, você perde 30% da sua vida." },
        { spellID = 15286, level = 25, talent = true, en = "Debuff on the target: your Shadow damage heals you and your group. Keep it up.",
          ptBR = "Efeito no alvo: seu dano de Sombra cura você e o seu grupo. Mantenha ativo." },
        { spellID = 15407, level = 20, talent = true, en = "Channeled filler once the DoTs are up. Let it finish: the last tick hits hardest.",
          ptBR = "Preenchimento canalizado depois dos DoTs. Deixe terminar: o último tique bate mais forte." },
        { spellID = 15473, level = 40, talent = true, en = "Your form: Shadow spells cost half the mana. A heal cast drops it.",
          ptBR = "Sua forma: feitiços de Sombra custam metade da mana. Conjurar uma cura tira a forma." },
        { spellID = 17, level = 6, en = "Shield yourself before the pull so hits do not slow your casts.",
          ptBR = "Escudo em você antes do combate, para os golpes não atrasarem seus feitiços." },
        { spellID = 585, level = 1, en = "Opener and filler until you have Mind Flay.",
          ptBR = "Abertura e preenchimento até você ter Tortura Mental." },
        { spellID = 15487, level = 30, talent = true, en = "Your only interrupt. One talent point.",
          ptBR = "Sua única interrupção. Custa um ponto de talento." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = SEQ(SWP, MIND_FLAY), shift = SMITE },
          BUTTON5 = { normal = SHOOT, shift = MIND_FLAY },
          E = CONTROL,
          F = { normal = SWP },
          Q = { normal = PLAGUE, shift = VE },
          R = { normal = MIND_BLAST, shift = SWD },
          V = ITEMS,
          ["1"] = { normal = SILENCE },
          ["2"] = { normal = PWS, shift = FADE },
          ["3"] = { normal = FLASH_HEAL, shift = HEAL, alt = RENEW },
          ["4"] = { normal = PWF, shift = INNER_FIRE, alt = SHADOW_PROT, altshift = FEAR_WARD },
          X = { normal = DISPEL, shift = CURE_DISEASE, alt = MANA_BURN },
        },
        [3] = {
          BUTTON4 = { normal = SEQ(SWP, MIND_FLAY) },
          BUTTON5 = { normal = SHOOT, shift = MIND_FLAY },
          E = CONTROL,
          F = { normal = SWP },
          Q = { normal = PLAGUE, shift = VE },
          R = { normal = MIND_BLAST, shift = SWD },
          V = ITEMS,
          ["1"] = { normal = SILENCE },
          ["2"] = { normal = PWS, shift = FADE },
          ["3"] = { normal = FLASH_HEAL, shift = GREATER_HEAL, alt = RENEW },
          ["4"] = { normal = PWF, shift = INNER_FIRE, alt = SHADOW_PROT, altshift = FEAR_WARD },
          C = { normal = SHADOWFORM },
          X = { normal = DISPEL, shift = ABOLISH, alt = MANA_BURN },
        },
      },
    },
  },
}
