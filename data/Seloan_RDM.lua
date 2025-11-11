-- Seloan_RDM.lua
-- Basic Red Mage (RDM) configuration file with AutoLoader support
local autoloader = require("autoloader")
autoloader.auto_echo_drops = true
autoloader.auto_remedy = true
autoloader.lockstyle = 20
autoloader.auto_movement = "on"
autoloader.register_keybind("^F10", "input //ez cycle back") -- keybinds for separate eznuke add-on
autoloader.register_keybind("!F10", "input //ez cycle")

local log = require("autoloader-logger")

function before_precast(spell)
    if not spell or spell.action_type ~= "Magic" or spell.skill ~= "Enhancing Magic" then return end

    local composure_recast = autoloader.get_ability_recast("Composure")

    -- If Composure not up and it's ready, use it and then re-cast.
    if not buffactive['Composure'] and composure_recast == 0 then
        cancel_spell()
        windower.send_command("input /ja 'Composure' <me>;wait 1.2;input /ma '" .. spell.english .. "' " .. spell.target.name)
        log.info(("%s => Composure => %s"):format(spell.english, spell.english))
        return true -- block original precast
    end

    local self_cast = (spell.target and (spell.target.type:lower() == 'self' or spell.target.name == (windower.ffxi.get_player() or {}).name))
    if self_cast then
        if spell.english == "Phalanx II" then
            -- Downgrade Phalanx II when casting on self
            cancel_spell()
            windower.send_command("input /ma 'Phalanx' " .. spell.target.name)
            log.info("Phalanx II (Self) => Phalanx (Self)")
            return true -- block original precast
        end
    end

    return false
end