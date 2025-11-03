-- Copyright (c) 2025, NeatMachine
-- All rights reserved.
-- (BSD-3-Clause)

include("Modes")
local Spellbook = include("AutoLoader-Spellbook")
local res = rawget(_G, "res") or require("resources")

AutoLoader = {}
_G.AutoLoader = AutoLoader

-- ======================
-- Logging / Globals
-- ======================
AutoLoader.log = {
  mode   = M { "info", "debug", "off" },
  prefix = "[AutoLoader]",
  color  = 207,
}
AutoLoader.log.mode:set("debug") -- TODO: dev-only

AutoLoader.sets = {}

AutoLoader.modes = {
  idle          = M { ["description"] = "Idle", "default", "dt", "mdt" },
  melee         = M { ["description"] = "Melee", "default", "acc", "dt", "mdt", "off" },
  magic         = M { ["description"] = "Magic", "default", "macc", "mb" },
  weapon_lock   = M { "on", "off" },
  auto_movement = M { ["description"] = "Movement Polling", "on", "off" },
  auto_mb       = M { ["description"] = "Magic Burst Polling", "on", "off" },
  lockstyle     = M { ["description"] = "Lockstyle" },
  weapon        = M { ["description"] = "Weapon", "off" }, -- seed with "off"
}

AutoLoader.mode_display_names = {
  ["default"] = "Default",
  ["dt"] = "DT",
  ["mdt"] = "MDT",
  ["acc"] = "ACC",
  ["macc"] = "MACC",
  ["mb"] = "MB",
  ["on"] = "On",
  ["off"] = "Off",
  lockstyle = {}
}

local keybinds = {}
local _resolve_cache = {}

-- ======================
-- Small utils
-- ======================
local function normalize_token(s)
  s = tostring(s or "")
  return (s:gsub("%s+", "_"):gsub("'", ""):lower())
end

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function starts_with(str, prefix)
  if type(str) ~= "string" or type(prefix) ~= "string" then return false end
  return str:sub(1, #prefix):lower() == prefix:lower()
end

-- Current weapon label (pretty)
local function current_weapon_display()
  return tostring((AutoLoader.modes.weapon and AutoLoader.modes.weapon.current) or "")
end

-- Returns: set_key, pretty_weapon_or_nil, pretty_mode
--   melee[.weapon][.mode]
local function build_melee_key_and_labels(explicit_mode)
  local mode = explicit_mode
  if not mode or mode == "" then
    mode = AutoLoader.modes.melee.current
  end
  local pretty_mode = tostring(mode or "default"):lower()

  local wdisp       = current_weapon_display()
  local wkey        = normalize_token(wdisp)

  local key         = "melee"
  if wkey ~= "" then key = key .. "." .. wkey end
  if pretty_mode ~= "default" then key = key .. "." .. pretty_mode end

  return key, (wkey ~= "" and wdisp or nil), pretty_mode
end

-- ======================
-- Logging / echo
-- ======================
local function format_msg(msg, ...)
  local lg = AutoLoader.log
  local message = ""
  if lg and lg.prefix then message = lg.prefix .. " " end

  if select("#", ...) > 0 then
    local ok, out = pcall(string.format, tostring(msg), ...)
    message = message .. (ok and out or (tostring(msg) .. " [Format Error]"))
  else
    message = message .. tostring(msg)
  end
  return message
end

local function say(msg, ...)
  local log = AutoLoader.log
  if windower and windower.add_to_chat then
    windower.add_to_chat((log and log.color) or 207, format_msg(tostring(msg), ...))
  end
end

function AutoLoader.debug(msg, ...)
  local log = AutoLoader.log
  if log and log.mode and log.mode.current == "debug"
      and windower and windower.add_to_chat then
    windower.add_to_chat(log.color or 207, format_msg("[Debug] " .. tostring(msg), ...))
  end
end

function AutoLoader.info(msg, ...)
  local log = AutoLoader.log
  if log and log.mode and log.mode.current ~= "off" then
    say(msg, ...)
  end
end

local function sanitize_for_echo(s)
  s = tostring(s or "")
  s = s:gsub("[\r\n\t]", " ")
      :gsub("’", "'"):gsub("‘", "'")
      :gsub("“", '"'):gsub("”", '"')
      :gsub("–", "-"):gsub("—", "-")
      :gsub("…", "...")
      :gsub("→", "->"):gsub("←", "<-"):gsub("↔", "<->")
      :gsub(";", ":")
      :gsub("[^\x20-\x7E]", "?")
      :gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

function AutoLoader.echo(msg)
  if not (windower and windower.send_command) then return end
  local clean = sanitize_for_echo(msg)
  windower.send_command("@input /echo " .. clean)
end

function AutoLoader.error(msg, ...)
  local m = format_msg(tostring(msg), ...)
  local log = AutoLoader.log
  if windower and windower.add_to_chat then
    windower.add_to_chat((log and log.color) or 207, m)
  end
  error(m, 2) -- blame caller
end

-- ======================
-- Set resolution / equip
-- ======================
local function shallow_copy(t)
  local r = {}
  for k, v in pairs(t or {}) do r[k] = v end
  return r
end

local WEAPON_SLOTS      = { main = true, sub = true, range = true, ammo = true }
local WEAPON_LOCK_SLOTS = { main = true, sub = true, range = true --[[, ammo=true]] }

local function strip_weapon_slots(set)
  if type(set) ~= "table" then return set end
  for slot in pairs(WEAPON_LOCK_SLOTS) do set[slot] = nil end
  return set
end

local function filter_weapon_only(set)
  if type(set) ~= "table" then return set end
  local out = {}
  for k, v in pairs(set) do
    if WEAPON_SLOTS[k] then out[k] = v end
  end
  return out
end

local function push_set_name_if_exists(t, name)
  if name and name ~= "" and AutoLoader.sets[name] then t[#t + 1] = name end
end

-- combine sets without any weapon-lock stripping (used by weapon-mode)
local function combine_sets(names)
  local combined = {}
  for _, name in ipairs(names or {}) do
    local s = AutoLoader.sets[name]
    if s then combined = set_combine(combined, s) end
  end
  return combined
end

local function resolve_sets(names)
  if type(names) ~= "table" or #names == 0 then return {} end

  local key = table.concat(names, "\31")
  local hit = _resolve_cache[key]
  if hit then return hit end

  local combined = {}
  for _, name in ipairs(names) do
    local s = AutoLoader.sets[name]
    if s then
      combined = set_combine(combined, s)
    else
      AutoLoader.debug("resolve_sets(): Skipping missing set '%s'", name)
    end
  end

  _resolve_cache[key] = combined
  local result = combined
  if AutoLoader.modes.weapon_lock.current == "on" then
    AutoLoader.debug("resolve_sets(): weapon lock is on, clearing weapon slots.")
    result = strip_weapon_slots(shallow_copy(combined))
  end
  return result
end

local function set_idle_equip()
  local names = {}
  push_set_name_if_exists(names, "idle")
  local mode = AutoLoader.modes.idle.current
  if mode ~= "default" then push_set_name_if_exists(names, "idle." .. mode) end
  equip(resolve_sets(names))
  if AutoLoader.check_weapon_change then AutoLoader.check_weapon_change() end
end

local function set_melee_equip()
  local names = {}
  push_set_name_if_exists(names, "melee")

  local mode = AutoLoader.modes.melee.current
  if mode ~= "default" then push_set_name_if_exists(names, "melee." .. mode) end

  local wdisp = AutoLoader.modes.weapon.current
  local wkey  = normalize_token(wdisp)
  if wkey ~= "" then
    push_set_name_if_exists(names, "melee." .. wkey)
    if mode ~= "default" then
      push_set_name_if_exists(names, "melee." .. wkey .. "." .. mode)
    end
  end
  equip(resolve_sets(names))
  if AutoLoader.check_weapon_change then AutoLoader.check_weapon_change() end
end

-- ======================
-- Pattern helpers (search)
-- ======================
local function lua_escape(s)
  local magic = "().%+-*?[^$"
  return (tostring(s or ""):gsub("([" .. magic:gsub("%%", "%%%%") .. "])", "%%%1"))
end

-- Map results: { ["set.name"] = <table>, ... }
local function find_sets_matching(pattern, opts)
  opts = opts or {}
  if type(pattern) ~= "string" or pattern == "" then return {} end

  local ci  = (opts.case_insensitive ~= false) -- default true
  local pat = ci and pattern:lower() or pattern
  local out = {}

  for name, set_tbl in pairs(AutoLoader.sets or {}) do
    local hay = ci and name:lower() or name
    if hay:match(pat) then
      out[name] = set_tbl
    end
  end

  return out
end

local function find_sets_by_prefix_suffix(prefix, suffix, opts)
  local pat = "^" .. lua_escape(prefix or "") .. ".*" .. lua_escape(suffix or "") .. "$"
  return find_sets_matching(pat, opts)
end

-- ======================
-- Filename helpers / I/O
-- ======================
local function expected_prefixes()
  local base = ("%s_%s"):format(player.name, player.main_job:lower())
  return base .. ".", base .. "_"
end

local function which_prefix(fname)
  if type(fname) ~= "string" then return nil end
  local dot, under = expected_prefixes()
  if fname:sub(1, #dot) == dot then return "dot", #dot end
  if fname:sub(1, #under) == under then return "under", #under end
  return nil
end

local function is_expected_prefix(fname)
  return which_prefix(fname) ~= nil
end

local function extract_set_name(file)
  local kind, prefix_len = which_prefix(file)
  if not kind then return nil end
  local rest = file:sub(prefix_len + 1)
  return rest:gsub("%.lua$", "")
end

local function is_weapon(name)
  if type(name) ~= "string" then return false end
  name = name:lower():gsub("%s+", "")
  -- weapon.<digits>.<text>
  return name:match("^weapon%.%d+%.[^%.]+$") ~= nil
end

local function normalize_set_name(name)
  if type(name) ~= "string" then return nil end
  local normalized = name:gsub("%s+", "_"):gsub("'", "")
  if is_weapon(name) then
    local prefix, suffix = normalized:match("^(.-)%.([^%.]+)$")
    if prefix and suffix then
      return prefix:lower() .. "." .. suffix
    end
    return normalized:lower()
  else
    return normalized:lower()
  end
end

local function compile(code, chunkname, env)
  if type(loadstring) == "function" then
    local fn, err = loadstring(code, chunkname)
    if not fn then
      AutoLoader.error(err); return nil
    end
    if type(setfenv) == "function" then setfenv(fn, env) end
    return fn
  elseif type(load) == "function" then
    return load(code, chunkname or "=(AutoLoader)", "t", env)
  else
    AutoLoader.error("No load function available")
    return nil
  end
end

local function get_export_dir()
  if not windower or not windower.addon_path then
    AutoLoader.error("AutoLoader: windower.addon_path not available (must run inside GearSwap)")
  end
  return windower.addon_path .. "data/export/"
end

local function list_dir(path)
  if windower and windower.get_dir then
    AutoLoader.debug("Using windower.get_dir")
    return windower.get_dir(path) or {}
  else
    AutoLoader.debug("windower.get_dir not available.")
  end
  return {}
end

local function read_last_export_table(path)
  local f, err = io.open(path, "r")
  if not f then
    AutoLoader.error("open failed: %s", err or "unknown"); return nil
  end
  local src = f:read("*a") or ""; f:close()

  local src_lower, last_eq = src:lower(), nil
  for pos in src_lower:gmatch("()sets%s*%.%s*exported%s*=%s*%{") do last_eq = pos end
  if not last_eq then
    AutoLoader.error("No sets.exported table found in %s", path); return nil
  end

  local open_idx = src:find("%{", last_eq)
  if not open_idx then
    AutoLoader.error("Malformed export (missing '{')"); return nil
  end

  local tail, last_close_rel = src:sub(open_idx), nil
  for pos in tail:gmatch("()}") do last_close_rel = pos end
  if not last_close_rel then
    AutoLoader.error("Malformed export (missing closing '}')"); return nil
  end

  local close_idx = open_idx + last_close_rel - 1
  local table_src = src:sub(open_idx, close_idx)

  local env       = setmetatable({}, { __index = _G })
  local fn, cerr  = compile("return " .. table_src, "@AutoLoader:" .. (path:match("([^/\\]+)$") or path), env)
  if not fn then
    AutoLoader.error(("Compile failed: %s"):format(cerr or "unknown")); return nil
  end

  local ok, tbl = pcall(fn)
  if not ok then
    AutoLoader.error(("exec failed: %s"):format(tbl or "unknown")); return nil
  end
  if type(tbl) ~= "table" then
    AutoLoader.error("Export literal did not evaluate to a table"); return nil
  end
  return tbl
end

local function export_filename_dot(set_name)
  return ("%s_%s.%s.lua"):format(player.name, player.main_job:lower(), set_name)
end
local function export_filename_underscore(set_name)
  return ("%s_%s_%s.lua"):format(player.name, player.main_job:lower(), set_name)
end

local function delete_exports(selector, opts)
  opts = opts or {}
  local dry = (opts.dry_run ~= false) -- default true

  local export_dir = get_export_dir()
  local files = list_dir(export_dir) or {}
  local removed = 0

  local pat
  if not selector or selector == "" or selector == "all" then
    pat = ".*"
  elseif selector:match("^/.+/$") then
    pat = selector:sub(2, -2) -- raw Lua pattern /.../
  else
    pat = "^" .. lua_escape(selector) .. "$"
  end

  for _, fname in ipairs(files) do
    if is_expected_prefix(fname) then
      local set_name = extract_set_name(fname)
      if set_name and set_name:match(pat) then
        local full = export_dir .. fname
        if dry then
          say("Would delete: %s", fname)
        else
          local ok, err = os.remove(full)
          if ok then
            removed = removed + 1
            AutoLoader.sets[normalize_set_name(set_name)] = nil
          else
            AutoLoader.error("Failed to delete %s (%s)", fname, tostring(err))
          end
        end
      end
    end
  end

  _resolve_cache = {}

  if dry then
    say("Dry run complete. Use: gs c delete %s confirm", selector or "all")
  else
    show(("Deleted %d export file(s)."):format(removed))
  end
  return removed
end

local function save_export_file(raw_name)
  local name = normalize_set_name(raw_name)
  local dir  = get_export_dir()

  -- pre-delete both naming styles
  delete_exports(name, { dry_run = false })
  os.remove(dir .. export_filename_dot(name))
  os.remove(dir .. export_filename_underscore(name))

  _resolve_cache = {}

  if windower and windower.send_command then
    windower.send_command(("input //gs export %s"):format(name))
    windower.send_command("wait 0.5; gs c reload_sets")
    show(("Set saved: '%s'"):format(name))
  else
    AutoLoader.error("Cannot export: Windower not available")
  end
end

local function load_sets()
  AutoLoader.debug("load_sets()")
  local results = {}
  local export_dir = get_export_dir()
  AutoLoader.debug("Export directory: %s", export_dir)

  local files = list_dir(export_dir)
  if not files then
    AutoLoader.error("Failed to list directory: %s", export_dir)
    return results
  end

  AutoLoader.debug("Found %d entries in directory", #files)
  for _, name in ipairs(files) do
    if is_expected_prefix(name) then
      local content = read_last_export_table(export_dir .. name)
      if content then
        local set_name = extract_set_name(name)
        if set_name then
          local normalized_name = normalize_set_name(set_name)
          results[normalized_name] = content
          AutoLoader.debug("Loaded set: %s", normalized_name)
        else
          AutoLoader.debug("Skipped (unexpected set name): %s", name)
        end
      else
        AutoLoader.error("Failed to read file: %s (file not found, empty, or malformed)", name)
      end
    else
      local dot, under = expected_prefixes()
      AutoLoader.debug("Skipped (prefix mismatch): %s (expected starts with %s or %s)", name, dot, under)
    end
  end
  return results
end

local function get_set(name)
  if not AutoLoader.sets then
    AutoLoader.debug("AutoLoader.get_set(%s): No sets loaded yet", name)
    return nil
  end
  local content = AutoLoader.sets[name]
  AutoLoader.debug("AutoLoader.get_set(%s): %s", name, content and "found" or "not found")
  return content
end

-- ======================
-- Lockstyle helpers
-- ======================
local function reverse_map(map)
  local reverse = {}
  for k, v in pairs(map) do reverse[v:lower()] = k end
  return reverse
end

function AutoLoader.register_lockstyle(equipset_number, display_name)
  local mode = AutoLoader.modes.lockstyle
  if not equipset_number then return end

  equipset_number = tostring(equipset_number)
  local opts = {}
  for _, v in ipairs(mode) do table.insert(opts, v) end

  local already = false
  for _, v in ipairs(opts) do
    if tostring(v) == equipset_number then
      already = true; break
    end
  end

  if not already then
    table.insert(opts, equipset_number)
    mode:options(unpack(opts))
    AutoLoader.mode_display_names.lockstyle[equipset_number] = display_name or equipset_number
    AutoLoader.debug("Added lockstyle %s %s", equipset_number, display_name or "")
  end
end

local function get_lockstyle_id(name)
  if name then return reverse_map(AutoLoader.mode_display_names.lockstyle)[name:lower()] end
end

function AutoLoader.apply_lockstyle(lockstyle)
  lockstyle = tostring(lockstyle)
  if lockstyle and AutoLoader.modes.lockstyle:contains(lockstyle) then
    windower.send_command("input /lockstyleset " .. lockstyle)
  elseif lockstyle then
    local lockstyle_number = get_lockstyle_id(lockstyle)
    if lockstyle_number then
      windower.send_command("input /lockstyleset " .. lockstyle_number)
    else
      AutoLoader.error("Could not find lockstyle %s. Make sure it's registered in %s_%s",
        lockstyle, player.name, player.main_job)
    end
  else
    AutoLoader.error("apply_lockstyle() parameter lockstyle cannot be nil")
  end
end

-- ======================
-- JA ready helper
-- ======================
function AutoLoader.ja_ready(name)
  local recasts = windower.ffxi.get_ability_recasts()
  if not recasts or not res or not res.job_abilities then return false end
  local ja = res.job_abilities:with("en", name)
  if not ja then return false end
  local id = ja.recast_id
  return recasts[id] == 0
end

-- ======================
-- Weapon Mode System
-- ======================
AutoLoader._wm = AutoLoader._wm or {
  applying      = false,
  last_snapshot = nil, -- "main|sub|range"
}

local function weapon_snapshot()
  local eq    = (player and player.equipment) or {}
  local main  = tostring(eq.main or "")
  local sub   = tostring(eq.sub or "")
  local range = tostring(eq.range or "")
  return main .. "|" .. sub .. "|" .. range
end

-- Find a weapon-set by display token:
-- 1) weapon.<digits>.<token>
-- 2) melee.<token>[.mode] (fallback)
local function _find_weapon_key_and_set(wtoken)
  local esc = lua_escape(wtoken)
  for key, set_tbl in pairs(AutoLoader.sets or {}) do
    if key:match("^weapon%.%d+%." .. esc .. "$") then
      return key, set_tbl
    end
  end
  -- fallback to any melee.<token>... set
  for key, set_tbl in pairs(AutoLoader.sets or {}) do
    if key:match("^melee%." .. esc .. "($|%.)") then
      return key, set_tbl
    end
  end
  return nil, nil
end

-- Equip a weapon selection, bypassing weapon_lock and only touching weapon slots.
local function _equip_weapon_choice_by_token(wtoken)
  local key, tbl = _find_weapon_key_and_set(wtoken)
  if not tbl then
    AutoLoader.error("No weapon set found for '%s' (expected weapon.<slot>.%s or melee.%s...)", wtoken, wtoken, wtoken)
    return false
  end
  local just_weapons = filter_weapon_only(tbl)
  equip(just_weapons) -- do NOT resolve via resolve_sets (bypass lock stripping)
  return true
end

-- Centralized applier. If mode != off, it equips even if weapon_lock == on.
function AutoLoader.apply_weapon_mode()
  if AutoLoader._wm.applying then return false end
  AutoLoader._wm.applying = true

  local mode = AutoLoader.modes.weapon.current or "off"
  local did = false

  if mode ~= "off" then
    local wtoken = normalize_token(mode)
    did = _equip_weapon_choice_by_token(wtoken)
  end

  AutoLoader._wm.last_snapshot = weapon_snapshot()
  AutoLoader._wm.applying = false
  return did
end

-- Public API to set weapon mode (adds option if missing)
function AutoLoader.set_weapon_mode(display_name)
  local target = tostring(display_name or "off")
  if not AutoLoader.modes.weapon:contains(target) then
    local curr = {}
    for _, v in ipairs(AutoLoader.modes.weapon) do curr[#curr + 1] = v end
    curr[#curr + 1] = target
    AutoLoader.modes.weapon:options(unpack(curr))
  end
  AutoLoader.modes.weapon:set(target)

  local did = AutoLoader.apply_weapon_mode() -- weapon mode trumps weapon_lock
  AutoLoader.echo("Weapon Mode: " .. target)
  return did
end

function AutoLoader.clear_weapon_mode(reason)
  if AutoLoader.modes.weapon.current ~= "off" then
    AutoLoader.modes.weapon:set("off")
    AutoLoader.echo("Weapon Mode: Off" .. (reason and (" (" .. reason .. ")") or ""))
  end
end

-- Detect external weapon changes:
-- If mode != off AND weapon_lock == off AND snapshot changed => set mode off.
function AutoLoader.check_weapon_change()
  local mode = AutoLoader.modes.weapon.current or "off"
  local locked = (AutoLoader.modes.weapon_lock.current == "on")
  local snap = weapon_snapshot()

  if mode ~= "off" and not locked then
    if AutoLoader._wm.last_snapshot and AutoLoader._wm.last_snapshot ~= snap then
      AutoLoader.clear_weapon_mode("external weapon change")
    end
  end

  AutoLoader._wm.last_snapshot = snap
end

-- ======================
-- Hook runner
-- ======================
local function call_hook(name, stub, ...)
  local fn = rawget(_G, name)
  if type(fn) == "function" and fn ~= stub then
    local ok, result = pcall(fn, ...)
    if not ok then
      AutoLoader.error("Hook '" .. name .. "' failed: " .. tostring(result))
      return nil, result
    end
    return result
  end
  return nil
end

-- ======================
-- Keybind helpers
-- ======================
local function try_bind(key, cmd)
  if type(key) ~= "string" or key == "" then return false, "invalid key" end
  if type(cmd) ~= "string" or cmd == "" then return false, "invalid command" end
  if not (windower and windower.send_command) then return false, "windower not available" end
  local ok, err = pcall(function() windower.send_command(("bind %s %s"):format(key, cmd)) end)
  if not ok then return false, tostring(err or "bind failed") end
  keybinds[key] = cmd
  return true
end

local function try_unbind(key)
  if type(key) ~= "string" or key == "" then return false, "invalid key" end
  if not (windower and windower.send_command) then return false, "windower not available" end
  local ok, err = pcall(function() windower.send_command(("unbind %s"):format(key)) end)
  if not ok then return false, tostring(err or "unbind failed") end
  keybinds[key] = nil
  return true
end

function AutoLoader.set_keybind(key, cmd)
  if type(key) ~= "string" or key == "" then
    AutoLoader.error("set_keybind: invalid key"); return false
  end
  local desired, applied = cmd, keybinds[key]
  if not desired or desired == "" then
    local ok, err = try_unbind(key)
    if not ok then
      AutoLoader.error("Failed to unbind %s, %s", key, err or "unknown"); return false
    end
    AutoLoader.debug("Unbound %s", key); return true
  end
  if desired ~= applied then
    local ok, err = try_bind(key, desired)
    if not ok then
      AutoLoader.error("set_keybind: bind failed for %s -> %s (%s)", key, desired, err or "unknown"); return false
    end
    AutoLoader.debug("Bound %s -> %s", key, desired); return true
  end
  AutoLoader.debug("Key %s already bound to %s", key, desired); return true
end

function AutoLoader.clear_keybinds()
  AutoLoader.debug("Clearing keybinds")
  for key, _ in pairs(keybinds) do
    local ok, err = try_unbind(key)
    if not ok then
      AutoLoader.error("Failed to unbind %s, %s", key, err); return false
    end
  end
end

-- ======================
-- GearSwap hooks
-- ======================
AutoLoader.stub_after_user_setup = function() end
after_user_setup = AutoLoader.stub_after_user_setup
function user_setup()
  AutoLoader._wm.last_snapshot = weapon_snapshot()
  call_hook("after_user_setup", AutoLoader.stub_after_user_setup)
end

AutoLoader.stub_after_get_sets = function() end
after_get_sets = AutoLoader.stub_after_get_sets
function get_sets()
  AutoLoader.debug("AutoLoader: Loading export files...")
  AutoLoader.sets = load_sets()
  call_hook("after_get_sets", AutoLoader.stub_after_get_sets)
end

AutoLoader.stub_before_status_change = function() end
before_status_change = AutoLoader.stub_before_status_change
AutoLoader.stub_after_status_change = function() end
after_status_change = AutoLoader.stub_after_status_change
function status_change(new, old)
  local continue = call_hook("before_status_change", AutoLoader.stub_before_status_change, new, old)
  if continue == false then return end
  AutoLoader.debug("status_change %s -> %s", old, new)

  if new == "Engaged" and AutoLoader.modes.melee.current ~= "off" then
    set_melee_equip()
  elseif new == "Resting" then
    if AutoLoader.sets["resting"] then equip(AutoLoader.sets["resting"]) end
  else
    set_idle_equip()
  end

  call_hook("after_status_change", AutoLoader.stub_after_status_change, new, old)
end

AutoLoader.stub_before_precast = function() end
before_precast = AutoLoader.stub_before_precast
AutoLoader.stub_after_precast = function() end
after_precast = AutoLoader.stub_after_precast
function precast(spell)
  local continue = call_hook("before_precast", AutoLoader.stub_before_precast, spell)
  if continue == false then return end

  if spell then
    if spell.action_type == "Magic" then
      local ordered_sets = Spellbook.get_ordered_set_names(spell)
      if Spellbook.is_instant(spell) then
        equip(resolve_sets(ordered_sets))
      else
        equip(resolve_sets({ "ma", "precast.ma", "precast", "interrupt", "fastcast", unpack(ordered_sets) }))
      end
    elseif spell.action_type == "WeaponSkill" then
      equip(resolve_sets({ "ws", "weaponskill", spell.english }))
    else
      equip(resolve_sets({ spell.english, "precast." .. spell.english }))
    end
  end

  call_hook("after_precast", AutoLoader.stub_after_precast, spell)
end

AutoLoader.stub_before_midcast = function() end
before_midcast = AutoLoader.stub_before_midcast
AutoLoader.stub_after_midcast = function() end
after_midcast = AutoLoader.stub_after_midcast
function midcast(spell)
  local continue = call_hook("before_midcast", AutoLoader.stub_before_midcast, spell)
  if continue == false then return end
  if spell.action_type == "Magic" then
    local skill = spell.skill and spell.skill:match("^(%S+)"):lower()
    local ordered_sets = Spellbook.get_ordered_set_names(spell)
    equip(resolve_sets({ skill, unpack(ordered_sets) }))
  end
  call_hook("after_midcast", AutoLoader.stub_after_midcast, spell)
end

AutoLoader.stub_before_aftercast = function() end
before_aftercast = AutoLoader.stub_before_aftercast
AutoLoader.stub_after_aftercast = function() end
after_aftercast = AutoLoader.stub_after_aftercast
function aftercast(spell)
  local continue = call_hook("before_aftercast", AutoLoader.stub_before_aftercast, spell)
  if continue == false then return end
  AutoLoader.status_refresh()
  if AutoLoader.check_weapon_change then AutoLoader.check_weapon_change() end
  call_hook("after_aftercast", AutoLoader.stub_after_aftercast, spell)
end

function AutoLoader.status_refresh()
  status_change(player.status, player.status)
end

-- ======================
-- Commands
-- ======================
local function handle_log_command(arg)
  local lg = AutoLoader.log
  if not lg or not lg.mode then return end

  if not arg or arg == "" then
    lg.mode:cycle()
    say("Log mode set to: %s", lg.mode.current)
    return
  end

  local mode = arg:lower()
  if lg.mode:contains(mode) then
    lg.mode:set(mode)
    say("Log mode set to: %s", lg.mode.current)
  else
    AutoLoader.error("Invalid log mode: %s", mode)
  end
end

local function handle_idle_command(arg)
  if not arg or arg == "" then
    AutoLoader.modes.idle:cycle()
    local mode_display = AutoLoader.mode_display_names[AutoLoader.modes.idle.current] or AutoLoader.modes.idle.current
    AutoLoader.echo(AutoLoader.modes.idle.description .. " Mode: " .. mode_display)
    AutoLoader.status_refresh()
    return
  end

  local mode = arg:lower()
  if AutoLoader.modes.idle:contains(mode) then
    AutoLoader.modes.idle:set(mode)
    local mode_display = AutoLoader.mode_display_names[AutoLoader.modes.idle.current] or AutoLoader.modes.idle.current
    AutoLoader.echo(AutoLoader.modes.idle.description .. " Mode: " .. mode_display)
    AutoLoader.status_refresh()
  else
    AutoLoader.error("Invalid idle mode: %s", arg)
  end
end

local function handle_melee_save_command(arg)
  local mode = trim(arg or "")
  if mode ~= "" then
    mode = mode:lower()
    if not AutoLoader.modes.melee:contains(mode) then
      AutoLoader.error("Unknown melee mode: %s", mode); return
    end
  end

  local set_name, pretty_weapon, pretty_mode = build_melee_key_and_labels(mode)
  save_export_file(set_name)
  show(("Saved Melee set  Weapon: %s  Mode: %s  Key: %s")
    :format(pretty_weapon or "(none)", pretty_mode, set_name))
end

local function handle_melee_command(arg)
  arg = tostring(arg or "")

  -- No args: cycle like before
  if arg == "" then
    AutoLoader.modes.melee:cycle()
    local mode_display = AutoLoader.mode_display_names[AutoLoader.modes.melee.current] or AutoLoader.modes.melee.current
    AutoLoader.echo(AutoLoader.modes.melee.description .. " Mode: " .. mode_display)
    AutoLoader.status_refresh()
    return
  end

  -- Subcommands
  local op, rest = arg:match("^(%S+)%s*(.*)$")
  op = (op or ""):lower()

  if op == "save" then
    handle_melee_save_command(rest) -- supports: "melee save" and "melee save acc"
    return
  end

  -- Otherwise treat as direct mode set (back-compat)
  local mode = arg:lower()
  if AutoLoader.modes.melee:contains(mode) then
    AutoLoader.modes.melee:set(mode)
    local mode_display = AutoLoader.mode_display_names[AutoLoader.modes.melee.current] or AutoLoader.modes.melee.current
    AutoLoader.echo(AutoLoader.modes.melee.description .. " Mode: " .. mode_display)
    AutoLoader.status_refresh()
  else
    AutoLoader.error("Invalid melee mode: %s", arg)
  end
end

local function handle_magic_command(arg)
  if not arg or arg == "" then
    AutoLoader.modes.magic:cycle()
    local mode_display = AutoLoader.mode_display_names[AutoLoader.modes.magic.current] or AutoLoader.modes.magic.current
    AutoLoader.echo(AutoLoader.modes.magic.description .. " Mode: " .. mode_display)
    AutoLoader.status_refresh()
    return
  end

  local mode = arg:lower()
  if AutoLoader.modes.magic:contains(mode) then
    AutoLoader.modes.magic:set(mode)
    local mode_display = AutoLoader.mode_display_names[AutoLoader.modes.magic.current] or AutoLoader.modes.magic.current
    AutoLoader.echo(AutoLoader.modes.magic.description .. " Mode: " .. mode_display)
    AutoLoader.status_refresh()
  else
    AutoLoader.error("Invalid magic mode: %s", arg)
  end
end

local function handle_save_weapon_command(arg)
  if not arg or not is_weapon(arg) then
    AutoLoader.error("Usage: save weapon.<slot>.<name>")
    return
  end
  save_export_file(arg)
end

local function handle_delete_weapon_command(arg)
  AutoLoader.error("delete_weapon not implemented yet")
end

local function handle_show_command(arg)
  if not arg or arg == "" then
    say("All loaded sets:")
    for name, _ in pairs(AutoLoader.sets) do say(name) end
  else
    local set_name = normalize_set_name(arg)
    local content = get_set(set_name)
    if content then
      say("'%s':", set_name)
      for k, v in pairs(content) do
        say("  %s: %s", tostring(k), tostring(v))
      end
    else
      say("Set '%s' not found.", set_name)
    end
  end
end

local function handle_lock_weapon_command(arg)
  arg = trim(arg or "")
  if arg == "" then
    AutoLoader.modes.weapon_lock:cycle()
  else
    local v = arg:lower()
    if AutoLoader.modes.weapon_lock:contains(v) then
      AutoLoader.modes.weapon_lock:set(v)
    else
      AutoLoader.error("Invalid lock_weapon value: %s (use on|off)", arg)
      return
    end
  end
  AutoLoader.echo("Weapon Lock: " .. AutoLoader.modes.weapon_lock.current)
end

local function handle_weapon_command(arg)
  arg = trim(arg or "")
  if arg == "" then
    AutoLoader.modes.weapon:cycle()
    AutoLoader.apply_weapon_mode() -- trumps lock
    AutoLoader.echo("Weapon Mode: " .. AutoLoader.modes.weapon.current)
    return
  end
  AutoLoader.set_weapon_mode(arg)
end

local function handle_lockstyle_command(arg)
  if not arg or arg == "" then
    AutoLoader.modes.lockstyle:cycle()
    AutoLoader.apply_lockstyle(AutoLoader.modes.lockstyle.current)
    AutoLoader.echo(AutoLoader.modes.lockstyle.description .. ": " ..
      (AutoLoader.mode_display_names.lockstyle[AutoLoader.modes.lockstyle.current] or AutoLoader.modes.lockstyle.current))
    return
  end

  if AutoLoader.modes.lockstyle:contains(arg) then
    AutoLoader.modes.lockstyle:set(arg)
    AutoLoader.apply_lockstyle(AutoLoader.modes.lockstyle.current)
    AutoLoader.echo(AutoLoader.modes.lockstyle.description .. ": " ..
      (AutoLoader.mode_display_names.lockstyle[AutoLoader.modes.lockstyle.current] or AutoLoader.modes.lockstyle.current))
    return
  end

  local reverse = reverse_map(AutoLoader.mode_display_names.lockstyle)
  local reverse_arg = reverse[arg]
  if reverse_arg and AutoLoader.modes.lockstyle:contains(reverse_arg) then
    AutoLoader.modes.lockstyle:set(reverse_arg)
    AutoLoader.apply_lockstyle(AutoLoader.modes.lockstyle.current)
    AutoLoader.echo(AutoLoader.modes.lockstyle.description .. ": " ..
      (AutoLoader.mode_display_names.lockstyle[AutoLoader.modes.lockstyle.current] or AutoLoader.modes.lockstyle.current))
  else
    AutoLoader.error("Lockstyle %s not registered in %s_%s.lua", arg, player.name, player.main_job)
  end
end

local function handle_save_command(arg)
  if not arg or arg == "" then
    AutoLoader.error("Usage: save <set_name>|weapon.<slot>.<set_name>")
    return
  end
  save_export_file(arg)
end

local function handle_delete_command(arg)
  arg = tostring(arg or "")
  local sel, maybe_confirm = arg:match("^(.-)%s+(confirm)$")
  local selector = trim(sel or arg)
  local confirm = (maybe_confirm == "confirm")

  if selector == "" then
    say("Usage: delete <set_name|/pattern/|all> [confirm]")
    say("Example: gs c delete /melee%.acc/ confirm")
    return
  end

  delete_exports(selector, { dry_run = (not confirm) })
end

-- ======================
-- Help system
-- ======================
local function _collect_mode_values(mode_obj)
  local vals = {}
  for _, v in ipairs(mode_obj) do vals[#vals + 1] = tostring(v) end
  return vals
end

local function _join(arr, sep)
  sep = sep or ", "
  local s = ""
  for i, v in ipairs(arr) do
    s = s .. (i > 1 and sep or "") .. tostring(v)
  end
  return s
end

local function _mode_sig(mode_obj)
  return "<mode> ::= " .. _join(_collect_mode_values(mode_obj), " | ")
end

local function _effective_melee_key_line()
  local key, w, m = build_melee_key_and_labels(nil)
  return ("Effective melee key now: %s  (weapon=%s, mode=%s)"):format(key, w or "none", m)
end

local function _print_kv(label, value)
  say("  %-14s %s", label .. ":", value)
end

-- Topic registry
local _HELP = {
  log = {
    title    = "log",
    desc     = "Set or view log verbosity.",
    usage    = { "log", "log <mode>" },
    params   = { "<mode> ::= info | debug | off" },
    examples = { "gs c log debug", "gs c log off" },
    dynamic  = function() return "Current: " .. AutoLoader.log.mode.current end,
  },

  idle = {
    title    = "idle",
    desc     = "Cycle or set idle gear mode.",
    usage    = { "idle", "idle <mode>" },
    params   = { _mode_sig(AutoLoader.modes.idle) },
    examples = { "gs c idle dt", "gs c idle" },
    dynamic  = function() return "Current: " .. AutoLoader.modes.idle.current end,
  },

  melee = {
    title    = "melee",
    desc     = "Cycle/set melee mode and save melee snapshots (weapon-aware).",
    usage    = { "melee", "melee <mode>", "melee save [<mode>]" },
    params   = {
      _mode_sig(AutoLoader.modes.melee),
      "When omitted, `melee save` uses your CURRENT melee mode.",
      "Saved key format: melee[.normalized_weapon][.mode]",
    },
    examples = {
      "gs c melee acc",
      "gs c melee save",
      "gs c melee save dt",
    },
    dynamic  = function() return _effective_melee_key_line() end,
  },

  magic = {
    title    = "magic",
    desc     = "Cycle or set magic mode.",
    usage    = { "magic", "magic <mode>" },
    params   = { _mode_sig(AutoLoader.modes.magic) },
    examples = { "gs c magic macc", "gs c magic mb" },
    dynamic  = function() return "Current: " .. AutoLoader.modes.magic.current end,
  },

  weapon = {
    title    = "weapon",
    desc     = "Set/cycle weapon mode. 'off' disables weapon enforcement. Weapon mode EQUIPS even if weapon_lock is on.",
    usage    = { "weapon", "weapon off", "weapon <display_name>" },
    params   = {
      "Display names are free-form (e.g., 'Crocea Mors'); we match exported weapon.<slot>.<name> or melee.<name> sets.",
      "Only weapon slots are equipped from the chosen set.",
    },
    examples = {
      "gs c weapon Crocea Mors",
      "gs c weapon off",
      "gs c weapon", -- cycles through registered options
    },
    dynamic  = function() return "Current: " .. AutoLoader.modes.weapon.current end,
  },

  save = {
    title    = "save",
    desc     = "Export current equipped set to file (overwrites same-name export).",
    usage    = { "save <set_name>", "save weapon.<slot>.<name>" },
    params   = {
      "<set_name> ::= free-form, normalized to lowercase with spaces->underscores",
      "weapon.<slot>.<name> ::= e.g. weapon.1.crocea_mors (slot is digits)",
    },
    examples = {
      "gs c save idle.dt",
      "gs c save weapon.1.crocea_mors",
    },
  },

  save_weapon = {
    title    = "save_weapon",
    desc     = "Shorthand for weapon-typed export.",
    usage    = { "save_weapon weapon.<slot>.<name>" },
    params   = { "See `help save` for pattern details." },
    examples = { "gs c save_weapon weapon.2.naegling" },
  },

  delete = {
    title    = "delete",
    desc     = "Delete export files by exact name, pattern, or all (dry-run by default).",
    usage    = { "delete <set_name>", "delete /lua_pattern/", "delete all", "delete <selector> confirm" },
    params   = {
      "Use 'confirm' to actually delete; otherwise performs a dry run.",
      "Selector matches the exported set name (without prefix/extension).",
    },
    examples = {
      "gs c delete melee.acc",
      "gs c delete /melee%.crocea_mors%.*/",
      "gs c delete all confirm",
    },
  },

  show = {
    title    = "show",
    desc     = "List loaded set names or dump a specific set's top-level keys.",
    usage    = { "show", "show <set_name>" },
    examples = { "gs c show", "gs c show melee.acc" },
  },

  lock_weapon = {
    title    = "lock_weapon",
    desc     = "Toggle or set weapon lock; strips weapon slots when equipping resolved sets.",
    usage    = { "lock_weapon", "lock_weapon on", "lock_weapon off" },
    examples = { "gs c lock_weapon on", "gs c lock_weapon" },
    dynamic  = function() return "Current: " .. AutoLoader.modes.weapon_lock.current end,
  },

  lockstyle = {
    title    = "lockstyle",
    desc     = "Cycle or set lockstyle by id or registered name.",
    usage    = { "lockstyle", "lockstyle <id>", "lockstyle <registered_name>" },
    examples = { "gs c lockstyle 12", "gs c lockstyle 'Blue Mage A'" },
  },

  --[[
  auto_movement = {
    title = "auto_movement",
    desc  = "Toggle/set movement polling flag (scaffolding).",
    usage = { "auto_movement", "auto_movement on", "auto_movement off" },
    dynamic = function() return "Current: " .. AutoLoader.modes.auto_movement.current end,
  },

  auto_mb = {
    title = "auto_mb",
    desc  = "Toggle/set magic burst polling flag (scaffolding).",
    usage = { "auto_mb", "auto_mb on", "auto_mb off" },
    dynamic = function() return "Current: " .. AutoLoader.modes.auto_mb.current end,
  },
  --]]

  sets = {
    title    = "sets",
    desc     = "List valid set names.",
    usage    = { "help sets" },
    examples = { "gs c help sets" },
  },

  reload_sets = {
    title = "reload_sets",
    desc  = "Reloads exports from disk and clears resolved-set cache.",
    usage = { "reload_sets" },
  },

  help = {
    title    = "help",
    desc     = "Show command index or help for a specific topic.",
    usage    = { "help", "help <topic>" },
    examples = { "gs c help melee", "gs c help save" },
  },
}

local function _sorted_keys(t)
  local keys = {}
  for k, _ in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  return keys
end

local function _print_help_index()
  say("Available commands (use: gs c help <topic>):")
  for _, k in ipairs(_sorted_keys(_HELP)) do
    local h = _HELP[k]
    if k ~= "help" then
      say("  %-14s %s", k, h.desc or "")
    end
  end
  say("  %-14s %s", "help", _HELP.help.desc or "")
end

local function _print_topic(h)
  say(h.title .. " — " .. (h.desc or ""))
  if h.usage and #h.usage > 0 then
    _print_kv("Usage", h.usage[1])
    for i = 2, #h.usage do say("  %-14s %s", "", h.usage[i]) end
  end
  if h.params and #h.params > 0 then
    _print_kv("Params", h.params[1])
    for i = 2, #h.params do say("  %-14s %s", "", h.params[i]) end
  end
  if h.examples and #h.examples > 0 then
    _print_kv("Examples", h.examples[1])
    for i = 2, #h.examples do say("  %-14s %s", "", h.examples[i]) end
  end
  if h.dynamic then
    local ok, dyn = pcall(h.dynamic)
    if ok and dyn and dyn ~= "" then _print_kv("Now", dyn) end
  end
end

local function handle_help_command(arg)
  arg = trim(arg or "")
  if arg == "" or arg == "topics" or arg == "index" then
    _print_help_index()
    return
  end

  -- Special: show valid set-name patterns + Spellbook names
  if arg == "sets" then
    local idle_modes  = (AutoLoader and AutoLoader.modes and AutoLoader.modes.idle) and
    _collect_mode_values(AutoLoader.modes.idle) or {}
    local melee_modes = (AutoLoader and AutoLoader.modes and AutoLoader.modes.melee) and
    _collect_mode_values(AutoLoader.modes.melee) or {}

    -- Patterns users can create/save
    say("Valid set names (patterns):")
    say("  idle")
    say("  melee (Engaged set)")
    say("  *idle and melee sets are saved according to your current mode and weapon. See: //gs c help mode and //gs c help weapon")
    say("  ws (Weaponskill catch-all set)")
    say("  fastcast (Equipped before spells are cast)")
    say("  <weaponskill> (Weaponskill by name)")
    say("  <ability> (Ability by name)")
    say("  <spell> (Spell by name)")

    -- Spellbook-known set names
    local listed = {}
    if type(Spellbook) == "table" then
      -- Prefer the helper you added that returns an array of strings
      local getter = Spellbook.list_all_set_names or Spellbook.get_all_set_names or Spellbook.collect_all_set_names
      if type(getter) == "function" then
        local ok, names = pcall(getter)
        if ok and type(names) == "table" and #names > 0 then
          listed = names
        end
      end

      -- Fallback: flatten from internals if present
      if #listed == 0 and type(Spellbook._internal) == "table" and type(Spellbook._internal.spell_map) == "table" then
        for _, group in pairs(Spellbook._internal.spell_map) do
          if type(group) == "table" then
            for _, arr in pairs(group) do
              if type(arr) == "table" then
                for _, setname in ipairs(arr) do
                  table.insert(listed, tostring(setname))
                end
              elseif type(arr) == "string" then
                table.insert(listed, tostring(arr))
              end
            end
          end
        end
      end
    end

    if #listed > 0 then
      -- De-dup while preserving order
      local seen = {}
      say("Spellbook set names:")
      for _, n in ipairs(listed) do
        if not seen[n] then
          seen[n] = true
          say("  %s", n)
        end
      end

      say("  These sets are applied intelligently to groups of spells for your convenience. Specificity always wins: If you save a set for a spell by name, that set will always have highest priority.")
      say("  Check the AutoLoader README.md for more details about this add-on.")
    else
      say("Spellbook set names: (none found)")
    end
    return
  end

  -- direct match
  local topic = _HELP[arg]
  if topic then
    _print_topic(topic)
    return
  end

  -- fuzzy prefix/similar suggestions
  local matches = {}
  local low = arg:lower()
  for k, _ in pairs(_HELP) do
    if k:lower():find("^" .. lua_escape(low)) then matches[#matches + 1] = k end
  end
  table.sort(matches)

  if #matches == 1 then
    _print_topic(_HELP[matches[1]])
  elseif #matches > 1 then
    say("Did you mean:")
    for _, m in ipairs(matches) do say("  %s", m) end
  else
    say("No help topic '%s'. Try: gs c help", arg)
  end
end

-- ======================
-- self_command router
-- ======================
function self_command(cmd)
  cmd = tostring(cmd or "")
  local a1, tail = cmd:match("^(%S+)%s*(.*)$")
  a1 = (a1 or ""):lower()
  local a2 = (tail ~= "" and tail) or nil

  if a1 == "log" then
    handle_log_command(a2)
  elseif a1 == "element" then -- reserved for Spellbook.Elements
  elseif a1 == "idle" then
    handle_idle_command(a2)
  elseif a1 == "melee" then
    handle_melee_command(a2)
  elseif a1 == "magic" then
    handle_magic_command(a2)
  elseif a1 == "weapon" then
    handle_weapon_command(a2)
  elseif a1 == "save_weapon" then
    handle_save_weapon_command(a2)
  elseif a1 == "delete_weapon" then
    handle_delete_weapon_command(a2)
  elseif a1 == "lock_weapon" then
    handle_lock_weapon_command(a2)
  elseif a1 == "auto_movement" then -- future
  elseif a1 == "auto_mb" then       -- future
  elseif a1 == "lockstyle" then
    handle_lockstyle_command(a2)
  elseif a1 == "save" then
    handle_save_command(a2)
  elseif a1 == "show" then
    handle_show_command(a2)
  elseif a1 == "delete" then
    handle_delete_command(a2)
  elseif a1 == "reload_sets" then
    reload_sets(true)
    return
  elseif a1 == "help" then
    handle_help_command(a2)
  else
    AutoLoader.info("Unknown command: %s", a1 or "nil")
  end
end

-- TODO(weapon-command unification)
-- Target API (kept on ice until stable):
--   gs c weapon save weapon.<slot>.<name>   -- e.g., weapon.1.crocea_mors
--   gs c weapon mode <label|off>            -- “off” disables weapon-mode logic
--   gs c weapon use <label>                 -- apply saved weapon set
--   gs c weapon lock on|off                 -- lock weapon slots
--   gs c weapon show                        -- list weapon.* sets and current
--
-- Notes:
-- - Keep `save_weapon` and `lock_weapon` working for now (back-compat shims).
-- - Weapon mode always overrides lock on switch; otherwise lock wins.
-- - If weapon mode ≠ off and user changes weapon with lock off → auto-switch to Off.


local function reload_sets(force_message)
  AutoLoader.sets = load_sets()
  _resolve_cache = {}

  local message = "Sets refreshed."
  if force_message then
    show(message)
  else
    AutoLoader.debug(message)
  end
end

-- ======================
-- Unload
-- ======================
AutoLoader.stub_before_user_unload = function() end
before_user_unload = AutoLoader.stub_before_user_unload
function user_unload()
  call_hook("before_user_unload", AutoLoader.stub_before_user_unload)
  AutoLoader.clear_keybinds()
end
