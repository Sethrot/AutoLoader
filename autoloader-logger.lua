-- libs/autoloader-logger.lua
-- Logger for Windower/GearSwap.
-- - Always writes to: addons/GearSwap/data/autoloader/log/YYYY-MM-DD.log
-- - On-screen output can be toggled per level; file logging never stops.
-- - Prunes logs older than 2 days (keeps today and previous 2).
-- - Lua 5.1-safe.

local logger = {}

-- =====================
-- Config (defaults)
-- =====================
logger.prefix            = "[AutoLoader]"

-- On-screen toggles (file logging always on)
logger.debug_to_screen   = false  -- default OFF (requested)
logger.info_to_screen    = true
logger.warn_to_screen    = true
logger.error_to_screen   = true
logger.echo_to_screen    = true

-- Chat colors
logger.color_debug       = 123
logger.color_info        = 207
logger.color_warn        = 200
logger.color_error       = 167
logger.color_echo        = 204

-- Internal state
local _current_day, _file_path = nil, nil
local _wrote_header, _pruned_today, _announced_path = false, false, false

-- =====================
-- Utilities
-- =====================
local function _fmt(fmt, ...)
  if select('#', ...) == 0 then return tostring(fmt) end
  local ok, out = pcall(string.format, tostring(fmt), ...)
  return ok and out or tostring(fmt)
end

local function _chat(color, text)
  if windower and windower.add_to_chat then
    windower.add_to_chat(color, text)
  else
    print(text)
  end
end

local function _today()      return os.date("%Y-%m-%d") end
local function _nowstamp()   return os.date("%H:%M:%S") end

local function _norm(path) return (tostring(path or ""):gsub("\\","/")) end

local function _addon_base()
  -- e.g., ".../addons/<current-addon>/" (with trailing slash)
  return _norm((windower and windower.addon_path) or "./")
end

local function _parent_dir(path_with_trailing)
  -- Drop the last segment, keep trailing slash on result
  local p = _norm(path_with_trailing or "")
  if not p:match("/$") then p = p .. "/" end
  local parent = p:match("^(.*[/])[^/]+/$") or "./"
  return parent
end

local function _gearswap_base()
  -- Convert "<...>/addons/<something>/" -> "<...>/addons/GearSwap/"
  local parent = _parent_dir(_addon_base())        -- ".../addons/"
  return parent .. "GearSwap/"
end

local function _gearswap_data_dir()
  return _gearswap_base() .. "data/"
end

local function _ensure_dirs(abs_path_dir)
  -- best-effort; Windower provides create_dir
  if windower and windower.create_dir then
    local parts = {}
    for seg in _norm(abs_path_dir):gmatch("([^/]+)/") do parts[#parts+1] = seg end
    local acc = ""
    for i, seg in ipairs(parts) do
      acc = acc .. seg .. "/"
      pcall(windower.create_dir, acc)
    end
  end
end

local function _ensure_file()
  local day = _today()
  if _file_path and _current_day == day then return end

  _current_day   = day
  _wrote_header  = false
  _pruned_today  = false
  _announced_path= false

  local base_data = _gearswap_data_dir()                      -- ".../addons/GearSwap/data/"
  local log_dir   = base_data .. "autoloader/log/"            -- ".../data/autoloader/log/"
  _ensure_dirs(log_dir)

  _file_path = log_dir .. day .. ".log"
end

local function _append_line(line)
  _ensure_file()
  local f = io.open(_file_path, "a")
  if f then
    f:write(("[%s] %s\n"):format(_nowstamp(), line))
    f:close()
  end
end

local function _maybe_header()
  if _wrote_header then return end
  _wrote_header = true
  local banner = ("===== %s session start %s ====="):format(logger.prefix, os.date("%Y-%m-%d %H:%M:%S"))
  _append_line(banner)

  if not _announced_path then
    _announced_path = true
    _chat(logger.color_info, ("%s [INFO] logging to %s"):format(logger.prefix, _file_path))
  end
end

-- -------- pruning (> 2 days old) --------
local function _ymd_offset_str(offset_days)
  local t = os.date("*t")
  local ts = os.time{ year=t.year, month=t.month, day=t.day, hour=12 } + (offset_days * 86400)
  return os.date("%Y-%m-%d", ts)
end

local function _delete_log_for(day_str)
  local path = _gearswap_data_dir() .. "autoloader/log/" .. day_str .. ".log"
  pcall(os.remove, path)
end

local function _prune_old()
  if _pruned_today then return end
  _pruned_today = true
  -- keep today, -1, -2; delete -3..-90 if present
  for i = 3, 90 do
    _delete_log_for(_ymd_offset_str(-i))
  end
end

local function _emit(level, color, fmt, ...)
  local body = _fmt(fmt, ...)
  local line = ("%s [%s] %s"):format(logger.prefix, level, body)

  _ensure_file()
  _maybe_header()
  _prune_old()

  -- Always append to file
  _append_line(line)

  -- Optional on-screen
  local show = true
  if     level == "DEBUG" then show = logger.debug_to_screen
  elseif level == "INFO"  then show = logger.info_to_screen
  elseif level == "WARN"  then show = logger.warn_to_screen
  elseif level == "ERROR" then show = logger.error_to_screen
  elseif level == "ECHO"  then show = logger.echo_to_screen
  end
  if show then _chat(color, line) end
end

-- =====================
-- Public API
-- =====================
function logger.set_prefix(p) logger.prefix = tostring(p or logger.prefix) end

-- on-screen toggles
function logger.enable_debug_screen(on) logger.debug_to_screen = not (on == false) end
function logger.enable_info_screen(on)  logger.info_to_screen  = not (on == false) end
function logger.enable_warn_screen(on)  logger.warn_to_screen  = not (on == false) end
function logger.enable_error_screen(on) logger.error_to_screen = not (on == false) end
function logger.enable_echo_screen(on)  logger.echo_to_screen  = not (on == false) end

-- emitters
function logger.debug(fmt, ...) _emit("DEBUG", logger.color_debug, fmt, ...) end
function logger.info(fmt,  ...) _emit("INFO",  logger.color_info,  fmt, ...) end
function logger.warn(fmt,  ...) _emit("WARN",  logger.color_warn,  fmt, ...) end
function logger.error(fmt, ...) _emit("ERROR", logger.color_error, fmt, ...) end
function logger.echo(fmt,  ...) _emit("ECHO",  logger.color_echo,  fmt, ...) end

return logger
