local codex = {}

codex.STAT = {
  hp="HP", mp="MP", str="STR", dex="DEX", vit="VIT", agi="AGI", int="INT", mnd="MND", chr="CHR",
  accuracy="Accuracy", attack="Attack",
  ranged_accuracy="RangedAccuracy", ranged_attack="RangedAttack",
  macc="MagicAccuracy", mab="MAB",
  haste_pct="HastePct", dt="DT", pdt="PDT", mdt="MDT",
  eva="Evasion", meva="MEVA",
  store_tp="StoreTP", save_tp="SaveTP", tp_bonus="TPBonus",
  da="DA", ta="TA", qa="QA",
  fast_cast="FastCast",
  mbd="MBD", mbd2="MBD2",
  sc_bonus="SCBonus",
  refresh="Refresh",
  subtle_blow="SubtleBlow",
  subtle_blow_ii="SubtleBlowII",
}

codex.PERCENT_LIKE = {
  HastePct=true, DT=true, PDT=true, MDT=true, MBD=true, MBD2=true, SCBonus=true,
}

codex.TAGS = {
  hp="HP", mp="MP", str="STR", dex="DEX", vit="VIT", agi="AGI", int="INT", mnd="MND", chr="CHR",
  accuracy="Accuracy", acc_abbrev="Acc.",
  attack="Attack",   atk_abbrev="Atk.",
  ranged_accuracy="Ranged Accuracy", r_acc="R.Acc.", ranged_acc_abbrev="Rng. Acc.",
  ranged_attack="Ranged Attack",     r_att="R.Att.", ranged_atk_abbrev="Rng. Atk.",
  magic_accuracy="Magic Accuracy", mag_acc="Mag. Acc.", magic_acc="Magic Acc.",
  magic_atk_bonus="Magic Atk. Bonus", mag_atk_bns="Mag. Atk. Bns.",
  haste="Haste",
  damage_taken="Damage taken", pdt="PDT", mdt="MDT",
  evasion="Evasion", mag_eva="Mag. Eva.", m_eva="M.Eva", magic_evasion="Magic Evasion",
  store_tp="Store TP", save_tp="Save TP", tp_bonus="TP Bonus",
  double_attack="Double Attack", triple_attack="Triple Attack", quadruple_attack="Quadruple Attack",
  fast_cast="Fast Cast",
  magic_burst_damage="Magic burst damage", magic_burst_damage_ii="Magic burst damage II",
  skillchain_bonus="Skillchain Bonus",
  refresh="Refresh",
  subtle_blow="Subtle Blow", subtle_blow_ii="Subtle Blow II",
}

codex.STAT_TAGS = {
  [codex.STAT.hp] = { codex.TAGS.hp }, [codex.STAT.mp] = { codex.TAGS.mp },
  [codex.STAT.str] = { codex.TAGS.str }, [codex.STAT.dex] = { codex.TAGS.dex }, [codex.STAT.vit] = { codex.TAGS.vit },
  [codex.STAT.agi] = { codex.TAGS.agi }, [codex.STAT.int] = { codex.TAGS.int }, [codex.STAT.mnd] = { codex.TAGS.mnd }, [codex.STAT.chr] = { codex.TAGS.chr },

  [codex.STAT.accuracy] = { codex.TAGS.accuracy, codex.TAGS.acc_abbrev },
  [codex.STAT.attack]   = { codex.TAGS.attack,   codex.TAGS.atk_abbrev },

  [codex.STAT.ranged_accuracy] = { codex.TAGS.ranged_accuracy, codex.TAGS.ranged_acc_abbrev or codex.TAGS.r_acc },
  [codex.STAT.ranged_attack]   = { codex.TAGS.ranged_attack,   codex.TAGS.ranged_atk_abbrev or codex.TAGS.r_att },

  [codex.STAT.macc] = { codex.TAGS.magic_accuracy, codex.TAGS.mag_acc, codex.TAGS.magic_acc },
  [codex.STAT.mab]  = { codex.TAGS.magic_atk_bonus, codex.TAGS.mag_atk_bns },

  [codex.STAT.haste_pct] = { codex.TAGS.haste },

  [codex.STAT.dt]  = { codex.TAGS.damage_taken }, [codex.STAT.pdt] = { codex.TAGS.pdt }, [codex.STAT.mdt] = { codex.TAGS.mdt },

  [codex.STAT.eva]  = { codex.TAGS.evasion },
  [codex.STAT.meva] = { codex.TAGS.magic_evasion, codex.TAGS.mag_eva, codex.TAGS.m_eva },

  [codex.STAT.store_tp] = { codex.TAGS.store_tp }, [codex.STAT.save_tp] = { codex.TAGS.save_tp }, [codex.STAT.tp_bonus] = { codex.TAGS.tp_bonus },

  [codex.STAT.da] = { codex.TAGS.double_attack }, [codex.STAT.ta] = { codex.TAGS.triple_attack }, [codex.STAT.qa] = { codex.TAGS.quadruple_attack },

  [codex.STAT.fast_cast] = { codex.TAGS.fast_cast },

  [codex.STAT.mbd] = { codex.TAGS.magic_burst_damage }, [codex.STAT.mbd2] = { codex.TAGS.magic_burst_damage_ii },
  [codex.STAT.sc_bonus] = { codex.TAGS.skillchain_bonus },

  [codex.STAT.refresh] = { codex.TAGS.refresh },

  [codex.STAT.subtle_blow]    = { codex.TAGS.subtle_blow },
  [codex.STAT.subtle_blow_ii] = { codex.TAGS.subtle_blow_ii },
}

codex.BAG_KEYS = {
  'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4',
  'wardrobe5','wardrobe6','wardrobe7','wardrobe8',
}

codex.SLOT_NAMES = {
  [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',[6]='Hands',[7]='Legs',
  [8]='Feet',[9]='Neck',[10]='Waist',[11]='Left Ear',[12]='Right Ear',[13]='Left Ring',[14]='Right Ring',[15]='Back'
}

codex.TAG_ID_BY_LABEL = {}
for _, lbl in pairs(codex.TAGS) do
  if type(lbl) == "string" and lbl ~= "" then
    codex.TAG_ID_BY_LABEL[lbl] = lbl
    codex.TAG_ID_BY_LABEL['"'..lbl..'"'] = lbl
  end
end

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

codex.SPELL_CASTING_SETS = {
  enfeebling = {
    ["Sleep"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Sleepga"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Silence"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Bind"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Break"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Breakga"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Dispel"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Inundation"]  = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Gravity"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },
    ["Frazzle"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc },

    -- Remember, you can always create an explicit set for a spell or its base. They will be applied last.
    -- //gs c save distract
    -- //gs c save frazzle_iii
    ["Distract"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.skill, codex.CASTING_SETS.enfeebling.mnd },
    ["Frazzle III"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.skill, codex.CASTING_SETS.enfeebling.mnd },

    -- Potency: stat driven
    ["Paralyze"]    = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.mnd },
    ["Slow"]        = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.mnd },
    ["Addle"]       = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.mnd },

    ["Blind"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.skill, codex.CASTING_SETS.enfeebling.int },

    -- Potency: skill-based ticks
    ["Poison"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.skill },
    ["Poisonga"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.enfeebling.default, codex.CASTING_SETS.enfeebling.duration, codex.CASTING_SETS.enfeebling.macc, codex.CASTING_SETS.enfeebling.skill },

    ["Dia"]         = { codex.CASTING_SETS.enfeebling.duration },
  },

  enhancing = {
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

    -- Element bars
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
  },

  elemental = {
    ["Burn"]        = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Frost"]       = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Choke"]       = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Rasp"]        = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Shock"]       = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },
    ["Drown"]       = { codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.enfeeble },

    ["Pyrohelix"]   = { codex.CASTING_SETS.elemental.helix },
    ["Cryohelix"]   = { codex.CASTING_SETS.elemental.helix },
    ["Anemohelix"]  = { codex.CASTING_SETS.elemental.helix },
    ["Geohelix"]    = { codex.CASTING_SETS.elemental.helix },
    ["Ionohelix"]   = { codex.CASTING_SETS.elemental.helix },
    ["Hydrohelix"]  = { codex.CASTING_SETS.elemental.helix },
    ["Luminohelix"] = { codex.CASTING_SETS.elemental.helix },
    ["Noctohelix"]  = { codex.CASTING_SETS.elemental.helix_dark },

    ["Fire"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Blizzard"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Aero"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Stone"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Thunder"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Water"]       = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },

    ["Firaga"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Blizzaga"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Aeroga"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Stonega"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Thunderga"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },
    ["Waterga"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.macc, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },

    ["Fira"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Blizzara"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Stonera"]     = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Aera"]        = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    ["Thundara"]    = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke, codex.CASTING_SETS.elemental.geo },
    -- Just in case
    ["Watera"]      = { codex.CASTING_SETS.macc, codex.CASTING_SETS.int, codex.CASTING_SETS.elemental.default, codex.CASTING_SETS.elemental.skill, codex.CASTING_SETS.mab, codex.CASTING_SETS.elemental.nuke },


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

  },

  --TBH, you should just create Drain + Absorb sets, which will overwrite all of this.
  -- "drain" + "dark.absorb"
  dark = {
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
  },

  divine = {
    ["Banish"] = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.divine.default, codex.CASTING_SETS.divine.skill, codex.CASTING_SETS.divine.nuke },
    ["Holy"]   = { codex.CASTING_SETS.macc, codex.CASTING_SETS.mnd, codex.CASTING_SETS.divine.default, codex.CASTING_SETS.divine.skill, codex.CASTING_SETS.divine.nuke },
  },

  healing = {
    -- You should definitely just make a specific "cure" set.
    -- //gs c save cure
    ["Cure"] = { codex.CASTING_SETS.mnd, codex.CASTING_SETS.healing.default }
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

function codex.base(name)
  if not name or name == "" then return "" end
  local s = tostring(name)
  local base = s:match("^(.-)%s+[IVX]+$") or s
  return (tostring(base or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

codex.WEAPON_SKILLS = {

  sword = {
    ["Savage Blade"] = {
      hits = 2,
      class = "physical",
      ftp = {4.00, 10.25, 13.75},
      ftp_rep = false,
      wsc = { STR = 0.50, MND = 0.50 },
      sc = {"Fragmentation", "Scission"},
    },

    ["Chant du Cygne"] = {
      hits = 3,
      class = "physical",
      ftp = {1.6328125, 1.6328125, 1.6328125},
      ftp_rep = true,
      wsc = { DEX = 0.80 },
      crit_rate = {0.15, 0.25, 0.40},
      sc = {"Light", "Distortion"},
    },
  },

  great_sword = {
    ["Resolution"] = {
      hits = 5,
      class = "physical",
      ftp = {0.71875, 1.50, 2.25},
      ftp_rep = true,
      wsc = { STR = 0.80 },        -- BG lists 73~85% depending on merits/history; use 0.80 as current
      attack_mod = 0.85,
      sc = {"Light", "Fragmentation", "Scission"},
    },

    ["Torcleaver"] = {
      hits = 1,
      class = "physical",
      ftp = {4.75, 7.50, 9.765625},
      ftp_rep = false,
      wsc = { VIT = 0.80 },
      sc = {"Light", "Distortion"},
    },
  },

  dagger = {
    ["Rudra's Storm"] = {
      hits = 1,
      class = "physical",
      ftp = {5.00, 10.19, 13.00},
      ftp_rep = false,
      wsc = { DEX = 0.80 },
      sc = {"Darkness", "Distortion"},
    },

    ["Evisceration"] = {
      hits = 5,
      class = "physical",
      ftp = {1.25, 1.25, 1.25},
      ftp_rep = true,
      wsc = { DEX = 0.50 },
      crit_rate = {0.10, 0.25, 0.50},
      sc = {"Gravitation", "Transfixion"},
    },
  },

  katana = {
    ["Blade: Hi"] = {
      hits = 1,
      class = "physical",
      ftp = {3.50, 3.50, 3.50},
      ftp_rep = false,
      wsc = { DEX = 0.80 },
      crit_rate = {0.10, 0.25, 0.40},
      sc = {"Light", "Transfixion"},
    },
  },

  great_katana = {
    ["Tachi: Fudo"] = {
      hits = 1,
      class = "physical",
      ftp = {4.75, 7.50, 9.75},
      ftp_rep = false,
      wsc = { STR = 0.80 },
      sc = {"Light", "Fragmentation"},
    },
  },

  polearm = {
    ["Stardiver"] = {
      hits = 4,
      class = "physical",
      ftp = {0.828125, 0.875, 0.90625},
      ftp_rep = true,
      wsc = { STR = 0.60 },
      sc = {"Light", "Detonation"},
    },
  },

  hand_to_hand = {
    ["Victory Smite"] = {
      hits = 4,
      class = "physical",
      ftp = {1.50, 1.50, 1.50},
      ftp_rep = true,
      wsc = { STR = 0.80 },
      crit_rate = {0.10, 0.25, 0.45},
      sc = {"Light", "Fragmentation"},
    },
  },

  staff = {
    ["Cataclysm"] = {
      hits = 1,
      class = "magical",
      ftp = {3.75, 6.50, 8.50},
      ftp_rep = false,
      wsc = { INT = 0.40, MND = 0.40 },
      element = "Darkness",
      dstat = "INT-MND",
      sc = {"Darkness", "Gravitation"},
    },
  },

  marksmanship = {
    ["Last Stand"] = {
      hits = 2,
      class = "ranged_physical",
      ftp = {2.00, 2.00, 2.00},
      ftp_rep = true,
      wsc = { AGI = 0.80 },
      sc = {"Light", "Fragmentation"},
    },

    ["Leaden Salute"] = {
      hits = 1,
      class = "magical_ranged",
      ftp = {4.00, 10.19, 13.00},
      ftp_rep = false,
      wsc = { AGI = 0.80 },
      element = "Darkness",
      dstat = "AGI-VIT",
      sc = {"Darkness", "Gravitation"},
    },

    ["Wildfire"] = {
      hits = 1,
      class = "magical_ranged",
      ftp = {2.00, 2.75, 3.50},
      ftp_rep = false,
      wsc = { AGI = 0.60 },
      element = "Fire",
      dstat = "AGI-MND",
      sc = {"Light", "Fusion"},
    },
  },

  archery = {
    ["Jishnu's Radiance"] = {
      hits = 3,
      class = "ranged_physical",
      ftp = {1.75, 1.75, 1.75},
      ftp_rep = true,
      wsc = { DEX = 0.80 },
      -- (Page notes crit scales with TP, but exact tiers aren’t listed; omit when not explicit.)
      sc = {"Light", "Transfixion"},
    },

    ["Namas Arrow"] = {
      hits = 1,
      class = "ranged_physical",
      ftp = {3.50, 3.50, 3.50},
      ftp_rep = false,
      wsc = { STR = 0.30, AGI = 0.30 },
      sc = {"Light", "Fusion"},
    },

    ["Apex Arrow"] = {
      hits = 1,
      class = "ranged_physical",
      ftp = {1.50, 1.75, 2.00},
      ftp_rep = false,
      wsc = { STR = 0.20, AGI = 0.20 },
      sc = {"Light", "Detonation"},
    },
  },
}

return codex