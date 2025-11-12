local autoloader = {}

require("Modes")
require("lists")
local res                            = require("resources")

local utils                          = require("autoloader-utils")
local sets                           = require("autoloader-sets")
local codex                          = require("autoloader-codex")
local log                            = require("autoloader-logger")

autoloader.default_weapon_id         = 1
autoloader.lockstyle                 = nil
autoloader.auto_echo_drops           = false
autoloader.auto_remedy               = false
autoloader.idle_refresh              = nil
autoloader.auto_movement             = false
autoloader.idle_mode                 = "default"
autoloader.melee_mode                = "default"
autoloader.magic_mode                = "default"
autoloader.use_auto_sets             = true

local _idle_mode                     = M { ["description"] = "Idle", "default", "dt", "mdt" }
local _melee_mode                    = M { ["description"] = "Melee", "default", "acc", "dt", "mdt", "sb", "off" }
local _magic_mode                    = M { ["description"] = "Magic", "default", "acc", "mb" }
local _auto_movement_mode            = M { ["description"] = "Movement", "off", "on" }

local _weapons                       = {}
local _current_weapon_id             = autoloader.default_weapon_id
local _keybinds                      = {}


local _mode_display_names = {
    ["default"] = "Default",
    ["dt"] = "DT",
    ["mdt"] = "MDT",
    ["acc"] = "Accuracy",
    ["sb"] = "Subtle Blow",
    ["mb"] = "Magic Burst",
    ["on"] = "On",
    ["off"] = "Off",
}

local function echo(msg)
    windower.send_command("input /echo " .. msg)
end

function autoloader.register_keybind(key, bind)
    if key and type(key) == "string" and bind and type(bind) == "string" then
        _keybinds[key] = bind
    end
end

local function pretty_mode_value(value)
    return _mode_display_names[value] or value
end

local function pretty_weapon_display(weapon)
    if weapon.name and weapon.id then
        return ("%s (%s)"):format(weapon.name, tostring(weapon.id))
    elseif weapon.id then
        return tostring(weapon.id)
    else
        return "None"
    end
end

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

local moving = false
local _last_move_check, _last_x, _last_y = nil, nil, nil
local function movement_poll(now)
    if not player then
        _last_move_check = nil
        return
    end
    if not _last_move_check then
        _last_move_check = now
        _last_x, _last_y = player.x, player.y
        return
    end
    if now - _last_move_check > 1 then
        _last_move_check = now

        local me = windower.ffxi.get_mob_by_index(player.index)
        if not me then
            _last_move_check = nil
            return
        end

        local player_x, player_y = me.x, me.y
        if player.status and player.status:lower() == "idle" then
            if (player_x ~= _last_x or player_y ~= _last_y) and not moving then
                moving = true
                equip(sets.get(codex.CORE_SETS.movement.default))
            elseif player_x == _last_x and player_y == _last_y and moving then
                moving = false
                autoloader.status_refresh()
            end
        end

        _last_x, _last_y = player_x, player_y
    end
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
    local tasks   = {}
    local running = false
    local ev_id   = nil

    local function detach_if_empty()
        if next(tasks) ~= nil then return end
        if running and ev_id and windower and windower.unregister_event then
            windower.unregister_event(ev_id)
            ev_id, running = nil, false
        end
    end

    local function ensure_handler()
        if running then return end

        -- Replace the poller handler with this version
        local function handler()
            local now = utils.now()
            for key, t in pairs(tasks) do
                if t.next_due <= now then
                    local ok, err = pcall(t.fn, now)
                    if not ok then
                        log.error(("Poll '%s' failed: %s"):format(tostring(key), tostring(err)))
                    end
                    t.next_due = now + t.interval
                end
            end
        end

        ev_id = windower.register_event('prerender', handler)
        running = true
    end

    function poll.ensure_registration(key, interval_sec, fn)
        if not key or not interval_sec or not fn then return false end
        tasks[key] = {
            interval = tonumber(interval_sec) or 1.0,
            fn       = fn,
            next_due = utils.now() + (tonumber(interval_sec) or 1.0),
        }
        ensure_handler()
        return true
    end

    --- Unregister a job by key.
    function poll.unregister(key)
        if key == nil then return end
        tasks[key] = nil
        detach_if_empty()
    end

    --- Remove all jobs and stop the handler.
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


local function update_movement_polling()
    local movement_poll_def = _polling_functions.movement
    if not movement_poll_def then return end

    if _auto_movement_mode.current == "on" then
        log.debug("Ensuring registration for " .. movement_poll_def.key)
        autoloader.poll.ensure_registration(movement_poll_def.key, movement_poll_def.interval, movement_poll_def.fn)
    else
        autoloader.poll.unregister(movement_poll_def.key)
        log.debug("Unregistered " .. movement_poll_def.key)
    end
end

function autoloader.set_movement_mode(value)
    local ok, err = try_set_mode(_auto_movement_mode, value)
    if not ok then
        log.error(err); return
    end
    log.info(("Movement Polling: %s"):format(pretty_mode_value(_auto_movement_mode.current)))
    update_movement_polling()
end

local function cycle_movement_mode()
    _auto_movement_mode:cycle()
    log.info(("Movement Polling: %s"):format(pretty_mode_value(_auto_movement_mode.current)))
    update_movement_polling()
end

function autoloader.set_idle_mode(value)
    local ok, err = try_set_mode(_idle_mode, value)
    if not ok then
        log.error(err); return
    end
    echo("Idle: " .. pretty_mode_value(autoloader.get_current_idle_mode()))
    autoloader.status_refresh()
end

local function cycle_idle_mode()
    log.debug("Cycling idle.")
    _idle_mode:cycle()
    echo("Idle: " .. pretty_mode_value(autoloader.get_current_idle_mode()))
    autoloader.status_refresh()
end
function autoloader.get_current_idle_mode()
    return _idle_mode.current
end

function autoloader.set_melee_mode(value)
    local ok, err = try_set_mode(_melee_mode, value)
    if not ok then
        log.error(err); return
    end
    echo("Melee: " .. pretty_mode_value(autoloader.get_current_melee_mode()))
    autoloader.status_refresh()
end

local function cycle_melee_mode()
    _melee_mode:cycle()
    echo("Melee: " .. pretty_mode_value(autoloader.get_current_melee_mode()))
    autoloader.status_refresh()
end
function autoloader.get_current_melee_mode()
    return _melee_mode.current
end

function autoloader.set_magic_mode(value)
    local ok, err = try_set_mode(_magic_mode, value)
    if not ok then log.error(err) end
    echo("Magic: " .. pretty_mode_value(autoloader.get_current_magic_mode()))
    autoloader.status_refresh()
end

local function cycle_magic_mode()
    _magic_mode:cycle()
    echo("Magic: " .. pretty_mode_value(autoloader.get_current_magic_mode()))
    autoloader.status_refresh()
end
function autoloader.get_current_magic_mode()
    return _magic_mode.current
end

function autoloader.get_current_weapon()
    return _current_weapon_id and _current_weapon_id > 0 and _weapons[_current_weapon_id]
end

function autoloader.get_ability_recast(name)
    local recasts = windower.ffxi.get_ability_recasts()
    if not recasts or not res or not res.job_abilities then return false end
    local ja = res.job_abilities:with("en", name)
    if not ja then return false end
    local id = ja.recast_id
    return recasts[id]
end

function autoloader.get_spell_id(name)
    if not res or not res.spells then return nil end
    local s = res.spells:with('en', name); return s and s.id or nil
end

function autoloader.set_weapon(id, announce)
    _weapons = sets.get_weapons()
    id = tonumber(id)
    if not id then
        log.error("ID " .. tostring(id) .. " is not valid.")
        return
    end

    local weapon = id and id > 0 and _weapons[id]
    if weapon then
        _current_weapon_id = weapon.id
        local current_weapon = _weapons[_current_weapon_id]
        autoloader.status_refresh()
        if announce then echo(("Weapon: %s"):format(pretty_weapon_display(current_weapon))) end
        return true, nil
    elseif id == autoloader.default_weapon_id then
        -- The default isn't present, fallback to .weapon0
        _current_weapon_id = 0
        autoloader.status_refresh()
        if announce then echo("Weapon: None") end
        return true, nil
    elseif id == 0 then
        _current_weapon_id = 0
        autoloader.status_refresh()
        if announce then echo("Weapon: None") end
        return true, nil
    else
        return false, "Did not find weapon with ID: " .. id
    end
end

local function cycle_weapon()
    -- Refresh from disk/cache in case something changed
    _weapons = sets.get_weapons() or {}

    -- Collect numeric IDs from the sparse table
    local ids = {}
    for id, weapon in pairs(_weapons) do
        if type(id) == "number" and weapon then
            ids[#ids + 1] = id
        end
    end

    table.sort(ids) -- e.g. {1, 4, 9}

    -- Need at least two to make “next” mean anything
    if #ids < 2 then return end

    -- Figure out where we are now
    local current = _current_weapon_id
    if not current or not _weapons[current] then
        -- If current is invalid, prefer the default if it exists
        if autoloader.default_weapon_id and _weapons[autoloader.default_weapon_id] then
            current = autoloader.default_weapon_id
        else
            current = 0
        end
    end

    -- Find current index in the sorted list (0 = not found)
    local idx = 0
    for i = 1, #ids do
        if ids[i] == current then
            idx = i
            break
        end
    end

    -- Compute next index, wrapping around
    local next_index
    if idx == 0 then
        -- If we weren't on a valid weapon, start at the first
        next_index = 1
    else
        next_index = idx + 1
        if next_index > #ids then
            next_index = 1
        end
    end

    local next_id = ids[next_index]
    if next_id then
        -- Second arg = announce; your set_weapon signature expects that
        autoloader.set_weapon(next_id, true)
    end
end
local function add_weapon(id, name)
    local ok, err = sets.save_weapon(id, name)
    if ok then
        windower.send_command(("wait 1;input //gs c a weapon select %s"):format(tostring(id)))
    else
        log.error(err)
    end
end
local function delete_weapon(id)
    if _current_weapon_id == tonumber(id) then
        _current_weapon_id = autoloader.default_weapon_id
        autoloader.set_weapon(_current_weapon_id, true)
    end
    sets.delete_weapon(id)
end

function autoloader.status_refresh()
    status_change(player.status, player.status)
end

local function auto_echo_drops(spell)
    if spell.action_type == "Magic" and buffactive["Silence"] or buffactive["silence"] then
        cancel_spell()
        windower.send_command("input /item 'Echo Drops' <me>;wait 1.2;/ma " .. spell.english .. " " .. spell.target)
        log.info(("%s (Silenced) => Echo Drops => %s"):format(spell.english, spell.english))
        return true
    end
end
local function auto_remedy(spell)
    if buffactive["Paralyze"] or buffactive["paralyze"] then
        cancel_spell()
        windower.send_command("input /item 'Remedy' <me>;wait 1.2;/ma " .. spell.english .. " " .. spell.target)
        log.info(("%s (Paralyzed) => Remedy => %s"):format(spell.english, spell.english))
        return true
    end
end

local utsu_ni_id       = autoloader.utsusemi_ni_id or autoloader.get_spell_id("Utsusemi: Ni")
local utsu_ichi_id     = autoloader.utsusemi_ichi_id or autoloader.get_spell_id("Utsusemi: Ichi")
local COPY_IMAGE_NAMES = { 'Copy Image', 'Copy Image (2)', 'Copy Image (3)', 'Copy Image (4)' }
local COPY_IMAGE_IDS   = { 66, 444, 445, 446 }
local function utsusemi_ichi_cancel_shadow()
    local cancelled = false
    for i, name in ipairs(COPY_IMAGE_NAMES) do
        if buffactive[name] then
            cancelled = true
            windower.send_command("input /cancel " .. tostring(COPY_IMAGE_IDS[i]) .. ";wait 0.4;/ma 'Utsusemi: Ichi' <me>")
            log.info("Utsusemi: Ichi => Cancel Shadows => Utsusemi: Ichi")
            break
        end
    end
    if not cancelled then
        windower.send_command("input /ma 'Utsusemi: Ichi' <me>")
        log.info("Utsusemi: Ichi")
    end
end

local function auto_utsusemi()
    local recasts     = windower.ffxi.get_spell_recasts() or {}
    local ni_recast   = (utsu_ni_id and recasts[utsu_ni_id]) or 9999
    local ichi_recast = (utsu_ichi_id and recasts[utsu_ichi_id]) or 9999

    local shadows = 0
    for i, name in ipairs(COPY_IMAGE_NAMES) do if buffactive[name] then shadows = i break end end

    if shadows >= 3 then
        log.info("3+ Shadows, Utsusemi Skipped.")
        return
    end

    if ni_recast == 0 then
        windower.send_command("input /ma 'Utsusemi: Ni' <me>")
        log.info("Utsusemi: Ni")
        return
    end

    if ichi_recast == 0 then
        utsusemi_ichi_cancel_shadow()
        return
    end
end

local function player_should_refresh_idle()
    if autoloader.idle_refresh == false or autoloader.idle_refresh == true then
        return autoloader.idle_refresh
    else
        return player.mp > 200
    end
end

-- Helper: fetch the res.items entry for a player.equipment.* table
local function resolve_item(entry)
    if type(entry) ~= 'table' then return nil end
    local name = tostring(entry.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' or name:lower() == 'empty' then return nil end

    -- Prefer id when present
    if entry.id and res.items[entry.id] then
        return res.items[entry.id]
    end

    -- Fallback by English name fields used in resources
    return res.items:with('en', name) or res.items:with('enl', name) or nil
end

local function player_is_dw()
    if type(player) ~= 'table' or type(player.equipment) ~= 'table' then
        return false
    end

    local sub_entry = player.equipment.sub
    if not sub_entry then return false end

    local item = resolve_item(sub_entry)
    if not item then return false end

    if type(item) ~= 'table' then return false end
    local slots = item.slots
    if type(slots) ~= 'table' then return false end

    -- Optional hard exclusion: if resources expose skill, exclude known shield skill
    if item.skill and res.skills then
        for sid, sk in pairs(res.skills) do
            local nm = (sk.en or sk.english or sk.name)
            if nm == 'Shield' and item.skill == sid then
                return false
            end
        end
    end


    -- Case 1: string-keyed slots table
    if slots.Main or slots.main then return true end

    -- Case 2: id-keyed slots table; find which id corresponds to "Main"
    if res.slots then
        local main_id
        for sid, sdef in pairs(res.slots) do
            local name = (sdef.en or sdef.english or sdef.name) or ""
            if name:lower() == 'main' then
                main_id = sid; break
            end
        end
        if main_id and slots[main_id] then return true end
    end

    -- Secondary, robust fallback: weapons have non-zero damage; shields/grips do not
    if type(item.damage) == 'number' and item.damage > 0 then
        return true
    end

    return false
end

local function get_ordered_mode_set_names(mode)
    local set_names = L {}

    local normalized_base = utils.sanitize(mode.description)
    if normalized_base then
        set_names:append(normalized_base)
        if normalized_base == "idle" and player_should_refresh_idle() then
            set_names:append(codex.CORE_SETS.idle.refresh)
        end
        if normalized_base == "melee" and player_is_dw() then
            set_names:append(codex.CORE_SETS.melee.dw)
        end
    end

    local normalized_current = mode.current ~= "default" and utils.sanitize(mode.current)
    if normalized_base and normalized_current then
        if normalized_current then
            set_names:append(normalized_base .. "." .. normalized_current)
        end
    end

    local current_weapon = _current_weapon_id and _weapons[_current_weapon_id]
    if normalized_base == "melee" and current_weapon then
        if normalized_base then
            set_names:append(normalized_base .. ".weapon" .. tostring(_current_weapon_id))
        end
        if normalized_current then
            set_names:append(normalized_base .. "." .. normalized_current .. ".weapon" .. tostring(_current_weapon_id))
        end
    end
    log.dump(set_names)
    return set_names
end

local function get_ordered_precast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and utils.sanitize(spell.english)
    if normalized_name then set_names:append("precast." .. normalized_name) end

    if spell.action_type == "Magic" then
        local base_name = spell.english and utils.sanitize(codex.get_base(spell.english))
        if base_name then set_names:append("precast." .. base_name) end
        set_names:append("fastcast")         -- The expected generic name.
        set_names:append("precast.fastcast") -- TODO: Do some kind of normalization on save instead of guessing
        set_names:append("precast.fast_cast")
        set_names:append("fast_cast")
    else
        if normalized_name then set_names:append(normalized_name) end

        if spell.action_type == "WeaponSkill" then
            set_names:append("ws")          -- The expected generic name.
            set_names:append("weaponskill") -- TODO: Do some kind of normalization on save instead of guessing
            set_names:append("precast.ws")
            set_names:append("precast.weaponskill")
        end
    end

    return set_names:reverse()
end

local function get_ordered_midcast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and utils.sanitize(spell.english)
    if normalized_name then set_names:append("midcast." .. normalized_name) end

    if spell.action_type == "Magic" then
        if normalized_name then set_names:append(normalized_name) end

        local base_name = spell.english and utils.sanitize(codex.get_base(spell.english))
        if base_name then
            set_names:append("midcast." .. base_name)
            set_names:append(base_name)
        end

        local current_magic_mode = _magic_mode.current
        if current_magic_mode and current_magic_mode ~= "default" then
            set_names:append("midcast." .. current_magic_mode)
            if normalized_name then set_names:append("midcast." .. current_magic_mode .. "." .. normalized_name) end
            if base_name then set_names:append("midcast." .. current_magic_mode .. "." .. base_name) end
        end

        -- FIX: key codex with strings
        local predefined_set = normalized_name and codex.SPELL_CASTING_SETS[normalized_name]
        if predefined_set then set_names:append(predefined_set) end

        local base_predefined_set = base_name and codex.SPELL_CASTING_SETS[base_name]
        if base_predefined_set then set_names:append(base_predefined_set) end

        local skill_name = spell.skill and utils.sanitize(spell.skill:match("^(%S+)"))
        if skill_name then set_names:append("midcast." .. skill_name) end
        if skill_name then set_names:append(skill_name) end
    end

    return set_names:reverse()
end


local function get_ordered_aftercast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and utils.sanitize(spell.english)
    if normalized_name then set_names:append("aftercast." .. normalized_name) end

    return set_names:reverse()
end

autoloader.stub_before_get_sets = function() end
before_get_sets = autoloader.stub_before_get_sets
autoloader.stub_after_get_sets = function() end
after_get_sets = autoloader.stub_after_get_sets
function get_sets()
    local terminate = utils.call_hook("before_get_sets", autoloader.stub_before_get_sets)
    if terminate then return end

    try_set_mode(_auto_movement_mode, autoloader.auto_movement)
    update_movement_polling()

    try_set_mode(_idle_mode, autoloader.idle_mode)
    try_set_mode(_melee_mode, autoloader.melee_mode)
    try_set_mode(_magic_mode, autoloader.magic_mode)

    if next(_keybinds) ~= nil then
        for key, bind in pairs(_keybinds) do
            local ok = pcall(function() windower.send_command(("bind %s %s"):format(key, bind)) end)
            if not ok then log.error(("Failed to bind %s => %s"):format(key, bind)) end
        end
    end

    if autoloader.use_auto_sets then
        sets.generate_auto_sets(1, 0.05, 32, 0.1)
    end

    _weapons = sets.get_weapons()
    log.debug("Loaded weapons.")

    if autoloader.lockstyle then
        windower.send_command("wait 1;input /lockstyleset " .. autoloader.lockstyle)
    end
    windower.send_command("wait 1;input //gs c status_refresh")

    utils.call_hook("after_get_sets", autoloader.stub_after_get_sets)
end

autoloader.stub_before_status_change = function() end
before_status_change = autoloader.stub_before_status_change
autoloader.stub_after_status_change = function() end
after_status_change = autoloader.stub_after_status_change
function status_change(new, old)
    local terminate = utils.call_hook("before_status_change", autoloader.stub_before_status_change, new, old)
    if terminate then return end
    log.debug(("Status %s -> %s"):format(old, new))

    if new == "Engaged" and _melee_mode.current ~= "off" then
        equip(sets.build_set(get_ordered_mode_set_names(_melee_mode)))
    elseif new == "Resting" then
        equip(sets.build_set({ "idle.rest", "idle.resting", "rest", "resting" }))
    else
        equip(sets.build_set(get_ordered_mode_set_names(_idle_mode)))
    end

    utils.call_hook("after_status_change", autoloader.stub_after_status_change, new, old)
end

autoloader.stub_before_precast = function() end
before_precast = autoloader.stub_before_precast
autoloader.stub_after_precast = function() end
after_precast = autoloader.stub_after_precast
function precast(spell)
    if autoloader.auto_echo_drops then
        local terminate = auto_echo_drops(spell)
        if terminate then return end
    end
    if autoloader.auto_remedy then
        local terminate = auto_remedy(spell)
        if terminate then return end
    end
    local terminate = utils.call_hook("before_precast", autoloader.stub_before_precast, spell)
    if terminate then return end

    equip(sets.build_set(get_ordered_precast_set_names(spell)))

    utils.call_hook("after_precast", autoloader.stub_after_precast, spell)
end

autoloader.stub_before_midcast = function() end
before_midcast = autoloader.stub_before_midcast
autoloader.stub_after_midcast = function() end
after_midcast = autoloader.stub_after_midcast
function midcast(spell)
    local terminate = utils.call_hook("before_midcast", autoloader.stub_before_midcast, spell)
    if terminate then return end

    equip(sets.build_set(get_ordered_midcast_set_names(spell)))

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

    utils.call_hook("after_aftercast", autoloader.stub_after_aftercast, spell)
end

autoloader.stub_before_file_unload = function() end
before_file_unload = autoloader.stub_before_file_unload
function file_unload()
    utils.call_hook("before_file_unload", autoloader.stub_before_file_unload)

    -- Unbind keybinds
    if next(_keybinds) ~= nil then
        for key, bind in pairs(_keybinds) do
            local ok, err = pcall(function() windower.send_command(("unbind %s"):format(key)) end)
            if not ok then log.info("Failed to unbind " .. key) end
        end
    end
end

local function handle_log_command(cmd)
    if cmd and cmd ~= "" then
        log.debug(cmd)
        log.mode:set(cmd)
        echo("Log: " .. log.mode.current)
        return
    end
    log.mode:cycle()
    echo("Log: " .. log.mode.current)
end

local function handle_idle_command(cmd)
    if cmd and cmd ~= "" then
        autoloader.set_idle_mode(cmd)
        return
    end
    cycle_idle_mode()
end

local function handle_melee_command(cmd)
    if cmd and cmd ~= "" then
        autoloader.set_melee_mode(cmd)
        return
    end
    cycle_melee_mode()
end

local function handle_magic_command(cmd)
    if cmd and cmd ~= "" then
        autoloader.set_magic_mode(cmd)
        return
    end
    cycle_magic_mode()
end

local function handle_weapon_command(cmd)
    cmd = tostring(cmd or "")

    local a1, tail = cmd:match("^(%S+)%s*(.*)$")
    a1 = (a1 or ""):lower()
    local a2 = (tail ~= "" and tail) or nil

    if a1 == "save" then
        local id, tail2 = a2:match("^(%S+)%s*(.*)$")
        local name = (tail2 ~= "" and tail2) or nil
        add_weapon(id, name)
    elseif a1 == "delete" then
        local ok, err = delete_weapon(a2)
        if ok == false then log.error(err) end
    elseif a1 == "select" then
        local ok, err = autoloader.set_weapon(a2, true)
        if not ok then log.error(err) end
    elseif a1 == "next" then
        cycle_weapon()
    end
end

local function handle_movement_command(cmd)
    if cmd then
        autoloader.set_movement_mode(cmd)
        return
    else
        cycle_movement_mode()
    end
end

local _help_topics, _help_order = {}, {}
local function Topic(name, def)
    _help_topics[name] = def
    _help_order[#_help_order + 1] = name
end

Topic("sets", sets.help_topic)

Topic('idle', {
    title    = "idle",
    desc     = "Set or cycle idle mode, which determines gear when not engaged.",
    usage    = { "idle", "idle <mode>" },
    params   = { "<mode> ::= default | dt | mdt" },
    examples = { "gs c a idle", "gs c a idle default", "gs c a idle dt" },
    dynamic  = function() return "Current: " .. pretty_mode_value(_idle_mode.current) end,
})

Topic('melee', {
    title    = "melee",
    desc     = "Set or cycle melee mode, which determines gear when engaged.",
    usage    = { "melee", "melee <mode>" },
    params   = { "<mode> ::= default | acc | dt | mdt | sb | off" },
    examples = { "gs c a melee default", "gs c a  melee acc", "gs c a melee off" },
    dynamic  = function() return "Current: " .. pretty_mode_value(_melee_mode.current) end,
})

Topic('magic', {
    title    = "magic",
    desc     = "Set or cycle magic mode, which determines baseline gear when casting.",
    usage    = { "magic", "magic <mode>" },
    params   = { "<mode> ::= default | macc | mb" },
    examples = { "gs c a magic default", "gs c a magic macc" },
    dynamic  = function() return "Current: " .. pretty_mode_value(_magic_mode.current) end,
})

Topic('weapon', {
    title    = "weapon",
    desc     = "Select or manage weapons.",
    usage    = { "gs c weapon <action>" },
    params   = { "<action> ::= select | save | delete" },
    examples = { "gs c a weapon select 2", "gs c a weapon save 3 Caladbolg" },
    dynamic  = function()
        return "Saving over an existing weapon ID without deleting it first will retain the saved sets for that ID."
            .. "\nID 0 is reserved. Current: "
            .. utils.pretty_weapon_name(_weapons[_current_weapon_id])
    end,
})

Topic('movement', {
    title    = "movement",
    desc     = "Enable or disable polling for automatic movement speed equipment.",
    usage    = { "movement", "movement <mode>" },
    params   = { "<mode> ::= on | off" },
    examples = { "gs c a movement on", "gs c a movement off" },
    dynamic  = function() return "Current: " .. pretty_mode_value(_auto_movement_mode.current) end,
})

Topic('log', {
    title    = "log",
    desc     = "Set or cycle log verbosity.",
    usage    = { "log", "log <mode>" },
    params   = { "<mode> ::= off | error | info | debug" },
    examples = { "gs c a log debug", "gs c a log off" },
    dynamic  = function()
        local m = log and log.mode
        local val = m and (m.value or m.current) or "off"
        return "Current: " .. pretty_mode_value(val)
    end,
})

Topic('help', {
    title    = "help <command>",
    desc     = "View command details.",
    usage    = { "gs c autoloader help", "gs c auto help", "gs c a help", "gs c a help <command>" },
    params   = { "<command> ::= set | weapon | idle | movement" },
    examples = { "gs c a help set", "gs c auto help idle" },
})

local function handle_help_command(cmd)
    cmd = cmd and tostring(cmd):lower() or nil
    local topic = cmd and _help_topics[cmd]
    if topic then
        utils.print_help_topic(topic)
    else
        print("[AutoLoader] Available commands:")
        for _, name in ipairs(_help_order) do
            local h = _help_topics[name]
            if h then print(("%s — %s"):format(h.title, h.desc or "")) end
        end
    end
end

autoloader.stub_before_self_command = function() end
before_self_command = autoloader.stub_before_self_command
function self_command(cmd)
    local terminate = utils.call_hook("before_self_command", autoloader.stub_before_self_command)
    if terminate then return end

    local a1, rest = utils.split_args(cmd)
    if not a1 then return end
    if a1:lower() == "auto" or a1:lower() == "a" or a1:lower() == "autoloader" then
        local a2, rest2 = utils.split_args(rest)
        if a2 == "log" then
            handle_log_command(rest2)
        elseif a2 == "sets" then
            sets.handle_sets_command(rest2)
        elseif a2 == "idle" then
            handle_idle_command(rest2)
        elseif a2 == "melee" then
            handle_melee_command(rest2)
        elseif a2 == "magic" then
            handle_magic_command(rest2)
        elseif a2 == "weapon" then
            handle_weapon_command(rest2)
        elseif a2 == "movement" then
            handle_movement_command(rest2)
        elseif a2 == "utsusemi" then
            auto_utsusemi()
        elseif a2 == "help" then
            handle_help_command(rest2)
        elseif a2 == "status_refresh" then
            autoloader.status_refresh()
        else
            handle_help_command()
        end
    end
end

log.debug("autoloader ready.")

return autoloader
