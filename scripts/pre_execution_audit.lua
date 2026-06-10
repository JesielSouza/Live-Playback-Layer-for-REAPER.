--[[
    pre_execution_audit.lua
    Consolidated read-only audit snapshot for future transport execution.
--]]

local PreExecutionAudit = {}

local function new_snapshot()
    return {
        ok = false,
        audit_status = "invalid",
        generated = true,
        current_section = nil,
        target_section = nil,
        target_position = nil,
        action = nil,
        manual_confirmed = false,
        gate_reason = nil,
        simulation_message = nil,
        preflight_status = nil,
        safety_level = nil,
        adapter_locked = false,
        seek_locked = false,
        readiness_status = nil,
        execution_allowed = false,
        summary = "audit_invalid",
        blockers = {},
        warnings = {},
        errors = {}
    }
end

local function append_blocker(blockers, value)
    if value ~= nil then
        table.insert(blockers, value)
    end
end

local function append_all_blockers(blockers, values)
    if type(values) ~= "table" then
        return
    end

    for _, value in ipairs(values) do
        append_blocker(blockers, value)
    end
end

function PreExecutionAudit.build(context)
    local snapshot = new_snapshot()

    if context == nil then
        table.insert(snapshot.errors, "missing_context")
        return snapshot
    end

    local runtime_snapshot = context.runtime_snapshot or {}
    local intent = context.intent or {}
    local ui_session_state = context.ui_session_state or {}
    local gate_result = context.gate_result or {}
    local simulation_result = context.simulation_result or {}
    local preflight_report = context.preflight_report or {}
    local safety_dashboard = context.safety_dashboard or {}
    local adapter_capabilities = context.adapter_capabilities or {}
    local seek_plan = context.seek_plan or {}
    local readiness = context.readiness or {}

    snapshot.current_section = runtime_snapshot.current_section
    snapshot.target_section = intent.target_section
    snapshot.target_position = seek_plan.target_position
    snapshot.action = intent.action
    snapshot.manual_confirmed = ui_session_state.transport_confirmed == true
    snapshot.gate_reason = gate_result.reason
    snapshot.simulation_message = simulation_result.message
    snapshot.preflight_status = preflight_report.status
    snapshot.safety_level = safety_dashboard.safety_level
    snapshot.adapter_locked = adapter_capabilities.real_transport_enabled ~= true
    snapshot.seek_locked = seek_plan.locked == true
    snapshot.readiness_status = readiness.status
    snapshot.execution_allowed = false

    append_all_blockers(snapshot.blockers, readiness.blockers)
    append_blocker(snapshot.blockers, gate_result.reason)
    append_blocker(snapshot.blockers, preflight_report.summary)
    append_blocker(snapshot.blockers, safety_dashboard.gate_reason)

    snapshot.ok = true
    if readiness.ready == true and snapshot.execution_allowed == true then
        snapshot.audit_status = "ready"
        snapshot.summary = "audit_ready"
    elseif snapshot.manual_confirmed == true and readiness.status == "review" then
        snapshot.audit_status = "review"
        snapshot.summary = "audit_review"
    else
        snapshot.audit_status = "blocked"
        snapshot.summary = "audit_blocked"
    end

    return snapshot
end

function PreExecutionAudit.format(snapshot)
    snapshot = snapshot or {}
    local blockers = snapshot.blockers or {}
    local lines = {
        "Audit Status: " .. tostring(snapshot.audit_status or "nil"),
        "Generated: " .. tostring(snapshot.generated == true),
        "Action: " .. tostring(snapshot.action or "nil"),
        "Current Section: " .. tostring(snapshot.current_section or "nil"),
        "Target Section: " .. tostring(snapshot.target_section or "nil"),
        "Target Position: " .. tostring(snapshot.target_position or "nil"),
        "Manual Confirmed: " .. tostring(snapshot.manual_confirmed == true),
        "Gate Reason: " .. tostring(snapshot.gate_reason or "nil"),
        "Simulation Message: " .. tostring(snapshot.simulation_message or "nil"),
        "Preflight Status: " .. tostring(snapshot.preflight_status or "nil"),
        "Safety Level: " .. tostring(snapshot.safety_level or "nil"),
        "Adapter Locked: " .. tostring(snapshot.adapter_locked == true),
        "Seek Locked: " .. tostring(snapshot.seek_locked == true),
        "Readiness Status: " .. tostring(snapshot.readiness_status or "nil"),
        "Execution Allowed: " .. tostring(snapshot.execution_allowed == true),
        "Summary: " .. tostring(snapshot.summary or "nil"),
        "Blockers:"
    }

    for _, blocker in ipairs(blockers) do
        table.insert(lines, "- " .. tostring(blocker))
    end

    return table.concat(lines, "\n")
end

return PreExecutionAudit
