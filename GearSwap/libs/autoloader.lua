-- Direct GearSwap hooks with before_/after_ stubs using the "autoloader_" namespace.
-- Job file: include('autoloader')
--
-- Commands (all debug output by default):
--   //gs c al help                 -- show this help
--   //gs c al show                 -- list unique set names (resolved via get_all)
--   //gs c al show <name>          -- display equipment in the resolved set (exact name)
--   //gs c al set <name>           -- equip a set by normalized name (e.g., "melee.acc")
--   //gs c al save <name>          -- export current gear via GearSwap and move into autoloader
--   //gs c al delete <name>        -- delete first matching set file (current SJ → others → auto)
--   //gs c al deleteall <name>     -- delete all matching set files across SJs + auto
--   //gs c al cache clear          -- clear loader cache
--   //gs c al cache size           -- show cache entry count
--   //gs c al dbg                  -- TEMP: scan Inventory + Wardrobes and print contents

local log  = require('autoloader-logger')
local sets = require('autoloader-sets')
local inv  = require('autoloader-scanner')

-- ---------- helpers ----------
local function safe_call(fn, where, ...)
    if type(fn) ~= 'function' then return end
    local ok, err = pcall(fn, ...)
    if not ok then log.error("%s error: %s", where, tostring(err)) end
end

local function call_chain(hook, core_fn, ...)
    safe_call(_G["before_autoloader_" .. hook], "before_autoloader_" .. hook, ...)
    if type(core_fn) == "function" then
        safe_call(core_fn, "autoloader_" .. hook, ...)
    end
    safe_call(_G["after_autoloader_" .. hook], "after_autoloader_" .. hook, ...)
end

local function equip_safe(s)
    if type(s) == "table" and equip then
        equip(s)
    elseif s ~= nil then
        log.debug("Loaded non-table from set file (%s). Not equipping.", type(s))
    end
end

local function normalize_set_name(s)
    return (tostring(s or ""):gsub("%s+", "."):gsub("'", ""):lower())
end

local function print_help()
    log.debug("AutoLoader commands:")
    log.debug("  //gs c al help                 - Show this help.")
    log.debug("  //gs c al show                 - List unique set names (resolved via get_all).")
    log.debug("  //gs c al show <name>          - Display equipment in the resolved set (exact).")
    log.debug("  //gs c al set <name>           - Equip set (e.g., 'melee.acc').")
    log.debug("  //gs c al save <name>          - Export current gear and save to autoloader.")
    log.debug("  //gs c al delete <name>        - Delete first matching set file.")
    log.debug("  //gs c al deleteall <name>     - Delete all matching set files across SJs + auto.")
    log.debug("  //gs c al cache clear          - Clear cache.")
    log.debug("  //gs c al cache size           - Show cache entry count.")
    log.debug("  //gs c al dbg                  - TEMP: Scan Inventory + Wardrobes and print contents.")
end

-- Pretty-print a set
local slot_order = {
    "main", "sub", "range", "ammo",
    "head", "body", "hands", "legs", "feet",
    "neck", "waist", "left_ear", "right_ear",
    "left_ring", "right_ring", "back",
}
local slot_synonyms = {
    main       = { "main" },
    sub        = { "sub" },
    range      = { "range", "ranged" },
    ammo       = { "ammo" },
    head       = { "head" },
    body       = { "body" },
    hands      = { "hands" },
    legs       = { "legs" },
    feet       = { "feet" },
    neck       = { "neck" },
    waist      = { "waist" },
    left_ear   = { "left_ear", "lear", "ear1", "l_ear" },
    right_ear  = { "right_ear", "rear", "ear2", "r_ear" },
    left_ring  = { "left_ring", "lring", "ring1", "l_ring" },
    right_ring = { "right_ring", "rring", "ring2", "r_ring" },
    back       = { "back" },
}
local function item_to_string(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then
        local nm = v.name or v.english or v.shortname or "<item>"
        if type(v.augments) == "table" and #v.augments > 0 then
            return ("%s {%s}"):format(nm, table.concat(v.augments, ", "))
        end
        return nm
    end
    return tostring(v)
end
local function get_slot_value(t, canonical)
    local alts = slot_synonyms[canonical] or { canonical }
    for _, k in ipairs(alts) do
        if t[k] ~= nil then return t[k], k end
    end
    return nil
end
local function print_set_equipment(name, t)
    log.debug("Show: %s", name)
    if type(t) ~= "table" then
        log.debug("Show: %s returned %s; nothing to display", name, type(t))
        return
    end
    for _, slot in ipairs(slot_order) do
        local v = get_slot_value(t, slot)
        if v ~= nil then
            log.debug("  %-10s -> %s", slot, item_to_string(v))
        end
    end
end

-- ---------- autoloader_* defaults ----------
local function autoloader_get_sets()
    log.debug("get_sets()")
    sets.init(windower.addon_path)
end

local function autoloader_user_setup()
    log.debug("user_setup()")
end

local function autoloader_precast(spell, action)
    log.debug("precast: %s", spell and spell.english or "<nil>")
    if spell and spell.action_type == "Magic" then
        local s = sets.get("fastcast")
        if s then equip_safe(s) end
    end
end

local function autoloader_midcast(spell)
    log.debug("midcast: %s", spell and spell.english or "<nil>")
end

local function autoloader_aftercast(spell)
    log.debug("aftercast: %s", spell and spell.english or "<nil>")
end

local function autoloader_status_change(new, old)
    log.debug("status_change: %s -> %s", tostring(old), tostring(new))
end




local function handle_dbg()
-- inside your autoloader.lua self command for "al dbg"
local scan = require('autoloader-scanner')
scan.dump_equipment()

end



-- //gs c al ...
local function autoloader_self_command(cmd)
    local raw = tostring(cmd or "")
    local lc  = raw:lower()
    if lc:sub(1, 3) ~= "al " then return end
    local arg = raw:sub(4)
    local arg_lc = arg:lower()

    -- help
    if arg_lc == "help" then
        print_help()
        return
    end

    -- cache ops
    if arg_lc == "cache clear" then
        sets.reset_cache()
        log.debug("Cache cleared.")
        return
    elseif arg_lc == "cache size" then
        local n = sets.cache_size and sets.cache_size() or 0
        log.debug("Cache size: %d", n)
        return
    end

    -- TEMP debug hook
    if arg_lc == "dbg" then
        -- in your gs command handler for: gs c al dbg
        handle_dbg()


        return
    end

    -- show (no arg => get_all; with arg => get exact and pretty-print)
    do
        local show_name = arg:match("^show%s*(.*)$")
        if arg_lc == "show" or show_name then
            show_name = show_name or ""
            if show_name == "" then
                local map = sets.get_all()
                local names = {}
                for k, _ in pairs(map) do names[#names + 1] = k end
                table.sort(names)
                log.debug("Show: %d set name(s)", #names)
                for _, n in ipairs(names) do
                    log.debug("  %s", n)
                end
            else
                local name = normalize_set_name(show_name)
                local s = sets.get(name)
                if s then
                    print_set_equipment(name, s)
                else
                    log.debug("Show: set not found: %s", name)
                end
            end
            return
        end
    end

    -- save <name>
    do
        local save_name = arg:match("^save%s+(.+)$")
        if save_name then
            save_name = normalize_set_name(save_name)
            log.debug("Save: %s", save_name)
            local r = sets.save(save_name)
            if r and r.ok then
                log.debug("Saved set to: %s", r.path or "<unknown>")
            else
                log.error("Save failed: %s", r and (r.err or "unknown") or "unknown")
            end
            return
        end
    end

    -- deleteall <name>
    do
        local delall_name = arg:match("^deleteall%s+(.+)$")
        if delall_name then
            delall_name = normalize_set_name(delall_name)
            log.debug("DeleteAll: %s", delall_name)
            local r = sets.delete_all(delall_name)
            if r then
                log.debug("DeleteAll: deleted=%d failed=%d", #(r.deleted or {}), #(r.failed or {}))
                for _, p in ipairs(r.deleted or {}) do
                    log.debug("Deleted: %s", p)
                end
                for _, f in ipairs(r.failed or {}) do
                    log.error("Failed: %s (%s)", f.path or "?", f.err or "unknown")
                end
            else
                log.error("DeleteAll failed: unknown error")
            end
            return
        end
    end

    -- delete <name>
    do
        local del_name = arg:match("^delete%s+(.+)$")
        if del_name then
            del_name = normalize_set_name(del_name)
            log.debug("Delete: %s", del_name)
            local r = sets.delete(del_name)
            if r and r.ok then
                log.debug("Deleted: %s", r.path or "<unknown>")
            else
                log.error("Delete failed: %s", r and (r.err or "unknown") or "unknown")
            end
            return
        end
    end

    -- set <name> (equip)
    do
        local set_name = arg:match("^set%s+(.+)$")
        if set_name then
            set_name = normalize_set_name(set_name)
            log.debug("Trying set: %s", set_name)
            local s = sets.get(set_name)
            if s then
                equip_safe(s)
                log.debug("Equipped set: %s", set_name)
            else
                log.debug("Set not found: %s", set_name)
            end
            return
        end
    end

    log.debug("Unknown command: %s", raw)
end

local function autoloader_buff_change(buff, gain)
    log.debug("buff_change: %s %s", tostring(buff), gain and "gain" or "loss")
end

-- ---------- GearSwap hooks ----------
function get_sets() call_chain("get_sets", autoloader_get_sets) end

function user_setup() call_chain("user_setup", autoloader_user_setup) end

function precast(spell, a) call_chain("precast", autoloader_precast, spell, a) end

function midcast(spell) call_chain("midcast", autoloader_midcast, spell) end

function aftercast(spell) call_chain("aftercast", autoloader_aftercast, spell) end

function status_change(n, o) call_chain("status_change", autoloader_status_change, n, o) end

function self_command(cmd) call_chain("self_command", autoloader_self_command, cmd) end

function buff_change(b, gain) call_chain("buff_change", autoloader_buff_change, b, gain) end

log.debug("AutoLoader ready. Hooks installed.")
