--[[
    ui_runtime.lua
    Pure read-only view model builder for runtime UI rendering.
--]]

local UIRuntime = {}

local function copy_list(values)
    local out = {}

    if type(values) ~= "table" then
        return out
    end

    for _, value in ipairs(values) do
        table.insert(out, value)
    end

    return out
end

function UIRuntime.format_status_line(view_model)
    view_model = view_model or {}

    return table.concat({
        tostring(view_model.app_state or "nil"),
        tostring(view_model.current_section or "nil"),
        tostring(view_model.next_section or "nil"),
        tostring(view_model.decision or "nil")
    }, "  ")
end

function UIRuntime.build_view_model(snapshot)
    if type(snapshot) ~= "table" then
        local view_model = {
            ok = false,
            read_only = true,
            title = "Live Playback Layer",
            app_state = nil,
            validation_status = nil,
            validation_ok = false,
            reaper_available = false,
            current_position = nil,
            current_section = nil,
            previous_section = nil,
            next_section = nil,
            decision = nil,
            section_count = 0,
            logger_event_count = 0,
            status_line = "",
            warnings = {},
            errors = { "missing_snapshot" }
        }
        view_model.status_line = UIRuntime.format_status_line(view_model)
        return view_model
    end

    local view_model = {
        ok = snapshot.ok == true,
        read_only = true,
        title = "Live Playback Layer",
        app_state = snapshot.app_state,
        validation_status = snapshot.validation_status,
        validation_ok = snapshot.validation_ok == true,
        reaper_available = snapshot.reaper_available == true,
        current_position = snapshot.position,
        current_section = snapshot.current_section,
        previous_section = snapshot.previous_section,
        next_section = snapshot.next_section,
        decision = snapshot.decision,
        section_count = snapshot.section_count or 0,
        logger_event_count = snapshot.logger_event_count or 0,
        status_line = "",
        warnings = copy_list(snapshot.warnings),
        errors = copy_list(snapshot.errors)
    }

    view_model.status_line = UIRuntime.format_status_line(view_model)
    return view_model
end

function UIRuntime.get_section_cards(view_model)
    view_model = view_model or {}

    return {
        { label = "Current", value = tostring(view_model.current_section or "nil") },
        { label = "Previous", value = tostring(view_model.previous_section or "nil") },
        { label = "Next", value = tostring(view_model.next_section or "nil") },
        { label = "Decision", value = tostring(view_model.decision or "nil") }
    }
end

return UIRuntime
