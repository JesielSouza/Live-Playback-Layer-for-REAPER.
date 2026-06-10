local seek_plan = require("scripts.seek_plan")
local transport_adapter = require("scripts.transport_adapter")
local transport_control = require("scripts.transport_control")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        current_section = "VERSE_1",
        target_section = "CHORUS_1"
    }
end

local function build_runtime()
    return {
        ok = true,
        current_section = "VERSE_1",
        sections = {
            { key = "CHORUS_1", start = 42 },
            { name = "BRIDGE", start = 84 },
            { id = "ENDING", start = 126 }
        }
    }
end

local function run_seek_plan_tests()
    print("Running seek plan tests...\n")

    local missing_intent = seek_plan.build(nil, build_runtime())
    assert(missing_intent.reason == "missing_intent", "Test 1 failed")
    print("Test 1 passed: build without intent returns missing_intent")

    local missing_runtime = seek_plan.build(build_intent(), nil)
    assert(missing_runtime.reason == "missing_runtime_snapshot", "Test 2 failed")
    print("Test 2 passed: build without runtime returns missing_runtime_snapshot")

    local bad_intent = build_intent()
    bad_intent.ok = false
    local intent_not_ok = seek_plan.build(bad_intent, build_runtime())
    assert(intent_not_ok.reason == "intent_not_ok", "Test 3 failed")
    print("Test 3 passed: intent_not_ok returns intent_not_ok")

    local no_target = build_intent()
    no_target.target_section = nil
    local missing_target = seek_plan.build(no_target, build_runtime())
    assert(missing_target.reason == "missing_target_section", "Test 4 failed")
    print("Test 4 passed: missing target_section returns missing_target_section")

    local direct = build_intent()
    direct.target_position = 12.5
    local direct_plan = seek_plan.build(direct, build_runtime())
    assert(direct_plan.target_position == 12.5, "Test 5 failed")
    print("Test 5 passed: direct target_position is preserved")

    local resolved = seek_plan.build(build_intent(), build_runtime())
    assert(resolved.target_position == 42, "Test 6 failed")
    print("Test 6 passed: target_position resolves from sections")

    assert(resolved.target_position == 42, "Test 7 failed")
    print("Test 7 passed: sections with key matching target work")

    local by_name = build_intent()
    by_name.target_section = "BRIDGE"
    local name_plan = seek_plan.build(by_name, build_runtime())
    assert(name_plan.target_position == 84, "Test 8 failed")
    print("Test 8 passed: sections with name matching target work")

    local by_id = build_intent()
    by_id.target_section = "ENDING"
    local id_plan = seek_plan.build(by_id, build_runtime())
    assert(id_plan.target_position == 126, "Test 9 failed")
    print("Test 9 passed: sections with id matching target work")

    local missing_position_intent = build_intent()
    missing_position_intent.target_section = "MISSING"
    local missing_position = seek_plan.build(missing_position_intent, build_runtime())
    assert(missing_position.reason == "missing_target_position", "Test 10 failed")
    print("Test 10 passed: missing position returns missing_target_position")

    assert(resolved.ok == true, "Test 11 failed")
    print("Test 11 passed: valid plan returns ok=true")

    assert(resolved.locked == true, "Test 12 failed")
    print("Test 12 passed: valid plan returns locked=true")

    assert(resolved.reason == "seek_plan_locked", "Test 13 failed")
    print("Test 13 passed: valid plan returns seek_plan_locked")

    local missing_plan = seek_plan.validate(nil)
    assert(missing_plan.reason == "missing_seek_plan", "Test 14 failed")
    print("Test 14 passed: validate without plan returns missing_seek_plan")

    local invalid_validation = seek_plan.validate(missing_position)
    assert(invalid_validation.reason == "seek_plan_not_ok", "Test 15 failed")
    print("Test 15 passed: validate plan ok=false returns seek_plan_not_ok")

    local locked_validation = seek_plan.validate(resolved)
    assert(locked_validation.executable == false, "Test 16 failed")
    print("Test 16 passed: validate plan ok=true returns executable=false")

    assert(locked_validation.reason == "seek_execution_locked", "Test 17 failed")
    print("Test 17 passed: validate plan ok=true returns seek_execution_locked")

    local formatted = seek_plan.format(resolved)
    assert(string.find(formatted, "Target Position"), "Test 18 failed")
    print("Test 18 passed: format contains Target Position")

    local adapter_plan = transport_adapter.build_seek_plan(build_intent(), build_runtime())
    assert(adapter_plan.reason == "seek_plan_locked", "Test 19 failed")
    print("Test 19 passed: TransportAdapter.build_seek_plan delegates correctly")

    local control_plan = transport_control.build_seek_plan(build_intent(), build_runtime())
    assert(control_plan.reason == "seek_plan_locked", "Test 20 failed")
    print("Test 20 passed: TransportControl.build_seek_plan delegates correctly")

    print("\nSeek plan tests passed successfully!")
end

run_seek_plan_tests()
