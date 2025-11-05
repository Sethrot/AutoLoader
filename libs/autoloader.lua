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

local autoloader         = {}
_G.autoloader            = autoloader

require("Modes")
require("lists")
local utils              = include("autoloader-utils")
local sets               = include("autoloader-sets")
--local scanner            = require("autoloader-scanner")
--local codex              = require("autoloader-codex")
local resolver           = include("autoloader-resolver")
local commands           = include("autoloader-commands")

autoloader.logger        = include("autoloader-logger")
autoloader.logger.debug("Intializing AutoLoader") 

local _auto_movement     = M { "off", "on" }
local _auto_echo_drops   = M { "off", "on" }
local _auto_remedy       = M { "off", "on" }
local _idle_mode         = M { ["description"] = "Idle", "default", "dt", "mdt" }
local _melee_mode        = M { ["description"] = "Melee", "default", "acc", "dt", "mdt", "off" }
local _magic_mode        = M { ["description"] = "Magic", "default", "macc", "mb" }
local _default_weapon_id = 1

local _weapons           = {}
local _current_weapon_id = _default_weapon_id

local _keybinds          = {}

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

function autoloader.set_auto_movement(enabled)
    local ok, err = try_set_mode(_auto_movement, enabled)
    if not ok then autoloader.logger.error(err) end
end

function autoloader.set_auto_echo_drops(enabled)
    local ok, err = try_set_mode(_auto_echo_drops, enabled)
    if not ok then autoloader.logger.error(err) end
end

function autoloader.set_auto_remedy(enabled)
    local ok, err = try_set_mode(_auto_remedy, enabled)
    if not ok then autoloader.logger.error(err) end
end

function autoloader.set_idle_mode(value)
    local ok, err = try_set_mode(_idle_mode, value)
    if not ok then
        autoloader.logger.error(err); return
    end
    autoloader.status_refresh()
end

function autoloader.set_melee_mode(value)
    local ok, err = try_set_mode(_melee_mode, value)
    if not ok then
        autoloader.logger.error(err); return
    end
    autoloader.status_refresh()
end

function autoloader.set_magic_mode(value)
    local ok, err = try_set_mode(_magic_mode, value)
    if not ok then autoloader.logger.error(err) end
    autoloader.status_refresh()
end

function autoloader.get_auto_movement()
    return _auto_movement.current
end

function autoloader.get_auto_echo_drops()
    return _auto_echo_drops.current
end

function autoloader.get_auto_remedy()
    return _auto_remedy.current
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

function autoloader.set_lockstyle(equipset)
    if equipset and type(equipset) == "number" then
        windower.send_command("input lockstyleset " .. equipset)
        autoloader.logger.info(("Applied lockstyle %s"):format(equipset))
    else
        autoloader.logger.error(("Invalid equipset %s, must be a number."):format(equipset))
    end
end

function autoloader.keybind(key, bind)
    if key and type(key) == "string" and bind and type(bind) == "string" then
        _keybinds[key] = bind
    end
end

function autoloader.status_refresh()
    status_change(player.status, player.status)
end

function autoloader.get_ability_recast(name)
    local recasts = windower.ffxi.get_ability_recasts()
    if not recasts or not res or not res.job_abilities then return false end
    local ja = res.job_abilities:with("en", name)
    if not ja then return false end
    local id = ja.recast_id
    return recasts[id]
end

autoloader.stub_before_user_setup = function() end
before_user_setup = autoloader.stub_before_user_setup
function user_setup()
    local continue = utils.call_hook("before_user_setup", autoloader.stub_before_user_setup)
    if continue == false then return end

    if next(_keybinds) ~= nil then
        for key, bind in pairs(_keybinds) do
            local ok = pcall(function()
                windower.send_command(("bind %s %s"):format(key, bind))
            end)
            if not ok then autoloader.logger.error(("Failed to bind %s => %s"):format(key, bind)) end
        end
    end
end

autoloader.stub_after_get_sets = function() end
after_get_sets = autoloader.stub_after_get_sets
function get_sets()
    autoloader.logger.debug("AutoLoader: Loading sets...")

    _weapons = sets.get_weapons()

    autoloader.status_refresh()

    utils.call_hook("after_get_sets", autoloader.stub_after_get_sets)
end

autoloader.stub_before_status_change = function() end
before_status_change = autoloader.stub_before_status_change
autoloader.stub_after_status_change = function() end
after_status_change = autoloader.stub_after_status_change
function status_change(new, old)
    local continue = utils.call_hook("before_status_change", autoloader.stub_before_status_change, new, old)
    if continue == false then return end
    autoloader.logger.debug(("status_change %s -> %s"):format(old, new))

    if new == "Engaged" and _melee_mode.current ~= "off" then
        equip(sets.build_set(resolver.resolve_melee_set_names()))
    elseif new == "Resting" then
        equip(sets.build_set({ "idle.rest", "idle.resting", "rest", "resting" }))
    else
        equip(sets.build_set(resolver.resolve_idle_set_names()))
    end

    utils.call_hook("after_status_change", autoloader.stub_after_status_change, new, old)
end

autoloader.stub_before_precast = function() end
before_precast = autoloader.stub_before_precast
autoloader.stub_after_precast = function() end
after_precast = autoloader.stub_after_precast
function precast(spell)
    local continue = utils.call_hook("before_precast", autoloader.stub_before_precast, spell)
    if continue == false then return end

    equip(sets.build_set(resolver.resolve_precast_set_names(spell)))

    utils.call_hook("after_precast", autoloader.stub_after_precast, spell)
end

autoloader.stub_before_midcast = function() end
before_midcast = autoloader.stub_before_midcast
autoloader.stub_after_midcast = function() end
after_midcast = autoloader.stub_after_midcast
function midcast(spell)
    local continue = utils.call_hook("before_midcast", autoloader.stub_before_midcast, spell)
    if continue == false then return end

    equip(sets.build_set(resolver.resolve_midcast_set_names(spell)))

    utils.call_hook("after_midcast", autoloader.stub_after_midcast, spell)
end

autoloader.stub_before_aftercast = function() end
before_aftercast = autoloader.stub_before_aftercast
autoloader.stub_after_aftercast = function() end
after_aftercast = autoloader.stub_after_aftercast
function aftercast(spell)
    local continue = utils.call_hook("before_aftercast", autoloader.stub_before_aftercast, spell)
    if continue == false then return end

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

    if next(_keybinds) ~= nil then
        for key, bind in pairs(_keybinds) do
            local ok, err = pcall(function() windower.send_command(("unbind %s"):format(key)) end)
            if not ok then autoloader.logger.error("Failed to unbind " .. bind) end
        end
    end
end

autoloader.logger.debug("AutoLoader ready.")
