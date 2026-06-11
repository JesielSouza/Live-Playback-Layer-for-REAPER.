--[[
    ui_midi_preview.lua
    Pure logic for building the UI representation of planned MIDI cues.
--]]

local UIMidiPreview = {}
local MidiCueModel = require("scripts.midi_cue_model")

function UIMidiPreview.build(cue_store, song_map, active_intent, options)
    options = options or {}
    local ui = {
        ok = false,
        current_section = song_map and song_map.current_section,
        next_section = song_map and song_map.next_section,
        active_target = active_intent and active_intent.target_section,
        current = nil,
        next = nil,
        active_target_preview = nil,
        summary_lines = {},
        warnings = {},
        errors = {}
    }

    if not cue_store then
        table.insert(ui.errors, "missing_cue_store")
        return ui
    end

    local function build_section_preview(sid)
        if not sid then return { valid_count = 0, invalid_count = 0, events = {}, invalid = {} } end
        local res = MidiCueModel.build_events_for_section(cue_store, sid)
        return {
            section_id = sid,
            events = res.events or {},
            invalid = res.invalid or {},
            valid_count = #(res.events or {}),
            invalid_count = #(res.invalid or {})
        }
    end

    ui.current = build_section_preview(ui.current_section)
    ui.next = build_section_preview(ui.next_section)
    ui.active_target_preview = build_section_preview(ui.active_target)

    ui.summary_lines = {
        "MIDI Cue Preview",
        "Planned only: yes",
        "MIDI sent: no",
        string.format("Current MIDI events: %d", ui.current.valid_count),
        string.format("Next MIDI events: %d", ui.next.valid_count),
        string.format("Active target MIDI events: %d", ui.active_target_preview.valid_count)
    }

    ui.ok = true
    return ui
end

function UIMidiPreview.get_current_events(model)
    return model and model.current and model.current.events or {}
end

function UIMidiPreview.get_next_events(model)
    return model and model.next and model.next.events or {}
end

function UIMidiPreview.get_active_target_events(model)
    return model and model.active_target_preview and model.active_target_preview.events or {}
end

function UIMidiPreview.get_summary_lines(model)
    return model and model.summary_lines or {}
end

function UIMidiPreview.format_event_line(e)
    return MidiCueModel.format_event(e)
end

function UIMidiPreview.format_section_preview(p)
    if not p or not p.section_id then return "Section: none" end
    return string.format("Section: %s (v=%d, i=%d)", p.section_id, p.valid_count, p.invalid_count)
end

return UIMidiPreview
