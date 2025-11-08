-- Seloan_RDM.lua
-- Basic Red Mage (RDM) configuration file with AutoLoader support

include("autoloader") -- The only really necessary part in this entire file, the rest is being fancy.
local common = include("common")

function before_user_setup()
    return common.before_user_setup()
end

function after_get_sets()
    common.set_lockstyle(20)
end

function before_precast(spell)
    local terminate = common.auto_remedy(spell)
    if terminate then return true end
    terminate = common.auto_echo_drops(spell)
    if terminate then return true end

    if not spell or spell.action_type ~= "Magic" or spell.skill ~= "Enhancing Magic" then return end

    local composure_recast = common.get_ability_recast("Composure")
    -- If Composure not up and it's ready, use it and then re-cast.
    if not buffactive['Composure'] and composure_recast == 0 then
        cancel_spell()
        windower.send_command("input /ja 'Composure' <me>;wait 1.2;input /ma '" .. spell.english .. "' " .. spell.target.name)
        common.show(("%s (%s) => Composure => %s (%s)"):format(spell.english, spell.target.name, spell.english, spell.target.name))
        return true -- block original precast
    end

    local self_cast = (spell.target and (spell.target.type:lower() == 'self' or spell.target.name == (windower.ffxi.get_player() or {}).name))
    if self_cast then
        if spell.english == "Phalanx II" then
            -- Downgrade Phalanx II when casting on self
            cancel_spell()
            windower.send_command("input /ma 'Phalanx' " .. spell.target.name)
            common.show(("Phalanx II (%s) => Phalanx (#s)"):format(spell.target.name, spell.target.name))
            return true -- block original precast
        end
    end

    return false
end

function after_precast(spell)
    -- Do something after AutoLoader handles aftercast.
    -- AutoCast.debug("AutoLoader just handled precast for me. It probably equipped some awesome and strictly relevant gear based on my named exports. Thanks AutoLoader!")
end

function before_midcast(spell)
    -- Do something before AutoLoader handles midcast.
    -- Return false to skip AutoLoader's own midcast handling.
end

function after_midcast(spell)
    -- Do something after AutoLoader handles midcast.
end

function before_aftercast(spell)
    -- Do something before AutoLoader handles aftercast.
    -- Return false to skip AutoLoader's own aftercast handling.
end

function after_aftercast(spell)
    -- Do something after AutoLoader handles aftercast.
end

function before_status_change(new, old)
    -- Do something before AutoLoader handles status_change.
    -- Return false to skip AutoLoader's own status_change handling.
end

function after_status_change(new, old)
    -- Do something after AutoLoader handles status_change.
end

function before_user_unload()
    return common.before_user_unload()
end
