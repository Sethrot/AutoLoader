-- Seloan_RDM.lua
-- Basic Red Mage (RDM) configuration file with AutoLoader support
local autoloader = require("autoloader")
local common_job = require("common_job")
local codex = require("autoloader-codex")
local log = require("autoloader-logger")
autoloader.lockstyle = 20
autoloader.auto_movement = "on"
autoloader.register_keybind("^F10", "input //ez cycle back")
autoloader.register_keybind("!F10", "input //ez cycle")


function before_precast(spell)
    if spell and spell.action_type and spell.action_type:lower() == "magic" and spell.skill then
        -- Magic
        -- Use echos if necessary
        local terminate = common_job.auto_echo_drops(spell)
        if terminate == true then return true end

        if spell.skill:lower() == "enhancing magic" then
            -- Enhancing Magic

            -- If Composure not up and it's ready, use it and then re-cast.
            if not buffactive["Composure"] and codex.get_ability_recast("Composure") == 0 then
                common_job.ja_then_recast("Composure", spell)
                return true -- block original precast
            end

            -- Phalanx II downgrade on self
            local self_cast = (spell.target and (spell.target.type:lower() == "self" or spell.target.name == (windower.ffxi.get_player() or {}).name))
            if self_cast then
                if spell.english == "Phalanx II" then
                    -- Downgrade Phalanx II when casting on self
                    cancel_spell()
                    windower.send_command("input /ma 'Phalanx' " .. spell.target.name)
                    log.info("Phalanx II (Self) => Phalanx (Self)")
                    return true -- block original precast
                end
            end
        end
    end
    return false
end

function before_self_command(cmd)
    if cmd == "utsusemi" then
        common_job.auto_utsusemi()
        return true
    end
end
