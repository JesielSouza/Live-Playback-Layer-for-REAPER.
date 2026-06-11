--[[
    ui_live_control.lua
    Pure logic for building the UI representation of live queue and loop controls.
--]]

local UILiveControl = {}
local LiveQueue = require("scripts.live_queue")
local LoopMode = require("scripts.loop_mode")

function UILiveControl.build(live_queue, loop_state, song_map, options)
    options = options or {}
    local ui = {
        ok = false,
        queue_lines = {},
        loop_lines = {},
        summary_lines = {},
        warnings = {},
        errors = {}
    }

    if not live_queue or not loop_state then
        table.insert(ui.errors, "missing_live_control_data")
        return ui
    end

    -- Loop Lines
    ui.loop_lines = { LoopMode.format(loop_state) }

    -- Queue Lines
    local items = LiveQueue.get_items(live_queue)
    if #items == 0 then
        ui.queue_lines = { "Live ReOrder Queue", "Queue: empty" }
    else
        ui.queue_lines = { "Live ReOrder Queue" }
        for i, item in ipairs(items) do
            table.insert(ui.queue_lines, LiveQueue.format_item(item, i))
        end
    end

    -- Summary Lines
    local q_summ = LiveQueue.get_summary(live_queue)
    local l_summ = LoopMode.get_summary(loop_state)
    
    ui.summary_lines = {
        "Live Control Summary",
        string.format("Queue Items: %d", q_summ.count),
        string.format("Infinite Loop: %s", l_summ.enabled and "ON (" .. tostring(l_summ.section_id) .. ")" or "OFF")
    }

    ui.ok = true
    return ui
end

function UILiveControl.get_lines(model)
    local lines = {}
    if model then
        for _, l in ipairs(model.queue_lines or {}) do table.insert(lines, l) end
        for _, l in ipairs(model.loop_lines or {}) do table.insert(lines, l) end
    end
    return lines
end

function UILiveControl.get_queue_lines(model)
    return model and model.queue_lines or {}
end

function UILiveControl.get_loop_lines(model)
    return model and model.loop_lines or {}
end

function UILiveControl.format_queue_item(item, index)
    return LiveQueue.format_item(item, index)
end

function UILiveControl.format_loop_state(loop_state)
    return LoopMode.format(loop_state)
end

return UILiveControl
