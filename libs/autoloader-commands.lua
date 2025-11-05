local autoloader = rawget(_G, 'autoloader') or error('autoloader not initialized')

local utils = require("autoloader-utils")
local sets = require("autoloader-sets")

local commands = {}

local _help_topics, _help_order = {}, {}
local function Topic(name, def)
  _help_topics[name] = def
  _help_order[#_help_order+1] = name
end

Topic('set', {
  title    = "set",
  desc     = "Show and manage equipment sets.",
  usage    = { "set <action>" },
  params   = { "<action> ::= show | load | save | delete" },
  examples = { "gs c set save idle",  "gs c set save savage blade", "gs c set show cure", "gs c set show", "gs c load melee",  },
  dynamic  = function()
    return "Aware of current modes and weapon. Current:"
      .. "\nIdle: "  .. utils.pretty_mode_value(autoloader.get_idle_mode())  .. ", "
      .. "\nMelee: " .. utils.pretty_mode_value(autoloader.get_melee_mode()) .. ", "
      .. "\nMagic: " .. utils.pretty_mode_value(autoloader.get_magic_mode()) .. ", "
      .. "\nWeapon: " .. utils.pretty_weapon_name(autoloader.get_current_weapon()) end,
})

Topic('idle', {
  title    = "idle",
  desc     = "Set or cycle idle mode, which determines gear when not engaged.",
  usage    = { "idle", "idle <mode>" },
  params   = { "<mode> ::= default | dt | mdt" },
  examples = { "gs c idle default", "gs c idle dt" },
  dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_idle_mode()) end,
})

Topic('melee', {
  title    = "melee",
  desc     = "Set or cycle melee mode, which determines gear when engaged.",
  usage    = { "melee", "melee <mode>" },
  params   = { "<mode> ::= default | acc | dt | mdt | off" },
  examples = { "gs c melee default", "gs c melee acc", "gs c melee off" },
  dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_melee_mode()) end,
})

Topic('magic', {
  title    = "magic",
  desc     = "Set or cycle magic mode, which determines baseline gear when casting.",
  usage    = { "magic", "magic <mode>" },
  params   = { "<mode> ::= default | macc | mb" },
  examples = { "gs c magic default", "gs c magic macc" },
  dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_magic_mode()) end,
})

Topic('weapon', {
  title    = "weapon",
  desc     = "Select or manage weapons.",
  usage    = { "gs c weapon <action>" },
  params   = { "<action> ::= select | save | delete" },
  examples = { "gs c weapon select 2", "gs c weapon save 3 Caladbolg" },
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
  examples = { "gs c echodrops on", "gs c echodrops off" },
  dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_auto_echo_drops()) end,
})

Topic('remedy', {
  title    = "remedy",
  desc     = "Enable or disable auto remedy.",
  usage    = { "remedy", "remedy <mode>" },
  params   = { "<mode> ::= on | off" },
  examples = { "gs c remedy on", "gs c remedy off" },
  dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_auto_remedy()) end,
})

Topic('movement', {
  title    = "movement",
  desc     = "Enable or disable polling for auto movement equip.",
  usage    = { "movement", "movement <mode>" },
  params   = { "<mode> ::= on | off" },
  examples = { "gs c movement on", "gs c movement off" },
  dynamic  = function() return "Current: " .. utils.pretty_mode_value(autoloader.get_auto_movement()) end,
})

Topic('log', {
  title    = "log",
  desc     = "Set or cycle log verbosity.",
  usage    = { "log", "log <mode>" },
  params   = { "<mode> ::= off | error | info | debug" },
  examples = { "gs c log debug", "gs c log off" },
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
  usage    = { "gs c help", "gs c help <command>" },
  params   = { "<command> ::= set | weapon | idle | movement" },
  examples = { "gs c help set", "gs c help movement" },
})

local function log(msg)
    autoloader.logger.info(msg, true)
end

local function handle_help_command(cmd)
    cmd = cmd and tostring(cmd):lower() or nil
    local topic = cmd and _help_topics[cmd]
    if topic then
        print(topic.title .. " — " .. (topic.desc or ""))
        if topic.usage   and #topic.usage   > 0 then print("Usage:");   for i=1,#topic.usage   do print(topic.usage[i])   end end
        if topic.params  and #topic.params  > 0 then print("Params:");  for i=1,#topic.params  do print(topic.params[i])  end end
        if topic.examples and #topic.examples > 0 then print("Examples:"); for i=1,#topic.examples do print(topic.examples[i]) end end
        if topic.dynamic then local ok,dyn = pcall(topic.dynamic); if ok and dyn and dyn ~= "" then print(dyn) end end
    else
        print("[AutoLoader] Available commands:")
        for _, name in ipairs(_help_order) do
            local h = _help_topics[name]
            if h then print(("%s — %s"):format(h.title, h.desc or "")) end
        end
    end
end


local function handle_idle_command(cmd)

end

local function handle_melee_command(cmd)

end

local function handle_magic_command(cmd)

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

function commands.handle(cmd)
    cmd = tostring(cmd or "")
    local a1, tail = cmd:match("^(%S+)%s*(.*)$")
    a1 = (a1 or ""):lower()
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
