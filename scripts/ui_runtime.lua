--[[
    ui_runtime.lua
    Pure read-only view model builder for runtime UI rendering.
--]]

local UIRuntime = {}

local function text_or_nil(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function bool_label(value)
    return value == true and "true" or "false"
end

local function position_label(value)
    if type(value) ~= "number" then
        return "nil"
    end

    return string.format("%.2fs", value)
end

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
        text_or_nil(view_model.app_state),
        text_or_nil(view_model.current_section),
        text_or_nil(view_model.next_section),
        text_or_nil(view_model.decision)
    }, "  ")
end

local function apply_labels(view_model)
    view_model.current_position_label = position_label(view_model.current_position)
    view_model.read_only_label = bool_label(view_model.read_only)
    view_model.validation_label = text_or_nil(view_model.validation_status)
        .. " / ok="
        .. bool_label(view_model.validation_ok)
    view_model.diagnostics_label = "sections="
        .. tostring(view_model.section_count or 0)
        .. " events="
        .. tostring(view_model.logger_event_count or 0)
    view_model.status_line = UIRuntime.format_status_line(view_model)
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
            current_position_label = "nil",
            read_only_label = "true",
            validation_label = "nil / ok=false",
            diagnostics_label = "sections=0 events=0",
            warnings = {},
            errors = { "missing_snapshot" }
        }
        apply_labels(view_model)
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
        current_position_label = "",
        read_only_label = "",
        validation_label = "",
        diagnostics_label = "",
        warnings = copy_list(snapshot.warnings),
        errors = copy_list(snapshot.errors)
    }

    apply_labels(view_model)
    return view_model
end

function UIRuntime.get_section_cards(view_model)
    view_model = view_model or {}

    return {
        { label = "Current", value = text_or_nil(view_model.current_section) },
        { label = "Previous", value = text_or_nil(view_model.previous_section) },
        { label = "Next", value = text_or_nil(view_model.next_section) },
        { label = "Decision", value = text_or_nil(view_model.decision) }
    }
end

return UIRuntime
