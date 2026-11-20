-- Hunter guide. Shape and sources: see Warlock.lua and docs/spec-v4.md "Guide data package".
-- No pet commands (attack, follow, stay): those stay on the pet bar. Mend Pet, Call Pet and Revive Pet are
-- hunter spells. Raptor Strike is 14260: rank 1 (level 1) is not in the trainer data; the macro casts by name.
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
local DETERRENCE, TRUESHOT, INTIMIDATION = T(19263, "Deterrence"), T(1299346, "Trueshot Aura"), T(19577, "Intimidation")
local COUNTER, BESTIAL, SNIPER = T(19306, "Counterattack"), T(19574, "Bestial Wrath"), T(1310687, "Sniper Shot")

-- Keys every spec shares from 20 on: pet care on E, traps on R, escapes on G, consumables on V.
local PET = { normal = MEND_PET, shift = CALL_PET, alt = REVIVE_PET }
local TRAPS = { normal = FREEZING, shift = IMMO_TRAP, alt = FROST_TRAP, altshift = EXPLOSIVE }
local ITEMS = { normal = { item = "HSPOT" }, shift = { item = "HEAL" }, alt = { item = "EAT" } }

FoilKeybindsGuides.HUNTER = {
  suggested = 11372, -- Beast Mastery levels best: a strong pet tanks while you shoot
  tested = false,
  -- Levels 1-19, every spec: no talent spell yet, the same shots for all three.
  shared = {
    ["1"] = { normal = ARCANE, shift = MULTI },
    ["2"] = { normal = SERPENT },
    ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP },
    ["4"] = { normal = RAPTOR, shift = MONGOOSE },
    Q = { normal = MARK },
    E = PET,
    R = { normal = IMMO_TRAP },
    F = { normal = HAWK, shift = MONKEY },
    V = ITEMS,
  },
  specs = {
    [11372] = {
      name = "Beast Mastery",
      meanings = { ["1"] = "main", ["2"] = "dot", ["3"] = "cc", ["4"] = "dot", ["5"] = "buff", Q = "utility", E = "pet", R = "utility", T = "aoe", F = "buff", G = "defense", V = "items" },
      priority = {
        { spellID = 1130, level = 6, en = "Mark the target first: your shots and your pet hit it harder.",
          ptBR = "Marque o alvo primeiro: seus tiros e o seu pet causam mais dano nele." },
        { spellID = 1978, level = 4, en = "Nature DoT. Put it on targets that will live a while.",
          ptBR = "DoT de Natureza. Aplique em alvos que vão durar um pouco." },
        { spellID = 3044, level = 6, en = "Instant shot. Use it on cooldown while the pet holds the target.",
          ptBR = "Tiro instantâneo. Use sempre que estiver disponível enquanto o pet segura o alvo." },
        { spellID = 2643, level = 18, en = "Hits up to three enemies. Good on a single target too.",
          ptBR = "Acerta até três inimigos. Também é bom contra um alvo só." },
        { spellID = 19574, level = 40, talent = true, en = "Sends your pet into a rage. Use it on hard pulls.",
          ptBR = "Deixa o seu pet enfurecido. Use nos combates difíceis." },
        { spellID = 19577, level = 30, talent = true, en = "Your pet stuns the target. Use it to stop a cast or to save your pet.",
          ptBR = "Seu pet atordoa o alvo. Use para interromper uma conjuração ou para salvar o pet." },
        { spellID = 3045, level = 26, en = "Faster shots for a short time. Save it for elites and hard fights.",
          ptBR = "Tiros mais rápidos por pouco tempo. Guarde para elites e lutas difíceis." },
        { spellID = 136, level = 12, en = "Heals your pet over time, during and between pulls.",
          ptBR = "Cura o seu pet ao longo do tempo, durante e entre os combates." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = ARCANE, shift = MULTI },
          ["2"] = { normal = SERPENT, shift = SCORPID },
          ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP, alt = SCARE },
          ["4"] = { normal = RAPTOR, shift = MONGOOSE },
          ["5"] = { normal = RAPID, shift = INTIMIDATION },
          Q = { normal = MARK, shift = FLARE },
          E = PET,
          R = TRAPS,
          F = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = BEAST },
          G = { normal = FEIGN, shift = DISENGAGE },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = ARCANE, shift = MULTI },
          ["2"] = { normal = SERPENT, shift = SCORPID, alt = VIPER },
          ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP, alt = SCARE },
          ["4"] = { normal = RAPTOR, shift = MONGOOSE },
          ["5"] = { normal = RAPID, shift = INTIMIDATION, alt = BESTIAL },
          Q = { normal = MARK, shift = FLARE },
          E = PET,
          R = TRAPS,
          T = { normal = VOLLEY },
          F = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = PACK },
          G = { normal = FEIGN, shift = DISENGAGE },
          V = ITEMS,
        },
      },
    },
    [11371] = {
      name = "Marksmanship",
      meanings = { ["1"] = "main", ["2"] = "dot", ["3"] = "cc", ["4"] = "dot", ["5"] = "main", Q = "utility", E = "pet", R = "utility", T = "aoe", F = "buff", G = "defense", V = "items" },
      priority = {
        { spellID = 1130, level = 6, en = "Mark the target first: every shot hits it harder.",
          ptBR = "Marque o alvo primeiro: todos os tiros causam mais dano nele." },
        { spellID = 19434, level = 20, en = "Hard-hitting shot with a cast. Open the fight with it.",
          ptBR = "Tiro forte com tempo de conjuração. Abra o combate com ele." },
        { spellID = 1978, level = 4, en = "Nature DoT. Put it on targets that will live a while.",
          ptBR = "DoT de Natureza. Aplique em alvos que vão durar um pouco." },
        { spellID = 3044, level = 6, en = "Instant shot to fill the gaps.", ptBR = "Tiro instantâneo para preencher os intervalos." },
        { spellID = 2643, level = 18, en = "Shares a cooldown with Aimed Shot. Use it when Aimed Shot is not ready.",
          ptBR = "Divide o tempo de recarga com o tiro forte de conjuração. Use quando ele não estiver pronto." },
        { spellID = 1299346, level = 25, talent = true, en = "Aura that adds ranged attack power for you and the group. Keep it on.",
          ptBR = "Aura que aumenta o poder de ataque à distância seu e do grupo. Mantenha ativa." },
        { spellID = 1310687, level = 40, talent = true, en = "Long cast shot from far away. Open with it on a target that is not coming at you yet.",
          ptBR = "Tiro de conjuração longa e de muito longe. Abra com ele num alvo que ainda não veio até você." },
        { spellID = 3045, level = 26, en = "Faster shots for a short time. Save it for elites and hard fights.",
          ptBR = "Tiros mais rápidos por pouco tempo. Guarde para elites e lutas difíceis." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = ARCANE, shift = MULTI },
          ["2"] = { normal = SERPENT, shift = SCORPID },
          ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP, alt = SCARE },
          ["4"] = { normal = RAPTOR, shift = MONGOOSE },
          ["5"] = { normal = AIMED, shift = RAPID },
          Q = { normal = MARK, shift = FLARE },
          E = PET,
          R = TRAPS,
          F = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = TRUESHOT },
          G = { normal = FEIGN, shift = DISENGAGE },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = ARCANE, shift = MULTI },
          ["2"] = { normal = SERPENT, shift = SCORPID, alt = VIPER },
          ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP, alt = SCARE },
          ["4"] = { normal = RAPTOR, shift = MONGOOSE },
          ["5"] = { normal = AIMED, shift = RAPID, alt = SNIPER },
          Q = { normal = MARK, shift = FLARE },
          E = PET,
          R = TRAPS,
          T = { normal = VOLLEY },
          F = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = TRUESHOT },
          G = { normal = FEIGN, shift = DISENGAGE, alt = PACK },
          V = ITEMS,
        },
      },
    },
    [11370] = {
      name = "Survival",
      meanings = { ["1"] = "main", ["2"] = "dot", ["3"] = "cc", ["4"] = "dot", ["5"] = "buff", Q = "utility", E = "pet", R = "utility", T = "aoe", F = "buff", G = "defense", V = "items" },
      priority = {
        { spellID = 1130, level = 6, en = "Mark the target first: you and your pet hit it harder.",
          ptBR = "Marque o alvo primeiro: você e o seu pet causam mais dano nele." },
        { spellID = 1978, level = 4, en = "Nature DoT. Put it on targets that will live a while.",
          ptBR = "DoT de Natureza. Aplique em alvos que vão durar um pouco." },
        { spellID = 3044, level = 6, en = "Instant shot while the enemy runs at you.",
          ptBR = "Tiro instantâneo enquanto o inimigo corre até você." },
        { spellID = 13795, level = 16, en = "Fire trap: drop it at your feet before the enemy reaches you.",
          ptBR = "Armadilha de Fogo: coloque aos seus pés antes do inimigo chegar." },
        { spellID = 14260, level = 8, en = "Strong melee hit when the enemy is on you.",
          ptBR = "Golpe corpo a corpo forte quando o inimigo estiver colado em você." },
        { spellID = 1495, level = 16, en = "Use it right after you dodge.", ptBR = "Use logo depois de se esquivar." },
        { spellID = 19306, level = 30, talent = true, en = "Strike that lights up after you parry. Use it right away.",
          ptBR = "Golpe que fica disponível depois que você apara um ataque. Use na hora." },
        { spellID = 19263, level = 20, talent = true, en = "More dodge and parry for a short time. Use it when several enemies hit you.",
          ptBR = "Mais esquiva e aparo por pouco tempo. Use quando vários inimigos baterem em você." },
      },
      templates = {
        [2] = {
          ["1"] = { normal = ARCANE, shift = MULTI },
          ["2"] = { normal = SERPENT, shift = SCORPID },
          ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP, alt = SCARE },
          ["4"] = { normal = RAPTOR, shift = MONGOOSE, alt = COUNTER },
          ["5"] = { normal = RAPID },
          Q = { normal = MARK, shift = FLARE },
          E = PET,
          R = TRAPS,
          F = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = BEAST },
          G = { normal = FEIGN, shift = DISENGAGE, alt = DETERRENCE },
          V = ITEMS,
        },
        [3] = {
          ["1"] = { normal = ARCANE, shift = MULTI },
          ["2"] = { normal = SERPENT, shift = SCORPID, alt = VIPER },
          ["3"] = { normal = CONCUSSIVE, shift = WING_CLIP, alt = SCARE },
          ["4"] = { normal = RAPTOR, shift = MONGOOSE, alt = COUNTER },
          ["5"] = { normal = RAPID },
          Q = { normal = MARK, shift = FLARE },
          E = PET,
          R = TRAPS,
          T = { normal = VOLLEY },
          F = { normal = HAWK, shift = MONKEY, alt = CHEETAH, altshift = PACK },
          G = { normal = FEIGN, shift = DISENGAGE, alt = DETERRENCE },
          V = ITEMS,
        },
      },
    },
  },
}
