-- libs/autoloader-scanner.lua
-- Scans inventory/wardrobes; returns equippable items and attaches codex info.
-- No regex or description parsing here—only uses resource fields.
-- Lua 5.1 safe.

local autoloader = rawget(_G, 'autoloader') or error('autoloader not initialized')

local res     = require('resources')
local ok_ext, extdata = pcall(require, 'extdata')
local codex   = require('autoloader-codex-equipment')

local scanner = {}

-- =====================
-- Debug (per-file)
-- =====================
local SCAN_DEBUG = false               -- flip per-file
local SCAN_TAG   = "[AL:scanner]"
local _unpack    = (table and table.unpack) or _G.unpack

local function _fmt(fmt, ...)
  if select('#', ...) == 0 then return tostring(fmt) end
  local ok, out = pcall(string.format, tostring(fmt), ...)
  return ok and out or tostring(fmt)
end

local function dbg(fmt, ...)
  if not SCAN_DEBUG then return end
  local msg = _fmt(fmt, ...)
  if log and type(autoloader.log.debug) == "function" then
    if _unpack then
      pcall(autoloader.log.debug, "%s %s", SCAN_TAG, msg)
    else
      pcall(autoloader.log.debug, SCAN_TAG .. " " .. msg)
    end
  elseif windower and windower.add_to_chat then
    windower.add_to_chat(123, SCAN_TAG .. " " .. msg)
  else
    print(SCAN_TAG .. " " .. msg)
  end
end

local function pretty(obj)
  local function pv(v, d, seen)
    d = d or 0
    seen = seen or {}
    if type(v) ~= "table" then
      if type(v) == "string" then
        local s = v
        if #s > 240 then s = s:sub(1,240) .. ("…(%d chars)"):format(#v) end
        return string.format("%q", s)
      end
      return tostring(v)
    end
    if seen[v] or d >= 6 then return '""' end
    seen[v] = true
    local n, is_array = #v, true
    for k,_ in pairs(v) do if type(k) ~= "number" or k < 1 or k > n or k%1~=0 then is_array=false break end end
    if is_array then
      local t = {}
      for i=1,n do t[#t+1] = pv(v[i], d+1, seen) end
      return "["..table.concat(t,", ").."]"
    else
      local keys = {}
      for k,_ in pairs(v) do keys[#keys+1] = k end
      table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
      local t = {}
      for _,k in ipairs(keys) do t[#t+1] = tostring(k).."="..pv(v[k], d+1, seen) end
      return "{ "..table.concat(t,", ").." }"
    end
  end
  return pv(obj)
end

-- ---------- config ----------
local BAG_KEYS = {
  'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4',
  'wardrobe5','wardrobe6','wardrobe7','wardrobe8',
}

-- stable slot names for bit positions 0..15
local SLOT_NAMES = {
  [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',[6]='Hands',[7]='Legs',
  [8]='Feet',[9]='Neck',[10]='Waist',[11]='Left Ear',[12]='Right Ear',[13]='Left Ring',[14]='Right Ring',[15]='Back'
}

local JOB_ORDER = { 'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG','SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN' }
local JOBS = {}; for _,j in ipairs(JOB_ORDER) do JOBS[j] = true end

-- ---------- utils ----------
local function hasbit(x, bit) return type(x)=='number' and (math.floor(x/bit) % 2 == 1) end

local function decode_slots(mask)
  local out = {}
  for i=0,15 do local b=2^i; if hasbit(mask or 0, b) then out[#out+1] = SLOT_NAMES[i] end end
  return out
end

local function item_def(id)  return res.items and res.items[id] or nil end
local function item_name(id)
  local it = item_def(id)
  return (it and (it.enl or it.en or it.english or it.name)) or ('')
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

local function jobs_line_from_set(set)
  if not set then return nil end
  if set.ALL then return 'All Jobs' end
  local arr = {}; for c,_ in pairs(set) do arr[#arr+1] = c end
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
  local bag_items = each_bag_items()

  for _, rec in ipairs(bag_items) do
    local e  = rec.entry
    local it = item_def(e.id)
    if it then
      -- Ask codex if it's equipment and for parsed stats (scanner does not parse)
      local info = codex.get_equipment(e.id, { entry = e })

      if info then
        local jobs_str, jobs_set = decode_jobs_from_record(it)
        local min_lv  = it.level or nil
        local su_req  = it.superior_level or nil
        local can_now = player_can_equip(jobs_set, min_lv, su_req)

        rows[#rows+1] = {
          bag            = rec.bag,
          slot_index     = rec.slot,
          id             = e.id,
          name           = item_name(e.id),
          equipment      = it,               -- resources item row
          jobs_line      = jobs_str or jobs_line_from_set(jobs_set),
          jobs_set       = jobs_set,
          min_level      = min_lv,
          superior_level = su_req,
          equip_slots    = (it.slots and decode_slots(it.slots)) or {},
          augments       = get_augments(e),
          can_equip_now  = can_now,
          codex          = info,             -- { equipment = it, stats = {...} }
        }
      end
      -- if info == nil => not equipment; we skip silently
    end
  end

  table.sort(rows, function(a,b)
    if a.bag == b.bag then return (a.name or '') < (b.name or '') end
    return a.bag < b.bag
  end)

  dbg("scanned %d bag entries, %d equippable rows", #bag_items, #rows)
  return rows
end

-- pretty dumper (objects)
function scanner.dump_equipment_objects(limit)
  local rows = scanner.find_available_equipment()
  local n = math.min(limit or #rows, #rows)
  dbg("dumping %d/%d rows", n, #rows)
  for i = 1, n do
    dbg("#%d %s", i, pretty(rows[i]))
  end
  return rows
end

return scanner
