--[[
    run_tests.lua
    Test runner for the Live Playback Layer project.
--]]

print("Starting test suite...\n")

-- Helper to run a test file
local function run_test_file(path)
    print("----------------------------------------")
    print("Running: " .. path)
    local success, err = pcall(function()
        dofile(path)
    end)
    if not success then
        print("\nFAILED: " .. path)
        print(err)
        os.exit(1)
    end
end

-- List of test files to run
local test_files = {
    "tests/test_logger.lua",
    "tests/test_validation.lua",
    "tests/test_runtime.lua",
    "tests/test_ui_session.lua",
    "tests/test_transport_adapter.lua",
    "tests/test_transport_gate.lua",
    "tests/test_transport_simulator.lua",
    "tests/test_transport_preflight.lua",
    "tests/test_safety_dashboard.lua",
    "tests/test_seek_plan.lua",
    "tests/test_transport_readiness.lua",
    "tests/test_pre_execution_audit.lua",
    "tests/test_transport_control.lua",
    "tests/test_ui_runtime.lua",
    "tests/test_song_map.lua",
    "tests/test_ui_timeline.lua",
    "tests/test_track_adapter.lua",
    "tests/test_track_catalog.lua",
    "tests/test_mixer_state.lua",
    "tests/test_ui_mixer.lua",
    "tests/test_setlist_model.lua",
    "tests/test_setlist_store.lua",
    "tests/test_ui_setlist.lua",
    "tests/test_project_load_adapter.lua",
    "tests/test_live_queue.lua",
    "tests/test_loop_mode.lua",
    "tests/test_ui_live_control.lua",
    "tests/test_cue_model.lua",
    "tests/test_cue_store.lua",
    "tests/test_ui_cues.lua"
}

for _, file in ipairs(test_files) do
    run_test_file(file)
end

print("\n----------------------------------------")
print("ALL TESTS PASSED SUCCESSFULLY!")
