--[[
    navigation.lua
    Pure section navigation planner. It only reads validated sections and
    returns planned navigation data for reporting.
--]]

local Navigation = {}

local function get_metadata(section)
    if type(section) ~= "table" then
        return {}
    end

    return section.metadata or section.meta or {}
end

local function get_ordered_sections(sections)
    local ordered = {}

    if type(sections) ~= "table" then
        return ordered
    end

    for _, section in ipairs(sections) do
        if type(section) == "table" and section.name then
            table.insert(ordered, section)
        end
    end

    table.sort(ordered, function(a, b)
        return (a.start_pos or 0) < (b.start_pos or 0)
    end)

    return ordered
end

function Navigation.build_section_index(sections)
    local index = {
        by_name = {},
        ordered = get_ordered_sections(sections)
    }

    for _, section in ipairs(index.ordered) do
        index.by_name[section.name] = section
    end

    return index
end

function Navigation.get_current_section(sections, current_section_name)
    local index = Navigation.build_section_index(sections)

    if current_section_name then
        return index.by_name[current_section_name]
    end

    return index.ordered[1]
end

function Navigation.get_next_section(sections, current_section_name)
    local index = Navigation.build_section_index(sections)
    local current = Navigation.get_current_section(sections, current_section_name)

    if not current then
        return nil
    end

    local metadata = get_metadata(current)
    if metadata.next and index.by_name[metadata.next] then
        return index.by_name[metadata.next]
    end

    for i, section in ipairs(index.ordered) do
        if section == current then
            return index.ordered[i + 1]
        end
    end

    return nil
end

function Navigation.get_previous_section(sections, current_section_name)
    local index = Navigation.build_section_index(sections)
    local current = Navigation.get_current_section(sections, current_section_name)

    if not current then
        return nil
    end

    for i, section in ipairs(index.ordered) do
        if section == current then
            return index.ordered[i - 1]
        end
    end

    return nil
end

function Navigation.plan_initial_navigation(sections, current_section_name)
    local index = Navigation.build_section_index(sections)
    local plan = {
        ok = true,
        current = nil,
        next = nil,
        previous = nil,
        loop_enabled = false,
        decision = nil,
        warnings = {},
        errors = {}
    }

    if #index.ordered == 0 then
        plan.ok = false
        plan.decision = "NO_SECTIONS"
        table.insert(plan.errors, "No valid sections available.")
        return plan
    end

    plan.current = Navigation.get_current_section(sections, current_section_name)
    if current_section_name and not plan.current then
        plan.ok = false
        plan.decision = "INVALID_CURRENT_SECTION"
        table.insert(plan.errors, "Current section was not found: " .. tostring(current_section_name))
        return plan
    end

    plan.next = Navigation.get_next_section(sections, current_section_name)
    plan.previous = Navigation.get_previous_section(sections, current_section_name)

    local metadata = get_metadata(plan.current)
    if metadata.loop == "1" then
        plan.loop_enabled = true
        plan.decision = "LOOP_CURRENT"
    elseif plan.next then
        plan.decision = "NEXT_SECTION_READY"
    else
        plan.decision = "END_OF_SONG"
    end

    return plan
end

function Navigation.format_sections_map(sections)
    local index = Navigation.build_section_index(sections)
    local lines = {}

    for i, section in ipairs(index.ordered) do
        local metadata = get_metadata(section)
        table.insert(lines, string.format(
            "[%d] %s start=%s end=%s next=%s loop=%s",
            i,
            tostring(section.name or ""),
            tostring(section.start_pos or ""),
            tostring(section.end_pos or ""),
            tostring(metadata.next or ""),
            tostring(metadata.loop or "")
        ))
    end

    return table.concat(lines, "\n")
end

function Navigation.format_navigation_plan(plan)
    plan = plan or {}

    local lines = {
        "current: " .. tostring(plan.current and plan.current.name or "nil"),
        "next: " .. tostring(plan.next and plan.next.name or "nil"),
        "previous: " .. tostring(plan.previous and plan.previous.name or "nil"),
        "loop_enabled: " .. tostring(plan.loop_enabled == true),
        "decision: " .. tostring(plan.decision or "nil")
    }

    if plan.warnings and #plan.warnings > 0 then
        table.insert(lines, "warnings: " .. table.concat(plan.warnings, "; "))
    end

    if plan.errors and #plan.errors > 0 then
        table.insert(lines, "errors: " .. table.concat(plan.errors, "; "))
    end

    return table.concat(lines, "\n")
end

return Navigation
