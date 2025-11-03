-- Copyright (c) 2025, NeatMachine
-- All rights reserved. (BSD-3-Clause)

local Spellbook = {}

--These sets are mapped, in order of priority, to spells in the spell_map below.
--Applied before (and therefore overwritten by) any set named for a specific spell (or its base).
local CALC_SETS = {
  MAB        = "mab",
  MACC       = "macc",
  MB         = "mb",
  NUKE       = "nuke",
  STR        = "str",
  VIT        = "vit",
  DEX        = "dex",
  MND        = "mnd",
  INT        = "int",
  CHR        = "chr",

  HEALING    = {
    DEFAULT = "healing",
    WEATHER = "healing.weather",
  },

  ENFEEBLING = {
    DEFAULT  = "enfeebling",
    MACC     = "enfeebling.macc",
    MND      = "enfeebling.mnd",
    INT      = "enfeebling.int",
    SKILL    = "enfeebling.skill",
    DURATION = "enfeebling.duration",
  },

  ENHANCING  = {
    DEFAULT     = "enhancing",
    DURATION    = "enhancing.duration",
    POTENCY     = "enhancing.potency",
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
  },

  dark       = {
    default     = "dark",
    enfeeble    = "dark.enfeeble",
    drain_aspir = "dark.drain_aspir",
    absorb      = "dark.absorb",
  },

  divine     = {
    default = "divine",
    skill = "divine.skill",
    nuke = "divine.nuke"
  }
}

-- Lowest Priority => Highest Priority list of appplicable equipment sets.
-- The set corresponding to magic type (ex: enfeebling) is always applied before these are considred.
-- In some cases, we introduce a raw stat and then re-insert the base "enfeebling" or "enhancing" set to jump it in priority.
-- Explicit sets always win, if you create a "Drain" set it will be equipped last for Drain.
-- Tiered spells like "Drain III" will look for explicit sets, but then fall back to base "Drain" and use its set and its spell map.
local spell_map = {
  enfeebling = {
    ["Sleep"]       = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Sleepga"]     = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Silence"]     = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Bind"]        = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Break"]       = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Breakga"]     = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Dispel"]      = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Inundation"]  = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Gravity"]     = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },
    ["Frazzle"]     = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc },

    -- Remember, you can always create an explicit set for a spell or its base. They will be applied last.
    -- //gs c save distract
    -- //gs c save frazzle_iii
    ["Distract"]    = { CALC_SETS.macc, CALC_SETS.mnd, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.skill, CALC_SETS.enfeebling.mnd },
    ["Frazzle III"] = { CALC_SETS.macc, CALC_SETS.mnd, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.skill, CALC_SETS.enfeebling.mnd },

    -- Potency: stat driven
    ["Paralyze"]    = { CALC_SETS.mnd, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc, CALC_SETS.enfeebling.mnd },
    ["Slow"]        = { CALC_SETS.mnd, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc, CALC_SETS.enfeebling.mnd },
    ["Addle"]       = { CALC_SETS.mnd, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc, CALC_SETS.enfeebling.mnd },

    ["Blind"]       = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.macc, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.skill, CALC_SETS.enfeebling.int },

    -- Potency: skill-based ticks
    ["Poison"]      = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc, CALC_SETS.enfeebling.skill },
    ["Poisonga"]    = { CALC_SETS.macc, CALC_SETS.enfeebling.default, CALC_SETS.enfeebling.duration, CALC_SETS.enfeebling.macc, CALC_SETS.enfeebling.skill },

    ["Dia"]         = { CALC_SETS.enfeebling.duration },
  },

  enhancing = {
    ["Temper"]       = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill },
    ["Haste"]        = { CALC_SETS.enhancing.duration },
    ["Auspice"]      = { CALC_SETS.enhancing.duration },

    ["Protect"]      = { CALC_SETS.enhancing.duration },
    ["Protectra"]    = { CALC_SETS.enhancing.duration },
    ["Shell"]        = { CALC_SETS.enhancing.duration },
    ["Shellra"]      = { CALC_SETS.enhancing.duration },

    ["Enfire"]       = { CALC_SETS.macc, CALC_SETS.enhancing.default, CALC_SETS.enhancing.macc, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.enspell },
    ["Enblizzard"]   = { CALC_SETS.macc, CALC_SETS.enhancing.default, CALC_SETS.enhancing.macc, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.enspell },
    ["Enaero"]       = { CALC_SETS.macc, CALC_SETS.enhancing.default, CALC_SETS.enhancing.macc, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.enspell },
    ["Enstone"]      = { CALC_SETS.macc, CALC_SETS.enhancing.default, CALC_SETS.enhancing.macc, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.enspell },
    ["Enthunder"]    = { CALC_SETS.macc, CALC_SETS.enhancing.default, CALC_SETS.enhancing.macc, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.enspell },
    ["Enwater"]      = { CALC_SETS.macc, CALC_SETS.enhancing.default, CALC_SETS.enhancing.macc, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.enspell },

    -- Element bars
    ["Barfire"]      = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barblizzard"]  = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Baraero"]      = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barstone"]     = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barthunder"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barwater"]     = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },

    ["Barfira"]      = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barblizzara"]  = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Baraera"]      = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barstonra"]    = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barthundra"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },
    ["Barwatera"]    = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_element },

    ["Baramnesia"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barvirus"]     = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barparalyze"]  = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barsilence"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barpetrify"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barpoison"]    = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barblind"]     = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },
    ["Barsleep"]     = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.bar_status },

    ["Baramnesra"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barvira"]      = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barparalyzra"] = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barsilencera"] = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barpetra"]     = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barpoisonra"]  = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barblindra"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },
    ["Barsleepra"]   = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill, CALC_SETS.enhancing.duration, CALC_SETS.enhancing.bar_status },

    -- You'll probably want to create sets for these
    -- //gs c save stoneskin
    -- //gs c save phalanx
    ["Stoneskin"]    = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.default, CALC_SETS.enhancing.skill },
    ["Phalanx"]      = { CALC_SETS.enhancing.duration, CALC_SETS.enhancing.skill },

    ["Blaze Spikes"] = { CALC_SETS.mab, CALC_SETS.enhancing.spikes },
    ["Ice Spikes"]   = { CALC_SETS.mab, CALC_SETS.enhancing.spikes },
    ["Shock Spikes"] = { CALC_SETS.mab, CALC_SETS.enhancing.spikes },

    ["Refresh"]      = { CALC_SETS.enhancing.duration },
    ["Regen"]        = { CALC_SETS.enhancing.duration },
  },

  elemental = {
    ["Burn"]        = { CALC_SETS.int, CALC_SETS.elemental.enfeeble },
    ["Frost"]       = { CALC_SETS.int, CALC_SETS.elemental.enfeeble },
    ["Choke"]       = { CALC_SETS.int, CALC_SETS.elemental.enfeeble },
    ["Rasp"]        = { CALC_SETS.int, CALC_SETS.elemental.enfeeble },
    ["Shock"]       = { CALC_SETS.int, CALC_SETS.elemental.enfeeble },
    ["Drown"]       = { CALC_SETS.int, CALC_SETS.elemental.enfeeble },

    ["Pyrohelix"]   = { CALC_SETS.elemental.helix },
    ["Cryohelix"]   = { CALC_SETS.elemental.helix },
    ["Anemohelix"]  = { CALC_SETS.elemental.helix },
    ["Geohelix"]    = { CALC_SETS.elemental.helix },
    ["Ionohelix"]   = { CALC_SETS.elemental.helix },
    ["Hydrohelix"]  = { CALC_SETS.elemental.helix },
    ["Luminohelix"] = { CALC_SETS.elemental.helix },
    ["Noctohelix"]  = { CALC_SETS.elemental.helix_dark },

    ["Fire"]        = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Blizzard"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Aero"]        = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Stone"]       = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Thunder"]     = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Water"]       = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },

    ["Firaga"]      = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Blizzaga"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Aeroga"]      = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Stonega"]     = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Thunderga"]   = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Waterga"]     = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },

    ["Fira"]        = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.geo },
    ["Blizzara"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.geo },
    ["Stonera"]     = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.geo },
    ["Aera"]        = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.geo },
    ["Thundara"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.geo },
    -- Just in case
    ["Watera"]      = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },


    ["Flare"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Freeze"]   = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Tornado"]  = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.elemental.macc, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Quake"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Burst"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },
    ["Flood"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.macc, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },

    ["Meteor"]   = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke },

    ["Comet"]    = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },
    ["Firaja"]   = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },
    ["Blizzaja"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },
    ["Aeroja"]   = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },
    ["Stoneja"]  = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },
    ["Thundaja"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },
    ["Waterja"]  = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.elemental.default, CALC_SETS.elemental.skill, CALC_SETS.mab, CALC_SETS.elemental.nuke, CALC_SETS.elemental.cumulative },

  },

  --TBH, you should just create Drain + Absorb sets, which will overwrite all of this.
  -- "drain" + "dark.absorb"
  dark = {
    ["Bio"]        = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.enfeeble },
    ["Drain"]      = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb, "Aspir", CALC_SETS.dark.drain_aspir },
    ["Aspir"]      = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb, "Drain", CALC_SETS.dark.drain_aspir },
    ["Absorb-STR"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-DEX"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-VIT"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-INT"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-MND"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-CHR"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-AGI"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-ACC"] = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
    ["Absorb-TP"]  = { CALC_SETS.macc, CALC_SETS.int, CALC_SETS.dark.default, CALC_SETS.dark.skill, CALC_SETS.dark.absorb },
  },

  divine = {
    ["Banish"] = { CALC_SETS.macc, CALC_SETS.mnd, CALC_SETS.divine.default, CALC_SETS.divine.skill, CALC_SETS.divine.nuke },
    ["Holy"]   = { CALC_SETS.macc, CALC_SETS.mnd, CALC_SETS.divine.default, CALC_SETS.divine.skill, CALC_SETS.divine.nuke },
  },

  healing = {
    -- You should definitely just make a specific "cure" set.
    -- //gs c save cure
    ["Cure"] = { CALC_SETS.mnd, CALC_SETS.healing.default }
  }
}

-- Instant/near-instant where midcast set during precast is desirable
local INSTANT = { ["Stun"] = true }

-- Buffs you typically cancel before reapplying
local NON_REFRESHABLE = {
  ["Stoneskin"] = true,
  ["Aquaveil"] = true,
  ["Phalanx"] = true,
  ["Ice Spikes"] = true,
  ["Blaze Spikes"] = true,
  ["Shock Spikes"] = true,
}

-----------------------------------------------------------
-- small utils
-----------------------------------------------------------
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function get_base(name)
  if not name or name == "" then return "" end
  local s = tostring(name)
  local base = s:match("^(.-)%s+[IVX]+$") or s
  return trim(base)
end

local function push_unique(t, name, seen, dbg_reason)
  if not name or name == "" then return end
  seen = seen or {}
  if not seen[name] then
    t[#t + 1] = name
    seen[name] = true
    local dbg = (rawget(_G, "AutoLoader") and AutoLoader.debug) or function() end
    dbg("[Spellbook] push '%s'%s", name, dbg_reason and (" (" .. dbg_reason .. ")") or "")
  end
end

local function mode_magic()
  local mode = (rawget(_G, "AutoLoader")
    and AutoLoader.modes and AutoLoader.modes.magic
    and AutoLoader.modes.magic.current) or "default"
  return tostring(mode):lower()
end

local function tbl_join(t, sep)
  sep = sep or ", "
  local out = {}
  for i, v in ipairs(t or {}) do out[i] = tostring(v) end
  return table.concat(out, sep)
end

-----------------------------------------------------------
-- public helpers
-----------------------------------------------------------
function Spellbook.is_instant(spell_or_name)
  local name = type(spell_or_name) == "table" and (spell_or_name.english or spell_or_name.name) or spell_or_name
  return INSTANT[get_base(name)]
end

function Spellbook.is_refreshable(spell_or_name)
  local name = type(spell_or_name) == "table" and (spell_or_name.english or spell_or_name.name) or spell_or_name
  if not name then return true end
  return not NON_REFRESHABLE[get_base(name)]
end

function Spellbook.collect_spell_map_set_names(opts)
  -- Returns a flat array of all set names referenced in spell_map, in the
  -- order they appear within each spell's list. If opts.dedupe = true,
  -- duplicates are removed while preserving first-seen order.
  local dedupe = opts and opts.dedupe
  local names, seen = {}, {}

  local function add(v)
    v = tostring(v or "")
    if v == "" then return end
    if dedupe then
      if seen[v] then return end
      seen[v] = true
    end
    names[#names + 1] = v
  end

  if type(spell_map) ~= "table" then return names end

  for _, byspell in pairs(spell_map) do
    if type(byspell) == "table" then
      for _, arr in pairs(byspell) do
        if type(arr) == "table" then
          for i = 1, #arr do add(arr[i]) end
        else
          add(arr)
        end
      end
    end
  end

  return names
end

-----------------------------------------------------------
-- core: compute ordered set names for this spell
-- Order is highest -> lowest priority. AutoLoader resolves & combines.
-----------------------------------------------------------
function Spellbook.get_ordered_set_names(spell)
  local dbg = (rawget(_G, "AutoLoader") and AutoLoader.debug) or function() end
  local out, seen = {}, {}
  if not spell then
    dbg("[Spellbook] get_ordered_set_names(nil) -> []")
    return out
  end

  local name  = (spell.english or spell.name or "")
  local base  = get_base(name)
  local skill = (spell.skill and spell.skill:match("^(%S+)"):lower()) or "" -- "enfeebling", "dark", "enhancing", etc.

  dbg("[Spellbook] resolve: name='%s' base='%s' skill='%s'", tostring(name), tostring(base), tostring(skill))

  -- helper: try to fetch a mapping (array or string) for a given key from either a flat or grouped map
  local function lookup_map(key)
    if not key or key == "" then return nil end
    -- flat table support: SPELL_MAP or spell_map
    if type(SPELL_MAP) == "table" and SPELL_MAP[key] then return SPELL_MAP[key] end
    if type(spell_map) == "table" and spell_map[key] then return spell_map[key] end
    -- grouped table support: spell_map.enfeebling / spell_map.enhancing / etc.
    if type(spell_map) == "table" then
      for _, group in pairs(spell_map) do
        if type(group) == "table" and group[key] then return group[key] end
      end
    end
    return nil
  end

  local function push_map(m, why)
    if not m then return end
    if type(m) == "string" then
      push_unique(out, m, seen, why)
    elseif type(m) == "table" then
      for _, v in ipairs(m) do
        push_unique(out, v, seen, why)
      end
    end
  end

  local function explicit_key(s)
    return (tostring(s or "")):lower():gsub("%s+", "_")
  end

  -- 1) Always start with the spell's skill bucket (e.g., "enfeebling", "dark", "enhancing")
  if skill ~= "" then
    push_unique(out, skill, seen, "skill-first")
  end

  -- 2) If this is tiered, use the base spell's map first (ascending priority list)
  if base ~= "" and base ~= name then
    push_map(lookup_map(base), "base-map")
  else
    -- even non-tiered spells may have a base-keyed entry
    push_map(lookup_map(base), "base-map")
  end

  -- 3) Then the exact spell's map, if it exists (e.g., "Drain II")
  push_map(lookup_map(name), "exact-map")

  -- 4) Then base spell's explicit set name (e.g., "drain")
  if base ~= "" then
    push_unique(out, base:lower(), seen, "explicit-base")
  end

  -- 5) Finally the exact spell's explicit set name (e.g., "drain_ii")
  push_unique(out, explicit_key(name), seen, "explicit-exact")

  dbg("[Spellbook] ordered => [%s]", tbl_join(out))
  return out
end

-----------------------------------------------------------
-- expose internals (optional: for tests / tooling)
-----------------------------------------------------------
Spellbook._internal = {
  CALC_SETS       = CALC_SETS,
  spell_map       = spell_map,
  INSTANT         = INSTANT,
  NON_REFRESHABLE = NON_REFRESHABLE,
}

return Spellbook
