local loop_mode = require("scripts.loop_mode")

local function run_loop_mode_tests()
    print("Running loop mode tests...\n")

    -- 1. Create
    local l = loop_mode.create()
    assert(l.enabled == false, "Test 1 failed")
    print("Test 1 passed: create works")

    -- 2-3. Enable
    loop_mode.enable(l, "CHORUS_1", { label = "Chorus 1", target_position = 30.0 })
    assert(l.enabled == true, "Test 2 failed")
    assert(l.section_id == "CHORUS_1", "Test 3 failed")
    assert(l.target_position == 30.0, "Test 3 failed")
    print("Test 2-3 passed: enable works")

    -- 4. Disable
    loop_mode.disable(l)
    assert(l.enabled == false and l.section_id == nil, "Test 4 failed")
    print("Test 4 passed: disable works")

    -- 5-7. Toggle
    loop_mode.toggle(l, "S1")
    assert(l.enabled == true and l.section_id == "S1", "Test 5 failed")
    loop_mode.toggle(l, "S1")
    assert(l.enabled == false, "Test 6 failed")
    loop_mode.toggle(l, "S1")
    loop_mode.toggle(l, "S2")
    assert(l.enabled == true and l.section_id == "S2", "Test 7 failed")
    print("Test 5-7 passed: toggle works")

    -- 8-9. Getters
    assert(loop_mode.is_enabled(l) == true, "Test 8 failed")
    assert(loop_mode.get_section(l) == "S2", "Test 9 failed")
    print("Test 8-9 passed: getters work")

    -- 10. Validate
    local song_map = { ok = true, sections = { { id = "S1", name = "S1" } } }
    loop_mode.validate_against_song_map(l, song_map)
    assert(#l.warnings > 0, "Test 10 failed: S2 not in map")
    print("Test 10 passed: validate works")

    -- 11-12. Format
    local f1 = loop_mode.format({ enabled = false })
    assert(string.find(f1, "OFF"), "Test 11 failed")
    local f2 = loop_mode.format(l)
    assert(string.find(f2, "ON S2"), "Test 12 failed")
    print("Test 11-12 passed: format works")

    print("\nLoop mode tests passed successfully!")
end

run_loop_mode_tests()
