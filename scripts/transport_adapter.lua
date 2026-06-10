--[[
    transport_adapter.lua
    Real transport adapter for REAPER.
--]]

local TransportAdapter = {}
local SeekPlan = require("scripts.seek_plan")

function TransportAdapter.get_capabilities(options)
    return {
        real_transport_supported = true,
        real_transport_enabled = true,
        can_play_stop = true,
        can_seek = true,
        can_mutate_project = false,
        backend = "reaper",
        reason = "mvp_ready"
    }
end

local function validation_result(reason)
    return {
        ok = false,
        executable = false,
        reason = reason,
        warnings = {},
        errors = { reason }
    }
end

function TransportAdapter.validate_real_execution(intent, runtime_snapshot, gate_result, options)
    if intent == nil then
        return validation_result("missing_intent")
    end

    if runtime_snapshot == nil then
        return validation_result("missing_runtime_snapshot")
    end

    if gate_result == nil then
        return validation_result("missing_gate_result")
    end

    if intent.ok ~= true then
        return validation_result("intent_not_ok")
    end

    if gate_result.executable ~= true then
        return validation_result("gate_not_executable")
    end

    return {
        ok = true,
        executable = true,
        reason = "gate_passed",
        warnings = {},
        errors = {}
    }
end

function TransportAdapter.build_seek_plan(intent, runtime_snapshot, options)
    return SeekPlan.build(intent, runtime_snapshot, options)
end

function TransportAdapter.execute_real(intent, runtime_snapshot, gate_result, options)
    options = options or {}
    local action = type(intent) == "table" and intent.action or nil
    local target_section = type(intent) == "table" and intent.target_section or nil

    if not options.enable_real_cursor_move and not options.enable_real_seek then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "real_cursor_move_not_enabled",
            warnings = {},
            errors = {}
        }
    end

    if not options.execution_armed then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "execution_not_armed",
            warnings = {},
            errors = {}
        }
    end

    if not options.manual_confirmed then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "manual_confirmation_required",
            warnings = {},
            errors = {}
        }
    end

    local seek_plan = TransportAdapter.build_seek_plan(intent, runtime_snapshot, options)
    if not seek_plan or seek_plan.ok ~= true then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "seek_plan_not_ok",
            warnings = {},
            errors = {}
        }
    end

    local target_position = seek_plan.target_position
    if type(target_position) ~= "number" then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "missing_target_position",
            warnings = {},
            errors = {}
        }
    end

    if not (_G.reaper) then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "reaper_not_available",
            warnings = {},
            errors = {}
        }
    end

    if type(_G.reaper.SetEditCurPos) ~= "function" then
        return {
            ok = false,
            executed = false,
            real_transport_attempted = false,
            action = action,
            target_section = target_section,
            reason = "set_edit_cur_pos_not_available",
            warnings = {},
            errors = {}
        }
    end

    -- Real Action
    local seekplay = options.seekplay == true
    _G.reaper.SetEditCurPos(target_position, false, seekplay)

    return {
        ok = true,
        executed = true,
        real_transport_attempted = true,
        action = action,
        target_section = target_section,
        target_position = target_position,
        reason = seekplay and "seek_executed" or "cursor_move_executed",
        warnings = {},
        errors = {}
    }
end

function TransportAdapter.execute_play(options)
    options = options or {}

    if not options.enable_real_play then
        return { ok = false, executed = false, reason = "real_play_not_enabled" }
    end

    if not options.execution_armed then
        return { ok = false, executed = false, reason = "execution_not_armed" }
    end

    if not (_G.reaper) then
        return { ok = false, executed = false, reason = "reaper_not_available" }
    end

    if type(_G.reaper.OnPlayButton) ~= "function" then
        return { ok = false, executed = false, reason = "play_not_available" }
    end

    _G.reaper.OnPlayButton()

    return {
        ok = true,
        executed = true,
        action = "play",
        reason = "play_executed"
    }
end

function TransportAdapter.execute_stop(options)
    options = options or {}

    if not options.enable_real_stop then
        return { ok = false, executed = false, reason = "real_stop_not_enabled" }
    end

    if not (_G.reaper) then
        return { ok = false, executed = false, reason = "reaper_not_available" }
    end

    if type(_G.reaper.OnStopButton) ~= "function" then
        return { ok = false, executed = false, reason = "stop_not_available" }
    end

    _G.reaper.OnStopButton()

    return {
        ok = true,
        executed = true,
        action = "stop",
        reason = "stop_executed"
    }
end

function TransportAdapter.get_playback_status(options)
    local reaper_available = (_G.reaper ~= nil)
    local play_state = nil
    local play_position = nil

    if reaper_available then
        if type(_G.reaper.GetPlayState) == "function" then
            play_state = _G.reaper.GetPlayState()
        end
        if type(_G.reaper.GetPlayPosition) == "function" then
            play_position = _G.reaper.GetPlayPosition()
        end
    end

    return {
        reaper_available = reaper_available,
        play_state = play_state,
        is_playing = play_state == 1 or play_state == 5, -- 1=playing, 5=recording
        is_paused = play_state == 2,
        is_recording = play_state == 4 or play_state == 5,
        play_position = play_position
    }
end

function TransportAdapter.format_execution_result(result)
    result = result or {}

    return table.concat({
        "Executed: " .. tostring(result.executed == true),
        "Real Transport Attempted: " .. tostring(result.real_transport_attempted == true),
        "Reason: " .. tostring(result.reason or "nil"),
        "Action: " .. tostring(result.action or "nil"),
        "Target Section: " .. tostring(result.target_section or "nil")
    }, "\n")
end

return TransportAdapter
