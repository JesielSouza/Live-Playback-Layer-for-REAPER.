local transport_adapter = require("scripts.transport_adapter")
local transport_control = require("scripts.transport_control")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        target_section = "CHORUS_1"
    }
end

local function build_runtime()
    return {
        ok = true,
        current_section = "VERSE_1",
        next_section = "CHORUS_1"
    }
end

local function build_gate(executable)
    return {
        executable = executable == true
    }
end

local function run_transport_adapter_tests()
    print("Running transport adapter tests...\n")

    local capabilities = transport_adapter.get_capabilities({ real_transport_enabled = true })
    assert(capabilities.real_transport_supported == false, "Test 1 failed")
    print("Test 1 passed: capabilities real_transport_supported=false")

    assert(capabilities.real_transport_enabled == false, "Test 2 failed")
    print("Test 2 passed: capabilities real_transport_enabled=false")

    assert(capabilities.can_play_stop == false, "Test 3 failed")
    print("Test 3 passed: capabilities can_play_stop=false")

    assert(capabilities.can_seek == false, "Test 4 failed")
    print("Test 4 passed: capabilities can_seek=false")

    assert(capabilities.can_mutate_project == false, "Test 5 failed")
    print("Test 5 passed: capabilities can_mutate_project=false")

    local missing_intent = transport_adapter.validate_real_execution(nil, build_runtime(), build_gate(true))
    assert(missing_intent.reason == "missing_intent", "Test 6 failed")
    print("Test 6 passed: validate without intent returns missing_intent")

    local missing_runtime = transport_adapter.validate_real_execution(build_intent(), nil, build_gate(true))
    assert(missing_runtime.reason == "missing_runtime_snapshot", "Test 7 failed")
    print("Test 7 passed: validate without runtime returns missing_runtime_snapshot")

    local missing_gate = transport_adapter.validate_real_execution(build_intent(), build_runtime(), nil)
    assert(missing_gate.reason == "missing_gate_result", "Test 8 failed")
    print("Test 8 passed: validate without gate returns missing_gate_result")

    local bad_intent = build_intent()
    bad_intent.ok = false
    local intent_not_ok = transport_adapter.validate_real_execution(bad_intent, build_runtime(), build_gate(true))
    assert(intent_not_ok.reason == "intent_not_ok", "Test 9 failed")
    print("Test 9 passed: validate ok=false intent returns intent_not_ok")

    local gate_not_executable = transport_adapter.validate_real_execution(build_intent(), build_runtime(), build_gate(false))
    assert(gate_not_executable.reason == "gate_not_executable", "Test 10 failed")
    print("Test 10 passed: validate executable=false gate returns gate_not_executable")

    local locked = transport_adapter.validate_real_execution(build_intent(), build_runtime(), build_gate(true))
    assert(locked.reason == "real_transport_locked", "Test 11 failed")
    assert(locked.executable == false, "Test 11 failed")
    print("Test 11 passed: validate all ok still returns real_transport_locked")

    local execution = transport_adapter.execute_real(build_intent(), build_runtime(), build_gate(true))
    assert(execution.executed == false, "Test 12 failed")
    print("Test 12 passed: execute_real never executes")

    assert(execution.real_transport_attempted == false, "Test 13 failed")
    print("Test 13 passed: execute_real returns real_transport_attempted=false")

    assert(execution.action == "go_next", "Test 14 failed")
    print("Test 14 passed: execute_real preserves action")

    assert(execution.target_section == "CHORUS_1", "Test 15 failed")
    print("Test 15 passed: execute_real preserves target_section")

    local formatted = transport_adapter.format_execution_result(execution)
    assert(string.find(formatted, "Executed"), "Test 16 failed")
    print("Test 16 passed: format_execution_result contains Executed")

    assert(string.find(formatted, "Reason"), "Test 17 failed")
    print("Test 17 passed: format_execution_result contains Reason")

    local control_execution = transport_control.execute_real_intent(build_intent(), build_runtime(), build_gate(true))
    assert(control_execution.executed == false, "Test 18 failed")
    print("Test 18 passed: TransportControl.execute_real_intent returns executed=false")

    print("\nTransport adapter tests passed successfully!")
end

run_transport_adapter_tests()
