local autoloader = require("autoloader")
local codex = require("autoloader-codex")
local common_job = require("common_job")
local log = require("autoloader-logger")
local auto_sets = require("autoloader-sets")

autoloader.lockstyle = 2
autoloader.auto_movement = "on"


local function is_blue_magic(spell)
    return spell and spell.action_type and spell.action_type:lower() == "magic" and spell.skill and
           spell.skill:lower() == "blue magic"
end

function before_precast(spell)
    if spell and spell.action_type and spell.action_type:lower() == "magic" then
        local terminate = common_job.auto_echo_drops(spell)
        if terminate == true then return true end
    end
    return false
end

function after_midcast(spell)
    if is_blue_magic(spell) then
        -- Blue Magic
        local self_cast = (spell.target and (spell.target.type:lower() == "self" or spell.target.name == (windower.ffxi.get_player() or {}).name))
        -- Buff => Self cast and not healing
        local is_buff = self_cast == true and not codex.BLUE_MAGIC.MAGICAL.HEALING_SPELLS:contains(spell.english)
        if buffactive["Diffusion"] and is_buff then
            -- Equip diffusion enhanced set over other resolved sets
            autoloader.equip_clean(auto_sets.get("blue.magical_buff_diffusion"))
        end
    end
end

function before_self_command(cmd)
    if cmd == "utsusemi" then
        common_job.auto_utsusemi()
        return true
    end
end

local last_nat_meditation_check = nil
local function check_nat_meditation(now)
    if not player or not buffactive or not player.status or player.status:lower() ~= "engaged" or autoloader.get_current_melee_mode():lower() == "off" then
        last_nat_meditation_check = nil
        return
    elseif not codex.player_can_cast("Nat. Meditation") then
        last_nat_meditation_check = nil
        return
    end

    if not last_nat_meditation_check then
        last_nat_meditation_check = now
        return
    end
    if now - last_nat_meditation_check > 10 then
        last_nat_meditation_check = now

        if not buffactive["Attack Boost"] and codex.get_spell_recast("Nat. Meditation") == 0 then
            windower.send_command("input /recast 'Nat. Meditation'")
        end

    end
end

function after_get_sets()
    autoloader.poll.ensure_registration("check_nat_meditation", 10, check_nat_meditation)
end
