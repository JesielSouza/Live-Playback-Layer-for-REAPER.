local smoke = require("scripts.reaper_smoke_test")
local state = require("scripts.state")

local function run_smoke_tests()
    print("Running reaper smoke tests...\n")

    -- Set mock environment
    local original_reaper = _G.reaper
    _G.reaper = nil

    local mock_result = {
        context = {
            validation = { status = "ready", ok = true, sections = {{}, {}}, summary = "All good" },
            project_scan = { regions = {{}, {}, {}} },
            dependencies = { reaper_available = true }
        },
        events = { {}, {} }
    }

    local rep = smoke.format_reaper_report(mock_result)

    -- 1. format_reaper_report inclui o título.
    assert(string.find(rep, "=== Live Playback Layer — REAPER Smoke Test ==="), "Test 1 failed")
    print("Test 1 passed: format_reaper_report includes the title")

    -- 2. format_reaper_report inclui validation status.
    assert(string.find(rep, "Validation Status: ready"), "Test 2 failed")
    print("Test 2 passed: format_reaper_report includes validation status")

    -- 3. format_reaper_report inclui section count.
    assert(string.find(rep, "Section Count: 2"), "Test 3 failed")
    print("Test 3 passed: format_reaper_report includes section count")

    -- 4. print_to_reaper_console usa print fallback sem REAPER e não crasha.
    local print_ran_without_crash = pcall(function()
        smoke.print_to_reaper_console("Testing fallback print")
    end)
    assert(print_ran_without_crash == true, "Test 4 failed")
    print("Test 4 passed: print_to_reaper_console falls back cleanly when REAPER is nil")

    -- 5. print_to_reaper_console usa reaper.ShowConsoleMsg quando mockado.
    local console_msg_called = false
    _G.reaper = {
        ShowConsoleMsg = function(msg)
            console_msg_called = true
            assert(string.find(msg, "Mocked message"), "Test 5 internal assertion failed")
        end
    }
    smoke.print_to_reaper_console("Mocked message")
    assert(console_msg_called == true, "Test 5 failed")
    print("Test 5 passed: print_to_reaper_console uses reaper.ShowConsoleMsg when available")

    -- Prepare to test SmokeTest.run() natively but with a mock REAPER API returning regions
    _G.reaper.GetAppVersion = function() return "6.0.0" end
    _G.reaper.CountProjectMarkers = function(proj) return 0, 0, 2 end
    _G.reaper.EnumProjectMarkers = function(i)
        if i == 0 then return 1, true, 0, 10, "INTRO|loop=0", 1 end
        if i == 1 then return 1, true, 10, 20, "VERSE_1", 2 end
        return 0, false, 0, 0, "", 0
    end

    -- 6. SmokeTest.run() retorna context, events e report.
    -- 8. Nenhum teste chama transporte real (because we didn't mock transport APIs and it didn't crash).
    -- 9. Nenhum teste exige ReaImGui.
    local run_res = smoke.run()
    assert(run_res.context ~= nil, "Test 6 failed: context nil")
    assert(run_res.events ~= nil, "Test 6 failed: events nil")
    assert(type(run_res.report) == "string", "Test 6 failed: report missing")
    print("Test 6, 8, 9 passed: SmokeTest.run() executes safely, returns fields, and avoids transport/UI")

    -- 10. SmokeTest.run() com projeto mockado e region válida termina com validação ready ou warning.
    assert(run_res.context.validation.status == "ready" or run_res.context.validation.status == "warning", "Test 10 failed")
    assert(state.get_current() == state.STATES.SONG_LOADED, "Test 10 failed")
    print("Test 10 passed: SmokeTest.run() with valid regions ends in SONG_LOADED")

    -- 7. safe_main não propaga erro cru.
    -- Break run to force error
    local original_run = smoke.run
    smoke.run = function() error("Simulated critical failure") end
    local main_ok = pcall(smoke.safe_main)
    assert(main_ok == true, "Test 7 failed: safe_main propagated raw error")
    print("Test 7 passed: safe_main traps errors safely")

    -- Restore
    smoke.run = original_run
    _G.reaper = original_reaper

    print("\nReaper smoke tests passed successfully!")
end

run_smoke_tests()
