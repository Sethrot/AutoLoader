local autoloader = rawget(_G, 'autoloader') or error('autoloader not initialized')

local utils = require("autoloader-utils")
local codex = require("autoloader-codex")

require("lists")

local resolver = {}

function resolver.resolve_precast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and utils.normalize_set_name(spell.english)
    if normalized_name then set_names:append("precast." .. normalized_name) end

    if spell.action_type == "Magic" then
        local base_name = spell.english and utils.normalize_set_name(codex.spells.get_base(spell.english))
        if base_name then set_names:append("precast." .. base_name) end
        set_names:append("fastcast") -- The expected generic name.
        set_names:append("precast.fastcast") -- TODO: Do some kind of normalization on save instead of guessing
        set_names:append("precast.fast_cast")
        set_names:append("fast_cast")
    else
        if normalized_name then set_names:append(normalized_name) end

        if spell.action_type == "WeaponSkill" then
            set_names:append("ws") -- The expected generic name.
            set_names:append("weaponskill") -- TODO: Do some kind of normalization on save instead of guessing
            set_names:append("precast.ws")
            set_names:append("precast.weaponskill")
        end
    end

    return set_names:reverse()
end

function resolver.resolve_midcast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and utils.normalize_set_name(spell.english)
    if normalized_name then set_names:append("midcast." .. normalized_name) end

    if spell.action_type == "Magic" then
        if normalized_name then set_names:append(normalized_name) end

        local base_name = spell.english and utils.normalize_set_name(codex.spells.get_base(spell.english))
        if base_name then
            set_names:append("midcast." .. base_name)
            set_names:append(base_name)
        end

        local skill_name = spell.skill and utils.normalize_set_name(spell.skill:match("^(%S+)"))
        if skill_name then set_names:append("midcast." .. skill_name) end
        if skill_name then set_names:append(skill_name) end
    end

    return set_names:reverse()
end

function resolver.resolve_aftercast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and utils.normalize_set_name(spell.english)
    if normalized_name then set_names:append("midcast." .. normalized_name) end

    return set_names:reverse()
end

local function resolve_mode_set_names(base, value)
    local set_names = L {}

    local normalized_base = utils.normalize_set_name(base)
    if normalized_base then set_names:append(normalized_base) end

    local normalized_current = nil
    if normalized_base and value:lower() ~= "default" then
        normalized_current = utils.normalize_set_name(value)
        if normalized_current then set_names:append(normalized_base .. "." .. normalized_current) end
    end

    return set_names:reverse()
end

local function resolve_mode_set_names_with_weapon(base, value, current_weapon)
    local set_names = resolve_mode_set_names(base, value):reverse()

    if current_weapon and current_weapon.id then
        local snap = set_names:copy(false)
        for i, v in ipairs(snap) do
            set_names:append(v .. ".weapon" .. current_weapon.id)
        end
    end

    return set_names:reverse()
end

function resolver.resolve_idle_set_names()
    return resolve_mode_set_names_with_weapon("idle", autoloader.get_current_idle_mode(), autoloader.get_current_weapon())
end

function resolver.resolve_melee_set_names()
    return resolve_mode_set_names_with_weapon("melee", autoloader.get_current_melee_mode(), autoloader.get_current_weapon())
end

function resolver.resolve_magic_set_names()
    return resolve_mode_set_names_with_weapon("melee", autoloader.get_current_magic_mode(), autoloader.get_current_weapon())
end

function resolver.resolve_save_set(name)
    if not name then autoloader.logger.error("resolve_save_set() name is required."); return end

    local normalized = utils.normalize_set_name(name)

    local isMode = false
    if utils.starts_with(normalized, "idle") then
        isMode = true
        local idle_modes = autoloader.get_idle_modes()
        local idle_prefixes = idle_modes:map(function(s) return "idle." .. s end)
        local current_idle_mode = autoloader.get_current_idle_mode():lower()
        if current_idle_mode ~= "default" and not utils.starts_with_any(normalized, idle_prefixes) then
            normalized = normalized:gsub("idle", "idle." .. current_idle_mode)
        end
        normalized = normalized:gsub("idle.default", "idle") -- We got the intention, now strip default
    elseif utils.starts_with(normalized, "melee") then
        isMode = true
        local melee_modes = autoloader.get_melee_modes()
        local melee_prefixes = melee_modes:map(function(s) return "melee." .. s end)
        local current_melee_mode = autoloader.get_current_melee_mode():lower()
        if current_melee_mode ~= "default" and not utils.starts_with_any(normalized, melee_prefixes) then
            normalized = normalized:gsub("melee", "melee." .. current_melee_mode)
        end
        normalized = normalized:gsub("melee.default", "melee") -- We got the intention, now strip default
    elseif utils.starts_with(normalized, "magic") then
        isMode = true
        local magic_modes = autoloader.get_magic_modes()
        local magic_prefixes = magic_modes:map(function(s) return "magic." .. s end)
        local current_magic_mode = autoloader.get_current_magic_mode():lower()
        if current_magic_mode ~= "default" and not utils.starts_with_any(normalized, magic_prefixes) then
            normalized = normalized:gsub("magic", "magic." .. current_magic_mode)
        end
        normalized = normalized:gsub("magic.default", "magic") -- We got the intention, now strip default
    end

    local current_weapon = autoloader.get_current_weapon()
    if isMode and (not normalized:find("%.weapon")) and current_weapon and current_weapon.id > 0 then
        normalized = utils.ensure_suffix(".weapon" .. current_weapon.id)
    end
    normalized = normalized:gsub(".weapon0", "") -- We got the intention, now strip default

    autoloader.logger.debug(("resolver.resolve_save_set() %s => %s"):format(name, normalized))

    return normalized
end

return resolver
