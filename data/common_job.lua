local log = require("autoloader-logger")
local codex = require("autoloader-codex")

local common_job = {}

local utsu_ni_id       = utsusemi_ni_id or codex.get_spell_name("Utsusemi: Ni")
local utsu_ichi_id     = utsusemi_ichi_id or codex.get_spell_name("Utsusemi: Ichi")
local COPY_IMAGE_NAMES = { 'Copy Image', 'Copy Image (2)', 'Copy Image (3)', 'Copy Image (4)' }
local COPY_IMAGE_IDS   = { 66, 444, 445, 446 }
local function utsusemi_ichi_cancel_shadow()
    local cancelled = false
    for i, name in ipairs(COPY_IMAGE_NAMES) do
        if buffactive[name] then
            cancelled = true
            windower.send_command("input /cancel " ..
                tostring(COPY_IMAGE_IDS[i]) .. ";wait 0.4;/ma 'Utsusemi: Ichi' <me>")
            log.info("Utsusemi: Ichi => Cancel Shadows => Utsusemi: Ichi")
            break
        end
    end
    if not cancelled then
        windower.send_command("input /ma 'Utsusemi: Ichi' <me>")
        log.info("Utsusemi: Ichi")
    end
end

function common_job.auto_utsusemi()
    local recasts     = windower.ffxi.get_spell_recasts() or {}
    local ni_recast   = (utsu_ni_id and recasts[utsu_ni_id]) or 9999
    local ichi_recast = (utsu_ichi_id and recasts[utsu_ichi_id]) or 9999

    local shadows     = 0
    for i, name in ipairs(COPY_IMAGE_NAMES) do
        if buffactive[name] then
            shadows = i
            break
        end
    end

    if shadows >= 3 then
        log.info("3+ Shadows, Utsusemi Skipped.")
        return
    end

    if ni_recast == 0 then
        windower.send_command("input /ma 'Utsusemi: Ni' <me>")
        log.info("Utsusemi: Ni")
        return
    end

    if ichi_recast == 0 then
        utsusemi_ichi_cancel_shadow()
        return
    end
end

function common_job.auto_echo_drops(spell)
    if spell.action_type == "Magic" and buffactive["Silence"] or buffactive["silence"] then
        cancel_spell()
        windower.send_command("input /item 'Echo Drops' <me>;wait 1.2;/ma " .. spell.english .. " " .. spell.target)
        log.info(("%s (Silenced) => Echo Drops => %s"):format(spell.english, spell.english))
        return true
    end
end
function common_job.auto_remedy(spell)
    if buffactive["Paralyze"] or buffactive["paralyze"] then
        cancel_spell()
        windower.send_command("input /item 'Remedy' <me>;wait 1.2;/ma " .. spell.english .. " " .. spell.target)
        log.info(("%s (Paralyzed) => Remedy => %s"):format(spell.english, spell.english))
        return true
    end
end

function common_job.ja_then_recast(ja_name, spell)
        cancel_spell()
        windower.send_command(("input /ja '%s' <me>;wait 1.2;input /ma '%s' %s"):format(ja_name, spell.english, spell.target.name))
        log.info(("%s => %s => %s"):format(spell.english, ja_name, spell.english))
end


return common_job