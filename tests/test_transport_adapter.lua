local transport_adapter = require("scripts.transport_adapter")
local transport_control = require("scripts.transport_control")

local function build_intent()
    return {
        ok = true,
        action = "go_next",
        target_section = "CHORUS_1"
    }
end

local function build_runtime()
    return {
        ok = true,
        current_section = "VERSE_1",
        next_section = "CHORUS_1"
    }
end

local function build_gate(executable)
    return {
        executable = executable == true
    }
end

local function run_transport_adapter_tests()
    print("Running transport adapter tests...\n")

    local capabilities = transport_adapter.get_capabilities({ real_transport_enabled = true })
    assert(capabilities.real_transport_supported == false, "Test 1 failed")
    print("Test 1 passed: capabilities real_transport_supported=false")

    assert(capabilities.real_transport_enabled == false, "Test 2 failed")
    print("Test 2 passed: capabilities real_transport_enabled=false")

    assert(capabilities.can_play_stop == false, "Test 3 failed")
    print("Test 3 passed: capabilities can_play_stop=false")

    assert(capabilities.can_seek == false, "Test 4 failed")
    print("Test 4 passed: capabilities can_seek=false")

    assert(capabilities.can_mutate_project == false, "Test 5 failed")
    print("Test 5 passed: capabilities can_mutate_project=false")

    -- Task 032: Real Execution Tests
    local intent = build_intent()
    local snapshot = build_runtime()
    local gate = build_gate(true)

    -- 1. execute_real sem enable_real_cursor_move retorna real_cursor_move_not_enabled
    local res1 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = false })
    assert(res1.reason == "real_cursor_move_not_enabled", "Test 6 failed")
    assert(res1.executed == false, "Test 6 failed")
    print("Test 6 passed: real_cursor_move_not_enabled")

    -- 2. enable true mas execution_armed=false retorna execution_not_armed
    local res2 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = false })
    assert(res2.reason == "execution_not_armed", "Test 7 failed")
    print("Test 7 passed: execution_not_armed")

    -- 3. armed true mas manual_confirmed=false retorna manual_confirmation_required
    local res3 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = false })
    assert(res3.reason == "manual_confirmation_required", "Test 8 failed")
    print("Test 8 passed: manual_confirmation_required")

    -- 4. seek_plan inválido retorna seek_plan_not_ok ou missing_target_position (intent sem ok)
    local bad_intent = build_intent()
    bad_intent.ok = false
    local res4 = transport_adapter.execute_real(bad_intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = true })
    assert(res4.reason == "seek_plan_not_ok", "Test 9 failed")
    print("Test 9 passed: seek_plan_not_ok")

    -- 5. sem _G.reaper retorna reaper_not_available
    _G.reaper = nil
    local res5 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = true })
    assert(res5.reason == "reaper_not_available", "Test 10 failed")
    print("Test 10 passed: reaper_not_available")

    -- 6. sem SetEditCurPos retorna set_edit_cur_pos_not_available
    _G.reaper = {}
    local res6 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = true })
    assert(res6.reason == "set_edit_cur_pos_not_available", "Test 11 failed")
    print("Test 11 passed: set_edit_cur_pos_not_available")

    -- 7. caminho válido chama SetEditCurPos com target_position
    local last_pos = nil
    local call_count = 0
    _G.reaper = {
        SetEditCurPos = function(pos, moveview, seekplay)
            last_pos = pos
            call_count = call_count + 1
        end
    }
    local res7 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = true })
    assert(res7.ok == true, "Test 12 failed")
    assert(res7.executed == true, "Test 12 failed")
    assert(res7.reason == "cursor_move_executed", "Test 12 failed")
    assert(call_count == 1, "Test 12 failed")
    assert(type(last_pos) == "number", "Test 12 failed")
    print("Test 12 passed: cursor_move_executed")

    -- 8. caminho válido retorna executed=true e preserva info
    assert(res7.real_transport_attempted == true, "Test 13 failed")
    assert(res7.action == "go_next", "Test 13 failed")
    assert(res7.target_section == "CHORUS_1", "Test 13 failed")
    assert(res7.target_position == last_pos, "Test 13 failed")
    print("Test 13 passed: execution info preserved")

    -- Limpar mock
    _G.reaper = nil

    print("\nTransport adapter tests passed successfully!")
end

run_transport_adapter_tests()
