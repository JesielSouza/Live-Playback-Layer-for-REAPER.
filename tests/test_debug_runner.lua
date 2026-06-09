local debug_runner = require("scripts.debug_runner")
local state = require("scripts.state")

local function run_debug_runner_tests()
    print("Running debug runner tests...\n")

    -- Set mock environment
    _G.reaper = nil

    -- Run READY test
    local ready_scan = debug_runner.build_sample_project_scan("ready")
    local ready_res = debug_runner.run(ready_scan)

    -- 1. ready sample retorna validation.status = ready.
    assert(ready_res.context.validation.status == "ready", "Test 1 failed")
    print("Test 1 passed: ready sample returns validation.status = ready")

    -- 2. ready sample termina com State SONG_LOADED.
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 2 failed")
    print("Test 2 passed: ready sample finishes with State SONG_LOADED")

    -- Run WARNING test
    local warning_scan = debug_runner.build_sample_project_scan("warning")
    local warning_res = debug_runner.run(warning_scan)

    -- 3. warning sample retorna validation.status = warning.
    assert(warning_res.context.validation.status == "warning", "Test 3 failed")
    print("Test 3 passed: warning sample returns validation.status = warning")

    -- 4. warning sample termina com State SONG_LOADED.
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 4 failed")
    print("Test 4 passed: warning sample finishes with State SONG_LOADED")

    -- Run BLOCKED test
    local blocked_scan = debug_runner.build_sample_project_scan("blocked")
    local blocked_res = debug_runner.run(blocked_scan)

    -- 5. blocked sample retorna validation.status = blocked.
    assert(blocked_res.context.validation.status == "blocked", "Test 5 failed")
    print("Test 5 passed: blocked sample returns validation.status = blocked")

    -- 6. blocked sample termina com State ERROR.
    assert(state.get_current() == state.STATES.ERROR, "Test 6 failed")
    print("Test 6 passed: blocked sample finishes with State ERROR")

    -- Report contents check (using warning_res as baseline)
    local rep = warning_res.report

    -- 7. report contém validation status.
    assert(string.find(rep, "Validation Status: warning"), "Test 7 failed")
    print("Test 7 passed: report contains validation status")

    -- 8. report contém section count.
    assert(string.find(rep, "Section Count: 2"), "Test 8 failed")
    print("Test 8 passed: report contains section count")

    -- 9. report contém logger event count.
    assert(string.find(rep, "Logger Event Count:"), "Test 9 failed")
    print("Test 9 passed: report contains logger event count")

    -- 10. Logger events são gerados durante run.
    assert(#warning_res.events > 0, "Test 10 failed")
    print("Test 10 passed: logger events are generated during run")

    print("\nDebug runner tests passed successfully!")
end

run_debug_runner_tests()
