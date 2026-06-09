--[[
    debug_runner.lua
    Responsabilidade: Pipeline de execução e teste offline para simular o
    ambiente do Live Playback Layer (Smoke Test preparation).
--]]

local bootstrap = require("scripts.bootstrap")
local logger = require("scripts.logger")
local state = require("scripts.state")

local DebugRunner = {}

function DebugRunner.build_sample_project_scan(kind)
    if kind == "ready" then
        return {
            reaper_available = true,
            warnings = {},
            errors = {},
            regions = {
                { name = "INTRO|loop=0", start_pos = 0, end_pos = 10, index = 1 },
                { name = "VERSE|loop=1", start_pos = 10, end_pos = 20, index = 2 }
            }
        }
    elseif kind == "warning" then
        return {
            reaper_available = false,
            warnings = {"Running offline"},
            errors = {},
            regions = {
                { name = "CHORUS|loop=abc", start_pos = 0, end_pos = 10, index = 1 }, -- generates parser warning
                { name = "BRIDGE|loop=0", start_pos = 10, end_pos = 20, index = 2 }
            }
        }
    elseif kind == "blocked" then
        return {
            reaper_available = false,
            warnings = {},
            errors = {},
            regions = {
                { name = "INVALID", start_pos = 20, end_pos = 10, index = 1 } -- invalid timing
            }
        }
    end

    return nil
end

function DebugRunner.format_report(startup_context, logger_events)
    local lines = {}
    table.insert(lines, "=== Debug Runner Report ===")
    if startup_context and startup_context.validation then
        local v = startup_context.validation
        table.insert(lines, "Validation Status: " .. tostring(v.status))
        table.insert(lines, "Validation Ok: " .. tostring(v.ok))
        table.insert(lines, "Section Count: " .. tostring(v.sections and #v.sections or 0))
        table.insert(lines, "Summary: " .. tostring(v.summary))
    else
        table.insert(lines, "Validation Status: N/A")
    end

    table.insert(lines, "Final State: " .. tostring(state.get_current()))

    local ev_count = logger_events and #logger_events or 0
    table.insert(lines, "Logger Event Count: " .. tostring(ev_count))
    table.insert(lines, "===========================")

    return table.concat(lines, "\n")
end

function DebugRunner.run(project_scan_override)
    logger.clear()
    local ctx = bootstrap.initialize_app(project_scan_override)
    local events = logger.get_events()

    -- Copy events so we have a static snapshot for the return
    local events_copy = {}
    for _, ev in ipairs(events) do
        table.insert(events_copy, ev)
    end

    local report_text = DebugRunner.format_report(ctx, events_copy)

    return {
        context = ctx,
        events = events_copy,
        report = report_text
    }
end

return DebugRunner
