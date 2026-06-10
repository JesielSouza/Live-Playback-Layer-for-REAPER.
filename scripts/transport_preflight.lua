--[[
    transport_preflight.lua
    Read-only preflight report for transport intents. This module only
    consolidates in-memory state and never calls REAPER APIs.
--]]

local TransportPreflight = {}

local function new_report()
    return {
        ok = false,
        status = "invalid",
        action = nil,
        target_section = nil,
        manual_confirmed = false,
        gate_executable = false,
        gate_reason = nil,
        simulation_ok = false,
        simulation_message = nil,
        summary = "",
        warnings = {},
        errors = {}
    }
end

local function invalid_report(message)
    local report = new_report()
    report.summary = message
    table.insert(report.errors, message)
    return report
end

function TransportPreflight.build_report(intent, gate_result, simulation_result, ui_session_state)
    if intent == nil then
        return invalid_report("missing_intent")
    end

    if gate_result == nil then
        return invalid_report("missing_gate_result")
    end

    if simulation_result == nil then
        return invalid_report("missing_simulation_result")
    end

    ui_session_state = ui_session_state or {}

    local report = new_report()
    report.action = intent.action
    report.target_section = intent.target_section
    report.manual_confirmed = ui_session_state.transport_confirmed == true
    report.gate_executable = gate_result.executable == true
    report.gate_reason = gate_result.reason
    report.simulation_ok = simulation_result.ok == true
    report.simulation_message = simulation_result.message

    if gate_result.blocked == true then
        report.status = "blocked"
        report.summary = "preflight_blocked"
        return report
    end

    if report.manual_confirmed == true and report.simulation_ok == false then
        report.ok = true
        report.status = "ready_for_simulation"
        report.summary = "manual_confirmed_but_simulation_not_ready"
        return report
    end

    if report.simulation_ok == true then
        report.ok = true
        report.status = "simulated"
        report.summary = "simulation_ready"
        return report
    end

    report.status = "blocked"
    report.summary = "preflight_blocked"
    return report
end

function TransportPreflight.format_report(report)
    report = report or {}

    return table.concat({
        "Status: " .. tostring(report.status or "nil"),
        "Action: " .. tostring(report.action or "nil"),
        "Target Section: " .. tostring(report.target_section or "nil"),
        "Manual Confirmed: " .. tostring(report.manual_confirmed == true),
        "Gate Executable: " .. tostring(report.gate_executable == true),
        "Gate Reason: " .. tostring(report.gate_reason or "nil"),
        "Simulation OK: " .. tostring(report.simulation_ok == true),
        "Simulation Message: " .. tostring(report.simulation_message or "nil"),
        "Summary: " .. tostring(report.summary or "nil")
    }, "\n")
end

return TransportPreflight
