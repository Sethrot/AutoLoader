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
    params   = { "<action> ::= save | load | list | delete | reload" },
    examples = { "gs c set save idle", "gs c set save savage blade", "gs c set load cure", "gs c set list" },
    dynamic  = function()
        return "Aware of selected mode and weapon. Current:"
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
    cmd = tostring(cmd or "")
    local a1, tail = cmd:match("^(%S+)%s*(.*)$")
    a1 = (a1 or ""):lower()
    local a2 = (tail ~= "" and tail) or nil

    if a1 == "save" then
        
    elseif a1 == "delete" then

    elseif a1 == "select" then
        
    end
end

local function handle_movement_command(cmd)
    if cmd then
        autoloader.set_auto_movement(cmd)
        return
    end
end

local function handle_set_command(cmd)
    cmd = tostring(cmd or "")
    local a1, tail = cmd:match("^(%S+)%s*(.*)$")
    a1 = (a1 or ""):lower()
    local a2 = (tail ~= "" and tail) or nil

    if a1 == "save" then
        sets.save(a2)
    elseif a1 == "load" then
        local set = sets.get(a2)
        if not set then autoloader.logger.info("Could not find set: " .. a2) return end
        equip(set)
        autoloader.logger.info("Loaded " .. a2)
    elseif a1 == "list" then
        local saved_sets = sets.list()
        autoloader.logger.info("Sets:")
        if saved_sets then
            -- log saved set names
        end
    elseif a1 == "delete" then
        local result = sets.delete(a2)
        if result then autoloader.logger.info("Deleted " .. a1) end
    elseif a1 == "reload" then
        local result = sets.clear_cache()
        if result then autoloader.logger.info("Cleared sets cache.") end
    end
end

local function handle_log_command(cmd)
    if cmd then
        autoloader.set_log_mode(cmd)
        return
    end
    autoloader.cycle_log_mode()
end

function commands.handle(cmd)
    local a1, tail = cmd:match("^%s*a%s+(%S+)%s*(.*)$")
    if not a1 then a1, tail = cmd:match("^%s*auto%s+(%S+)%s*(.*)$") end
    if not a1 then a1, tail = cmd:match("^%s*autoloader%s+(%S+)%s*(.*)$") end

    local a2 = (tail ~= "" and tail) or nil

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
    elseif a1 == "movement" then
        handle_movement_command(a2)
    elseif a1 == "set" then
        handle_set_command(a2)
    elseif a1 == "help" then
        handle_help_command(a2)
    else
        handle_help_command()
    end
end

return commands
