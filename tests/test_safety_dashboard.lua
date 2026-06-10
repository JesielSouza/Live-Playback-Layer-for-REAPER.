local safety_dashboard = require("scripts.safety_dashboard")

local function build_preflight(status)
    return {
        status = status or "blocked"
    }
end

local function build_gate(executable)
    return {
        executable = executable == true,
        reason = executable == true and "transport_execution_not_implemented" or "transport_disabled"
    }
end

local function build_simulation()
    return {
        message = "simulation_disabled"
    }
end

local function build_session(confirmed)
    return {
        transport_confirmed = confirmed == true
    }
end

local function contains(values, expected)
    for _, value in ipairs(values) do
        if value == expected then
            return true
        end
    end

    return false
end

local function run_safety_dashboard_tests()
    print("Running safety dashboard tests...\n")

    local missing_preflight = safety_dashboard.build(nil, build_gate(), build_simulation())
    assert(missing_preflight.safety_level == "invalid", "Test 1 failed")
    assert(missing_preflight.errors[1] == "missing_preflight_report", "Test 1 failed")
    print("Test 1 passed: missing preflight_report returns invalid/missing_preflight_report")

    local missing_gate = safety_dashboard.build(build_preflight(), nil, build_simulation())
    assert(missing_gate.safety_level == "invalid", "Test 2 failed")
    assert(missing_gate.errors[1] == "missing_gate_result", "Test 2 failed")
    print("Test 2 passed: missing gate_result returns invalid/missing_gate_result")

    local missing_simulation = safety_dashboard.build(build_preflight(), build_gate(), nil)
    assert(missing_simulation.safety_level == "invalid", "Test 3 failed")
    assert(missing_simulation.errors[1] == "missing_simulation_result", "Test 3 failed")
    print("Test 3 passed: missing simulation_result returns invalid/missing_simulation_result")

    local locked = safety_dashboard.build(build_preflight(), build_gate(), build_simulation(), build_session(false))
    assert(locked.transport_real_enabled == false, "Test 4 failed")
    print("Test 4 passed: transport_real_enabled is always false")

    assert(locked.execution_blocked == true, "Test 5 failed")
    print("Test 5 passed: execution_blocked is always true")

    assert(locked.safety_level == "locked", "Test 6 failed")
    print("Test 6 passed: no manual confirmation returns locked")

    local review = safety_dashboard.build(build_preflight(), build_gate(false), build_simulation(), build_session(true))
    assert(review.safety_level == "review", "Test 7 failed")
    print("Test 7 passed: confirmed plus non-executable gate returns review")

    local ready = safety_dashboard.build(build_preflight("simulated"), build_gate(true), build_simulation(), build_session(true))
    assert(ready.safety_level == "ready_for_future_execution", "Test 8 failed")
    print("Test 8 passed: ready_for_future_execution requires confirmed simulated executable")

    assert(contains(locked.guarantees, "transport_real_disabled"), "Test 9 failed")
    print("Test 9 passed: guarantees contains transport_real_disabled")

    assert(contains(locked.guarantees, "no_play_stop_calls"), "Test 10 failed")
    print("Test 10 passed: guarantees contains no_play_stop_calls")

    assert(contains(locked.guarantees, "no_main_on_command"), "Test 11 failed")
    print("Test 11 passed: guarantees contains no_main_on_command")

    assert(contains(locked.guarantees, "no_cursor_move"), "Test 12 failed")
    print("Test 12 passed: guarantees contains no_cursor_move")

    assert(contains(locked.guarantees, "no_seek"), "Test 13 failed")
    print("Test 13 passed: guarantees contains no_seek")

    assert(contains(locked.guarantees, "no_project_mutation"), "Test 14 failed")
    print("Test 14 passed: guarantees contains no_project_mutation")

    local formatted = safety_dashboard.format(locked)
    assert(string.find(formatted, "Safety Level"), "Test 15 failed")
    print("Test 15 passed: format contains Safety Level")

    assert(string.find(formatted, "Guarantees"), "Test 16 failed")
    print("Test 16 passed: format contains Guarantees")

    print("\nSafety dashboard tests passed successfully!")
end

run_safety_dashboard_tests()
