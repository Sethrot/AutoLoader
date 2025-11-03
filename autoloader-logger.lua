-- libs/autoloader-logger.lua
-- Quiet, size-rotating logger for Windower/GearSwap.
-- - Writes to: GearSwap/data/autoloader/log/autoloader.log
-- - Rotates to: GearSwap/data/autoloader/log/autoloader-YYYYMMDD-HHMMSS.log
-- - Keeps at most N files total (current + rotated). Default 5.
-- - File logging is ALWAYS on; screen output is per-level toggle.
-- - Lua 5.1-safe.

local logger = {}

-- =====================
-- Config (defaults)
-- =====================
logger.prefix            = "[AutoLoader]"

-- Size rotation & retention
logger.max_bytes         = 1024 * 1024        -- ~1 MiB per file before rotate
logger.max_files         = 5                  -- total, including current autoloader.log

-- On-screen toggles (file logging ALWAYS on)
logger.debug_to_screen   = false
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

-- =====================
-- Internal state
-- =====================
local _dir, _current_path, _manifest_path
local _fh, _size = nil, 0
local _wrote_header = false

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

local function _nowstamp()  return os.date("%H:%M:%S") end
local function _tsfile()    return os.date("%Y%m%d-%H%M%S") end
local function _norm(p)     return tostring(p or ""):gsub("\\","/") end

local function _resolve_gearswap_data_dir()
  local addon_base = _norm((windower and windower.addon_path) or "./")
  local addons_root = addon_base:match("^(.-/addons/)")
  if not addons_root then
    local root = addon_base:match("^(.-/)") or "./"
    addons_root = root .. "addons/"
  end
  return addons_root .. "GearSwap/data/"
end

local function _ensure_dir(path)
  if windower and windower.create_dir then
    pcall(windower.create_dir, path)
  end
end

local function _open_append(path)
  local f = io.open(path, "ab")
  if f then
    -- find current size once; then track in-memory
    local ok, pos = pcall(function() return f:seek("end") end)
    _size = (ok and pos) or 0
  end
  return f
end

local function _write_manifest(list)
  local ok = pcall(function()
    local f = io.open(_manifest_path, "w")
    if not f then error("manifest open fail") end
    for i = 1, #list do f:write(list[i], "\n") end
    f:close()
  end)
  return ok
end

local function _read_manifest()
  local list, ok = {}, false
  local f = io.open(_manifest_path, "r")
  if f then
    for line in f:lines() do
      local s = line:gsub("%s+$", "")
      if s ~= "" then list[#list+1] = s end
    end
    f:close(); ok = true
  end
  return list, ok
end

local function _rotate_if_needed(incoming_len)
  incoming_len = tonumber(incoming_len or 0) or 0
  if (_size + incoming_len) < logger.max_bytes then
    return -- no rotation necessary
  end

  -- Close current handle so Windows lets us rename.
  if _fh then pcall(function() _fh:flush(); _fh:close() end) end
  _fh = nil

  -- Compute rotated name and rename current to it.
  local rotated = ("autoloader-%s.log"):format(_tsfile())
  local rotated_path = _dir .. rotated
  pcall(os.rename, _current_path, rotated_path)

  -- Update manifest & prune to keep (max_files - 1) rotated files
  local list = select(1, _read_manifest())
  list[#list+1] = rotated
  -- If we must keep at most logger.max_files total INCLUDING the current file,
  -- then we keep at most (max_files - 1) rotated names in the manifest:
  while #list > math.max(0, (logger.max_files or 5) - 1) do
    local victim = table.remove(list, 1) -- oldest
    pcall(os.remove, _dir .. victim)
  end
  _write_manifest(list)

  -- Recreate current file and reopen
  _fh = _open_append(_current_path)
  _size = 0
  _wrote_header = false
end

local function _ensure_open()
  if _fh then return end

  local data_dir  = _resolve_gearswap_data_dir()
  local base_dir  = data_dir .. "autoloader/"
  _dir            = base_dir .. "log/"
  _ensure_dir(data_dir); _ensure_dir(base_dir); _ensure_dir(_dir)

  _current_path   = _dir .. "autoloader.log"
  _manifest_path  = _dir .. "manifest.txt"

  _fh = _open_append(_current_path)
  if not _fh then
    -- Last-ditch: try to create directories again and re-open
    _ensure_dir(_dir)
    _fh = _open_append(_current_path)
  end
end

local function _maybe_header()
  if _wrote_header then return end
  _wrote_header = true
  local banner = ("===== %s session start %s ====="):format(logger.prefix, os.date("%Y-%m-%d %H:%M:%S"))
  local line = ("[%s] %s"):format(_nowstamp(), banner)
  if _fh then
    _fh:write(line, "\n"); _size = _size + #line + 1
  end
end

local function _append_line(line)
  _ensure_open()
  if not _fh then return end

  -- Rotate BEFORE writing, based on the exact incoming length.
  _rotate_if_needed(#line + 12) -- rough timestamp + bracket cost

  -- Write and advance size
  _fh:write(("[%s] %s\n"):format(_nowstamp(), line))
  _size = _size + #line + 12 -- keep it simple; exact byte count not critical
  _fh:flush()                -- keep data durable in case of crash
end

local function _emit(level, color, fmt, ...)
  _ensure_open()
  _maybe_header()

  local body = _fmt(fmt, ...)
  local line = ("%s [%s] %s"):format(logger.prefix, level, body)

  -- FILE: always on
  _append_line(line)

  -- SCREEN: per-level toggles
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
function logger.set_max_bytes(n) logger.max_bytes = tonumber(n) or logger.max_bytes end
function logger.set_max_files(n) logger.max_files = math.max(1, tonumber(n) or logger.max_files) end

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

-- explicit flush/close (optional; GearSwap reload will drop the module anyway)
function logger.flush()
  if _fh then pcall(function() _fh:flush() end) end
end
function logger.close()
  if _fh then pcall(function() _fh:flush(); _fh:close() end); _fh = nil end
end

return logger