-- libs/autoloader-codex-equipment.lua
-- Resolve equipment by id or name, validate it's equippable, parse description
-- into stat hits (safe), and return an info-rich object. Lua 5.1-safe.

local res             = require('resources')
local log             = require('autoloader-logger')
local ok_ext, extdata = pcall(require, 'extdata')

local M = {}

-- =====================
-- Debug helper (safe)
-- =====================
M.DEBUG = true   -- flip this or gate off your logger to silence

-- --- debug logger shim (only prints if autoloader-logger exists) ---
local _oklog, _log = pcall(require, 'autoloader-logger')

-- -------------------------------------------------------------------


local _unpack = (table and table.unpack) or _G.unpack  -- Windower sometimes lacks one

local function dbg(fmt, ...)
  if not (M.DEBUG and log and type(log.debug) == "function") then return end
  local args = { ... }
  for i = 1, #args do if args[i] == nil then args[i] = "<nil>" end end
  if _unpack then
    pcall(log.debug, fmt, _unpack(args))
  else
    -- Fallback preformat (up to 12 args); never throw
    local okf, msg = pcall(string.format,
      fmt, args[1], args[2], args[3], args[4], args[5], args[6],
           args[7], args[8], args[9], args[10], args[11], args[12])
    if okf and type(msg) == "string" then pcall(log.debug, msg) else pcall(log.debug, fmt) end
  end
end

-- =====================
-- Job constants/utils
-- =====================
local JOB_ORDER = { 'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG',
                    'SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN' }
local JOBS = {}; for _, j in ipairs(JOB_ORDER) do JOBS[j] = true end

-- =====================
-- Tiny utils
-- =====================
local function ascii_only(s)
  s = tostring(s or ""):gsub("[\r\n]", " ")
  s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
  return s
end

local SLOT_NAMES = {
  [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',[6]='Hands',[7]='Legs',
  [8]='Feet',[9]='Neck',[10]='Waist',[11]='Left Ear',[12]='Right Ear',[13]='Left Ring',[14]='Right Ring',[15]='Back'
}

local function hasbit(x, bit) return type(x)=='number' and (math.floor(x/bit) % 2 == 1) end

local function decode_slots(mask)
  local out = {}
  for i=0,15 do local b=2^i; if hasbit(mask or 0, b) then out[#out+1] = SLOT_NAMES[i] end end
  return out
end

local function normalize_name(s)
  s = tostring(s or ''):lower()
  s = s:gsub("[%s%p]+", " "):gsub("^%s+",""):gsub("%s+$","")
  return s
end

local function join(arr, sep)
  sep = sep or ", "
  local t = {}
  for _,v in ipairs(arr or {}) do t[#t+1] = tostring(v) end
  return table.concat(t, sep)
end

local function kv_join(t)
  if type(t) ~= "table" then return tostring(t) end
  local keys = {}
  for k,_ in pairs(t) do keys[#keys+1] = tostring(k) end
  table.sort(keys)
  local parts = {}
  for _,k in ipairs(keys) do parts[#parts+1] = (k..":"..tostring(t[k])) end
  return table.concat(parts, ", ")
end

-- =====================
-- Resource helpers
-- =====================
local function item_def(id) return res.items and res.items[id] or nil end
local function item_name_from_def(it) return (it and (it.enl or it.en or it.english or it.name)) or nil end
local function item_desc_en(id)
  local d = res.item_descriptions and res.item_descriptions[id]
  local s = d and (d.en or d.english or d.enl or d.description) or ''
  return ascii_only(s)
end

-- Decide "is equipment?"
local VALID_EQUIP_CATS = {
  armor=true, weapon=true, ranged=true, shield=true, ammunition=true
}
local function is_equipment_record(it)
  if not it then return false end
  if (it.slots or 0) ~= 0 then return true end
  local cat = (it.category or ''):lower()
  return VALID_EQUIP_CATS[cat] or false
end

-- Lazy name index
local NAME_TO_ID = nil
local function build_name_index()
  local map = {}
  for id, it in pairs(res.items or {}) do
    local n1 = normalize_name(it.enl or it.en or it.english or it.name)
    if n1 ~= '' then map[n1] = id end
    local n2 = n1:gsub("%s+%f[%w]r%d+$","")
    if n2 ~= '' then map[n2] = map[n2] or id end
  end
  return map
end

local function resolve_id(ref)
  if type(ref) == 'number' then return ref end
  if type(ref) == 'string' then
    local n = tonumber(ref); if n then return n end
    NAME_TO_ID = NAME_TO_ID or build_name_index()
    return NAME_TO_ID[normalize_name(ref)]
  end
  return nil
end

-- =====================
-- Level / jobs parsing
-- =====================
local function parse_ilvl(desc)
  local n = tostring(desc or ""):match("<%s*Item%s+Level%s*:%s*(%d+)%s*>")
  return tonumber(n)
end

local function decode_jobs_from_record(it)
  if not it or it.jobs == nil then return nil, nil end
  local list = {}
  if type(it.jobs) == 'number' then
    for i, code in ipairs(JOB_ORDER) do if hasbit(it.jobs, 2^(i-1)) then list[#list+1] = code end end
  elseif type(it.jobs) == 'table' then
    for k, v in pairs(it.jobs) do
      if v then
        local code
        if type(k) == 'number' then
          local row = res.jobs and res.jobs[k]; code = row and (row.ens or row.en)
        else code = tostring(k):upper() end
        if code and JOBS[code] then list[#list+1] = code end
      end
    end
  end
  if #list == 0 then return nil, nil end
  table.sort(list)
  if #list >= #JOB_ORDER then return "All Jobs", { ALL = true } end
  local set = {}; for _, c in ipairs(list) do set[c] = true end
  return table.concat(list, '/'), set
end

local function parse_level_and_jobs_from_text(desc)
  if not desc or desc=='' then return nil,nil,nil end
  local last, i = nil, 1
  while true do
    local p = desc:find("[Ll][Vv]%s*%.?%s*%d+", i)
    if not p then break end
    last = p; i = p + 1
  end
  if not last then
    if desc:find("All%s+Jobs") then return 1, {'ALL'}, "All Jobs" end
    return nil,nil,nil
  end
  local tail = desc:sub(last)
  local lv   = tonumber(tail:match("[Ll][Vv]%s*%.?%s*(%d+)"))
  local line = tail:match("^[^\n]*") or ""
  if line:find("All%s+Jobs") then return lv or 1, {'ALL'}, "All Jobs" end

  local tokens, seen = {}, {}
  for tok in line:gmatch("([A-Z][A-Z][A-Z])") do
    if JOBS[tok] and not seen[tok] then seen[tok]=true; tokens[#tokens+1]=tok end
  end
  if #tokens==0 and desc:find("All%s+Jobs") then return lv or 1, {'ALL'}, "All Jobs" end
  return lv, (#tokens>0 and tokens or nil), (#tokens>0 and table.concat(tokens,'/') or nil)
end

local function jobs_set_from_any(x)
  if not x then return nil end
  if type(x) == 'table' then
    if x.ALL then return { ALL = true } end
    local set = {}
    local is_array = (#x > 0)
    if is_array then for _,c in ipairs(x) do set[tostring(c):upper()] = true end
    else for k,v in pairs(x) do if v then set[tostring(k):upper()] = true end end end
    return next(set) and set or nil
  end
  return nil
end

local function jobs_line_from_set(set)
  if not set then return nil end
  if set.ALL then return 'All Jobs' end
  local arr = {}
  for c,_ in pairs(set) do arr[#arr+1] = c end
  table.sort(arr)
  return #arr > 0 and table.concat(arr, '/') or nil
end

-- =====================
-- Stat constants + tags
-- =====================
local STAT = {
  hp="HP", mp="MP", str="STR", dex="DEX", vit="VIT", agi="AGI", int="INT", mnd="MND", chr="CHR",
  accuracy="Accuracy", attack="Attack", crit_rate_pct="CritRatePct", da="DA", ta="TA", qa="QA", wsd="WSD", pdl="PDL",
  ranged_accuracy="RangedAccuracy", ranged_attack="RangedAttack", true_shot="TrueShot", barrage="Barrage",
  haste_pct="HastePct", dual_wield_pct="DualWieldPct", snapshot="Snapshot", rapid_shot="RapidShot",
  store_tp="StoreTP", save_tp="SaveTP", tp_bonus="TPBonus", regain="Regain",
  subtle_blow="SubtleBlow", subtle_blow_ii="SubtleBlowII",
  magic_accuracy="MagicAccuracy", mab="MAB", mbd="MBD", mbd2="MBD2", sc_bonus="SCBonus", fast_cast="FastCast",
  cure_potency="CurePotency", cure_potency_ii="CurePotencyII", cure_potency_received="CurePotencyReceived",
  enhancing_duration_pct="EnhancingDurationPct", song_duration_pct="SongDurationPct", song_plus="SongPlus",
  evasion="Evasion", meva="MEVA", mdb="MDB",
  all_status_resist="AllStatusResist", resist_petrify="ResistPetrify", resist_bind="ResistBind",
  resist_gravity="ResistGravity", resist_silence="ResistSilence", resist_dark="ResistDark",
  dt="DT", pdt="PDT", mdt="MDT",
  sird="SIRD", enmity="Enmity", refresh="Refresh", conserve_mp="ConserveMP",
  movement_speed="MoveSpeed", treasure_hunter="TreasureHunter",
}

local PERCENT_LIKE = {
  HastePct=true, CritRatePct=true, MBD=true, MBD2=true, SCBonus=true,
  PDL=true, DT=true, PDT=true, MDT=true, SIRD=true, SongDurationPct=true, EnhancingDurationPct=true,
}

local TAGS = {
  hp="HP", mp="MP", str="STR", dex="DEX", vit="VIT", agi="AGI", int="INT", mnd="MND", chr="CHR",
  accuracy="Accuracy", attack="Attack", atk_abbrev="Atk.", crit_rate="Critical hit rate",
  double_attack="Double Attack", triple_attack="Triple Attack", quadruple_attack="Quadruple Attack",
  weapon_skill_damage="Weapon Skill Damage",
  physical_damage_limit="Physical damage limit", pdl="PDL",
  ranged_accuracy="Ranged Accuracy", ranged_acc_abbrev="Ranged Acc.", r_acc="R.Acc.",
  ranged_attack="Ranged Attack",   ranged_atk_abbrev="Ranged Atk.",  r_att="R.Att.",
  true_shot="True Shot", barrage="Barrage",
  haste="Haste", dual_wield="Dual Wield", snapshot="Snapshot", rapid_shot="Rapid Shot",
  store_tp="Store TP", save_tp="Save TP", tp_bonus="TP Bonus", regain="Regain",
  subtle_blow="Subtle Blow", subtle_blow_ii="Subtle Blow II",
  magic_accuracy="Magic Accuracy", mag_acc="Mag. Acc.", magic_acc="Magic Acc.",
  magic_atk_bonus="Magic Atk. Bonus", mag_atk_bns="Mag. Atk. Bns.",
  magic_burst_damage="Magic burst damage", magic_burst_damage_ii="Magic burst damage II",
  skillchain_bonus="Skillchain Bonus", fast_cast="Fast Cast",
  evasion="Evasion", eva_abbrev="Eva.",
  magic_evasion="Magic Evasion", mag_eva="Mag. Eva.", m_eva="M.Eva", magic_eva="Magic Eva.",
  magic_def_bonus="Magic Def. Bonus", magic_defense_bonus="Magic Defense Bonus", mdb="MDB",
  damage_taken="Damage taken", pdt="PDT", physical_damage_taken="Physical damage taken",
  mdt="MDT",    magic_damage_taken="Magic damage taken",
  all_status_resist="Resistance to all status ailments",
  resist_petrify="Resist Petrify", resist_bind="Resist Bind", resist_gravity="Resist Gravity",
  resist_silence="Resist Silence", resist_dark="Resist Dark",
  refresh="Refresh", conserve_mp="Conserve MP", movement_speed="Movement speed",
  enmity="Enmity", spell_interrupt_down="Spell interruption rate down", treasure_hunter="Treasure Hunter",
  cure_potency="\"Cure\" potency", cure_potency_plain="Cure potency", cure_potency_ii="Cure potency II",
  cure_potency_received="Cure potency received", cure_effect_received="\"Cure\" effect received",
  enhancing_duration="Enhancing magic duration", song_duration="Song duration", all_songs="All songs",
}

local STAT_TAGS = {
  [STAT.hp]  = { TAGS.hp }, [STAT.mp]  = { TAGS.mp },
  [STAT.str] = { TAGS.str },[STAT.dex] = { TAGS.dex },[STAT.vit] = { TAGS.vit },
  [STAT.agi] = { TAGS.agi },[STAT.int] = { TAGS.int },[STAT.mnd] = { TAGS.mnd },[STAT.chr] = { TAGS.chr },
  [STAT.accuracy]      = { TAGS.accuracy },
  [STAT.attack]        = { TAGS.attack, TAGS.atk_abbrev },
  [STAT.crit_rate_pct] = { TAGS.crit_rate },
  [STAT.da]            = { TAGS.double_attack },
  [STAT.ta]            = { TAGS.triple_attack },
  [STAT.qa]            = { TAGS.quadruple_attack },
  [STAT.wsd]           = { TAGS.weapon_skill_damage },
  [STAT.pdl]           = { TAGS.physical_damage_limit, TAGS.pdl },
  [STAT.ranged_accuracy] = { TAGS.ranged_accuracy, TAGS.ranged_acc_abbrev, TAGS.r_acc },
  [STAT.ranged_attack]   = { TAGS.ranged_attack,   TAGS.ranged_atk_abbrev, TAGS.r_att },
  [STAT.true_shot]       = { TAGS.true_shot },
  [STAT.barrage]         = { TAGS.barrage },
  [STAT.haste_pct]      = { TAGS.haste },
  [STAT.dual_wield_pct] = { TAGS.dual_wield },
  [STAT.snapshot]       = { TAGS.snapshot },
  [STAT.rapid_shot]     = { TAGS.rapid_shot },
  [STAT.store_tp]       = { TAGS.store_tp },
  [STAT.save_tp]        = { TAGS.save_tp },
  [STAT.tp_bonus]       = { TAGS.tp_bonus },
  [STAT.regain]         = { TAGS.regain },
  [STAT.subtle_blow]    = { TAGS.subtle_blow },
  [STAT.subtle_blow_ii] = { TAGS.subtle_blow_ii },
  [STAT.magic_accuracy] = { TAGS.magic_accuracy, TAGS.mag_acc, TAGS.magic_acc },
  [STAT.mab]            = { TAGS.magic_atk_bonus, TAGS.mag_atk_bns },
  [STAT.mbd]            = { TAGS.magic_burst_damage },
  [STAT.mbd2]           = { TAGS.magic_burst_damage_ii },
  [STAT.sc_bonus]       = { TAGS.skillchain_bonus },
  [STAT.fast_cast]      = { TAGS.fast_cast },
  [STAT.cure_potency]          = { TAGS.cure_potency, TAGS.cure_potency_plain },
  [STAT.cure_potency_ii]       = { TAGS.cure_potency_ii },
  [STAT.cure_potency_received] = { TAGS.cure_potency_received, TAGS.cure_effect_received },
  [STAT.enhancing_duration_pct]= { TAGS.enhancing_duration },
  [STAT.song_duration_pct]     = { TAGS.song_duration },
  [STAT.song_plus]             = { TAGS.all_songs },
  [STAT.evasion] = { TAGS.evasion, TAGS.eva_abbrev },
  [STAT.meva]    = { TAGS.magic_evasion, TAGS.mag_eva, TAGS.m_eva, TAGS.magic_eva },
  [STAT.mdb]     = { TAGS.magic_def_bonus, TAGS.magic_defense_bonus, TAGS.mdb },
  [STAT.all_status_resist] = { TAGS.all_status_resist },
  [STAT.resist_petrify]    = { TAGS.resist_petrify },
  [STAT.resist_bind]       = { TAGS.resist_bind },
  [STAT.resist_gravity]    = { TAGS.resist_gravity },
  [STAT.resist_silence]    = { TAGS.resist_silence },
  [STAT.resist_dark]       = { TAGS.resist_dark },
  [STAT.dt]  = { TAGS.damage_taken },
  [STAT.pdt] = { TAGS.pdt, TAGS.physical_damage_taken },
  [STAT.mdt] = { TAGS.mdt, TAGS.magic_damage_taken },
  [STAT.sird]           = { TAGS.spell_interrupt_down },
  [STAT.enmity]         = { TAGS.enmity },
  [STAT.refresh]        = { TAGS.refresh },
  [STAT.conserve_mp]    = { TAGS.conserve_mp },
  [STAT.movement_speed] = { TAGS.movement_speed },
  [STAT.treasure_hunter]= { TAGS.treasure_hunter },
}

-- =====================
-- Tag maps + matchers
-- =====================
local TAG_ID_BY_LABEL = {}
for id, label in pairs(TAGS) do
  if type(label) == "string" and label ~= "" then
    TAG_ID_BY_LABEL[label] = id
    TAG_ID_BY_LABEL['"'..label..'"'] = id
  else
    dbg("[codex] TAGS[%s] is nil/empty; skipping", tostring(id))
  end
end

-- Build once; avoid string.format so % is safe.
local MATCHERS = nil
local function escape_lua_pattern(s) return (s:gsub("(%W)","%%%1")) end
local function build_matchers()
  local out = {}
  for stat_key, label_list in pairs(STAT_TAGS) do
    if type(label_list) == "table" then
      for _, label in ipairs(label_list) do
        if type(label) == "string" and label ~= "" then
          local esc = escape_lua_pattern(label)
          local pat = '()("?' .. esc .. '"?)%s*([+-]?)%s*(%d+)%s*(%%?)()'
          out[#out+1] = { stat_key=stat_key, label=label, tag_id=TAG_ID_BY_LABEL[label], pattern=pat }
        else
          dbg("[codex] Nil/empty label under %s; skipping", tostring(stat_key))
        end
      end
    else
      dbg("[codex] STAT_TAGS[%s] is not a list; skipping", tostring(stat_key))
    end
  end
  dbg("[codex] built %d stat matchers", #out)
  return out
end
local function get_matchers()
  if not MATCHERS then MATCHERS = build_matchers() end
  return MATCHERS
end

-- =====================
-- Sanitizer + parser
-- =====================
local function sanitize_base_text(text)
  text = tostring(text or "")
  local keep = {}
  for line in text:gmatch("[^\r\n]+") do
    local drop =
      line:match("^%s*Augments?%s*:") or
      line:match("^%s*Path%s*:") or
      line:match("^%s*Rank%s*:") or
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
      line:match("^%s*Additional%s+effect%s*:") or
      line:match("^%s*(DMG|Delay|DPS)%s*:%s*%d+")
    if not drop then table.insert(keep, line) end
  end
  local text2 = table.concat(keep, "\n")
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

local function parse_stats(desc_text)
  local raw = desc_text or ""
  dbg("[codex] desc raw len=%d", #raw)
  local text = sanitize_base_text(raw)
  dbg("[codex] desc sanitized len=%d", #text)

  local hits = {}
  local matchers = get_matchers()
  dbg("[codex] scanning with %d matchers", #matchers)

  for _, m in ipairs(matchers) do
    for s, rawlabel, sign, val, unit, e in text:gmatch(m.pattern) do
      local unit_resolved, unit_source = infer_unit(m.stat_key, unit)
      hits[#hits+1] = {
        key = m.stat_key, tag = rawlabel, tag_id = TAG_ID_BY_LABEL[rawlabel] or TAG_ID_BY_LABEL[rawlabel:gsub('^"', ''):gsub('"$', '')],
        value = tonumber(val), sign = (sign ~= "" and sign) or ((m.stat_key == STAT.dt or m.stat_key == STAT.pdt or m.stat_key == STAT.mdt) and "-" or "+"),
        unit = unit_resolved, unit_source = unit_source,
        raw = text:sub(s, e-1), span = { s-1, e-1 },
      }
    end
  end

  table.sort(hits, function(a,b) return a.span[1] < b.span[1] end)
  dbg("[codex] hits=%d", #hits)
  return hits, text
end

-- =====================
-- Folding + record stats
-- =====================
local function fold_hit_totals(hits)
  local totals = {}
  for _,h in ipairs(hits or {}) do
    local v = h.value or 0
    if h.sign == "-" then v = -v end
    totals[h.key] = (totals[h.key] or 0) + v
  end
  return totals
end

local function record_stats_of(it)
  local out = {}
  if it and it.damage  then out.dmg   = it.damage end
  if it and it.delay   then out.delay = it.delay end
  if it and it.defense then out.def   = it.defense end
  return out
end

local function get_augments_from_entry(entry)
  if not ok_ext or not entry or not entry.extdata then return nil end
  local ok, ex = pcall(extdata.decode, entry)
  if not ok or type(ex) ~= 'table' then return nil end
  local a = ex.augments
  if type(a) == 'table' and #a > 0 then
    local out = {}
    for _,v in ipairs(a) do if v and v ~= '' then out[#out+1] = v end end
    if #out > 0 then return out end
  end
  return nil
end

-- =====================
-- Public API
-- =====================
local function build_common(it, desc_raw)
  local slots_mask = (it and it.slots) or 0
  local equip_slots = decode_slots(slots_mask)
  dbg("[codex] mask=%s (dec=%s), slots=[%s]",
      string.format("0x%04X", tonumber(slots_mask or 0) or 0), tostring(slots_mask or 0), join(equip_slots))

  local record_stats = record_stats_of(it)
  dbg("[codex] record_stats={%s}", kv_join(record_stats))

  local ilvl = parse_ilvl(desc_raw)
  local lvl_txt, text_jobs_tbl, text_jobs_str = parse_level_and_jobs_from_text(desc_raw)
  local jobs_str_rec, jobs_set_rec = decode_jobs_from_record(it)
  local min_level = lvl_txt or (it and it.level) or nil

  dbg("[codex] jobs(record)=%s; jobs(text)=%s; minLv=%s",
      tostring(jobs_str_rec or "—"), tostring(text_jobs_str or "—"), tostring(min_level or "—"))

  local jobs_set = jobs_set_rec
  if not jobs_set and text_jobs_tbl then jobs_set = jobs_set_from_any(text_jobs_tbl) end
  local jobs_line = jobs_str_rec or text_jobs_str or jobs_line_from_set(jobs_set)

  dbg("[codex] jobs_line=%s; jobs_set={%s}",
      tostring(jobs_line or "—"), kv_join(jobs_set or {}))

  local jobs_list = {}
  if jobs_set then
    if jobs_set.ALL then jobs_list = { 'ALL' }
    else for c,_ in pairs(jobs_set) do jobs_list[#jobs_list+1] = c end; table.sort(jobs_list) end
  end

  return {
    slots_mask   = slots_mask,
    equip_slots  = equip_slots,
    ilvl         = ilvl,
    min_level    = min_level,
    jobs_list    = jobs_list,
    jobs_line    = jobs_line,
    jobs_set     = jobs_set,
    record_stats = record_stats,
  }
end

--- Resolve item by id/name, ensure it's equipment, parse, and return info.
-- @param ref number|string (id or name)
-- @param opts table|nil { entry=windower_item_entry, desc=override_desc }
-- @return info_table | nil, err_table|nil
function M.get_equipment(ref, opts)
  opts = opts or {}

  local id = resolve_id(ref)
  if not id then
    dbg("[codex] resolve_id failed for ref=%s", tostring(ref))
    return nil, { code="not_found", ref=tostring(ref or "<nil>") }
  end

  local it = item_def(id)
  if not it then
    dbg("[codex] res.items[%s] not found", tostring(id))
    return nil, { code="not_found", id=id }
  end

  local cat = tostring(it.category or "")
  local mask = tonumber(it.slots or 0) or 0
  dbg("[codex] item %s (id=%s): category=%s, slots_mask=%s",
      item_name_from_def(it) or "<unnamed>", tostring(id),
      cat, string.format("0x%04X", mask))

  if not is_equipment_record(it) then
    dbg("[codex] not_equipment -> category=%s slots_mask=%s", cat, string.format("0x%04X", mask))
    return nil, { code="not_equipment", id=id, name=item_name_from_def(it) or ("<id "..id..">"), category=it.category, slots=(it.slots or 0) }
  end

  local name = item_name_from_def(it) or ('<id '..id..'>')
  local desc_en = opts.desc or item_desc_en(id) or ""
  local preview = (desc_en:gsub("\r",""))
  if #preview > 160 then preview = preview:sub(1,160)..'…' end
  dbg("[codex] parsing item: %s (id=%s) | desc: %s", name or "<?>", tostring(id or "<nil>"), (#preview>0 and preview) or "<EMPTY>")

  local base = build_common(it, desc_en)
  local hits, desc_base = parse_stats(desc_en)
  local totals = fold_hit_totals(hits)
  dbg("[codex] totals={%s}", kv_join(totals))

  local info = {
    id = id, name = name,
    category = it.category, skill = it.skill,
    slots_mask   = base.slots_mask,
    equip_slots  = base.equip_slots,
    ilvl         = base.ilvl,
    min_level    = base.min_level,
    jobs_list    = base.jobs_list,
    jobs_line    = base.jobs_line,
    jobs_set     = base.jobs_set,
    record_stats = base.record_stats,         -- dmg/delay/def from record
    stats        = { totals = totals, hits = hits }, -- parsed totals/hits (may be empty)
    desc_en      = desc_en,
    desc_base    = desc_base,
    augments     = opts.entry and get_augments_from_entry(opts.entry) or nil,
  }
  return info, nil
end

-- Convenience wrappers
function M.by_id(id, opts)   return M.get_equipment(id, opts) end
function M.by_name(name, o)  return M.get_equipment(name, o)  end

-- Exports
M.is_equipment = is_equipment_record
M.STAT = STAT
M.TAGS = TAGS
M.STAT_TAGS = STAT_TAGS
M.PERCENT_LIKE = PERCENT_LIKE
M.sanitize_base_text = sanitize_base_text
M.parse_stats = parse_stats
M.jobs_line_from_set = jobs_line_from_set
M.jobs_set_from_any = jobs_set_from_any
M.JOB_ORDER = JOB_ORDER

return M
