local transport_preflight = require("scripts.transport_preflight")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        target_section = "CHORUS_1"
    }
end

local function build_gate_result(blocked)
    return {
        executable = false,
        blocked = blocked == true,
        reason = blocked == true and "transport_disabled" or "not_blocked"
    }
end

local function build_simulation_result(ok)
    return {
        ok = ok == true,
        message = ok == true and "simulation_success" or "simulation_disabled"
    }
end

local function build_session_state(confirmed)
    return {
        transport_confirmed = confirmed == true
    }
end

local function run_transport_preflight_tests()
    print("Running transport preflight tests...\n")

    local missing_intent = transport_preflight.build_report(nil, build_gate_result(), build_simulation_result())
    assert(missing_intent.status == "invalid", "Test 1 failed")
    assert(missing_intent.errors[1] == "missing_intent", "Test 1 failed")
    print("Test 1 passed: missing intent returns invalid/missing_intent")

    local missing_gate = transport_preflight.build_report(build_intent(), nil, build_simulation_result())
    assert(missing_gate.status == "invalid", "Test 2 failed")
    assert(missing_gate.errors[1] == "missing_gate_result", "Test 2 failed")
    print("Test 2 passed: missing gate_result returns invalid/missing_gate_result")

    local missing_simulation = transport_preflight.build_report(build_intent(), build_gate_result(), nil)
    assert(missing_simulation.status == "invalid", "Test 3 failed")
    assert(missing_simulation.errors[1] == "missing_simulation_result", "Test 3 failed")
    print("Test 3 passed: missing simulation_result returns invalid/missing_simulation_result")

    local blocked = transport_preflight.build_report(
        build_intent(),
        build_gate_result(true),
        build_simulation_result(false),
        build_session_state(false)
    )
    assert(blocked.status == "blocked", "Test 4 failed")
    assert(blocked.summary == "preflight_blocked", "Test 4 failed")
    print("Test 4 passed: blocked gate returns status blocked")

    local ready_for_simulation = transport_preflight.build_report(
        build_intent(),
        build_gate_result(false),
        build_simulation_result(false),
        build_session_state(true)
    )
    assert(ready_for_simulation.status == "ready_for_simulation", "Test 5 failed")
    assert(ready_for_simulation.summary == "manual_confirmed_but_simulation_not_ready", "Test 5 failed")
    print("Test 5 passed: manual confirmed plus simulation not ok returns ready_for_simulation")

    local simulated = transport_preflight.build_report(
        build_intent(),
        build_gate_result(false),
        build_simulation_result(true),
        build_session_state(true)
    )
    assert(simulated.status == "simulated", "Test 6 failed")
    print("Test 6 passed: simulation ok returns simulated")

    assert(simulated.action == "go_next", "Test 7 failed")
    print("Test 7 passed: action is preserved")

    assert(simulated.target_section == "CHORUS_1", "Test 8 failed")
    print("Test 8 passed: target_section is preserved")

    assert(simulated.manual_confirmed == true, "Test 9 failed")
    print("Test 9 passed: manual_confirmed reflects ui_session_state")

    assert(blocked.gate_reason == "transport_disabled", "Test 10 failed")
    print("Test 10 passed: gate_reason is preserved")

    assert(blocked.simulation_message == "simulation_disabled", "Test 11 failed")
    print("Test 11 passed: simulation_message is preserved")

    local formatted = transport_preflight.format_report(simulated)
    assert(string.find(formatted, "Status"), "Test 12 failed")
    print("Test 12 passed: format_report contains Status")

    assert(string.find(formatted, "Summary"), "Test 13 failed")
    print("Test 13 passed: format_report contains Summary")

    print("\nTransport preflight tests passed successfully!")
end

run_transport_preflight_tests()
