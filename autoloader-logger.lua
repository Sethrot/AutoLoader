-- libs/autoloader-logger.lua
-- Rotating Logger for Windower/GearSwap (Lua 5.1-safe).
--
-- Changes from time-based pruning:
--   • Size-based rotation: create a NEW file once current file ≥ max_bytes.
--   • Keep at most max_files log files (default 5); delete oldest on overflow.
--   • Files are timestamped: autoloader-YYYY-MM-DD_HH-MM-SS.log
--
-- Behavior:
--   • Always writes to: addons/GearSwap/data/autoloader/log/<timestamped>.log
--   • On-screen output can be toggled per level; file logging never stops.
--   • Safe to use without explicit init(); lazy-initializes on first write.
--
-- Public API (compatible with prior version + a few additions):
--   logger.set_prefix(p)
--   logger.enable_debug_screen(on)  logger.enable_info_screen(on)
--   logger.enable_warn_screen(on)   logger.enable_error_screen(on)
--   logger.enable_echo_screen(on)
--   logger.debug(fmt, ...)          logger.info(fmt, ...)
--   logger.warn(fmt, ...)           logger.error(fmt, ...)
--   logger.echo(fmt, ...)
--   -- New (optional):
--   logger.init({ max_files=?, max_bytes=?, base=? , debug_to_screen=?, ... })
--   logger.set_max_files(n)         logger.set_max_bytes(n)
--   logger.set_chat(level, on)      -- level in {"debug","info","warn","error","echo"}
--
local logger = {}

-- =====================
-- Config (defaults)
-- =====================
logger.prefix            = "[AutoLoader]"

-- On-screen toggles (file logging always on)
logger.debug_to_screen   = false  -- default OFF (chatty)
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

-- Rotation controls
logger.max_files         = 5                 -- keep at most 5 files
logger.max_bytes         = 1024 * 1024      -- 1 MiB per file (recommendation)
logger.base              = "autoloader"     -- filename base: <base>-<stamp>.log

-- Internal state
local _file, _file_path, _bytes = nil, nil, 0
local _dir,  _index_path        = nil, nil
local _announced_path           = false
local _file_failed_once         = false
local _index                    = {}         -- list of filenames (oldest..newest)
local _inited                   = false

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

local function _norm(p) return tostring(p or ""):gsub("\\","/") end
local function _path_join(a,b)
  if not a or a == "" then return b end
  local last = a:sub(-1)
  if last == "/" or last == "\\" then return a .. b end
  return a .. "/" .. b
end

local function _stamp_file() return os.date("%Y-%m-%d_%H-%M-%S") end
local function _nowstamp()   return os.date("%H:%M:%S") end

-- e.g., "<...>/addons/<anyAddon>/" -> "<...>/addons/GearSwap/data/"
local function _resolve_gearswap_data_dir()
  local addon_base = _norm((windower and windower.addon_path) or "./")
  local addons_root = addon_base:match("^(.-/addons/)")
  if not addons_root then
    addons_root = (addon_base:match("^(.-/)") or "./") .. "addons/"
  end
  return _path_join(addons_root, "GearSwap/data/")
end

local function _ensure_dir(path)
  if not path or path == "" then return end
  if windower and windower.create_dir then
    pcall(windower.create_dir, path)
  end
  -- If windower.create_dir is not available, we rely on directories already existing.
end

-- Simple index file of filenames (one per line) to avoid directory scans.
local function _save_index()
  if not _index_path then return end
  local f = io.open(_index_path, "w")
  if not f then return end
  for i = 1, #_index do
    f:write(_index[i], "\n")
  end
  f:close()
end

local function _load_index()
  _index = {}
  if not _index_path then return end
  local f = io.open(_index_path, "r")
  if not f then return end
  for line in f:lines() do
    if line and line ~= "" then _index[#_index+1] = line end
  end
  f:close()
end

local function _announce_once(path)
  if _announced_path then return end
  _announced_path = true
  _chat(logger.color_info, ("%s [INFO] logging to %s"):format(logger.prefix, path))
end

local function _open_new_file()
  -- Close prior handle
  if _file then pcall(_file.close, _file) end

  local fname = string.format("%s-%s.log", logger.base, _stamp_file())
  _file_path  = _path_join(_dir, fname)
  _file       = io.open(_file_path, "w")
  _bytes      = 0
  if not _file then
    if not _file_failed_once then
      _file_failed_once = true
      _chat(logger.color_warn, ("%s [WARN] could not open log file: %s"):format(logger.prefix, tostring(_file_path)))
    end
    return
  end

  -- Track in index and prune if necessary
  _index[#_index+1] = fname
  while #_index > (tonumber(logger.max_files) or 5) do
    local oldest = table.remove(_index, 1)
    if oldest and oldest ~= "" then
      pcall(os.remove, _path_join(_dir, oldest))
    end
  end
  _save_index()

  -- Session banner
  local banner = ("===== %s session start %s ====="):format(logger.prefix, os.date("%Y-%m-%d %H:%M:%S"))
  _file:write(("[%s] %s\n"):format(_nowstamp(), banner))
  _file:flush()
  _bytes = _bytes + #banner + 12  -- rough accounting is fine here

  _announce_once(_file_path)
end

local function _rotate_if_needed()
  local cap = tonumber(logger.max_bytes) or (1024*1024)
  if (_bytes or 0) >= cap then
    _open_new_file()
  end
end

local function _ensure_ready()
  if _inited then return end
  -- Resolve directories & index path
  local data_dir = _resolve_gearswap_data_dir()                -- abs
  local base_dir = _path_join(data_dir, "autoloader")
  local log_dir  = _path_join(base_dir, "log")

  _ensure_dir(data_dir)
  _ensure_dir(base_dir)
  _ensure_dir(log_dir)

  _dir        = log_dir
  _index_path = _path_join(_dir, logger.base .. ".idx")
  _load_index()
  _open_new_file()
  _inited = true
end

local function _write_line(line)
  _ensure_ready()
  if not _file then return end
  local rec = ("[%s] %s\n"):format(_nowstamp(), line)
  _file:write(rec)
  _file:flush()
  _bytes = _bytes + #rec
  _rotate_if_needed()
end

local function _emit(level, color, fmt, ...)
  local body = _fmt(fmt, ...)
  local text = ("%s [%s] %s"):format(logger.prefix, level, body)

  _write_line(text)

  -- On-screen (optional)
  local show = true
  if     level == "DEBUG" then show = not not logger.debug_to_screen
  elseif level == "INFO"  then show = not not logger.info_to_screen
  elseif level == "WARN"  then show = not not logger.warn_to_screen
  elseif level == "ERROR" then show = not not logger.error_to_screen
  elseif level == "ECHO"  then show = not not logger.echo_to_screen
  end
  if show then _chat(color, text) end
end

-- =====================
-- Public API
-- =====================

-- Optional initializer to tweak defaults in one shot
function logger.init(opts)
  opts = opts or {}
  if opts.prefix ~= nil then logger.prefix = tostring(opts.prefix) end

  if opts.debug_to_screen ~= nil then logger.debug_to_screen = not not opts.debug_to_screen end
  if opts.info_to_screen  ~= nil then logger.info_to_screen  = not not opts.info_to_screen  end
  if opts.warn_to_screen  ~= nil then logger.warn_to_screen  = not not opts.warn_to_screen  end
  if opts.error_to_screen ~= nil then logger.error_to_screen = not not opts.error_to_screen end
  if opts.echo_to_screen  ~= nil then logger.echo_to_screen  = not not opts.echo_to_screen  end

  if opts.color_debug ~= nil then logger.color_debug = tonumber(opts.color_debug) or logger.color_debug end
  if opts.color_info  ~= nil then logger.color_info  = tonumber(opts.color_info ) or logger.color_info  end
  if opts.color_warn  ~= nil then logger.color_warn  = tonumber(opts.color_warn ) or logger.color_warn  end
  if opts.color_error ~= nil then logger.color_error = tonumber(opts.color_error) or logger.color_error end
  if opts.color_echo  ~= nil then logger.color_echo  = tonumber(opts.color_echo ) or logger.color_echo  end

  if opts.max_files   ~= nil then logger.max_files  = tonumber(opts.max_files) or logger.max_files end
  if opts.max_bytes   ~= nil then logger.max_bytes  = tonumber(opts.max_bytes) or logger.max_bytes end
  if opts.base        ~= nil then logger.base       = tostring(opts.base)       or logger.base end

  -- Re-init file/dir if already inited (e.g., after changing base or limits)
  _inited = false
  _ensure_ready()
  return logger
end

function logger.set_prefix(p) logger.prefix = tostring(p or logger.prefix) end

-- On-screen toggles
function logger.enable_debug_screen(on) logger.debug_to_screen = not (on == false) end
function logger.enable_info_screen(on)  logger.info_to_screen  = not (on == false) end
function logger.enable_warn_screen(on)  logger.warn_to_screen  = not (on == false) end
function logger.enable_error_screen(on) logger.error_to_screen = not (on == false) end
function logger.enable_echo_screen(on)  logger.echo_to_screen  = not (on == false) end

-- Limits
function logger.set_max_files(n)
  local v = tonumber(n)
  if v and v > 0 then
    logger.max_files = v
    -- prune immediately if needed
    if _inited and #_index > v then
      while #_index > v do
        local oldest = table.remove(_index, 1)
        if oldest and oldest ~= "" then pcall(os.remove, _path_join(_dir, oldest)) end
      end
      _save_index()
    end
  end
end

function logger.set_max_bytes(n)
  local v = tonumber(n)
  if v and v > 0 then
    logger.max_bytes = v
    -- trigger rotation if current file already exceeds
    if _inited and _bytes >= v then _open_new_file() end
  end
end

-- Fine-grain chat mirroring (levels: "debug","info","warn","error","echo")
function logger.set_chat(level, on)
  local lv = (tostring(level or ""):lower())
  if lv == "debug" then logger.debug_to_screen = not not on
  elseif lv == "info" then logger.info_to_screen = not not on
  elseif lv == "warn" then logger.warn_to_screen = not not on
  elseif lv == "error" then logger.error_to_screen = not not on
  elseif lv == "echo" then logger.echo_to_screen = not not on
  end
end

-- Emitters
function logger.debug(fmt, ...) _emit("DEBUG", logger.color_debug, fmt, ...) end
function logger.info(fmt,  ...) _emit("INFO",  logger.color_info,  fmt, ...) end
function logger.warn(fmt,  ...) _emit("WARN",  logger.color_warn,  fmt, ...) end
function logger.error(fmt, ...) _emit("ERROR", logger.color_error, fmt, ...) end
function logger.echo(fmt,  ...) _emit("ECHO",  logger.color_echo,  fmt, ...) end

return logger
