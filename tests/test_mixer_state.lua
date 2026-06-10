local mixer_state = require("scripts.mixer_state")

local function run_mixer_state_tests()
    print("Running mixer state tests...\n")

    local state = mixer_state.create()
    assert(state.visible == true, "Test 1 failed")
    print("Test 1 passed: create visible true")

    mixer_state.toggle_visible(state)
    assert(state.visible == false, "Test 2 failed")
    mixer_state.toggle_visible(state)
    assert(state.visible == true, "Test 2 failed")
    print("Test 2 passed: toggle_visible works")

    mixer_state.set_visible(state, false)
    assert(state.visible == false, "Test 3 failed")
    print("Test 3 passed: set_visible false works")

    mixer_state.set_selected_track(state, 42)
    assert(state.selected_track_id == 42, "Test 4 failed")
    assert(mixer_state.get_selected_track(state) == 42, "Test 4 failed")
    print("Test 4 passed: selected_track works")

    local res = { ok = true, action = "test" }
    mixer_state.set_last_mixer_result(state, res)
    assert(state.last_mixer_result == res, "Test 5 failed")
    assert(mixer_state.get_last_mixer_result(state) == res, "Test 5 failed")
    print("Test 5 passed: last_mixer_result works")

    mixer_state.set_category_collapsed(state, "drums", true)
    assert(mixer_state.is_category_collapsed(state, "drums") == true, "Test 6 failed")
    assert(mixer_state.is_category_collapsed(state, "keys") == false, "Test 6 failed")
    print("Test 6 passed: category collapse works")

    local s = mixer_state.get_state(state)
    assert(type(s) == "table", "Test 7 failed")
    assert(s.visible == false, "Test 7 failed")
    print("Test 7 passed: get_state returns state")

    print("\nMixer state tests passed successfully!")
end

run_mixer_state_tests()
