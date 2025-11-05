include("Modes")

local logger = {}

local _VERBOSITY = { OFF = "off", ERROR = "error", INFO = "info", DEBUG = "debug" }
local _verbosity_level = {
  [_VERBOSITY.OFF] = 0,
  [_VERBOSITY.ERROR] = 1,
  [_VERBOSITY.INFO] = 2,
  [_VERBOSITY.DEBUG] = 3
}
local _verbosity_display = {
  [_VERBOSITY.OFF] = "Off",
  [_VERBOSITY.ERROR] = "ERROR",
  [_VERBOSITY.INFO] = "",
  [_VERBOSITY.DEBUG] = "Debug",
}

logger.options = {
  prefix = "[AutoLoader]",
  verbosity = _VERBOSITY.DEBUG, -- TODO: For dev only
  color = 207,
  max_chars_per_line = 80,
}
logger.mode = M { ["description"] = "Log", _VERBOSITY.OFF, _VERBOSITY.ERROR, _VERBOSITY.INFO, _VERBOSITY.DEBUG }

-- TODO: try getting from file settings
logger.mode:set(logger.options.verbosity)

local function word_wrap(msg)
  local out, line, len, limit = {}, "", 0, logger.options.max_chars_per_line
  for word, sep in msg:gmatch("(%S+)(%s*)") do
    local wlen = #word
    if len > 0 and (len + 1 + wlen) > limit then
      out[#out + 1] = line
      line, len = word, wlen
    else
      if len > 0 then
        line, len = (line .. " " .. word), (len + 1 + wlen)
      else
        line, len = word, wlen
      end
    end
    -- if a single word is longer than limit, hard-split it
    while len > limit do
      out[#out + 1] = line:sub(1, limit)
      line          = line:sub(limit + 1)
      len           = #line
    end
  end
  if len > 0 then out[#out + 1] = line end
  return out
end

local function format_message(tag, msg, color)
  if windower and windower.add_to_chat then
    local sanitized = msg
        :gsub("[\r\n\t]", " ")    -- normalize line breaks/tabs to space
        :gsub("\194\160", " ")    -- non-breaking space (UTF-8) -> space (optional but handy)
        :gsub("[%z\1-\31\127]", "") -- strip control chars
        :gsub("%s+", " ")         -- collapse whitespace runs
        :gsub("^%s+", "")         -- trim left
        :gsub("%s+$", "")         -- trim right

    local head = ("%s%s "):format(logger.options.prefix, (tag and tag ~= "" and "(" .. tag .. ")") or "")
    local lines = word_wrap(sanitized)

    for i = 1, #lines do
      local line = head .. lines[i]
        windower.add_to_chat(color, line)
    end
    return true, nil
  else
    return false, logger.options.prefix .. " Log failure: windower.add_to_chat not available."
  end
end

function logger.info(msg, force)
  if force or _verbosity_level[logger.mode.current] >= _verbosity_level[_VERBOSITY.INFO] then
    format_message((force and "") or _verbosity_display[_VERBOSITY.INFO], msg, logger.options.color)
  end
end

function logger.debug(msg)
  if _verbosity_level[logger.mode.current] >= _verbosity_level[_VERBOSITY.DEBUG] then
    format_message(_verbosity_display[_VERBOSITY.DEBUG], msg, 161)
  end
end

function logger.error(msg)
  if _verbosity_level[logger.mode.current] >= _verbosity_level[_VERBOSITY.ERROR] then
    local ok, err = format_message(_verbosity_display[_VERBOSITY.ERROR], msg, 39)
    if not ok then
      print(err)
    end
  end
end

function logger.export_to_file(path)
  logger.error("logger.export_to_file not yet implemented.")
end

return logger
