--[[
    ui_cues.lua
    Pure logic for building the UI representation of section cues.
--]]

local UICues = {}
local CueModel = require("scripts.cue_model")
local SongMap = require("scripts.song_map")

function UICues.build(cue_store, song_map, active_intent, options)
    options = options or {}
    local ui = {
        ok = false,
        groups = {},
        current_section = song_map and song_map.current_section,
        next_section = song_map and song_map.next_section,
        active_target = active_intent and active_intent.target_section,
        current_cues = {},
        next_cues = {},
        active_target_cues = {},
        summary_lines = {},
        warnings = {},
        errors = {}
    }

    if not cue_store then
        table.insert(ui.errors, "missing_cue_store")
        return ui
    end

    local cues = CueModel.get_cues(cue_store)
    
    -- Filter specific cues
    if ui.current_section then
        ui.current_cues = CueModel.get_cues_for_section(cue_store, ui.current_section)
    end
    if ui.next_section then
        ui.next_cues = CueModel.get_cues_for_section(cue_store, ui.next_section)
    end
    if ui.active_target then
        ui.active_target_cues = CueModel.get_cues_for_section(cue_store, ui.active_target)
    end

    -- Group cues by section (respecting song map order if possible)
    local sections = song_map and song_map.sections or {}
    local sections_seen = {}
    
    local function add_group(sid, label)
        if sections_seen[sid] then return end
        local scues = CueModel.get_cues_for_section(cue_store, sid)
        if #scues > 0 or sid == ui.current_section or sid == ui.active_target then
            local enabled = 0
            for _, c in ipairs(scues) do if c.enabled then enabled = enabled + 1 end end
            table.insert(ui.groups, {
                section_id = sid,
                label = label or sid,
                cues = scues,
                cue_count = #scues,
                enabled_count = enabled
            })
            sections_seen[sid] = true
        end
    end

    for _, s in ipairs(sections) do
        add_group(s.id, s.label)
    end

    -- Add any remaining sections that have cues but aren't in song map
    for _, c in ipairs(cues) do
        add_group(c.section_id)
    end

    -- Summary Lines
    local summary = CueModel.get_summary(cue_store)
    ui.summary_lines = {
        "Section Cues",
        string.format("Cues: %d enabled=%d disabled=%d", summary.cue_count, summary.enabled_count, summary.disabled_count),
        string.format("Current section cues: %d", #ui.current_cues),
        string.format("Next section cues: %d", #ui.next_cues),
        string.format("Active target cues: %d", #ui.active_target_cues),
        "Cues are planned only. No MIDI is sent."
    }

    ui.ok = true
    return ui
end

function UICues.get_section_cue_groups(ui_cues)
    return ui_cues and ui_cues.groups or {}
end

function UICues.get_current_cues(ui_cues)
    return ui_cues and ui_cues.current_cues or {}
end

function UICues.get_next_cues(ui_cues)
    return ui_cues and ui_cues.next_cues or {}
end

function UICues.get_active_target_cues(ui_cues)
    return ui_cues and ui_cues.active_target_cues or {}
end

function UICues.get_summary_lines(ui_cues)
    return ui_cues and ui_cues.summary_lines or {}
end

function UICues.format_cue(cue)
    if not cue then return "nil" end
    local status = cue.enabled and "[ON]" or "[OFF]"
    return string.format("%s %s: %s", status, tostring(cue.type), tostring(cue.label))
end

function UICues.format_group(group)
    if not group then return "nil" end
    return string.format("%s (%d cues)", group.label or group.section_id, group.cue_count)
end

return UICues
