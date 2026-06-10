local function msg(text)
    if _G and _G.reaper and type(_G.reaper.ShowConsoleMsg) == "function" then
        _G.reaper.ShowConsoleMsg(tostring(text) .. "\n")
    end
end

local function configure_project_package_path()
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

if not (_G and _G.reaper) then
    return
end

if not reaper.ImGui_GetBuiltinPath then
    msg("ReaImGui is not available. Install ReaImGui via ReaPack.")
    return
end

local imgui_package_path = reaper.ImGui_GetBuiltinPath() .. "/?.lua"
if not package.path:find(imgui_package_path, 1, true) then
    package.path = imgui_package_path .. ";" .. package.path
end

configure_project_package_path()

local ImGui = require("imgui")("0.10")
local Runtime = require("scripts.runtime")
local UIRuntime = require("scripts.ui_runtime")

local ctx = ImGui.CreateContext("Live Playback Layer")

local function value_or_nil(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function render_line(label, value)
    ImGui.Text(ctx, label .. ": " .. value_or_nil(value))
end

local function loop()
    local snapshot_ok, snapshot = pcall(function()
        return Runtime.build_snapshot()
    end)

    local view_model = nil
    if snapshot_ok then
        view_model = UIRuntime.build_view_model(snapshot)
    end

    if ImGui.Begin(ctx, "Live Playback Layer") then
        ImGui.Text(ctx, "Live Playback Layer")

        if snapshot_ok and view_model then
            ImGui.Text(ctx, value_or_nil(view_model.status_line))
            ImGui.Text(ctx, "")
            render_line("Read Only", view_model.read_only)
            render_line("App State", view_model.app_state)
            render_line("Validation Status", view_model.validation_status)
            render_line("Current Position", view_model.current_position and (tostring(view_model.current_position) .. "s") or nil)
            render_line("Current Section", view_model.current_section)
            render_line("Previous Section", view_model.previous_section)
            render_line("Next Section", view_model.next_section)
            render_line("Decision", view_model.decision)
            render_line("Section Count", view_model.section_count)
            render_line("Logger Event Count", view_model.logger_event_count)
            ImGui.Text(ctx, "")
            ImGui.Text(ctx, "No transport actions are triggered.")
        else
            ImGui.Text(ctx, "Runtime snapshot failed.")
            ImGui.Text(ctx, value_or_nil(snapshot))
        end

        ImGui.End(ctx)
    end

    reaper.defer(loop)
end

reaper.defer(loop)
