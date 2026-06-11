--[[
    midi_cue_model.lua
    Pure logic for parsing and validating MIDI cue payloads.
--]]

local MidiCueModel = {}

function MidiCueModel.trim(s)
    if type(s) ~= "string" then return s end
    return s:match("^%s*(.-)%s*$")
end

function MidiCueModel.parse_int(s)
    local n = tonumber(s)
    if n and n == math.floor(n) then
        return n
    end
    return nil
end

function MidiCueModel.parse_payload(payload)
    payload = MidiCueModel.trim(payload)
    if not payload or payload == "" then
        return { ok = false, reason = "missing_midi_payload", errors = { "missing_midi_payload" } }
    end

    local parts = {}
    for part in payload:gmatch("([^:]+)") do
        table.insert(parts, MidiCueModel.trim(part))
    end

    if #parts ~= 4 then
        return { ok = false, raw = payload, reason = "invalid_midi_format", errors = { "format_must_be_command:ch:d1:d2" } }
    end

    local command = parts[1]:lower()
    if command ~= "note_on" and command ~= "note_off" and command ~= "cc" then
        return { ok = false, raw = payload, reason = "invalid_midi_command", errors = { "invalid_midi_command" } }
    end

    local channel = MidiCueModel.parse_int(parts[2])
    if not channel then
        return { ok = false, raw = payload, command = command, reason = "invalid_midi_channel_format", errors = { "invalid_midi_channel_format" } }
    end
    if channel < 1 or channel > 16 then
        return { ok = false, raw = payload, command = command, reason = "invalid_midi_channel", errors = { "invalid_midi_channel" } }
    end

    local d1 = MidiCueModel.parse_int(parts[3])
    if not d1 then
        local r = (command == "cc") and "invalid_midi_controller_format" or "invalid_midi_note_format"
        return { ok = false, raw = payload, command = command, channel = channel, reason = r, errors = { r } }
    end
    if d1 < 0 or d1 > 127 then
        local r = (command == "cc") and "invalid_midi_controller" or "invalid_midi_note"
        return { ok = false, raw = payload, command = command, channel = channel, reason = r, errors = { r } }
    end

    local d2 = MidiCueModel.parse_int(parts[4])
    if not d2 then
        local r = (command == "cc") and "invalid_midi_value_format" or "invalid_midi_velocity_format"
        return { ok = false, raw = payload, command = command, channel = channel, reason = r, errors = { r } }
    end
    if d2 < 0 or d2 > 127 then
        local r = (command == "cc") and "invalid_midi_value" or "invalid_midi_velocity"
        return { ok = false, raw = payload, command = command, channel = channel, reason = r, errors = { r } }
    end

    local res = {
        ok = true,
        command = command,
        channel = channel,
        data1 = d1,
        data2 = d2,
        raw = payload,
        reason = "midi_payload_valid",
        errors = {},
        warnings = {}
    }

    if command == "cc" then
        res.controller = d1
        res.value = d2
    else
        res.note = d1
        res.velocity = d2
    end

    return res
end

function MidiCueModel.build_event_from_cue(cue)
    if not cue or cue.type ~= "midi_placeholder" then
        return { ok = false, reason = "not_midi_placeholder" }
    end
    if cue.enabled == false then
        return { ok = false, reason = "cue_disabled" }
    end

    local res = MidiCueModel.parse_payload(cue.payload)
    res.cue_id = cue.id
    res.section_id = cue.section_id
    res.label = cue.label
    res.enabled = cue.enabled
    res.planned_only = true
    res.will_send = false
    
    return res
end

function MidiCueModel.build_events_for_section(cue_store, section_id)
    local out = {
        ok = true,
        section_id = section_id,
        events = {},
        invalid = {},
        warnings = {},
        errors = {}
    }
    if not cue_store or not section_id then return out end
    
    local CueModel = require("scripts.cue_model")
    local cues = CueModel.get_cues_for_section(cue_store, section_id)
    
    for _, c in ipairs(cues) do
        if c.type == "midi_placeholder" then
            local ev = MidiCueModel.build_event_from_cue(c)
            if ev.ok then
                table.insert(out.events, ev)
            else
                table.insert(out.invalid, ev)
            end
        end
    end
    
    return out
end

function MidiCueModel.build_events_for_cues(cues)
    local out = { events = {}, invalid = {} }
    if type(cues) ~= "table" then return out end
    
    for _, c in ipairs(cues) do
        if c.type == "midi_placeholder" then
            local ev = MidiCueModel.build_event_from_cue(c)
            if ev.ok then
                table.insert(out.events, ev)
            else
                table.insert(out.invalid, ev)
            end
        end
    end
    return out
end

function MidiCueModel.format_event(event)
    if not event then return "nil" end
    if not event.ok then
        return string.format("[INVALID] %s label=%s", tostring(event.reason), tostring(event.label))
    end
    
    local d1_name = (event.command == "cc") and "ctrl" or "note"
    local d2_name = (event.command == "cc") and "val" or "vel"
    
    return string.format("[DRY] %s ch=%d %s=%d %s=%d label=%s",
        tostring(event.command),
        event.channel or 0,
        d1_name, event.data1 or 0,
        d2_name, event.data2 or 0,
        tostring(event.label))
end

function MidiCueModel.get_summary(events)
    local total = 0
    local valid = 0
    local invalid = 0
    if type(events) == "table" then
        total = #events
        for _, e in ipairs(events) do
            if e.ok then valid = valid + 1 else invalid = invalid + 1 end
        end
    end
    return {
        total = total,
        valid = valid,
        invalid = invalid,
        planned_only = true,
        will_send = false
    }
end

return MidiCueModel
