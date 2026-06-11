local cue_store = require("scripts.cue_store")
local cue_model = require("scripts.cue_model")

local function run_cue_store_tests()
    print("Running cue store tests...\n")

    local test_path = "tests/tmp_cues_test.lua"
    
    -- Path Resolution
    local default_path = cue_store.get_default_path()
    assert(type(default_path) == "string", "Test Path 1 failed")
    assert(string.find(default_path, "live_playback_cues.lua"), "Test Path 2 failed")
    print("Test Path passed: get_default_path returns absolute-like path")

    -- 1-3 Serialize
    local store = cue_model.create_empty()
    cue_model.add_cue(store, { section_id = "S1", label = "Note \"With Quotes\"" })
    local content = cue_store.serialize(store)
    assert(string.find(content, "return {"), "Test 1 failed")
    assert(string.find(content, "\\\""), "Test 2 failed: aspas must be escaped")
    print("Test 1-3 passed: serialize works with escaping")

    -- 4 Deserialize
    local raw = cue_store.deserialize(content)
    assert(type(raw) == "table", "Test 4 failed")
    assert(#raw.cues == 1, "Test 4 failed")
    print("Test 4 passed: deserialize returns table")

    -- 5-7 Save/Load
    local save_res = cue_store.save(store, test_path)
    assert(save_res.ok == true, "Test 5 failed")
    
    local load_res = cue_store.load(test_path)
    assert(load_res.ok == true, "Test 6 failed")
    assert(#load_res.store.cues == 1, "Test 6 failed")
    
    local missing_res = cue_store.load("non-existent-path")
    assert(missing_res.ok == false, "Test 7 failed")
    assert(missing_res.reason == "cue_file_not_found", "Test 7 failed")
    print("Test 5-7 passed: save/load works with explicit path")

    -- 8-9 Ensure
    os.remove(test_path)
    local s_ens = cue_store.ensure(test_path)
    assert(s_ens ~= nil, "Test 8 failed")
    assert(#s_ens.cues == 0, "Test 8 failed")
    assert(cue_store.exists(test_path), "Test 8 failed")
    print("Test 8-9 passed: ensure works")

    -- 10 Invalid content
    local f = io.open(test_path, "w")
    f:write("invalid lua code")
    f:close()
    local inv_res = cue_store.load(test_path)
    assert(inv_res.ok == false, "Test 10 failed")
    assert(inv_res.reason == "cue_load_failed", "Test 10 failed")
    print("Test 10 passed: handles invalid content")

    -- Cleanup
    os.remove(test_path)
    print("\nCue store tests passed successfully!")
end

run_cue_store_tests()
