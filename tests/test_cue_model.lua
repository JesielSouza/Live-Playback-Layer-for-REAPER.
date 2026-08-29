local cue_model = require("scripts.cue_model")

local function run_cue_model_tests()
    print("Running cue model tests...\n")

    -- 1. Create Empty
    local empty = cue_model.create_empty()
    assert(empty.version == 1, "Test 1 failed")
    assert(#empty.cues == 0, "Test 1 failed")
    print("Test 1 passed: create_empty works")

    -- 2-4. Normalize Cue
    local c1 = cue_model.normalize_cue({ section_id = "S1", label = "Note" }, 1)
    assert(c1.id == "cue_1", "Test 2 failed")
    assert(c1.type == "note", "Test 3 failed")
    assert(c1.enabled == true, "Test 4 failed")
    print("Test 2-4 passed: normalize_cue works")

    -- 6-7. Get for Section
    local store = cue_model.create_empty()
    cue_model.add_cue(store, { section_id = "S1", label = "C1" })
    cue_model.add_cue(store, { section_id = "S2", label = "C2" })
    cue_model.add_cue(store, { section_id = "S1", label = "C3", enabled = false })
    
    local s1_cues = cue_model.get_cues_for_section(store, "S1")
    assert(#s1_cues == 2, "Test 6 failed")
    
    local s1_enabled = cue_model.get_enabled_cues_for_section(store, "S1")
    assert(#s1_enabled == 1, "Test 7 failed")
    print("Test 6-7 passed: get_cues_for_section works")

    -- 9-12. Placeholders
    cue_model.add_placeholder_cue(store, "S2", "midi_placeholder")
    local s2_cues = cue_model.get_cues_for_section(store, "S2")
    assert(#s2_cues == 2, "Test 9 failed")
    assert(s2_cues[2].type == "midi_placeholder", "Test 10 failed")
    print("Test 9-12 passed: placeholders work")

    -- 13-16. Management
    local cid = s2_cues[1].id
    cue_model.set_cue_enabled(store, cid, false)
    assert(cue_model.get_cue_by_id(store, cid).enabled == false, "Test 15 failed")
    
    cue_model.remove_cue(store, cid)
    assert(#cue_model.get_cues_for_section(store, "S2") == 1, "Test 13 failed")
    print("Test 13-16 passed: management (enable/remove) works")

    -- 18-20. Validate
    local valid = cue_model.validate(store)
    assert(valid.ok == true, "Test 18 failed")
    
    cue_model.add_cue(store, { id = "dup", section_id = "S3" })
    cue_model.add_cue(store, { id = "dup", section_id = "S4" })
    local invalid = cue_model.validate(store)
    assert(invalid.ok == false, "Test 18 failed: duplicate id")
    print("Test 18-20 passed: validation works")

    -- 21. Summary
    local summ = cue_model.get_summary(store)
    assert(summ.cue_count == 5, "Test 21 failed")
    print("Test 21 passed: get_summary works")

    print("\nCue model tests passed successfully!")
end

run_cue_model_tests()
