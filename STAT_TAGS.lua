local STAT_TAGS = {
  -- Primary attributes
  hp                     = "HP",
  mp                     = "MP",
  str                    = "STR",
  dex                    = "DEX",
  vit                    = "VIT",
  agi                    = "AGI",
  int                    = "INT",
  mnd                    = "MND",
  chr                    = "CHR",

  -- Melee offense
  accuracy               = "Accuracy",
  attack                 = "Attack",
  atk_abbrev             = "Atk.",
  crit_rate              = "Critical hit rate",
  double_attack          = "Double Attack",
  triple_attack          = "Triple Attack",
  quadruple_attack       = "Quadruple Attack",
  weapon_skill_damage    = "Weapon Skill Damage",
  physical_damage_limit  = "Physical damage limit",
  pdl                    = "PDL",

  -- Ranged offense
  ranged_accuracy        = "Ranged Accuracy",
  ranged_acc_abbrev      = "Ranged Acc.",
  r_acc                  = "R.Acc.",
  ranged_attack          = "Ranged Attack",
  ranged_atk_abbrev      = "Ranged Atk.",
  r_att                  = "R.Att.",
  true_shot              = "True Shot",
  barrage                = "Barrage",

  -- Tempo (melee / ranged)
  haste                  = "Haste",
  dual_wield             = "Dual Wield",
  snapshot               = "Snapshot",
  rapid_shot             = "Rapid Shot",

  -- TP / Subtle (split)
  store_tp               = "Store TP",
  save_tp                = "Save TP",
  tp_bonus               = "TP Bonus",
  regain                 = "Regain",
  subtle_blow            = "Subtle Blow",
  subtle_blow_ii         = "Subtle Blow II",

  -- Caster offense
  magic_accuracy         = "Magic Accuracy",
  mag_acc                = "Mag. Acc.",
  magic_acc              = "Magic Acc.",
  magic_atk_bonus        = "Magic Atk. Bonus",
  mag_atk_bns            = "Mag. Atk. Bns.",
  fast_cast              = "Fast Cast",
  magic_burst_damage     = "Magic burst damage",
  magic_burst_damage_ii  = "Magic burst damage II",
  skillchain_bonus       = "Skillchain Bonus",

  -- Defense / magic defense
  evasion                = "Evasion",
  eva_abbrev             = "Eva.",
  magic_evasion          = "Magic Evasion",
  mag_eva                = "Mag. Eva.",
  m_eva                  = "M.Eva",
  magic_eva              = "Magic Eva.",
  magic_def_bonus        = "Magic Def. Bonus",
  magic_defense_bonus    = "Magic Defense Bonus",
  mdb                    = "MDB",

  -- Mitigation
  damage_taken           = "Damage taken",
  pdt                    = "PDT",
  physical_damage_taken  = "Physical damage taken",
  mdt                    = "MDT",
  magic_damage_taken     = "Magic damage taken",

  -- Resistances
  all_status_resist      = "Resistance to all status ailments",
  resist_petrify         = "Resist Petrify",
  resist_bind            = "Resist Bind",
  resist_gravity         = "Resist Gravity",
  resist_silence         = "Resist Silence",
  resist_dark            = "Resist Dark",

  -- Utility / control
  refresh                = "Refresh",
  conserve_mp            = "Conserve MP",
  movement_speed         = "Movement speed",
  enmity                 = "Enmity",
  spell_interrupt_down   = "Spell interruption rate down",
  treasure_hunter        = "Treasure Hunter",

  -- Healer / enhancer
  cure_potency           = "\"Cure\" potency",
  cure_potency_plain     = "Cure potency",
  cure_potency_ii        = "Cure potency II",
  cure_potency_received  = "Cure potency received",
  cure_effect_received   = "\"Cure\" effect received",
  enhancing_duration     = "Enhancing magic duration",
  song_duration          = "Song duration",
  all_songs              = "All songs",

  -- Skills (+X)
  parrying_skill         = "Parrying skill",
  dagger_skill           = "Dagger skill",
  club_skill             = "Club skill",
  great_axe_skill        = "Great Axe skill",
  magic_accuracy_skill   = "Magic Accuracy skill",
}

return STAT_TAGS
