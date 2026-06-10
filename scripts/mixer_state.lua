--[[
    mixer_state.lua
    Manages UI state for the mixer (visibility, selection, collapsed categories).
--]]

local MixerState = {}

function MixerState.create()
    return {
        visible = true,
        selected_track_id = nil,
        last_mixer_result = nil,
        collapsed_categories = {}
    }
end

function MixerState.toggle_visible(state)
    state = state or MixerState.create()
    state.visible = not (state.visible == true)
    return state
end

function MixerState.set_visible(state, visible)
    state = state or MixerState.create()
    state.visible = (visible == true)
    return state
end

function MixerState.is_visible(state)
    if type(state) ~= "table" then return true end
    return state.visible == true
end

function MixerState.set_selected_track(state, track_id)
    state = state or MixerState.create()
    state.selected_track_id = track_id
    return state
end

function MixerState.get_selected_track(state)
    if type(state) ~= "table" then return nil end
    return state.selected_track_id
end

function MixerState.set_last_mixer_result(state, result)
    state = state or MixerState.create()
    state.last_mixer_result = result
    return state
end

function MixerState.get_last_mixer_result(state)
    if type(state) ~= "table" then return nil end
    return state.last_mixer_result
end

function MixerState.set_category_collapsed(state, category, collapsed)
    state = state or MixerState.create()
    state.collapsed_categories[category] = (collapsed == true)
    return state
end

function MixerState.is_category_collapsed(state, category)
    if type(state) ~= "table" or not state.collapsed_categories then return false end
    return state.collapsed_categories[category] == true
end

function MixerState.get_state(state)
    state = state or MixerState.create()
    return {
        visible = state.visible == true,
        selected_track_id = state.selected_track_id,
        last_mixer_result = state.last_mixer_result,
        collapsed_categories = state.collapsed_categories or {}
    }
end

return MixerState
