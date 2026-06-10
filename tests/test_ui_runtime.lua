local ui_runtime = require("scripts.ui_runtime")

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
        warnings = {},
        errors = {}
    }
end

local function run_ui_runtime_tests()
    print("Running UI runtime tests...\n")

    local view_model = ui_runtime.build_view_model(build_snapshot())

    assert(view_model.ok == true, "Test 1 failed")
    print("Test 1 passed: build_view_model with valid snapshot returns ok=true")

    assert(view_model.read_only == true, "Test 2 failed")
    print("Test 2 passed: build_view_model preserves read_only=true")

    assert(view_model.app_state == "SONG_LOADED", "Test 3 failed")
    print("Test 3 passed: build_view_model preserves app_state")

    assert(view_model.current_section == "VERSE_1", "Test 4 failed")
    print("Test 4 passed: build_view_model preserves current_section")

    assert(view_model.next_section == "CHORUS_1", "Test 5 failed")
    print("Test 5 passed: build_view_model preserves next_section")

    assert(view_model.decision == "NEXT_SECTION_READY", "Test 6 failed")
    print("Test 6 passed: build_view_model preserves decision")

    assert(type(view_model.status_line) == "string" and #view_model.status_line > 0, "Test 7 failed")
    print("Test 7 passed: build_view_model generates status_line")

    local missing = ui_runtime.build_view_model(nil)
    assert(missing.ok == false, "Test 8 failed")
    assert(missing.errors[1] == "missing_snapshot", "Test 8 failed")
    print("Test 8 passed: build_view_model with nil returns ok=false")

    local cards = ui_runtime.get_section_cards(view_model)
    assert(cards[1].label == "Current Section", "Test 9 failed")
    print("Test 9 passed: get_section_cards returns Current Section")

    assert(cards[2].label == "Previous Section", "Test 10 failed")
    print("Test 10 passed: get_section_cards returns Previous Section")

    assert(cards[3].label == "Next Section", "Test 11 failed")
    print("Test 11 passed: get_section_cards returns Next Section")

    assert(cards[4].label == "Decision", "Test 12 failed")
    print("Test 12 passed: get_section_cards returns Decision")

    local status_line = ui_runtime.format_status_line(view_model)
    assert(string.find(status_line, "SONG_LOADED"), "Test 13 failed")
    print("Test 13 passed: format_status_line contains app_state")

    assert(string.find(status_line, "VERSE_1"), "Test 14 failed")
    print("Test 14 passed: format_status_line contains current_section")

    assert(string.find(status_line, "NEXT_SECTION_READY"), "Test 15 failed")
    print("Test 15 passed: format_status_line contains decision")

    assert(view_model.current_position_label == "12.00s", "Test 16 failed")
    print("Test 16 passed: current_position_label formats numbers with two decimals")

    local nil_position = build_snapshot()
    nil_position.position = nil
    local nil_position_view = ui_runtime.build_view_model(nil_position)
    assert(nil_position_view.current_position_label == "nil", "Test 17 failed")
    print("Test 17 passed: current_position_label formats nil as nil")

    assert(view_model.read_only_label == "true", "Test 18 failed")
    print("Test 18 passed: read_only_label returns true")

    assert(string.find(view_model.validation_label, "ready"), "Test 19 failed")
    print("Test 19 passed: validation_label includes status")

    assert(string.find(view_model.diagnostics_label, "events=6"), "Test 20 failed")
    print("Test 20 passed: diagnostics_label includes logger_event_count")

    local partial_view = ui_runtime.build_view_model({ ok = false })
    assert(partial_view.ok == false, "Test 21 failed")
    assert(partial_view.status_line ~= nil, "Test 21 failed")
    print("Test 21 passed: build_view_model handles partial snapshots")

    local nil_status_line = ui_runtime.format_status_line({})
    assert(type(nil_status_line) == "string", "Test 22 failed")
    assert(string.find(nil_status_line, "nil"), "Test 22 failed")
    print("Test 22 passed: status_line handles nil fields")

    assert(cards[1].emphasis == true, "Test 23 failed")
    assert(cards[3].emphasis == true, "Test 23 failed")
    assert(cards[4].emphasis == true, "Test 23 failed")
    print("Test 23 passed: key cards have emphasis=true")

    local diagnostics = ui_runtime.get_diagnostics_lines(view_model)
    assert(diagnostics[1] == "Section Count: 4", "Test 24 failed")
    print("Test 24 passed: get_diagnostics_lines returns Section Count")

    assert(diagnostics[2] == "Logger Event Count: 6", "Test 25 failed")
    print("Test 25 passed: get_diagnostics_lines returns Logger Event Count")

    assert(ui_runtime.get_read_only_warning() == "No transport actions are triggered.", "Test 26 failed")
    print("Test 26 passed: get_read_only_warning returns read-only warning")

    print("\nUI runtime tests passed successfully!")
end

run_ui_runtime_tests()
