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
        next_section = "CHORUS_1",
        sections = {
            { name = "VERSE_1", start = 10 },
            { name = "CHORUS_1", start = 30 }
        }
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
    assert(capabilities.real_transport_supported == true, "Test 1 failed")
    assert(capabilities.real_transport_enabled == true, "Test 2 failed")
    assert(capabilities.can_play_stop == true, "Test 3 failed")
    assert(capabilities.can_seek == true, "Test 4 failed")
    print("Test 1-5 passed: capabilities are MVP ready")

    -- Task 032/033/MVP: Real Execution Tests
    local intent = build_intent()
    local snapshot = build_runtime()
    local gate = build_gate(true)

    -- 1. execute_real sem enable retorna real_cursor_move_not_enabled
    local res1 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = false, enable_real_seek = false })
    assert(res1.reason == "real_cursor_move_not_enabled", "Test 6 failed")
    print("Test 6 passed: real_cursor_move_not_enabled")

    -- 2. enable true mas execution_armed=false retorna execution_not_armed
    local res2 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = false })
    assert(res2.reason == "execution_not_armed", "Test 7 failed")
    print("Test 7 passed: execution_not_armed")

    -- 3. armed true mas manual_confirmed=false retorna manual_confirmation_required
    local res3 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = false })
    assert(res3.reason == "manual_confirmation_required", "Test 8 failed")
    print("Test 8 passed: manual_confirmation_required")

    -- 5. sem _G.reaper retorna reaper_not_available
    _G.reaper = nil
    local res5 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = true })
    assert(res5.reason == "reaper_not_available", "Test 10 failed")
    print("Test 10 passed: reaper_not_available")

    -- 7. caminho válido chama SetEditCurPos(pos, false, false)
    local last_pos = nil
    local last_seekplay = nil
    _G.reaper = {
        SetEditCurPos = function(pos, moveview, seekplay)
            last_pos = pos
            last_seekplay = seekplay
        end
    }
    local res7 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_cursor_move = true, execution_armed = true, manual_confirmed = true, seekplay = false })
    assert(res7.executed == true, "Test 12 failed")
    assert(res7.reason == "cursor_move_executed", "Test 12 failed")
    assert(last_seekplay == false, "Test 12 failed")
    print("Test 12 passed: cursor_move_executed")

    -- 8. caminho válido com seekplay=true chama SetEditCurPos(pos, false, true)
    local res8 = transport_adapter.execute_real(intent, snapshot, gate, { enable_real_seek = true, execution_armed = true, manual_confirmed = true, seekplay = true })
    assert(res8.reason == "seek_executed", "Test 13 failed")
    assert(last_seekplay == true, "Test 13 failed")
    print("Test 13 passed: seek_executed")

    -- Limpar mock para testar reaper não disponível
    _G.reaper = nil

    -- Play Tests
    local play_res = transport_adapter.execute_play({ enable_real_play = true, execution_armed = true })
    assert(play_res.reason == "reaper_not_available", "Test 14 failed")
    
    local play_called = false
    _G.reaper = {
        OnPlayButton = function() play_called = true end
    }
    play_res = transport_adapter.execute_play({ enable_real_play = true, execution_armed = true })
    assert(play_res.executed == true, "Test 15 failed")
    assert(play_called == true, "Test 15 failed")
    print("Test 14-15 passed: execute_play works")

    -- Stop Tests
    local stop_called = false
    _G.reaper.OnStopButton = function() stop_called = true end
    local stop_res = transport_adapter.execute_stop({ enable_real_stop = true })
    assert(stop_res.executed == true, "Test 16 failed")
    assert(stop_called == true, "Test 16 failed")
    print("Test 16 passed: execute_stop works")

    -- Status Tests
    _G.reaper.GetPlayState = function() return 1 end
    _G.reaper.GetPlayPosition = function() return 10.5 end
    local status = transport_adapter.get_playback_status({})
    assert(status.is_playing == true, "Test 17 failed")
    assert(status.play_position == 10.5, "Test 17 failed")
    print("Test 17 passed: get_playback_status works")

    -- Limpar mock
    _G.reaper = nil

    print("\nTransport adapter tests passed successfully!")
end

run_transport_adapter_tests()
