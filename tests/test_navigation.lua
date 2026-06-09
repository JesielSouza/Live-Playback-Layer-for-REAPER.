local navigation = require("scripts.navigation")

local function make_sections()
    return {
        { name = "CHORUS_1", start_pos = 30, end_pos = 50, meta = { loop = "1", next = "ENDING" } },
        { name = "INTRO", start_pos = 0, end_pos = 10, meta = { loop = "0", next = "VERSE_1" } },
        { name = "ENDING", start_pos = 50, end_pos = 60, meta = { loop = "0" } },
        { name = "VERSE_1", start_pos = 10, end_pos = 30, meta = { loop = "0", next = "CHORUS_1" } }
    }
end

local function run_navigation_tests()
    print("Running navigation tests...\n")

    local sections = make_sections()

    local index = navigation.build_section_index(sections)
    assert(index.by_name.INTRO.name == "INTRO", "Test 1 failed")
    assert(index.ordered[1].name == "INTRO", "Test 1 failed")
    assert(index.ordered[4].name == "ENDING", "Test 1 failed")
    print("Test 1 passed: build_section_index creates by_name and ordered")

    assert(navigation.get_current_section(sections).name == "INTRO", "Test 2 failed")
    print("Test 2 passed: get_current_section without name returns first section")

    assert(navigation.get_current_section(sections, "VERSE_1").name == "VERSE_1", "Test 3 failed")
    print("Test 3 passed: get_current_section with name returns matching section")

    assert(navigation.get_current_section(sections, "MISSING") == nil, "Test 4 failed")
    print("Test 4 passed: get_current_section with invalid name returns nil")

    assert(navigation.get_next_section(sections, "INTRO").name == "VERSE_1", "Test 5 failed")
    print("Test 5 passed: get_next_section uses valid metadata.next")

    assert(navigation.get_next_section(sections, "ENDING") == nil, "Test 7 failed")
    print("Test 7 passed: get_next_section returns nil at the end")

    local fallback_sections = {
        { name = "A", start_pos = 0, end_pos = 10, meta = { loop = "0" } },
        { name = "B", start_pos = 10, end_pos = 20, meta = { loop = "0" } }
    }
    assert(navigation.get_next_section(fallback_sections, "A").name == "B", "Test 6 failed")
    print("Test 6 passed: get_next_section falls back to ordered next")

    assert(navigation.get_previous_section(sections, "CHORUS_1").name == "VERSE_1", "Test 8 failed")
    print("Test 8 passed: get_previous_section returns ordered previous")

    local no_sections_plan = navigation.plan_initial_navigation({})
    assert(no_sections_plan.ok == false, "Test 9 failed")
    assert(no_sections_plan.decision == "NO_SECTIONS", "Test 9 failed")
    print("Test 9 passed: plan_initial_navigation without sections returns NO_SECTIONS")

    local invalid_plan = navigation.plan_initial_navigation(sections, "MISSING")
    assert(invalid_plan.ok == false, "Test 10 failed")
    assert(invalid_plan.decision == "INVALID_CURRENT_SECTION", "Test 10 failed")
    print("Test 10 passed: plan_initial_navigation with invalid current returns INVALID_CURRENT_SECTION")

    local loop_plan = navigation.plan_initial_navigation(sections, "CHORUS_1")
    assert(loop_plan.loop_enabled == true, "Test 11 failed")
    assert(loop_plan.decision == "LOOP_CURRENT", "Test 11 failed")
    print("Test 11 passed: plan_initial_navigation with loop=1 returns LOOP_CURRENT")

    local next_plan = navigation.plan_initial_navigation(sections, "INTRO")
    assert(next_plan.next.name == "VERSE_1", "Test 12 failed")
    assert(next_plan.decision == "NEXT_SECTION_READY", "Test 12 failed")
    print("Test 12 passed: plan_initial_navigation with next returns NEXT_SECTION_READY")

    local end_plan = navigation.plan_initial_navigation(sections, "ENDING")
    assert(end_plan.next == nil, "Test 13 failed")
    assert(end_plan.decision == "END_OF_SONG", "Test 13 failed")
    print("Test 13 passed: plan_initial_navigation at end returns END_OF_SONG")

    local sections_map = navigation.format_sections_map(sections)
    assert(string.find(sections_map, "INTRO"), "Test 14 failed")
    assert(string.find(sections_map, "CHORUS_1"), "Test 14 failed")
    print("Test 14 passed: format_sections_map contains section names")

    local plan_report = navigation.format_navigation_plan(next_plan)
    assert(string.find(plan_report, "NEXT_SECTION_READY"), "Test 15 failed")
    print("Test 15 passed: format_navigation_plan contains decision")

    print("\nNavigation tests passed successfully!")
end

run_navigation_tests()
