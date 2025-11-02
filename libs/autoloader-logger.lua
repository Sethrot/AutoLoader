-- Minimal, configurable logger for GearSwap/Windower (Lua 5.2).
-- API: debug, info, error, say, echo, configure, set_prefix, set_debug, set_info, set_echo, set_colors, current_config

local logger = {}

-- ----- configuration (defaults) -----
local _cfg = {
  prefix        = "[AutoLoader]",  -- shown in chat + echo
  debug_enabled = true,            -- gate debug lines
  info_enabled  = true,            -- gate info lines
  echo_enabled  = true,            -- gate echo()
  colors = {
    debug = 123,   -- teal-ish
    info  = 160,   -- muted light gray
    say   = 200,   -- white
    error = 167,   -- red
  },
}

-- ----- internals -----
local function fmt(msg, ...)
  if select("#", ...) == 0 then return tostring(msg) end
  local ok, out = pcall(string.format, tostring(msg), ...)
  return ok and out or tostring(msg)
end

local function add_to_chat(color, text)
  color = tonumber(color) or 200
  if _G.windower and windower.add_to_chat then
    windower.add_to_chat(color, text)
  else
    print(text)
  end
end

local function do_echo(text)
  if not _cfg.echo_enabled then return end
  local safe = tostring(text):gsub("[\r\n]", " ")
  if _G.windower and windower.send_command then
    windower.send_command(('input /echo %s'):format(safe))
  else
    print(("[ECHO] %s"):format(safe))
  end
end

local function with_prefix(body)
  if _cfg.prefix and _cfg.prefix ~= "" then
    return ("%s %s"):format(_cfg.prefix, body)
  end
  return body
end

-- ----- public api -----
function logger.debug(msg, ...)
  if not _cfg.debug_enabled then return end
  add_to_chat(_cfg.colors.debug, with_prefix(fmt(msg, ...)))
end

function logger.info(msg, ...)
  if not _cfg.info_enabled then return end
  add_to_chat(_cfg.colors.info, with_prefix(fmt(msg, ...)))
end

-- ALWAYS visible (no color override param)
function logger.say(msg, ...)
  add_to_chat(_cfg.colors.say, with_prefix(fmt(msg, ...)))
end

function logger.error(msg, ...)
  add_to_chat(_cfg.colors.error, with_prefix(fmt(msg, ...)))
end

function logger.echo(msg, ...)
  do_echo(with_prefix(fmt(msg, ...)))
end

-- ----- configuration helpers -----
function logger.configure(opts)
  if type(opts) ~= "table" then return logger end
  if opts.prefix        ~= nil then _cfg.prefix        = tostring(opts.prefix) end
  if opts.debug_enabled ~= nil then _cfg.debug_enabled = not not opts.debug_enabled end
  if opts.info_enabled  ~= nil then _cfg.info_enabled  = not not opts.info_enabled end
  if opts.echo_enabled  ~= nil then _cfg.echo_enabled  = not not opts.echo_enabled end
  if type(opts.colors)  == "table" then
    for k, v in pairs(opts.colors) do
      if _cfg.colors[k] ~= nil then _cfg.colors[k] = tonumber(v) or _cfg.colors[k] end
    end
  end
  return logger
end

function logger.set_prefix(p)   _cfg.prefix = tostring(p or "") ; return logger end
function logger.set_debug(b)    _cfg.debug_enabled = not not b  ; return logger end
function logger.set_info(b)     _cfg.info_enabled  = not not b  ; return logger end
function logger.set_echo(b)     _cfg.echo_enabled  = not not b  ; return logger end
function logger.set_colors(t)
  if type(t) == "table" then
    for k, v in pairs(t) do
      if _cfg.colors[k] ~= nil then _cfg.colors[k] = tonumber(v) or _cfg.colors[k] end
    end
  end
  return logger
end

function logger.current_config()
  local copy = {
    prefix        = _cfg.prefix,
    debug_enabled = _cfg.debug_enabled,
    info_enabled  = _cfg.info_enabled,
    echo_enabled  = _cfg.echo_enabled,
    colors        = {},
  }
  for k, v in pairs(_cfg.colors) do copy.colors[k] = v end
  return copy
end

return logger
