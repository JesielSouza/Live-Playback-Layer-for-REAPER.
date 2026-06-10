local song_map = require("scripts.song_map")

local function build_snapshot()
    return {
        current_section = "VERSE_1",
        next_section = "CHORUS_1",
        sections = {
            { name = "INTRO", start = 0, ["end"] = 10 },
            { name = "VERSE_1", start = 10, ["end"] = 30 },
            { name = "CHORUS_1", start = 30, ["end"] = 50, loop = true },
            { name = "ENDING", start = 50, ["end"] = 60 }
        }
    }
end

local function run_song_map_tests()
    print("Running song map tests...\n")

    local missing = song_map.build(nil)
    assert(missing.ok == false, "Test 1 failed")
    assert(missing.errors[1] == "no_sections_found", "Test 1 failed")
    print("Test 1 passed: build with nil returns ok=false")

    local map = song_map.build(build_snapshot())
    assert(map.ok == true, "Test 2 failed")
    assert(#map.sections == 4, "Test 2 failed")
    print("Test 2 passed: build with valid snapshot returns ok=true")

    local intro = map.sections[1]
    assert(intro.name == "INTRO", "Test 3 failed")
    assert(intro.start == 0, "Test 3 failed")
    assert(intro.end_pos == 10, "Test 3 failed")
    assert(intro.duration == 10, "Test 3 failed")
    print("Test 3 passed: section normalization works")

    local verse = map.sections[2]
    assert(verse.is_current == true, "Test 4 failed")
    assert(verse.is_next == false, "Test 4 failed")
    print("Test 4 passed: is_current marked correctly")

    local chorus = map.sections[3]
    assert(chorus.is_current == false, "Test 5 failed")
    assert(chorus.is_next == true, "Test 5 failed")
    assert(chorus.loop == true, "Test 5 failed")
    print("Test 5 passed: is_next and loop marked correctly")

    local found = song_map.find_section(map, "ENDING")
    assert(found ~= nil, "Test 6 failed")
    assert(found.name == "ENDING", "Test 6 failed")
    print("Test 6 passed: find_section works")

    song_map.select_section(map, "ENDING")
    assert(map.selected_section == "ENDING", "Test 7 failed")
    assert(found.is_selected == true, "Test 7 failed")
    print("Test 7 passed: select_section works")

    local intent = song_map.build_intent_for_section(map, "ENDING")
    assert(intent.ok == true, "Test 8 failed")
    assert(intent.action == "jump_to_section", "Test 8 failed")
    assert(intent.target_section == "ENDING", "Test 8 failed")
    assert(intent.target_position == 50, "Test 8 failed")
    print("Test 8 passed: build_intent_for_section works")

    local loop_intent = song_map.build_loop_current_intent(map)
    assert(loop_intent.ok == true, "Test 9 failed")
    assert(loop_intent.action == "loop_current", "Test 9 failed")
    assert(loop_intent.target_section == "VERSE_1", "Test 9 failed")
    assert(loop_intent.target_position == 10, "Test 9 failed")
    print("Test 9 passed: build_loop_current_intent works")

    local summary = song_map.get_summary(map)
    assert(summary.section_count == 4, "Test 10 failed")
    assert(summary.current_section == "VERSE_1", "Test 10 failed")
    assert(summary.selected_section == "ENDING", "Test 10 failed")
    print("Test 10 passed: get_summary works")

    print("\nSong map tests passed successfully!")
end

run_song_map_tests()
