--[[
    transport_gate.lua
    Pure safety gate for future transport execution. This module only evaluates
    intent state and never calls REAPER APIs.
--]]

local TransportGate = {}

local function resolve_options(options)
    options = options or {}

    return {
        enable_transport = options.enable_transport == true,
        require_manual_confirmation = options.require_manual_confirmation ~= false,
        manual_confirmed = options.manual_confirmed == true,
        allow_project_mutation = options.allow_project_mutation == true
    }
end

local function build_result(reason, checks)
    return {
        ok = false,
        executable = false,
        blocked = true,
        reason = reason,
        checks = checks,
        warnings = {},
        errors = { reason }
    }
end

function TransportGate.evaluate(intent, runtime_snapshot, options)
    local resolved = resolve_options(options)
    local checks = {
        transport_enabled = resolved.enable_transport,
        intent_ok = type(intent) == "table" and intent.ok == true,
        runtime_ok = type(runtime_snapshot) == "table" and runtime_snapshot.ok == true,
        manual_confirmation_ok = not resolved.require_manual_confirmation or resolved.manual_confirmed,
        project_mutation_allowed = resolved.allow_project_mutation
    }

    if type(intent) ~= "table" then
        return build_result("missing_intent", checks)
    end

    if type(runtime_snapshot) ~= "table" then
        return build_result("missing_runtime_snapshot", checks)
    end

    if intent.ok ~= true then
        return build_result("intent_not_ok", checks)
    end

    if runtime_snapshot.ok ~= true then
        return build_result("runtime_not_ok", checks)
    end

    if resolved.enable_transport ~= true then
        return build_result("transport_disabled", checks)
    end

    if checks.manual_confirmation_ok ~= true then
        return build_result("manual_confirmation_required", checks)
    end

    if resolved.allow_project_mutation ~= true then
        return build_result("project_mutation_not_allowed", checks)
    end

    return build_result("transport_execution_not_implemented", checks)
end

function TransportGate.format_gate_result(gate_result)
    gate_result = gate_result or {}
    local checks = gate_result.checks or {}

    return table.concat({
        "Executable: " .. tostring(gate_result.executable == true),
        "Blocked: " .. tostring(gate_result.blocked == true),
        "Reason: " .. tostring(gate_result.reason or "nil"),
        "transport_enabled: " .. tostring(checks.transport_enabled == true),
        "intent_ok: " .. tostring(checks.intent_ok == true),
        "runtime_ok: " .. tostring(checks.runtime_ok == true),
        "manual_confirmation_ok: " .. tostring(checks.manual_confirmation_ok == true),
        "project_mutation_allowed: " .. tostring(checks.project_mutation_allowed == true)
    }, "\n")
end

return TransportGate
