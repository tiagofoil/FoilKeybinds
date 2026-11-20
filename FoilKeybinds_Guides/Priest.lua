-- Priest guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Smite and Lesser Heal rank 1 are starting spells (granted in the trainer data), learned at level 1.
-- Racial priest spells (Starshards, Feedback, Shadowguard and the like) stay out: most players never get them.
-- Shadowform is left out: its Forever tooltip shows no level requirement.
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
local SHOOT = S(5019, "Shoot")
-- One-button rotation: a castsequence that starts over on a new target and after combat.
local function SEQ(...) return { seq = { ... }, reset = { target = true, combat = true } } end

-- Home keys (docs/spec-v6.md): Mouse 4 is the rotation (Shadow, leveling) or the main heal (Holy,
-- Discipline), wand on Mouse 5, Psychic Scream on E, DoTs and the most pressed spell on F and Q,
-- Mind Blast or the big heal on R. Sequences hold only spells with no cooldown (Shadow Word: Pain, Smite,
-- Mind Flay): Mind Blast, Devouring Plague and Penance stay on their own keys.
-- Keys every spec shares from 20 on: wand, control, defense, buffs, dispels, consumables.
local CONTROL = { normal = SCREAM, shift = SHACKLE }
local DEFENSE = { normal = FADE }
local BUFFS = { normal = PWF, shift = INNER_FIRE, alt = DIVINE_SPIRIT, altshift = FEAR_WARD }
local DISPELS2 = { normal = DISPEL, shift = CURE_DISEASE }
local DISPELS3 = { normal = DISPEL, shift = ABOLISH }
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }

FoilKeybindsGuides.PRIEST = {
  suggested = 11622, -- Shadow levels best: DoTs that heal you, little time spent drinking
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three, all leveling solo.
  -- Smite (level 1) ends the sequence, so Mouse 4 casts from the first level (Shadow Word: Pain at 4).
  shared = {
    BUTTON4 = { normal = SEQ(SWP, SMITE, SMITE, SMITE) },
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
        { spellID = 17, level = 6, en = "Absorb shield. Put it on whoever will take damage, before it lands.",
          ptBR = "Escudo que absorve dano. Aplique em quem vai apanhar, antes do dano chegar." },
        { spellID = 402174, level = 30, talent = true, en = "Channeled volley that heals an ally or hurts an enemy. Use it on cooldown.",
          ptBR = "Rajada canalizada que cura um aliado ou causa dano num inimigo. Use sempre que estiver disponível." },
        { spellID = 10060, level = 40, talent = true, en = "Speeds up an ally's spells. Save it for hard fights.",
          ptBR = "Acelera os feitiços de um aliado. Guarde para lutas difíceis." },
        { spellID = 2061, level = 20, en = "Fast heal for sudden damage.", ptBR = "Cura rápida para dano repentino." },
        { spellID = 139, level = 8, en = "Heal over time. Cheap and good while you move.",
          ptBR = "Cura ao longo do tempo. Barata e boa para usar em movimento." },
        { spellID = 589, level = 4, en = "Shadow DoT for solo leveling. Put it on first.",
          ptBR = "DoT de Sombra para subir de nível sozinho. Aplique primeiro." },
        { spellID = 585, level = 1, en = "Holy nuke. Filler when nothing else is ready.",
          ptBR = "Ataque Sagrado. Preenchimento quando nada mais estiver pronto." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = FLASH_HEAL, shift = RENEW },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = PWS },
          Q = { normal = SWP, shift = HOLY_FIRE, alt = MIND_BLAST },
          R = { normal = HEAL, shift = PENANCE },
          V = ITEMS,
          ["2"] = DEFENSE,
          ["3"] = { normal = POH },
          ["4"] = BUFFS,
          X = DISPELS2,
        },
        [3] = {
          BUTTON4 = { normal = FLASH_HEAL, shift = RENEW, alt = HEAL },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = PWS },
          Q = { normal = SWP, shift = HOLY_FIRE, alt = MIND_BLAST },
          R = { normal = GREATER_HEAL, shift = PENANCE, ctrl = PI },
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
        { spellID = 139, level = 8, en = "Heal over time. Keep it on the tank.", ptBR = "Cura ao longo do tempo. Mantenha no tanque." },
        { spellID = 2061, level = 20, en = "Fast heal for sudden damage. Costs a lot of mana.",
          ptBR = "Cura rápida para dano repentino. Gasta bastante mana." },
        { spellID = 2054, level = 16, en = "Efficient heal for steady damage.", ptBR = "Cura eficiente para dano constante." },
        { spellID = 2060, level = 40, en = "Biggest heal. Slow cast: use it on a tank taking heavy hits.",
          ptBR = "Maior cura. Conjuração lenta: use num tanque que está apanhando muito." },
        { spellID = 401859, level = 40, talent = true, en = "Heal that jumps to the next hurt ally. Keep it going in the group.",
          ptBR = "Cura que pula para o próximo aliado ferido. Mantenha rodando no grupo." },
        { spellID = 15237, level = 20, talent = true, en = "Instant Holy damage and healing around you. Good on packs.",
          ptBR = "Dano Sagrado e cura instantâneos ao seu redor. Bom contra grupos de inimigos." },
        { spellID = 14914, level = 20, en = "Opener with a long cast: hits hard, then burns over time.",
          ptBR = "Abertura com conjuração longa: bate forte e depois queima ao longo do tempo." },
        { spellID = 585, level = 1, en = "Holy nuke. Your filler while leveling solo.",
          ptBR = "Ataque Sagrado. Seu preenchimento para subir de nível sozinho." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = FLASH_HEAL, shift = PWS },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = RENEW },
          Q = { normal = SWP, shift = HOLY_FIRE, alt = MIND_BLAST },
          R = { normal = HEAL, shift = HOLY_NOVA },
          V = ITEMS,
          ["2"] = DEFENSE,
          ["3"] = { normal = POH },
          ["4"] = BUFFS,
          X = DISPELS2,
        },
        [3] = {
          BUTTON4 = { normal = FLASH_HEAL, shift = PWS, alt = HEAL },
          BUTTON5 = { normal = SHOOT, shift = SMITE },
          E = CONTROL,
          F = { normal = RENEW, shift = POM },
          Q = { normal = SWP, shift = HOLY_FIRE, alt = MIND_BLAST },
          R = { normal = GREATER_HEAL, shift = HOLY_NOVA },
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
        { spellID = 17, level = 6, en = "Shield yourself before the pull so hits do not slow your casts.",
          ptBR = "Escudo em você antes do combate, para os golpes não atrasarem seus feitiços." },
        { spellID = 589, level = 4, en = "Shadow DoT. Put it on every target first.",
          ptBR = "DoT de Sombra. Aplique primeiro em todos os alvos." },
        { spellID = 15286, level = 30, talent = true, en = "Your Shadow damage heals you and your party. Put it on before your nukes.",
          ptBR = "Seu dano de Sombra cura você e o seu grupo. Aplique antes dos seus ataques." },
        { spellID = 2944, level = 20, en = "Disease DoT that heals you. Use it on cooldown on longer fights.",
          ptBR = "DoT de doença que cura você. Use sempre que puder em lutas mais longas." },
        { spellID = 8092, level = 10, en = "Big Shadow hit. Use it on cooldown.", ptBR = "Dano de Sombra forte. Use sempre que estiver disponível." },
        { spellID = 15407, level = 20, talent = true, en = "Channeled filler. Your main damage once the DoTs are up.",
          ptBR = "Preenchimento canalizado. Seu dano principal depois que os DoTs estiverem ativos." },
        { spellID = 1309595, level = 32, en = "Instant finisher. If the target lives, you take damage back.",
          ptBR = "Finalizador instantâneo. Se o alvo sobreviver, você sofre dano de volta." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = SEQ(SWP, MIND_FLAY, MIND_FLAY, MIND_FLAY), shift = SMITE },
          BUTTON5 = { normal = SHOOT, shift = MIND_FLAY },
          E = CONTROL,
          F = { normal = SWP },
          Q = { normal = PLAGUE, shift = VE },
          R = { normal = MIND_BLAST, shift = SWD },
          V = ITEMS,
          ["2"] = { normal = PWS, shift = FADE },
          ["3"] = { normal = FLASH_HEAL, shift = HEAL, alt = RENEW },
          ["4"] = { normal = PWF, shift = INNER_FIRE, alt = SHADOW_PROT, altshift = FEAR_WARD },
          X = { normal = DISPEL, shift = CURE_DISEASE, alt = MANA_BURN },
        },
        [3] = {
          BUTTON4 = { normal = SEQ(SWP, MIND_FLAY, MIND_FLAY, MIND_FLAY), shift = SMITE },
          BUTTON5 = { normal = SHOOT, shift = MIND_FLAY },
          E = CONTROL,
          F = { normal = SWP },
          Q = { normal = PLAGUE, shift = VE },
          R = { normal = MIND_BLAST, shift = SWD },
          V = ITEMS,
          ["2"] = { normal = PWS, shift = FADE },
          ["3"] = { normal = FLASH_HEAL, shift = GREATER_HEAL, alt = RENEW },
          ["4"] = { normal = PWF, shift = INNER_FIRE, alt = SHADOW_PROT, altshift = FEAR_WARD },
          X = { normal = DISPEL, shift = ABOLISH, alt = MANA_BURN },
        },
      },
    },
  },
}
