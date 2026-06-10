local ui_runtime = require("scripts.ui_runtime")
local ui_session = require("scripts.ui_session")

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
        },
        context = {
            validation = {
                sections = {
                    { name = "INTRO", start = 0, ["end"] = 10 },
                    { name = "VERSE_1", start = 10, ["end"] = 30 },
                    { name = "CHORUS_1", start = 30, ["end"] = 50 },
                    { name = "ENDING", start = 50, ["end"] = 60 }
                }
            }
        },
        warnings = {},
        errors = {}
    }
end

local function run_ui_runtime_tests()
    print("Running UI runtime tests...\n")

    local view_model = ui_runtime.build_view_model(build_snapshot())

    assert(view_model.ok == true, "Test 1 failed")
    print("Test 1 passed: build_view_model with valid snapshot returns ok=true")

    assert(view_model.app_state == "SONG_LOADED", "Test 3 failed")
    assert(view_model.current_section == "VERSE_1", "Test 4 failed")
    assert(view_model.next_section == "CHORUS_1", "Test 5 failed")
    assert(view_model.decision == "NEXT_SECTION_READY", "Test 6 failed")
    print("Test 3-6 passed: build_view_model preserves key snapshot fields")

    -- v0.2 ViewModel enrichment tests
    assert(view_model.song_map.ok == true, "Test 81 failed")
    assert(#view_model.song_map.sections == 4, "Test 81 failed")
    print("Test 81 passed: view_model includes song_map")

    assert(view_model.timeline.ok == true, "Test 82 failed")
    assert(#view_model.timeline.blocks == 4, "Test 82 failed")
    print("Test 82 passed: view_model includes timeline")

    assert(view_model.active_intent.action == "go_next", "Test 83 failed")
    print("Test 83 passed: default active_intent is go_next")

    local session = ui_session.create()
    ui_session.select_section(session, "ENDING", 50.0)
    local selected_view = ui_runtime.build_view_model(build_snapshot(), session)
    assert(selected_view.selected_section == "ENDING", "Test 84 failed")
    assert(selected_view.active_intent.action == "jump_to_section", "Test 85 failed")
    assert(selected_view.active_intent.target_section == "ENDING", "Test 85 failed")
    print("Test 84-85 passed: active_intent follows selection")

    local operator_lines = ui_runtime.get_operator_lines(selected_view)
    local has_selected = false
    local has_active = false
    for _, line in ipairs(operator_lines) do
        if string.find(line, "Selected Target: ENDING") then has_selected = true end
        if string.find(line, "Active Target: ENDING") then has_active = true end
    end
    assert(has_selected == true, "Test 86 failed")
    assert(has_active == true, "Test 87 failed")
    print("Test 86-87 passed: get_operator_lines includes selection info")

    local timeline_lines = ui_runtime.get_timeline_lines(view_model)
    assert(timeline_lines[1] == "Song Map", "Test 88 failed")
    assert(string.find(timeline_lines[2], "INTRO"), "Test 88 failed")
    print("Test 88 passed: get_timeline_lines works")

    print("\nUI runtime tests passed successfully!")
end

run_ui_runtime_tests()
