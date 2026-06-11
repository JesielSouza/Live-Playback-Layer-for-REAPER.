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
local TransportControl = require("scripts.transport_control")
local MixerState = require("scripts.mixer_state")
local TrackAdapter = require("scripts.track_adapter")
local UIMixer = require("scripts.ui_mixer")
local SetlistStore = require("scripts.setlist_store")
local SetlistModel = require("scripts.setlist_model")
local UISetlist = require("scripts.ui_setlist")
local ProjectLoadAdapter = require("scripts.project_load_adapter")

local ctx = ImGui.CreateContext("Live Playback Layer")
local ui_session = UISession.create()
local mixer_state = MixerState.create()

-- Setlist initialization
local setlist_path = SetlistStore.get_default_path()
local setlist = SetlistStore.ensure(setlist_path)

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
        view_model = UIRuntime.build_view_model(snapshot, ui_session, mixer_state, {
            setlist_override = setlist
        })
        view_model.frame_count = frame_count
    end

    if ImGui.Begin(ctx, "Live Playback Layer") then
        ImGui.Text(ctx, "Live Playback Layer")

        if snapshot_ok and view_model then
            local summary = view_model.operator_summary or {}
            
            -- 1. Setlist / Songs
            render_separator()
            ImGui.Text(ctx, "Setlist / Songs")
            ImGui.Text(ctx, "Setlist file: " .. tostring(setlist_path))
            ImGui.Text(ctx, "Project loading is explicit only. Next/Previous will not load projects.")
            
            local ui_setlist = view_model.ui_setlist or {}
            for _, card in ipairs(ui_setlist.cards or {}) do
                if card.is_current then
                    ImGui.TextColored(ctx, 0x00FF00FF, card.label)
                else
                    ImGui.Text(ctx, card.label)
                end
                
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "LOAD##l" .. card.id) then
                    -- Mark as current then load
                    SetlistModel.set_current_song(setlist, card.id)
                    SetlistStore.save(setlist, setlist_path)
                    local res = ProjectLoadAdapter.load_project(card.project_path, { enable_project_load = true })
                    UISession.set_last_project_load_result(ui_session, res)
                end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "DRY##d" .. card.id) then
                    local res = ProjectLoadAdapter.load_project(card.project_path, { enable_project_load = true, dry_run = true })
                    UISession.set_last_project_load_result(ui_session, res)
                end
            end
            
            if ImGui.Button(ctx, "Previous Song") then
                local res = SetlistModel.move_previous(setlist)
                UISession.set_last_setlist_result(ui_session, res)
                if res.ok then SetlistStore.save(setlist, setlist_path) end
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Next Song") then
                local res = SetlistModel.move_next(setlist)
                UISession.set_last_setlist_result(ui_session, res)
                if res.ok then SetlistStore.save(setlist, setlist_path) end
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Add Placeholder") then
                SetlistModel.add_song(setlist, { title = "Current Project" })
                local res = SetlistStore.save(setlist, setlist_path)
                UISession.set_last_setlist_result(ui_session, res)
            end

            if ImGui.Button(ctx, "Load Current Project") then
                local current = SetlistModel.get_current_song(setlist)
                if current then
                    local res = ProjectLoadAdapter.load_project(current.project_path, { enable_project_load = true })
                    UISession.set_last_project_load_result(ui_session, res)
                end
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Dry Run Current") then
                local current = SetlistModel.get_current_song(setlist)
                if current then
                    local res = ProjectLoadAdapter.load_project(current.project_path, { enable_project_load = true, dry_run = true })
                    UISession.set_last_project_load_result(ui_session, res)
                end
            end
            
            if ImGui.Button(ctx, "Save Setlist") then
                local res = SetlistStore.save(setlist, setlist_path)
                UISession.set_last_setlist_result(ui_session, res)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Reload Setlist") then
                local res = SetlistStore.load(setlist_path)
                if res.ok then setlist = res.setlist end
                UISession.set_last_setlist_result(ui_session, res)
            end
            
            local last_sl = UISession.get_last_setlist_result(ui_session)
            if last_sl then
                ImGui.Text(ctx, "Last Setlist Action: " .. tostring(last_sl.reason))
                if last_sl.ok == false then
                    ImGui.TextColored(ctx, 0xFF0000FF, "Path: " .. tostring(last_sl.path))
                    if last_sl.error then
                        ImGui.TextColored(ctx, 0xFF0000FF, "Error: " .. tostring(last_sl.error))
                    end
                end
            end

            local last_load = UISession.get_last_project_load_result(ui_session)
            if last_load then
                ImGui.Text(ctx, "Last Project Load: " .. tostring(last_load.reason))
                if last_load.ok == false then
                    ImGui.TextColored(ctx, 0xFF0000FF, "Path: " .. tostring(last_load.project_path or last_load.path))
                    if last_load.error then
                        ImGui.TextColored(ctx, 0xFF0000FF, "Error: " .. tostring(last_load.error))
                    end
                end
            end

            -- 2. Playback Status (Grande)
            render_separator()
            ImGui.Text(ctx, "PLAYBACK: " .. string.upper(summary.playback or "UNKNOWN"))
            
            -- 3. Visual Timeline / Song Map
            render_separator()
            ImGui.Text(ctx, "Song Map")
            local blocks = view_model.timeline and view_model.timeline.blocks or {}
            for i, block in ipairs(blocks) do
                local prefix = ""
                if block.is_current then prefix = "> "
                elseif block.is_next then prefix = ">> "
                elseif block.is_selected then prefix = "* "
                elseif block.is_loop then prefix = "@ "
                end
                
                local label = prefix .. block.label
                if ImGui.Button(ctx, label .. "##" .. i) then
                    UISession.select_section(ui_session, block.id, block.start)
                end
                if i < #blocks then
                    ImGui.SameLine(ctx)
                end
            end

            -- 4. Operator Panel
            render_separator()
            ImGui.Text(ctx, "Operator Panel")
            for _, line in ipairs(UIRuntime.get_operator_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            -- Botões Principais
            if ImGui.Button(ctx, "Confirm Intent") then
                UISession.confirm_transport(ui_session, view_model.active_intent)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Arm") then
                UISession.arm_execution(ui_session)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Clear") then
                UISession.clear_transport_confirmation(ui_session)
                UISession.disarm_execution(ui_session)
                UISession.clear_selected_section(ui_session)
            end

            if ImGui.Button(ctx, "Move Cursor") then
                local result = TransportControl.execute_real_intent(
                    view_model.active_intent,
                    snapshot,
                    view_model.transport_gate_result,
                    {
                        enable_real_cursor_move = true,
                        enable_real_seek = false,
                        execution_armed = UISession.is_execution_armed(ui_session),
                        manual_confirmed = UISession.is_transport_confirmed(ui_session, view_model.active_intent),
                        seekplay = false
                    }
                )
                UISession.set_last_execution_result(ui_session, result)
                UISession.disarm_execution(ui_session)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Jump/Seek Now") then
                local result = TransportControl.execute_real_intent(
                    view_model.active_intent,
                    snapshot,
                    view_model.transport_gate_result,
                    {
                        enable_real_cursor_move = false,
                        enable_real_seek = true,
                        execution_armed = UISession.is_execution_armed(ui_session),
                        manual_confirmed = UISession.is_transport_confirmed(ui_session, view_model.active_intent),
                        seekplay = true
                    }
                )
                UISession.set_last_execution_result(ui_session, result)
                UISession.disarm_execution(ui_session)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Loop Current") then
                local loop_intent = TransportControl.build_loop_current_intent(snapshot)
                UISession.confirm_transport(ui_session, loop_intent)
                
                local result = TransportControl.execute_real_intent(
                    loop_intent,
                    snapshot,
                    view_model.transport_gate_result,
                    {
                        enable_real_cursor_move = false,
                        enable_real_seek = true,
                        execution_armed = UISession.is_execution_armed(ui_session),
                        manual_confirmed = true,
                        seekplay = true
                    }
                )
                UISession.set_last_execution_result(ui_session, result)
                UISession.disarm_execution(ui_session)
            end

            if ImGui.Button(ctx, "Play") then
                local result = TransportControl.execute_play({
                    enable_real_play = true,
                    execution_armed = UISession.is_execution_armed(ui_session)
                })
                UISession.set_last_execution_result(ui_session, result)
                UISession.disarm_execution(ui_session)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Stop") then
                local result = TransportControl.execute_stop({
                    enable_real_stop = true
                })
                UISession.set_last_execution_result(ui_session, result)
                UISession.disarm_execution(ui_session)
            end

            -- 5. Mixer / Stems
            render_separator()
            if ImGui.Button(ctx, (MixerState.is_visible(mixer_state) and "Hide Mixer" or "Show Mixer")) then
                MixerState.toggle_visible(mixer_state)
            end

            if MixerState.is_visible(mixer_state) then
                ImGui.Text(ctx, "Mixer / Stems")
                for _, line in ipairs(UIRuntime.get_mixer_summary_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end

                local mixer = view_model.mixer or {}
                for _, section in ipairs(UIMixer.get_category_sections(mixer)) do
                    if ImGui.CollapsingHeader(ctx, UIMixer.format_category_header(section), ImGui.TreeNodeFlags_DefaultOpen) then
                        for _, row in ipairs(section.rows) do
                            ImGui.Text(ctx, string.format("%d%%", row.volume_percent or 0))
                            ImGui.SameLine(ctx)
                            if ImGui.Button(ctx, (row.muted and "UNMUTE" or "MUTE") .. "##m" .. row.track_id) then
                                local res = TrackAdapter.set_track_mute(row.track_id, not row.muted, { enable_mixer_write = true })
                                MixerState.set_last_mixer_result(mixer_state, res)
                            end
                            ImGui.SameLine(ctx)
                            if ImGui.Button(ctx, (row.soloed and "UNSOLO" or "SOLO") .. "##s" .. row.track_id) then
                                local res = TrackAdapter.set_track_solo(row.track_id, not row.soloed, { enable_mixer_write = true })
                                MixerState.set_last_mixer_result(mixer_state, res)
                            end
                            ImGui.SameLine(ctx)
                            if ImGui.Button(ctx, "V-##v-" .. row.track_id) then
                                local res = TrackAdapter.set_track_volume(row.track_id, (row.volume or 0) - 0.05, { enable_mixer_write = true })
                                MixerState.set_last_mixer_result(mixer_state, res)
                            end
                            ImGui.SameLine(ctx)
                            if ImGui.Button(ctx, "V+##v+" .. row.track_id) then
                                local res = TrackAdapter.set_track_volume(row.track_id, (row.volume or 0) + 0.05, { enable_mixer_write = true })
                                MixerState.set_last_mixer_result(mixer_state, res)
                            end
                            ImGui.SameLine(ctx)
                            ImGui.Text(ctx, row.name)
                        end
                    end
                end

                local last_res = MixerState.get_last_mixer_result(mixer_state)
                if last_res then
                    ImGui.Text(ctx, "Last Mixer Action: " .. TrackAdapter.format_result(last_res))
                end
            end

            -- 6. Debug
            render_separator()
            local debug_label = view_model.debug_visible and "Hide Debug" or "Show Debug"
            if ImGui.Button(ctx, debug_label) then
                UISession.toggle_debug(ui_session)
            end

            if view_model.debug_visible then
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
                ImGui.Text(ctx, "Project Load Diagnostics")
                for _, line in ipairs(UIRuntime.get_project_load_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end

                render_separator()
                ImGui.Text(ctx, "Setlist Diagnostics")
                for _, line in ipairs(UIRuntime.get_setlist_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end

                render_separator()
                ImGui.Text(ctx, "Transport Preview")
                for _, line in ipairs(UIRuntime.get_transport_preview_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end
                ImGui.Text(ctx, value_or_nil(view_model.transport_confirmation_label))
                for _, line in ipairs(UIRuntime.get_transport_confirmation_lines(view_model)) do
                    ImGui.Text(ctx, line)
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
            end
        else
            ImGui.Text(ctx, "Runtime snapshot failed.")
            ImGui.Text(ctx, value_or_nil(snapshot))
        end

        ImGui.End(ctx)
    end

    reaper.defer(loop)
end

reaper.defer(loop)
