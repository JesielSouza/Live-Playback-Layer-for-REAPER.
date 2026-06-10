local pre_execution_audit = require("scripts.pre_execution_audit")

local function build_context(overrides)
    overrides = overrides or {}

    return {
        runtime_snapshot = overrides.runtime_snapshot or { current_section = "VERSE_1" },
        intent = overrides.intent or { action = "go_next", target_section = "CHORUS_1" },
        ui_session_state = overrides.ui_session_state or { transport_confirmed = true },
        gate_result = overrides.gate_result or { reason = "transport_disabled" },
        simulation_result = overrides.simulation_result or { message = "simulation_disabled" },
        preflight_report = overrides.preflight_report or { status = "blocked", summary = "preflight_blocked" },
        safety_dashboard = overrides.safety_dashboard or { safety_level = "review", gate_reason = "transport_disabled" },
        adapter_capabilities = overrides.adapter_capabilities or { real_transport_enabled = false },
        seek_plan = overrides.seek_plan or { target_position = 30, locked = true },
        readiness = overrides.readiness or {
            status = "review",
            ready = false,
            blockers = { "adapter_enabled" }
        }
    }
end

local function has_blocker(snapshot, expected)
    for _, blocker in ipairs(snapshot.blockers) do
        if blocker == expected then
            return true
        end
    end

    return false
end

local function run_pre_execution_audit_tests()
    print("Running pre-execution audit tests...\n")

    local missing = pre_execution_audit.build(nil)
    assert(missing.audit_status == "invalid", "Test 1 failed")
    assert(missing.errors[1] == "missing_context", "Test 1 failed")
    print("Test 1 passed: missing context returns invalid/missing_context")

    local snapshot = pre_execution_audit.build(build_context())
    assert(snapshot.current_section == "VERSE_1", "Test 2 failed")
    print("Test 2 passed: current_section is preserved")

    assert(snapshot.target_section == "CHORUS_1", "Test 3 failed")
    print("Test 3 passed: target_section is preserved")

    assert(snapshot.target_position == 30, "Test 4 failed")
    print("Test 4 passed: target_position is preserved")

    assert(snapshot.action == "go_next", "Test 5 failed")
    print("Test 5 passed: action is preserved")

    assert(snapshot.manual_confirmed == true, "Test 6 failed")
    print("Test 6 passed: manual_confirmed reflects session")

    assert(snapshot.gate_reason == "transport_disabled", "Test 7 failed")
    print("Test 7 passed: gate_reason is preserved")

    assert(snapshot.simulation_message == "simulation_disabled", "Test 8 failed")
    print("Test 8 passed: simulation_message is preserved")

    assert(snapshot.preflight_status == "blocked", "Test 9 failed")
    print("Test 9 passed: preflight_status is preserved")

    assert(snapshot.safety_level == "review", "Test 10 failed")
    print("Test 10 passed: safety_level is preserved")

    assert(snapshot.adapter_locked == true, "Test 11 failed")
    print("Test 11 passed: adapter_locked true when real_transport_enabled=false")

    assert(snapshot.seek_locked == true, "Test 12 failed")
    print("Test 12 passed: seek_locked true when seek_plan.locked=true")

    assert(snapshot.readiness_status == "review", "Test 13 failed")
    print("Test 13 passed: readiness_status is preserved")

    assert(snapshot.execution_allowed == false, "Test 14 failed")
    print("Test 14 passed: execution_allowed is always false")

    local unconfirmed = pre_execution_audit.build(build_context({
        ui_session_state = { transport_confirmed = false },
        readiness = { status = "blocked", ready = false, blockers = {} }
    }))
    assert(unconfirmed.audit_status == "blocked", "Test 15 failed")
    print("Test 15 passed: manual_confirmed=false returns audit_status blocked")

    assert(snapshot.audit_status == "review", "Test 16 failed")
    print("Test 16 passed: confirmed plus readiness review returns audit_status review")

    local impossible_ready = pre_execution_audit.build(build_context({
        readiness = { status = "ready", ready = true, blockers = {} }
    }))
    assert(impossible_ready.audit_status ~= "ready", "Test 17 failed")
    print("Test 17 passed: ready does not happen when execution_allowed=false")

    assert(has_blocker(snapshot, "adapter_enabled"), "Test 18 failed")
    print("Test 18 passed: blockers include readiness blockers")

    assert(has_blocker(snapshot, "transport_disabled"), "Test 19 failed")
    print("Test 19 passed: blockers include gate reason")

    local formatted = pre_execution_audit.format(snapshot)
    assert(string.find(formatted, "Audit Status"), "Test 20 failed")
    print("Test 20 passed: format contains Audit Status")

    assert(string.find(formatted, "Execution Allowed"), "Test 21 failed")
    print("Test 21 passed: format contains Execution Allowed")

    assert(string.find(formatted, "Blockers"), "Test 22 failed")
    print("Test 22 passed: format contains Blockers")

    print("\nPre-execution audit tests passed successfully!")
end

run_pre_execution_audit_tests()
