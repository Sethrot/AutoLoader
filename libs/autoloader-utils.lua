require("lists")

local utils = {}

function utils.call_hook(name, stub, ...)
  local fn = rawget(_G, name)
  if type(fn) == "function" and fn ~= stub then
    local ok, result = pcall(fn, ...)
    if not ok then
      autoloader.logger.error("Hook '" .. name .. "' failed: " .. tostring(result))
      return nil, result
    end
    return result
  end

  return nil
end

function utils.get_keys(map)
  local keys, i = L {}
  for k in pairs(map or {}) do
    keys:append(k)
  end
  return keys
end

function utils.get_keys_sorted(map)
  return utils.get_keys(map):sort()
end

function utils.split3_by_dot(s)
  local a,b,c = s:match("^([^%.]+)%.([^%.]+)%.(.+)$")
  if a then return a,b,c end
  a,b = s:match("^([^%.]+)%.(.+)$")
  if a then return a,b,nil end
  return s,nil,nil
end

function utils.split_args(cmd)
    return cmd:match("^%s*(%S+)%s*(.*)$")
end

function utils.escape_lua_pattern(s)
  return (tostring(s or ""):gsub("(%W)", "%%%1"))
end

function utils.join_paths(a, b)
  if a:sub(-1) == "/" then return a .. b end
  return a .. "/" .. b
end

function utils.slice_balanced_braces(s, open_pos)
  -- returns substring from the opening '{' at open_pos through its matching '}'
  local i, n = open_pos, #s
  local depth = 0
  local in_s, in_d = false, false
  local esc = false
  local in_line_comment, in_block_comment = false, false

  while i <= n do
    local c  = s:sub(i, i)
    local c2 = (i < n) and s:sub(i, i + 1) or ""

    if in_line_comment then
      if c == "\n" then in_line_comment = false end
    elseif in_block_comment then
      if c2 == "]]" then
        in_block_comment = false; i = i + 1
      end
    elseif in_s then
      if esc then
        esc = false
      elseif c == "\\" then
        esc = true
      elseif c == "'" then
        in_s = false
      end
    elseif in_d then
      if esc then
        esc = false
      elseif c == "\\" then
        esc = true
      elseif c == '"' then
        in_d = false
      end
    else
      -- not in string/comment
      if c2 == "--" then
        -- long comment?
        local c4 = (i + 3 <= n) and s:sub(i + 2, i + 3) or ""
        if c4 == "[[" then
          in_block_comment = true
          i = i + 3
        else
          in_line_comment = true
          i = i + 1
        end
      elseif c == "'" then
        in_s = true
      elseif c == '"' then
        in_d = true
      elseif c == '{' then
        depth = depth + 1
        if depth == 1 then open_pos = i end
      elseif c == '}' then
        depth = depth - 1
        if depth == 0 then
          return s:sub(open_pos, i)
        end
      end
    end

    i = i + 1
  end

  return nil -- unbalanced
end

function utils.get_directory_name(path)
  return path:match("^(.*)/[^/]+$") or "."
end

function utils.normalize_path(p)
  p = tostring(p or ""):gsub("[\r\n\t]", "")
  p = p:gsub("\\", "/"):gsub("/+", "/")
  if p ~= "" and p:sub(-1) ~= "/" then p = p .. "/" end
  return p
end

function utils.ensure_dir(dir)
  -- Windows 'mkdir' is idempotent (succeeds if already exists)
  os.execute(string.format('mkdir "%s"', dir))
  return true
end

function utils.remove_file(path)
  if windower.file_exists(path) then
    os.remove(path)
  end
end

function utils.wait_for_file(path, timeout_s, period_s, on_ready, on_timeout)
  path      = tostring(path or '')
  timeout_s = tonumber(timeout_s) or 3.0
  period_s  = tonumber(period_s)  or 0.10

  local deadline = os.clock() + timeout_s

  local function step()
    if windower.file_exists(path) then
      if autoloader and autoloader.logger and autoloader.logger.debug then
      end
      if on_ready then pcall(on_ready, path) end
      return
    end

    if os.clock() >= deadline then
      if on_timeout then pcall(on_timeout, path) end
      return
    end

    coroutine.schedule(step, period_s)
  end

  step() -- kick off
end

function utils.move_file(src, dst)
  utils.ensure_dir(utils.get_directory_name(dst))
  utils.remove_file(dst)
  local ok = os.rename(src, dst)
  if ok then return true, nil end

  local in_f = io.open(src, "rb"); if not in_f then return false, "Could not open file: " .. src end
  local data = in_f:read("*a"); in_f:close()
  local out_f, e = io.open(dst, "wb"); if not out_f then return false, e end
  out_f:write(data); out_f:close()
  os.remove(src)
  return true, nil
end

function utils.starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function utils.starts_with_any(s, prefixes)
  if prefixes == nil then return false end
  -- single string
  if type(prefixes) == "string" then
    return utils.starts_with(s, prefixes), prefixes
  end

  -- list/array: prefer numeric 1..n iteration so order is preserved
  local n = (type(prefixes) == "table" and (prefixes.n or #prefixes)) or 0
  for i = 1, n do
    local p = prefixes[i]
    if type(p) == "string" and utils.starts_with(s, p) then
      return true, p
    end
  end

  -- fallback for non-array tables (if someone passed a set-like table)
  for _, p in pairs(prefixes) do
    if type(p) == "string" and utils.starts_with(s, p) then
      return true, p
    end
  end

  return false
end

function utils.ends_with(s, suffix)
  return s:sub(-#suffix) == suffix
end

function utils.ensure_prefix(s, prefix)
  s = tostring(s or "")
  prefix = tostring(prefix or "")
  if prefix == "" then return s end

  if utils.starts_with(s, prefix) then return s end

  return prefix .. s
end

function utils.ensure_suffix(s, suffix)
  s = tostring(s or "")
  suffix = tostring(suffix or "")
  if suffix == "" then return s end

  if utils.ends_with(s, suffix) then return s end

  return s .. suffix
end

function utils.get_array_values(array)
  local values = L {}

  if type(array) ~= 'table' then return values end
  for i = 1, #array do values:append(array[i]) end

  return values
end

function utils.get_mode_options(mode)
  return utils.get_array_values(mode and (mode.options or mode))
end

function utils.ascii_only(s)
  s = tostring(s or ""):gsub("[\r\n]", " ")
  s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
  return s
end

function utils.print_help_topic(topic)
    if not topic then return end

    print(topic.title .. " — " .. (topic.desc or ""))
    if topic.usage and #topic.usage > 0 then
        print("Usage:"); for i = 1, #topic.usage do print(topic.usage[i]) end
    end
    if topic.params and #topic.params > 0 then
        print("Params:"); for i = 1, #topic.params do print(topic.params[i]) end
    end
    if topic.examples and #topic.examples > 0 then
        print("Examples:"); for i = 1, #topic.examples do print(topic.examples[i]) end
    end
    if topic.dynamic then
        local ok, dyn = pcall(topic.dynamic); if ok and dyn and dyn ~= "" then print(dyn) end
    end
end

function utils.sanitize(name)
    return (tostring(name or ""):gsub("'", ""):gsub("%s+", "_"):lower())
end

local function get_sanitized_name_parts(name)
    return utils.split3_by_dot(utils.sanitize(name))
end
function utils.sanitize_set_name(name)
    if not name then return nil, "Name is required." end

    local p1, p2, p3 = get_sanitized_name_parts(name)
    if not p1 then return nil, "Invalid name: " .. name end

    return utils.sanitize(name), nil
end

return utils
