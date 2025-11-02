-- libs/autoloader-scanner.lua
-- Scans inventory/wardrobes; returns equippable items with slots, jobs, level,
-- parsed base stats, augments, and the EN description. Lua 5.1 safe.

local log = require('autoloader-logger')
local res = require('resources')
local ok_ext, extdata = pcall(require, 'extdata')

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
local function ascii_only(s) s = tostring(s or ""):gsub("[\r\n]", " "); s = s:gsub("[%z\1-\8\11\12\14-\31]", ""); return s end
local function hasbit(x, bit) if type(x)~='number' then return false end; return math.floor(x/bit) % 2 == 1 end
local function decode_slots(mask)
  local out = {}
  for i=0,15 do local b=2^i; if hasbit(mask or 0, b) then out[#out+1] = SLOT_NAMES[i] end end
  return out
end
local function join(arr, sep) sep=sep or ", "; local t={}; for _,v in ipairs(arr or {}) do t[#t+1]=tostring(v) end; return table.concat(t, sep) end

-- ---------- item helpers ----------
local function item_def(id) return res.items and res.items[id] or nil end
local function item_name(id) local it=item_def(id); return (it and (it.enl or it.en or it.english or it.name)) or ('<id '..tostring(id)..'>') end
local function item_desc_en(id)
  local d = res.item_descriptions and res.item_descriptions[id]
  local s = d and (d.en or d.english or d.enl or d.description) or ''
  return ascii_only(s)
end

local function get_augments(entry)
  if not ok_ext or not entry or not entry.extdata then return nil end
  local ok, ex = pcall(extdata.decode, entry); if not ok or type(ex)~='table' then return nil end
  local a = ex.augments
  if type(a)=='table' and #a>0 then
    local out = {}
    for _,v in ipairs(a) do if v and v~='' then out[#out+1]=v end end
    if #out>0 then return out end
  end
  return nil
end

local function is_equipment(it)
  if not it then return false end
  if (it.slots or 0) ~= 0 then return true end
  local cat = (it.category or ''):lower()
  return (cat=='armor' or cat=='weapon' or cat=='ranged' or cat=='shield' or cat=='ammunition')
end

-- ---------- parsing ----------
local function parse_ilvl(desc)
  local n = desc:match("<%s*Item%s+Level%s*:%s*(%d+)%s*>"); return tonumber(n)
end

local function parse_level_and_jobs_from_text(desc)
  if not desc or desc=='' then return nil,nil,nil end
  -- last "Lv.##" occurrence
  local last, i = nil, 1
  while true do local p = desc:find("[Ll][Vv]%s*%.?%s*%d+", i); if not p then break end; last=p; i=p+1 end
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

local function decode_jobs_from_record(it)
  if not it or it.jobs == nil then return nil, nil end
  local list = {}
  if type(it.jobs) == 'number' then
    for i,code in ipairs(JOB_ORDER) do if hasbit(it.jobs, 2^(i-1)) then list[#list+1]=code end end
  elseif type(it.jobs) == 'table' then
    for code, v in pairs(it.jobs) do if v then code = tostring(code):upper(); if JOBS[code] then list[#list+1]=code end end end
  end
  if #list==0 then return nil,nil end
  table.sort(list)
  if #list >= #JOB_ORDER then return "All Jobs", {ALL=true} end
  local set = {}; for _,c in ipairs(list) do set[c]=true end
  return table.concat(list,'/'), set
end

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
local function parse_stats(desc)
  local out = {}
  local function pull(pats) for _,p in ipairs(pats) do local v = desc:match(p); if v then return tonumber(v) end end end
  for k,p in pairs(STAT_PATTERNS) do local v = pull(p); if v~=nil then out[k]=v end end
  return out
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

-- ---------- public ----------
function scanner.find_available_equipment()
  local rows = {}
  for _, rec in ipairs(each_bag_items()) do
    local e  = rec.entry
    local it = item_def(e.id)
    if it and is_equipment(it) then
      local desc  = item_desc_en(e.id) or ''
      local slots = decode_slots(it.slots or 0)        -- ALWAYS a table
      local ilvl  = parse_ilvl(desc)
      local stats = parse_stats(desc)

      -- supplement from item record when present
      if it.damage  then stats.dmg   = stats.dmg   or it.damage end
      if it.delay   then stats.delay = stats.delay or it.delay end
      if it.defense then stats.def   = stats.def   or it.defense end

      -- prefer record jobs; fallback to text parsing
      local jobs_str, jobs_set = decode_jobs_from_record(it)
      local lvl_txt, text_jobs_tbl, text_jobs_str = parse_level_and_jobs_from_text(desc)
      local min_lv   = lvl_txt or it.level or nil
      if not jobs_str then jobs_str = text_jobs_str end
      local equip_jobs = jobs_set or text_jobs_tbl

      rows[#rows+1] = {
        bag = rec.bag, slot_index = rec.slot, id = e.id,
        name = item_name(e.id),
        equip_slots = slots,
        ilvl = ilvl, min_level = min_lv,
        equip_jobs = equip_jobs,  -- table like { WAR=true, ... } or { 'WAR','BST' } from text
        equip_line = jobs_str,    -- string "WAR/BST" or "All Jobs"
        stats = stats,
        augments = get_augments(e),
        desc_en = desc,
      }
    end
  end
  table.sort(rows, function(a,b) if a.bag==b.bag then return (a.name or '') < (b.name or '') end return a.bag < b.bag end)
  return rows
end

function scanner.dump_equipment()
  local rows = scanner.find_available_equipment()
  log.debug("DBG: %d equippable item(s) found", #rows)
  for _, r in ipairs(rows) do
    local slots_txt = (#r.equip_slots>0) and ('['..join(r.equip_slots,'/')..']') or '[EQ]'
    local meta = {}
    if r.ilvl      then meta[#meta+1] = ('iLv.%d'):format(r.ilvl) end
    if r.min_level then meta[#meta+1] = ('Lv.%d'):format(r.min_level) end
    if r.equip_line then meta[#meta+1] = r.equip_line end
    local s=r.stats or {}; local sb={}
    for _,k in ipairs({'dmg','delay','def','acc','atk','racc','ratk','macc','mab','haste','pdt','mdt','eva','meva','str','dex','vit','agi','int','mnd','chr'}) do
      if s[k]~=nil then sb[#sb+1]=(k..':'..s[k]) end
    end
    local aug = (r.augments and #r.augments>0) and (' | Augs: '..table.concat(r.augments, ', ')) or ''
    log.debug("[%s] %s x1 %s %s  %s%s",
      r.bag, r.name, slots_txt,
      (#meta>0 and table.concat(meta,' | ') or '—'),
      (#sb>0 and table.concat(sb, ', ') or 'no parsed stats'),
      aug
    )

    -- If we couldn't determine jobs, print the raw EN desc to see why.
    if not r.equip_line then
      log.debug("Desc EN => %s", r.desc_en or "<nil>")
    end
  end
end

return scanner
