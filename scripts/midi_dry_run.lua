--[[
    midi_dry_run.lua
    Simulates sending MIDI events without actually calling REAPER or MIDI APIs.
--]]

local MidiDryRun = {}

function MidiDryRun.create()
    return {
        last_run = nil
    }
end

function MidiDryRun.run(events, options)
    options = options or {}
    local res = {
        ok = true,
        dry_run = true,
        sent = false,
        source = tostring(options.source or "manual"),
        section_id = options.section_id,
        event_count = 0,
        valid_count = 0,
        invalid_count = 0,
        events = {},
        invalid = {},
        reason = "midi_dry_run_completed",
        timestamp = os.time(),
        warnings = {},
        errors = {}
    }

    if not events or (type(events) == "table" and #events == 0 and not events.events) then
        res.reason = "no_midi_events"
        return res
    end

    local list = events
    local inv_list = {}
    
    if type(events) == "table" and events.events then
        list = events.events
        inv_list = events.invalid or {}
    end

    for _, e in ipairs(list) do
        res.event_count = res.event_count + 1
        if e.ok then
            res.valid_count = res.valid_count + 1
            table.insert(res.events, e)
        else
            res.invalid_count = res.invalid_count + 1
            table.insert(res.invalid, e)
        end
    end

    for _, e in ipairs(inv_list) do
        res.event_count = res.event_count + 1
        res.invalid_count = res.invalid_count + 1
        table.insert(res.invalid, e)
    end

    return res
end

function MidiDryRun.format_result(result)
    if not result then return "nil" end
    return string.format("Dry Run: %s, Source: %s, Valid: %d, Invalid: %d, Reason: %s",
        tostring(result.dry_run),
        tostring(result.source),
        result.valid_count or 0,
        result.invalid_count or 0,
        tostring(result.reason))
end

function MidiDryRun.get_last_event(result)
    if not result or not result.events or #result.events == 0 then return nil end
    return result.events[#result.events]
end

return MidiDryRun
