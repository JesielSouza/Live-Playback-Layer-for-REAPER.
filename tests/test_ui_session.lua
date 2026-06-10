local ui_session = require("scripts.ui_session")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        target_section = "CHORUS_1"
    }
end

local function run_ui_session_tests()
    print("Running UI session tests...\n")

    local session = ui_session.create()
    assert(session.transport_confirmed == false, "Test 1 failed")
    print("Test 1 passed: create returns transport_confirmed=false")

    ui_session.confirm_transport(session, build_intent())
    assert(session.transport_confirmed == true, "Test 2 failed")
    print("Test 2 passed: confirm_transport with ok intent confirms")

    assert(session.confirmation_count == 1, "Test 3 failed")
    print("Test 3 passed: confirm_transport increments confirmation_count")

    assert(session.confirmed_action == "go_next", "Test 4 failed")
    print("Test 4 passed: confirm_transport saves action")

    assert(session.confirmed_target_section == "CHORUS_1", "Test 5 failed")
    print("Test 5 passed: confirm_transport saves target_section")

    local nil_intent_session = ui_session.create()
    ui_session.confirm_transport(nil_intent_session, nil)
    assert(nil_intent_session.transport_confirmed == false, "Test 6 failed")
    print("Test 6 passed: nil intent does not confirm")

    local bad_intent_session = ui_session.create()
    local bad_intent = build_intent()
    bad_intent.ok = false
    ui_session.confirm_transport(bad_intent_session, bad_intent)
    assert(bad_intent_session.transport_confirmed == false, "Test 7 failed")
    print("Test 7 passed: ok=false intent does not confirm")

    ui_session.clear_transport_confirmation(session)
    assert(session.transport_confirmed == false, "Test 8 failed")
    assert(session.confirmed_action == nil, "Test 8 failed")
    assert(session.confirmed_target_section == nil, "Test 8 failed")
    print("Test 8 passed: clear_transport_confirmation removes confirmation")

    assert(session.confirmation_count == 1, "Test 9 failed")
    print("Test 9 passed: clear preserves confirmation_count")

    ui_session.confirm_transport(session, build_intent())
    assert(ui_session.is_transport_confirmed(session, build_intent()) == true, "Test 10 failed")
    print("Test 10 passed: is_transport_confirmed returns true for same action/target")

    local different_action = build_intent()
    different_action.action = "go_previous"
    assert(ui_session.is_transport_confirmed(session, different_action) == false, "Test 11 failed")
    print("Test 11 passed: is_transport_confirmed returns false for different action")

    local different_target = build_intent()
    different_target.target_section = "ENDING"
    assert(ui_session.is_transport_confirmed(session, different_target) == false, "Test 12 failed")
    print("Test 12 passed: is_transport_confirmed returns false for different target")

    ui_session.reset(session)
    assert(session.transport_confirmed == false, "Test 13 failed")
    assert(session.confirmation_count == 0, "Test 13 failed")
    assert(session.execution_armed == false, "Test 13 failed: reset must disarm")
    print("Test 13 passed: reset clears state, zeroes confirmation_count and disarms")

    ui_session.confirm_transport(session, build_intent())
    local state = ui_session.get_state(session)
    state.transport_confirmed = false
    state.confirmation_count = 99
    assert(session.transport_confirmed == true, "Test 14 failed")
    assert(session.confirmation_count == 1, "Test 14 failed")
    print("Test 14 passed: get_state returns safe copy")

    ui_session.arm_execution(session)
    assert(session.execution_armed == true, "Test 15 failed")
    assert(ui_session.is_execution_armed(session) == true, "Test 15 failed")
    print("Test 15 passed: arm_execution arms session")

    ui_session.disarm_execution(session)
    assert(session.execution_armed == false, "Test 16 failed")
    assert(ui_session.is_execution_armed(session) == false, "Test 16 failed")
    print("Test 16 passed: disarm_execution disarms session")

    ui_session.arm_execution(session)
    ui_session.clear_transport_confirmation(session)
    assert(session.execution_armed == false, "Test 17 failed")
    print("Test 17 passed: clear_transport_confirmation also disarms")

    local result = { ok = true, executed = true, reason = "test" }
    ui_session.set_last_execution_result(session, result)
    assert(ui_session.get_last_execution_result(session) == result, "Test 18 failed")
    local state2 = ui_session.get_state(session)
    assert(state2.last_execution_result == result, "Test 18 failed: get_state includes result")
    print("Test 18 passed: set/get last_execution_result works")

    ui_session.reset(session)
    assert(ui_session.is_debug_visible(session) == false, "Test 19 failed: reset must hide debug")
    ui_session.toggle_debug(session)
    assert(ui_session.is_debug_visible(session) == true, "Test 20 failed: toggle_debug fails")
    ui_session.toggle_debug(session)
    assert(ui_session.is_debug_visible(session) == false, "Test 21 failed: toggle_debug back fails")
    ui_session.set_debug_visible(session, true)
    assert(ui_session.is_debug_visible(session) == true, "Test 22 failed: set_debug_visible true fails")
    ui_session.set_debug_visible(session, false)
    assert(ui_session.is_debug_visible(session) == false, "Test 23 failed: set_debug_visible false fails")
    local state3 = ui_session.get_state(session)
    assert(state3.debug_visible == false, "Test 24 failed: get_state includes debug_visible")
    print("Test 19-24 passed: debug visibility state management works")

    ui_session.set_last_operator_action(session, "test_action")
    local state4 = ui_session.get_state(session)
    assert(state4.last_operator_action == "test_action", "Test 25 failed")
    print("Test 25 passed: last_operator_action saved")

    -- v0.2 Selection tests
    ui_session.select_section(session, "CHORUS_1", 30.0)
    assert(ui_session.get_selected_section(session) == "CHORUS_1", "Test 26 failed")
    assert(ui_session.is_section_selected(session, "CHORUS_1") == true, "Test 26 failed")
    print("Test 26 passed: select_section works")

    ui_session.confirm_selected_section(session, { ok = true, action = "jump_to_section", target_section = "CHORUS_1" })
    assert(session.transport_confirmed == true, "Test 27 failed")
    print("Test 27 passed: confirm_selected_section works")

    ui_session.select_section(session, "ENDING", 50.0)
    assert(session.transport_confirmed == false, "Test 28 failed")
    print("Test 28 passed: changing selection invalidates confirmation")

    ui_session.clear_selected_section(session)
    assert(ui_session.get_selected_section(session) == nil, "Test 29 failed")
    print("Test 29 passed: clear_selected_section works")

    print("\nUI session tests passed successfully!")
end

run_ui_session_tests()
