local autoloader      = rawget(_G, 'autoloader') or error('autoloader not initialized')

local res             = require('resources')
local ok_ext, extdata = pcall(require, 'extdata')
local codex           = require('autoloader-codex')
local utils           = require("autoloader-utils")

local scanner         = {}

local function infer_unit(stat_key, unit)
  if unit == "%" then return "%", "explicit" end
  if codex.PERCENT_LIKE[stat_key] then return "%", "inferred" end
  return "", "none"
end

local function build_matchers()
  local out = {}
  for stat_key, label_list in pairs(codex.STAT_TAGS) do
    for _, label in ipairs(label_list) do
      local esc = utils.escape_lua_pattern(label)
      local pat = '()("?' .. esc .. '"?)%s*([+-]?)%s*(%d+)%s*(%%?)()'
      out[#out + 1] = { stat_key = stat_key, label = label, pattern = pat }
    end
  end
  return out
end
local _matchers = _matchers or build_matchers()


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
  text2 = text2:gsub("[\t ]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return text2
end

local function parse_stats(desc_text)
  local raw = desc_text or ""
  local text = sanitize_base_text(raw)

  local hits = {}
  for _, m in ipairs(_matchers) do
    for s, rawlabel, sign, val, unit, e in text:gmatch(m.pattern) do
      local unit_resolved, unit_source = infer_unit(m.stat_key, unit)
      hits[#hits + 1] = {
        key         = m.stat_key,
        tag         = rawlabel,
        tag_id      = codex.TAG_ID_BY_LABEL[rawlabel] or codex.TAG_ID_BY_LABEL[rawlabel:gsub('^"', ''):gsub('"$', '')],
        value       = tonumber(val),
        sign        = (sign ~= "" and sign) or
        ((m.stat_key == codex.STAT.dt or m.stat_key == codex.STAT.pdt or m.stat_key == codex.STAT.mdt) and "-" or "+"),
        unit        = unit_resolved,
        unit_source = unit_source,
        span        = { s - 1, e - 1 },
      }
    end
  end

  table.sort(hits, function(a, b) return a.span[1] < b.span[1] end)
  return hits, text
end

local function get_stat_totals(desc)
  local stats = parse_stats(desc)

  local totals = {}
  for _, h in ipairs(stats or {}) do
    local v = h.value or 0
    if h.sign == "-" then v = -v end
    totals[h.key] = (totals[h.key] or 0) + v
  end
  return totals
end

local function get_augments_from_entry(entry)
  if not ok_ext or not entry or not entry.extdata then return nil end

  local ok, ex = pcall(extdata.decode, entry)
  if not ok or type(ex) ~= 'table' then return nil end

  local a = ex.augments
  if type(a) == 'table' and #a > 0 then
    local out = {}
    for _, v in ipairs(a) do if v and v ~= '' then out[#out + 1] = v end end
    if #out > 0 then return out end
  end
  return nil
end

local function all_available_bag_items()
  local items = windower.ffxi.get_items() or {}
  local list = {}
  for _, key in ipairs(codex.BAG_KEYS) do
    local bag = items[key]
    if type(bag) == 'table' and type(bag.max) == 'number' then
      for slot = 1, bag.max do
        local e = bag[slot]
        if type(e) == 'table' and e.id and e.id > 0 then
          list[#list + 1] = { bag = key:upper(), slot = slot, entry = e }
        end
      end
    end
  end
  return list
end

local function player_can_equp(e)
  if not e or not e.category or e.category:lower() ~= "armor" then return false end

  local player = windower.ffxi.get_player()

  -- Lvl req
  if not e.level or e.level > player.main_job_level then return false end

  -- Job req
  local jobs = e.jobs and e.jobs:map(function(v, k) return res.jobs[v] and res.jobs[v].ens end)
  if not jobs or not jobs[player.main_job] then return false end

  -- Race/Gender req
  local player_mob = windower.ffxi.get_mob_by_index(player.index)
  local race = player_mob and player_mob.race
  if not e.races or not e.races[race] then return false end

  -- Su check
  if e.superior_level and e.superior_level > player.superior_level then return false end

  return true
end

function scanner.find_available_equipment()
  local rows = {}
  local bag_items = all_available_bag_items()

  for _, rec in ipairs(bag_items) do
    local item = res.items and rec.entry and res.items[rec.entry.id]
    if item and player_can_equp(item) then
      local d = res.item_descriptions and res.item_descriptions[rec.entry.id]
      local s = d and (d.en or d.english or d.enl or d.description) or ''
      local desc = utils.ascii_only(s)
      local slots = item.slots:map(function(slot) return codex.SLOT_NAMES[slot]:gsub(" ", "_"):lower() end)
      
      rows[#rows + 1] = {
        id = rec.entry.id,
        name = item.en,
        slots = slots,
        parsed_stats = get_stat_totals(desc),
        augments = get_augments_from_entry(rec.entry)
      }

    end
  end

  table.sort(rows, function(a, b)
    autoloader.logger.dump(a)
    if a.bag == b.bag then return (a.name or '') < (b.name or '') end
    return a.bag < b.bag
  end)

  autoloader.logger.debug(("Scanned %d bag entries, %d equippable items."):format(#bag_items, #rows))
  return rows
end

return scanner
