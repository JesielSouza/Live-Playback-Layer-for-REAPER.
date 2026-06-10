local transport_control = require("scripts.transport_control")

local function build_snapshot()
    return {
        current_section = "VERSE_1",
        previous_section = "INTRO",
        next_section = "CHORUS_1",
        decision = "NEXT_SECTION_READY",
        sections = {
            { name = "INTRO", start = 0, ["end"] = 10 },
            { name = "VERSE_1", start = 10, ["end"] = 30 },
            { name = "CHORUS_1", start = 30, ["end"] = 50 },
            { name = "ENDING", start = 50, ["end"] = 60 }
        }
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

    -- v0.2 Song Map and Manual Intent tests
    local song_map = transport_control.build_song_map(build_snapshot())
    assert(song_map.ok == true, "Test 16 failed")
    assert(#song_map.sections == 4, "Test 16 failed")
    print("Test 16 passed: build_song_map works")

    local manual_intent = transport_control.build_manual_section_intent(build_snapshot(), "ENDING")
    assert(manual_intent.ok == true, "Test 17 failed")
    assert(manual_intent.action == "jump_to_section", "Test 17 failed")
    assert(manual_intent.target_section == "ENDING", "Test 17 failed")
    assert(manual_intent.target_position == 50, "Test 17 failed")
    print("Test 17 passed: build_manual_section_intent works")

    print("\nTransport control tests passed successfully!")
end

run_transport_control_tests()
