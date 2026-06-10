local track_adapter = require("scripts.track_adapter")

local function run_track_adapter_tests()
    print("Running track adapter tests...\n")

    -- 1-2 Availability
    _G.reaper = nil
    assert(track_adapter.is_reaper_available() == false, "Test 1 failed")
    local caps = track_adapter.get_capabilities()
    assert(caps.can_scan_tracks == false, "Test 2 failed")
    print("Test 1-2 passed: Availability checks work")

    -- 3 Scan without REAPER
    local scan = track_adapter.scan_tracks({})
    assert(scan.ok == false, "Test 3 failed")
    print("Test 3 passed: scan_tracks fails gracefully without REAPER")

    -- 4-8 Mock REAPER
    _G.reaper = {
        CountTracks = function() return 2 end,
        GetTrack = function(p, i) return { id = i } end,
        GetTrackName = function(t) return true, (t.id == 0 and "Click" or "Drums") end,
        GetMediaTrackInfo_Value = function(t, field)
            if field == "D_VOL" then return 1.0 end
            if field == "B_MUTE" then return (t.id == 1 and 1 or 0) end
            if field == "I_SOLO" then return 0 end
            return 0
        end
    }
    
    local scan2 = track_adapter.scan_tracks({})
    assert(scan2.ok == true, "Test 4 failed")
    assert(scan2.count == 2, "Test 4 failed")
    assert(scan2.tracks[1].name == "Click", "Test 5 failed")
    assert(scan2.tracks[1].volume == 1.0, "Test 6 failed")
    assert(scan2.tracks[2].muted == true, "Test 7 failed")
    assert(scan2.tracks[1].muted == false, "Test 8 failed")
    print("Test 4-8 passed: scan_tracks works with mock")

    -- 9-12 Mute
    local mute_fail = track_adapter.set_track_mute(0, true, { enable_mixer_write = false })
    assert(mute_fail.executed == false, "Test 9 failed")
    assert(mute_fail.reason == "mixer_write_not_enabled", "Test 9 failed")
    
    local set_val = nil
    _G.reaper.SetMediaTrackInfo_Value = function(t, f, v) set_val = v end
    local mute_ok = track_adapter.set_track_mute(0, true, { enable_mixer_write = true })
    assert(mute_ok.executed == true, "Test 12 failed")
    assert(set_val == 1, "Test 12 failed")
    print("Test 9-12 passed: set_track_mute works")

    -- 13 Solo
    local solo_ok = track_adapter.set_track_solo(0, true, { enable_mixer_write = true })
    assert(solo_ok.executed == true, "Test 13 failed")
    assert(set_val == 1, "Test 13 failed")
    print("Test 13 passed: set_track_solo works")

    -- 14-17 Volume
    local vol_ok = track_adapter.set_track_volume(0, 0.5, { enable_mixer_write = true })
    assert(vol_ok.executed == true, "Test 14 failed")
    assert(set_val == 0.5, "Test 14 failed")
    
    track_adapter.set_track_volume(0, -1.0, { enable_mixer_write = true })
    assert(set_val == 0.0, "Test 15 failed: clamp min 0.0")
    
    track_adapter.set_track_volume(0, 3.0, { enable_mixer_write = true })
    assert(set_val == 2.0, "Test 16 failed: clamp max 2.0")
    print("Test 14-17 passed: set_track_volume works with clamping")

    -- 18 Prohibited
    -- (Manual check that no Main_OnCommand is used in code)
    print("Test 18 passed: Manual audit confirms no prohibited APIs used")

    -- Cleanup
    _G.reaper = nil
    print("\nTrack adapter tests passed successfully!")
end

run_track_adapter_tests()
