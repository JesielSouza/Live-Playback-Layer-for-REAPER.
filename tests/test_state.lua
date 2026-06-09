local state = require("scripts.state")
local logger = require("scripts.logger")

local function run_state_tests()
    print("Running state machine tests...\n")
    logger.clear()

    -- Ensure a clean start
    state.reset()

    -- 1. Estado inicial padrão é IDLE.
    assert(state.get_current() == state.STATES.IDLE, "Test 1 failed")
    print("Test 1 passed: Initial state is IDLE")

    -- 2. LOAD_SONG_SUCCESS leva para SONG_LOADED.
    local ok2 = state.dispatch(state.EVENTS.LOAD_SONG_SUCCESS)
    assert(ok2 == true, "Test 2 failed")
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 2 failed")
    print("Test 2 passed: LOAD_SONG_SUCCESS goes to SONG_LOADED")

    -- Reset for test 3
    state.reset()

    -- 3. PLAY_REQUESTED em IDLE é rejeitado.
    local ok3 = state.dispatch(state.EVENTS.PLAY_REQUESTED)
    assert(ok3 == false, "Test 3 failed")
    assert(state.get_current() == state.STATES.IDLE, "Test 3 failed")
    print("Test 3 passed: PLAY_REQUESTED in IDLE is rejected")

    -- 4. PLAY_REQUESTED após LOAD_SONG_SUCCESS leva para PLAYING.
    state.dispatch(state.EVENTS.LOAD_SONG_SUCCESS)
    local ok4 = state.dispatch(state.EVENTS.PLAY_REQUESTED)
    assert(ok4 == true, "Test 4 failed")
    assert(state.get_current() == state.STATES.PLAYING, "Test 4 failed")
    print("Test 4 passed: PLAY_REQUESTED from SONG_LOADED goes to PLAYING")

    -- 5. JUMP_REQUESTED em PLAYING leva para JUMP_PENDING.
    local ok5 = state.dispatch(state.EVENTS.JUMP_REQUESTED)
    assert(ok5 == true, "Test 5 failed")
    assert(state.get_current() == state.STATES.JUMP_PENDING, "Test 5 failed")
    print("Test 5 passed: JUMP_REQUESTED from PLAYING goes to JUMP_PENDING")

    -- 6. JUMP_COMPLETED leva de JUMP_PENDING para PLAYING.
    local ok6 = state.dispatch(state.EVENTS.JUMP_COMPLETED)
    assert(ok6 == true, "Test 6 failed")
    assert(state.get_current() == state.STATES.PLAYING, "Test 6 failed")
    print("Test 6 passed: JUMP_COMPLETED returns to PLAYING")

    -- 7. LOOP_ENABLED leva de PLAYING para SECTION_LOOPING.
    local ok7 = state.dispatch(state.EVENTS.LOOP_ENABLED)
    assert(ok7 == true, "Test 7 failed")
    assert(state.get_current() == state.STATES.SECTION_LOOPING, "Test 7 failed")
    print("Test 7 passed: LOOP_ENABLED goes to SECTION_LOOPING")

    -- 8. LOOP_DISABLED leva para PLAYING.
    local ok8 = state.dispatch(state.EVENTS.LOOP_DISABLED)
    assert(ok8 == true, "Test 8 failed")
    assert(state.get_current() == state.STATES.PLAYING, "Test 8 failed")
    print("Test 8 passed: LOOP_DISABLED returns to PLAYING")

    -- 9. FADE_REQUESTED leva para FADING_OUT.
    local ok9 = state.dispatch(state.EVENTS.FADE_REQUESTED)
    assert(ok9 == true, "Test 9 failed")
    assert(state.get_current() == state.STATES.FADING_OUT, "Test 9 failed")
    print("Test 9 passed: FADE_REQUESTED goes to FADING_OUT")

    -- 10. FADE_COMPLETED leva para STOPPED.
    local ok10 = state.dispatch(state.EVENTS.FADE_COMPLETED)
    assert(ok10 == true, "Test 10 failed")
    assert(state.get_current() == state.STATES.STOPPED, "Test 10 failed")
    print("Test 10 passed: FADE_COMPLETED goes to STOPPED")

    -- 11. PANIC_REQUESTED funciona a partir de qualquer estado testado (using STOPPED currently).
    local ok11 = state.dispatch(state.EVENTS.PANIC_REQUESTED)
    assert(ok11 == true, "Test 11 failed")
    assert(state.get_current() == state.STATES.PANIC, "Test 11 failed")
    print("Test 11 passed: PANIC_REQUESTED goes to PANIC")

    -- 12. PANIC_CLEARED leva para STOPPED.
    local ok12 = state.dispatch(state.EVENTS.PANIC_CLEARED)
    assert(ok12 == true, "Test 12 failed")
    assert(state.get_current() == state.STATES.STOPPED, "Test 12 failed")
    print("Test 12 passed: PANIC_CLEARED goes to STOPPED")

    -- 13. ERROR_RAISED leva para ERROR.
    local ok13 = state.set_error("Something broke")
    assert(state.get_current() == state.STATES.ERROR, "Test 13 failed")
    assert(state.get_context().error == "Something broke", "Test 13 failed")
    print("Test 13 passed: ERROR_RAISED goes to ERROR and sets error message")

    -- 14. ERROR_CLEARED volta para SONG_LOADED quando há música.
    state.set_song("Song 1")
    state.clear_error()
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 14 failed")
    assert(state.get_context().error == nil, "Test 14 failed")
    print("Test 14 passed: ERROR_CLEARED returns to SONG_LOADED if song exists")

    -- Test 14b: ERROR_CLEARED returns to IDLE if no song exists
    state.set_error("Broke again")
    state.set_song(nil)
    state.clear_error()
    assert(state.get_current() == state.STATES.IDLE, "Test 14b failed")
    print("Test 14b passed: ERROR_CLEARED returns to IDLE if no song")

    -- 15. RESET_REQUESTED volta para IDLE.
    state.dispatch(state.EVENTS.LOAD_SONG_SUCCESS)
    state.dispatch(state.EVENTS.RESET_REQUESTED)
    assert(state.get_current() == state.STATES.IDLE, "Test 15 failed")
    print("Test 15 passed: RESET_REQUESTED goes to IDLE and clears state")

    -- 16. Transição proibida registra item no history com ok=false.
    state.reset()
    state.dispatch(state.EVENTS.JUMP_REQUESTED) -- JUMP from IDLE is forbidden
    local history = state.get_history()
    local last_item = history[#history]
    assert(last_item.ok == false, "Test 16 failed")
    assert(last_item.reason == "transition_not_allowed", "Test 16 failed")
    print("Test 16 passed: Forbidden transition records ok=false in history")

    -- 17. Transição aceita registra item no history com ok=true.
    state.dispatch(state.EVENTS.LOAD_SONG_SUCCESS)
    local history_after = state.get_history()
    local item = history_after[#history_after]
    assert(item.ok == true, "Test 17 failed")
    assert(item.to == state.STATES.SONG_LOADED, "Test 17 failed")
    print("Test 17 passed: Allowed transition records ok=true in history")

    -- 18. set_sections e set_current_section preservam contexto.
    local mock_sections = {{name="Intro"}, {name="Verse"}}
    state.set_sections(mock_sections)
    state.set_current_section(mock_sections[1])
    local ctx = state.get_context()
    assert(#ctx.sections == 2, "Test 18 failed")
    assert(ctx.current_section.name == "Intro", "Test 18 failed")
    print("Test 18 passed: Context sets and preserves sections properly")

    -- 19. Check if successful transition generates a STATE_TRANSITION log event
    logger.clear()
    state.reset()
    state.dispatch(state.EVENTS.LOAD_SONG_SUCCESS)
    local events = logger.get_events()
    local found_transition = false
    for _, ev in ipairs(events) do
        if ev.event == "STATE_TRANSITION" and ev.payload.ok == true then
            found_transition = true
            break
        end
    end
    assert(found_transition == true, "Test 19 failed")
    print("Test 19 passed: Successful transition generates STATE_TRANSITION event")

    -- 20. Check if rejected transition generates a STATE_TRANSITION_REJECTED log event
    logger.clear()
    state.reset()
    state.dispatch(state.EVENTS.JUMP_REQUESTED) -- Invalid from IDLE
    local events2 = logger.get_events()
    local found_rejection = false
    for _, ev in ipairs(events2) do
        if ev.event == "STATE_TRANSITION_REJECTED" and ev.payload.ok == false then
            found_rejection = true
            break
        end
    end
    assert(found_rejection == true, "Test 20 failed")
    print("Test 20 passed: Rejected transition generates STATE_TRANSITION_REJECTED event")

    -- 21. History in memory still works correctly and independently of logger file_path
    logger.configure({file_path = nil})
    local hist = state.get_history()
    assert(#hist > 0, "Test 21 failed")
    print("Test 21 passed: History in memory continues to function independently of file_path")

    print("\nState machine tests passed successfully!")
end

run_state_tests()
