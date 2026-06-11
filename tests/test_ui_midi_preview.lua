local ui_midi_preview = require("scripts.ui_midi_preview")
local midi_cue_model = require("scripts.midi_cue_model")

local function run_ui_midi_preview_tests()
    print("Running UI midi preview tests...\n")

    local store = {
        version = 1,
        cues = {
            { id = "c1", type = "midi_placeholder", section_id = "S1", payload = "note_on:1:60:100", enabled = true, label = "L1" },
            { id = "c2", type = "midi_placeholder", section_id = "S2", payload = "cc:1:20:127", enabled = true, label = "L2" },
            { id = "c3", type = "midi_placeholder", section_id = "S1", payload = "invalid", enabled = true, label = "L3" }
        }
    }
    
    local song_map = {
        ok = true,
        current_section = "S1",
        next_section = "S2",
        sections = { { id = "S1", label = "S1" }, { id = "S2", label = "S2" } }
    }
    
    -- 1-3. Build
    local ui = ui_midi_preview.build(store, song_map, { target_section = "S2" })
    assert(ui.ok == true, "Test 1 failed")
    assert(ui.current.valid_count == 1, "Test 2 failed")
    assert(ui.current.invalid_count == 1, "Test 2 failed")
    assert(ui.next.valid_count == 1, "Test 3 failed")
    print("Test 1-3 passed: build filters and counts events correctly")

    -- 4-6. Summary
    local lines = ui_midi_preview.get_summary_lines(ui)
    assert(lines[1] == "MIDI Cue Preview", "Test 4 failed")
    assert(string.find(lines[3], "MIDI sent: no"), "Test 5 failed")
    print("Test 4-6 passed: summary lines work")

    -- 8-10. format
    local fmt = ui_midi_preview.format_event_line(ui.current.events[1])
    assert(string.find(fmt, "note_on"), "Test 8 failed")
    
    local s_fmt = ui_midi_preview.format_section_preview(ui.current)
    assert(string.find(s_fmt, "S1"), "Test 10 failed")
    print("Test 8-10 passed: formatting works")

    print("\nUI midi preview tests passed successfully!")
end

run_ui_midi_preview_tests()
