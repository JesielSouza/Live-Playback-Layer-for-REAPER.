--[[
    safety_dashboard.lua
    Read-only operational safety dashboard. This module consolidates state and
    never calls REAPER APIs or triggers transport actions.
--]]

local SafetyDashboard = {}

local GUARANTEES = {
    "transport_real_disabled",
    "no_play_stop_calls",
    "no_command_dispatch",
    "no_cursor_move",
    "no_seek",
    "no_project_mutation"
}

local function copy_guarantees()
    local out = {}
    for _, guarantee in ipairs(GUARANTEES) do
        table.insert(out, guarantee)
    end
    return out
end

local function new_dashboard()
    return {
        ok = false,
        safety_level = "invalid",
        transport_real_enabled = false,
        execution_blocked = true,
        manual_confirmation_active = false,
        gate_reason = nil,
        preflight_status = nil,
        simulation_message = nil,
        guarantees = copy_guarantees(),
        warnings = {},
        errors = {}
    }
end

local function invalid_dashboard(message)
    local dashboard = new_dashboard()
    table.insert(dashboard.errors, message)
    return dashboard
end

function SafetyDashboard.build(preflight_report, gate_result, simulation_result, ui_session_state)
    if preflight_report == nil then
        return invalid_dashboard("missing_preflight_report")
    end

    if gate_result == nil then
        return invalid_dashboard("missing_gate_result")
    end

    if simulation_result == nil then
        return invalid_dashboard("missing_simulation_result")
    end

    ui_session_state = ui_session_state or {}

    local dashboard = new_dashboard()
    dashboard.manual_confirmation_active = ui_session_state.transport_confirmed == true
    dashboard.gate_reason = gate_result.reason
    dashboard.preflight_status = preflight_report.status
    dashboard.simulation_message = simulation_result.message

    if dashboard.manual_confirmation_active ~= true then
        dashboard.safety_level = "locked"
        return dashboard
    end

    if preflight_report.status == "simulated" and gate_result.executable == true then
        dashboard.ok = true
        dashboard.safety_level = "ready_for_future_execution"
        return dashboard
    end

    dashboard.ok = true
    dashboard.safety_level = "review"
    return dashboard
end

function SafetyDashboard.format(dashboard)
    dashboard = dashboard or {}
    local guarantees = dashboard.guarantees or {}
    local lines = {
        "Safety Level: " .. tostring(dashboard.safety_level or "nil"),
        "Transport Real Enabled: " .. tostring(dashboard.transport_real_enabled == true),
        "Execution Blocked: " .. tostring(dashboard.execution_blocked ~= false),
        "Manual Confirmation Active: " .. tostring(dashboard.manual_confirmation_active == true),
        "Gate Reason: " .. tostring(dashboard.gate_reason or "nil"),
        "Preflight Status: " .. tostring(dashboard.preflight_status or "nil"),
        "Simulation Message: " .. tostring(dashboard.simulation_message or "nil"),
        "Guarantees:"
    }

    for _, guarantee in ipairs(guarantees) do
        table.insert(lines, "- " .. tostring(guarantee))
    end

    return table.concat(lines, "\n")
end

return SafetyDashboard
