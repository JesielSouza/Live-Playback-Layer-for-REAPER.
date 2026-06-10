--[[
    transport_readiness.lua
    Read-only checklist for future real transport enablement.
--]]

local TransportReadiness = {}

local CHECK_ORDER = {
    "adapter_supported",
    "adapter_enabled",
    "gate_executable",
    "preflight_simulated",
    "safety_not_blocked",
    "seek_plan_ok",
    "seek_plan_unlocked",
    "manual_confirmed"
}

local function empty_report()
    return {
        ok = false,
        ready = false,
        status = "invalid",
        checks = {
            adapter_supported = false,
            adapter_enabled = false,
            gate_executable = false,
            preflight_simulated = false,
            safety_not_blocked = false,
            seek_plan_ok = false,
            seek_plan_unlocked = false,
            manual_confirmed = false
        },
        blockers = {},
        warnings = {},
        summary = "readiness_invalid"
    }
end

local function add_blockers(report)
    for _, check_name in ipairs(CHECK_ORDER) do
        if report.checks[check_name] ~= true then
            table.insert(report.blockers, check_name)
        end
    end
end

function TransportReadiness.build(context)
    if context == nil then
        local report = empty_report()
        table.insert(report.blockers, "missing_context")
        return report
    end

    local adapter_capabilities = context.adapter_capabilities or {}
    local gate_result = context.gate_result or {}
    local preflight_report = context.preflight_report or {}
    local safety_dashboard = context.safety_dashboard or {}
    local seek_plan = context.seek_plan or {}
    local ui_session_state = context.ui_session_state or {}

    local report = empty_report()
    report.checks.adapter_supported = adapter_capabilities.real_transport_supported == true
    report.checks.adapter_enabled = adapter_capabilities.real_transport_enabled == true
    report.checks.gate_executable = gate_result.executable == true
    report.checks.preflight_simulated = preflight_report.status == "simulated"
    report.checks.safety_not_blocked = safety_dashboard.execution_blocked ~= true
    report.checks.seek_plan_ok = seek_plan.ok == true
    report.checks.seek_plan_unlocked = seek_plan.locked ~= true
    report.checks.manual_confirmed = ui_session_state.transport_confirmed == true

    add_blockers(report)
    report.ready = #report.blockers == 0
    report.ok = true

    if report.ready then
        report.status = "ready"
        report.summary = "readiness_ready"
    elseif report.checks.manual_confirmed == true then
        report.status = "review"
        report.summary = "readiness_review"
    else
        report.status = "blocked"
        report.summary = "readiness_blocked"
    end

    return report
end

function TransportReadiness.format(report)
    report = report or {}
    local checks = report.checks or {}
    local blockers = report.blockers or {}
    local lines = {
        "Status: " .. tostring(report.status or "nil"),
        "Ready: " .. tostring(report.ready == true),
        "Summary: " .. tostring(report.summary or "nil"),
        "Checks:"
    }

    for _, check_name in ipairs(CHECK_ORDER) do
        table.insert(lines, "- " .. check_name .. ": " .. tostring(checks[check_name] == true))
    end

    table.insert(lines, "Blockers:")
    for _, blocker in ipairs(blockers) do
        table.insert(lines, "- " .. tostring(blocker))
    end

    return table.concat(lines, "\n")
end

return TransportReadiness
