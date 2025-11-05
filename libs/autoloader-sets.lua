local autoloader = rawget(_G, 'autoloader') or error('autoloader not initialized')

local utils = require("autoloader-utils")
local resolver = require("autoloader-resolver")

local sets = {}

local _root = _root or (windower and windower.addon_path) or "."

local _cache = {}

local function get_exported_file_prefix()
  return windower.ffxi.get_player().name .. "_"
end

local function get_directory(dir)
  utils.ensure_dir(dir)
  return windower.get_dir(dir)
end

local function list_files(dir)
  dir = utils.normalize_path(dir)
  local entries = get_directory(dir)
  autoloader.logger.debug("list_files() under " .. dir)

  local files = {}
  for _, name in ipairs(entries) do
    if name:sub(-1) ~= "/" then
      files[#files + 1] = name
    end
  end
  table.sort(files)
  return files
end

local function list_folders(dir)
  autoloader.logger.debug("list_folders() under " .. dir)

  local entries = get_directory(dir)
  local folders = {}
  for _, name in ipairs(entries) do
    if name:sub(-1) == "/" then
      folders[#folders + 1] = name:sub(1, -2) -- strip trailing '/'
    end
  end

  table.sort(folders)
  return folders
end

local function get_export_path()
  return utils.join_paths(_root, ("data/export"))
end

local function get_subjob_path(subjob)
  return utils.join_paths(_root,
    ("data/autoloader/jobs/%s/%s"):format(windower.ffxi.get_player().main_job:lower(), (subjob or "default"):lower()))
end

local function get_auto_path()
  return utils.join_paths(_root, ("data/autoloader/auto"))
end

local function get_job_prefix()
  return windower.ffxi.get_player().main_job:lower() .. "."
end

local function get_exported_file_name(set_name)
  set_name = utils.ensure_prefix(set_name, get_job_prefix())
  return ("%s%s.lua"):format(get_exported_file_prefix(), set_name)
end

local function compile_table_expr(table_src, chunkname)
  -- returns a function that when called yields the table
  local code = "return " .. table_src
  if _G.loadstring then
    local fn, err = loadstring(code, chunkname or "@AutoLoader:table")
    if not fn then return nil, err end
    if setfenv then setfenv(fn, {}) end
    return fn, nil
  else
    return load(code, chunkname or "@AutoLoader:table", "t", {})
  end
end

local function load_set(abs_filename)
  if not windower.file_exists(abs_filename) then
    autoloader.logger.debug("load_set() file: " .. filename .. " does not exist.")
    return
  end

  local f, ferr = io.open(abs_filename, "rb")
  if not f then
    autoloader.logger.debug(("load_set() couldn't open file %s: %s"):format(filename, tostring(ferr)))
    return
  end

  local src = f:read("*a"); f:close()
  if not src or src == "" then
    autoloader.logger.debug("load_set() empty file: " .. filename)
    return
  end

  local normalized_content = src:lower()
  local anchor_pos, label

  -- Prefer a top-level 'return { ... }'
  anchor_pos = normalized_content:find("return%s*%{")
  if anchor_pos then
    label = "return"
  else
    -- Then try 'sets.exported = { ... }'
    anchor_pos = normalized_content:find("sets%s*%.%s*exported%s*=%s*%{")
    if anchor_pos then
      label = "sets.exported"
    else
      -- Finally, 'sets = { ... }'
      anchor_pos = normalized_content:find("sets%s*=%s*%{")
      if anchor_pos then
        label = "sets"
      end
    end
  end

  if not anchor_pos then
    autoloader.logger.debug(("Couldn't parse %s, no table anchor (return/sets.exported/sets) found"):format(filename))
    return
  end

  local brace_pos = normalized_content:find("%{", anchor_pos)
  if not brace_pos then
    autoloader.logger.debug(("Couldn't parse %s, anchor without opening brace"):format(filename))
    return
  end

  local table_src = utils.slice_balanced_braces(src, brace_pos)
  if not table_src then
    autoloader.logger.debug(("Couldn't parse %s, unbalanced braces"):format(filename))
    return
  end

  local fn, cerr = compile_table_expr(table_src, "@AutoLoader:" .. (filename or "set"))
  if not fn then
    autoloader.logger.debug(("%s compilation failed: %s"):format(filename, tostring(cerr)))
    return
  end

  local ok, result = pcall(fn)
  if not ok then
    autoloader.logger.debug(("%s evaluation failed: %s"):format(filename, tostring(result)))
    return
  end

  if result == nil then
    autoloader.logger.debug(("Loaded %s (%s) but it produced nil"):format(filename, label or "?"))
  else
    autoloader.logger.debug(("Loaded %s (%s)"):format(filename, label or "?"))
  end
end

function sets.build_set(...)
  local args = { ... }

  -- convenience: allow a single table { "a","b","c" }
  if #args == 1 and type(args[1]) == "table" then
    args = args[1]
  end

  local combined, count = nil, 0
  for i, name in ipairs(args) do
    local n = utils.normalize_set_name(name)
    local part = sets.get(n)
    if type(part) == "table" then
      combined = (combined == nil) and part or set_combine(combined or {}, part or {})
      count = count + 1
      autoloader.logger.debug(("BuildSet: added %s"):format(n))
    else
      if part == nil then
        autoloader.logger.debug(("BuildSet: not found %s"):format(n))
      else
        autoloader.logger.debug(("BuildSet: %s returned %s; skipped"):format(n, type(part)))
      end
    end
  end

  if not combined then
    autoloader.logger.debug("BuildSet: no sets resolved")
    return nil
  end

  autoloader.logger.debug(("BuildSet: combined %d set(s)"):format(count))
  return combined
end

function sets.get(name)
  if not name or type(name) ~= "string" then return nil end

  name = utils.normalize_set_name(name)
  local filename = ("%s%s%s.lua"):format(get_exported_file_prefix(), get_job_prefix(), name)
  autoloader.logger.debug(("Looking for file: %s"):format(filename))

  -- Return cached set
  if _cache and _cache[name] then return _cache[name] end

  -- Try to load set from current job/subjob path
  local job, current_subjob = windower.ffxi.get_player().main_job:lower(), windower.ffxi.get_player().sub_job:lower()
  local subjob_file = utils.join_paths(get_subjob_path(current_subjob), filename)
  autoloader.logger.debug("Looking in " .. subjob_file)
  local set = windower.file_exists(subjob_file) and load_set(subjob_file)
  if set then
    _cache[name] = set
    return _cache[name]
  end

  -- Try to load set from current job/other subjob path
  -- Enumerate folders under data/autoloader/jobs/<job>/
  local base = utils.join_paths(_root, "data/autoloader/jobs")
  local main_job_dir = utils.join_paths(base, windower.ffxi.get_player().main_job:lower())
  local subjob_folders = list_folders(main_job_dir)
  for _, subjob in ipairs(subjob_folders) do
    if subjob ~= current_subjob then
      local fallback_file = utils.join_paths(get_subjob_path(subjob), filename)
      autoloader.logger.debug("Looking in " .. fallback_file)
      local fallback_set = windower.file_exists(fallback_file) and load_set(fallback_file)
      if fallback_set then
        _cache[name] = fallback_set
        return _cache[name]
      end
    end
  end

  -- Try to load set from auto-generated folder
  local auto_file = utils.join_paths(get_auto_path(), filename)
  autoloader.logger.debug("Looking in " .. auto_file)
  local auto_set = windower.file_exists(auto_file) and load_set(auto_file)
  if auto_set then
    _cache[name] = auto_set
    return _cache[name]
  end

  return
end

function sets.save(name, path)
  if not name then return false, "sets.save() name is required." end

  local resolved_name = resolver.resolve_save_set(name)
  local exported_filename = get_exported_file_name(resolved_name)
  local exported_file = utils.join_paths(get_export_path(), exported_filename)

  if windower.file_exists(exported_file) then
    utils.remove_file(exported_file)
    autoloader.logger.debug("Deleted existing file: " .. exported_file)
  end

  local gearswap_export_cmd = ('gs export filename %s%s'):format(get_job_prefix(), resolved_name)
  autoloader.logger.debug(("Exporting via GearSwap: %s"):format(gearswap_export_cmd))
  windower.send_command(gearswap_export_cmd)

  utils.await_file(exported_file, { every = 0.10, timeout = 1.0 },
    function()
      autoloader.logger.debug("Found export: " .. exported_file)
      if not windower.file_exists(exported_file) then
        autoloader.logger.error(("Could not find exported file: %s"):format(exported_file))
        return
      end

      local target_file = utils.join_paths(path or get_subjob_path(windower.ffxi.get_player().sub_job), exported_filename)
      autoloader.logger.debug(("Moving export to: %s"):format(target_file))

      return utils.move_file(exported_file, target_file)
    end,
    function()
        autoloader.logger.error(("Could not find exported file: %s"):format(exported_file))
    end
  )
end

function sets.delete(name)
end

function sets.get_weapons()
  local weapons = {}
  -- TODO

  return weapons
end

function sets.clear_cache()
  _cache = {}
  autoloader.logger.debug("Cache cleared.")
end

return sets
