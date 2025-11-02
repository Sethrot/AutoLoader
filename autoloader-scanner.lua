-- libs/autoloader-scanner.lua
-- Scans inventory/wardrobes; returns equippable items with slots, jobs, level,
-- parsed base stats, augments, Superior (Su) level, and the EN description.
-- Lua 5.1 safe.

local log = require('autoloader-logger')
local res = require('resources')
local ok_ext, extdata = pcall(require, 'extdata')
local codex = require("autoloader-codex-equipment")

local scanner = {}

-- ---------- config ----------
local BAG_KEYS = {
  'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4',
  'wardrobe5','wardrobe6','wardrobe7','wardrobe8',
}

-- Stable slot names for bit positions 0..15
local SLOT_NAMES = {
  [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',[6]='Hands',[7]='Legs',
  [8]='Feet',[9]='Neck',[10]='Waist',[11]='Left Ear',[12]='Right Ear',[13]='Left Ring',[14]='Right Ring',[15]='Back'
}

local JOB_ORDER = { 'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG','SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN' }
local JOBS = {}; for _,j in ipairs(JOB_ORDER) do JOBS[j] = true end

-- ---------- tiny utils ----------
local function ascii_only(s)
  s = tostring(s or ""):gsub("[\r\n]", " ")
  s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
  return s
end

local function hasbit(x, bit)
  if type(x) ~= 'number' then return false end
  return math.floor(x/bit) % 2 == 1
end

local function decode_slots(mask)
  local out = {}
  for i=0,15 do
    local b = 2^i
    if hasbit(mask or 0, b) then out[#out+1] = SLOT_NAMES[i] end
  end
  return out
end

local function join(arr, sep)
  sep = sep or ", "
  local t = {}
  for _,v in ipairs(arr or {}) do t[#t+1] = tostring(v) end
  return table.concat(t, sep)
end

-- pretty printer (JSON-ish) for debug
local function _pp_val(v, d, seen, max_depth, max_str_len)
  max_depth   = max_depth   or 6
  max_str_len = max_str_len or 240
  if type(v) ~= 'table' then
    if type(v) == 'string' then
      local s = v
      if #s > max_str_len then
        s = s:sub(1, max_str_len) .. ('…(%d chars)'):format(#v)
      end
      return string.format('%q', s)
    end
    return tostring(v)
  end
  if seen[v] then return '"<cycle>"' end
  if d >= max_depth then return '"<max-depth>"' end
  seen[v] = true

  local n = #v
  local is_array = true
  local count = 0
  for k,_ in pairs(v) do
    count = count + 1
    if type(k) ~= 'number' or k < 1 or k > n or k%1 ~= 0 then
      is_array = false; break
    end
  end

  if is_array then
    local buf = {}
    for i=1,n do buf[#buf+1] = _pp_val(v[i], d+1, seen, max_depth, max_str_len) end
    return '[' .. table.concat(buf, ', ') .. ']'
  else
    local keys = {}
    for k,_ in pairs(v) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _,k in ipairs(keys) do
      local key = tostring(k)
      parts[#parts+1] = key .. ' = ' .. _pp_val(v[k], d+1, seen, max_depth, max_str_len)
    end
    return '{' .. table.concat(parts, ', ') .. '}'
  end
end

local function pretty(obj, opts)
  opts = opts or {}
  return _pp_val(obj, 0, {}, opts.max_depth, opts.max_str_len)
end

local function log_multiline(label, s, width)
  s = tostring(s or "")
  width = width or 96
  log.debug("%s (%d chars):", label, #s)
  local i = 1
  while i <= #s do
    log.debug("%s", s:sub(i, i+width-1))
    i = i + width
  end
end

-- ---------- item helpers ----------
local function item_def(id)
  return res.items and res.items[id] or nil
end

local function item_name(id)
  local it = item_def(id)
  return (it and (it.enl or it.en or it.english or it.name)) or ('<id '..tostring(id)..'>')
end

local function item_desc_en(id)
  local d = res.item_descriptions and res.item_descriptions[id]
  local s = d and (d.en or d.english or d.enl or d.description) or ''
  return ascii_only(s)
end

local function item_desc_raw(id)
  local d = res.item_descriptions and res.item_descriptions[id]
  return d and (d.en or d.english or d.enl or d.description) or ''
end

local function get_augments(entry)
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

local function is_equipment(it)
  if not it then return false end
  if (it.slots or 0) ~= 0 then return true end
  local cat = (it.category or ''):lower()
  return (cat=='armor' or cat=='weapon' or cat=='ranged' or cat=='shield' or cat=='ammunition')
end

-- Prefer resource field; fallback to parsing "SuN" in description
local function item_superior_level(it, desc)
  if it and it.superior_level then return tonumber(it.superior_level) end
  if not desc or desc == '' then return nil end
  local n = desc:match("Su(%d)")
  return n and tonumber(n) or nil
end

-- ---------- parsing ----------
local function parse_ilvl(desc)
  local n = desc:match("<%s*Item%s+Level%s*:%s*(%d+)%s*>")
  return tonumber(n)
end

-- Parse level + jobs from description line
local function parse_level_and_jobs_from_text(desc)
  if not desc or desc=='' then return nil,nil,nil end
  -- find last "Lv.##"
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

-- Patterns used by the stat regex parser
local STAT_PATTERNS = {
  dmg={"DMG%s*:%s*(%-?%d+)"}, delay={"Delay%s*:%s*(%-?%d+)"}, def={"DEF%s*:?%s*(%-?%d+)"},
  str={"STR%s*[:%+]%s*(%-?%d+)"}, dex={"DEX%s*[:%+]%s*(%-?%d+)"}, vit={"VIT%s*[:%+]%s*(%-?%d+)"},
  agi={"AGI%s*[:%+]%s*(%-?%d+)"}, int={"INT%s*[:%+]%s*(%-?%d+)"}, mnd={"MND%s*[:%+]%s*(%-?%d+)"},
  chr={"CHR%s*[:%+]%s*(%-?%d+)"}, acc={"Accuracy%s*[:%+]%s*(%-?%d+)"},
  racc={"R%.?%s*Accuracy%s*[:%+]%s*(%-?%d+)", "Rng%.?%s*Acc%.?%s*[:%+]%s*(%-?%d+)"},
  atk={"Attack%s*[:%+]%s*(%-?%d+)"}, ratk={"R%.?%s*Attack%s*[:%+]%s*(%-?%d+)"},
  macc={"Magic%s+Accuracy%s*[:%+]%s*(%-?%d+)", "M%.?Acc%.?%s*[:%+]%s*(%-?%d+)"},
  mab={"Magic%s+Atk%.?%s*Bonus%s*[:%+]%s*(%-?%d+)", "M%.?A%.?B%.?%s*[:%+]%s*(%-?%d+)"},
  haste={"Haste%s*[:%+]?%s*(%d+)%%%s*"},
  pdt={"PDT%s*[:%-%+]?%s*(%d+)%%%s*","Damage%s*taken%s*[:%-%+]?%s*(%d+)%%%s*"},
  mdt={"MDT%s*[:%-%+]?%s*(%d+)%%%s*","Magic%s*damage%s*taken%s*[:%-%+]?%s*(%d+)%%%s*"},
  eva={"Evasion%s*[:%+]?%s*(%-?%d+)"}, meva={"Magic%s*Evasion%s*[:%+]?%s*(%-?%d+)"},
}

-- returns: stats table, and (if dbg=true) a match-debug table { key = {pattern=..., value=...}, ... }
local function parse_stats(desc, dbg)
  local out, matched = {}, {}
  local function try(key, pats)
    for _,p in ipairs(pats) do
      local v = desc:match(p)
      if v ~= nil then
        local num = tonumber(v)
        out[key] = (num ~= nil) and num or v
        if dbg then matched[key] = { pattern = p, value = v } end
        return
      end
    end
  end
  for k,p in pairs(STAT_PATTERNS) do try(k, p) end
  return out, matched
end

-- ---------- jobs helpers ----------
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
          local row = res.jobs and res.jobs[k]
          code = row and (row.ens or row.en)
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

  local set = {}
  for _, c in ipairs(list) do set[c] = true end
  return table.concat(list, '/'), set
end

local function jobs_set_from_any(x)
  if not x then return nil end
  if type(x) == 'table' then
    local array_len, has_non_array = #x, false
    for k,_ in pairs(x) do
      if type(k) ~= 'number' or k < 1 or k > array_len then has_non_array = true break end
    end
    if has_non_array then
      if x.ALL then return { ALL = true } end
      local set = {}
      for k,v in pairs(x) do if v then set[tostring(k):upper()] = true end end
      return next(set) and set or nil
    else
      local set = {}
      for _,c in ipairs(x) do set[tostring(c):upper()] = true end
      return next(set) and set or nil
    end
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

local function player_jobs()
  local p = windower.ffxi.get_player() or {}
  local function code_of(id_or_str)
    if not id_or_str then return nil end
    if type(id_or_str) == 'string' then return id_or_str:upper() end
    local row = res.jobs and res.jobs[id_or_str]
    return row and (row.ens or row.en) or nil
  end
  local mj = code_of(p.main_job or p.main_job_id)
  local sj = code_of(p.sub_job  or p.sub_job_id)
  local ml = tonumber(p.main_job_level or p.main_level or p.level or 0) or 0
  local sl = tonumber(p.sub_job_level  or p.sub_level  or 0) or 0
  local su = tonumber(p.superior_level or 0) or 0
  return { main = mj, sub = sj, main_level = ml, sub_level = sl, superior_level = su }
end

local function player_can_equip(job_set, min_lv, su_req)
  if not job_set then return false end
  local pj = player_jobs()
  local required = min_lv or 1
  local su_ok = (su_req == nil) or ((pj.superior_level or 0) >= su_req)

  if job_set.ALL then
    return su_ok and (pj.main and (pj.main_level or 0) >= required) or false
  end

  local ok_main = pj.main and job_set[pj.main] and (pj.main_level or 0) >= required
  local ok_sub  = pj.sub  and job_set[pj.sub ] and (pj.sub_level  or 0) >= required
  return su_ok and (ok_main or ok_sub)
end

-- ---------- bag scanning ----------
local function each_bag_items()
  local items = windower.ffxi.get_items() or {}
  local list = {}
  for _, key in ipairs(BAG_KEYS) do
    local bag = items[key]
    if type(bag) == 'table' and type(bag.max) == 'number' then
      for slot = 1, bag.max do
        local e = bag[slot]
        if type(e) == 'table' and e.id and e.id > 0 then
          list[#list+1] = { bag = key:upper(), slot = slot, entry = e }
        end
      end
    end
  end
  return list
end

-- ---------- public: main scan ----------
function scanner.find_available_equipment()
  local rows = {}
  for _, rec in ipairs(each_bag_items()) do
    local e  = rec.entry
    local it = item_def(e.id)
    if it and is_equipment(it) then
      local desc  = item_desc_en(e.id) or ''
      local slots = decode_slots(it.slots or 0)
      local ilvl  = parse_ilvl(desc)
      local stats = parse_stats(desc)  -- normal (non-debug) path
      local su    = item_superior_level(it, desc)


          codex.get_equipment(it)

      -- supplement from item record when present
      if it.damage  then stats.dmg   = stats.dmg   or it.damage end
      if it.delay   then stats.delay = stats.delay or it.delay end
      if it.defense then stats.def   = stats.def   or it.defense end

      -- prefer record jobs; fallback to text parsing
      local jobs_str, jobs_set = decode_jobs_from_record(it)
      local lvl_txt, text_jobs_tbl, text_jobs_str = parse_level_and_jobs_from_text(desc)
      local min_lv = lvl_txt or it.level or nil

      if not jobs_set and text_jobs_tbl then
        jobs_set = jobs_set_from_any(text_jobs_tbl)
      end
      if not jobs_str then
        jobs_str = text_jobs_str or jobs_line_from_set(jobs_set)
      end

      -- list form
      local jobs_list = {}
      if jobs_set then
        if jobs_set.ALL then
          jobs_list = { 'ALL' }
        else
          for c,_ in pairs(jobs_set) do jobs_list[#jobs_list+1] = c end
          table.sort(jobs_list)
        end
      end

      local can_now = player_can_equip(jobs_set, min_lv, su)

      rows[#rows+1] = {
        bag = rec.bag, slot_index = rec.slot, id = e.id,
        name = item_name(e.id),
        equip_slots = slots,

        ilvl = ilvl, min_level = min_lv,
        superior_level = su,     -- Su N (nil if not applicable)

        jobs = jobs_list,            -- e.g. { 'RDM','BLM' } or { 'ALL' }
        jobs_line = jobs_str,        -- e.g. "RDM/BLM" or "All Jobs"
        jobs_set = jobs_set,         -- set form
        can_equip_now = can_now,     -- bool (includes Su check)

        stats = stats,
        augments = get_augments(e),
        desc_en = desc,
      }
    end
  end
  table.sort(rows, function(a,b)
    if a.bag == b.bag then return (a.name or '') < (b.name or '') end
    return a.bag < b.bag
  end)
  return rows
end

-- ---------- public: human-friendly dumps ----------
function scanner.dump_equipment()
  local rows = scanner.find_available_equipment()
  log.debug("DBG: %d equippable item(s) found", #rows)
  for _, r in ipairs(rows) do
    local slots_txt = (#r.equip_slots>0) and ('['..join(r.equip_slots,'/')..']') or '[EQ]'
    local meta = {}
    if r.ilvl          then meta[#meta+1] = ('iLv.%d'):format(r.ilvl) end
    if r.min_level     then meta[#meta+1] = ('Lv.%d'):format(r.min_level) end
    if r.superior_level then meta[#meta+1] = ('Su%d'):format(r.superior_level) end
    if r.jobs_line     then meta[#meta+1] = ('Jobs: %s'):format(r.jobs_line) end
    if r.can_equip_now ~= nil then meta[#meta+1] = (r.can_equip_now and '✓ you' or '× you') end

    local s = r.stats or {}
    local sb = {}
    for _,k in ipairs({'dmg','delay','def','acc','atk','racc','ratk','macc','mab','haste','pdt','mdt','eva','meva','str','dex','vit','agi','int','mnd','chr'}) do
      if s[k] ~= nil then sb[#sb+1] = (k..':'..s[k]) end
    end
    local aug = (r.augments and #r.augments>0) and (' | Augs: '..table.concat(r.augments, ', ')) or ''

    log.debug("[%s] %s x1 %s %s  %s%s",
      r.bag, r.name, slots_txt,
      (#meta>0 and table.concat(meta,' | ') or '—'),
      (#sb>0 and table.concat(sb, ', ') or 'no parsed stats'),
      aug
    )
  end
end

-- Pretty-dump the actual objects (first N)
function scanner.dump_equipment_objects(limit, opts)
  local rows = scanner.find_available_equipment()
  local n = math.min(limit or #rows, #rows)
  log.debug("DBG: dumping %d/%d equipment row objects", n, #rows)
  for i = 1, n do
    log.debug("#%d %s", i, pretty(rows[i], opts))
  end
  return rows
end

-- NEW: Regex debug — show the exact input string we parse and the matches
-- Usage: require('autoloader-scanner').dump_regex_debug(10, {wrap=120, show_raw=true})
function scanner.dump_regex_debug(limit, opts)
  opts = opts or {}
  local wrap = tonumber(opts.wrap or 120) or 120
  local list = each_bag_items()
  local n = math.min(limit or #list, #list)
  log.debug("DBG: regex debug for %d/%d bag items", n, #list)

  local count = 0
  for i = 1, #list do
    if count >= n then break end
    local rec = list[i]
    local e   = rec.entry
    local it  = item_def(e.id)
    if it and is_equipment(it) then
      count = count + 1
      local desc_input = item_desc_en(e.id) or ''
      local stats, matched = parse_stats(desc_input, true)
      local su = item_superior_level(it, desc_input)

      log.debug("#%d [%s] %s (id:%d)", count, rec.bag, item_name(e.id), e.id)
      if su then log.debug("  superior_level: Su%d", su) end
      if opts.show_raw then
        log_multiline("  raw_desc", item_desc_raw(e.id), wrap)
      end
      log_multiline("  regex_input", desc_input, wrap)

      if next(matched) then
        -- show in stable order by key
        local keys = {}
        for k,_ in pairs(matched) do keys[#keys+1] = k end
        table.sort(keys)
        for _,k in ipairs(keys) do
          local m = matched[k]
          log.debug("  match %-4s: %s => %s", k, m.pattern, tostring(m.value))
        end
      else
        log.debug("  match: <none>")
      end

      if next(stats) then
        log.debug("  stats: %s", pretty(stats))
      else
        log.debug("  stats: {}")
      end
    end
  end
end

return scanner
