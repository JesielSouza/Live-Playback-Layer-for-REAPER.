--[[
    position.lua
    Minimal read-only position reader for REAPER cursor/playhead state.
--]]

local navigation = require("scripts.navigation")

local Position = {}

local function has_sections(sections)
    return type(sections) == "table" and #sections > 0
end

function Position.get_reaper_position()
    local result = {
        ok = false,
        position = nil,
        source = "unavailable",
        warnings = {},
        errors = {}
    }

    if not (_G and _G.reaper and type(_G.reaper.GetCursorPosition) == "function") then
        table.insert(result.warnings, "reaper_cursor_unavailable")
        return result
    end

    local ok, value = pcall(_G.reaper.GetCursorPosition)
    if not ok or type(value) ~= "number" then
        table.insert(result.errors, "reaper_cursor_read_failed")
        return result
    end

    result.ok = true
    result.position = value
    result.source = "reaper_cursor"
    return result
end

function Position.find_section_at_position(sections, position)
    if type(position) ~= "number" or type(sections) ~= "table" then
        return nil
    end

    local index = navigation.build_section_index(sections)
    for i, section in ipairs(index.ordered) do
        local start_pos = section.start_pos
        local end_pos = section.end_pos

        if type(start_pos) == "number" and type(end_pos) == "number" then
            if start_pos <= position and position < end_pos then
                return section
            end

            if i == #index.ordered and position == end_pos then
                return section
            end
        end
    end

    return nil
end

function Position.build_position_snapshot(sections, position)
    local snapshot = {
        ok = false,
        position = position,
        current_section = nil,
        previous_section = nil,
        next_section = nil,
        navigation_plan = nil,
        warnings = {},
        errors = {}
    }

    if position == nil then
        table.insert(snapshot.errors, "missing_position")
        return snapshot
    end

    if not has_sections(sections) then
        table.insert(snapshot.errors, "missing_sections")
        return snapshot
    end

    snapshot.current_section = Position.find_section_at_position(sections, position)
    if not snapshot.current_section then
        table.insert(snapshot.warnings, "position_outside_sections")
        table.insert(snapshot.errors, "position_outside_sections")
        return snapshot
    end

    snapshot.navigation_plan = navigation.plan_initial_navigation(sections, snapshot.current_section.name)
    snapshot.previous_section = snapshot.navigation_plan and snapshot.navigation_plan.previous or nil
    snapshot.next_section = snapshot.navigation_plan and snapshot.navigation_plan.next or nil
    snapshot.ok = true

    return snapshot
end

function Position.format_position_snapshot(snapshot)
    snapshot = snapshot or {}

    local lines = {
        "Current Position: " .. tostring(snapshot.position or "nil") .. "s",
        "Current Section: " .. tostring(snapshot.current_section and snapshot.current_section.name or "nil"),
        "Previous Section: " .. tostring(snapshot.previous_section and snapshot.previous_section.name or "nil"),
        "Next Section: " .. tostring(snapshot.next_section and snapshot.next_section.name or "nil"),
        "Decision: " .. tostring(snapshot.navigation_plan and snapshot.navigation_plan.decision or "nil")
    }

    if snapshot.warnings and #snapshot.warnings > 0 then
        table.insert(lines, "Warnings: " .. table.concat(snapshot.warnings, "; "))
    end

    if snapshot.errors and #snapshot.errors > 0 then
        table.insert(lines, "Errors: " .. table.concat(snapshot.errors, "; "))
    end

    return table.concat(lines, "\n")
end

return Position
