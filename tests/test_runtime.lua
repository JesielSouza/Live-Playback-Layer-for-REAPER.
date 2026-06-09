local runtime = require("scripts.runtime")
local state = require("scripts.state")

local function build_valid_scan()
    return {
        regions = {
            { name = "INTRO|loop=0|next=VERSE_1", start_pos = 0, end_pos = 10, index = 1 },
            { name = "VERSE_1|loop=0|next=CHORUS_1", start_pos = 10, end_pos = 30, index = 2 },
            { name = "CHORUS_1|loop=1|next=ENDING", start_pos = 30, end_pos = 50, index = 3 },
            { name = "ENDING|loop=0", start_pos = 50, end_pos = 60, index = 4 }
        }
    }
end

local function build_invalid_scan()
    return {
        regions = {}
    }
end

local function run_runtime_tests()
    print("Running runtime tests...\n")

    local original_reaper = _G.reaper
    _G.reaper = nil

    local snapshot = runtime.build_snapshot({
        project_scan_override = build_valid_scan(),
        position_override = 12
    })

    assert(snapshot.ok == true, "Test 1 failed")
    print("Test 1 passed: build_snapshot with valid project_scan returns ok=true")

    assert(snapshot.app_state == state.STATES.SONG_LOADED, "Test 2 failed")
    print("Test 2 passed: build_snapshot with valid project_scan returns app_state SONG_LOADED")

    assert(snapshot.read_only == true, "Test 3 failed")
    print("Test 3 passed: build_snapshot returns read_only=true")

    assert(snapshot.validation_status == "ready", "Test 4 failed")
    print("Test 4 passed: build_snapshot returns validation_status ready")

    assert(snapshot.section_count == 4, "Test 5 failed")
    print("Test 5 passed: build_snapshot returns correct section_count")

    assert(snapshot.current_section == "VERSE_1", "Test 6 failed")
    print("Test 6 passed: build_snapshot with position_override returns current_section VERSE_1")

    assert(snapshot.previous_section == "INTRO", "Test 7 failed")
    print("Test 7 passed: build_snapshot returns previous_section INTRO")

    assert(snapshot.next_section == "CHORUS_1", "Test 8 failed")
    print("Test 8 passed: build_snapshot returns next_section CHORUS_1")

    assert(snapshot.decision == "NEXT_SECTION_READY", "Test 9 failed")
    print("Test 9 passed: build_snapshot returns decision NEXT_SECTION_READY")

    local invalid_snapshot = runtime.build_snapshot({
        project_scan_override = build_invalid_scan(),
        position_override = 12
    })

    assert(invalid_snapshot.ok == false, "Test 10 failed")
    print("Test 10 passed: build_snapshot with invalid project_scan returns ok=false")

    assert(invalid_snapshot.validation_status == "blocked", "Test 11 failed")
    print("Test 11 passed: invalid build_snapshot preserves validation_status blocked")

    assert(snapshot.logger_event_count >= 1, "Test 12 failed")
    print("Test 12 passed: build_snapshot returns logger_event_count >= 1")

    local formatted = runtime.format_snapshot(snapshot)
    assert(string.find(formatted, "Runtime Snapshot"), "Test 13 failed")
    print("Test 13 passed: format_snapshot contains Runtime Snapshot")

    assert(string.find(formatted, "App State"), "Test 14 failed")
    print("Test 14 passed: format_snapshot contains App State")

    assert(string.find(formatted, "Current Section"), "Test 15 failed")
    print("Test 15 passed: format_snapshot contains Current Section")

    assert(string.find(formatted, "Read Only"), "Test 16 failed")
    print("Test 16 passed: format_snapshot contains Read Only")

    _G.reaper = original_reaper

    print("\nRuntime tests passed successfully!")
end

run_runtime_tests()
