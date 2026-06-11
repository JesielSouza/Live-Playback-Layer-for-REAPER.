local midi_dry_run = require("scripts.midi_dry_run")

local function run_midi_dry_run_tests()
    print("Running midi dry run tests...\n")

    -- 1-2. run sem eventos
    local res1 = midi_dry_run.run({}, { source = "manual" })
    assert(res1.ok == true, "Test 1 failed")
    assert(res1.reason == "no_midi_events", "Test 2 failed")
    print("Test 1-2 passed: Empty events handling works")

    -- 3-10. run com evento
    local events = {
        { ok = true, command = "note_on", channel = 1, data1 = 60, data2 = 100 },
        { ok = false, reason = "invalid_midi_payload", label = "Bad" }
    }
    local res2 = midi_dry_run.run(events, { source = "current", section_id = "INTRO" })
    assert(res2.ok == true, "Test 3 failed")
    assert(res2.dry_run == true, "Test 4 failed")
    assert(res2.sent == false, "Test 3 failed: sent must be false")
    assert(res2.valid_count == 1, "Test 6 failed")
    assert(res2.invalid_count == 1, "Test 7 failed")
    assert(res2.source == "current", "Test 8 failed")
    assert(res2.section_id == "INTRO", "Test 9 failed")
    print("Test 3-10 passed: run with events works")

    -- format
    local fmt = midi_dry_run.format_result(res2)
    assert(string.find(fmt, "Dry Run: true"), "Test 10 failed")
    print("Test 10 passed: format_result works")

    print("\nMIDI dry run tests passed successfully!")
end

run_midi_dry_run_tests()
