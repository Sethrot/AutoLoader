local autoloader = rawget(_G, 'autoloader') or error('autoloader not initialized')

local utils = require("autoloader-utils")
local codex = require("autoloader-codex")

require("lists")

local resolver = {}

local function get_sanitized_name_parts(name)
    return utils.split3_by_dot(resolver.sanitize(name))
end

local function resolve_mode_set_names(base, value)
    local set_names = L {}

    local normalized_base = resolver.sanitize(base)
    if normalized_base then set_names:append(normalized_base) end

    local normalized_current = nil
    if normalized_base and value:lower() ~= "default" then
        normalized_current = resolver.sanitize(value)
        if normalized_current then set_names:append(normalized_base .. "." .. normalized_current) end
    end

    return set_names
end

local function resolve_mode_set_names_with_weapon(base, value, current_weapon)
    local set_names = resolve_mode_set_names(base, value)

    if current_weapon and current_weapon.id then
        local snap = set_names:copy(false)
        for i, v in ipairs(snap) do
            set_names:append(v .. ".weapon" .. current_weapon.id)
        end
    end

    return set_names
end

local function get_current_modes()
    return {
        ["idle"] = autoloader.get_current_idle_mode(),
        ["melee"] = autoloader.get_current_melee_mode(),
        ["magic"] = autoloader.get_current_magic_mode()
    }
end

local function get_mode_options()
    local current_modes = {
        ["idle"] = autoloader.get_idle_modes(),
        ["melee"] = autoloader.get_melee_modes(),
        ["magic"] = autoloader.get_magic_modes()
    }
end

function resolver.sanitize(name)
    return (tostring(name or ""):gsub("'", ""):gsub("%s+", "_"):lower())
end

function resolver.resolve_current_idle_set_names()
    return resolve_mode_set_names_with_weapon("idle", autoloader.get_current_idle_mode(), autoloader.get_current_weapon())
end

function resolver.resolve_current_melee_set_names()
    return resolve_mode_set_names_with_weapon("melee", autoloader.get_current_melee_mode(), autoloader.get_current_weapon())
end

function resolver.resolve_current_magic_set_names()
    return resolve_mode_set_names_with_weapon("melee", autoloader.get_current_magic_mode(), autoloader.get_current_weapon())
end

function resolver.resolve_precast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and resolver.sanitize(spell.english)
    if normalized_name then set_names:append("precast." .. normalized_name) end

    if spell.action_type == "Magic" then
        local base_name = spell.english and resolver.sanitize(codex.spells.get_base(spell.english))
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

    local normalized_name = spell.english and resolver.sanitize(spell.english)
    if normalized_name then set_names:append("midcast." .. normalized_name) end

    if spell.action_type == "Magic" then
        if normalized_name then set_names:append(normalized_name) end

        local base_name = spell.english and resolver.sanitize(codex.spells.get_base(spell.english))
        if base_name then
            set_names:append("midcast." .. base_name)
            set_names:append(base_name)
        end

        local skill_name = spell.skill and resolver.sanitize(spell.skill:match("^(%S+)"))
        if skill_name then set_names:append("midcast." .. skill_name) end
        if skill_name then set_names:append(skill_name) end
    end

    return set_names:reverse()
end

function resolver.resolve_aftercast_set_names(spell)
    local set_names = L {}

    local normalized_name = spell.english and resolver.sanitize(spell.english)
    if normalized_name then set_names:append("midcast." .. normalized_name) end

    return set_names:reverse()
end

function resolver.resolve_user_set_name(name)
    if not name then autoloader.logger.error("resolve_user_set_name() name is required."); return end

    local p1, p2, p3 = get_sanitized_name_parts(name)

    if not p1 then autoloader.logger.error("resolve_user_set_name() invalid name: " .. name); return end

    if p1 == "idle" or p1 == "melee" or p1 == "magic" then
        -- Set is for a mode
        local current_modes = get_current_modes()
        local current_mode = current_modes and current_modes[p1]
        local mode_options = get_mode_options()
        local current_mode_options = mode_options and mode_options[p1]
        if not p2 then
            if current_mode and current_mode ~= "default" then
                p2 = current_mode -- Saving "idle" under DT idle mode will save idle.dt
                autoloader.logger.debug("resolve_user_set_name() Added current " .. p1 .. " mode modifier => " .. p2)
            end
        elseif p2 == "default" then
            p2 = nil -- Default is implied by no arg
            autoloader.logger.debug("resolve_user_set_name() removed default modifier.")
        elseif utils.starts_with(p2, "weapon") then
            -- idle.weapon1 is valid, but we'll move it to p3 to simplify processing
            p3 = p2
            p2 = nil
            autoloader.logger.debug("resolve_user_set_name() Moved weapon to from p2 to p3 => " .. p3)
        elseif not utils.starts_with_any(p2, current_mode_options) then
            -- There's some invalid mode part specified
            autoloader.logger.error("Invalid mode value: " .. p2)
            return
        end

        local current_weapon = autoloader.get_current_weapon()
        if p3 then
            local weapon_id = p3:match("^weapon(%d+)")
            if not weapon_id then
                autoloader.logger.error("Invalid weapon value: " .. p3)
                return
            elseif weapon_id == tostring(0) then
                -- weapon0 is valid, but it's implied so we'll remove it.
                p3 = nil
                autoloader.logger.debug("resolve_user_set_name() Removed default weapon value from set name => " .. p3)
            end
        elseif current_weapon and current_weapon.id and current_weapon.id ~= 0 then
            -- Weapon wasn't specified, but a weapon is assigned. We'll add the modifier.
            p3 = "weapon" .. current_weapon.id
            autoloader.logger.debug("resolve_user_set_name() Added selected weapon to set name => " .. p3)
        end

        return ("%s%s%s"):format(p1, (p2 and ("." .. p2)) or "", (p3 and ("." .. p3)) or "")
    else
       return resolver.sanitize(name)
    end
end

return resolver
