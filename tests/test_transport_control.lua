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

    -- MVP delegation tests
    local status = transport_control.get_playback_status({})
    assert(type(status) == "table", "Test 15 failed")
    print("Test 15 passed: get_playback_status works")

    local play_res = transport_control.execute_play({ enable_real_play = false })
    assert(play_res.executed == false, "Test 16 failed")
    print("Test 16 passed: execute_play delegates to adapter")

    local stop_res = transport_control.execute_stop({ enable_real_stop = false })
    assert(stop_res.executed == false, "Test 17 failed")
    print("Test 17 passed: execute_stop delegates to adapter")

    local next_intent2 = transport_control.build_next_intent(build_snapshot())
    assert(next_intent2.action == "go_next", "Test 18 failed")
    assert(next_intent2.target_section == "CHORUS_1", "Test 18 failed")
    print("Test 18 passed: build_next_intent works")

    local loop_intent2 = transport_control.build_loop_current_intent(build_snapshot())
    assert(loop_intent2.action == "loop_current", "Test 19 failed")
    assert(loop_intent2.target_section == "VERSE_1", "Test 19 failed")
    print("Test 19 passed: build_loop_current_intent works")

    print("\nTransport control tests passed successfully!")
end

run_transport_control_tests()
