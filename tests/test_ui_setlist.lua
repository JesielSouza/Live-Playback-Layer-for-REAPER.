local ui_setlist = require("scripts.ui_setlist")
local setlist_model = require("scripts.setlist_model")

local function run_ui_setlist_tests()
    print("Running UI setlist tests...\n")

    local sl = setlist_model.create_empty()
    setlist_model.add_song(sl, { id = "s1", title = "Song 1", bpm = 120 })
    setlist_model.add_song(sl, { id = "s2", title = "Song 2", project_path = "/path/to/reaper" })
    
    -- 1-3 Build
    local ui = ui_setlist.build(sl)
    assert(ui.ok == true, "Test 1 failed")
    assert(#ui.cards == 2, "Test 2 failed")
    assert(ui.cards[1].is_current == true, "Test 3 failed")
    print("Test 1-3 passed: build creates cards with current marked")

    -- 4-6 Format Card
    local c1 = ui.cards[1]
    assert(string.find(c1.label, "Song 1"), "Test 4 failed")
    assert(string.find(c1.label, "120 BPM"), "Test 5 failed")
    assert(c1.has_project_path == false, "Test 6 failed")
    
    local c2 = ui.cards[2]
    assert(c2.has_project_path == true, "Test 6 failed")
    print("Test 4-6 passed: card formatting and metadata work")

    -- 7-9 Summary
    local lines = ui_setlist.get_summary_lines(ui)
    assert(lines[1] == "Setlist", "Test 7 failed")
    assert(string.find(lines[2], "Songs: 2"), "Test 8 failed")
    assert(string.find(ui.cards[1].label, "▶"), "Test 9 failed: current prefix")
    print("Test 7-9 passed: summary lines and prefixes work")

    -- 10 Empty build
    local ui_empty = ui_setlist.build(nil)
    assert(ui_empty.ok == false, "Test 10 failed")
    print("Test 10 passed: handles nil setlist")

    print("\nUI setlist tests passed successfully!")
end

run_ui_setlist_tests()
