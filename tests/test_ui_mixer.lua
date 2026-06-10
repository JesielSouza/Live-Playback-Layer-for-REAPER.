local ui_mixer = require("scripts.ui_mixer")
local track_catalog = require("scripts.track_catalog")
local mixer_state = require("scripts.mixer_state")

local function run_ui_mixer_tests()
    print("Running UI mixer tests...\n")

    local scan = {
        ok = true,
        tracks = {
            { id = 0, name = "Click", volume = 1.0, muted = false, soloed = false },
            { id = 1, name = "Bateria", volume = 0.8, muted = true, soloed = false }
        }
    }
    local catalog = track_catalog.build(scan)
    local state = mixer_state.create()
    
    local ui = ui_mixer.build(catalog, state)
    assert(ui.ok == true, "Test 1 failed")
    assert(#ui.rows == 2, "Test 2 failed")
    assert(#ui.categories == 2, "Test 3 failed")
    print("Test 1-3 passed: Build UI Mixer works")

    local summary = ui_mixer.get_summary_lines(ui)
    assert(string.find(summary[2], "total=2"), "Test 4 failed")
    print("Test 4 passed: Summary lines correct")

    local row = ui.rows[1]
    assert(string.find(row.label, "CLICK"), "Test 5 failed")
    assert(string.find(row.label, "100%%"), "Test 6 failed")
    print("Test 5-6 passed: Track row label correct")

    mixer_state.set_selected_track(state, 0)
    local ui2 = ui_mixer.build(catalog, state)
    assert(ui2.rows[1].selected == true, "Test 7 failed")
    print("Test 7 passed: Selection reflected in UI row")

    local categories = ui_mixer.get_category_sections(ui)
    assert(categories[1].id == "click", "Test 8 failed")
    assert(categories[2].id == "drums", "Test 9 failed")
    print("Test 8-9 passed: Category ordering correct")

    print("\nUI mixer tests passed successfully!")
end

run_ui_mixer_tests()
