-- SPDX-License-Identifier: BSD-3-Clause
-- Copyright (c) 2025 NeatMachine

-- Seloan_RDM.lua
-- Basic Red Mage (RDM) configuration file with AutoLoader support
local autoloader = require("autoloader")
autoloader.lockstyle = 20
autoloader.auto_movement = "on"
autoloader.register_keybind("^F10", "input //ez cycle back") -- keybinds for separate eznuke add-on
autoloader.register_keybind("!F10", "input //ez cycle")

local log = require("autoloader-logger")

function before_precast(spell)

    return false
end