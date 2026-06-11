local midi_cue_model = require("scripts.midi_cue_model")

local function run_midi_cue_model_tests()
    print("Running midi cue model tests...\n")

    -- 1-3 Utils
    assert(midi_cue_model.trim("  test  ") == "test", "Test 1 failed")
    assert(midi_cue_model.parse_int("60") == 60, "Test 2 failed")
    assert(midi_cue_model.parse_int("60.5") == nil, "Test 3 failed")
    print("Test 1-3 passed: Utils work")

    -- 4-7 Parse Payload Success
    local res1 = midi_cue_model.parse_payload("note_on:1:60:100")
    assert(res1.ok == true, "Test 5 failed")
    assert(res1.command == "note_on", "Test 5 failed")
    assert(res1.channel == 1, "Test 5 failed")
    assert(res1.note == 60, "Test 5 failed")
    assert(res1.velocity == 100, "Test 5 failed")

    local res2 = midi_cue_model.parse_payload("cc:16:20:127")
    assert(res2.ok == true, "Test 7 failed")
    assert(res2.controller == 20, "Test 7 failed")
    assert(res2.value == 127, "Test 7 failed")
    print("Test 4-7 passed: Payload parsing works")

    -- 8-16 Parse Payload Failure
    assert(midi_cue_model.parse_payload("").reason == "missing_midi_payload", "Test 4 failed")
    assert(midi_cue_model.parse_payload("note_on:1:60").reason == "invalid_midi_format", "Test 8 failed")
    assert(midi_cue_model.parse_payload("invalid:1:60:100").reason == "invalid_midi_command", "Test 8 failed")
    assert(midi_cue_model.parse_payload("note_on:17:60:100").reason == "invalid_midi_channel", "Test 10 failed")
    assert(midi_cue_model.parse_payload("note_on:1:128:100").reason == "invalid_midi_note", "Test 12 failed")
    assert(midi_cue_model.parse_payload("cc:1:20:128").reason == "invalid_midi_value", "Test 16 failed")
    print("Test 8-16 passed: Validation rules work")

    -- 17-21 Build Events
    local cues = {
        { id = "c1", type = "midi_placeholder", section_id = "S1", payload = "note_on:1:60:100", enabled = true, label = "L1" },
        { id = "c2", type = "note", section_id = "S1" },
        { id = "c3", type = "midi_placeholder", section_id = "S1", payload = "invalid", enabled = true, label = "L3" }
    }
    local out = midi_cue_model.build_events_for_cues(cues)
    assert(#out.events == 1, "Test 20 failed")
    assert(#out.invalid == 1, "Test 21 failed")
    assert(out.events[1].planned_only == true, "Test 19 failed")
    print("Test 17-21 passed: Build events from cues works")

    -- 22-23 format/summary
    local fmt = midi_cue_model.format_event(out.events[1])
    assert(string.find(fmt, "DRY"), "Test 22 failed")
    assert(string.find(fmt, "note_on"), "Test 22 failed")
    
    local summ = midi_cue_model.get_summary(out.events)
    assert(summ.valid == 1, "Test 23 failed")
    print("Test 22-23 passed: Format and Summary work")

    print("\nMIDI cue model tests passed successfully!")
end

run_midi_cue_model_tests()
