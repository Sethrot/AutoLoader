-- Seloan_RDM.lua
-- Basic Red Mage (RDM) configuration file with AutoLoader support
local job = require("autoloader-job")
job.auto_echo_drops = true
job.auto_remedy = true
job.auto_movement = true
job.lockstyle = 20

local log = require("autoloader-logger")


function before_precast(spell)
    if not spell or spell.action_type ~= "Magic" or spell.skill ~= "Enhancing Magic" then return end

    local composure_recast = job.get_ability_recast("Composure")
    -- If Composure not up and it's ready, use it and then re-cast.
    if not buffactive['Composure'] and composure_recast == 0 then
        cancel_spell()
        windower.send_command("input /ja 'Composure' <me>;wait 1.2;input /ma '" .. spell.english .. "' " .. spell.target.name)
        log.info(("%s (%s) => Composure => %s (%s)"):format(spell.english, spell.target.name, spell.english, spell.target.name))
        return true -- block original precast
    end

    local self_cast = (spell.target and (spell.target.type:lower() == 'self' or spell.target.name == (windower.ffxi.get_player() or {}).name))
    if self_cast then
        if spell.english == "Phalanx II" then
            -- Downgrade Phalanx II when casting on self
            cancel_spell()
            windower.send_command("input /ma 'Phalanx' " .. spell.target.name)
            log.info(("Phalanx II (%s) => Phalanx (#s)"):format(spell.target.name, spell.target.name))
            return true -- block original precast
        end
    end

    return false
end