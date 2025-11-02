-- Cached retrieval, saving, deletion, and listing of Name_job.<set_name>.lua
-- Uses Windower player info to resolve Name/Job/SJ and searches:
--   jobs/<job>/<sj>/ -> other SJs (alphabetical, incl. 'default') -> auto/
-- Loading is sandboxed to avoid polluting globals; supports `return {...}` and `sets`/`sets.exported`.

local log = require('autoloader-logger')

local sets = {}

-- ---------- internals ----------
local _root  = nil
local _cache = {}   -- cache[abs_path] = content (or nil if a previous load failed)

local function join(a, b)
  if a:sub(-1) == "/" then return a .. b end
  return a .. "/" .. b
end

local function ensure_lua_ext(filename)
  if filename:lower():sub(-4) == ".lua" then return filename end
  return filename .. ".lua"
end

local function file_exists(path)
  if _G.windower and windower.file_exists then
    return windower.file_exists(path)
  end
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function get_dir(path)
  if _G.windower and windower.get_dir then
    return windower.get_dir(path) or {}
  end
  return {}
end

local function list_files(dir)
  local entries = get_dir(dir)
  local files = {}
  for _, name in ipairs(entries) do
    if name:sub(-1) ~= "/" then
      files[#files+1] = name
    end
  end
  table.sort(files)
  return files
end

local function list_subjobs(job)
  -- Enumerate subjob folders under data/autoloader/jobs/<job>/
  local base = join(_root, "data/autoloader/jobs")
  local job_dir = join(base, job)
  local entries = get_dir(job_dir)
  local sjs = {}
  for _, name in ipairs(entries) do
    if name:sub(-1) == "/" then
      sjs[#sjs+1] = name:sub(1, -2) -- strip trailing '/'
    end
  end
  table.sort(sjs)
  return sjs
end

local function get_player_ctx()
  if not (_G.windower and windower.ffxi and windower.ffxi.get_player) then
    return nil, "Windower player API unavailable"
  end
  local p = windower.ffxi.get_player()
  if not p then return nil, "Player not available yet" end
  local name = p.name or ""
  local job  = (p.main_job or ""):lower():sub(1,3)
  local sj   = (p.sub_job  or ""):lower():sub(1,3)
  if sj == "" or sj == "non" or sj == "nil" then sj = "default" end
  if name == "" or job == "" then return nil, "Missing name or job" end
  return { name = name, job = job, sj = sj }, nil
end

-- ----- helpers for parsing & compiling a single table literal -----

local function slice_balanced_braces(s, open_pos)
  -- returns substring from the opening '{' at open_pos through its matching '}'
  local i, n = open_pos, #s
  local depth = 0
  local in_s, in_d = false, false
  local esc = false
  local in_line_comment, in_block_comment = false, false

  while i <= n do
    local c  = s:sub(i,i)
    local c2 = (i < n) and s:sub(i, i+1) or ""

    if in_line_comment then
      if c == "\n" then in_line_comment = false end

    elseif in_block_comment then
      if c2 == "]]" then in_block_comment = false; i = i + 1 end

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
        local c4 = (i+3 <= n) and s:sub(i+2,i+3) or ""
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

-- ----- private: parse-only loader for first table in file (return {...} | sets.exported = {...} | sets = {...}) -----

local function load_set(abs_path)
  if _cache[abs_path] ~= nil then
    return _cache[abs_path], true
  end
  if not file_exists(abs_path) then
    return nil, false
  end

  local f, ferr = io.open(abs_path, "rb")
  if not f then
    log.error("Open error %s: %s", abs_path, tostring(ferr))
    _cache[abs_path] = nil
    return nil, false
  end
  local src = f:read("*a"); f:close()
  if not src or src == "" then
    log.debug("Empty file: %s", abs_path)
    _cache[abs_path] = nil
    return nil, false
  end

  local lower = src:lower()
  local anchor_pos, label

  -- Prefer a top-level 'return { ... }'
  anchor_pos = lower:find("return%s*%{")
  if anchor_pos then
    label = "return"
  else
    -- Then try 'sets.exported = { ... }'
    anchor_pos = lower:find("sets%s*%.%s*exported%s*=%s*%{")
    if anchor_pos then
      label = "sets.exported"
    else
      -- Finally, 'sets = { ... }'
      anchor_pos = lower:find("sets%s*=%s*%{")
      if anchor_pos then
        label = "sets"
      end
    end
  end

  if not anchor_pos then
    log.error("Parse error %s: no table anchor (return/sets.exported/sets) found", abs_path)
    _cache[abs_path] = nil
    return nil, false
  end

  local brace_pos = src:find("%{", anchor_pos)
  if not brace_pos then
    log.error("Parse error %s: anchor without opening brace", abs_path)
    _cache[abs_path] = nil
    return nil, false
  end

  local table_src = slice_balanced_braces(src, brace_pos)
  if not table_src then
    log.error("Parse error %s: unbalanced braces", abs_path)
    _cache[abs_path] = nil
    return nil, false
  end

  local fn, cerr = compile_table_expr(table_src, "@AutoLoader:" .. (abs_path or "set"))
  if not fn then
    log.error("Compile error %s: %s", abs_path, tostring(cerr))
    _cache[abs_path] = nil
    return nil, false
  end

  local ok, result = pcall(fn)
  if not ok then
    log.error("Eval error %s: %s", abs_path, tostring(result))
    _cache[abs_path] = nil
    return nil, false
  end

  if result == nil then
    log.debug("Loaded %s (%s) but it produced nil", abs_path, label or "?")
  else
    log.debug("Loaded %s (%s)", abs_path, label or "?")
  end

  _cache[abs_path] = result
  return result, false
end



local function probe_job_sj(job, sj, filename)
  local abs = join(_root, ("data/autoloader/jobs/%s/%s/%s"):format(job, sj, filename))

  if _cache[abs] ~= nil then
    log.debug("%s: Loaded %s from cache", sj:upper(), filename)
    return _cache[abs]
  end

  if not file_exists(abs) then
    log.debug("%s: Not found", sj:upper())
    return nil
  end

  local content, from_cache = load_set(abs)
  if content ~= nil then
    if from_cache then
      log.debug("%s: Loaded %s from cache", sj:upper(), filename)
    else
      log.debug("%s: Loaded %s", sj:upper(), filename)
    end
    return content
  end

  return nil
end

local function probe_auto(filename)
  local abs = join(_root, ("data/autoloader/auto/%s"):format(filename))

  if _cache[abs] ~= nil then
    log.debug("Auto: Loaded %s from cache", filename)
    return _cache[abs]
  end

  if not file_exists(abs) then
    log.debug("Auto: Not found")
    return nil
  end

  local content, from_cache = load_set(abs)
  if content ~= nil then
    if from_cache then
      log.debug("Auto: Loaded %s from cache", filename)
    else
      log.debug("Auto: Loaded %s", filename)
    end
    return content
  end

  return nil
end

-- ---------- filesystem helpers (save/move) ----------
local function dirname(path)
  return path:match("^(.*)/[^/]+$") or "."
end

local function ensure_dir(dir)
  -- Windows 'mkdir' is idempotent (succeeds if already exists)
  os.execute(string.format('mkdir "%s"', dir))
  return true
end

local function remove_file(path)
  if file_exists(path) then
    os.remove(path)
  end
end

local function move_file(src, dst)
  ensure_dir(dirname(dst))
  remove_file(dst)
  local ok = os.rename(src, dst)
  if ok then return true end
  -- fallback copy
  local in_f = io.open(src, "rb"); if not in_f then return false end
  local data = in_f:read("*a"); in_f:close()
  local out_f, e = io.open(dst, "wb"); if not out_f then return false, e end
  out_f:write(data); out_f:close()
  os.remove(src)
  return true
end

local function spin_sleep(sec)
  local t0 = os.clock()
  while os.clock() - t0 < sec do end
end

local function wait_for_file(path, timeout_s, poll_s)
  timeout_s = timeout_s or 3.0
  poll_s = poll_s or 0.1
  local t0 = os.clock()
  while os.clock() - t0 < timeout_s do
    if file_exists(path) then return true end
    spin_sleep(poll_s)
  end
  return false
end

local function build_export_path(ctx, set_name)
  local filename = ensure_lua_ext(("%s_%s.%s"):format(ctx.name, ctx.job, tostring(set_name)))
  return join(_root, ("data/export/%s"):format(filename)), filename
end

local function build_autoloader_path(ctx, set_name)
  local filename = ensure_lua_ext(("%s_%s.%s"):format(ctx.name, ctx.job, tostring(set_name)))
  return join(_root, ("data/autoloader/jobs/%s/%s/%s"):format(ctx.job, ctx.sj, filename)), filename
end

local function escape_lua_pattern(s)
  return (tostring(s or ""):gsub("(%W)","%%%1"))
end

local function set_name_from_filename(ctx, filename)
  local prefix = ("%s_%s."):format(ctx.name, ctx.job)
  if filename:sub(1, #prefix) ~= prefix then return nil end
  if filename:lower():sub(-4) ~= ".lua" then return nil end
  return filename:sub(#prefix + 1, -5)
end

local function extract_set_name_for_ctx(ctx, filename)
  return set_name_from_filename(ctx, filename)
end

-- ---------- public API ----------
function sets.init(root)
  _root = root or (windower and windower.addon_path) or "."
  _cache = {}
  log.debug("Storage initialized. Root: %s", _root)
end

function sets.reset_cache()
  _cache = {}
  log.debug("Cache cleared.")
end

-- get(set_name) -> returns set table or nil
-- set_name is normalized (e.g., "melee.acc")
function sets.get(set_name)
  assert(set_name and set_name ~= "", "[autoloader-sets.get] set_name is required")
  if not _root then sets.init() end

  local ctx, err = get_player_ctx()
  if not ctx then
    log.error("Cannot resolve player context: %s", err or "unknown")
    return nil
  end

  local filename = ensure_lua_ext(("%s_%s.%s"):format(ctx.name, ctx.job, tostring(set_name)))
  log.debug("Looking for file: %s", filename)

  -- 1) Current SJ
  local content = probe_job_sj(ctx.job, ctx.sj, filename)
  if content ~= nil then return content end

  -- 2) All other SJs (alphabetical, includes 'default')
  local sjs = list_subjobs(ctx.job)
  for _, other_sj in ipairs(sjs) do
    if other_sj ~= ctx.sj then
      local v = probe_job_sj(ctx.job, other_sj, filename)
      if v ~= nil then return v end
    end
  end

  -- 3) Auto fallback
  return probe_auto(filename)
end

function sets.cache_size()
  local n = 0
  for _ in pairs(_cache) do n = n + 1 end
  return n
end

-- Drives GearSwap export, waits for data/export file, moves to autoloader/jobs/<job>/<sj>/ (overwrite), invalidates cache.
function sets.save(set_name)
  assert(set_name and set_name ~= "", "[autoloader-sets.save] set_name is required")
  if not _root then sets.init() end

  local ctx, err = get_player_ctx()
  if not ctx then
    log.error("Cannot resolve player context for save: %s", err or "unknown")
    return { ok=false, err=err or "player context unavailable" }
  end

  local export_path, export_filename = build_export_path(ctx, set_name)
  local target_path,  target_filename  = build_autoloader_path(ctx, set_name)

  if file_exists(export_path) then
    log.debug("Deleting existing export: %s", export_filename)
    remove_file(export_path)
  end

  local gs_cmd = string.format('gs export filename %s.%s; wait 1; gs export', ctx.job, tostring(set_name))
  log.debug("Exporting via GearSwap: %s", gs_cmd)
  if _G.windower and windower.send_command then
    windower.send_command(gs_cmd)
  else
    log.error("Windower send_command not available; cannot export.")
    return { ok=false, err="send_command unavailable" }
  end

  local timeout_s, poll_s = 3.0, 0.1
  if not wait_for_file(export_path, timeout_s, poll_s) then
    log.error("Export did not produce file within %.1fs: %s", timeout_s, export_filename)
    return { ok=false, err="export timeout", exported=export_path }
  end

  log.debug("Moving export to: %s", target_filename)
  local ok, move_err = move_file(export_path, target_path)
  if not ok then
    log.error("Move failed: %s", tostring(move_err or "unknown"))
    return { ok=false, err="move failed", exported=export_path, path=target_path }
  end

  _cache[target_path] = nil
  log.debug("Saved set: %s", target_path)
  return { ok=true, path=target_path, exported=export_path }
end

-- list_all([pattern]) -> { {name=..., sj=..., job=..., src="jobs"/"auto", path=..., filename=...}, ... }
function sets.list_all(pattern)
  if not _root then sets.init() end

  local ctx, err = get_player_ctx()
  if not ctx then
    log.error("Cannot resolve player context for list_all: %s", err or "unknown")
    return {}
  end

  local results = {}

  local function add_records_from_dir(abs_dir, sj_tag, src_tag)
    log.debug("ListAll: scanning %s", abs_dir)
    for _, fname in ipairs(list_files(abs_dir)) do
      local set_name = extract_set_name_for_ctx(ctx, fname)
      if set_name then
        if not pattern or tostring(set_name):find(pattern) ~= nil then
          local abs_path = join(abs_dir, fname)
          results[#results+1] = {
            name     = set_name,
            sj       = sj_tag,
            job      = ctx.job,   -- include job code for printing [job][sj]
            src      = src_tag,   -- "jobs" or "auto"
            path     = abs_path,
            filename = fname,
          }
          log.debug("ListAll: found %s (%s) -> %s", fname, sj_tag, set_name)
        end
      end
    end
  end

  -- 1) current SJ
  local sj_dir = join(_root, ("data/autoloader/jobs/%s/%s"):format(ctx.job, ctx.sj))
  add_records_from_dir(sj_dir, ctx.sj, "jobs")

  -- 2) other SJs (alphabetical, incl. 'default')
  local sjs = list_subjobs(ctx.job)
  for _, other_sj in ipairs(sjs) do
    if other_sj ~= ctx.sj then
      local dir2 = join(_root, ("data/autoloader/jobs/%s/%s"):format(ctx.job, other_sj))
      add_records_from_dir(dir2, other_sj, "jobs")
    end
  end

  -- 3) auto
  local auto_dir = join(_root, "data/autoloader/auto")
  add_records_from_dir(auto_dir, "auto", "auto")

  log.debug("ListAll: total matches = %d", #results)
  return results
end

-- ---------- get_all (unique names -> resolved sets) ----------
-- get_all([pattern]) -> { ["melee.acc"] = <table>, ["idle.pdt"] = <table>, ... }
-- - pattern is an optional Lua pattern matched against the set *name*
-- - unique names are discovered across current SJ, other SJs (alpha, incl. 'default'), then auto
-- - for each unique name we call sets.get(name) to resolve the actual source (SJ priority + auto)
function sets.get_all(pattern)
  if not _root then sets.init() end

  local ctx, err = get_player_ctx()
  if not ctx then
    log.error("Cannot resolve player context for get_all: %s", err or "unknown")
    return {}
  end

  local names = {}  -- set of unique names

  local function gather(abs_dir)
    log.debug("GetAll: scanning %s", abs_dir)
    for _, fname in ipairs(list_files(abs_dir)) do
      local name = extract_set_name_for_ctx(ctx, fname)
      if name and (not pattern or tostring(name):find(pattern) ~= nil) then
        if not names[name] then
          names[name] = true
          log.debug("GetAll: discovered name '%s'", name)
        end
      end
    end
  end

  -- discover unique names (priority discovery order mirrors get())
  gather(join(_root, ("data/autoloader/jobs/%s/%s"):format(ctx.job, ctx.sj))) -- current SJ
  local sjs = list_subjobs(ctx.job)
  for _, other_sj in ipairs(sjs) do
    if other_sj ~= ctx.sj then
      gather(join(_root, ("data/autoloader/jobs/%s/%s"):format(ctx.job, other_sj))) -- other SJs
    end
  end
  gather(join(_root, "data/autoloader/auto")) -- auto

  -- resolve each unique name via sets.get(name)
  local out, discovered, resolved = {}, 0, 0
  for _ in pairs(names) do discovered = discovered + 1 end
  for name in pairs(names) do
    local s = sets.get(name)
    if type(s) == "table" then
      out[name] = s
      resolved = resolved + 1
      log.debug("GetAll: resolved '%s'", name)
    else
      if s == nil then
        log.debug("GetAll: '%s' not resolved (missing or nil return)", name)
      else
        log.debug("GetAll: '%s' returned non-table (%s); skipped", name, type(s))
      end
    end
  end

  log.debug("GetAll: %d unique name(s), %d resolved", discovered, resolved)
  return out
end

-- ---------- deletion ----------
-- helpers built on list_all to keep resolution order consistent
local function locate_existing(ctx, filename)
  local set_name = set_name_from_filename(ctx, filename)
  if not set_name then return nil end
  local pat = "^" .. escape_lua_pattern(set_name) .. "$"
  local rows = sets.list_all(pat)  -- already ordered: current SJ, others (alpha), then auto
  return rows[1] and rows[1].path or nil
end

local function locate_all_existing(ctx, filename)
  local set_name = set_name_from_filename(ctx, filename)
  if not set_name then return {} end
  local pat = "^" .. escape_lua_pattern(set_name) .. "$"
  local rows = sets.list_all(pat)
  local paths = {}
  for _, r in ipairs(rows) do paths[#paths+1] = r.path end
  return paths
end

-- delete(set_name) -> { ok=true, path=... } | { ok=false, err=..., path=? }
function sets.delete(set_name)
  assert(set_name and set_name ~= "", "[autoloader-sets.delete] set_name is required")
  if not _root then sets.init() end

  local ctx, err = get_player_ctx()
  if not ctx then
    log.error("Cannot resolve player context for delete: %s", err or "unknown")
    return { ok=false, err=err or "player context unavailable" }
  end

  local filename = ensure_lua_ext(("%s_%s.%s"):format(ctx.name, ctx.job, tostring(set_name)))
  log.debug("Delete: Looking for file: %s", filename)

  local path = locate_existing(ctx, filename)
  if not path then
    log.debug("Delete: Not found: %s", filename)
    return { ok=false, err="not found" }
  end

  local ok, rem_err = os.remove(path)
  if not ok then
    log.error("Delete failed: %s", tostring(rem_err or "unknown"))
    return { ok=false, err="delete failed", path=path }
  end

  _cache[path] = nil
  log.debug("Deleted set: %s", path)
  return { ok=true, path=path }
end

-- delete_all(set_name) -> { ok=true/false, deleted={...}, failed={{path=...,err=...},...} }
function sets.delete_all(set_name)
  assert(set_name and set_name ~= "", "[autoloader-sets.delete_all] set_name is required")
  if not _root then sets.init() end

  local ctx, err = get_player_ctx()
  if not ctx then
    log.error("Cannot resolve player context for delete_all: %s", err or "unknown")
    return { ok=false, err=err or "player context unavailable", deleted={}, failed={} }
  end

  local filename = ensure_lua_ext(("%s_%s.%s"):format(ctx.name, ctx.job, tostring(set_name)))
  log.debug("DeleteAll: Looking for file: %s", filename)

  local paths = locate_all_existing(ctx, filename)
  if #paths == 0 then
    log.debug("DeleteAll: Not found: %s", filename)
    return { ok=false, err="not found", deleted={}, failed={} }
  end

  local deleted, failed = {}, {}
  for _, path in ipairs(paths) do
    local ok, rem_err = os.remove(path)
    if ok then
      _cache[path] = nil
      log.debug("Deleted set: %s", path)
      deleted[#deleted+1] = path
    else
      local msg = tostring(rem_err or "unknown")
      log.error("Delete failed: %s (%s)", path, msg)
      failed[#failed+1] = { path = path, err = msg }
    end
  end

  return { ok = (#failed == 0), deleted = deleted, failed = failed }
end

-- ---------- build_set (ordered combine) ----------
-- build_set(name1, name2, ...) -> combined table or nil
-- - Names can be raw; we normalize to lowercase and replace spaces with dots.
-- - Each part is loaded via sets.get(). Non-table parts are skipped.
-- - Combination uses GearSwap's set_combine() when available, else a deep-merge fallback.
local function normalize_set_name(s)
  return (tostring(s or ""):gsub("%s+", "."):gsub("'", ""):lower())
end

local function fallback_clone(t)
  local r = {}
  for k, v in pairs(t or {}) do
    r[k] = (type(v) == "table") and fallback_clone(v) or v
  end
  return r
end

local function fallback_merge(a, b)
  -- deep merge where b overrides a
  local out = fallback_clone(a or {})
  local function merge(dst, src)
    for k, v in pairs(src or {}) do
      if type(v) == "table" and type(dst[k]) == "table" then
        merge(dst[k], v)
      else
        dst[k] = v
      end
    end
  end
  merge(out, b or {})
  return out
end

local function combine_sets(base, part)
  if type(_G.set_combine) == "function" then
    return set_combine(base or {}, part or {})
  else
    return fallback_merge(base, part)
  end
end

function sets.build_set(...)
  if not _root then sets.init() end

  local args = { ... }
  -- convenience: allow a single table { "a","b","c" }
  if #args == 1 and type(args[1]) == "table" then
    args = args[1]
  end

  local combined, count = nil, 0
  for i, name in ipairs(args) do
    local n = normalize_set_name(name)
    local part = sets.get(n)
    if type(part) == "table" then
      combined = (combined == nil) and part or combine_sets(combined, part)
      count = count + 1
      log.debug("BuildSet: added %s", n)
    else
      if part == nil then
        log.debug("BuildSet: not found %s", n)
      else
        log.debug("BuildSet: %s returned %s; skipped", n, type(part))
      end
    end
  end

  if not combined then
    log.debug("BuildSet: no sets resolved")
    return nil
  end

  log.debug("BuildSet: combined %d set(s)", count)
  return combined
end

return sets
