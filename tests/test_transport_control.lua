local transport_control = require("scripts.transport_control")

local function build_snapshot()
    return {
        current_section = "VERSE_1",
        previous_section = "INTRO",
        next_section = "CHORUS_1",
        decision = "NEXT_SECTION_READY"
    }
end

local function run_transport_control_tests()
    print("Running transport control tests...\n")

    local missing = transport_control.build_intent("go_next", nil)
    assert(missing.ok == false, "Test 1 failed")
    assert(missing.errors[1] == "missing_runtime_snapshot", "Test 1 failed")
    print("Test 1 passed: build_intent nil snapshot returns ok=false")

    local next_intent = transport_control.build_intent("go_next", build_snapshot())
    assert(next_intent.target_section == "CHORUS_1", "Test 2 failed")
    print("Test 2 passed: go_next uses next_section as target")

    local previous_intent = transport_control.build_intent("go_previous", build_snapshot())
    assert(previous_intent.target_section == "INTRO", "Test 3 failed")
    print("Test 3 passed: go_previous uses previous_section as target")

    local loop_intent = transport_control.build_intent("loop_current", build_snapshot())
    assert(loop_intent.target_section == "VERSE_1", "Test 4 failed")
    print("Test 4 passed: loop_current uses current_section as target")

    local stop_intent = transport_control.build_intent("stop_at_end", build_snapshot())
    assert(stop_intent.decision == "STOP_AT_END_INTENT", "Test 5 failed")
    print("Test 5 passed: stop_at_end generates STOP_AT_END_INTENT")

    assert(next_intent.dry_run == true, "Test 6 failed")
    print("Test 6 passed: dry_run default is true")

    assert(next_intent.executable == false, "Test 7 failed")
    print("Test 7 passed: executable is false")

    local can_execute, reason = transport_control.can_execute(next_intent)
    assert(can_execute == false, "Test 8 failed")
    assert(reason == "transport_execution_not_enabled", "Test 8 failed")
    print("Test 8 passed: can_execute returns false")

    local execution = transport_control.execute_intent(next_intent)
    assert(execution.executed == false, "Test 9 failed")
    assert(execution.reason == "transport_execution_not_enabled", "Test 9 failed")
    print("Test 9 passed: execute_intent does not execute")

    local formatted = transport_control.format_intent(next_intent)
    assert(string.find(formatted, "go_next"), "Test 10 failed")
    print("Test 10 passed: format_intent contains action")

    assert(string.find(formatted, "CHORUS_1"), "Test 11 failed")
    print("Test 11 passed: format_intent contains target_section")

    local no_next = transport_control.build_intent("go_next", { current_section = "ENDING" })
    assert(no_next.ok == false, "Test 12 failed")
    assert(no_next.errors[1] == "missing_target_section", "Test 12 failed")
    print("Test 12 passed: go_next without next_section returns ok=false")

    local no_previous = transport_control.build_intent("go_previous", { current_section = "INTRO" })
    assert(no_previous.ok == false, "Test 13 failed")
    assert(no_previous.errors[1] == "missing_target_section", "Test 13 failed")
    print("Test 13 passed: go_previous without previous_section returns ok=false")

    local no_current = transport_control.build_intent("loop_current", { next_section = "VERSE_1" })
    assert(no_current.ok == false, "Test 14 failed")
    assert(no_current.errors[1] == "missing_target_section", "Test 14 failed")
    print("Test 14 passed: loop_current without current_section returns ok=false")

    print("\nTransport control tests passed successfully!")
end

run_transport_control_tests()
