-- Seloan_DRK.lua
-- Minimal Dark Knight (DRK) configuration file with AutoLoader support

local autoloader = require("autoloader")
local common_job = require("common_job")
autoloader.auto_movement = "on"

-- Remember to save your basic sets in-game using commands:
-- //gs c auto sets save idle
-- //gs c auto sets save melee
-- //gs c auto sets save ws

-- //gs c auto sets save vorpal_scythe
------ Will overwrite your ws set for Vorpal Scythe only

-- //gs c auto sets save fastcast
------ This one is always good to save.

-- //gs c auto sets save dark
------ Applies as a base set for all dark magic

-- //gs c auto sets save drain
------ This will be recognized by Drain II, III as well. (and Aspir)



function before_self_command(cmd)
    if cmd == "utsusemi" then
        common_job.auto_utsusemi()
        return true
    end
end