local transport_simulator = require("scripts.transport_simulator")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        current_section = "VERSE_1",
        target_section = "CHORUS_1",
        decision = "NEXT_SECTION_READY",
        warnings = {},
        errors = {}
    }
end

local function build_runtime()
    return {
        ok = true,
        current_section = "VERSE_1",
        next_section = "CHORUS_1",
        decision = "NEXT_SECTION_READY"
    }
end

local function run_transport_simulator_tests()
    print("Running transport simulator tests...\n")

    local missing_intent = transport_simulator.simulate(nil, build_runtime(), {
        enabled = true,
        manual_confirmed = true
    })
    assert(missing_intent.ok == false, "Test 1 failed")
    assert(missing_intent.errors[1] == "missing_intent", "Test 1 failed")
    print("Test 1 passed: simulate without intent returns missing_intent")

    local missing_runtime = transport_simulator.simulate(build_intent(), nil, {
        enabled = true,
        manual_confirmed = true
    })
    assert(missing_runtime.ok == false, "Test 2 failed")
    assert(missing_runtime.errors[1] == "missing_runtime_snapshot", "Test 2 failed")
    print("Test 2 passed: simulate without runtime returns missing_runtime_snapshot")

    local disabled = transport_simulator.simulate(build_intent(), build_runtime(), {
        enabled = false,
        manual_confirmed = true
    })
    assert(disabled.ok == false, "Test 3 failed")
    assert(disabled.message == "simulation_disabled", "Test 3 failed")
    print("Test 3 passed: enabled=false returns simulation_disabled")

    local manual_required = transport_simulator.simulate(build_intent(), build_runtime(), {
        enabled = true,
        manual_confirmed = false
    })
    assert(manual_required.ok == false, "Test 4 failed")
    assert(manual_required.message == "manual_confirmation_required", "Test 4 failed")
    print("Test 4 passed: manual_confirmed=false returns manual_confirmation_required")

    local bad_intent = build_intent()
    bad_intent.ok = false
    local intent_not_ok = transport_simulator.simulate(bad_intent, build_runtime(), {
        enabled = true,
        manual_confirmed = true
    })
    assert(intent_not_ok.ok == false, "Test 5 failed")
    assert(intent_not_ok.message == "intent_not_ok", "Test 5 failed")
    print("Test 5 passed: intent_not_ok returns intent_not_ok")

    local valid = transport_simulator.simulate(build_intent(), build_runtime(), {
        enabled = true,
        manual_confirmed = true
    })
    assert(valid.ok == true, "Test 6 failed")
    print("Test 6 passed: valid path returns ok=true")

    assert(valid.simulated == true, "Test 7 failed")
    print("Test 7 passed: valid path returns simulated=true")

    assert(valid.executed == false, "Test 8 failed")
    print("Test 8 passed: valid path returns executed=false")

    assert(valid.target_section == "CHORUS_1", "Test 9 failed")
    print("Test 9 passed: valid path preserves target_section")

    local formatted = transport_simulator.format_result(valid)
    assert(string.find(formatted, "Simulated"), "Test 10 failed")
    print("Test 10 passed: format_result contains Simulated")

    assert(string.find(formatted, "Executed"), "Test 11 failed")
    print("Test 11 passed: format_result contains Executed")

    assert(string.find(formatted, "Target Section"), "Test 12 failed")
    print("Test 12 passed: format_result contains Target Section")

    print("\nTransport simulator tests passed successfully!")
end

run_transport_simulator_tests()
