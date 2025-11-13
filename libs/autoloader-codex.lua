-- SPDX-License-Identifier: BSD-3-Clause
-- Copyright (c) 2025 NeatMachine

local codex = {}

codex.CORE_SETS = {
    idle = {
        default = "idle",
        refresh = "idle.refresh",
        dt = "idle.dt",
        mdt = "idle.mdt",
    },
    melee = {
        default = "melee",
        dt = "melee.dt",
        mdt = "melee.mdt",
        acc = "melee.acc",
        sb = "melee.sb",
        dw = "melee.dw"
    },
    magic = {
        default = "magic",
        macc = "magic.macc",
        mb = "magic.mb"
    },
    ranged = {
        default = "ranged",
        acc = "ranged.acc"
    },
    weaponskill = {
        default = "weaponskill"
    },
    resting = {
        hp = "resting",
        mp = "resting.mp"
    },
    precast = {
        fastcast = "fastcast"
    },
    movement = {
        default = "movement"
    }
}

codex.CASTING_SETS = {
    healing    = {
        default = "healing",
        weather = "healing.weather",
    },

    enfeebling = {
        default  = "enfeebling",
        macc     = "enfeebling.macc",
        mnd      = "enfeebling.mnd",
        int      = "enfeebling.int",
        skill    = "enfeebling.skill",
        duration = "enfeebling.duration",
    },

    enhancing  = {
        default     = "enhancing",
        duration    = "enhancing.duration",
        potency     = "enhancing.potency",
        mnd         = "enhancing.mnd",
        skill       = "enhancing.skill",
        enspell     = "enhancing.enspell",
        bar_status  = "enhancing.bar_status",
        bar_element = "enhancing.bar_element"
    },

    elemental  = {
        default    = "elemental",
        macc       = "elemental.macc",
        nuke       = "elemental.nuke",
        enfeeble   = "elemental.enfeeble",
        helix      = "elemental.helix",
        helix_dark = "elemental.helix_dark",
        cumulative = "elemental.cumulative",
        geo        = "elemental.geo",
        skill      = "elemental.skill",
    },

    dark       = {
        default     = "dark",
        enfeeble    = "dark.enfeeble",
        drain_aspir = "dark.drain_aspir",
        absorb      = "dark.absorb",
        skill       = "dark.skill",
    },

    divine     = {
        default = "divine",
        skill = "divine.skill",
        nuke = "divine.nuke"
    }
}

codex.INSTANT_SPELLS = { ["Stun"] = true }

codex.NON_REFRESHABLE_SPELLS = {
    ["Stoneskin"] = true,
    ["Aquaveil"] = true,
    ["Phalanx"] = true,
    ["Ice Spikes"] = true,
    ["Blaze Spikes"] = true,
    ["Shock Spikes"] = true,
}

function codex.get_base(name)
    if not name or name == "" then return "" end
    local s = tostring(name)
    local base = s:match("^(.-)%s+[IVX]+$") or s
    return (tostring(base or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

codex.STAT = {
    -- Core attributes / resources
    hp                     = "HP",
    mp                     = "MP",
    str                    = "STR",
    dex                    = "DEX",
    vit                    = "VIT",
    agi                    = "AGI",
    int                    = "INT",
    mnd                    = "MND",
    chr                    = "CHR",

    -- Offense / accuracy
    accuracy               = "Accuracy",
    ranged_accuracy        = "Ranged Accuracy",
    attack                 = "Attack",
    ranged_attack          = "Ranged Attack",
    magic_accuracy         = "Magic Accuracy",
    magic_atk_bonus        = "Magic Atk. Bonus",
    magic_damage           = "Magic Damage",
    ws_accuracy            = "Weapon skill Accuracy",

    -- Tempo / TP engine
    haste                  = "Haste",
    dual_wield             = "Dual Wield",
    store_tp               = "Store TP",
    save_tp                = "Save TP",
    tp_bonus               = "TP Bonus",
    snapshot               = "Snapshot",
    rapid_shot             = "Rapid Shot",
    fast_cast              = "Fast Cast",
    sird                   = "Spell interruption rate down",

    -- Multi / crit / WS / MB
    da                     = "Double Attack",
    ta                     = "Triple Attack",
    qa                     = "Quadruple Attack",
    crit_rate              = "Critical hit rate",
    crit_dmg               = "Critical hit damage",
    ws_dmg                 = "Weapon skill damage",
    sc_dmg                 = "Skillchain Bonus",
    mb_dmg                 = "Magic burst damage",
    mb_dmg_ii              = "Magic burst damage II",

    -- Defensive / evasion
    defense                = "Defense",
    evasion                = "Evasion",
    magic_evasion          = "Magic Evasion",
    pdt                    = "PDT",
    mdt                    = "MDT",
    dt                     = "Damage taken",
    breath_dt              = "Breath damage taken",
    pdl                    = "Physical damage limit",

    subtle_blow            = "Subtle Blow",
    subtle_blow_ii         = "Subtle Blow II",

    -- Enmity / recovery
    enmity                 = "Enmity",
    refresh                = "Refresh",
    regen                  = "Regen",
    regain                 = "Regain",

    hp_while_healing       = "HP recovered while healing",
    mp_while_healing       = "MP recovered while healing",

    -- Skills (combat)
    h2h_skill              = "Hand-to-Hand skill",
    dagger_skill           = "Dagger skill",
    sword_skill            = "Sword skill",
    great_sword_skill      = "Great Sword skill",
    axe_skill              = "Axe skill",
    great_axe_skill        = "Great Axe skill",
    scythe_skill           = "Scythe skill",
    polearm_skill          = "Polearm skill",
    katana_skill           = "Katana skill",
    gkt_skill              = "Great Katana skill",
    club_skill             = "Club skill",
    staff_skill            = "Staff skill",
    archery_skill          = "Archery skill",
    marksmanship_skill     = "Marksmanship skill",
    throwing_skill         = "Throwing skill",
    shield_skill           = "Shield skill",
    parrying_skill         = "Parrying skill",
    guarding_skill         = "Guarding skill",
    martial_arts           = "Martial Arts",
    evasion_skill          = "Evasion Skill",

    -- Skills (magic/perform)
    enhancing_skill        = "Enhancing magic skill",
    enfeebling_skill       = "Enfeebling magic skill",
    elemental_skill        = "Elemental magic skill",
    divine_skill           = "Divine magic skill",
    dark_skill             = "Dark magic skill",
    healing_skill          = "Healing magic skill",
    summoning_skill        = "Summoning magic skill",
    singing_skill          = "Singing skill",
    string_skill           = "String instrument skill",
    wind_skill             = "Wind instrument skill",
    ninjutsu_skill         = "Ninjutsu skill",
    geomancy_skill         = "Geomancy skill",
    handbell_skill         = "Handbell skill",

    cure_potency           = "Cure potency",
    cure_potency_received  = "Potency of Cure effects received",
    waltz_potency          = "Waltz potency",
    waltz_potency_received = "Potency of Waltz effects received",
    cure_potency_ii        = "Cure potency II",

    pet_accuracy           = "Pet: Accuracy",
    pet_attack             = "Pet: Attack",
    pet_ranged_accuracy    = "Pet: Ranged Accuracy",
    pet_ranged_attack      = "Pet: Ranged Attack",
    pet_magic_accuracy     = "Pet: Magic Accuracy",
    pet_magic_atk_bonus    = "Pet: Magic Atk. Bonus",
    pet_haste              = "Pet: Haste",
    pet_dt                 = "Pet: Damage taken",
    pet_pdt                = "Pet: PDT",
    pet_mdt                = "Pet: MDT",
    pet_evasion            = "Pet: Evasion",
    pet_magic_evasion      = "Pet: Magic Evasion",
    pet_store_tp           = "Pet: Store TP",
    pet_regen              = "Pet: Regen",
    pet_regain             = "Pet: Regain",


    -- Job/trait and utility
    quick_cast           = "Quick cast",
    divine_benison       = "Divine Benison",
    inquartata           = "Inquartata",
    occult_acumen        = "Occult Acumen",
    sublimation          = "Sublimation",

    -- Buff potency/duration
    song_effect_duration = "Song effect duration",
    enhancing_duration   = "Enhancing magic effect duration",
    indicolure_duration  = "Indicolure effect duration",
    enfeebling_duration  = "Enfeebling magic effect duration",

    -- GEO bookkeeping (you already have geomancy/handbell skill keys)
    geomancy             = "Geomancy", -- generic potency bucket (optional, leave if unused)

    -- White/Blue utility bumps (+X)
    phalanx              = "Phalanx",
    stoneskin            = "Stoneskin",
    aquaveil             = "Aquaveil",
    cursna               = "Cursna",
    elemental_siphon     = "Elemental Siphon",

    -- Summoner / BP
    blood_pact_delay     = "Blood Pact delay",
    blood_pact_delay_ii  = "Blood Pact delay II",
    blood_pact_damage    = "Blood Pact damage",

    -- Beastmaster
    reward               = "Reward",

    -- Weapon sheet stats
    dmg                  = "DMG:",
    delay                = "Delay:",
}

codex.STAT_ALIASES = {
    -- Core attributes / resources
    [codex.STAT.hp]                     = { "HP" },
    [codex.STAT.mp]                     = { "MP" },
    [codex.STAT.str]                    = { "STR" },
    [codex.STAT.dex]                    = { "DEX" },
    [codex.STAT.vit]                    = { "VIT" },
    [codex.STAT.agi]                    = { "AGI" },
    [codex.STAT.int]                    = { "INT" },
    [codex.STAT.mnd]                    = { "MND" },
    [codex.STAT.chr]                    = { "CHR" },

    -- Offense / accuracy
    [codex.STAT.accuracy]               = { "Accuracy", "Acc." },
    [codex.STAT.ranged_accuracy]        = { "Ranged Accuracy", "Rng. Acc.", "R.Acc.", "R acc" },
    [codex.STAT.attack]                 = { "Attack", "Atk." },
    [codex.STAT.ranged_attack]          = { "Ranged Attack", "Rng. Atk.", "R.Att." },
    [codex.STAT.magic_accuracy]         = { "Magic Accuracy", "Mag. Acc.", "Magic Acc.", "Mag acc", "M acc" },
    [codex.STAT.magic_atk_bonus]        = { "Magic Atk. Bonus", "MAB", "Mag. Atk. Bns." },
    [codex.STAT.magic_damage]           = { "Magic Damage", "Mag. dmg" },

    -- Tempo / TP engine
    [codex.STAT.haste]                  = { "Haste" },
    [codex.STAT.dual_wield]             = { "Dual Wield" },
    [codex.STAT.store_tp]               = { "Store TP" },
    [codex.STAT.save_tp]                = { "Save TP" },
    [codex.STAT.tp_bonus]               = { "TP Bonus" },
    [codex.STAT.snapshot]               = { "Snapshot" },
    [codex.STAT.rapid_shot]             = { "Rapid Shot" },
    [codex.STAT.fast_cast]              = { "Fast Cast", "Spellcasting time", "Cast time" },
    [codex.STAT.sird]                   = {
        "Spell interruption rate down",
        "Spell interrupt. rate down",
        "Interrupt. rate down",
        "Interrupt rate down",
        "SIRD",
    },

    -- Multi / crit / WS / MB
    [codex.STAT.da]                     = { "Double Attack", "Double Atk.", "Dbl.Atk." },
    [codex.STAT.ta]                     = { "Triple Attack", "Triple Atk." },
    [codex.STAT.qa]                     = { "Quadruple Attack", "Quad. Atk." },
    [codex.STAT.crit_rate]              = { "Critical hit rate", "Crit. hit rate", "Crithit rate" },
    [codex.STAT.crit_dmg]               = { "Critical hit damage" },
    [codex.STAT.ws_dmg]                 = { "Weapon skill damage", "WSD" },
    [codex.STAT.sc_dmg]                 = { "Skillchain Bonus", "Skillchain dmg" },
    [codex.STAT.mb_dmg]                 = { "Magic burst damage", "Magic Burst damage", "Magic burst dmg" },
    [codex.STAT.mb_dmg_ii]              = { "Magic burst damage II", "Magic Burst damage II" },

    -- Defensive / evasion
    [codex.STAT.defense]                = { "Defense", "DEF" },
    [codex.STAT.evasion]                = { "Evasion" },
    [codex.STAT.magic_evasion]          = { "Magic Evasion", "Mag. Eva.", "M.Eva", "Magic eva" },
    [codex.STAT.pdt]                    = { "PDT", "Physical damage taken", "Phys. dmg taken" },
    [codex.STAT.mdt]                    = { "MDT", "Magic damage taken" },
    [codex.STAT.dt]                     = { "Damage taken" },
    [codex.STAT.breath_dt]              = { "Breath damage taken" },
    [codex.STAT.pdl]                    = { "Physical damage limit" },

    [codex.STAT.subtle_blow]            = { "Subtle Blow" },
    [codex.STAT.subtle_blow_ii]         = { "Subtle Blow II" },

    -- Enmity / recovery
    [codex.STAT.enmity]                 = { "Enmity" },
    [codex.STAT.refresh]                = { "Refresh" },
    [codex.STAT.regen]                  = { "Regen" },
    [codex.STAT.regain]                 = { "Regain" },

    -- Resting recovery substats
    [codex.STAT.hp_while_healing]       = { "HP recovered while healing", "Healing HP" },
    [codex.STAT.mp_while_healing]       = { "MP recovered while healing", "Healing MP" },

    -- Skills (combat)
    [codex.STAT.h2h_skill]              = { "Hand-to-Hand skill", "Hand-to-hand skill" },
    [codex.STAT.dagger_skill]           = { "Dagger skill" },
    [codex.STAT.sword_skill]            = { "Sword skill" },
    [codex.STAT.great_sword_skill]      = { "Great Sword skill" },
    [codex.STAT.axe_skill]              = { "Axe skill" },
    [codex.STAT.great_axe_skill]        = { "Great Axe skill" },
    [codex.STAT.scythe_skill]           = { "Scythe skill" },
    [codex.STAT.polearm_skill]          = { "Polearm skill" },
    [codex.STAT.katana_skill]           = { "Katana skill" },
    [codex.STAT.gkt_skill]              = { "Great Katana skill" },
    [codex.STAT.club_skill]             = { "Club skill" },
    [codex.STAT.staff_skill]            = { "Staff skill" },
    [codex.STAT.archery_skill]          = { "Archery skill" },
    [codex.STAT.marksmanship_skill]     = { "Marksmanship skill" },
    [codex.STAT.throwing_skill]         = { "Throwing skill" },
    [codex.STAT.shield_skill]           = { "Shield skill" },
    [codex.STAT.parrying_skill]         = { "Parrying skill" },
    [codex.STAT.guarding_skill]         = { "Guarding skill" },
    [codex.STAT.evasion]                = { "Evasion Skill" },

    -- Skills (magic/perform)
    [codex.STAT.enhancing_skill]        = { "Enhancing magic skill" },
    [codex.STAT.enfeebling_skill]       = { "Enfeebling magic skill" },
    [codex.STAT.elemental_skill]        = { "Elemental magic skill" },
    [codex.STAT.divine_skill]           = { "Divine magic skill" },
    [codex.STAT.dark_skill]             = { "Dark magic skill" },
    [codex.STAT.healing_skill]          = { "Healing magic skill" },
    [codex.STAT.summoning_skill]        = { "Summoning magic skill" },
    [codex.STAT.singing_skill]          = { "Singing skill" },
    [codex.STAT.string_skill]           = { "String instrument skill", "String instruments skill" },
    [codex.STAT.wind_skill]             = { "Wind instrument skill", "Wind instruments skill" },
    [codex.STAT.ninjutsu_skill]         = { "Ninjutsu skill" },
    [codex.STAT.geomancy_skill]         = { "Geomancy skill" },
    [codex.STAT.handbell_skill]         = { "Handbell skill" },

    -- Cure / Waltz potency and received
    [codex.STAT.cure_potency]           = { "\"Cure\" potency", "Cure potency" },
    [codex.STAT.waltz_potency]          = { "\"Waltz\" potency", "Waltz potency" },
    [codex.STAT.cure_potency_received]  = { "Potency of \"Cure\" effects received", "Potency of \"Cure\" and \"Waltz\" effects received" },
    [codex.STAT.waltz_potency_received] = { "Potency of \"Waltz\" effects received", "Potency of \"Cure\" and \"Waltz\" effects received" },
    [codex.STAT.cure_potency_ii]        = { "\"Cure\" potency II" },

    -- Pet stats
    [codex.STAT.pet_accuracy]           = { "Pet: Accuracy" },
    [codex.STAT.pet_attack]             = { "Pet: Attack" },
    [codex.STAT.pet_ranged_accuracy]    = { "Pet: Ranged Accuracy" },
    [codex.STAT.pet_ranged_attack]      = { "Pet: Ranged Attack" },
    [codex.STAT.pet_magic_accuracy]     = { "Pet: Magic Accuracy" },
    [codex.STAT.pet_magic_atk_bonus]    = { "Pet: Magic Atk. Bonus" },
    [codex.STAT.pet_haste]              = { "Pet: Haste" },
    [codex.STAT.pet_dt]                 = { "Pet: Damage taken" },
    [codex.STAT.pet_pdt]                = { "Pet: PDT" },
    [codex.STAT.pet_mdt]                = { "Pet: MDT" },
    [codex.STAT.pet_evasion]            = { "Pet: Evasion" },
    [codex.STAT.pet_magic_evasion]      = { "Pet: Magic Evasion" },
    [codex.STAT.pet_store_tp]           = { "Pet: Store TP" },
    [codex.STAT.pet_regen]              = { "Pet: Regen" },
    [codex.STAT.pet_regain]             = { "Pet: Regain" },

    -- Trait / utility
    [codex.STAT.quick_cast]             = { "Quick cast", "Occ. quickens spellcasting", "Occasionally quickens spellcasting" },
    [codex.STAT.divine_benison]         = { "Divine Benison" },
    [codex.STAT.inquartata]             = { "Inquartata" },
    [codex.STAT.occult_acumen]          = { "Occult Acumen" },
    [codex.STAT.sublimation]            = { "Sublimation" },

    -- Durations / potency buckets
    [codex.STAT.song_effect_duration]   = { "Song effect duration", "Song duration" },
    [codex.STAT.indicolure_duration]    = { "Indicolure effect duration" },
    [codex.STAT.enhancing_duration]     = {
        "Enhancing magic effect duration",
        "Enhancing magic duration",
        "Enhancing duration",
    },
    [codex.STAT.enfeebling_duration]    = {
        "Enfeebling magic effect duration",
        "Enfeebling magic duration",
        "Enfeebling duration",
    },
    -- GEO generic (optional)
    [codex.STAT.geomancy]               = { "Geomancy" },

    -- Utility bumps
    [codex.STAT.phalanx]                = { "Phalanx" },
    [codex.STAT.stoneskin]              = { "Stoneskin" },
    [codex.STAT.aquaveil]               = { "Aquaveil" },
    [codex.STAT.cursna]                 = { "Cursna" },
    [codex.STAT.elemental_siphon]       = { "Elemental Siphon" },

    -- Summoner / Blood Pact (no grouping)
    [codex.STAT.blood_pact_delay]       = { "Blood Pact delay", "Blood Pact ability delay" },
    [codex.STAT.blood_pact_delay_ii]    = { "Blood Pact delay II", "Blood Pact recast time II", "Blood Pact ability delay II", "Blood Pact ab. del. II" },
    [codex.STAT.blood_pact_damage]      = { "Blood Pact damage", "Pet: Blood Pact damage", "PetL Blood Pact dmg", "Blood Pact dmg" },


    [codex.STAT.ws_accuracy] = {
        "Weapon skill accuracy",
        "WS accuracy",
        "WS acc.",
        "Weapon-skill accuracy",
        "W.S. accuracy",
    },

    -- Weapon sheet (shown on weapons)
    [codex.STAT.dmg]         = { "DMG:" },
    [codex.STAT.delay]       = { "Delay:" },
}

codex.ALIAS_STAT = {}
do
    local alias_table         = codex.ALIAS or {}
    local stat_aliases        = codex.STAT_ALIASES or {}

    -- Reverse: alias VALUE -> alias KEY (e.g., "Rng. Atk." -> "rng_atk")
    local alias_name_by_value = {}
    for alias_key, alias_val in pairs(alias_table) do
        if type(alias_val) == "string" and alias_val ~= "" then
            alias_name_by_value[alias_val] = alias_key
        end
    end

    -- For each stat, wire all alias KEYS -> that stat_key
    for stat_key, canonical_label in pairs(codex.STAT or {}) do
        local list = stat_aliases[canonical_label]
        if type(list) == "table" then
            for i = 1, #list do
                local alias_val  = list[i]
                local alias_name = alias_name_by_value[alias_val]
                if alias_name then
                    codex.ALIAS_STAT[alias_name] = stat_key
                end
            end
        end
    end
end

codex.PERCENT_LIKE = codex.PERCENT_LIKE or {
    haste = true,
    fast_cast = true,
    sird = true,
    pdt = true,
    mdt = true,
    dt = true,
    breath_dt = true,
    pdl = true,
    crit_rate = true,
    crit_dmg = true,
    ws_dmg = true,
    snapshot = true,
    rapid_shot = true,
    mb_dmg = true,
    mb_dmg_ii = true,
    pet_haste = true,
    pet_dt = true,
    pet_pdt = true,
    pet_mdt = true,
}

codex.PET_PREFIXES = { "Pet:", "Pet", "Avatar", "Wyvern", "Automaton", "Luopan" }

-- Credit checkparam
-- https://github.com/Icydeath/ffxi-addons/blob/master/checkparam
codex.KNOWN_ENHANCED_BY_ID = {
    [10392] = { [codex.STAT.cursna] = 10 },        -- Malison Medallion
    [10393] = { [codex.STAT.cursna]  = 15 },        -- Debilis Medallion
    [10394] = { [codex.STAT.fast_cast] = 5 },      -- Orunmila's Torque
    [10752] = { [codex.STAT.fast_cast] = 2 },      -- Prolix Ring
    [11037] = { [codex.STAT.stoneskin] = 10 },     -- Earthcry Earring
    [11602] = { [codex.STAT.martial_arts] = 10 },  -- Cirque Necklace
    [11603] = { [codex.STAT.dual_wield] = 3 },     -- Charis Necklace
    [11732] = { [codex.STAT.dual_wield] = 5 },     -- Nusku's Sash
    [14739] = { [codex.STAT.dual_wield] = 5 },     -- Suppanomimi
    [14813] = { [codex.STAT.da] = 5 },             -- Brutal Earring
    [15962] = { [codex.STAT.mb_dmg] = 5 },         -- Static Earring
    [16209] = { [codex.STAT.snapshot] = 5 },       -- Navarch's Mantle
    [19062] = { [codex.STAT.divine_benison] = 1 }, -- Yagrush80
    [19082] = { [codex.STAT.divine_benison] = 2 }, -- Yagrush85
    [19614] = { [codex.STAT.divine_benison] = 3 }, -- Yagrush90
    [19821] = { [codex.STAT.divine_benison] = 3 }, -- Yagrush99
    [21062] = { [codex.STAT.divine_benison] = 3 }, -- Yagrush119
    [21063] = { [codex.STAT.divine_benison] = 3 }, -- Yagrush119+
    [21078] = { [codex.STAT.divine_benison] = 3 }, -- Yagrush119AG
    [27279] = { [codex.STAT.pdt] = 6 },           -- Eri. Leg Guards
    [27280] = { [codex.STAT.pdt] = 7 },           -- Eri. Leg Guards +1
    [28197] = { [codex.STAT.snapshot] = 9 },       -- Nahtirah Trousers
    [28637] = { [codex.STAT.fast_cast] = 7 },      -- Lifestream Cape
    -- ...add the rest of your list here as you encounter them.
}

codex.BAG_KEYS = {
    'inventory', 'wardrobe', 'wardrobe2', 'wardrobe3', 'wardrobe4',
    'wardrobe5', 'wardrobe6', 'wardrobe7', 'wardrobe8',
}

codex.SLOT_NAMES = {
    [0] = 'Main',
    [1] = 'Sub',
    [2] = 'Range',
    [3] = 'Ammo',
    [4] = 'Head',
    [5] = 'Body',
    [6] = 'Hands',
    [7] = 'Legs',
    [8] = 'Feet',
    [9] = 'Neck',
    [10] = 'Waist',
    [11] = 'Left Ear',
    [12] = 'Right Ear',
    [13] = 'Left Ring',
    [14] = 'Right Ring',
    [15] = 'Back'
}

codex.SPELL_CASTING_SETS = {
    ["Sleep"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Sleepga"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Silence"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Bind"]         = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Break"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Breakga"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Dispel"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Inundation"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Gravity"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Frazzle"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },

    -- Remember, you can always create an explicit set for a spell or its base. They will be applied last.
    -- //gs c save distract
    -- //gs c save frazzle_iii
    ["Distract"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.skill, codex.CASTING_SETS.enfeebling.mnd },
    ["Frazzle III"]  = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.skill, codex.CASTING_SETS.enfeebling.mnd },

    -- Potency: stat driven
    ["Paralyze"]     = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.mnd },
    ["Slow"]         = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.mnd },
    ["Addle"]        = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.mnd },

    ["Blind"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.skill, codex.CASTING_SETS.enfeebling.int },

    -- Potency: skill-based ticks
    ["Poison"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.skill },
    ["Poisonga"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.skill },

    ["Dia"]          = { codex.CASTING_SETS.enfeebling.duration },

    ["Temper"]       = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill },
    ["Haste"]        = { codex.CASTING_SETS.enhancing.duration },
    ["Auspice"]      = { codex.CASTING_SETS.enhancing.duration },

    ["Protect"]      = { codex.CASTING_SETS.enhancing.duration },
    ["Protectra"]    = { codex.CASTING_SETS.enhancing.duration },
    ["Shell"]        = { codex.CASTING_SETS.enhancing.duration },
    ["Shellra"]      = { codex.CASTING_SETS.enhancing.duration },

    ["Enfire"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.macc, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.enspell },
    ["Enblizzard"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.macc, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.enspell },
    ["Enaero"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.macc, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.enspell },
    ["Enstone"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.macc, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.enspell },
    ["Enthunder"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.macc, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.enspell },
    ["Enwater"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.macc, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.enspell },

    ["Barfire"]      = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barblizzard"]  = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Baraero"]      = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barstone"]     = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barthunder"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barwater"]     = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },

    ["Barfira"]      = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barblizzara"]  = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Baraera"]      = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barstonra"]    = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barthundra"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },
    ["Barwatera"]    = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_element },

    ["Baramnesia"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barvirus"]     = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barparalyze"]  = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barsilence"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barpetrify"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barpoison"]    = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barblind"]     = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },
    ["Barsleep"]     = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.bar_status },

    ["Baramnesra"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barvira"]      = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barparalyzra"] = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barsilencera"] = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barpetra"]     = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barpoisonra"]  = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barblindra"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },
    ["Barsleepra"]   = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill, codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.bar_status },

    -- You'll probably want to create sets for these
    -- //gs c save stoneskin
    -- //gs c save phalanx
    ["Stoneskin"]    = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.default, codex.CASTING_SETS.enhancing.skill },
    ["Phalanx"]      = { codex.CASTING_SETS.enhancing.duration, codex.CASTING_SETS.enhancing.skill },

    ["Blaze Spikes"] = { codex.CASTING_SETS.mab, codex.CASTING_SETS.enhancing.spikes },
    ["Ice Spikes"]   = { codex.CASTING_SETS.mab, codex.CASTING_SETS.enhancing.spikes },
    ["Shock Spikes"] = { codex.CASTING_SETS.mab, codex.CASTING_SETS.enhancing.spikes },

    ["Refresh"]      = { codex.CASTING_SETS.enhancing.duration },
    ["Regen"]        = { codex.CASTING_SETS.enhancing.duration },

    ["Burn"]         = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Frost"]        = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Choke"]        = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Rasp"]         = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Shock"]        = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Drown"]        = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },

    ["Pyrohelix"]    = { codex.CASTING_SETS.elemental.helix },
    ["Cryohelix"]    = { codex.CASTING_SETS.elemental.helix },
    ["Anemohelix"]   = { codex.CASTING_SETS.elemental.helix },
    ["Geohelix"]     = { codex.CASTING_SETS.elemental.helix },
    ["Ionohelix"]    = { codex.CASTING_SETS.elemental.helix },
    ["Hydrohelix"]   = { codex.CASTING_SETS.elemental.helix },
    ["Luminohelix"]  = { codex.CASTING_SETS.elemental.helix },
    ["Noctohelix"]   = { codex.CASTING_SETS.elemental.helix_dark },

    ["Fire"]         = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Blizzard"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Aero"]         = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Stone"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Thunder"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Water"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },

    ["Firaga"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Blizzaga"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Aeroga"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Stonega"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Thunderga"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Waterga"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },

    ["Fira"]         = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Blizzara"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Stonera"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Aera"]         = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Thundara"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    -- Just in case
    ["Watera"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },


    ["Flare"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Freeze"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Tornado"]  = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Quake"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Burst"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Flood"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },

    ["Meteor"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },

    ["Comet"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },
    ["Firaja"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },
    ["Blizzaja"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },
    ["Aeroja"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },
    ["Stoneja"]  = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },
    ["Thundaja"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },
    ["Waterja"]  = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.cumulative },


    --TBH, you should just create Drain + Absorb sets, which will overwrite all of this.
    -- "drain" + "dark.absorb"
    ["Bio"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.enfeeble },
    ["Drain"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb, "Aspir", codex.CASTING_SETS.dark.drain_aspir },
    ["Aspir"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb, "Drain", codex.CASTING_SETS.dark.drain_aspir },
    ["Absorb-STR"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-DEX"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-VIT"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-INT"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-MND"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-CHR"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-AGI"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-ACC"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },
    ["Absorb-TP"]  = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.dark.default, codex.CASTING_SETS.dark.skill, codex.CASTING_SETS.dark.absorb },

    ["Banish"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.divine.default, codex.CASTING_SETS.divine.skill, codex.CASTING_SETS.divine.nuke },
    ["Holy"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.divine.default, codex.CASTING_SETS.divine.skill, codex.CASTING_SETS.divine.nuke },

    -- You should definitely just make a specific "cure" set.
    -- //gs c save cure
    ["Cure"]       = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.healing.default }
}

codex.STAT_CAP = {
    haste = 25, -- gear haste cap (percent)
    pdt   = 50, -- reduction caps (percent)
    mdt   = 50,
    dt    = 50,
}

codex.INVERTED_STATS = {
    [codex.STAT.dt]                = true,
    [codex.STAT.pdt]               = true,
    [codex.STAT.mdt]               = true,
    [codex.STAT.breath_dt]         = true,

    [codex.STAT.pet_dt]            = true,
    [codex.STAT.pet_pdt]           = true,
    [codex.STAT.pet_mdt]           = true,

    [codex.STAT.delay]             = true,
    [codex.STAT.fast_cast]         = true, -- For cast time reductions
}

codex.ENHANCEMENT_VERBS = {
    "enhances", "improves", "augments",
    "increases", "reduces", "adds",
    "occasionally", "extends", "shortens", "set:"
}

codex.LATENTS = {
    "reive", "lair reive", "colonization reive",
    "unity", "unity ranking",
    "campaign", "ballista", "besieged",
    "assault", "einherjar", "salvage", "nyzul",
    "skirmish", "delve", "fracture",
    "ambuscade", "omen", "odyssey", "sortie",
    "in dynamis:",                     -- e.g. Dynamis weapon conditional stats
    "daytime:",                        -- e.g. daytime/nighttime toggles
    "nighttime:",                      -- idem
    "same elemental magic as weather", -- weather/day synergy text
    "campaign:", "besieged:", "ballista:", "reive:",
    "odin:", "sortie:", "odyssey:",    -- event/zone buffs

}

-- =========================
-- DARK MAGIC
-- =========================
local function calc_dark_absorb(s)
    -- Drain/Aspir/Absorb: landing & potency scale with Dark skill and M.Acc; INT contributes
    return
        (s[codex.STAT.dark_skill] or 0) * 3.0 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.5
end

local function calc_dark_default(s)
    -- Mixed dark (nuke/enfeeble bias)
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 1.0 +
        (s[codex.STAT.int] or 0) * 1.0 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.5 +
        (s[codex.STAT.dark_skill] or 0) * 0.5
end

local function calc_dark_drain_aspir(s)
    -- Drain/Aspir: Dark skill and accuracy dominate; INT helps
    return
        (s[codex.STAT.dark_skill] or 0) * 3.0 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.5
end

local function calc_dark_enfeeble(s)
    -- Bio/other dark enfeebles: emphasize landing
    return
        (s[codex.STAT.magic_accuracy] or 0) * 1.0 +
        (s[codex.STAT.dark_skill] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.4
end

local function calc_dark_skill(s)
    -- Landing/tiers driven by Dark skill; then M.Acc; then INT
    return
        (s[codex.STAT.dark_skill] or 0) * 100 +
        (s[codex.STAT.magic_accuracy] or 0) * 10 +
        (s[codex.STAT.int] or 0)
end

-- =========================
-- DIVINE MAGIC
-- =========================
local function calc_divine_default(s)
    -- Divine mixed (Banish/Holy side): MND + MAB; M.Acc & skill matter
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 1.0 +
        (s[codex.STAT.mnd] or 0) * 1.0 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.5 +
        (s[codex.STAT.divine_skill] or 0) * 0.5
end

local function calc_divine_nuke(s)
    -- Holy/Banish nuke focus: MAB + Magic Damage + MND
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 2.0 +
        (s[codex.STAT.magic_damage] or 0) * 1.0 +
        (s[codex.STAT.mnd] or 0) * 1.0 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.3
end

local function calc_divine_skill(s)
    -- Divine skill → resist tiers; then M.Acc; then MND
    return
        (s[codex.STAT.divine_skill] or 0) * 100 +
        (s[codex.STAT.magic_accuracy] or 0) * 10 +
        (s[codex.STAT.mnd] or 0)
end

-- =========================
-- ELEMENTAL MAGIC
-- =========================
local function calc_elemental_cumulative(s)
    -- Longer fights: blend damage and accuracy
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 2.0 +
        (s[codex.STAT.magic_damage] or 0) * 0.8 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.8 +
        (s[codex.STAT.int] or 0) * 0.5
end

local function calc_elemental_default(s)
    -- General nuking baseline
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 2.0 +
        (s[codex.STAT.magic_damage] or 0) * 0.8 +
        (s[codex.STAT.int] or 0) * 0.5 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.4
end

local function calc_elemental_enfeeble(s)
    -- Elemental enfeebles (Burn/Frost/etc.): land rate priority
    return
        (s[codex.STAT.magic_accuracy] or 0) * 1.0 +
        (s[codex.STAT.elemental_skill] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.6
end

local function calc_elemental_geo(s)
    -- Geomancy focus: potency/duration/landing
    return
        (s[codex.STAT.geomancy_skill] or 0) * 1.0 +
        (s[codex.STAT.handbell_skill] or 0) * 0.8 +
        (s[codex.STAT.indicolure_duration] or 0) * 10 +
        (s[codex.STAT.geomancy] or 0) * 20 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.5
end

local function calc_elemental_helix(s)
    -- Helix: INT + MAB; skill/acc for tiers/landing
    return
        (s[codex.STAT.int] or 0) * 2.0 +
        (s[codex.STAT.magic_atk_bonus] or 0) * 1.5 +
        (s[codex.STAT.elemental_skill] or 0) * 0.5 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.3
end

local function calc_elemental_helix_dark(s)
    -- Dark‐element helix (still Elemental school) → same priorities as helix
    return
        (s[codex.STAT.int] or 0) * 2.0 +
        (s[codex.STAT.magic_atk_bonus] or 0) * 1.5 +
        (s[codex.STAT.elemental_skill] or 0) * 0.5 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.3
end

local function calc_elemental_macc(s)
    -- Elemental accuracy: hit rate
    return
        (s[codex.STAT.magic_accuracy] or 0) * 1.0 +
        (s[codex.STAT.elemental_skill] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.5
end

local function calc_elemental_nuke(s)
    -- Heavy damage: MAB > M.Dmg > INT; small M.Acc
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 2.5 +
        (s[codex.STAT.magic_damage] or 0) * 1.2 +
        (s[codex.STAT.int] or 0) * 0.8 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.2
end

local function calc_elemental_skill(s)
    -- Elemental skill priority (tiers/resist), then M.Acc, then INT
    return
        (s[codex.STAT.elemental_skill] or 0) * 100 +
        (s[codex.STAT.magic_accuracy] or 0) * 10 +
        (s[codex.STAT.int] or 0)
end

-- =========================
-- ENFEEBLING MAGIC
-- =========================
-- Enfeebling (default): rank for reliable landing across mixed enfeebles.
-- Mechanics: Magic Accuracy drives hit rate; dSTAT contributes depending on spell
-- (MND for white enfeebles like Slow/Paralyze; INT for black enfeebles like Blind).
-- Without per-spell context, weight both MND and INT symmetrically so sets that
-- help either family are preferred. Uses only codex.STAT keys.
local function calc_enfeebling_default(s)
    local macc = s[codex.STAT.macc] or 0
    local mnd  = s[codex.STAT.mnd] or 0
    local int  = s[codex.STAT.int] or 0

    -- Strong emphasis on landing rate (M.Acc), with moderate value from both dSTATs.
    return (macc * 1.0) + (mnd * 0.6) + (int * 0.6)
end

local function calc_enfeebling_duration(s)
    -- Duration correlates with skill + dSTAT; M.Acc supports landing
    return
        (s[codex.STAT.enfeebling_skill] or 0) * 1.0 +
        (s[codex.STAT.mnd] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.6 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.3
end

local function calc_enfeebling_int(s)
    -- INT‐based enfeebles: Blind/Poison/etc.
    return
        (s[codex.STAT.magic_accuracy] or 0) * 0.9 +
        (s[codex.STAT.enfeebling_skill] or 0) * 0.7 +
        (s[codex.STAT.int] or 0) * 0.8 +
        (s[codex.STAT.mnd] or 0) * 0.2
end

local function calc_enfeebling_macc(s)
    -- Pure landing priority
    return
        (s[codex.STAT.magic_accuracy] or 0) * 1.0 +
        (s[codex.STAT.enfeebling_skill] or 0) * 0.7 +
        (s[codex.STAT.int] or 0) * 0.4 +
        (s[codex.STAT.mnd] or 0) * 0.4
end

local function calc_enfeebling_mnd(s)
    -- MND‐based enfeebles: Slow/Paralyze/etc.
    return
        (s[codex.STAT.magic_accuracy] or 0) * 0.9 +
        (s[codex.STAT.enfeebling_skill] or 0) * 0.7 +
        (s[codex.STAT.mnd] or 0) * 0.8 +
        (s[codex.STAT.int] or 0) * 0.2
end

local function calc_enfeebling_skill(s)
    -- Skill → tiers/resists
    return
        (s[codex.STAT.enfeebling_skill] or 0) * 100 +
        (s[codex.STAT.magic_accuracy] or 0) * 10 +
        (s[codex.STAT.mnd] or 0)
end

-- =========================
-- ENHANCING MAGIC
-- =========================
local function calc_enhancing_bar_element(s)
    -- Bar‐element: Enhancing skill + MND
    return
        (s[codex.STAT.enhancing_skill] or 0) * 1.0 +
        (s[codex.STAT.mnd] or 0) * 1.0
end

local function calc_enhancing_bar_status(s)
    -- Bar‐status: similar emphasis
    return
        (s[codex.STAT.enhancing_skill] or 0) * 1.0 +
        (s[codex.STAT.mnd] or 0) * 1.2
end

local function calc_enhancing_default(s)
    -- Generic Enhancing (no duration tag)
    return
        (s[codex.STAT.enhancing_skill] or 0) * 3.0 +
        (s[codex.STAT.mnd] or 0) * 0.5
end

local function calc_enhancing_duration(s)
    -- Duration gear dominates; skill adds baseline potency
    return
        (s[codex.STAT.enhancing_duration] or 0) * 100 +
        (s[codex.STAT.enhancing_skill] or 0) * 1.0 +
        (s[codex.STAT.mnd] or 0) * 0.3
end

local function calc_enhancing_enspell(s)
    -- Enspell add‐hit: Enhancing skill; MND modest; tiny MAB relevance
    return
        (s[codex.STAT.enhancing_skill] or 0) * 1.5 +
        (s[codex.STAT.mnd] or 0) * 0.8 +
        (s[codex.STAT.magic_atk_bonus] or 0) * 0.4
end

local function calc_enhancing_mnd(s)
    -- MND‐leaning enhancing
    return
        (s[codex.STAT.mnd] or 0) * 1.0 +
        (s[codex.STAT.enhancing_skill] or 0) * 0.8
end

local function calc_enhancing_potency(s)
    -- Potency helpers: skill + specific enhancing tags when present
    return
        (s[codex.STAT.enhancing_skill] or 0) * 2.0 +
        (s[codex.STAT.mnd] or 0) * 0.6 +
        (s[codex.STAT.phalanx] or 0) * 50 +
        (s[codex.STAT.stoneskin] or 0) * 50 +
        (s[codex.STAT.aquaveil] or 0) * 20
end

local function calc_enhancing_skill(s)
    -- Pure skill emphasis
    return
        (s[codex.STAT.enhancing_skill] or 0) * 100 +
        (s[codex.STAT.mnd] or 0) * 0.5
end

-- =========================
-- FAST CAST / PRECAST
-- =========================
local function calc_precast_fastcast(s)
    -- Fast Cast (spells): cast time reduction (cap ~80%)
    local cap = codex.STAT_CAP or {}
    local fc_cap = cap.fast_cast or 80
    local fc = math.min(s[codex.STAT.fast_cast] or 0, fc_cap)
    return fc * 100
end

-- =========================
-- HEALING MAGIC
-- =========================
local function calc_healing_default(s)
    -- Healing: Cure Potency/II > Healing Skill > MND
    return
        (s[codex.STAT.cure_potency] or 0) * 200 +
        (s[codex.STAT.cure_potency_ii] or 0) * 300 +
        (s[codex.STAT.healing_skill] or 0) * 2.0 +
        (s[codex.STAT.mnd] or 0) * 0.5
end

local function calc_healing_weather(s)
    -- No tracked weather/day stat here; fall back to healing weights
    return
        (s[codex.STAT.cure_potency] or 0) * 200 +
        (s[codex.STAT.healing_skill] or 0) * 2.0 +
        (s[codex.STAT.mnd] or 0) * 0.5
end

local function calc_idle_default(s)
    -- Idle: Refresh >> Regen > Regain
    return
        (s[codex.STAT.refresh] or 0) * 1000 +
        (s[codex.STAT.regen] or 0) * 200 +
        (s[codex.STAT.regain] or 0) * 150
end

local function calc_idle_dt(s)
    -- Idle DT: assume 70% physical / 30% magical; multiplicative stacking; cap at 50%
    local cap      = codex.STAT_CAP or {}
    local dt       = math.min(s[codex.STAT.dt] or 0, cap.dt or 50)
    local pdt      = math.min(s[codex.STAT.pdt] or 0, cap.pdt or 50)
    local mdt      = math.min(s[codex.STAT.mdt] or 0, cap.mdt or 50)
    local phys     = 1 - (1 - dt / 100) * (1 - pdt / 100)
    local mag      = 1 - (1 - dt / 100) * (1 - mdt / 100)
    local expected = 0.70 * phys + 0.30 * mag
    return expected * 10000
        + (s[codex.STAT.defense] or 0) * 0.4
        + (s[codex.STAT.evasion] or 0) * 0.8
        + (s[codex.STAT.vit] or 0) * 0.6
        + (s[codex.STAT.agi] or 0) * 0.2
end

local function calc_idle_mdt(s)
    -- Idle MDT: assume 20% physical / 80% magical
    local cap      = codex.STAT_CAP or {}
    local dt       = math.min(s[codex.STAT.dt] or 0, cap.dt or 50)
    local pdt      = math.min(s[codex.STAT.pdt] or 0, cap.pdt or 50)
    local mdt      = math.min(s[codex.STAT.mdt] or 0, cap.mdt or 50)
    local phys     = 1 - (1 - dt / 100) * (1 - pdt / 100)
    local mag      = 1 - (1 - dt / 100) * (1 - mdt / 100)
    local expected = 0.20 * phys + 0.80 * mag
    return expected * 10000
        + (s[codex.STAT.magic_evasion] or 0) * 1.2
        + (s[codex.STAT.mnd] or 0) * 0.4
        + (s[codex.STAT.evasion] or 0) * 0.3
        + (s[codex.STAT.defense] or 0) * 0.3
end

local function calc_idle_refresh(s)
    -- Pure refresh idle
    return (s[codex.STAT.refresh] or 0) * 1000
end

local function calc_magic_default(s)
    -- Nuking baseline
    return
        (s[codex.STAT.magic_atk_bonus] or 0) * 2.0 +
        (s[codex.STAT.magic_damage] or 0) * 0.8 +
        (s[codex.STAT.int] or 0) * 0.5 +
        (s[codex.STAT.magic_accuracy] or 0) * 0.4
end

local function calc_magic_macc(s)
    -- Landing rate
    return
        (s[codex.STAT.magic_accuracy] or 0) * 1.0 +
        (s[codex.STAT.elemental_skill] or 0) * 0.6 +
        (s[codex.STAT.int] or 0) * 0.5
end

local function calc_magic_mb(s)
    -- MB I (~40% cap) and MB II
    local mb1 = math.min(s[codex.STAT.mb_dmg] or 0, 40)
    local mb2 = (s[codex.STAT.mb_dmg_ii] or 0)
    return (mb1 * 100) + (mb2 * 200)
end

local function calc_melee_acc(s)
    -- Accuracy leaning
    return
        (s[codex.STAT.accuracy] or 0) * 1.0 +
        (s[codex.STAT.dex] or 0) * 0.8
end

local function calc_melee_default(s)
    -- General TP: accuracy + multi‐attack + capped gear haste + attack
    local cap = codex.STAT_CAP or {}
    local h = math.min(s[codex.STAT.haste] or 0, cap.haste or 25)
    return
        (s[codex.STAT.attack] or 0) * 1.0 +
        (s[codex.STAT.accuracy] or 0) * 1.2 +
        h * 40 +
        (s[codex.STAT.da] or 0) * 100 +
        (s[codex.STAT.ta] or 0) * 150 +
        (s[codex.STAT.qa] or 0) * 200 +
        (s[codex.STAT.store_tp] or 0) * 5 +
        (s[codex.STAT.save_tp] or 0) * 3 +
        (s[codex.STAT.str] or 0) * 0.6 +
        (s[codex.STAT.dex] or 0) * 0.5
end

local function calc_melee_dt(s)
    -- Engaged DT: assume 80% physical / 20% magical
    local cap      = codex.STAT_CAP or {}
    local dt       = math.min(s[codex.STAT.dt] or 0, cap.dt or 50)
    local pdt      = math.min(s[codex.STAT.pdt] or 0, cap.pdt or 50)
    local mdt      = math.min(s[codex.STAT.mdt] or 0, cap.mdt or 50)
    local phys     = 1 - (1 - dt / 100) * (1 - pdt / 100)
    local mag      = 1 - (1 - dt / 100) * (1 - mdt / 100)
    local expected = 0.80 * phys + 0.20 * mag
    return expected * 10000
        + (s[codex.STAT.defense] or 0) * 0.4
        + (s[codex.STAT.evasion] or 0) * 0.8
        + (s[codex.STAT.vit] or 0) * 0.6
        + (s[codex.STAT.agi] or 0) * 0.2
end

local function calc_melee_dw(s)
    -- Dual Wield tuning: DW first, haste synergy, then accuracy
    local cap = codex.STAT_CAP or {}
    local h = math.min(s[codex.STAT.haste] or 0, cap.haste or 25)
    return
        (s[codex.STAT.dual_wield] or 0) * 100 +
        h * 20 +
        (s[codex.STAT.accuracy] or 0) * 0.5
end

local function calc_melee_mdt(s)
    -- Engaged MDT: assume 30% physical / 70% magical
    local cap      = codex.STAT_CAP or {}
    local dt       = math.min(s[codex.STAT.dt] or 0, cap.dt or 50)
    local pdt      = math.min(s[codex.STAT.pdt] or 0, cap.pdt or 50)
    local mdt      = math.min(s[codex.STAT.mdt] or 0, cap.mdt or 50)
    local phys     = 1 - (1 - dt / 100) * (1 - pdt / 100)
    local mag      = 1 - (1 - dt / 100) * (1 - mdt / 100)
    local expected = 0.30 * phys + 0.70 * mag
    return expected * 10000
        + (s[codex.STAT.magic_evasion] or 0) * 1.5
        + (s[codex.STAT.mnd] or 0) * 0.4
        + (s[codex.STAT.defense] or 0) * 0.3
end

local function calc_melee_sb(s)
    -- Subtle Blow (I & II)
    return
        (s[codex.STAT.subtle_blow] or 0) * 50 +
        (s[codex.STAT.subtle_blow_ii] or 0) * 100
end

local function calc_ranged_acc(s)
    -- Accuracy‐leaning ranged
    return
        (s[codex.STAT.ranged_accuracy] or 0) * 1.5 +
        (s[codex.STAT.agi] or 0) * 0.75 +
        (s[codex.STAT.ranged_attack] or 0) * 0.25
end

local function calc_ranged_default(s)
    -- General ranged set
    return
        (s[codex.STAT.ranged_attack] or 0) * 1.0 +
        (s[codex.STAT.ranged_accuracy] or 0) * 0.8 +
        (s[codex.STAT.agi] or 0) * 0.4
end

local function calc_resting_hp(s)
    -- HP recovered while healing
    return (s[codex.STAT.hp_while_healing] or 0)
end

local function calc_resting_mp(s)
    -- MP recovered while healing (small synergy from HP recovery)
    return
        (s[codex.STAT.mp_while_healing] or 0) +
        (s[codex.STAT.hp_while_healing] or 0) * 0.15
end

local function calc_weaponskill_default(s)
    -- Gear‐agnostic WS emphasis: WS Damage and Skillchain Bonus
    return
        (s[codex.STAT.ws_dmg] or 0) * 100 +
        (s[codex.STAT.sc_dmg] or 0) * 50
end

codex.SET_FUNCTIONS = {
    [codex.CORE_SETS.idle.default]             = calc_idle_default,
    [codex.CORE_SETS.idle.refresh]             = calc_idle_refresh,
    [codex.CORE_SETS.idle.dt]                  = calc_idle_dt,
    [codex.CORE_SETS.idle.mdt]                 = calc_idle_mdt,

    [codex.CORE_SETS.melee.default]            = calc_melee_default,
    [codex.CORE_SETS.melee.acc]                = calc_melee_acc,
    [codex.CORE_SETS.melee.dt]                 = calc_melee_dt,
    [codex.CORE_SETS.melee.mdt]                = calc_melee_mdt,
    [codex.CORE_SETS.melee.sb]                 = calc_melee_sb,
    [codex.CORE_SETS.melee.dw]                 = calc_melee_dw,

    [codex.CORE_SETS.magic.default]            = calc_magic_default,
    [codex.CORE_SETS.magic.macc]               = calc_magic_macc,
    [codex.CORE_SETS.magic.mb]                 = calc_magic_mb,

    [codex.CORE_SETS.ranged.default]           = calc_ranged_default,
    [codex.CORE_SETS.ranged.acc]               = calc_ranged_acc,

    [codex.CORE_SETS.resting.hp]               = calc_resting_hp,
    [codex.CORE_SETS.resting.mp]               = calc_resting_mp,

    [codex.CORE_SETS.precast.fastcast]         = calc_precast_fastcast,
    [codex.CORE_SETS.weaponskill.default]      = calc_weaponskill_default,

    [codex.CASTING_SETS.healing.default]       = calc_healing_default,
    [codex.CASTING_SETS.healing.weather]       = calc_healing_weather,

    [codex.CASTING_SETS.enfeebling.default]    = calc_enfeebling_default,
    [codex.CASTING_SETS.enfeebling.macc]       = calc_enfeebling_macc,
    [codex.CASTING_SETS.enfeebling.mnd]        = calc_enfeebling_mnd,
    [codex.CASTING_SETS.enfeebling.int]        = calc_enfeebling_int,
    [codex.CASTING_SETS.enfeebling.skill]      = calc_enfeebling_skill,
    [codex.CASTING_SETS.enfeebling.duration]   = calc_enfeebling_duration,

    [codex.CASTING_SETS.enhancing.default]     = calc_enhancing_default,
    [codex.CASTING_SETS.enhancing.duration]    = calc_enhancing_duration,
    [codex.CASTING_SETS.enhancing.potency]     = calc_enhancing_potency,
    [codex.CASTING_SETS.enhancing.mnd]         = calc_enhancing_mnd,
    [codex.CASTING_SETS.enhancing.skill]       = calc_enhancing_skill,
    [codex.CASTING_SETS.enhancing.enspell]     = calc_enhancing_enspell,
    [codex.CASTING_SETS.enhancing.bar_status]  = calc_enhancing_bar_status,
    [codex.CASTING_SETS.enhancing.bar_element] = calc_enhancing_bar_element,

    [codex.CASTING_SETS.elemental.default]     = calc_elemental_default,
    [codex.CASTING_SETS.elemental.macc]        = calc_elemental_macc,
    [codex.CASTING_SETS.elemental.nuke]        = calc_elemental_nuke,
    [codex.CASTING_SETS.elemental.enfeeble]    = calc_elemental_enfeeble,
    [codex.CASTING_SETS.elemental.helix]       = calc_elemental_helix,
    [codex.CASTING_SETS.elemental.helix_dark]  = calc_elemental_helix_dark,
    [codex.CASTING_SETS.elemental.cumulative]  = calc_elemental_cumulative,
    [codex.CASTING_SETS.elemental.geo]         = calc_elemental_geo,
    [codex.CASTING_SETS.elemental.skill]       = calc_elemental_skill,

    [codex.CASTING_SETS.dark.default]          = calc_dark_default,
    [codex.CASTING_SETS.dark.enfeeble]         = calc_dark_enfeeble,
    [codex.CASTING_SETS.dark.drain_aspir]      = calc_dark_drain_aspir,
    [codex.CASTING_SETS.dark.absorb]           = calc_dark_absorb,
    [codex.CASTING_SETS.dark.skill]            = calc_dark_skill,

    [codex.CASTING_SETS.divine.default]        = calc_divine_default,
    [codex.CASTING_SETS.divine.skill]          = calc_divine_skill,
    [codex.CASTING_SETS.divine.nuke]           = calc_divine_nuke,
}

codex.WEAPON_SKILLS = {

    sword = {
        ["Savage Blade"] = {
            hits = 2,
            class = "physical",
            ftp = { 4.00, 10.25, 13.75 },
            ftp_rep = false,
            wsc = { STR = 0.50, MND = 0.50 },
            sc = { "Fragmentation", "Scission" },
        },

        ["Chant du Cygne"] = {
            hits = 3,
            class = "physical",
            ftp = { 1.6328125, 1.6328125, 1.6328125 },
            ftp_rep = true,
            wsc = { DEX = 0.80 },
            crit_rate = { 0.15, 0.25, 0.40 },
            sc = { "Light", "Distortion" },
        },
    },

    great_sword = {
        ["Resolution"] = {
            hits = 5,
            class = "physical",
            ftp = { 0.71875, 1.50, 2.25 },
            ftp_rep = true,
            wsc = { STR = 0.80 }, -- BG lists 73~85% depending on merits/history; use 0.80 as current
            attack_mod = 0.85,
            sc = { "Light", "Fragmentation", "Scission" },
        },

        ["Torcleaver"] = {
            hits = 1,
            class = "physical",
            ftp = { 4.75, 7.50, 9.765625 },
            ftp_rep = false,
            wsc = { VIT = 0.80 },
            sc = { "Light", "Distortion" },
        },
    },

    dagger = {
        ["Rudra's Storm"] = {
            hits = 1,
            class = "physical",
            ftp = { 5.00, 10.19, 13.00 },
            ftp_rep = false,
            wsc = { DEX = 0.80 },
            sc = { "Darkness", "Distortion" },
        },

        ["Evisceration"] = {
            hits = 5,
            class = "physical",
            ftp = { 1.25, 1.25, 1.25 },
            ftp_rep = true,
            wsc = { DEX = 0.50 },
            crit_rate = { 0.10, 0.25, 0.50 },
            sc = { "Gravitation", "Transfixion" },
        },
    },

    katana = {
        ["Blade: Hi"] = {
            hits = 1,
            class = "physical",
            ftp = { 3.50, 3.50, 3.50 },
            ftp_rep = false,
            wsc = { DEX = 0.80 },
            crit_rate = { 0.10, 0.25, 0.40 },
            sc = { "Light", "Transfixion" },
        },
    },

    great_katana = {
        ["Tachi: Fudo"] = {
            hits = 1,
            class = "physical",
            ftp = { 4.75, 7.50, 9.75 },
            ftp_rep = false,
            wsc = { STR = 0.80 },
            sc = { "Light", "Fragmentation" },
        },
    },

    polearm = {
        ["Stardiver"] = {
            hits = 4,
            class = "physical",
            ftp = { 0.828125, 0.875, 0.90625 },
            ftp_rep = true,
            wsc = { STR = 0.60 },
            sc = { "Light", "Detonation" },
        },
    },

    hand_to_hand = {
        ["Victory Smite"] = {
            hits = 4,
            class = "physical",
            ftp = { 1.50, 1.50, 1.50 },
            ftp_rep = true,
            wsc = { STR = 0.80 },
            crit_rate = { 0.10, 0.25, 0.45 },
            sc = { "Light", "Fragmentation" },
        },
    },

    staff = {
        ["Cataclysm"] = {
            hits = 1,
            class = "magical",
            ftp = { 3.75, 6.50, 8.50 },
            ftp_rep = false,
            wsc = { INT = 0.40, MND = 0.40 },
            element = "Darkness",
            dstat = "INT-MND",
            sc = { "Darkness", "Gravitation" },
        },
    },

    marksmanship = {
        ["Last Stand"] = {
            hits = 2,
            class = "ranged_physical",
            ftp = { 2.00, 2.00, 2.00 },
            ftp_rep = true,
            wsc = { AGI = 0.80 },
            sc = { "Light", "Fragmentation" },
        },

        ["Leaden Salute"] = {
            hits = 1,
            class = "magical_ranged",
            ftp = { 4.00, 10.19, 13.00 },
            ftp_rep = false,
            wsc = { AGI = 0.80 },
            element = "Darkness",
            dstat = "AGI-VIT",
            sc = { "Darkness", "Gravitation" },
        },

        ["Wildfire"] = {
            hits = 1,
            class = "magical_ranged",
            ftp = { 2.00, 2.75, 3.50 },
            ftp_rep = false,
            wsc = { AGI = 0.60 },
            element = "Fire",
            dstat = "AGI-MND",
            sc = { "Light", "Fusion" },
        },
    },

    archery = {
        ["Jishnu's Radiance"] = {
            hits = 3,
            class = "ranged_physical",
            ftp = { 1.75, 1.75, 1.75 },
            ftp_rep = true,
            wsc = { DEX = 0.80 },
            -- (Page notes crit scales with TP, but exact tiers aren’t listed; omit when not explicit.)
            sc = { "Light", "Transfixion" },
        },

        ["Namas Arrow"] = {
            hits = 1,
            class = "ranged_physical",
            ftp = { 3.50, 3.50, 3.50 },
            ftp_rep = false,
            wsc = { STR = 0.30, AGI = 0.30 },
            sc = { "Light", "Fusion" },
        },

        ["Apex Arrow"] = {
            hits = 1,
            class = "ranged_physical",
            ftp = { 1.50, 1.75, 2.00 },
            ftp_rep = false,
            wsc = { STR = 0.20, AGI = 0.20 },
            sc = { "Light", "Detonation" },
        },
    },
}

return codex
