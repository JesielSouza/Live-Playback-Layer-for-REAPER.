--[[
    seek_plan.lua
    Builds a future seek plan as read-only data. This module never calls any
    host API and never changes playback state.
--]]

local SeekPlan = {}

local function new_plan()
    return {
        ok = false,
        action = nil,
        current_section = nil,
        target_section = nil,
        target_position = nil,
        seek_required = false,
        locked = true,
        reason = "",
        warnings = {},
        errors = {}
    }
end

local function fail(reason, intent, runtime_snapshot)
    local plan = new_plan()
    plan.reason = reason
    plan.action = type(intent) == "table" and intent.action or nil
    plan.current_section = type(intent) == "table" and intent.current_section
        or type(runtime_snapshot) == "table" and runtime_snapshot.current_section
        or nil
    plan.target_section = type(intent) == "table" and intent.target_section or nil
    plan.target_position = type(intent) == "table" and intent.target_position or nil
    table.insert(plan.errors, reason)
    return plan
end

local function section_matches(section, target_section)
    if type(section) ~= "table" then
        return false
    end

    return section.key == target_section
        or section.name == target_section
        or section.id == target_section
end

local function get_sections(runtime_snapshot)
    if type(runtime_snapshot.sections) == "table" then
        return runtime_snapshot.sections
    end

    local context = runtime_snapshot.context or {}
    local validation = runtime_snapshot.validation or context.validation or {}

    if type(validation.sections) == "table" then
        return validation.sections
    end

    return nil
end

local function get_section_position(section)
    if type(section.start) == "number" then
        return section.start
    end

    if type(section.start_time) == "number" then
        return section.start_time
    end

    if type(section.start_position) == "number" then
        return section.start_position
    end

    if type(section.position) == "number" then
        return section.position
    end

    if type(section.region_start) == "number" then
        return section.region_start
    end

    if type(section.start_pos) == "number" then
        return section.start_pos
    end

    return nil
end

local function resolve_target_position(intent, runtime_snapshot)
    if type(intent.target_position) == "number" then
        return intent.target_position
    end

    local sections = get_sections(runtime_snapshot)
    if type(sections) ~= "table" then
        return nil
    end

    for _, section in ipairs(sections) do
        local section_position = get_section_position(section)
        if section_matches(section, intent.target_section) and type(section_position) == "number" then
            return section_position
        end
    end

    return nil
end

function SeekPlan.build(intent, runtime_snapshot, options)
    if intent == nil then
        return fail("missing_intent", intent, runtime_snapshot)
    end

    if runtime_snapshot == nil then
        return fail("missing_runtime_snapshot", intent, runtime_snapshot)
    end

    if intent.ok ~= true then
        return fail("intent_not_ok", intent, runtime_snapshot)
    end

    if intent.target_section == nil then
        return fail("missing_target_section", intent, runtime_snapshot)
    end

    local target_position = resolve_target_position(intent, runtime_snapshot)
    if target_position == nil then
        return fail("missing_target_position", intent, runtime_snapshot)
    end

    return {
        ok = true,
        action = intent.action,
        current_section = intent.current_section or runtime_snapshot.current_section,
        target_section = intent.target_section,
        target_position = target_position,
        seek_required = true,
        locked = true,
        reason = "seek_plan_locked",
        warnings = {},
        errors = {}
    }
end

function SeekPlan.validate(plan, options)
    if plan == nil then
        return {
            ok = false,
            executable = false,
            reason = "missing_seek_plan",
            warnings = {},
            errors = { "missing_seek_plan" }
        }
    end

    if plan.ok ~= true then
        return {
            ok = false,
            executable = false,
            reason = "seek_plan_not_ok",
            warnings = {},
            errors = { "seek_plan_not_ok" }
        }
    end

    return {
        ok = false,
        executable = false,
        reason = "seek_execution_locked",
        warnings = {},
        errors = { "seek_execution_locked" }
    }
end

function SeekPlan.format(plan)
    plan = plan or {}

    return table.concat({
        "Action: " .. tostring(plan.action or "nil"),
        "Current Section: " .. tostring(plan.current_section or "nil"),
        "Target Section: " .. tostring(plan.target_section or "nil"),
        "Target Position: " .. tostring(plan.target_position or "nil"),
        "Seek Required: " .. tostring(plan.seek_required == true),
        "Locked: " .. tostring(plan.locked == true),
        "Reason: " .. tostring(plan.reason or "nil")
    }, "\n")
end

return SeekPlan
