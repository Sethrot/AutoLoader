-- aliases.lua (in-game strings only)
local Aliases = {}

-- Canonical → list of in-game label variants you actually see on gear
Aliases.by_canon = {
  -- Headers / params
  DEF               = { "DEF" },
  DMG               = { "DMG" },
  Delay             = { "Delay" },
  DPS               = { "DPS" },

  -- Primary attrs
  HP                = { "HP" },
  MP                = { "MP" },
  STR               = { "STR" },
  DEX               = { "DEX" },
  VIT               = { "VIT" },
  AGI               = { "AGI" },
  INT               = { "INT" },
  MND               = { "MND" },
  CHR               = { "CHR" },

  -- Melee offense
  Accuracy          = { "Accuracy" },
  Attack            = { "Attack", "Atk." },
  CritRatePct       = { "Critical hit rate" },
  DA                = { "Double Attack" },
  TA                = { "Triple Attack" },
  QA                = { "Quadruple Attack" },
  WSD               = { "Weapon Skill Damage" },
  PDL               = { "Physical damage limit", "PDL" }, -- some items show full text, some show PDL

  -- Ranged offense
  RangedAccuracy    = { "Ranged Accuracy", "Ranged Acc.", "R.Acc." },
  RangedAttack      = { "Ranged Attack",   "Ranged Atk.", "R.Att." },
  TrueShot          = { "True Shot" },
  Barrage           = { "Barrage" },

  -- Tempo (melee / ranged)
  HastePct          = { "Haste" },
  DualWieldPct      = { "Dual Wield" },
  Snapshot          = { "Snapshot" },
  RapidShot         = { "Rapid Shot" },

  -- TP / Subtle (split)
  StoreTP           = { "Store TP" },
  SaveTP            = { "Save TP" },
  TPBonus           = { "TP Bonus" },
  Regain            = { "Regain" },
  SubtleBlow        = { "Subtle Blow" },
  SubtleBlowII      = { "Subtle Blow II" },

  -- Caster offense
  MagicAccuracy     = { "Magic Accuracy", "Mag. Acc.", "Magic Acc." },
  MAB               = { "Magic Atk. Bonus", "Mag. Atk. Bns.", "MAB" },
  MagicDamage       = { "Magic Damage", "M. Dmg." },
  MBD               = { "Magic burst damage" },
  MBD2              = { "Magic burst damage II" },
  SCBonus           = { "Skillchain Bonus" },
  FastCast          = { "Fast Cast" },

  -- Healer / enhancer
  CurePotency           = { "\"Cure\" potency", "Cure potency" }, -- many items include the quotes
  CurePotencyII         = { "Cure potency II" },
  CurePotencyReceived   = { "Cure potency received", "Potency of \"Cure\" effect received" },
  EnhancingDurationPct  = { "Enhancing magic duration", "Enhancing duration" },
  SongDurationPct       = { "Song duration" },
  SongPlus              = { "All songs" }, -- e.g., All songs +1

  -- Defense / resist
  Evasion           = { "Evasion", "Eva." },
  MEVA              = { "Magic Evasion", "Mag. Eva.", "M.Eva", "Magic Eva." },
  MDB               = { "Magic Def. Bonus", "Magic Defense Bonus", "MDB" },
  AllStatusResist   = { "Resistance to all status ailments" },
  ResistPetrify     = { "Resist Petrify" },
  ResistBind        = { "Resist Bind" },
  ResistGravity     = { "Resist Gravity" },
  ResistSilence     = { "Resist Silence" },
  ResistDark        = { "Resist Dark" },

  -- Mitigation / caps
  DT                = { "Damage taken" },                -- DT%
  PDT               = { "PDT", "Physical damage taken" },-- PDT%
  MDT               = { "MDT", "Magic damage taken" },   -- MDT%

  -- Utility / control
  Refresh           = { "Refresh" },
  ConserveMP        = { "Conserve MP" },
  MoveSpeed         = { "Movement speed" },
  TreasureHunter    = { "Treasure Hunter" },
  SIRD              = { "Spell interruption rate down" },
  Enmity            = { "Enmity" },
  AdditionalEffect  = { "Additional effect" },

  -- Skills (+X)
  ParryingSkill         = { "Parrying skill" },
  DaggerSkill           = { "Dagger skill" },
  ClubSkill             = { "Club skill" },
  GreatAxeSkill         = { "Great Axe skill" },
  MagicAccuracySkill    = { "Magic Accuracy skill" },
}

-- Which canonical keys are percentage-like by default (so you can stick a % if missing)
Aliases.percent_like = {
  HastePct=true, CritRatePct=true, MBD=true, MBD2=true, SCBonus=true,
  PDL=true, DT=true, PDT=true, MDT=true, SIRD=true,
  SongDurationPct=true, EnhancingDurationPct=true,
}

-- --- helpers ---
local function norm(s)
  if not s then return nil end
  s = s:gsub('[“”]', '"'):gsub("[’]", "'"):gsub("%s+", " "):gsub("^%s+",""):gsub("%s+$","")
  return s
end

function Aliases.build_lookup()
  local t = {}
  for canon, vars in pairs(Aliases.by_canon) do
    t[norm(canon)] = canon
    for _, v in ipairs(vars) do t[norm(v)] = canon end
  end
  return t
end

function Aliases.normalize_label(raw, lookup)
  lookup = lookup or Aliases._lookup or Aliases.build_lookup()
  Aliases._lookup = lookup
  local k = norm(raw)
  return lookup[k] or raw
end

return Aliases
