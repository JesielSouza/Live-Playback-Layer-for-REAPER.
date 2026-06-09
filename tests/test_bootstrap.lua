local bootstrap = require("scripts.bootstrap")
local state = require("scripts.state")
local main = require("scripts.main")
local logger = require("scripts.logger")

local function run_bootstrap_tests()
    print("Running bootstrap pipeline tests...\n")
    logger.clear()

    -- Setup for offline/mock test
    _G.reaper = nil

    -- 1. check_dependencies returns lua_ok = true
    local deps1 = bootstrap.check_dependencies()
    assert(deps1.lua_ok == true, "Test 1 failed")
    print("Test 1 passed: check_dependencies returns lua_ok = true")

    -- 2. Outside REAPER, check_dependencies returns warning reaper_not_available
    local deps2 = bootstrap.check_dependencies()
    local has_warning = false
    for _, warn in ipairs(deps2.warnings) do
        if warn == "reaper_not_available" then
            has_warning = true
        end
    end
    assert(deps2.reaper_available == false, "Test 2 failed")
    assert(has_warning == true, "Test 2 failed")
    print("Test 2 passed: Outside REAPER, check_dependencies warns reaper_not_available")

    -- Prepare a mock valid scan
    local valid_scan = {
        regions = {
            { name = "VERSE|loop=0", start_pos = 0, end_pos = 10, index = 1 },
            { name = "CHORUS|loop=1", start_pos = 10, end_pos = 20, index = 2 }
        }
    }

    -- 3. build_startup_context with valid project_scan returns validation ready
    local ctx3 = bootstrap.build_startup_context(valid_scan)
    assert(ctx3.validation.status == "ready", "Test 3 failed")
    assert(#ctx3.validation.sections == 2, "Test 3 failed")
    print("Test 3 passed: build_startup_context with valid scan returns ready")

    -- 4. initialize_app with valid project_scan sets State to SONG_LOADED
    local ctx4 = bootstrap.initialize_app(valid_scan)
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 4 failed")
    assert(ctx4.state == state.STATES.SONG_LOADED, "Test 4 failed")
    local state_ctx = state.get_context()
    assert(#state_ctx.sections == 2, "Test 4 failed")
    print("Test 4 passed: initialize_app with valid scan puts state in SONG_LOADED")

    -- Prepare a mock warning scan
    local warning_scan = {
        regions = {
            { name = "VERSE|loop=abc", start_pos = 0, end_pos = 10, index = 1 },
            { name = "CHORUS", start_pos = 10, end_pos = 20, index = 2 }
        }
    }

    -- 5. initialize_app with warning project_scan sets State to SONG_LOADED preserving warning
    local ctx5 = bootstrap.initialize_app(warning_scan)
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 5 failed")
    assert(ctx5.state == state.STATES.SONG_LOADED, "Test 5 failed")
    assert(ctx5.validation.status == "warning", "Test 5 failed")
    print("Test 5 passed: initialize_app with warning scan puts state in SONG_LOADED")

    -- Prepare an invalid scan
    local invalid_scan = {
        regions = {}
    }

    -- 6. initialize_app with invalid scan sets State to ERROR
    local ctx6 = bootstrap.initialize_app(invalid_scan)
    assert(state.get_current() == state.STATES.ERROR, "Test 6 failed")
    assert(ctx6.state == state.STATES.ERROR, "Test 6 failed")
    assert(ctx6.validation.status == "blocked", "Test 6 failed")
    print("Test 6 passed: initialize_app with invalid scan puts state in ERROR")

    -- 7. apply_validation_to_state with blocked registers error in State
    state.reset()
    local mock_blocked = {
        status = "blocked",
        summary = "Fatal validation error",
        errors = {"missing_regions"}
    }
    bootstrap.apply_validation_to_state(mock_blocked)
    assert(state.get_current() == state.STATES.ERROR, "Test 7 failed")
    assert(state.get_context().error == "Fatal validation error", "Test 7 failed")
    print("Test 7 passed: apply_validation_to_state with blocked sets State ERROR")

    -- 8. get_last_startup_context returns the last context
    bootstrap.initialize_app(valid_scan)
    local last_ctx = bootstrap.get_last_startup_context()
    assert(last_ctx ~= nil, "Test 8 failed")
    assert(last_ctx.validation.status == "ready", "Test 8 failed")
    print("Test 8 passed: get_last_startup_context returns the correct context")

    -- 9. main.start(project_scan_override) returns initialized context
    local main_ctx = main.start(valid_scan)
    assert(main_ctx ~= nil, "Test 9 failed")
    assert(main_ctx.validation.status == "ready", "Test 9 failed")
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 9 failed")
    print("Test 9 passed: main.start correctly routes to Bootstrap.initialize_app")

    -- Check Logger integration hooks for valid scan
    logger.clear()
    bootstrap.initialize_app(valid_scan)
    local events = logger.get_events()

    local function has_event(name)
        for _, ev in ipairs(events) do
            if ev.event == name then return true end
        end
        return false
    end

    assert(has_event("APP_START"), "Missing APP_START")
    assert(has_event("DEPENDENCIES_CHECKED"), "Missing DEPENDENCIES_CHECKED")
    assert(has_event("PROJECT_SCANNED"), "Missing PROJECT_SCANNED")
    assert(has_event("VALIDATION_READY"), "Missing VALIDATION_READY")
    assert(has_event("STATE_LOADED"), "Missing STATE_LOADED")
    print("Test 10 passed: Valid initialization generates expected sequence of log events")

    -- Check Logger integration hooks for warning scan
    logger.clear()
    bootstrap.initialize_app(warning_scan)
    local events_warn = logger.get_events()
    local has_warn_event = false
    for _, ev in ipairs(events_warn) do
        if ev.event == "VALIDATION_WARNING" then has_warn_event = true break end
    end
    assert(has_warn_event == true, "Missing VALIDATION_WARNING")
    print("Test 11 passed: Warning initialization generates VALIDATION_WARNING event")

    -- Check Logger integration hooks for invalid scan
    logger.clear()
    bootstrap.initialize_app(invalid_scan)
    local events_err = logger.get_events()
    local has_blocked = false
    local has_state_error = false
    for _, ev in ipairs(events_err) do
        if ev.event == "VALIDATION_BLOCKED" then has_blocked = true end
        if ev.event == "STATE_ERROR" then has_state_error = true end
    end
    assert(has_blocked == true, "Missing VALIDATION_BLOCKED")
    assert(has_state_error == true, "Missing STATE_ERROR")
    print("Test 12 passed: Invalid initialization generates VALIDATION_BLOCKED and STATE_ERROR events")

    print("\nBootstrap pipeline tests passed successfully!")
end

run_bootstrap_tests()
