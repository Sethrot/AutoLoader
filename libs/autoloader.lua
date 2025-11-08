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

local autoloader = {}
_G.autoloader    = autoloader

require("Modes")
require("lists")
local utils       = include("autoloader-utils")
local sets        = include("autoloader-sets")
local scanner     = include("autoloader-scanner")
local resolver    = include("autoloader-resolver")
local commands    = include("autoloader-commands")

autoloader.logger = include("autoloader-logger")
autoloader.logger.debug("Intializing AutoLoader")

local _auto_movement     = M { "off", "on" }
local _idle_mode         = M { ["description"] = "Idle", "default", "dt", "mdt" }
local _melee_mode        = M { ["description"] = "Melee", "default", "acc", "dt", "mdt", "off" }
local _magic_mode        = M { ["description"] = "Magic", "default", "macc", "mb" }
local _default_weapon_id = 1

local _weapons           = {}
local _current_weapon_id = _default_weapon_id


local function try_set_mode(mode, value)
    if not mode then return false, "Mode is required." end
    if not value then return false, "Value is required" end
    if not mode:contains(value) then
        return false,
            ("%s is not a valid value for mode %s"):format(value, mode.description or "")
    end

    mode:set(value)
    return true, nil
end

local function echo(msg)
    windower.send_command("input /echo " .. msg)
end

local function movement_poll(now)

end

local _polling_functions = {
    movement = {
        key = "movement_polling",
        interval = 1.0,
        fn = movement_poll
    }
}

local poll = {}
do
    local tasks   = {} -- key -> {fn=function(now), interval=number, next_due=number}
    local running = false
    local handler = nil

    local function detach_if_empty()
        if next(tasks) ~= nil then return end
        if running and windower and windower.unregister_event and handler then
            pcall(windower.unregister_event, 'prerender', handler)
            handler, running = nil, false
        end
    end

    local function ensure_handler()
        if running then return end
        handler = function()
            -- nothing scheduled → detach if we can, otherwise cheap return
            if next(tasks) == nil then
                detach_if_empty()
                return
            end

            local now = os.clock()
            -- collect due keys first (safe against registry mutations during callbacks)
            local due = {}
            for k, t in pairs(tasks) do
                if now >= t.next_due then
                    due[#due + 1] = k
                end
            end

            -- run due tasks
            for i = 1, #due do
                local k = due[i]
                local t = tasks[k]
                if t then
                    local ok = xpcall(t.fn, debug.traceback, now)
                    -- even on error, schedule next tick (keeps the loop alive but won’t crash)
                    t.next_due = now + t.interval
                end
            end

            -- if callbacks removed everything, detach
            detach_if_empty()
        end

        windower.register_event('prerender', handler)
        running = true
    end

    --- Register (or replace) a periodic job.
    -- @param key       string|number  (identifier)
    -- @param interval  number         (seconds, e.g. 0.5 or 1.0)
    -- @param fn        function(now)  (now = os.clock())
    function poll.ensure_registration(key, interval, fn)
        assert(key ~= nil, 'poll.register_once: key required')
        assert(type(fn) == 'function', 'poll.register_once: fn must be function')
        if tasks[key] then return false end
        tasks[key] = { fn = fn, interval = tonumber(interval) or 1.0, next_due = os.clock() }
        ensure_handler()
        return true
    end

    --- Unregister a job by key.
    function poll.unregister(key)
        if key == nil then return end
        tasks[key] = nil
        detach_if_empty()
    end

    --- Remove all jobs and stop the handler (if supported).
    function poll.clear()
        for k in pairs(tasks) do tasks[k] = nil end
        detach_if_empty()
    end

    --- How many active jobs?
    function poll.count()
        local n = 0; for _ in pairs(tasks) do n = n + 1 end; return n
    end
end
autoloader.poll = poll

function autoloader.set_auto_movement(value)
    local ok, err = try_set_mode(_auto_movement, value)
    if not ok then autoloader.logger.error(err) end

    local movement_poll = _polling_functions.movement
    if movement_poll then
        if _auto_movement.current then
            autoloader.logger.debug("Ensuring resgistration for  " .. movement_poll.key)
            autoloader.poll.ensure_registration(movement_poll.key, movement_poll.interval, movement_poll.fn)
        else
            autoloader.poll.unregister(movement_poll.key)
            autoloader.logger.debug("Unregistered " .. movement_poll.key)
        end
    end
end

function autoloader.toggle_auto_movement()
    _auto_movement:cycle()
    echo("Auto Movement: " .. utils.pretty_mode_value(_auto_movement.current))
    local movement_poll = _polling_functions.movement
    if movement_poll then
        if _auto_movement.current then
            autoloader.logger.debug("Ensuring resgistration for  " .. movement_poll.key)
            autoloader.poll.ensure_registration(movement_poll.key, movement_poll.interval, movement_poll.fn)
        else
            autoloader.poll.unregister(movement_poll.key)
            autoloader.logger.debug("Unregistered " .. movement_poll.key)
        end
    end
end

function autoloader.get_auto_movement()
    return _auto_movement.current
end

function autoloader.set_idle_mode(value)
    local ok, err = try_set_mode(_idle_mode, value)
    if not ok then autoloader.logger.error(err); return end
    echo("Idle: " .. utils.pretty_mode_value(autoloader.get_current_idle_mode()))
    autoloader.status_refresh()
end

function autoloader.set_log_mode(value)
    local ok, err = try_set_mode(autoloader.logger.mode, value)
    if not ok then autoloader.logger.error(err); return end
    echo("Log: " .. utils.pretty_mode_value(autoloader.logger.mode.current))
end

function autoloader.cycle_log_mode()
    autoloader.logger.debug("cycling log")
    autoloader.logger.mode:cycle()
    echo("Log: " .. utils.pretty_mode_value(autoloader.logger.mode.current))
end

function autoloader.cycle_idle_mode()
    autoloader.logger.debug("cycling idle")
    _idle_mode:cycle()
    echo("Idle: " .. utils.pretty_mode_value(autoloader.get_current_idle_mode()))
    autoloader.status_refresh()
end

function autoloader.set_melee_mode(value)
    local ok, err = try_set_mode(_melee_mode, value)
    if not ok then autoloader.logger.error(err); return end
    echo("Melee: " .. utils.pretty_mode_value(autoloader.get_current_melee_mode()))
    autoloader.status_refresh()
end

function autoloader.cycle_melee_mode()
    _melee_mode:cycle()
    echo("Melee: " .. utils.pretty_mode_value(autoloader.get_current_melee_mode()))
    autoloader.status_refresh()
end

function autoloader.set_magic_mode(value)
    local ok, err = try_set_mode(_magic_mode, value)
    if not ok then autoloader.logger.error(err) end
    echo("Magic: " .. utils.pretty_mode_value(autoloader.get_current_magic_mode()))
    autoloader.status_refresh()
end

function autoloader.cycle_magic_mode()
    _magic_mode:cycle()
    echo("Magic: " .. utils.pretty_mode_value(autoloader.get_current_magic_mode()))
    autoloader.status_refresh()
end

function autoloader.get_current_idle_mode()
    return _idle_mode.current
end

function autoloader.get_idle_modes()
    return utils.get_mode_options(_idle_mode)
end

function autoloader.get_current_melee_mode()
    return _melee_mode.current
end

function autoloader.get_melee_modes()
    return utils.get_mode_options(_melee_mode)
end

function autoloader.get_current_magic_mode()
    return _magic_mode.current
end

function autoloader.get_magic_modes()
    return utils.get_mode_options(_magic_mode)
end

function autoloader.get_current_weapon()
    return _current_weapon_id and _weapons[_current_weapon_id]
end

function autoloader.set_weapon(id)
    if id and _weapons[id] then
        _current_weapon_id = id
        autoloader.status_refresh()
        return true
    else
        _current_weapon_id = 0
        autoloader.status_refresh()
        return false
    end
end

function autoloader.status_refresh()
    status_change(player.status, player.status)
end

autoloader.stub_before_user_setup = function() end
before_user_setup = autoloader.stub_before_user_setup
function user_setup()
    local terminate = utils.call_hook("before_user_setup", autoloader.stub_before_user_setup)
    if terminate then return end
end

autoloader.stub_after_get_sets = function() end
after_get_sets = autoloader.stub_after_get_sets
function get_sets()
    scanner.generate_auto_sets()
    autoloader.logger.debug("generate_auto_sets finished")

    _weapons = sets.get_weapons()

    autoloader.status_refresh()

    utils.call_hook("after_get_sets", autoloader.stub_after_get_sets)
end

autoloader.stub_before_status_change = function() end
before_status_change = autoloader.stub_before_status_change
autoloader.stub_after_status_change = function() end
after_status_change = autoloader.stub_after_status_change
function status_change(new, old)
    local terminate = utils.call_hook("before_status_change", autoloader.stub_before_status_change, new, old)
    if terminate then return end
    autoloader.logger.debug(("status_change %s -> %s"):format(old, new))

    if new == "Engaged" and _melee_mode.current ~= "off" then
        equip(sets.build_set(resolver.resolve_current_melee_set_names()))
    elseif new == "Resting" then
        equip(sets.build_set({ "idle.rest", "idle.resting", "rest", "resting" }))
    else
        equip(sets.build_set(resolver.resolve_current_idle_set_names()))
    end

    utils.call_hook("after_status_change", autoloader.stub_after_status_change, new, old)
end

autoloader.stub_before_precast = function() end
before_precast = autoloader.stub_before_precast
autoloader.stub_after_precast = function() end
after_precast = autoloader.stub_after_precast
function precast(spell)
    local terminate = utils.call_hook("before_precast", autoloader.stub_before_precast, spell)
    if terminate then return end

    equip(sets.build_set(resolver.resolve_precast_set_names(spell)))

    utils.call_hook("after_precast", autoloader.stub_after_precast, spell)
end

autoloader.stub_before_midcast = function() end
before_midcast = autoloader.stub_before_midcast
autoloader.stub_after_midcast = function() end
after_midcast = autoloader.stub_after_midcast
function midcast(spell)
    local terminate = utils.call_hook("before_midcast", autoloader.stub_before_midcast, spell)
    if terminate then return end

    equip(sets.build_set(resolver.resolve_midcast_set_names(spell)))

    utils.call_hook("after_midcast", autoloader.stub_after_midcast, spell)
end

autoloader.stub_before_aftercast = function() end
before_aftercast = autoloader.stub_before_aftercast
autoloader.stub_after_aftercast = function() end
after_aftercast = autoloader.stub_after_aftercast
function aftercast(spell)
    local terminate = utils.call_hook("before_aftercast", autoloader.stub_before_aftercast, spell)
    if terminate then return end

    autoloader.status_refresh()
    --if autoloader.check_weapon_change then autoloader.check_weapon_change() end

    utils.call_hook("after_aftercast", autoloader.stub_after_aftercast, spell)
end

function self_command(cmd)
    commands.handle(cmd)
end

autoloader.stub_before_user_unload = function() end
before_user_unload = autoloader.stub_before_user_unload
function user_unload()
    utils.call_hook("before_user_unload", autoloader.stub_before_user_unload)
end

autoloader.logger.debug("AutoLoader ready.")
