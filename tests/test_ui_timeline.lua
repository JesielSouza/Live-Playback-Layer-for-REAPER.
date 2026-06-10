local ui_timeline = require("scripts.ui_timeline")
local song_map = require("scripts.song_map")

local function build_song_map()
    local snapshot = {
        current_section = "VERSE_1",
        next_section = "CHORUS_1",
        sections = {
            { name = "INTRO", start = 0, ["end"] = 10 },
            { name = "VERSE_1", start = 10, ["end"] = 30 },
            { name = "CHORUS_1", start = 30, ["end"] = 50 },
            { name = "BRIDGE", start = 50, ["end"] = 70 }
        }
    }
    return song_map.build(snapshot)
end

local function run_ui_timeline_tests()
    print("Running UI timeline tests...\n")

    local map = build_song_map()
    local timeline = ui_timeline.build(map)
    assert(timeline.ok == true, "Test 1 failed")
    assert(#timeline.blocks == 4, "Test 1 failed")
    print("Test 1 passed: build creates blocks")

    local verse = timeline.blocks[2]
    assert(verse.state == "current", "Test 2 failed")
    assert(verse.is_current == true, "Test 2 failed")
    print("Test 2 passed: current state correct")

    local chorus = timeline.blocks[3]
    assert(chorus.state == "next", "Test 3 failed")
    assert(chorus.is_next == true, "Test 3 failed")
    print("Test 3 passed: next state correct")

    song_map.select_section(map, "BRIDGE")
    local timeline2 = ui_timeline.build(map)
    local bridge = timeline2.blocks[4]
    assert(bridge.state == "selected", "Test 4 failed")
    assert(bridge.is_selected == true, "Test 4 failed")
    print("Test 4 passed: selected state correct")

    assert(verse.width_weight == 20, "Test 5 failed")
    print("Test 5 passed: width_weight uses duration")

    local formatted = ui_timeline.format_block(verse)
    assert(string.find(formatted, "CURRENT"), "Test 6 failed")
    print("Test 6 passed: format_block contains CURRENT")

    local selected = ui_timeline.get_selected_block(timeline2)
    assert(selected.id == "BRIDGE", "Test 7 failed")
    print("Test 7 passed: get_selected_block works")

    print("\nUI timeline tests passed successfully!")
end

run_ui_timeline_tests()
