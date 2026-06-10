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

    local confirmation = ui_runtime.get_transport_confirmation_lines(view_model)
    assert(confirmation[1] == "Status: NOT CONFIRMED", "Test 27 failed")
    print("Test 27 passed: get_transport_confirmation_lines returns Status")

    assert(confirmation[5] == "Action: go_next", "Test 28 failed")
    print("Test 28 passed: get_transport_confirmation_lines returns Action")

    assert(confirmation[6] == "Target: CHORUS_1", "Test 29 failed")
    print("Test 29 passed: get_transport_confirmation_lines returns Target")

    assert(confirmation[7] == "Mode: DRY RUN", "Test 30 failed")
    print("Test 29 passed: get_transport_confirmation_lines returns dry-run mode")

    assert(confirmation[8] == "Execution: DISABLED", "Test 31 failed")
    print("Test 30 passed: get_transport_confirmation_lines returns disabled execution")

    assert(confirmation[9] == "Confirmation: visual only", "Test 32 failed")
    print("Test 31 passed: get_transport_confirmation_lines returns visual-only confirmation")

    assert(view_model.transport_execution_enabled == false, "Test 33 failed")
    print("Test 32 passed: build_view_model sets transport_execution_enabled=false")

    assert(view_model.transport_confirmation_required == true, "Test 34 failed")
    print("Test 33 passed: build_view_model sets transport_confirmation_required=true")

    assert(view_model.simulation_result.message == "simulation_disabled", "Test 35 failed")
    print("Test 34 passed: build_view_model sets simulation_disabled by default")

    local simulation = ui_runtime.get_transport_simulation_lines(view_model)
    assert(simulation[1] == "Simulated: true", "Test 36 failed")
    print("Test 35 passed: get_transport_simulation_lines returns Simulated")

    assert(simulation[2] == "Executed: false", "Test 37 failed")
    print("Test 36 passed: get_transport_simulation_lines returns Executed")

    assert(simulation[3] == "Message: simulation_disabled", "Test 38 failed")
    print("Test 37 passed: get_transport_simulation_lines returns Message")

    assert(view_model.manual_confirmation_active == false, "Test 39 failed")
    print("Test 39 passed: build_view_model without confirmation sets manual_confirmation_active=false")

    local session = ui_session.create()
    ui_session.confirm_transport(session, view_model.transport_intent_preview)
    local confirmed_view = ui_runtime.build_view_model(build_snapshot(), session)
    assert(confirmed_view.manual_confirmation_active == true, "Test 40 failed")
    print("Test 40 passed: build_view_model with matching confirmation sets manual_confirmation_active=true")

    assert(type(view_model.preflight_report) == "table", "Test 41 failed")
    print("Test 41 passed: build_view_model exposes preflight_report")

    local preflight = ui_runtime.get_transport_preflight_lines(view_model)
    assert(preflight[1] == "Status: blocked", "Test 42 failed")
    print("Test 42 passed: get_transport_preflight_lines returns Status")

    assert(preflight[9] == "Summary: preflight_blocked", "Test 43 failed")
    print("Test 43 passed: get_transport_preflight_lines returns Summary")

    assert(type(view_model.safety_dashboard) == "table", "Test 44 failed")
    print("Test 44 passed: build_view_model exposes safety_dashboard")

    local safety = ui_runtime.get_safety_dashboard_lines(view_model)
    assert(safety[1] == "Safety Level: locked", "Test 45 failed")
    print("Test 45 passed: get_safety_dashboard_lines returns Safety Level")

    assert(safety[2] == "Transport Real Enabled: false", "Test 46 failed")
    print("Test 46 passed: get_safety_dashboard_lines returns Transport Real Enabled")

    assert(safety[8] == "Guarantees:", "Test 47 failed")
    print("Test 47 passed: get_safety_dashboard_lines returns Guarantees")

    print("\nUI runtime tests passed successfully!")
end

run_ui_runtime_tests()
