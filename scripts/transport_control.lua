--[[
    transport_control.lua
    Transport intent builder and execution dispatcher.
--]]

local TransportControl = {}
local TransportAdapter = require("scripts.transport_adapter")
local TransportGate = require("scripts.transport_gate")
local TransportSimulator = require("scripts.transport_simulator")
local SongMap = require("scripts.song_map")
local LiveQueue = require("scripts.live_queue")
local LoopMode = require("scripts.loop_mode")

local VALID_ACTIONS = {
    go_next = true,
    go_previous = true,
    loop_current = true,
    stop_at_end = true,
    jump_to_section = true,
    live_queue_jump = true,
    infinite_loop = true
}

local function default_options(options)
    options = options or {}
    return {
        dry_run = options.dry_run ~= false
    }
end

local function new_intent(action, runtime_snapshot, options)
    return {
        ok = true,
        dry_run = options.dry_run,
        action = action,
        current_section = runtime_snapshot and runtime_snapshot.current_section or nil,
        target_section = nil,
        target_position = nil,
        decision = runtime_snapshot and runtime_snapshot.decision or nil,
        executable = false,
        reason = "dry_run_intent_only",
        warnings = {},
        errors = {}
    }
end

function TransportControl.build_intent(action, runtime_snapshot, options)
    local resolved_options = default_options(options)

    if type(runtime_snapshot) ~= "table" then
        return {
            ok = false,
            dry_run = resolved_options.dry_run,
            action = action,
            current_section = nil,
            target_section = nil,
            target_position = nil,
            decision = nil,
            executable = false,
            reason = "missing_runtime_snapshot",
            warnings = {},
            errors = { "missing_runtime_snapshot" }
        }
    end

    local intent = new_intent(action, runtime_snapshot, resolved_options)

    if not VALID_ACTIONS[action] then
        intent.ok = false
        intent.reason = "invalid_action"
        table.insert(intent.errors, "invalid_action")
        return intent
    end

    if action == "go_next" then
        intent.target_section = runtime_snapshot.next_section
    elseif action == "go_previous" then
        intent.target_section = runtime_snapshot.previous_section
    elseif action == "loop_current" then
        intent.target_section = runtime_snapshot.current_section
    elseif action == "stop_at_end" then
        intent.target_section = nil
        intent.decision = "STOP_AT_END_INTENT"
    end

    if action ~= "stop_at_end" and action ~= "jump_to_section" and action ~= "live_queue_jump" and action ~= "infinite_loop" and not intent.target_section then
        intent.ok = false
        intent.reason = "missing_target_section"
        table.insert(intent.errors, "missing_target_section")
    end

    if not intent.dry_run then
        -- In MVP, intents are built as dry-run first, then confirmed/executed
        intent.dry_run = true
    end

    return intent
end

function TransportControl.build_next_intent(runtime_snapshot)
    return TransportControl.build_intent("go_next", runtime_snapshot, { dry_run = true })
end

function TransportControl.build_loop_current_intent(runtime_snapshot)
    local song_map = SongMap.build(runtime_snapshot)
    return SongMap.build_loop_current_intent(song_map)
end

function TransportControl.build_manual_section_intent(runtime_snapshot, section_id_or_name)
    local song_map = SongMap.build(runtime_snapshot)
    return SongMap.build_intent_for_section(song_map, section_id_or_name)
end

function TransportControl.build_queue_intent(runtime_snapshot, queue_item)
    local intent = TransportControl.build_intent("live_queue_jump", runtime_snapshot, { dry_run = true })
    if not queue_item then
        intent.ok = false
        intent.reason = "missing_queue_item"
        return intent
    end
    intent.target_section = queue_item.section_id
    intent.target_position = queue_item.target_position
    intent.decision = "LIVE_QUEUE_TARGET"
    intent.reason = "live_queue_target"
    return intent
end

function TransportControl.build_loop_mode_intent(runtime_snapshot, loop_state)
    local intent = TransportControl.build_intent("infinite_loop", runtime_snapshot, { dry_run = true })
    if not loop_state or not loop_state.enabled then
        intent.ok = false
        intent.reason = "loop_not_enabled"
        return intent
    end
    intent.target_section = loop_state.section_id
    intent.target_position = loop_state.target_position
    intent.decision = "INFINITE_LOOP_TARGET"
    intent.reason = "infinite_loop_target"
    return intent
end

function TransportControl.resolve_active_intent(runtime_snapshot, ui_session)
    if not ui_session then return TransportControl.build_next_intent(runtime_snapshot) end
    
    local state = ui_session
    local song_map = SongMap.build(runtime_snapshot)

    -- 1. Infinite Loop
    if state.loop_mode and state.loop_mode.enabled then
        local intent = TransportControl.build_loop_mode_intent(runtime_snapshot, state.loop_mode)
        if intent.ok then
            if not intent.target_position then
                local s = SongMap.find_section(song_map, intent.target_section)
                intent.target_position = s and s.start
            end
            if intent.target_position then return intent, "infinite_loop" end
        end
    end

    -- 2. Live Queue
    if state.live_queue and not LiveQueue.is_empty(state.live_queue) then
        local item = LiveQueue.peek(state.live_queue)
        local intent = TransportControl.build_queue_intent(runtime_snapshot, item)
        if intent.ok then
            if not intent.target_position then
                local s = SongMap.find_section(song_map, intent.target_section)
                intent.target_position = s and s.start
            end
            if intent.target_position then return intent, "live_queue" end
        end
    end

    -- 3. Selected Section
    if state.selected_section then
        local intent = TransportControl.build_manual_section_intent(runtime_snapshot, state.selected_section)
        if intent.ok then return intent, "selected_section" end
    end

    -- 4. Next Natural
    return TransportControl.build_next_intent(runtime_snapshot), "next_section"
end

function TransportControl.build_song_map(runtime_snapshot)
    return SongMap.build(runtime_snapshot)
end

function TransportControl.format_intent(intent)
    intent = intent or {}

    return table.concat({
        "Action: " .. tostring(intent.action or "nil"),
        "Dry Run: " .. tostring(intent.dry_run == true),
        "Current Section: " .. tostring(intent.current_section or "nil"),
        "Target Section: " .. tostring(intent.target_section or "nil"),
        "Decision: " .. tostring(intent.decision or "nil"),
        "Executable: " .. tostring(intent.executable == true),
        "Reason: " .. tostring(intent.reason or "nil")
    }, "\n")
end

function TransportControl.can_execute(intent, runtime_snapshot, options)
    local gate_result = TransportGate.evaluate(intent, runtime_snapshot, options)
    if runtime_snapshot == nil then
        return false, "transport_execution_not_enabled", gate_result
    end

    return false, gate_result.reason, gate_result
end

function TransportControl.execute_intent(intent, options)
    return {
        ok = false,
        executed = false,
        dry_run = true,
        reason = "transport_execution_not_enabled"
    }
end

function TransportControl.simulate_intent(intent, runtime_snapshot, options)
    return TransportSimulator.simulate(intent, runtime_snapshot, options)
end

function TransportControl.execute_real_intent(intent, runtime_snapshot, gate_result, options)
    return TransportAdapter.execute_real(intent, runtime_snapshot, gate_result, options)
end

function TransportControl.execute_play(options)
    return TransportAdapter.execute_play(options)
end

function TransportControl.execute_stop(options)
    return TransportAdapter.execute_stop(options)
end

function TransportControl.get_playback_status(options)
    return TransportAdapter.get_playback_status(options)
end

function TransportControl.build_seek_plan(intent, runtime_snapshot, options)
    return TransportAdapter.build_seek_plan(intent, runtime_snapshot, options)
end

return TransportControl
