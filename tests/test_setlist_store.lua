local setlist_store = require("scripts.setlist_store")
local setlist_model = require("scripts.setlist_model")

local function run_setlist_store_tests()
    print("Running setlist store tests...\n")

    local test_path = "tests/tmp_setlist_test.lua"
    
    -- Path Resolution
    local default_path = setlist_store.get_default_path()
    assert(type(default_path) == "string", "Test Path 1 failed")
    assert(string.find(default_path, "live_playback_setlist.lua"), "Test Path 2 failed")
    print("Test Path passed: get_default_path returns absolute-like path")

    -- 1-3 Serialize
    local sl = setlist_model.create_default()
    local content = setlist_store.serialize(sl)
    assert(string.find(content, "return {"), "Test 1 failed")
    assert(string.find(content, "current_song_id ="), "Test 1 failed")
    
    local sl_escape = setlist_model.create_empty()
    setlist_model.add_song(sl_escape, { title = "Song \"With Quotes\"" })
    local content_escape = setlist_store.serialize(sl_escape)
    assert(string.find(content_escape, "\\\""), "Test 2 failed: aspas must be escaped")
    print("Test 1-3 passed: serialize works with escaping")

    -- 4 Deserialize
    local raw = setlist_store.deserialize(content)
    assert(type(raw) == "table", "Test 4 failed")
    assert(raw.current_song_id == sl.current_song_id, "Test 4 failed")
    print("Test 4 passed: deserialize returns table")

    -- 5-7 Save/Load
    local save_res = setlist_store.save(sl, test_path)
    assert(save_res.ok == true, "Test 5 failed")
    assert(save_res.path == test_path, "Test 5 failed")
    
    local load_res = setlist_store.load(test_path)
    assert(load_res.ok == true, "Test 6 failed")
    assert(load_res.setlist.current_song_id == sl.current_song_id, "Test 6 failed")
    assert(load_res.path == test_path, "Test 6 failed")
    
    local missing_res = setlist_store.load("non-existent-path")
    assert(missing_res.ok == false, "Test 7 failed")
    assert(missing_res.reason == "setlist_file_not_found", "Test 7 failed")
    assert(missing_res.path == "non-existent-path", "Test 7 failed")
    print("Test 5-7 passed: save/load works with explicit path")

    -- 8-9 Ensure
    os.remove(test_path)
    local sl_ens = setlist_store.ensure(test_path)
    assert(sl_ens ~= nil, "Test 8 failed")
    assert(#sl_ens.songs == 1, "Test 8 failed")
    assert(setlist_store.exists(test_path), "Test 8 failed")
    
    local sl_ens2 = setlist_store.ensure(test_path)
    assert(sl_ens2.current_song_id == sl_ens.current_song_id, "Test 9 failed: load existing")
    print("Test 8-9 passed: ensure works")

    -- 10 Invalid content
    local f = io.open(test_path, "w")
    f:write("invalid lua code")
    f:close()
    local inv_res = setlist_store.load(test_path)
    assert(inv_res.ok == false, "Test 10 failed")
    assert(inv_res.reason == "setlist_load_failed", "Test 10 failed")
    assert(inv_res.error ~= nil, "Test 10 failed: must include error detail")
    print("Test 10 passed: handles invalid content with error detail")

    -- 11 Save Failure
    local invalid_path = "/invalid/path/that/does/not/exist/setlist.lua"
    local fail_res = setlist_store.save(sl, invalid_path)
    assert(fail_res.ok == false, "Test 11 failed")
    assert(fail_res.reason == "setlist_save_failed", "Test 11 failed")
    assert(fail_res.error ~= nil, "Test 11 failed")
    print("Test 11 passed: handles save failure with detail")

    -- Cleanup
    os.remove(test_path)
    print("\nSetlist store tests passed successfully!")
end

run_setlist_store_tests()
