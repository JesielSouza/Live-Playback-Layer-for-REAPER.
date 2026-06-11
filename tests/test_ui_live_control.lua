local ui_live_control = require("scripts.ui_live_control")
local live_queue = require("scripts.live_queue")
local loop_mode = require("scripts.loop_mode")

local function run_ui_live_control_tests()
    print("Running UI live control tests...\n")

    local q = live_queue.create()
    local l = loop_mode.create()
    
    -- 1-2 empty build
    local model = ui_live_control.build(q, l)
    assert(model.ok == true, "Test 1 failed")
    assert(string.find(model.queue_lines[2], "empty"), "Test 2 failed")
    print("Test 1-2 passed: build empty works")

    -- 3-4 item build
    live_queue.add_section(q, "S1")
    local model2 = ui_live_control.build(q, l)
    assert(string.find(model2.queue_lines[2], "S1"), "Test 4 failed")
    print("Test 3-4 passed: build with queue item works")

    -- 5-6 loop lines
    assert(string.find(model2.loop_lines[1], "OFF"), "Test 5 failed")
    loop_mode.enable(l, "S2")
    local model3 = ui_live_control.build(q, l)
    assert(string.find(model3.loop_lines[1], "ON S2"), "Test 6 failed")
    print("Test 5-6 passed: loop lines work")

    -- 7 summary
    assert(model3.summary_lines[1] == "Live Control Summary", "Test 7 failed")
    print("Test 7 passed: summary lines work")

    print("\nUI live control tests passed successfully!")
end

run_ui_live_control_tests()
