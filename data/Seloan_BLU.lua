local autoloader = require("autoloader")
local codex = require("autoloader-codex")
local auto_sets = require("autoloader-sets")

autoloader.lockstyle = 2
autoloader.auto_movement = "on"


local function is_blue_magic(spell)
    return spell and spell.action_type and spell.action_type:lower() == "magic" and spell.skill and
           spell.skill:lower() == "blue magic"
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