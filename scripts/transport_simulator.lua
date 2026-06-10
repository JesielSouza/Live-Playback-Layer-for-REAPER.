--[[
    transport_simulator.lua
    In-memory transport execution simulator. This module never calls REAPER
    transport APIs and does not mutate the project.
--]]

local TransportSimulator = {}

local function new_result()
    return {
        ok = false,
        simulated = true,
        executed = false,
        action = nil,
        current_section = nil,
        target_section = nil,
        decision = nil,
        message = "",
        warnings = {},
        errors = {}
    }
end

local function fail(message)
    local result = new_result()
    result.message = message
    table.insert(result.errors, message)
    return result
end

function TransportSimulator.simulate(intent, runtime_snapshot, options)
    options = options or {}

    if intent == nil then
        return fail("missing_intent")
    end

    if runtime_snapshot == nil then
        return fail("missing_runtime_snapshot")
    end

    local result = new_result()
    result.action = intent.action
    result.current_section = intent.current_section or runtime_snapshot.current_section
    result.target_section = intent.target_section
    result.decision = intent.decision or runtime_snapshot.decision

    if options.enabled ~= true then
        result.message = "simulation_disabled"
        table.insert(result.errors, "simulation_disabled")
        return result
    end

    if options.manual_confirmed ~= true then
        result.message = "manual_confirmation_required"
        table.insert(result.errors, "manual_confirmation_required")
        return result
    end

    if intent.ok ~= true then
        result.message = "intent_not_ok"
        table.insert(result.errors, "intent_not_ok")
        return result
    end

    result.ok = true
    result.message = "simulation_success"
    result.target_section = intent.target_section

    return result
end

function TransportSimulator.format_result(result)
    result = result or {}

    return table.concat({
        "Simulated: " .. tostring(result.simulated == true),
        "Executed: " .. tostring(result.executed == true),
        "Action: " .. tostring(result.action or "nil"),
        "Current Section: " .. tostring(result.current_section or "nil"),
        "Target Section: " .. tostring(result.target_section or "nil"),
        "Decision: " .. tostring(result.decision or "nil"),
        "Message: " .. tostring(result.message or "nil")
    }, "\n")
end

return TransportSimulator
