-- Shaman guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Priorities and level ranges from the Icy Veins WoW Forever Shaman guides (leveling and rotation pages, read
-- 2026-11-20). Lightning Bolt and Healing Wave are granted at level 1 on Forever (trainer data bound 8 and 6).
-- Mana Tide Totem is 17354, the rank the trainer sells at 38: the talent rank's Forever page shows no real
-- level, so the row carries the trainer level, as Druid.lua does for Claw.
-- Talent levels: the level Icy Veins names in its leveling builds (Stormstrike 25, Water Shield 20 in the
-- Restoration build, Nature's Swiftness 30, Lightning Mastery and Riptide 40).
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end
local HSPOT, HEAL, EAT = { item = "HSPOT" }, { item = "HEAL" }, { item = "EAT" }

local BOLT, EARTH_SHOCK, FLAME_SHOCK, FROST_SHOCK = S(403, "Lightning Bolt"), S(8042, "Earth Shock"), S(8050, "Flame Shock"), S(8056, "Frost Shock")
local HW, LHW, SHIELD, PURGE = S(331, "Healing Wave"), S(8004, "Lesser Healing Wave"), S(324, "Lightning Shield"), S(370, "Purge")
local ROCKBITER, FLAMETONGUE, WINDFURY = S(8017, "Rockbiter Weapon"), S(8024, "Flametongue Weapon"), S(8232, "Windfury Weapon")
local STONESKIN, EARTHBIND, STONECLAW, STRENGTH = S(8071, "Stoneskin Totem"), S(2484, "Earthbind Totem"), S(5730, "Stoneclaw Totem"), S(8075, "Strength of Earth Totem")
local SEARING, FIRE_NOVA, MAGMA = S(3599, "Searing Totem"), S(408341, "Fire Nova"), S(8190, "Magma Totem")
local STREAM, SPRING, POISON_TOTEM, TREMOR = S(5394, "Healing Stream Totem"), S(5675, "Mana Spring Totem"), S(8166, "Poison Cleansing Totem"), S(8143, "Tremor Totem")
local GROUNDING, WF_TOTEM, CALL, RECALL = S(8177, "Grounding Totem"), S(8512, "Windfury Totem"), S(66842, "Call of the Elements"), S(36936, "Totemic Recall")
local CURE_POISON, CURE_DISEASE, SPIRIT, WOLF = S(526, "Cure Poison"), S(2870, "Cure Disease"), S(2008, "Ancestral Spirit"), S(2645, "Ghost Wolf")
local CHAIN_LIGHTNING, CHAIN_HEAL, MANA_TIDE = S(421, "Chain Lightning"), S(1064, "Chain Heal"), S(17354, "Mana Tide Totem")
local STORMSTRIKE, RIPTIDE, WATER_SHIELD = T(17364, "Stormstrike"), T(408521, "Riptide"), T(408510, "Water Shield")
local MASTERY, SWIFTNESS = T(16582, "Lightning Mastery"), T(16188, "Nature's Swiftness")

-- Home keys (docs/spec-v6.md). No castsequence: the shocks share a cooldown and the totems are dropped once
-- per pull. Earth Shock interrupts: on 1, or only on the mouse button when it is also the attack there; Frost Shock and
-- Earthbind on E, Flame Shock on F, Purge on Q, Ghost Wolf on C.
-- R is the fire key: the big spell of the spec on the plain press (Searing Totem before 20), Fire Nova on Shift
-- (on Forever a spell that bursts from your Fire totem, so the Fire totems sit on the same key), Magma on Alt,
-- Searing on Alt+Shift. Totems by job, not by element: the set Icy Veins says to keep up while leveling (Strength
-- of Earth, Stoneskin, Mana Spring, Windfury; Call of the Elements drops them all) on T, a far buff key; Stoneclaw
-- and Grounding on 2 (they take hits and spells for you), Healing Stream on 3 (a heal), Tremor, Poison Cleansing
-- and Totemic Recall on X (situational). Lightning Shield, Water Shield and the weapon buffs on 4.
local ITEMS = { normal = HSPOT, shift = HEAL, alt = EAT }
local CC = { normal = FROST_SHOCK, shift = EARTHBIND }
local DOT = { normal = FLAME_SHOCK }
local DEBUFF = { normal = PURGE }
local KICK = { normal = EARTH_SHOCK }
local GUARD = { normal = STONECLAW, shift = GROUNDING }
local SELF_HEALS2 = { normal = LHW, shift = HW, alt = STREAM }
local SELF_HEALS3 = { normal = LHW, shift = HW, alt = STREAM, altshift = CHAIN_HEAL }
local TOTEMS = { normal = CALL, shift = STRENGTH, alt = STONESKIN, altshift = SPRING, ctrl = WF_TOTEM }
local SITUATIONAL = { normal = TREMOR, shift = POISON_TOTEM, alt = RECALL }
local CURES = { normal = CURE_POISON, shift = CURE_DISEASE, alt = SPIRIT }
local FORM = { normal = WOLF }
local function FIRE(big, ctrl) return { normal = big, shift = FIRE_NOVA, alt = MAGMA, altshift = SEARING, ctrl = ctrl } end

FoilKeybindsGuides.SHAMAN = {
  -- Icy Veins does not rank the specs for leveling. Enhancement: melee with self heals, the one of the three
  -- not told it struggles on damage (Elemental) or should not solo (Restoration).
  suggested = 11363,
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same core spells for all three (Lightning Bolt, Earth
  -- Shock, Flame Shock, Searing Totem, Fire Nova from 12).
  shared = {
    BUTTON4 = { normal = BOLT },
    BUTTON5 = { normal = EARTH_SHOCK },
    E = { normal = EARTHBIND },
    F = DOT,
    Q = DEBUFF,
    R = { normal = SEARING, shift = FIRE_NOVA },
    V = ITEMS,
    ["2"] = { normal = STONECLAW },
    ["3"] = { normal = HW },
    ["4"] = { normal = SHIELD, shift = ROCKBITER, alt = FLAMETONGUE },
    T = { normal = STRENGTH, shift = STONESKIN },
    X = { normal = TREMOR },
    Z = { normal = CURE_POISON, shift = SPIRIT },
  },
  specs = {
    [11326] = {
      name = "Elemental Combat",
      priority = {
        { spellID = 403, level = 1, en = "Main nuke while leveling. Open from max range with it.",
          ptBR = "Ataque principal ao subir de nível. Abra o combate com ele do alcance máximo." },
        { spellID = 8050, level = 10, en = "Keep its DoT on your main target, above all on enemies that live a while.",
          ptBR = "Mantenha o DoT no seu alvo principal, ainda mais em inimigos que demoram a morrer." },
        { spellID = 408341, level = 12, en = "Area burst from your Fire totem. Use it on 3 or more enemies; it costs a lot of mana.",
          ptBR = "Explosão em área que sai do seu totem de fogo. Use em 3 ou mais inimigos; gasta muita mana." },
        { spellID = 421, level = 32, en = "Hits your target and jumps to enemies nearby. On packs, cast it on cooldown.",
          ptBR = "Atinge o seu alvo e pula para inimigos próximos. Em grupos de inimigos, use sempre que puder." },
        { spellID = 16582, level = 40, talent = true, en = "3-minute cooldown: no Chain Lightning cooldown and a faster Lightning Bolt. Use it on elites and big pulls.",
          ptBR = "Recarga de 3 minutos: o seu raio em cadeia fica sem recarga e o raio simples sai mais rápido. Use em elites e puxadas grandes." },
        { spellID = 3599, level = 10, en = "Fire totem for one target; Fire Nova needs a Fire totem down. Drop Magma Totem on packs.",
          ptBR = "Totem de fogo para um alvo; a explosão em área precisa de um totem de fogo no chão. Em grupos, use o totem de área." },
        { spellID = 8042, level = 4, en = "Interrupts a cast. Use it to pull casters into your area spells.",
          ptBR = "Interrompe uma conjuração. Use para trazer conjuradores até as suas magias em área." },
        { spellID = 331, level = 1, en = "Heal up between pulls. It is very mana efficient.",
          ptBR = "Cure-se entre uma puxada e outra. Gasta pouca mana pela cura que dá." },
      },
      templates = {
        [2] = {
          BUTTON4 = { normal = BOLT },
          BUTTON5 = { normal = EARTH_SHOCK },
          E = CC,
          F = DOT,
          Q = DEBUFF,
          R = FIRE(CHAIN_LIGHTNING),
          V = ITEMS,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS2,
          ["4"] = { normal = SHIELD, shift = FLAMETONGUE, alt = ROCKBITER },
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
        [3] = {
          BUTTON4 = { normal = BOLT },
          BUTTON5 = { normal = EARTH_SHOCK },
          E = CC,
          F = DOT,
          Q = DEBUFF,
          R = FIRE(CHAIN_LIGHTNING, MASTERY),
          V = ITEMS,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS3,
          ["4"] = { normal = SHIELD, shift = FLAMETONGUE, alt = ROCKBITER, altshift = WATER_SHIELD },
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
      },
    },
    [11363] = {
      name = "Enhancement",
      priority = {
        { spellID = 8232, level = 30, en = "Keep your weapon imbued. Before 30: Rockbiter solo, Flametongue in groups.",
          ptBR = "Mantenha a arma encantada. Antes do nível 30, use o bônus de arma de pedra sozinho e o de fogo em grupo." },
        { spellID = 17364, level = 25, talent = true, en = "Big weapon hit that makes your next shock stronger. Use it on cooldown.",
          ptBR = "Golpe forte de arma que deixa o seu próximo choque mais forte. Use sempre que estiver disponível." },
        { spellID = 8042, level = 4, en = "Your main attack from level 4. Use it on cooldown; it also interrupts.",
          ptBR = "Seu ataque principal desde o nível 4. Use sempre que puder; também interrompe." },
        { spellID = 8050, level = 10, en = "Keep its DoT up in long fights and groups. It shares the shock cooldown.",
          ptBR = "Mantenha o DoT em lutas longas e em grupo. Divide a recarga com os outros choques." },
        { spellID = 408341, level = 12, en = "Area damage from your Fire totem. Use it when mana allows.",
          ptBR = "Dano em área que sai do seu totem de fogo. Use quando a mana deixar." },
        { spellID = 8190, level = 26, en = "Fire totem for packs if mana allows. Searing Totem when mana is short.",
          ptBR = "Totem de fogo para grupos de inimigos, se a mana deixar. Com pouca mana, use o totem de um alvo." },
        { spellID = 403, level = 1, en = "Pull from range. Later, cast it at 5 Maelstrom Weapon stacks.",
          ptBR = "Puxe de longe com ele. Mais tarde, use quando o talento de acúmulos chegar a 5." },
        { spellID = 8004, level = 20, en = "Quick heal when a fight goes wrong. Healing Wave after the pull.",
          ptBR = "Cura rápida quando a luta aperta. Depois da puxada, use a cura grande." },
      },
      templates = {
        -- Melee: Earth Shock is the main attack from 4 on (Mouse 4, it also interrupts), Stormstrike the big hit
        -- on R from 25, Lightning Bolt to pull on Mouse 5.
        [2] = {
          BUTTON4 = { normal = EARTH_SHOCK },
          BUTTON5 = { normal = BOLT },
          E = CC,
          F = DOT,
          Q = DEBUFF,
          R = FIRE(STORMSTRIKE),
          V = ITEMS,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS2,
          ["4"] = { normal = SHIELD, shift = WINDFURY, alt = FLAMETONGUE, altshift = ROCKBITER },
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
        [3] = {
          BUTTON4 = { normal = EARTH_SHOCK },
          BUTTON5 = { normal = BOLT },
          E = CC,
          F = DOT,
          Q = DEBUFF,
          R = FIRE(STORMSTRIKE),
          V = ITEMS,
          ["2"] = GUARD,
          ["3"] = SELF_HEALS3,
          ["4"] = { normal = SHIELD, shift = WINDFURY, alt = FLAMETONGUE, altshift = ROCKBITER, ctrl = WATER_SHIELD },
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
      },
    },
    [11362] = {
      name = "Restoration",
      priority = {
        { spellID = 331, level = 1, en = "Your main heal while leveling. Talents make it strong and cheap.",
          ptBR = "Sua cura principal ao subir de nível. Os talentos deixam ela forte e barata." },
        { spellID = 408521, level = 40, talent = true, en = "Heal over time. Use it on hurt allies; it also makes Chain Heal stronger on them.",
          ptBR = "Cura ao longo do tempo. Use em aliados feridos; também deixa mais forte a cura em cadeia neles." },
        { spellID = 1064, level = 40, en = "Heal that jumps to hurt allies nearby. Start it on a target with Riptide.",
          ptBR = "Cura que pula para aliados feridos por perto. Comece num alvo que já tem a cura ao longo do tempo." },
        { spellID = 408510, level = 20, talent = true, en = "Shield that gives mana back. Keep it up in place of Lightning Shield.",
          ptBR = "Escudo que devolve mana. Mantenha ativo no lugar do escudo de raios." },
        { spellID = 5675, level = 26, en = "Water totem that gives mana back over time. Drop it before the pull.",
          ptBR = "Totem de água que devolve mana aos poucos. Coloque antes de puxar." },
        { spellID = 16188, level = 30, talent = true, en = "Your next heal is instant. Save it for an emergency.",
          ptBR = "A sua próxima cura sai instantânea. Guarde para uma emergência." },
        { spellID = 17354, level = 38, en = "Totem that gives the party a lot of mana. It comes from a talent.",
          ptBR = "Totem que devolve bastante mana ao grupo. Vem de um talento." },
        { spellID = 408341, level = 12, en = "With no one to heal, hit packs with it from your Fire totem.",
          ptBR = "Sem ninguém para curar, acerte grupos de inimigos com a explosão do seu totem de fogo." },
      },
      templates = {
        -- Heals on the plain press, solo damage on Shift (Lightning Bolt on Mouse 4, Chain Lightning on Mouse 5).
        -- Healing Wave is the main heal in every range (Icy Veins: most leveling heals are Healing Wave).
        -- 20-39: Nature's Swiftness is the big press on R. From 40: Riptide on Mouse 5, Chain Heal on R,
        -- Nature's Swiftness moves to 3 next to the other heals.
        [2] = {
          BUTTON4 = { normal = HW, shift = BOLT },
          BUTTON5 = { normal = LHW, shift = CHAIN_LIGHTNING },
          E = CC,
          F = DOT,
          Q = DEBUFF,
          R = FIRE(SWIFTNESS, MANA_TIDE),
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = { normal = STREAM },
          ["4"] = { normal = SHIELD, shift = WATER_SHIELD, alt = FLAMETONGUE, altshift = ROCKBITER },
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
        [3] = {
          BUTTON4 = { normal = HW, shift = BOLT },
          BUTTON5 = { normal = RIPTIDE, shift = CHAIN_LIGHTNING },
          E = CC,
          F = DOT,
          Q = DEBUFF,
          R = FIRE(CHAIN_HEAL, MANA_TIDE),
          V = ITEMS,
          ["1"] = KICK,
          ["2"] = GUARD,
          ["3"] = { normal = LHW, shift = STREAM, alt = SWIFTNESS },
          ["4"] = { normal = SHIELD, shift = WATER_SHIELD, alt = FLAMETONGUE, altshift = ROCKBITER },
          T = TOTEMS,
          X = SITUATIONAL,
          Z = CURES,
          C = FORM,
        },
      },
    },
  },
}
