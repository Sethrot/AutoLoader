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
