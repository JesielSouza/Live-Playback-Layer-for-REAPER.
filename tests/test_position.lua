local position = require("scripts.position")

local function make_sections()
    return {
        { name = "INTRO", start_pos = 0, end_pos = 10, meta = { loop = "0", next = "VERSE_1" } },
        { name = "VERSE_1", start_pos = 10, end_pos = 30, meta = { loop = "0", next = "CHORUS_1" } },
        { name = "CHORUS_1", start_pos = 30, end_pos = 50, meta = { loop = "1", next = "ENDING" } },
        { name = "ENDING", start_pos = 50, end_pos = 60, meta = { loop = "0" } }
    }
end

local function run_position_tests()
    print("Running position tests...\n")

    local sections = make_sections()

    assert(position.find_section_at_position(sections, 5).name == "INTRO", "Test 1 failed")
    print("Test 1 passed: find_section_at_position finds first section")

    assert(position.find_section_at_position(sections, 12).name == "VERSE_1", "Test 2 failed")
    print("Test 2 passed: find_section_at_position finds intermediate section")

    assert(position.find_section_at_position(sections, 55).name == "ENDING", "Test 3 failed")
    print("Test 3 passed: find_section_at_position finds last section")

    assert(position.find_section_at_position(sections, -1) == nil, "Test 4 failed")
    print("Test 4 passed: find_section_at_position returns nil before first section")

    assert(position.find_section_at_position(sections, 61) == nil, "Test 5 failed")
    print("Test 5 passed: find_section_at_position returns nil after last section")

    assert(position.find_section_at_position(sections, 60).name == "ENDING", "Test 6 failed")
    print("Test 6 passed: find_section_at_position treats last end_pos as last section")

    local verse_snapshot = position.build_position_snapshot(sections, 12)
    assert(verse_snapshot.ok == true, "Test 7 failed")
    print("Test 7 passed: build_position_snapshot with valid position returns ok=true")

    assert(verse_snapshot.current_section.name == "VERSE_1", "Test 8 failed")
    print("Test 8 passed: build_position_snapshot includes current_section")

    assert(verse_snapshot.next_section.name == "CHORUS_1", "Test 9 failed")
    print("Test 9 passed: build_position_snapshot includes next_section")

    assert(verse_snapshot.previous_section.name == "INTRO", "Test 10 failed")
    print("Test 10 passed: build_position_snapshot includes previous_section when applicable")

    local missing_position_snapshot = position.build_position_snapshot(sections, nil)
    assert(missing_position_snapshot.ok == false, "Test 11 failed")
    assert(missing_position_snapshot.errors[1] == "missing_position", "Test 11 failed")
    print("Test 11 passed: build_position_snapshot with nil position returns ok=false")

    local missing_sections_snapshot = position.build_position_snapshot({}, 12)
    assert(missing_sections_snapshot.ok == false, "Test 12 failed")
    assert(missing_sections_snapshot.errors[1] == "missing_sections", "Test 12 failed")
    print("Test 12 passed: build_position_snapshot without sections returns ok=false")

    local formatted = position.format_position_snapshot(verse_snapshot)
    assert(string.find(formatted, "Current Position"), "Test 13 failed")
    print("Test 13 passed: format_position_snapshot contains Current Position")

    assert(string.find(formatted, "Current Section"), "Test 14 failed")
    print("Test 14 passed: format_position_snapshot contains Current Section")

    local original_reaper = _G.reaper
    _G.reaper = {
        GetCursorPosition = function()
            return 12.5
        end
    }
    local reaper_position = position.get_reaper_position()
    assert(reaper_position.ok == true, "Test 15 failed")
    assert(reaper_position.position == 12.5, "Test 15 failed")
    assert(reaper_position.source == "reaper_cursor", "Test 15 failed")
    print("Test 15 passed: get_reaper_position with mock returns cursor position")

    _G.reaper = nil
    local unavailable_position_ok = pcall(function()
        local result = position.get_reaper_position()
        assert(result.ok == false, "Test 16 failed")
        assert(result.position == nil, "Test 16 failed")
        assert(result.source == "unavailable", "Test 16 failed")
    end)
    assert(unavailable_position_ok == true, "Test 16 failed")
    print("Test 16 passed: get_reaper_position without REAPER does not crash")

    _G.reaper = original_reaper

    print("\nPosition tests passed successfully!")
end

run_position_tests()
