local ui_cues = require("scripts.ui_cues")
local cue_model = require("scripts.cue_model")

local function run_ui_cues_tests()
    print("Running UI cues tests...\n")

    local store = cue_model.create_empty()
    cue_model.add_cue(store, { section_id = "S1", label = "Current Cue" })
    cue_model.add_cue(store, { section_id = "S2", label = "Next Cue" })
    
    local song_map = { 
        ok = true, 
        current_section = "S1", 
        next_section = "S2",
        sections = { { id = "S1", label = "S1" }, { id = "S2", label = "S2" } }
    }
    
    -- 1-2 Build
    local ui = ui_cues.build(store, song_map, { target_section = "S2" })
    assert(ui.ok == true, "Test 1 failed")
    assert(#ui.current_cues == 1, "Test 2 failed")
    assert(#ui.next_cues == 1, "Test 3 failed")
    print("Test 1-3 passed: build filters cues correctly")

    -- 4-6 Summary
    local lines = ui_cues.get_summary_lines(ui)
    assert(lines[1] == "Section Cues", "Test 4 failed")
    assert(string.find(lines[6], "planned only"), "Test 5 failed")
    print("Test 4-6 passed: summary lines work")

    -- 7-8 Format
    local formatted = ui_cues.format_cue(ui.current_cues[1])
    assert(string.find(formatted, "[ON]"), "Test 7 failed")
    assert(string.find(formatted, "Current Cue"), "Test 7 failed")
    print("Test 7-8 passed: format_cue works")

    print("\nUI cues tests passed successfully!")
end

run_ui_cues_tests()
