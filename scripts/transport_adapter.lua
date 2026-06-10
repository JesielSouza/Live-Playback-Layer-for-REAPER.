--[[
    transport_adapter.lua
    Future real transport adapter interface. The implementation is locked and
    returns disabled results only.
--]]

local TransportAdapter = {}
local SeekPlan = require("scripts.seek_plan")

function TransportAdapter.get_capabilities(options)
    return {
        real_transport_supported = false,
        real_transport_enabled = false,
        can_play_stop = false,
        can_seek = false,
        can_mutate_project = false,
        backend = "reaper",
        reason = "real_transport_locked"
    }
end

local function validation_result(reason)
    return {
        ok = false,
        executable = false,
        reason = reason,
        warnings = {},
        errors = { reason }
    }
end

function TransportAdapter.validate_real_execution(intent, runtime_snapshot, gate_result, options)
    if intent == nil then
        return validation_result("missing_intent")
    end

    if runtime_snapshot == nil then
        return validation_result("missing_runtime_snapshot")
    end

    if gate_result == nil then
        return validation_result("missing_gate_result")
    end

    if intent.ok ~= true then
        return validation_result("intent_not_ok")
    end

    if gate_result.executable ~= true then
        return validation_result("gate_not_executable")
    end

    return validation_result("real_transport_locked")
end

function TransportAdapter.build_seek_plan(intent, runtime_snapshot, options)
    return SeekPlan.build(intent, runtime_snapshot, options)
end

function TransportAdapter.execute_real(intent, runtime_snapshot, gate_result, options)
    local validation = TransportAdapter.validate_real_execution(intent, runtime_snapshot, gate_result, options)
    local seek_plan = nil

    if type(intent) == "table" then
        seek_plan = TransportAdapter.build_seek_plan(intent, runtime_snapshot, options)
    end

    return {
        ok = false,
        executed = false,
        real_transport_attempted = false,
        reason = validation.reason or "real_transport_locked",
        action = seek_plan and seek_plan.action or type(intent) == "table" and intent.action or nil,
        target_section = seek_plan and seek_plan.target_section or type(intent) == "table" and intent.target_section or nil,
        warnings = {},
        errors = { validation.reason or "real_transport_locked" }
    }
end

function TransportAdapter.format_execution_result(result)
    result = result or {}

    return table.concat({
        "Executed: " .. tostring(result.executed == true),
        "Real Transport Attempted: " .. tostring(result.real_transport_attempted == true),
        "Reason: " .. tostring(result.reason or "nil"),
        "Action: " .. tostring(result.action or "nil"),
        "Target Section: " .. tostring(result.target_section or "nil")
    }, "\n")
end

return TransportAdapter
