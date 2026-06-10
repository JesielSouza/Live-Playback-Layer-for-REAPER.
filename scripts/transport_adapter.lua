--[[
    transport_adapter.lua
    Future real transport adapter interface. The implementation is locked and
    returns disabled results only.
--]]

local TransportAdapter = {}
local SeekPlan = require("scripts.seek_plan")

function TransportAdapter.get_capabilities(options)
    return {
        real_transport_supported = false,
        real_transport_enabled = false,
        can_play_stop = false,
        can_seek = false,
        can_mutate_project = false,
        backend = "reaper",
        reason = "real_transport_locked"
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

    return validation_result("real_transport_locked")
end

function TransportAdapter.build_seek_plan(intent, runtime_snapshot, options)
    return SeekPlan.build(intent, runtime_snapshot, options)
end

function TransportAdapter.execute_real(intent, runtime_snapshot, gate_result, options)
    options = options or {}
    local action = type(intent) == "table" and intent.action or nil
    local target_section = type(intent) == "table" and intent.target_section or nil

    if not options.enable_real_cursor_move then
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
    _G.reaper.SetEditCurPos(target_position, false, false)

    return {
        ok = true,
        executed = true,
        real_transport_attempted = true,
        action = action,
        target_section = target_section,
        target_position = target_position,
        reason = "cursor_move_executed",
        warnings = {},
        errors = {}
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
