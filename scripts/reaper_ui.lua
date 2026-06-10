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
local UISession = require("scripts.ui_session")

local ctx = ImGui.CreateContext("Live Playback Layer")
local ui_session = UISession.create()
local frame_count = 0

local function value_or_nil(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function render_line(label, value)
    ImGui.Text(ctx, label .. ": " .. value_or_nil(value))
end

local function render_card(card)
    local prefix = card.emphasis and ">> " or ""
    ImGui.Text(ctx, prefix .. card.label .. ": " .. value_or_nil(card.value))
end

local function render_separator()
    if ImGui.Separator then
        ImGui.Separator(ctx)
    else
        ImGui.Text(ctx, "----------------")
    end
end

local function loop()
    frame_count = frame_count + 1

    local snapshot_ok, snapshot = pcall(function()
        return Runtime.build_snapshot()
    end)

    local view_model = nil
    if snapshot_ok then
        view_model = UIRuntime.build_view_model(snapshot, ui_session)
        view_model.frame_count = frame_count
    end

    if ImGui.Begin(ctx, "Live Playback Layer") then
        ImGui.Text(ctx, "Live Playback Layer")

        if snapshot_ok and view_model then
            render_separator()
            ImGui.Text(ctx, "Status")
            ImGui.Text(ctx, value_or_nil(view_model.status_line))
            render_line("Read Only", view_model.read_only_label)
            render_line("App State", view_model.app_state)
            render_line("Validation Status", view_model.validation_label)

            render_separator()
            ImGui.Text(ctx, "Position")
            local cards = UIRuntime.get_section_cards(view_model)
            render_card(cards[7])
            render_card(cards[1])

            render_separator()
            ImGui.Text(ctx, "Navigation")
            render_card(cards[2])
            render_card(cards[3])
            render_card(cards[4])

            render_separator()
            ImGui.Text(ctx, "Transport Preview")
            for _, line in ipairs(UIRuntime.get_transport_preview_lines(view_model)) do
                ImGui.Text(ctx, line)
            end
            ImGui.Text(ctx, value_or_nil(view_model.transport_confirmation_label))
            for _, line in ipairs(UIRuntime.get_transport_confirmation_lines(view_model)) do
                ImGui.Text(ctx, line)
            end
            if ImGui.Button(ctx, "Confirm Intent (dry-run)") then
                UISession.confirm_transport(ui_session, view_model.transport_intent_preview)
            end
            if ImGui.Button(ctx, "Clear Confirmation") then
                UISession.clear_transport_confirmation(ui_session)
            end

            render_separator()
            ImGui.Text(ctx, "Transport Gate")
            for _, line in ipairs(UIRuntime.get_transport_gate_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Transport Simulation")
            for _, line in ipairs(UIRuntime.get_transport_simulation_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Transport Preflight")
            for _, line in ipairs(UIRuntime.get_transport_preflight_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Operational Safety Dashboard")
            for _, line in ipairs(UIRuntime.get_safety_dashboard_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Real Transport Adapter")
            for _, line in ipairs(UIRuntime.get_transport_adapter_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Seek Plan")
            for _, line in ipairs(UIRuntime.get_seek_plan_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Real Transport Readiness")
            for _, line in ipairs(UIRuntime.get_transport_readiness_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Pre-Execution Audit")
            for _, line in ipairs(UIRuntime.get_pre_execution_audit_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            render_separator()
            ImGui.Text(ctx, "Diagnostics")
            for _, line in ipairs(UIRuntime.get_diagnostics_lines(view_model)) do
                ImGui.Text(ctx, line)
            end
            ImGui.Text(ctx, UIRuntime.get_read_only_warning())
        else
            ImGui.Text(ctx, "Runtime snapshot failed.")
            ImGui.Text(ctx, value_or_nil(snapshot))
        end

        ImGui.End(ctx)
    end

    reaper.defer(loop)
end

reaper.defer(loop)
