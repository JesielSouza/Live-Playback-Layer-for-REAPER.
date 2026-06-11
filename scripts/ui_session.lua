--[[
    ui_session.lua
    In-memory UI session state. This module does not call REAPER APIs and does
    not trigger transport actions.
--]]

local UISession = {}
local LiveQueue = require("scripts.live_queue")
local LoopMode = require("scripts.loop_mode")

local function apply_defaults(session)
    session.transport_confirmed = false
    session.confirmed_action = nil
    session.confirmed_target_section = nil
    session.confirmation_count = 0
    session.execution_armed = false
    session.last_execution_result = nil
    session.last_operator_action = nil
    session.last_setlist_result = nil
    session.last_project_load_result = nil
    session.last_cue_result = nil
    session.last_midi_dry_run_result = nil
    session.debug_visible = false
    
    -- v0.2 Selection state
    session.selected_section = nil
    session.selected_target_position = nil
    session.selected_action = nil
    
    -- v0.6 Live Control state
    session.live_queue = LiveQueue.create()
    session.loop_mode = LoopMode.create()
    session.last_live_control_result = nil

    -- v0.7 Cues state
    session.cues_dirty = false
    
    return session
end

function UISession.create()
    return apply_defaults({})
end

function UISession.reset(session)
    return apply_defaults(session or {})
end

function UISession.confirm_transport(session, intent)
    session = session or UISession.create()

    if type(intent) ~= "table" or intent.ok ~= true then
        return session
    end

    session.transport_confirmed = true
    session.confirmed_action = intent.action
    session.confirmed_target_section = intent.target_section
    session.confirmation_count = (session.confirmation_count or 0) + 1

    return session
end

function UISession.clear_transport_confirmation(session)
    session = session or UISession.create()
    session.transport_confirmed = false
    session.confirmed_action = nil
    session.confirmed_target_section = nil
    session.confirmation_count = session.confirmation_count or 0
    session.execution_armed = false
    -- Manual clear also clears selection
    session.selected_section = nil
    session.selected_target_position = nil
    session.selected_action = nil
    return session
end

function UISession.is_transport_confirmed(session, intent)
    if type(session) ~= "table" or session.transport_confirmed ~= true then
        return false
    end

    if type(intent) ~= "table" then
        return false
    end

    -- Confirmação só vale para mesma action e target_section
    return intent.action == session.confirmed_action
        and intent.target_section == session.confirmed_target_section
end

function UISession.arm_execution(session)
    session = session or UISession.create()
    session.execution_armed = true
    return session
end

function UISession.disarm_execution(session)
    session = session or UISession.create()
    session.execution_armed = false
    return session
end

function UISession.is_execution_armed(session)
    if type(session) ~= "table" then
        return false
    end
    return session.execution_armed == true
end

function UISession.toggle_debug(session)
    session = session or UISession.create()
    session.debug_visible = not (session.debug_visible == true)
    return session
end

function UISession.set_debug_visible(session, value)
    session = session or UISession.create()
    session.debug_visible = value == true
    return session
end

function UISession.is_debug_visible(session)
    if type(session) ~= "table" then
        return false
    end
    return session.debug_visible == true
end

function UISession.set_last_execution_result(session, result)
    session = session or UISession.create()
    session.last_execution_result = result
    return session
end

function UISession.get_last_execution_result(session)
    if type(session) ~= "table" then
        return nil
    end
    return session.last_execution_result
end

function UISession.set_last_operator_action(session, action)
    session = session or UISession.create()
    session.last_operator_action = action
    return session
end

function UISession.set_last_setlist_result(session, result)
    session = session or UISession.create()
    session.last_setlist_result = result
    return session
end

function UISession.get_last_setlist_result(session)
    if type(session) ~= "table" then return nil end
    return session.last_setlist_result
end

function UISession.set_last_project_load_result(session, result)
    session = session or UISession.create()
    session.last_project_load_result = result
    return session
end

function UISession.get_last_project_load_result(session)
    if type(session) ~= "table" then return nil end
    return session.last_project_load_result
end

function UISession.set_last_cue_result(session, result)
    session = session or UISession.create()
    session.last_cue_result = result
    return session
end

function UISession.get_last_cue_result(session)
    if type(session) ~= "table" then return nil end
    return session.last_cue_result
end

function UISession.set_last_midi_dry_run_result(session, result)
    session = session or UISession.create()
    session.last_midi_dry_run_result = result
    return session
end

function UISession.get_last_midi_dry_run_result(session)
    if type(session) ~= "table" then return nil end
    return session.last_midi_dry_run_result
end

-- v0.7 Cues dirty management
function UISession.set_cues_dirty(session, value)
    session = session or UISession.create()
    session.cues_dirty = (value == true)
    return session
end

function UISession.are_cues_dirty(session)
    if type(session) ~= "table" then return false end
    return session.cues_dirty == true
end

function UISession.mark_cues_dirty(session)
    return UISession.set_cues_dirty(session, true)
end

function UISession.clear_cues_dirty(session)
    return UISession.set_cues_dirty(session, false)
end

-- v0.2 Selection functions
function UISession.select_section(session, section_id, target_position)
    session = session or UISession.create()
    
    -- Se mudar a seleção, invalida a confirmação anterior
    if session.selected_section ~= section_id then
        session.transport_confirmed = false
        session.confirmed_action = nil
        session.confirmed_target_section = nil
    end
    
    session.selected_section = section_id
    session.selected_target_position = target_position
    session.selected_action = "jump_to_section"
    return session
end

function UISession.clear_selected_section(session)
    session = session or UISession.create()
    session.selected_section = nil
    session.selected_target_position = nil
    session.selected_action = nil
    return session
end

function UISession.get_selected_section(session)
    if type(session) ~= "table" then return nil end
    return session.selected_section
end

function UISession.is_section_selected(session, section_id)
    if type(session) ~= "table" then return false end
    return session.selected_section == section_id
end

function UISession.confirm_selected_section(session, intent)
    return UISession.confirm_transport(session, intent)
end

-- v0.6 Live Control functions
function UISession.get_live_queue(session)
    if type(session) ~= "table" then return LiveQueue.create() end
    return session.live_queue
end

function UISession.set_live_queue(session, queue)
    session = session or UISession.create()
    session.live_queue = queue
    -- Invalida confirmação se a fila mudar
    session.transport_confirmed = false
    return session
end

function UISession.clear_live_queue(session)
    session = session or UISession.create()
    LiveQueue.clear(session.live_queue)
    session.transport_confirmed = false
    return session
end

function UISession.add_to_live_queue(session, section_id, metadata)
    session = session or UISession.create()
    LiveQueue.add_section(session.live_queue, section_id, metadata)
    session.transport_confirmed = false
    return session
end

function UISession.remove_from_live_queue(session, index)
    session = session or UISession.create()
    LiveQueue.remove_at(session.live_queue, index)
    session.transport_confirmed = false
    return session
end

function UISession.move_live_queue_item_up(session, index)
    session = session or UISession.create()
    LiveQueue.move_up(session.live_queue, index)
    session.transport_confirmed = false
    return session
end

function UISession.move_live_queue_item_down(session, index)
    session = session or UISession.create()
    LiveQueue.move_down(session.live_queue, index)
    session.transport_confirmed = false
    return session
end

function UISession.get_loop_mode(session)
    if type(session) ~= "table" then return LoopMode.create() end
    return session.loop_mode
end

function UISession.enable_infinite_loop(session, section_id, metadata)
    session = session or UISession.create()
    LoopMode.enable(session.loop_mode, section_id, metadata)
    session.transport_confirmed = false
    return session
end

function UISession.disable_infinite_loop(session)
    session = session or UISession.create()
    LoopMode.disable(session.loop_mode)
    session.transport_confirmed = false
    return session
end

function UISession.toggle_infinite_loop(session, section_id, metadata)
    session = session or UISession.create()
    LoopMode.toggle(session.loop_mode, section_id, metadata)
    session.transport_confirmed = false
    return session
end

function UISession.set_last_live_control_result(session, result)
    session = session or UISession.create()
    session.last_live_control_result = result
    return session
end

function UISession.get_last_live_control_result(session)
    if type(session) ~= "table" then return nil end
    return session.last_live_control_result
end

function UISession.get_state(session)
    session = session or {}

    return {
        transport_confirmed = session.transport_confirmed == true,
        confirmed_action = session.confirmed_action,
        confirmed_target_section = session.confirmed_target_section,
        confirmation_count = session.confirmation_count or 0,
        execution_armed = session.execution_armed == true,
        debug_visible = session.debug_visible == true,
        last_execution_result = session.last_execution_result,
        last_operator_action = session.last_operator_action,
        last_setlist_result = session.last_setlist_result,
        last_project_load_result = session.last_project_load_result,
        last_cue_result = session.last_cue_result,
        last_midi_dry_run_result = session.last_midi_dry_run_result,
        cues_dirty = session.cues_dirty == true,
        selected_section = session.selected_section,
        selected_target_position = session.selected_target_position,
        selected_action = session.selected_action,
        live_queue = session.live_queue,
        loop_mode = session.loop_mode,
        last_live_control_result = session.last_live_control_result
    }
end

return UISession
