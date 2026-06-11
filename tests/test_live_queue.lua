local live_queue = require("scripts.live_queue")

local function run_live_queue_tests()
    print("Running live queue tests...\n")

    -- 1. Create
    local q = live_queue.create()
    assert(type(q.items) == "table" and #q.items == 0, "Test 1 failed")
    print("Test 1 passed: create works")

    -- 2-4. Add section
    live_queue.add_section(q, "CHORUS_1", { label = "Chorus 1", target_position = 30.0 })
    assert(#q.items == 1, "Test 2 failed")
    assert(q.items[1].section_id == "CHORUS_1", "Test 3 failed")
    assert(q.items[1].label == "Chorus 1", "Test 3 failed")
    assert(q.items[1].target_position == 30.0, "Test 4 failed")
    print("Test 2-4 passed: add_section works")

    -- 5-6. Peek/Pop
    local item = live_queue.peek(q)
    assert(item.section_id == "CHORUS_1", "Test 5 failed")
    
    local item2 = live_queue.pop(q)
    assert(item2.section_id == "CHORUS_1", "Test 6 failed")
    assert(#q.items == 0, "Test 6 failed")
    print("Test 5-6 passed: peek/pop works")

    -- 7. Remove at
    live_queue.add_section(q, "S1")
    live_queue.add_section(q, "S2")
    live_queue.remove_at(q, 1)
    assert(#q.items == 1 and q.items[1].section_id == "S2", "Test 7 failed")
    print("Test 7 passed: remove_at works")

    -- 8. Clear
    live_queue.clear(q)
    assert(#q.items == 0, "Test 8 failed")
    print("Test 8 passed: clear works")

    -- 9-10. Move
    live_queue.add_section(q, "S1")
    live_queue.add_section(q, "S2")
    live_queue.move_up(q, 2)
    assert(q.items[1].section_id == "S2", "Test 9 failed")
    live_queue.move_down(q, 1)
    assert(q.items[1].section_id == "S1", "Test 10 failed")
    print("Test 9-10 passed: move up/down works")

    -- 11. Is empty
    assert(live_queue.is_empty(q) == false, "Test 11 failed")
    live_queue.clear(q)
    assert(live_queue.is_empty(q) == true, "Test 11 failed")
    print("Test 11 passed: is_empty works")

    -- 12. Summary
    live_queue.add_section(q, "S1")
    local summ = live_queue.get_summary(q)
    assert(summ.count == 1 and summ.has_items == true, "Test 12 failed")
    print("Test 12 passed: get_summary works")

    -- 13. Validate
    local song_map = { ok = true, sections = { { id = "S2", name = "S2" } } }
    live_queue.add_section(q, "MISSING")
    live_queue.validate_against_song_map(q, song_map)
    assert(#q.warnings > 0, "Test 13 failed")
    print("Test 13 passed: validate detects missing sections")

    -- 14. Format
    local formatted = live_queue.format_item(q.items[1], 1)
    assert(string.find(formatted, "1. S1"), "Test 14 failed")
    print("Test 14 passed: format_item works")

    print("\nLive queue tests passed successfully!")
end

run_live_queue_tests()
