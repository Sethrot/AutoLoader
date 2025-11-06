local autoloader = rawget(_G, 'autoloader') or error('autoloader not initialized')

local utils = require("autoloader-utils")
local sets = require("autoloader-sets")

local commands = {}

local _help_topics, _help_order = {}, {}
local function Topic(name, def)
    _help_topics[name] = def
    _help_order[#_help_order + 1] = name
end

Topic('set', {
    title    = "set",
    desc     = "Show and manage equipment sets.",
    usage    = { "set <action>" },
    params   = { "<action> ::= show | load | save | delete" },
    examples = { "gs c set save idle", "gs c set save savage blade", "gs c set show cure", "gs c set show", "gs c load melee", },
    dynamic  = function()
        return "Aware of current modes and weapon. Current:"
            .. "\nIdle: " .. utils.pretty_mode_value(autoloader.get_idle_mode()) .. ", "
            .. "\nMelee: " .. utils.pretty_mode_value(autoloader.get_melee_mode()) .. ", "
            .. "\nMagic: " .. utils.pretty_mode_value(autoloader.get_magic_mode()) .. ", "
            .. "\nWeapon: " .. utils.pretty_weapon_name(autoloader.get_current_weapon())
    end,
})

Topic('idle', {
    title    = "idle",
    desc     = "Set or cycle idle mode, which determines gear when not engaged.",
    usage    = { "idle", "idle <mode>" },
    params   = { "<mode> ::= default | dt | mdt" },
    examples = { "gs c a idle", "gs c a idle default", "gs c a idle dt" },
    dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_idle_mode()) end,
})

Topic('melee', {
    title    = "melee",
    desc     = "Set or cycle melee mode, which determines gear when engaged.",
    usage    = { "melee", "melee <mode>" },
    params   = { "<mode> ::= default | acc | dt | mdt | off" },
    examples = { "gs c a melee default", "gs c a  melee acc", "gs c a melee off" },
    dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_melee_mode()) end,
})

Topic('magic', {
    title    = "magic",
    desc     = "Set or cycle magic mode, which determines baseline gear when casting.",
    usage    = { "magic", "magic <mode>" },
    params   = { "<mode> ::= default | macc | mb" },
    examples = { "gs c a magic default", "gs c a magic macc" },
    dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_magic_mode()) end,
})

Topic('weapon', {
    title    = "weapon",
    desc     = "Select or manage weapons.",
    usage    = { "gs c weapon <action>" },
    params   = { "<action> ::= select | save | delete" },
    examples = { "gs c a weapon select 2", "gs c a weapon save 3 Caladbolg" },
    dynamic  = function()
        return "Saving over an existing weapon ID without deleting it first will retain the saved sets for that ID."
            .. "\nID 0 is reserved for None. Current: "
            .. utils.pretty_weapon_name(autoloader.get_current_weapon())
    end,
})

Topic('echodrops', {
    title    = "echodrops",
    desc     = "Enable or disable auto echo drops.",
    usage    = { "echodrops", "echodrops <mode>" },
    params   = { "<mode> ::= on | off" },
    examples = { "gs c a echodrops on", "gs c a echodrops off" },
    dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_auto_echo_drops()) end,
})

Topic('remedy', {
    title    = "remedy",
    desc     = "Enable or disable auto remedy.",
    usage    = { "remedy", "remedy <mode>" },
    params   = { "<mode> ::= on | off" },
    examples = { "gs c a remedy on", "gs c a remedy off" },
    dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_auto_remedy()) end,
})

Topic('movement', {
    title    = "movement",
    desc     = "Enable or disable polling for auto movement equip.",
    usage    = { "movement", "movement <mode>" },
    params   = { "<mode> ::= on | off" },
    examples = { "gs c a movement on", "gs c a movement off" },
    dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_auto_movement()) end,
})

Topic('log', {
    title    = "log",
    desc     = "Set or cycle log verbosity.",
    usage    = { "log", "log <mode>" },
    params   = { "<mode> ::= off | error | info | debug" },
    examples = { "gs c a log debug", "gs c a log off" },
    dynamic  = function()
        local m = (autoloader.logger and autoloader.logger.mode)
            or (autoloader.logger and autoloader.logger.options and autoloader.logger.options.mode)
        local val = m and (m.value or m.current) or "off"
        return "Current: " .. utils.pretty_mode_value(val)
    end,
})

Topic('help', {
    title    = "help <command>",
    desc     = "View command details.",
    usage    = { "gs c autoloader help", "gs c auto help", "gs c a help", "gs c a help <command>" },
    params   = { "<command> ::= set | weapon | idle | movement" },
    examples = { "gs c auto help set", "gs c a help movement" },
})

local function log(msg)
    autoloader.logger.info(msg, true)
end

local function handle_help_command(cmd)
    cmd = cmd and tostring(cmd):lower() or nil
    local topic = cmd and _help_topics[cmd]
    if topic then
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
    else
        print("[AutoLoader] Available commands:")
        for _, name in ipairs(_help_order) do
            local h = _help_topics[name]
            if h then print(("%s — %s"):format(h.title, h.desc or "")) end
        end
    end
end


local function handle_idle_command(cmd)
    if cmd then
        autoloader.set_idle_mode(cmd)
        return
    end
    autoloader.cycle_idle_mode()
end

local function handle_melee_command(cmd)
    if cmd then
        autoloader.set_melee_mode(cmd)
        return
    end
    autoloader.cycle_melee_mode()
end

local function handle_magic_command(cmd)
    if cmd then
        autoloader.set_magic_mode(cmd)
        return
    end
    autoloader.cycle_magic_mode()
end

local function handle_weapon_command(cmd)

end

local function handle_movement_command(cmd)

end

local function handle_echodrops_command(cmd)

end

local function handle_remedy_command(cmd)

end

local function handle_set_command(cmd)
    cmd = tostring(cmd or "")
    local a1, tail = cmd:match("^(%S+)%s*(.*)$")
    a1 = (a1 or ""):lower()
    local a2 = (tail ~= "" and tail) or nil

    if a1 == "save" then
        sets.save(a2)
    end
end

local function handle_log_command(cmd)

end

function commands.handle(cmd)
    autoloader.logger.debug("handle cmd: " .. tostring(cmd or ""))

    local a1, tail = cmd:match("^%s*a%s+(%S+)%s*(.*)$")
    if not a1 then a1, tail = cmd:match("^%s*auto%s+(%S+)%s*(.*)$") end
    if not a1 then a1, tail = cmd:match("^%s*autoloader%s+(%S+)%s*(.*)$") end

    local a2 = (tail ~= "" and tail) or nil
    autoloader.logger.debug(("handle a1: %s, a2: %s"):format(a1 or "?", a2 or "?"))

    if a1 == "log" then
        handle_log_command(a2)
    elseif a1 == "idle" then
        handle_idle_command(a2)
    elseif a1 == "melee" then
        handle_melee_command(a2)
    elseif a1 == "magic" then
        handle_magic_command(a2)
    elseif a1 == "weapon" then
        handle_weapon_command(a2)
    elseif a1 == "auto_movement" then
        handle_movement_command(a2)
    elseif a1 == "echodrops" then
        handle_echodrops_command(a2)
    elseif a1 == "remedy" then
        handle_remedy_command(a2)
    elseif a1 == "set" then
        handle_set_command(a2)
    elseif a1 == "help" then
        handle_help_command(a2)
    else
        handle_help_command()
    end
end

return commands
