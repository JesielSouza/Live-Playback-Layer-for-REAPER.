local track_catalog = require("scripts.track_catalog")

local function run_track_catalog_tests()
    print("Running track catalog tests...\n")

    -- 1-10 Classification tests
    assert(track_catalog.classify_track_name("CLICK") == "click", "Test 1 failed")
    assert(track_catalog.classify_track_name("Metronome") == "click", "Test 1 failed")
    assert(track_catalog.classify_track_name("GUIDE") == "guide", "Test 2 failed")
    assert(track_catalog.classify_track_name("Vocal Cue") == "guide", "Test 2 failed")
    assert(track_catalog.classify_track_name("Bateria") == "drums", "Test 3 failed")
    assert(track_catalog.classify_track_name("Bass") == "bass", "Test 4 failed")
    assert(track_catalog.classify_track_name("Piano") == "keys", "Test 5 failed")
    assert(track_catalog.classify_track_name("Guitar") == "guitars", "Test 6 failed")
    assert(track_catalog.classify_track_name("Vocals") == "vocals", "Test 7 failed")
    assert(track_catalog.classify_track_name("Ambient Pad") == "pads", "Test 8 failed")
    assert(track_catalog.classify_track_name("Loop 1") == "tracks", "Test 9 failed")
    assert(track_catalog.classify_track_name("Unknown Thing") == "other", "Test 10 failed")
    print("Test 1-10 passed: Classification works")

    -- 11 Priority
    assert(track_catalog.classify_track_name("Click Guide") == "click", "Test 11 failed")
    print("Test 11 passed: Priority (click > guide) works")

    -- 12-16 Normalize
    local raw = { id = 0, display_index = 1, name = "Drums", volume = 0.5, muted = true, soloed = false }
    local normalized = track_catalog.normalize_track(raw)
    assert(normalized.id == 0, "Test 12 failed")
    assert(normalized.volume_percent == 50, "Test 13 failed")
    assert(normalized.category == "drums", "Test 14 failed")
    assert(normalized.is_click == false, "Test 14 failed")
    assert(normalized.is_guide == false, "Test 15 failed")
    assert(normalized.is_stem == true, "Test 16 failed")
    print("Test 12-16 passed: Normalization works")

    -- 17-20 Build
    local scan = {
        ok = true,
        tracks = {
            { id = 0, name = "Click", volume = 1.0, muted = false, soloed = false },
            { id = 1, name = "Drums", volume = 0.8, muted = true, soloed = false },
            { id = 2, name = "Vocals", volume = 1.0, muted = false, soloed = true }
        }
    }
    local catalog = track_catalog.build(scan)
    assert(catalog.ok == true, "Test 17 failed")
    assert(#catalog.tracks == 3, "Test 18 failed")
    assert(catalog.summary.total_tracks == 3, "Test 18 failed")
    assert(catalog.summary.muted_count == 1, "Test 19 failed")
    assert(catalog.summary.soloed_count == 1, "Test 20 failed")
    assert(catalog.summary.click_count == 1, "Test 20 failed")
    print("Test 17-20 passed: Build catalog works")

    print("\nTrack catalog tests passed successfully!")
end

run_track_catalog_tests()
