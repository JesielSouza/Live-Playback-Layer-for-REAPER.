--[[
    live_queue.lua
    Manages a logical queue of next sections for live performance.
--]]

local LiveQueue = {}

function LiveQueue.create()
    return {
        items = {},
        warnings = {},
        errors = {}
    }
end

function LiveQueue.from_state(state)
    local queue = LiveQueue.create()
    if type(state) == "table" and type(state.items) == "table" then
        for _, item in ipairs(state.items) do
            table.insert(queue.items, {
                section_id = item.section_id,
                label = item.label or item.section_id,
                target_position = item.target_position,
                added_at = item.added_at
            })
        end
    end
    return queue
end

function LiveQueue.add_section(queue, section_id, metadata)
    if not queue or not section_id then return queue end
    metadata = metadata or {}
    
    table.insert(queue.items, {
        section_id = tostring(section_id),
        label = tostring(metadata.label or section_id),
        target_position = tonumber(metadata.target_position),
        added_at = os.time()
    })
    return queue
end

function LiveQueue.remove_at(queue, index)
    if not queue or not index or index < 1 or index > #queue.items then
        return queue
    end
    table.remove(queue.items, index)
    return queue
end

function LiveQueue.clear(queue)
    if not queue then return LiveQueue.create() end
    queue.items = {}
    return queue
end

function LiveQueue.move_up(queue, index)
    if not queue or not index or index <= 1 or index > #queue.items then
        return queue
    end
    queue.items[index], queue.items[index-1] = queue.items[index-1], queue.items[index]
    return queue
end

function LiveQueue.move_down(queue, index)
    if not queue or not index or index < 1 or index >= #queue.items then
        return queue
    end
    queue.items[index], queue.items[index+1] = queue.items[index+1], queue.items[index]
    return queue
end

function LiveQueue.peek(queue)
    if not queue or #queue.items == 0 then return nil end
    return queue.items[1]
end

function LiveQueue.pop(queue)
    if not queue or #queue.items == 0 then return nil end
    return table.remove(queue.items, 1)
end

function LiveQueue.get_items(queue)
    return queue and queue.items or {}
end

function LiveQueue.is_empty(queue)
    return not queue or #queue.items == 0
end

function LiveQueue.get_summary(queue)
    if not queue then return { count = 0, has_items = false } end
    return {
        count = #queue.items,
        first_section = queue.items[1] and queue.items[1].section_id or nil,
        has_items = #queue.items > 0
    }
end

function LiveQueue.validate_against_song_map(queue, song_map)
    if not queue then return end
    queue.warnings = {}
    if not song_map or not song_map.ok then return end
    
    local SongMap = require("scripts.song_map")
    for _, item in ipairs(queue.items) do
        if not SongMap.find_section(song_map, item.section_id) then
            table.insert(queue.warnings, "queue_section_not_found: " .. tostring(item.section_id))
        end
    end
end

function LiveQueue.format_item(item, index)
    if not item then return "nil" end
    local pos = item.target_position and string.format(" -> %.2fs", item.target_position) or ""
    return string.format("%d. %s%s", index, item.label or item.section_id, pos)
end

return LiveQueue
