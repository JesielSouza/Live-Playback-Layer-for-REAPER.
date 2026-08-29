local setlist_model = require("scripts.setlist_model")

local function run_setlist_model_tests()
    print("Running setlist model tests...\n")

    -- 1-2 Creation
    local empty = setlist_model.create_empty()
    assert(empty.version == 1, "Test 1 failed")
    assert(#empty.songs == 0, "Test 1 failed")
    print("Test 1 passed: create_empty works")

    local default = setlist_model.create_default()
    assert(#default.songs == 1, "Test 2 failed")
    assert(default.current_song_id == default.songs[1].id, "Test 2 failed")
    print("Test 2 passed: create_default works")

    -- 3-5 Normalize Song
    local s1 = setlist_model.normalize_song({ title = "Test" }, 1)
    assert(s1.id == "song_1", "Test 3 failed")
    assert(s1.title == "Test", "Test 4 failed")
    
    local s2 = setlist_model.normalize_song({ bpm = 120 }, 2)
    assert(s2.bpm == 120, "Test 5 failed")
    print("Test 3-5 passed: normalize_song works")

    -- 6-7 Normalize Setlist
    local raw = { songs = { { title = "S1" }, { title = "S2" } } }
    local sl = setlist_model.normalize_setlist(raw)
    assert(sl.current_song_id == sl.songs[1].id, "Test 6 failed")
    
    raw.current_song_id = "non-existent"
    local sl2 = setlist_model.normalize_setlist(raw)
    assert(sl2.current_song_id == sl2.songs[1].id, "Test 7 failed")
    assert(sl2.warnings[1] == "current_song_not_found", "Test 7 failed")
    print("Test 6-7 passed: normalize_setlist works")

    -- 8-12 Navigation
    local songs = setlist_model.get_songs(sl)
    assert(#songs == 2, "Test 8 failed")
    
    local next_s = setlist_model.get_next_song(sl)
    assert(next_s.id == songs[2].id, "Test 9 failed")
    
    sl.current_song_id = songs[2].id
    assert(setlist_model.get_next_song(sl) == nil, "Test 10 failed")
    
    local prev_s = setlist_model.get_previous_song(sl)
    assert(prev_s.id == songs[1].id, "Test 11 failed")
    
    sl.current_song_id = songs[1].id
    assert(setlist_model.get_previous_song(sl) == nil, "Test 12 failed")
    print("Test 8-12 passed: Navigation logic works")

    -- 13-15 Move
    local res1 = setlist_model.move_next(sl)
    assert(res1.ok == true, "Test 13 failed")
    assert(sl.current_song_id == songs[2].id, "Test 13 failed")
    
    local res2 = setlist_model.move_next(sl)
    assert(res2.ok == false, "Test 14 failed")
    
    local res3 = setlist_model.move_previous(sl)
    assert(res3.ok == true, "Test 15 failed")
    assert(sl.current_song_id == songs[1].id, "Test 15 failed")
    print("Test 13-15 passed: move_next/previous works")

    -- 16-18 Add/Remove
    setlist_model.add_song(sl, { title = "S3" })
    assert(#sl.songs == 3, "Test 16 failed")
    
    setlist_model.remove_song(sl, songs[1].id)
    assert(#sl.songs == 2, "Test 17 failed")
    assert(sl.current_song_id == sl.songs[1].id, "Test 18 failed: current redefined after remove")
    print("Test 16-18 passed: add/remove works")

    -- 19-20 Reorder
    local song2_id = sl.songs[1].id
    setlist_model.reorder_song(sl, song2_id, "down")
    assert(sl.songs[1].title == "S3", "Test 19 failed")
    
    setlist_model.reorder_song(sl, song2_id, "up")
    assert(sl.songs[1].title == "S2", "Test 20 failed")
    print("Test 19-20 passed: reorder works")

    -- 21 Validate
    setlist_model.add_song(sl, { id = "dup", title = "D1" })
    setlist_model.add_song(sl, { id = "dup", title = "D2" })
    local val = setlist_model.validate(sl)
    assert(val.ok == false, "Test 21 failed")
    assert(val.errors[1] == "duplicate_song_id", "Test 21 failed")
    print("Test 21 passed: validation detects duplicates")

    -- 22 Summary
    local summ = setlist_model.get_summary(sl)
    assert(summ.song_count == 4, "Test 22 failed")
    print("Test 22 passed: get_summary works")

    print("\nSetlist model tests passed successfully!")
end

run_setlist_model_tests()
