local common    = {}

local log_color = 207

local _keybinds = {}

function common.show(msg)
    windower.add_to_chat(log_color, msg)
end

function common.keybind(key, bind)
    if key and type(key) == "string" and bind and type(bind) == "string" then
        _keybinds[key] = bind
    end
end

function common.auto_echo_drops(spell)
    if spell.action_type == "Magic" and buffactive["Silence"] or buffactive["silence"] then
        cancel_spell()
        windower.send_command("input /item 'Echo Drops' <me>;wait 1.2;/ma " .. spell.english .. " " .. spell.target)
        common.show(("%s (Silenced) => Echo Drops => %s"):format(spell.english, spell.english))
        return true
    end
end

function common.auto_remedy(spell)
    if buffactive["Paralyze"] or buffactive["paralyze"] then
        cancel_spell()
        windower.send_command("input /item 'Remedy' <me>;wait 1.2;/ma " .. spell.english .. " " .. spell.target)
        common.show(("%s (Paralyzed) => Remedy => %s"):format(spell.english, spell.english))
        return true
    end
end

local utsu_ni_id       = autoloader.utsusemi_ni_id or get_spell("Utsusemi: Ni")
local utsu_ichi_id     = autoloader.utsusemi_ichi_id or get_spell("Utsusemi: Ichi")
local COPY_IMAGE_NAMES = { 'Copy Image', 'Copy Image (2)', 'Copy Image (3)', 'Copy Image (4)' }
local COPY_IMAGE_IDS   = { 66, 444, 445, 446 }
local function utsusemi_ichi_cancel_shadow()
    local cancelled = false
    for i, name in ipairs(COPY_IMAGE_NAMES) do
        if buffactive[name] then
            cancelled = true
            windower.send_command("input /cancel " .. tostring(COPY_IMAGE_IDS[i]) .. ";wait 0.4")
            break
        end
    end
    windower.send_command("input /ma 'Utsusemi: Ichi' <me>")
    if cancelled then
        common.show("Utsusemi: Ichi => Cancel Shadows => Utsusemi: Ichi")
    else
        common.show("Utsusemi: Ichi")
    end
end

function common.auto_utsusemi()
    local recasts     = windower.ffxi.get_spell_recasts() or {}
    local ni_recast   = (utsu_ni_id and recasts[utsu_ni_id]) or 9999
    local ichi_recast = (utsu_ichi_id and recasts[utsu_ichi_id]) or 9999

    local n           = 0
    for _, name in ipairs(COPY_IMAGE_NAMES) do if buffactive[name] then n = n + 1 end end
    local shadows = math.min(n, 4)

    if shadows >= 3 then
        common.show("3+ Shadows, Utsusemi Skipped.")
        return
    end

    if ni_recast == 0 then
        windower.send_command("input /ma 'Utsusemi: Ni' <me>")
        common.show("Utsusemi: Ni")
        return
    end

    if ichi_recast == 0 then
        utsusemi_ichi_cancel_shadow()
        return
    end
end

function common.set_lockstyle(equipset)
    if equipset and type(equipset) == "number" then
        windower.send_command("input lockstyleset " .. equipset)
        common.show(("Applied lockstyle %s"):format(equipset))
    else
        common.show(("Invalid equipset: %s. Must be a number."):format(equipset))
    end
end

function common.get_ability_recast(name)
    local recasts = windower.ffxi.get_ability_recasts()
    if not recasts or not res or not res.job_abilities then return false end
    local ja = res.job_abilities:with("en", name)
    if not ja then return false end
    local id = ja.recast_id
    return recasts[id]
end

function common.before_user_setup()
    if next(_keybinds) ~= nil then
        for key, bind in pairs(_keybinds) do
            local ok = pcall(function()
                common.show(("bind %s %s"):format(key, bind))
            end)
            if not ok then common.show(("Failed to bind %s => %s"):format(key, bind)) end
        end
    end
end

function before_user_unload()
    if next(_keybinds) ~= nil then
        for key, bind in pairs(_keybinds) do
            local ok, err = pcall(function() windower.send_command(("unbind %s"):format(key)) end)
            if not ok then common.show("Failed to unbind " .. key) end
        end
    end
end

function self_command(cmd)
    if not cmd or cmd == "" then return end

    -- Parse root and rest
    local root, rest = cmd:match("^%s*(%S+)%s*(.*)$")
    if not root then return end

    local action, param
    if root:lower() == "c" then
        if rest and rest:lower() == "utsusemi" then
            common.auto_utsusemi()
        end
    end
end

return common
