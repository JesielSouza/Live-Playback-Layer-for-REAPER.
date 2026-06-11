local ui_runtime = require("scripts.ui_runtime")
local ui_session = require("scripts.ui_session")
local mixer_state = require("scripts.mixer_state")

local function build_snapshot()
    return {
        ok = true,
        read_only = true,
        app_state = "SONG_LOADED",
        validation_status = "ready",
        validation_ok = true,
        reaper_available = true,
        position = 12,
        current_section = "VERSE_1",
        previous_section = "INTRO",
        next_section = "CHORUS_1",
        decision = "NEXT_SECTION_READY",
        section_count = 4,
        logger_event_count = 6,
        sections = {
            { name = "INTRO", start = 0, ["end"] = 10 },
            { name = "VERSE_1", start = 10, ["end"] = 30 },
            { name = "CHORUS_1", start = 30, ["end"] = 50 },
            { name = "ENDING", start = 50, ["end"] = 60 }
        }
    }
end

local function build_mixer_state()
    return mixer_state.create()
end

local function run_ui_runtime_tests()
    print("Running UI runtime tests...\n")

    local session = ui_session.create()
    local mixer = build_mixer_state()
    
    local options = {
        track_scan_override = {
            ok = true,
            tracks = {
                { id = 0, name = "Click", volume = 1.0, muted = false, soloed = false },
                { id = 1, name = "Drums", volume = 0.8, muted = false, soloed = false }
            }
        }
    }

    local view_model = ui_runtime.build_view_model(build_snapshot(), session, mixer, options)

    assert(view_model.ok == true, "Test 1 failed")
    print("Test 1 passed: build_view_model ok")

    -- v0.3 Mixer tests
    assert(view_model.track_scan ~= nil, "Test 91 failed")
    assert(view_model.track_catalog ~= nil, "Test 92 failed")
    assert(view_model.mixer ~= nil, "Test 93 failed")
    assert(view_model.mixer.ok == true, "Test 93 failed")
    print("Test 91-93 passed: view_model includes mixer data")

    local mixer_lines = ui_runtime.get_mixer_lines(view_model)
    assert(mixer_lines[1] == "Mixer", "Test 94 failed")
    assert(string.find(mixer_lines[2], "CLICK"), "Test 95 failed")
    print("Test 94-95 passed: get_mixer_lines works")

    -- v0.6 Live Control tests
    assert(view_model.live_queue ~= nil, "Test 100 failed")
    assert(view_model.loop_mode ~= nil, "Test 101 failed")
    assert(view_model.ui_live_control ~= nil, "Test 102 failed")
    print("Test 100-102 passed: view_model includes live control data")

    assert(view_model.active_intent_source == "next_section", "Test 103 failed")
    
    ui_session.add_to_live_queue(session, "CHORUS_1", { target_position = 30.0 })
    local vm2 = ui_runtime.build_view_model(build_snapshot(), session, mixer, options)
    assert(vm2.active_intent_source == "live_queue", "Test 104 failed")
    
    ui_session.enable_infinite_loop(session, "VERSE_1", { target_position = 10.0 })
    local vm3 = ui_runtime.build_view_model(build_snapshot(), session, mixer, options)
    assert(vm3.active_intent_source == "infinite_loop", "Test 105 failed")
    print("Test 103-105 passed: active_intent_source follows priority")

    local live_lines = ui_runtime.get_live_control_lines(vm3)
    assert(string.find(live_lines[1], "Infinite Loop"), "Test 106 failed")
    print("Test 106 passed: get_live_control_lines works")

    print("\nUI runtime tests passed successfully!")
end

run_ui_runtime_tests()
