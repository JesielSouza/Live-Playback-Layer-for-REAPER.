--[[
    loop_mode.lua
    Manages the infinite loop logical state.
--]]

local LoopMode = {}

function LoopMode.create()
    return {
        enabled = false,
        section_id = nil,
        label = nil,
        target_position = nil,
        warnings = {},
        errors = {}
    }
end

function LoopMode.enable(loop_state, section_id, metadata)
    if not loop_state or not section_id then return loop_state end
    metadata = metadata or {}
    
    loop_state.enabled = true
    loop_state.section_id = tostring(section_id)
    loop_state.label = tostring(metadata.label or section_id)
    loop_state.target_position = tonumber(metadata.target_position)
    return loop_state
end

function LoopMode.disable(loop_state)
    if not loop_state then return LoopMode.create() end
    loop_state.enabled = false
    loop_state.section_id = nil
    loop_state.label = nil
    loop_state.target_position = nil
    return loop_state
end

function LoopMode.toggle(loop_state, section_id, metadata)
    if not loop_state then return LoopMode.create() end
    
    if loop_state.enabled and loop_state.section_id == section_id then
        return LoopMode.disable(loop_state)
    end
    
    return LoopMode.enable(loop_state, section_id, metadata)
end

function LoopMode.is_enabled(loop_state)
    return loop_state and loop_state.enabled == true
end

function LoopMode.get_section(loop_state)
    return loop_state and loop_state.section_id
end

function LoopMode.get_target(loop_state)
    return loop_state and loop_state.target_position
end

function LoopMode.get_summary(loop_state)
    if not loop_state then return { enabled = false } end
    return {
        enabled = loop_state.enabled == true,
        section_id = loop_state.section_id,
        target_position = loop_state.target_position
    }
end

function LoopMode.validate_against_song_map(loop_state, song_map)
    if not loop_state then return end
    loop_state.warnings = {}
    if not loop_state.enabled or not loop_state.section_id then return end
    if not song_map or not song_map.ok then return end
    
    local SongMap = require("scripts.song_map")
    if not SongMap.find_section(song_map, loop_state.section_id) then
        table.insert(loop_state.warnings, "loop_section_not_found: " .. tostring(loop_state.section_id))
    end
end

function LoopMode.format(loop_state)
    if not loop_state or not loop_state.enabled then
        return "Infinite Loop: OFF"
    end
    local pos = loop_state.target_position and string.format(" (%.2fs)", loop_state.target_position) or ""
    return string.format("Infinite Loop: ON %s%s", loop_state.label or loop_state.section_id, pos)
end

return LoopMode
