-- libs/autoloader-scanner.lua
-- Scanner: reads items from bags, normalizes/cleans descriptions, parses into
-- known stats and "enhancements" (unknown or non-numeric bonuses).
-- Lua 5.1-safe (no goto/labels).

local autoloader      = rawget(_G, 'autoloader') or error('autoloader not initialized')
local res             = require('resources')
local ok_ext, extdata = pcall(require, 'extdata')
local codex           = require('autoloader-codex')
local utils           = require('autoloader-utils')

local scanner         = {}

-- --- logging helpers -------------------------------------------------------

local function log_debug(fmt, ...)
  if autoloader and autoloader.logger and autoloader.logger.debug then
    if select('#', ...) > 0 then
      autoloader.logger.debug((fmt or ""):format(...))
    else
      autoloader.logger.debug(tostring(fmt or ""))
    end
  end
end

local function log_dump(tbl)
  if autoloader and autoloader.logger and autoloader.logger.dump then
    autoloader.logger.dump(tbl)
  end
end

-- Clean up description text and split into parseable lines.
--  • Case-insensitive by forcing lower()
--  • Keeps '.' so tokens like "atk. bonus" survive
--  • Splits on '/' '|' then on ',' only
--  • Removes escaped quotes/backslashes seen in some resource strings
--  • Filters latent/event-only lines via codex.LATENTS (lower-cased needles)
local function sanitize_description(raw)
  local txt = tostring(raw or "")

  -- Normalize odd encodings first
  txt = txt
      :gsub("\\\"", "\"")  -- unescape quotes
      :gsub("\\'",  "'")   -- unescape single quotes
      :gsub("\\",   "")    -- drop stray backslashes

  -- Normalize punctuation, drop quotes, lower-case
  txt = txt
      :gsub("[\r\n\t]", " ")
      :gsub("’", "'"):gsub("‘", "'")
      :gsub("“", '"'):gsub("”", '"')
      :gsub("–", "-"):gsub("—", "-")
      :gsub("…", "...")
      :gsub("→", "->"):gsub("←", "<-"):gsub("↔", "<->")
      :gsub('"', "")                      -- drop all quotes
      :gsub("%s+", " "):gsub("^%s+", "")  -- trim
      :gsub("%s+$", "")
      :lower()

  -- Hard split on '|' and '/'
  local segments, lines = {}, {}

  for seg in txt:gmatch("[^|/]+") do
    if seg ~= nil then
      seg = seg:gsub("^%s+", ""):gsub("%s+$", "")
      if seg ~= "" then
        segments[#segments+1] = seg
      end
    end
  end

  for i = 1, #segments do
    local s = segments[i]
    if type(s) == 'string' and s ~= "" then
      for piece in s:gmatch("[^,]+") do
        if piece ~= nil then
          piece = piece:gsub("^%s+", ""):gsub("%s+$", "")
          if piece ~= "" then
            lines[#lines+1] = piece
          end
        end
      end
    end
  end

  -- Filter latent/event-only lines
  local filtered = {}
  local skip_list = codex.LATENTS or codex.LATENT or {}
  for i = 1, #lines do
    local ln = lines[i]
    local skip = false
    for j = 1, #skip_list do
      local needle = skip_list[j]
      if needle and needle ~= "" and ln:find(needle, 1, true) then
        skip = true
        break
      end
    end
    if not skip then filtered[#filtered+1] = ln end
  end

  return filtered, txt
end

-- Detects if a numeric token looks like a range (“～”, “~”) so we don’t treat it
-- as a single stat value.
local function looks_like_range(s)
  if type(s) ~= 'string' then return false end
  return (s:find("～%s*%d") or s:find("〜%s*%d") or s:find("~%s*%d")) ~= nil
end

-- Build ordered (longest-first) matchers with word-frontier guards so that
-- short aliases like "int" don't match inside "print" or "magic".
local function build_matchers()
  local out = {}
  local aliases = codex.STAT_ALIASES or {}
  local esc = (utils and utils.escape_lua_pattern) or function(str)
    return (tostring(str or ""):gsub("(%W)","%%%1"))
  end

  for stat_key, alias_list in pairs(aliases) do
    for i = 1, #alias_list do
      local alias = tostring(alias_list[i] or ""):lower():gsub('"','')
      if alias ~= "" then
        local first_is_alnum = alias:match("^%w") ~= nil
        local last_is_alnum  = alias:match("%w$")  ~= nil
        local left  = first_is_alnum and "%f[%w]" or ""
        local right = last_is_alnum  and "%f[%W]" or ""
        local pat   = left .. esc(alias) .. right .. "%s*[:=]?%s*([+-]?%d+%.?%d*)%s*(%%?)"
        out[#out+1] = { stat_key = stat_key, alias = alias, pattern = pat, alias_len = #alias }
      end
    end
  end

  table.sort(out, function(a, b) return a.alias_len > b.alias_len end)
  return out
end

local function parse_description(item, ext_augments)
  local matchers = build_matchers()
  local desc_text = tostring(item.description or "")
  local lines, _ = sanitize_description(desc_text)

  local stats        = {}
  local enhancements = {}  -- key -> { count, last_text }
  local enh_verbs    = codex.ENHANCEMENT_VERBS or { "enhances", "improves", "augments", "increases", "reduces", "adds", "occasionally", "sometimes" }
  local inverted     = codex.INVERTED_STATS or {}

  local function add_stat(stat_key, val)
    local n = tonumber(val)
    if not n then return end
    -- invert ONLY if the stat is flagged inverted AND the value is negative
    if (n < 0) and inverted[stat_key] then n = -n end
    stats[stat_key] = (stats[stat_key] or 0) + n
  end

  local function add_enhancement(key, text)
    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if key == "" then return end
    local e = enhancements[key] or { count = 0, last_text = "" }
    e.count = e.count + 1
    e.last_text = text or e.last_text
    enhancements[key] = e
  end

  local function try_pet_line(ln)
    local rest = ln:match("^%s*pet%s*[:%-]?%s*(.+)$")
    if not rest then return false end
    for m = 1, #matchers do
      local mt = matchers[m]
      local num, pct = rest:match(mt.pattern)
      if num then
        if looks_like_range(rest) then
          add_enhancement("pet:" .. mt.alias, ln)
          return true
        end
        add_stat("pet_" .. mt.stat_key, num)
        return true
      end
    end
    add_enhancement("pet", ln)
    return true
  end

  -- Parse every line
  for i = 1, #lines do
    local ln = lines[i]
    local handled = false

    -- Ignore obvious set-bonus carriers as enhancements (never stats)
    if ln:find("set bonus", 1, true) or ln:find("set:", 1, true) then
      add_enhancement("set", ln)
      handled = true
    end

    if (not handled) and ln:find("pet", 1, true) then
      handled = try_pet_line(ln)
    end

    if not handled then
      -- Known stat aliases (longest-first)
      for m = 1, #matchers do
        local mt = matchers[m]
        local num, pct = ln:match(mt.pattern)
        if num then
          if looks_like_range(ln) then
            add_enhancement(mt.alias, ln)
          else
            add_stat(mt.stat_key, num)
          end
          handled = true
          break
        end
      end
    end

    if not handled then
      local verb_hit = false
      for _, v in ipairs(enh_verbs) do
        if ln:find(v, 1, true) then verb_hit = true break end
      end
      if verb_hit or ln:match("^[%a%p%s]+[%+%-]%d+") then
        local key = ln:match("^([%a%p%s]+)%s*[%+%-]?%d*%%?") or ln
        key = (key or ""):gsub("[%s%p]+$", ""):gsub("^%s+", "")
        if key ~= "" then add_enhancement(key, ln) end
      end
    end
  end

  -- Apply known hidden bonuses by item id
  local known = (codex.KNOWN_ENHANCED_BY_ID or {})[item.id or -1]
  if known then
    for k, v in pairs(known) do add_stat(k, v) end
  end

  return {
    id           = item.id,
    name         = item.en or item.enl or item.name,
    description  = table.concat(lines, " | "),
    stats        = stats,
    enhancements = enhancements,
  }
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
  local rows = {}

  for _, bag_key in ipairs(codex.BAG_KEYS or {}) do
    local bag = items[bag_key]
    if type(bag) == 'table' and type(bag.max) == 'number' then
      for slot = 1, bag.max do
        local entry = bag[slot]
        if type(entry) == 'table' and entry.id and entry.id > 0 then
          local it = res.items[entry.id]
          if it then
            -- stitch in description from resources if available
            local desc_res = res.item_descriptions and res.item_descriptions[entry.id]
            local desc = (desc_res and (desc_res.en or desc_res.enl)) or it.description or ""
            rows[#rows+1] = {
              bag       = bag_key,
              slot      = slot,
              entry     = entry,
              item      = it,
              id        = it.id,
              name      = it.en or it.enl or it.name,
              category  = (it.category or ""):lower(),
              desc_text = desc,
            }
          end
        end
      end
    end
  end

  return rows
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

local function find_available_equipment()
  local entries = all_available_bag_items()
  log_debug("Scanned %d bag entries.", #entries)

  local out = {}
  for i = 1, #entries do
    local rec = entries[i]
    if player_can_equp(rec) then
      local ext    = get_augments_from_entry(rec.entry)
      -- Compose a minimal item object for the parser with a reliable description
      local parse_item = {
        id          = rec.id,
        name        = rec.name,
        en          = rec.item.en,
        enl         = rec.item.enl,
        description = rec.desc_text,
      }
      local parsed = parse_description(parse_item, ext)

      out[#out+1] = {
        id            = rec.id,
        name          = rec.name,
        slots         = rec.item.slots,
        parsed_stats  = parsed.stats,
        enhancements  = parsed.enhancements,
        description   = parsed.description, -- normalized (no raw_desc to keep logs tidy)
        augments      = ext or nil,
      }
    end
  end

  table.sort(out, function(a, b)
    local an, bn = tostring(a.name or ""), tostring(b.name or "")
    if an == bn then return (a.id or 0) < (b.id or 0) end
    return an < bn
  end)

  log_debug("find_available_equipment: %d gear items.", #out)
  log_dump(out)

  return out
end

function scanner.generate_auto_sets()
  autoloader.logger.debug("scanner.find_available_equipment()")
  find_available_equipment()
end

return scanner
