-- libs/autoloader-codex-equipment.lua
-- Resolve equipment by id or name. If not equipment -> return nil.
-- Else return:
--   { equipment = <res.items[id]>,
--     stats = { ...data-rich parse output... } }

local res             = require('resources')
local log             = require('autoloader-logger')
local ok_ext, extdata = pcall(require, 'extdata')

local M = {}

-- Tag prefix for module logs
local TAG = "[AL:codex]"
local function dbg(fmt, ...)   log.debug(TAG .. " " .. fmt, ...) end
local function info(fmt, ...)  log.info (TAG .. " " .. fmt, ...) end
local function warn(fmt, ...)  log.warn (TAG .. " " .. fmt, ...) end

-- =====================
-- Constants + helpers
-- =====================
local VALID_EQUIP_CATS = { armor=true, weapon=true, ranged=true, shield=true, ammunition=true }

local JOB_ORDER = { 'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG','SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN' }
local JOBS = {}; for _, j in ipairs(JOB_ORDER) do JOBS[j] = true end

local SLOT_NAMES = {
  [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',[6]='Hands',[7]='Legs',
  [8]='Feet',[9]='Neck',[10]='Waist',[11]='Left Ear',[12]='Right Ear',[13]='Left Ring',[14]='Right Ring',[15]='Back'
}

local function ascii_only(s)
  s = tostring(s or ""):gsub("[\r\n]", " ")
  s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
  return s
end

local function hasbit(x, bit) return type(x)=='number' and (math.floor(x/bit) % 2 == 1) end

local function decode_slots(mask)
  local out = {}
  for i=0,15 do local b=2^i; if hasbit(mask or 0, b) then out[#out+1] = SLOT_NAMES[i] end end
  return out
end

local function item_def(id) return res.items and res.items[id] or nil end

local function item_desc_en(id)
  local d = res.item_descriptions and res.item_descriptions[id]
  local s = d and (d.en or d.english or d.enl or d.description) or ''
  return ascii_only(s)
end

local function is_equipment_record(it)
  if not it then return false end
  if (it.slots or 0) ~= 0 then return true end
  local cat = (it.category or ''):lower()
  return VALID_EQUIP_CATS[cat] or false
end

-- Optional name->id resolve
local function normalize_name(s)
  s = tostring(s or ''):lower()
  s = s:gsub("[%s%p]+", " "):gsub("^%s+",""):gsub("%s+$","")
  return s
end
local NAME_TO_ID
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
-- Parsing (regex machinery)
-- =====================
local STAT = {
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

local PERCENT_LIKE = {
  HastePct=true, DT=true, PDT=true, MDT=true, MBD=true, MBD2=true, SCBonus=true,
}

local TAGS = {
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

local STAT_TAGS = {
  [STAT.hp] = { TAGS.hp }, [STAT.mp] = { TAGS.mp },
  [STAT.str] = { TAGS.str }, [STAT.dex] = { TAGS.dex }, [STAT.vit] = { TAGS.vit },
  [STAT.agi] = { TAGS.agi }, [STAT.int] = { TAGS.int }, [STAT.mnd] = { TAGS.mnd }, [STAT.chr] = { TAGS.chr },

  [STAT.accuracy] = { TAGS.accuracy, TAGS.acc_abbrev },
  [STAT.attack]   = { TAGS.attack,   TAGS.atk_abbrev },

  [STAT.ranged_accuracy] = { TAGS.ranged_accuracy, TAGS.ranged_acc_abbrev or TAGS.r_acc },
  [STAT.ranged_attack]   = { TAGS.ranged_attack,   TAGS.ranged_atk_abbrev or TAGS.r_att },

  [STAT.macc] = { TAGS.magic_accuracy, TAGS.mag_acc, TAGS.magic_acc },
  [STAT.mab]  = { TAGS.magic_atk_bonus, TAGS.mag_atk_bns },

  [STAT.haste_pct] = { TAGS.haste },

  [STAT.dt]  = { TAGS.damage_taken }, [STAT.pdt] = { TAGS.pdt }, [STAT.mdt] = { TAGS.mdt },

  [STAT.eva]  = { TAGS.evasion },
  [STAT.meva] = { TAGS.magic_evasion, TAGS.mag_eva, TAGS.m_eva },

  [STAT.store_tp] = { TAGS.store_tp }, [STAT.save_tp] = { TAGS.save_tp }, [STAT.tp_bonus] = { TAGS.tp_bonus },

  [STAT.da] = { TAGS.double_attack }, [STAT.ta] = { TAGS.triple_attack }, [STAT.qa] = { TAGS.quadruple_attack },

  [STAT.fast_cast] = { TAGS.fast_cast },

  [STAT.mbd] = { TAGS.magic_burst_damage }, [STAT.mbd2] = { TAGS.magic_burst_damage_ii },
  [STAT.sc_bonus] = { TAGS.skillchain_bonus },

  [STAT.refresh] = { TAGS.refresh },

  [STAT.subtle_blow]    = { TAGS.subtle_blow },
  [STAT.subtle_blow_ii] = { TAGS.subtle_blow_ii },
}

local TAG_ID_BY_LABEL = {}
for _, lbl in pairs(TAGS) do
  if type(lbl) == "string" and lbl ~= "" then
    TAG_ID_BY_LABEL[lbl] = lbl
    TAG_ID_BY_LABEL['"'..lbl..'"'] = lbl
  end
end

local function escape_lua_pattern(s) return (s:gsub("(%W)","%%%1")) end

local MATCHERS = nil
local function build_matchers()
  local out = {}
  for stat_key, label_list in pairs(STAT_TAGS) do
    for _, label in ipairs(label_list) do
      local esc = escape_lua_pattern(label)
      local pat = '()("?' .. esc .. '"?)%s*([+-]?)%s*(%d+)%s*(%%?)()'
      out[#out+1] = { stat_key=stat_key, label=label, pattern=pat }
    end
  end
  dbg("built %d stat matchers", #out)
  return out
end

local function get_matchers()
  if not MATCHERS then MATCHERS = build_matchers() end
  return MATCHERS
end

-- sanitizer
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
      line:match("^%s*Set%s*Bonus%s*:") or
      line:match("^%s*Unity%s*Rank") or
      line:match("^%s*Enchantment%s*:") or
      line:match("^%s*Aftermath")
    if not drop then table.insert(keep, line) end
  end
  local text2 = table.concat(keep, "\n")
  text2 = text2:gsub("[\t ]+", " "):gsub("^%s+",""):gsub("%s+$","")
  return text2
end

local function infer_unit(stat_key, unit)
  if unit == "%" then return "%", "explicit" end
  if PERCENT_LIKE[stat_key] then return "%", "inferred" end
  return "", "none"
end

local function parse_ilvl(desc)
  local n = tostring(desc or ""):match("<%s*Item%s+Level%s*:%s*(%d+)%s*>")
  return tonumber(n)
end

local function _log_hits(hits, text)
  dbg("extracted %d hits:", hits and #hits or 0)
  for i, h in ipairs(hits or {}) do
    local s0 = (h.span and h.span[1] or -1) + 1
    local e0 = (h.span and h.span[2] or 0)
    local rawseg = (text and text:sub(s0, e0)) or ""
    dbg("  #%d key=%-14s val=%s%s sign=%s unit=%s (%s) tag=%s span=[%d,%d] raw=%q",
        i,
        tostring(h.key or "?"),
        tostring(h.value or "?"),
        tostring(h.unit or ""),
        tostring(h.sign or "+"),
        tostring(h.unit or ""),
        tostring(h.unit_source or "none"),
        tostring(h.tag or ""),
        s0-1, e0,
        rawseg)
  end
end

local function parse_stats(desc_text)
  local raw = desc_text or ""
  dbg("desc raw len=%d", #raw)
  local text = sanitize_base_text(raw)
  dbg("regex input (sanitized, len=%d): %s", #text, text)

  local hits = {}
  for _, m in ipairs(get_matchers()) do
    for s, rawlabel, sign, val, unit, e in text:gmatch(m.pattern) do
      local unit_resolved, unit_source = infer_unit(m.stat_key, unit)
      hits[#hits+1] = {
        key   = m.stat_key,
        tag   = rawlabel,
        tag_id= TAG_ID_BY_LABEL[rawlabel] or TAG_ID_BY_LABEL[rawlabel:gsub('^"', ''):gsub('"$', '')],
        value = tonumber(val),
        sign  = (sign ~= "" and sign) or ((m.stat_key == STAT.dt or m.stat_key == STAT.pdt or m.stat_key == STAT.mdt) and "-" or "+"),
        unit  = unit_resolved,
        unit_source = unit_source,
        span  = { s-1, e-1 },
      }
    end
  end

  table.sort(hits, function(a,b) return a.span[1] < b.span[1] end)
  _log_hits(hits, text)
  return hits, text
end

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
  if it and it.damage  then out.dmg = it.damage  end
  if it and it.delay   then out.delay = it.delay end
  if it and it.defense then out.def   = it.defense end
  return out
end

local function decode_jobs_from_record(it)
  if not it or it.jobs == nil then return nil, nil end
  local list = {}
  if type(it.jobs) == 'number' then
    for i, code in ipairs(JOB_ORDER) do
      if hasbit(it.jobs, 2^(i-1)) then list[#list+1] = code end
    end
  elseif type(it.jobs) == 'table' then
    for k, v in pairs(it.jobs) do
      if v then
        local code
        if type(k) == 'number' then
          local row = res.jobs and res.jobs[k]; code = row and (row.ens or row.en)
        else
          code = tostring(k):upper()
        end
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

--- Return nil if not equipment; else { equipment = it, stats = {...} }.
-- @param ref  number|string  (id or name)
-- @param opts table|nil      { entry = windower item entry (for augments) }
function M.get_equipment(ref, opts)
  opts = opts or {}
  local id = resolve_id(ref)
  if not id then
    dbg("resolve_id failed for ref=%s", tostring(ref))
    return nil
  end
  local it = item_def(id)
  if not is_equipment_record(it) then
    dbg("id=%s is not equipment (category=%s, slots=%s)", tostring(id), tostring(it and it.category or "nil"), tostring(it and it.slots or "nil"))
    return nil
  end

  local desc_en   = item_desc_en(id) or ""
  local hits, desc_base = parse_stats(desc_en)
  local totals    = fold_hit_totals(hits)

  local jobs_line, jobs_set = decode_jobs_from_record(it)
  local equip_slots = decode_slots(it.slots or 0)
  local augments    = opts.entry and get_augments_from_entry(opts.entry) or nil

  local stats = {
    id            = id,
    name          = it.enl or it.en or it.english or it.name,
    category      = it.category,
    skill         = it.skill,
    slots_mask    = it.slots or 0,
    equip_slots   = equip_slots,
    ilvl          = parse_ilvl(desc_en),
    min_level     = it.level or nil,
    superior_level= it.superior_level or nil,

    jobs_line     = jobs_line,
    jobs_set      = jobs_set,
    jobs_list     = (function(set)
      if not set then return nil end
      if set.ALL then return { 'ALL' } end
      local arr = {}; for c,_ in pairs(set) do arr[#arr+1] = c end
      table.sort(arr); return arr
    end)(jobs_set),

    record_stats  = record_stats_of(it),
    totals        = totals,
    hits          = hits,
    desc_en       = desc_en,
    desc_base     = desc_base,
    augments      = augments,
  }

  return { equipment = it, stats = stats }
end

M.is_equipment = is_equipment_record
M.JOB_ORDER    = JOB_ORDER
M.STAT         = STAT
M.TAGS         = TAGS

return M
