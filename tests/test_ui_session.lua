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
    print("Test 13 passed: reset clears state and zeroes confirmation_count")

    ui_session.confirm_transport(session, build_intent())
    local state = ui_session.get_state(session)
    state.transport_confirmed = false
    state.confirmation_count = 99
    assert(session.transport_confirmed == true, "Test 14 failed")
    assert(session.confirmation_count == 1, "Test 14 failed")
    print("Test 14 passed: get_state returns safe copy")

    print("\nUI session tests passed successfully!")
end

run_ui_session_tests()
