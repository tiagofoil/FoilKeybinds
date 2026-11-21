-- Hunter guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- Spells and order: Icy Veins WoW Forever Hunter leveling and rotation pages (read 2026-11-20).
-- No pet commands (attack, follow, stay): those stay on the pet bar. Mend Pet, Call Pet and Revive Pet are
-- hunter spells, so they sit on G. Raptor Strike is 14260: rank 1 (level 1) is not in the trainer data; the
-- macro casts by name. Auto Shot is not on a key: it is not in the trainer data the data test checks.
-- No castsequence: every Hunter attack (Arcane, Aimed, Multi, Summon Hawk, the melee strikes) has a cooldown,
-- and the shots without one (Hunter's Mark, the stings) are debuffs cast once per target.
-- Forever: Multi-Shot shares its cooldown with Aimed Shot and is for 2+ targets, so it sits with the area spells
-- on R. Summon Hawk shares its cooldown with Arcane Shot. Survival is a melee spec.
FoilKeybindsGuides = FoilKeybindsGuides or {}

local function S(id, name) return { spellID = id, name = name } end
local function T(id, name) return { spellID = id, name = name, talent = true } end

local RAPTOR, ARCANE, SERPENT, MARK = S(14260, "Raptor Strike"), S(3044, "Arcane Shot"), S(1978, "Serpent Sting"), S(1130, "Hunter's Mark")
local MONKEY, CONCUSSIVE, HAWK = S(13163, "Aspect of the Monkey"), S(5116, "Concussive Shot"), S(13165, "Aspect of the Hawk")
local CALL_PET, REVIVE_PET, MEND_PET = S(883, "Call Pet"), S(982, "Revive Pet"), S(136, "Mend Pet")
local WING_CLIP, MONGOOSE, IMMO_TRAP = S(2974, "Wing Clip"), S(1495, "Mongoose Bite"), S(13795, "Immolation Trap")
local MULTI, AIMED, DISENGAGE = S(2643, "Multi-Shot"), S(19434, "Aimed Shot"), S(781, "Disengage")
local FREEZING, CHEETAH, SCORPID = S(1499, "Freezing Trap"), S(5118, "Aspect of the Cheetah"), S(3043, "Scorpid Sting")
local RAPID, FROST_TRAP, FEIGN = S(3045, "Rapid Fire"), S(13809, "Frost Trap"), S(5384, "Feign Death")
local BEAST, FLARE, EXPLOSIVE = S(13161, "Aspect of the Beast"), S(1543, "Flare"), S(13813, "Explosive Trap")
local VIPER, VOLLEY, PACK, SCARE = S(3034, "Viper Sting"), S(1510, "Volley"), S(13159, "Aspect of the Pack"), S(1513, "Scare Beast")
local SUMMON_HAWK, INTIMIDATION, BESTIAL = T(1293241, "Summon Hawk"), T(19577, "Intimidation"), T(19574, "Bestial Wrath")
local SNIPER, STRIDER = T(1310687, "Sniper Shot"), T(1317257, "Strider Kick")

-- Home keys (docs/spec-v6.md): the main attack on Mouse 4, the second on Mouse 5, slows and traps on E,
-- Serpent Sting on F, Mark and the other stings on Q, the big shot on R with area on Shift, Alt and Alt+Shift
-- and Rapid Fire on Ctrl, pet care on G, aspects on C.
-- Keys every spec shares from 20 on: crowd control, stings, escapes, pet, consumables.
local CC = { normal = CONCUSSIVE, shift = WING_CLIP, alt = FREEZING, altshift = SCARE }
local SERPENT_KEY = { normal = SERPENT, shift = IMMO_TRAP }
local STINGS2 = { normal = MARK, shift = SCORPID }
local STINGS3 = { normal = MARK, shift = SCORPID, alt = VIPER }
local ESCAPES = { normal = FEIGN, shift = DISENGAGE, alt = FROST_TRAP }
local PET = { normal = MEND_PET, shift = CALL_PET, alt = REVIVE_PET }
local ASPECTS2 = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = BEAST }
local ASPECTS3 = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = PACK }
local UTILITY = { normal = FLARE }
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }
-- Ranged specs: Arcane Shot is the second attack, the melee strikes are the fallback when a mob reaches you.
local RANGED_SECOND = { normal = ARCANE, shift = RAPTOR, alt = MONGOOSE }

FoilKeybindsGuides.HUNTER = {
  suggested = 11372, -- Beast Mastery levels best (Icy Veins: the strongest leveler in Forever)
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet. Auto Shot and Serpent Sting at range, Arcane Shot from 6,
  -- Raptor Strike once the mob is in melee. Multi-Shot (18) is for groups, so it waits on R Shift.
  shared = {
    BUTTON4 = { normal = ARCANE },
    BUTTON5 = { normal = RAPTOR, shift = MONGOOSE },
    E = { normal = CONCUSSIVE, shift = WING_CLIP },
    F = SERPENT_KEY,
    Q = { normal = MARK },
    R = { shift = MULTI },
    V = ITEMS,
    G = PET,
    C = { normal = HAWK, shift = MONKEY },
  },
  specs = {
    [11372] = {
      name = "Beast Mastery",
      priority = {
        { spellID = 1130, level = 6, en = "Mark the target before the pull, then send the pet in first.",
          ptBR = "Marque o alvo antes de puxar e mande o pet na frente." },
        { spellID = 1978, level = 4, en = "Nature DoT. Cast it once the pet has hit the target a few times.",
          ptBR = "DoT de Natureza. Aplique depois que o pet já bateu algumas vezes no alvo." },
        { spellID = 1293241, level = 25, talent = true, en = "Your top button: keep two hawks on the target. Shares a cooldown with Arcane Shot.",
          ptBR = "Seu botão principal: mantenha dois falcões no alvo. Divide a recarga com o tiro arcano." },
        { spellID = 19434, level = 20, en = "Your hardest shot. Cast it every time it is ready.",
          ptBR = "Seu tiro mais forte. Use sempre que estiver pronto." },
        { spellID = 3044, level = 6, en = "Instant shot. Before 25 it is your main shot; later only when both hawks are up and you have mana.",
          ptBR = "Tiro instantâneo. Antes do 25 é o seu tiro principal; depois, só com os dois falcões ativos e mana sobrando." },
        { spellID = 2643, level = 18, en = "Two or more enemies: use it instead of Aimed Shot (they share a cooldown).",
          ptBR = "Dois ou mais inimigos: use no lugar do tiro forte (os dois dividem a recarga)." },
        { spellID = 13813, level = 34, en = "Fire trap for groups. Drop it every time it is ready.",
          ptBR = "Armadilha de Fogo para grupos. Coloque sempre que estiver pronta." },
        { spellID = 19574, level = 40, talent = true, en = "Big pet cooldown: more damage and immune to crowd control. Elites and hard pulls.",
          ptBR = "Grande recarga do pet: mais dano e imune a controle. Para elites e combates difíceis." },
        { spellID = 3045, level = 26, en = "Faster shots for a short time. Save it for elites and hard fights.",
          ptBR = "Tiros mais rápidos por pouco tempo. Guarde para elites e lutas difíceis." },
        { spellID = 19577, level = 30, talent = true, en = "Your pet stuns the target and gains a lot of threat. Use it often.",
          ptBR = "Seu pet atordoa o alvo e ganha muita ameaça. Use com frequência." },
        { spellID = 136, level = 12, en = "Heals your pet over time. Watch its health all the time.",
          ptBR = "Cura o seu pet ao longo do tempo. Fique de olho na vida dele o tempo todo." },
      },
      -- Summon Hawk is learned at 25, so Mouse 4 shows faded from 20 to 24; Arcane Shot on Mouse 5 covers it.
      -- Intimidation stops a cast, so it sits on the interrupt key. Bestial Wrath is a pet cooldown on G Ctrl:
      -- R has no free slot left after the big shot, three area spells and Rapid Fire.
      templates = {
        [2] = {
          BUTTON4 = { normal = SUMMON_HAWK },
          BUTTON5 = RANGED_SECOND,
          E = CC,
          F = SERPENT_KEY,
          Q = STINGS2,
          R = { normal = AIMED, shift = MULTI, alt = EXPLOSIVE, ctrl = RAPID },
          V = ITEMS,
          ["1"] = { normal = INTIMIDATION },
          ["2"] = ESCAPES,
          G = PET,
          C = ASPECTS2,
          X = UTILITY,
        },
        [3] = {
          BUTTON4 = { normal = SUMMON_HAWK },
          BUTTON5 = RANGED_SECOND,
          E = CC,
          F = SERPENT_KEY,
          Q = STINGS3,
          R = { normal = AIMED, shift = MULTI, alt = EXPLOSIVE, altshift = VOLLEY, ctrl = RAPID },
          V = ITEMS,
          ["1"] = { normal = INTIMIDATION },
          ["2"] = ESCAPES,
          G = { normal = MEND_PET, shift = CALL_PET, alt = REVIVE_PET, ctrl = BESTIAL },
          C = ASPECTS3,
          X = UTILITY,
        },
      },
    },
    [11371] = {
      name = "Marksmanship",
      priority = {
        { spellID = 1130, level = 6, en = "Mark the target before the pull, then send the pet in first.",
          ptBR = "Marque o alvo antes de puxar e mande o pet na frente." },
        { spellID = 1978, level = 4, en = "Nature DoT. Keep it on the target until it dies: a talent pays you for that.",
          ptBR = "DoT de Natureza. Mantenha no alvo até ele morrer: um talento recompensa isso." },
        { spellID = 1310687, level = 40, talent = true, en = "Your strongest shot, with a long cast. Open the fight with it.",
          ptBR = "Seu tiro mais forte, com conjuração longa. Abra o combate com ele." },
        { spellID = 19434, level = 20, en = "Your main shot. Cast it every time it is ready.",
          ptBR = "Seu tiro principal. Use sempre que estiver pronto." },
        { spellID = 1293241, level = 25, talent = true, en = "Beast Mastery talent you reach late. Once you have it, keep two hawks up.",
          ptBR = "Talento de Domínio das Feras que chega tarde. Quando tiver, mantenha dois falcões ativos." },
        { spellID = 3044, level = 6, en = "Instant shot for the gaps, when you have mana to spare.",
          ptBR = "Tiro instantâneo para os intervalos, quando sobrar mana." },
        { spellID = 2643, level = 18, en = "Two or more enemies: use it instead of Aimed Shot (they share a cooldown).",
          ptBR = "Dois ou mais inimigos: use no lugar do tiro principal (os dois dividem a recarga)." },
        { spellID = 13813, level = 34, en = "Fire trap for groups. Drop it every time it is ready.",
          ptBR = "Armadilha de Fogo para grupos. Coloque sempre que estiver pronta." },
        { spellID = 3045, level = 26, en = "Faster shots for a short time. Save it for elites and hard fights.",
          ptBR = "Tiros mais rápidos por pouco tempo. Guarde para elites e lutas difíceis." },
        { spellID = 781, level = 20, en = "You pulled the enemy off your pet: use it to drop your threat.",
          ptBR = "Você tirou o inimigo do pet: use para baixar a sua ameaça." },
      },
      -- Aimed Shot is the main shot, so it takes Mouse 4. Sniper Shot (40) is the big hit on R; before 40 R holds
      -- Rapid Fire, which moves to Ctrl when Sniper Shot comes. Summon Hawk shares Arcane Shot's cooldown, so it
      -- sits next to it on Mouse 5.
      templates = {
        [2] = {
          BUTTON4 = { normal = AIMED },
          BUTTON5 = RANGED_SECOND,
          E = CC,
          F = SERPENT_KEY,
          Q = STINGS2,
          R = { normal = RAPID, shift = MULTI, alt = EXPLOSIVE },
          V = ITEMS,
          ["2"] = ESCAPES,
          G = PET,
          C = ASPECTS2,
          X = UTILITY,
        },
        [3] = {
          BUTTON4 = { normal = AIMED },
          BUTTON5 = { normal = ARCANE, shift = SUMMON_HAWK, alt = RAPTOR, altshift = MONGOOSE },
          E = CC,
          F = SERPENT_KEY,
          Q = STINGS3,
          R = { normal = SNIPER, shift = MULTI, alt = EXPLOSIVE, altshift = VOLLEY, ctrl = RAPID },
          V = ITEMS,
          ["2"] = ESCAPES,
          G = PET,
          C = ASPECTS3,
          X = UTILITY,
        },
      },
    },
    [11370] = {
      name = "Survival",
      priority = {
        { spellID = 1130, level = 6, en = "Mark the target before the pull, then send the pet in first.",
          ptBR = "Marque o alvo antes de puxar e mande o pet na frente." },
        { spellID = 1978, level = 4, en = "Nature DoT. Cast it once and let it run out.",
          ptBR = "DoT de Natureza. Aplique uma vez e deixe acabar." },
        { spellID = 3044, level = 6, en = "Instant shot while the enemy runs at you, and again after you kick out.",
          ptBR = "Tiro instantâneo enquanto o inimigo corre até você, e de novo depois do chute." },
        { spellID = 14260, level = 8, en = "Your most important attack: a strong melee hit. Use it on cooldown.",
          ptBR = "Seu ataque mais importante: golpe corpo a corpo forte. Use sempre que estiver pronto." },
        { spellID = 1495, level = 16, en = "Your second melee hit. It lights up after you dodge; use it right away.",
          ptBR = "Seu segundo golpe corpo a corpo. Fica disponível depois que você se esquiva; use na hora." },
        { spellID = 1317257, level = 30, talent = true, en = "Melee kick that makes you run faster for a moment. Use it on cooldown.",
          ptBR = "Chute corpo a corpo que deixa você mais rápido por um instante. Use sempre que estiver pronto." },
        { spellID = 13795, level = 16, en = "Fire trap: drop it once you are in melee and keep it going.",
          ptBR = "Armadilha de Fogo: coloque quando estiver no corpo a corpo e mantenha ativa." },
        { spellID = 2643, level = 18, en = "Your ranged shot over Aimed Shot while leveling, and your area shot.",
          ptBR = "Seu tiro à distância no lugar do tiro forte enquanto sobe de nível, e o seu tiro em área." },
        { spellID = 13813, level = 34, en = "Fire trap for groups. Drop it every time it is ready.",
          ptBR = "Armadilha de Fogo para grupos. Coloque sempre que estiver pronta." },
        { spellID = 3045, level = 26, en = "Faster attacks, melee too. Save it for elites and hard fights.",
          ptBR = "Ataques mais rápidos, corpo a corpo também. Guarde para elites e lutas difíceis." },
        { spellID = 13161, level = 30, en = "Your aspect as a melee: faster melee swings.",
          ptBR = "Seu aspecto no corpo a corpo: golpes corpo a corpo mais rápidos." },
      },
      -- Melee spec on Forever: Raptor Strike on Mouse 4, Mongoose Bite on Mouse 5 (the source calls it the second
      -- melee attack, used on cooldown at 60), Strider Kick (30) is the big hit on R. Aspect of the Beast on C.
      -- Aimed Shot only at 60, cast once before running in.
      templates = {
        [2] = {
          BUTTON4 = { normal = RAPTOR },
          BUTTON5 = { normal = MONGOOSE, shift = ARCANE },
          E = CC,
          F = SERPENT_KEY,
          Q = STINGS2,
          R = { normal = STRIDER, shift = MULTI, alt = EXPLOSIVE, ctrl = RAPID },
          V = ITEMS,
          ["2"] = ESCAPES,
          G = PET,
          C = { normal = BEAST, shift = HAWK, alt = CHEETAH, altshift = MONKEY },
          X = UTILITY,
        },
        [3] = {
          BUTTON4 = { normal = RAPTOR },
          BUTTON5 = { normal = MONGOOSE, shift = ARCANE, alt = AIMED },
          E = CC,
          F = SERPENT_KEY,
          Q = STINGS3,
          R = { normal = STRIDER, shift = MULTI, alt = EXPLOSIVE, altshift = VOLLEY, ctrl = RAPID },
          V = ITEMS,
          ["2"] = ESCAPES,
          G = PET,
          C = { normal = BEAST, shift = HAWK, alt = CHEETAH, altshift = PACK },
          X = UTILITY,
        },
      },
    },
  },
}
