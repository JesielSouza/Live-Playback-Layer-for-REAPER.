--[[
    ui_timeline.lua
    Pure model for the UI representation of the song map (timeline blocks).
--]]

local UITimeline = {}

local function determine_state(section, song_map)
    if section.is_current then return "current" end
    if section.is_selected then return "selected" end
    if section.is_next then return "next" end
    if section.loop then return "loop" end
    return "normal"
end

function UITimeline.build(song_map, options)
    options = options or {}
    
    local timeline = {
        ok = false,
        blocks = {},
        selected_section = song_map and song_map.selected_section,
        current_section = song_map and song_map.current_section,
        next_section = song_map and song_map.next_section,
        errors = {},
        warnings = {}
    }

    if not song_map or not song_map.ok then
        table.insert(timeline.errors, "invalid_song_map")
        return timeline
    end

    for _, section in ipairs(song_map.sections) do
        local state = determine_state(section, song_map)
        local width_weight = (type(section.duration) == "number" and section.duration > 0) and section.duration or 1
        
        table.insert(timeline.blocks, {
            id = section.id,
            label = section.label,
            start = section.start,
            end_pos = section.end_pos,
            duration = section.duration,
            width_weight = width_weight,
            state = state,
            is_current = section.is_current,
            is_next = section.is_next,
            is_selected = section.is_selected,
            is_loop = section.loop
        })
    end

    timeline.ok = #timeline.blocks > 0
    return timeline
end

function UITimeline.get_blocks(timeline)
    return timeline and timeline.blocks or {}
end

function UITimeline.format_block(block)
    if not block then return "nil" end
    
    local prefix = ""
    if block.is_current then prefix = "[CURRENT] "
    elseif block.is_selected then prefix = "[SELECTED] "
    elseif block.is_next then prefix = "[NEXT] "
    elseif block.is_loop then prefix = "[LOOP] "
    end
    
    return prefix .. (block.label or block.id or "unknown")
end

function UITimeline.get_selected_block(timeline)
    if not timeline then return nil end
    for _, b in ipairs(timeline.blocks) do
        if b.is_selected then return b end
    end
    return nil
end

function UITimeline.get_current_block(timeline)
    if not timeline then return nil end
    for _, b in ipairs(timeline.blocks) do
        if b.is_current then return b end
    end
    return nil
end

function UITimeline.get_next_block(timeline)
    if not timeline then return nil end
    for _, b in ipairs(timeline.blocks) do
        if b.is_next then return b end
    end
    return nil
end

return UITimeline
