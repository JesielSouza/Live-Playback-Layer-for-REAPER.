--[[
    transport_control.lua
    Dry-run-only transport intent builder. This module never calls REAPER
    transport APIs and does not mutate the project.
--]]

local TransportControl = {}
local TransportAdapter = require("scripts.transport_adapter")
local TransportGate = require("scripts.transport_gate")
local TransportSimulator = require("scripts.transport_simulator")

local VALID_ACTIONS = {
    go_next = true,
    go_previous = true,
    loop_current = true,
    stop_at_end = true
}

local function default_options(options)
    options = options or {}
    return {
        dry_run = options.dry_run ~= false
    }
end

local function new_intent(action, runtime_snapshot, options)
    return {
        ok = true,
        dry_run = options.dry_run,
        action = action,
        current_section = runtime_snapshot and runtime_snapshot.current_section or nil,
        target_section = nil,
        target_position = nil,
        decision = runtime_snapshot and runtime_snapshot.decision or nil,
        executable = false,
        reason = "dry_run_intent_only",
        warnings = {},
        errors = {}
    }
end

function TransportControl.build_intent(action, runtime_snapshot, options)
    local resolved_options = default_options(options)

    if type(runtime_snapshot) ~= "table" then
        return {
            ok = false,
            dry_run = resolved_options.dry_run,
            action = action,
            current_section = nil,
            target_section = nil,
            target_position = nil,
            decision = nil,
            executable = false,
            reason = "missing_runtime_snapshot",
            warnings = {},
            errors = { "missing_runtime_snapshot" }
        }
    end

    local intent = new_intent(action, runtime_snapshot, resolved_options)

    if not VALID_ACTIONS[action] then
        intent.ok = false
        intent.reason = "invalid_action"
        table.insert(intent.errors, "invalid_action")
        return intent
    end

    if action == "go_next" then
        intent.target_section = runtime_snapshot.next_section
    elseif action == "go_previous" then
        intent.target_section = runtime_snapshot.previous_section
    elseif action == "loop_current" then
        intent.target_section = runtime_snapshot.current_section
    elseif action == "stop_at_end" then
        intent.target_section = nil
        intent.decision = "STOP_AT_END_INTENT"
    end

    if action ~= "stop_at_end" and not intent.target_section then
        intent.ok = false
        intent.reason = "missing_target_section"
        table.insert(intent.errors, "missing_target_section")
    end

    if not intent.dry_run then
        intent.ok = false
        intent.reason = "transport_execution_not_enabled"
        table.insert(intent.errors, "transport_execution_not_enabled")
    end

    return intent
end

function TransportControl.format_intent(intent)
    intent = intent or {}

    return table.concat({
        "Action: " .. tostring(intent.action or "nil"),
        "Dry Run: " .. tostring(intent.dry_run == true),
        "Current Section: " .. tostring(intent.current_section or "nil"),
        "Target Section: " .. tostring(intent.target_section or "nil"),
        "Decision: " .. tostring(intent.decision or "nil"),
        "Executable: " .. tostring(intent.executable == true),
        "Reason: " .. tostring(intent.reason or "nil")
    }, "\n")
end

function TransportControl.can_execute(intent, runtime_snapshot, options)
    local gate_result = TransportGate.evaluate(intent, runtime_snapshot, options)
    if runtime_snapshot == nil then
        return false, "transport_execution_not_enabled", gate_result
    end

    return false, gate_result.reason, gate_result
end

function TransportControl.execute_intent(intent, options)
    return {
        ok = false,
        executed = false,
        dry_run = true,
        reason = "transport_execution_not_enabled"
    }
end

function TransportControl.simulate_intent(intent, runtime_snapshot, options)
    return TransportSimulator.simulate(intent, runtime_snapshot, options)
end

function TransportControl.execute_real_intent(intent, runtime_snapshot, gate_result, options)
    return TransportAdapter.execute_real(intent, runtime_snapshot, gate_result, options)
end

return TransportControl
