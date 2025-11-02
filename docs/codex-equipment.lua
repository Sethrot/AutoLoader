-- constants_and_parser.lua
-- One file: STAT, TAGS, STAT_TAGS (USING TAG CONSTANTS), and a dynamic, constant-driven matcher.

-- =========================
-- 1) Canonical stat keys
-- =========================
local STAT = {
  -- Primary
  hp="HP", mp="MP", str="STR", dex="DEX", vit="VIT", agi="AGI", int="INT", mnd="MND", chr="CHR",

  -- Melee offense
  accuracy="Accuracy", attack="Attack", crit_rate_pct="CritRatePct",
  da="DA", ta="TA", qa="QA", wsd="WSD", pdl="PDL",

  -- Ranged offense
  ranged_accuracy="RangedAccuracy", ranged_attack="RangedAttack",
  true_shot="TrueShot", barrage="Barrage",

  -- Tempo
  haste_pct="HastePct", dual_wield_pct="DualWieldPct",
  snapshot="Snapshot", rapid_shot="RapidShot",

  -- TP / Subtle
  store_tp="StoreTP", save_tp="SaveTP", tp_bonus="TPBonus", regain="Regain",
  subtle_blow="SubtleBlow", subtle_blow_ii="SubtleBlowII",

  -- Caster offense
  magic_accuracy="MagicAccuracy", mab="MAB",
  mbd="MBD", mbd2="MBD2", sc_bonus="SCBonus", fast_cast="FastCast",

  -- Healer / Enhancer
  cure_potency="CurePotency", cure_potency_ii="CurePotencyII", cure_potency_received="CurePotencyReceived",
  enhancing_duration_pct="EnhancingDurationPct", song_duration_pct="SongDurationPct", song_plus="SongPlus",

  -- Defense / resist
  evasion="Evasion", meva="MEVA", mdb="MDB",
  all_status_resist="AllStatusResist",
  resist_petrify="ResistPetrify", resist_bind="ResistBind", resist_gravity="ResistGravity",
  resist_silence="ResistSilence", resist_dark="ResistDark",

  -- Mitigation
  dt="DT", pdt="PDT", mdt="MDT",

  -- Casting stability / control / utility
  sird="SIRD", enmity="Enmity",
  refresh="Refresh", conserve_mp="ConserveMP", movement_speed="MoveSpeed", treasure_hunter="TreasureHunter",
}

-- Percent-like keys (unit can be inferred as % even if the glyph is missing)
local PERCENT_LIKE = {
  HastePct=true, CritRatePct=true, MBD=true, MBD2=true, SCBonus=true,
  PDL=true, DT=true, PDT=true, MDT=true, SIRD=true,
  SongDurationPct=true, EnhancingDurationPct=true,
}

-- =========================
-- 2) Strong-typed Tag consts
-- =========================
-- Tag ids (keys) → in-game label strings (values)
local TAGS = {
  -- Primary
  hp="HP", mp="MP", str="STR", dex="DEX", vit="VIT", agi="AGI", int="INT", mnd="MND", chr="CHR",

  -- Melee offense
  accuracy="Accuracy",
  attack="Attack", atk_abbrev="Atk.",
  crit_rate="Critical hit rate",
  double_attack="Double Attack", triple_attack="Triple Attack", quadruple_attack="Quadruple Attack",
  weapon_skill_damage="Weapon Skill Damage",
  physical_damage_limit="Physical damage limit", pdl="PDL",

  -- Ranged offense
  ranged_accuracy="Ranged Accuracy", ranged_acc_abbrev="Ranged Acc.", r_acc="R.Acc.",
  ranged_attack="Ranged Attack",   ranged_atk_abbrev="Ranged Atk.",  r_att="R.Att.",
  true_shot="True Shot", barrage="Barrage",

  -- Tempo
  haste="Haste", dual_wield="Dual Wield", snapshot="Snapshot", rapid_shot="Rapid Shot",

  -- TP / Subtle
  store_tp="Store TP", save_tp="Save TP", tp_bonus="TP Bonus", regain="Regain",
  subtle_blow="Subtle Blow", subtle_blow_ii="Subtle Blow II",

  -- Caster offense
  magic_accuracy="Magic Accuracy", mag_acc="Mag. Acc.", magic_acc="Magic Acc.",
  magic_atk_bonus="Magic Atk. Bonus", mag_atk_bns="Mag. Atk. Bns.",
  magic_burst_damage="Magic burst damage", magic_burst_damage_ii="Magic burst damage II",
  skillchain_bonus="Skillchain Bonus", fast_cast="Fast Cast",

  -- Defense / magic defense
  evasion="Evasion", eva_abbrev="Eva.",
  magic_evasion="Magic Evasion", mag_eva="Mag. Eva.", m_eva="M.Eva", magic_eva="Magic Eva.",
  magic_def_bonus="Magic Def. Bonus", magic_defense_bonus="Magic Defense Bonus", mdb="MDB",

  -- Mitigation
  damage_taken="Damage taken", pdt="PDT", physical_damage_taken="Physical damage taken",
  mdt="MDT",    magic_damage_taken="Magic damage taken",

  -- Resistances
  all_status_resist="Resistance to all status ailments",
  resist_petrify="Resist Petrify", resist_bind="Resist Bind", resist_gravity="Resist Gravity",
  resist_silence="Resist Silence", resist_dark="Resist Dark",

  -- Utility / control
  refresh="Refresh", conserve_mp="Conserve MP", movement_speed="Movement speed",
  enmity="Enmity", spell_interrupt_down="Spell interruption rate down",
  treasure_hunter="Treasure Hunter",

  -- Healer / enhancer
  cure_potency="\"Cure\" potency", cure_potency_plain="Cure potency", cure_potency_ii="Cure potency II",
  cure_potency_received="Cure potency received", cure_effect_received="\"Cure\" effect received",
  enhancing_duration="Enhancing magic duration", song_duration="Song duration", all_songs="All songs",
}

-- ===========================================================
-- 3) Mapping STAT → { Tag constants (label strings) }
--    NOTE: these use TAGS.<id> constants (values are labels)
-- ===========================================================
local STAT_TAGS = {
  -- Primary
  [STAT.hp]  = { TAGS.hp }, [STAT.mp]  = { TAGS.mp },
  [STAT.str] = { TAGS.str },[STAT.dex] = { TAGS.dex },[STAT.vit] = { TAGS.vit },
  [STAT.agi] = { TAGS.agi },[STAT.int] = { TAGS.int },[STAT.mnd] = { TAGS.mnd },[STAT.chr] = { TAGS.chr },

  -- Melee offense
  [STAT.accuracy]      = { TAGS.accuracy },
  [STAT.attack]        = { TAGS.attack, TAGS.atk_abbrev },
  [STAT.crit_rate_pct] = { TAGS.crit_rate },
  [STAT.da]            = { TAGS.double_attack },
  [STAT.ta]            = { TAGS.triple_attack },
  [STAT.qa]            = { TAGS.quadruple_attack },
  [STAT.wsd]           = { TAGS.weapon_skill_damage },
  [STAT.pdl]           = { TAGS.physical_damage_limit, TAGS.pdl },

  -- Ranged offense
  [STAT.ranged_accuracy] = { TAGS.ranged_accuracy, TAGS.ranged_acc_abbrev, TAGS.r_acc },
  [STAT.ranged_attack]   = { TAGS.ranged_attack,   TAGS.ranged_atk_abbrev, TAGS.r_att },
  [STAT.true_shot]       = { TAGS.true_shot },
  [STAT.barrage]         = { TAGS.barrage },

  -- Tempo
  [STAT.haste_pct]      = { TAGS.haste },
  [STAT.dual_wield_pct] = { TAGS.dual_wield },
  [STAT.snapshot]       = { TAGS.snapshot },
  [STAT.rapid_shot]     = { TAGS.rapid_shot },

  -- TP / Subtle
  [STAT.store_tp]       = { TAGS.store_tp },
  [STAT.save_tp]        = { TAGS.save_tp },
  [STAT.tp_bonus]       = { TAGS.tp_bonus },
  [STAT.regain]         = { TAGS.regain },
  [STAT.subtle_blow]    = { TAGS.subtle_blow },
  [STAT.subtle_blow_ii] = { TAGS.subtle_blow_ii },

  -- Caster offense
  [STAT.magic_accuracy] = { TAGS.magic_accuracy, TAGS.mag_acc, TAGS.magic_acc },
  [STAT.mab]            = { TAGS.magic_atk_bonus, TAGS.mag_atk_bns },
  [STAT.mbd]            = { TAGS.magic_burst_damage },
  [STAT.mbd2]           = { TAGS.magic_burst_damage_ii },
  [STAT.sc_bonus]       = { TAGS.skillchain_bonus },
  [STAT.fast_cast]      = { TAGS.fast_cast },

  -- Healer / Enhancer
  [STAT.cure_potency]          = { TAGS.cure_potency, TAGS.cure_potency_plain },
  [STAT.cure_potency_ii]       = { TAGS.cure_potency_ii },
  [STAT.cure_potency_received] = { TAGS.cure_potency_received, TAGS.cure_effect_received },
  [STAT.enhancing_duration_pct]= { TAGS.enhancing_duration },
  [STAT.song_duration_pct]     = { TAGS.song_duration },
  [STAT.song_plus]             = { TAGS.all_songs },

  -- Defense / resist
  [STAT.evasion] = { TAGS.evasion, TAGS.eva_abbrev },
  [STAT.meva]    = { TAGS.magic_evasion, TAGS.mag_eva, TAGS.m_eva, TAGS.magic_eva },
  [STAT.mdb]     = { TAGS.magic_def_bonus, TAGS.magic_defense_bonus, TAGS.mdb },
  [STAT.all_status_resist] = { TAGS.all_status_resist },
  [STAT.resist_petrify]    = { TAGS.resist_petrify },
  [STAT.resist_bind]       = { TAGS.resist_bind },
  [STAT.resist_gravity]    = { TAGS.resist_gravity },
  [STAT.resist_silence]    = { TAGS.resist_silence },
  [STAT.resist_dark]       = { TAGS.resist_dark },

  -- Mitigation
  [STAT.dt]  = { TAGS.damage_taken },
  [STAT.pdt] = { TAGS.pdt, TAGS.physical_damage_taken },
  [STAT.mdt] = { TAGS.mdt, TAGS.magic_damage_taken },

  -- Utility / control
  [STAT.sird]           = { TAGS.spell_interrupt_down },
  [STAT.enmity]         = { TAGS.enmity },
  [STAT.refresh]        = { TAGS.refresh },
  [STAT.conserve_mp]    = { TAGS.conserve_mp },
  [STAT.movement_speed] = { TAGS.movement_speed },
  [STAT.treasure_hunter]= { TAGS.treasure_hunter },
}

-- ===================================================
-- 4) Helpers (build matchers and parse token values)
-- ===================================================
local function escape_lua_pattern(s) return (s:gsub("(%W)","%%%1")) end

-- Reverse: label -> tag_id (e.g., "Damage taken" -> "damage_taken")
local TAG_ID_BY_LABEL = {}
for tag_id, label in pairs(TAGS) do
  TAG_ID_BY_LABEL[label] = tag_id
  TAG_ID_BY_LABEL['"'..label..'"'] = tag_id -- accept quoted labels too
end

-- Build: label -> STAT key (from STAT_TAGS which now stores label constants)
local STAT_BY_LABEL = {}
for stat_key, label_list in pairs(STAT_TAGS) do
  for _, label in ipairs(label_list) do
    STAT_BY_LABEL[label] = stat_key
    STAT_BY_LABEL['"'..label..'"'] = stat_key
  end
end

-- Build matchers: {label, stat_key, tag_id, pattern}
local function build_matchers()
  local out = {}
  for stat_key, label_list in pairs(STAT_TAGS) do
    for _, label in ipairs(label_list) do
      local esc = escape_lua_pattern(label)
      -- Capture start/end with () to compute span; allow optional quotes, sign, %.
      local pat = '()("?%s"?)%s*([+-]?)%s*(%d+)%s*(%%?)()'
      pat = pat:format(esc)
      table.insert(out, { label=label, stat_key=stat_key, tag_id=TAG_ID_BY_LABEL[label], pattern=pat })
    end
  end
  return out
end

-- ---------- Sanitizer (skip aug/path/rank/latent/set/region/enchant and weapon-only) ----------
local function sanitize_base_text(text)
  local keep = {}
  for line in tostring(text):gmatch("[^\r\n]+") do
    local drop =
      line:match("^%s*Augments?%s*:") or
      line:match("^%s*Path%s*[A-D]%s*:") or
      line:match("^%s*Rank%s*R?%d+") or
      line:match("^%s*R:%s*%d+") or
      line:match("^%s*Latent%s*Effect%s*:") or
      line:match("^%s*Latent%s*:") or
      line:match("^%s*Set%s*:") or
      line:match("^%s*Set%s*Bonus%s*:") or
      line:match("^%s*Set%s*Effect%s*:") or
      line:match("^%s*Unity%s*Rank") or
      line:match("^%s*Enchantment%s*:") or
      line:match("^%s*Aftermath") or
      line:match("^%s*Afterglow") or
      line:match("^%s*Reives%s*:") or
      line:match("^%s*Campaign%s*:") or
      line:match("^%s*Ballista%s*:") or
      line:match("^%s*Dynamis%s*:") or
      line:match("^%s*Abyssea%s*:") or
      line:match("^%s*Odyssey%s*:") or
      line:match("^%s*Sortie%s*:") or
      line:match("^%s*Ambuscade%s*:") or
      line:match("^%s*Assault%s*:") or
      line:match("^%s*Salvage%s*:") or
      line:match("^%s*Einherjar%s*:") or
      line:match("^%s*Limbus%s*:") or
      line:match("^%s*Walk%s*of%s*Echoes%s*:") or
      line:match("^%s*Legion%s*:") or
      line:match("^%s*Besieged%s*:") or
      line:match("^%s*Voidwatch%s*:") or
      line:match("^%s*Delve%s*:") or
      line:match("^%s*Skirmish%s*:") or
      line:match("^%s*Nyzul%s*Isle%s*:") or
      line:match("^%s*Additional%s+effect%s*:") or -- weapon proc
      line:match("^%s*(DMG|Delay|DPS)%s*:%s*%d+")   -- weapon params
    if not drop then table.insert(keep, line) end
  end
  local text2 = table.concat(keep, "\n")
  -- inline gates (Set:/Latent:/region/etc.) and Main hand:
  local inline = {
    "[Ss]et%s*:?%s*[Bb]onus?%s*:%s*[^%.\n]*",
    "[Ss]et%s*:?%s*[Ee]ffect%s*:%s*[^%.\n]*",
    "[Ll]atent%s*[Ee]ffect%s*:%s*[^%.\n]*",
    "Unity%s*Rank%w*%s*:%s*[^%.\n]*",
    "Enchantment%s*:%s*[^%.\n]*",
    "Reives%s*:%s*[^%.\n]*",
    "Campaign%s*:%s*[^%.\n]*",
    "Ballista%s*:%s*[^%.\n]*",
    "Dynamis%s*:%s*[^%.\n]*",
    "Abyssea%s*:%s*[^%.\n]*",
    "Odyssey%s*:%s*[^%.\n]*",
    "Sortie%s*:%s*[^%.\n]*",
    "%f[%w]Main%s*hand%s*:%s*[^%.\n]*",
  }
  for _, p in ipairs(inline) do text2 = text2:gsub("%s+"..p, "") end
  text2 = text2:gsub("[\t ]+", " "):gsub("^%s+",""):gsub("%s+$","")
  return text2
end

local function infer_unit(stat_key, unit)
  if unit == "%" then return "%", "explicit" end
  if PERCENT_LIKE[stat_key] then return "%", "inferred" end
  return "", "none"
end

-- =======================
-- 5) Main parse function
-- =======================
local function parse_stats(desc_text)
  local text = sanitize_base_text(desc_text or "")
  local matchers = build_matchers()
  local hits = {}

  for _, m in ipairs(matchers) do
    -- Iterate all occurrences via gmatch; pattern uses () to capture span
    for s, rawlabel, sign, val, unit, e in text:gmatch(m.pattern) do
      local raw = text:sub(s, e-1)
      local unit_resolved, unit_source = infer_unit(m.stat_key, unit)
      local tag_label = rawlabel
      local tag_id = TAG_ID_BY_LABEL[tag_label] or TAG_ID_BY_LABEL[tag_label:gsub('^"', ''):gsub('"$', '')]

      table.insert(hits, {
        key = m.stat_key,            -- e.g., "DT"
        tag = tag_label,             -- exact label as matched (quotes preserved if present)
        tag_id = tag_id,             -- e.g., "damage_taken"
        value = tonumber(val),
        sign = (sign ~= "" and sign) or ((m.stat_key == STAT.dt or m.stat_key == STAT.pdt or m.stat_key == STAT.mdt) and "-" or "+"),
        unit = unit_resolved,
        unit_source = unit_source,
        raw = raw,
        span = { s-1, e-1 },         -- 0-based half-open [s,e)
      })
    end
  end

  table.sort(hits, function(a,b) return a.span[1] < b.span[1] end)
  return hits, text
end

-- Exports
return {
  STAT = STAT,
  TAGS = TAGS,
  STAT_TAGS = STAT_TAGS,    -- uses TAG constants (label strings)
  PERCENT_LIKE = PERCENT_LIKE,
  parse_stats = parse_stats,
  sanitize_base_text = sanitize_base_text,
}
