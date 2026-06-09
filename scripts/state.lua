--[[
    state.lua
    Responsabilidade: Manter o estado da aplicação (State Machine) e orquestrar as camadas.
    Versão: Pura, testável, apenas memória sem logging em arquivo (MVP 1.0).
--]]

local logger = require("scripts.logger")

local state = {}

-- Constant States
state.STATES = {
    IDLE = "IDLE",
    SONG_LOADED = "SONG_LOADED",
    PLAYING = "PLAYING",
    SECTION_LOOPING = "SECTION_LOOPING",
    JUMP_PENDING = "JUMP_PENDING",
    FADING_OUT = "FADING_OUT",
    STOPPED = "STOPPED",
    PANIC = "PANIC",
    ERROR = "ERROR"
}

-- Constant Events
state.EVENTS = {
    LOAD_SONG_SUCCESS = "LOAD_SONG_SUCCESS",
    PLAY_REQUESTED = "PLAY_REQUESTED",
    STOP_REQUESTED = "STOP_REQUESTED",
    LOOP_ENABLED = "LOOP_ENABLED",
    LOOP_DISABLED = "LOOP_DISABLED",
    JUMP_REQUESTED = "JUMP_REQUESTED",
    JUMP_COMPLETED = "JUMP_COMPLETED",
    FADE_REQUESTED = "FADE_REQUESTED",
    FADE_COMPLETED = "FADE_COMPLETED",
    PANIC_REQUESTED = "PANIC_REQUESTED",
    PANIC_CLEARED = "PANIC_CLEARED",
    ERROR_RAISED = "ERROR_RAISED",
    ERROR_CLEARED = "ERROR_CLEARED",
    RESET_REQUESTED = "RESET_REQUESTED"
}

-- Defined Allowed Transitions mapping
-- Structure: allowed_transitions[FROM_STATE][TO_STATE] = true
local allowed_transitions = {
    [state.STATES.IDLE] = {
        [state.STATES.SONG_LOADED] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.SONG_LOADED] = {
        [state.STATES.PLAYING] = true,
        [state.STATES.STOPPED] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.PLAYING] = {
        [state.STATES.JUMP_PENDING] = true,
        [state.STATES.SECTION_LOOPING] = true,
        [state.STATES.FADING_OUT] = true,
        [state.STATES.STOPPED] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.SECTION_LOOPING] = {
        [state.STATES.PLAYING] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.JUMP_PENDING] = {
        [state.STATES.PLAYING] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.FADING_OUT] = {
        [state.STATES.STOPPED] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.STOPPED] = {
        [state.STATES.PLAYING] = true,
        [state.STATES.SONG_LOADED] = true,
        [state.STATES.PANIC] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.PANIC] = {
        [state.STATES.STOPPED] = true,
        [state.STATES.ERROR] = true
    },
    [state.STATES.ERROR] = {
        [state.STATES.SONG_LOADED] = true,
        [state.STATES.IDLE] = true,
        [state.STATES.PANIC] = true
    }
}

-- Singleton Instance
local instance = nil

function state.new(initial_context)
    local o = {
        current_state = state.STATES.IDLE,
        song = nil,
        sections = {},
        current_section = nil,
        error = nil,
        history = {}
    }

    if initial_context then
        o.song = initial_context.song
        o.sections = initial_context.sections or {}
        o.current_section = initial_context.current_section
    end

    return o
end

-- Initialize or Reset the singleton
function state.init()
    instance = state.new()
end

function state.reset()
    instance = state.new()
    -- Create an initial record of the reset if needed, but per requirements we just go to IDLE.
end

function state.get_current()
    if not instance then state.init() end
    return instance.current_state
end

function state.get_context()
    if not instance then state.init() end
    return {
        song = instance.song,
        sections = instance.sections,
        current_section = instance.current_section,
        error = instance.error
    }
end

function state.get_history()
    if not instance then state.init() end
    return instance.history
end

function state.can_transition(to_state)
    if not instance then state.init() end
    local from_state = instance.current_state

    -- Special ANY cases
    if to_state == state.STATES.PANIC or to_state == state.STATES.ERROR then
        return true
    end

    if allowed_transitions[from_state] and allowed_transitions[from_state][to_state] then
        return true
    end

    return false
end

local function safe_log(level, event_name, payload)
    pcall(function()
        logger.log(level, event_name, payload)
    end)
end

function state.transition(to_state, event, payload)
    if not instance then state.init() end
    local from_state = instance.current_state

    if state.can_transition(to_state) then
        instance.current_state = to_state
        table.insert(instance.history, {
            from = from_state,
            to = to_state,
            event = event,
            payload = payload or {},
            ok = true
        })
        safe_log(logger.LEVELS.INFO, "STATE_TRANSITION", {
            from = from_state,
            to = to_state,
            event = event,
            ok = true
        })
        return true
    else
        table.insert(instance.history, {
            from = from_state,
            to = to_state,
            event = event,
            payload = payload or {},
            ok = false,
            reason = "transition_not_allowed"
        })
        safe_log(logger.LEVELS.WARN, "STATE_TRANSITION_REJECTED", {
            from = from_state,
            to = to_state,
            event = event,
            ok = false,
            reason = "transition_not_allowed"
        })
        return false
    end
end

function state.dispatch(event, payload)
    if not instance then state.init() end
    local current = instance.current_state

    if event == state.EVENTS.LOAD_SONG_SUCCESS then
        return state.transition(state.STATES.SONG_LOADED, event, payload)

    elseif event == state.EVENTS.PLAY_REQUESTED then
        -- Allowed only from SONG_LOADED, STOPPED, or valid transitions
        return state.transition(state.STATES.PLAYING, event, payload)

    elseif event == state.EVENTS.STOP_REQUESTED then
        return state.transition(state.STATES.STOPPED, event, payload)

    elseif event == state.EVENTS.LOOP_ENABLED then
        return state.transition(state.STATES.SECTION_LOOPING, event, payload)

    elseif event == state.EVENTS.LOOP_DISABLED then
        return state.transition(state.STATES.PLAYING, event, payload)

    elseif event == state.EVENTS.JUMP_REQUESTED then
        return state.transition(state.STATES.JUMP_PENDING, event, payload)

    elseif event == state.EVENTS.JUMP_COMPLETED then
        return state.transition(state.STATES.PLAYING, event, payload)

    elseif event == state.EVENTS.FADE_REQUESTED then
        return state.transition(state.STATES.FADING_OUT, event, payload)

    elseif event == state.EVENTS.FADE_COMPLETED then
        return state.transition(state.STATES.STOPPED, event, payload)

    elseif event == state.EVENTS.PANIC_REQUESTED then
        return state.transition(state.STATES.PANIC, event, payload)

    elseif event == state.EVENTS.PANIC_CLEARED then
        return state.transition(state.STATES.STOPPED, event, payload)

    elseif event == state.EVENTS.ERROR_RAISED then
        if payload and payload.message then
            instance.error = payload.message
        end
        return state.transition(state.STATES.ERROR, event, payload)

    elseif event == state.EVENTS.ERROR_CLEARED then
        instance.error = nil
        if instance.song then
            return state.transition(state.STATES.SONG_LOADED, event, payload)
        else
            return state.transition(state.STATES.IDLE, event, payload)
        end

    elseif event == state.EVENTS.RESET_REQUESTED then
        state.reset()
        return true
    end

    return false
end

function state.set_song(song)
    if not instance then state.init() end
    instance.song = song
end

function state.set_sections(sections)
    if not instance then state.init() end
    instance.sections = sections or {}
end

function state.set_current_section(section)
    if not instance then state.init() end
    instance.current_section = section
end

function state.set_error(message, payload)
    if not instance then state.init() end
    instance.error = message
    state.dispatch(state.EVENTS.ERROR_RAISED, payload)
end

function state.clear_error()
    if not instance then state.init() end
    state.dispatch(state.EVENTS.ERROR_CLEARED, {})
end

return state
