local transport_gate = require("scripts.transport_gate")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        current_section = "VERSE_1",
        target_section = "CHORUS_1",
        executable = false,
        reason = "dry_run_intent_only",
        warnings = {},
        errors = {}
    }
end

local function build_runtime()
    return {
        ok = true,
        app_state = "SONG_LOADED",
        current_section = "VERSE_1",
        next_section = "CHORUS_1"
    }
end

local function run_transport_gate_tests()
    print("Running transport gate tests...\n")

    local missing_intent = transport_gate.evaluate(nil, build_runtime())
    assert(missing_intent.reason == "missing_intent", "Test 1 failed")
    print("Test 1 passed: evaluate without intent returns missing_intent")

    local missing_runtime = transport_gate.evaluate(build_intent(), nil)
    assert(missing_runtime.reason == "missing_runtime_snapshot", "Test 2 failed")
    print("Test 2 passed: evaluate without runtime returns missing_runtime_snapshot")

    local bad_intent = build_intent()
    bad_intent.ok = false
    local intent_not_ok = transport_gate.evaluate(bad_intent, build_runtime())
    assert(intent_not_ok.reason == "intent_not_ok", "Test 3 failed")
    print("Test 3 passed: intent_not_ok blocks")

    local bad_runtime = build_runtime()
    bad_runtime.ok = false
    local runtime_not_ok = transport_gate.evaluate(build_intent(), bad_runtime)
    assert(runtime_not_ok.reason == "runtime_not_ok", "Test 4 failed")
    print("Test 4 passed: runtime_not_ok blocks")

    local transport_disabled = transport_gate.evaluate(build_intent(), build_runtime())
    assert(transport_disabled.reason == "transport_disabled", "Test 5 failed")
    print("Test 5 passed: enable_transport=false blocks")

    local manual_required = transport_gate.evaluate(build_intent(), build_runtime(), {
        enable_transport = true
    })
    assert(manual_required.reason == "manual_confirmation_required", "Test 6 failed")
    print("Test 6 passed: missing manual confirmation blocks")

    local mutation_blocked = transport_gate.evaluate(build_intent(), build_runtime(), {
        enable_transport = true,
        manual_confirmed = true
    })
    assert(mutation_blocked.reason == "project_mutation_not_allowed", "Test 7 failed")
    print("Test 7 passed: mutation not allowed blocks")

    local all_checks = transport_gate.evaluate(build_intent(), build_runtime(), {
        enable_transport = true,
        manual_confirmed = true,
        allow_project_mutation = true
    })
    assert(all_checks.executable == false, "Test 8 failed")
    assert(all_checks.reason == "transport_execution_not_implemented", "Test 8 failed")
    print("Test 8 passed: all checks still return not implemented")

    local formatted = transport_gate.format_gate_result(all_checks)
    assert(string.find(formatted, "Executable"), "Test 9 failed")
    print("Test 9 passed: format_gate_result contains Executable")

    assert(string.find(formatted, "Reason"), "Test 10 failed")
    print("Test 10 passed: format_gate_result contains Reason")

    assert(all_checks.checks.transport_enabled == true, "Test 11 failed")
    print("Test 11 passed: checks.transport_enabled reflects option")

    assert(all_checks.checks.manual_confirmation_ok == true, "Test 12 failed")
    print("Test 12 passed: checks.manual_confirmation_ok reflects option")

    assert(all_checks.checks.project_mutation_allowed == true, "Test 13 failed")
    print("Test 13 passed: checks.project_mutation_allowed reflects option")

    print("\nTransport gate tests passed successfully!")
end

run_transport_gate_tests()
