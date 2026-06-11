local transport_control = require("scripts.transport_control")
local ui_session = require("scripts.ui_session")

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

    -- v0.6 Live Control intents
    local q_intent = transport_control.build_queue_intent(build_snapshot(), { section_id = "CHORUS_1", target_position = 30.0 })
    assert(q_intent.action == "live_queue_jump", "Test 20 failed")
    assert(q_intent.target_section == "CHORUS_1", "Test 20 failed")
    print("Test 20 passed: build_queue_intent works")

    local l_intent = transport_control.build_loop_mode_intent(build_snapshot(), { enabled = true, section_id = "VERSE_1", target_position = 10.0 })
    assert(l_intent.action == "infinite_loop", "Test 21 failed")
    assert(l_intent.target_section == "VERSE_1", "Test 21 failed")
    print("Test 21 passed: build_loop_mode_intent works")

    -- resolve_active_intent priority tests
    local session = ui_session.create()
    local snap = build_snapshot()
    
    local i1, src1 = transport_control.resolve_active_intent(snap, session)
    assert(src1 == "next_section", "Test 22 failed")
    
    ui_session.select_section(session, "ENDING", 50.0)
    local i2, src2 = transport_control.resolve_active_intent(snap, session)
    assert(src2 == "selected_section", "Test 23 failed")
    
    ui_session.add_to_live_queue(session, "CHORUS_1", { target_position = 30.0 })
    local i3, src3 = transport_control.resolve_active_intent(snap, session)
    assert(src3 == "live_queue", "Test 24 failed")
    
    ui_session.enable_infinite_loop(session, "VERSE_1", { target_position = 10.0 })
    local i4, src4 = transport_control.resolve_active_intent(snap, session)
    assert(src4 == "infinite_loop", "Test 25 failed")
    assert(i4.target_position == 10.0, "Test 25 failed")
    print("Test 22-25 passed: resolve_active_intent priority works without get_state")

    -- Test missing fields
    local empty_session = {}
    local i5, src5 = transport_control.resolve_active_intent(snap, empty_session)
    assert(src5 == "next_section", "Test 26 failed")
    print("Test 26 passed: resolve_active_intent handles empty session table")

    print("\nTransport control tests passed successfully!")
end

run_transport_control_tests()
