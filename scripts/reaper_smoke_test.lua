--[[
    reaper_smoke_test.lua
    Responsabilidade: Entrypoint seguro para rodar dentro do REAPER
    como um ReaScript. Executa o pipeline Bootstrap completo usando
    metadados do projeto ativo (read-only) e cospe no console do REAPER.
--]]

local function configure_package_path()
    local source = debug and debug.getinfo and debug.getinfo(1, "S").source or nil
    if not source then
        return
    end

    local script_path = source:match("^@(.+)$")
    if not script_path then
        return
    end

    local script_dir = script_path:match("^(.*[\\/])")
    if not script_dir then
        return
    end

    local project_root = script_dir:gsub("[\\/]scripts[\\/]?$", "")
    if not project_root or project_root == script_dir then
        return
    end

    local patterns = {
        project_root .. "\\?.lua",
        project_root .. "\\?\\init.lua",
        project_root .. "/?.lua",
        project_root .. "/?/init.lua",
    }

    for _, pattern in ipairs(patterns) do
        if not package.path:find(pattern, 1, true) then
            package.path = package.path .. ";" .. pattern
        end
    end
end

configure_package_path()

local bootstrap = require("scripts.bootstrap")
local logger = require("scripts.logger")
local navigation = require("scripts.navigation")
local position = require("scripts.position")
local state = require("scripts.state")

local SmokeTest = {}

function SmokeTest.run()
    logger.clear()
    local ctx = bootstrap.initialize_app()
    local sections = ctx and ctx.validation and ctx.validation.sections or {}
    local sections_map = navigation.format_sections_map(sections)
    local navigation_plan = navigation.plan_initial_navigation(sections)
    local navigation_report = navigation.format_navigation_plan(navigation_plan)
    local position_result = position.get_reaper_position()
    local position_snapshot = nil
    if position_result.ok then
        position_snapshot = position.build_position_snapshot(sections, position_result.position)
    else
        position_snapshot = {
            ok = false,
            position = position_result.position,
            current_section = nil,
            previous_section = nil,
            next_section = nil,
            navigation_plan = nil,
            warnings = position_result.warnings or {},
            errors = position_result.errors or {}
        }
    end
    local position_report = position.format_position_snapshot(position_snapshot)
    local events = logger.get_events()

    local events_copy = {}
    for _, ev in ipairs(events) do
        table.insert(events_copy, ev)
    end

    local report_text = SmokeTest.format_reaper_report({
        context = ctx,
        events = events_copy,
        sections_map = sections_map,
        navigation_plan = navigation_plan,
        navigation_report = navigation_report,
        position_result = position_result,
        position_snapshot = position_snapshot,
        position_report = position_report
    })

    return {
        context = ctx,
        events = events_copy,
        sections_map = sections_map,
        navigation_plan = navigation_plan,
        navigation_report = navigation_report,
        position_result = position_result,
        position_snapshot = position_snapshot,
        position_report = position_report,
        report = report_text
    }
end

function SmokeTest.format_reaper_report(result)
    local ctx = result.context
    local v = ctx and ctx.validation or {}
    local scan = ctx and ctx.project_scan or {}
    local deps = ctx and ctx.dependencies or {}

    local lines = {}
    table.insert(lines, "=== Live Playback Layer — REAPER Smoke Test ===")
    table.insert(lines, "REAPER Available: " .. tostring(deps.reaper_available))
    table.insert(lines, "Regions Scanned: " .. tostring(scan.regions and #scan.regions or 0))
    table.insert(lines, "Validation Status: " .. tostring(v.status))
    table.insert(lines, "Validation Ok: " .. tostring(v.ok))
    table.insert(lines, "Section Count: " .. tostring(v.sections and #v.sections or 0))
    table.insert(lines, "Final State: " .. tostring(state.get_current()))
    table.insert(lines, "Summary: " .. tostring(v.summary))
    table.insert(lines, "")
    table.insert(lines, "=== Sections Map ===")
    table.insert(lines, tostring(result.sections_map or navigation.format_sections_map(v.sections or {})))
    table.insert(lines, "")
    table.insert(lines, "=== Navigation Plan ===")
    table.insert(lines, tostring(result.navigation_report or navigation.format_navigation_plan(result.navigation_plan)))
    table.insert(lines, "")
    table.insert(lines, "=== Position Snapshot ===")
    table.insert(lines, tostring(result.position_report or position.format_position_snapshot(result.position_snapshot)))

    local ev_count = result.events and #result.events or 0
    table.insert(lines, "Logger Event Count: " .. tostring(ev_count))
    table.insert(lines, "-------------------------------------------------")
    table.insert(lines, "NOTE: No transport actions were triggered.")
    table.insert(lines, "This script is completely read-only.")
    table.insert(lines, "=================================================")

    return table.concat(lines, "\n")
end

function SmokeTest.print_to_reaper_console(text)
    local success, _ = pcall(function()
        if _G.reaper and type(_G.reaper.ShowConsoleMsg) == "function" then
            _G.reaper.ShowConsoleMsg(tostring(text) .. "\n")
        else
            print(text)
        end
    end)
    -- Ignore failures to guarantee we never crash
end

function SmokeTest.safe_main()
    local ok, res = pcall(SmokeTest.run)
    if ok and type(res) == "table" then
        SmokeTest.print_to_reaper_console(res.report)
    else
        SmokeTest.print_to_reaper_console("=== Live Playback Layer — FATAL ERROR ===")
        SmokeTest.print_to_reaper_console("The smoke test failed to execute safely.")
        if type(res) == "string" then
            SmokeTest.print_to_reaper_console("Error Details: " .. res)
        end
        SmokeTest.print_to_reaper_console("=========================================")
    end
end

if _G and _G.reaper then
    SmokeTest.safe_main()
end

return SmokeTest
