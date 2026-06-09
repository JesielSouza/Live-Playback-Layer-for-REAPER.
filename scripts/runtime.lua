--[[
    runtime.lua
    Read-only runtime snapshot builder for future UI consumers.
--]]

local bootstrap = require("scripts.bootstrap")
local logger = require("scripts.logger")
local navigation = require("scripts.navigation")
local position = require("scripts.position")
local state = require("scripts.state")

local Runtime = {}

local function append_all(target, values)
    if type(values) ~= "table" then
        return
    end

    for _, value in ipairs(values) do
        table.insert(target, value)
    end
end

local function copy_events(events)
    local out = {}

    if type(events) ~= "table" then
        return out
    end

    for _, event in ipairs(events) do
        table.insert(out, event)
    end

    return out
end

function Runtime.build_snapshot(options)
    options = options or {}
    logger.clear()

    local context = bootstrap.initialize_app(options.project_scan_override)
    local events = copy_events(logger.get_events())
    local validation = context and context.validation or {}
    local sections = validation.sections or {}
    local warnings = {}
    local errors = {}

    local raw_position = nil
    local position_result = nil
    if options.position_override ~= nil then
        raw_position = options.position_override
    else
        position_result = position.get_reaper_position()
        raw_position = position_result.position
        append_all(warnings, position_result.warnings)
        append_all(errors, position_result.errors)
    end

    local position_snapshot = nil
    local current_section_name = nil
    if raw_position ~= nil then
        position_snapshot = position.build_position_snapshot(sections, raw_position)
        append_all(warnings, position_snapshot.warnings)
        append_all(errors, position_snapshot.errors)

        if position_snapshot.current_section then
            current_section_name = position_snapshot.current_section.name
        end
    end

    local navigation_plan = nil
    if current_section_name then
        navigation_plan = navigation.plan_initial_navigation(sections, current_section_name)
    elseif type(sections) == "table" and #sections > 0 then
        navigation_plan = navigation.plan_initial_navigation(sections)
    end

    local app_state = context and context.state or state.get_current()
    local snapshot = {
        ok = validation.ok == true and app_state == state.STATES.SONG_LOADED,
        read_only = true,
        app_state = app_state,
        reaper_available = context and context.dependencies and context.dependencies.reaper_available == true or false,
        validation_status = validation.status,
        validation_ok = validation.ok == true,
        validation_summary = validation.summary,
        section_count = type(sections) == "table" and #sections or 0,
        position = raw_position,
        current_section = position_snapshot and position_snapshot.current_section and position_snapshot.current_section.name or nil,
        previous_section = position_snapshot and position_snapshot.previous_section and position_snapshot.previous_section.name or nil,
        next_section = position_snapshot and position_snapshot.next_section and position_snapshot.next_section.name or nil,
        decision = navigation_plan and navigation_plan.decision or nil,
        logger_event_count = #events,
        context = context,
        events = events,
        position_snapshot = position_snapshot,
        navigation_plan = navigation_plan,
        warnings = warnings,
        errors = errors
    }

    return snapshot
end

function Runtime.format_snapshot(snapshot)
    snapshot = snapshot or {}

    local lines = {
        "=== Runtime Snapshot ===",
        "Read Only: " .. tostring(snapshot.read_only == true),
        "App State: " .. tostring(snapshot.app_state or "nil"),
        "REAPER Available: " .. tostring(snapshot.reaper_available == true),
        "Validation Status: " .. tostring(snapshot.validation_status or "nil"),
        "Validation Ok: " .. tostring(snapshot.validation_ok == true),
        "Section Count: " .. tostring(snapshot.section_count or 0),
        "Current Position: " .. tostring(snapshot.position or "nil") .. "s",
        "Current Section: " .. tostring(snapshot.current_section or "nil"),
        "Previous Section: " .. tostring(snapshot.previous_section or "nil"),
        "Next Section: " .. tostring(snapshot.next_section or "nil"),
        "Decision: " .. tostring(snapshot.decision or "nil"),
        "Logger Event Count: " .. tostring(snapshot.logger_event_count or 0)
    }

    if snapshot.warnings and #snapshot.warnings > 0 then
        table.insert(lines, "Warnings: " .. table.concat(snapshot.warnings, "; "))
    end

    if snapshot.errors and #snapshot.errors > 0 then
        table.insert(lines, "Errors: " .. table.concat(snapshot.errors, "; "))
    end

    return table.concat(lines, "\n")
end

return Runtime
