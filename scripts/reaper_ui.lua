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
local LiveQueue = require("scripts.live_queue")
local LoopMode = require("scripts.loop_mode")
local SongMap = require("scripts.song_map")
local CueStore = require("scripts.cue_store")
local CueModel = require("scripts.cue_model")
local UICues = require("scripts.ui_cues")
local MidiCueModel = require("scripts.midi_cue_model")
local MidiDryRun = require("scripts.midi_dry_run")
local UIMidiPreview = require("scripts.ui_midi_preview")

local ctx = ImGui.CreateContext("Live Playback Layer")
local ui_session = UISession.create()
local mixer_state = MixerState.create()

-- Setlist initialization
local setlist_path = SetlistStore.get_default_path()
local setlist = SetlistStore.ensure(setlist_path)

-- Cues initialization
local cue_path = CueStore.get_default_path()
local cue_store = CueStore.ensure(cue_path)

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
            setlist_override = setlist,
            cue_store_override = cue_store
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

            -- 4. Live Control
            render_separator()
            ImGui.Text(ctx, "Live Control")
            for _, line in ipairs(UIRuntime.get_live_control_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            if ImGui.Button(ctx, "Add Selected to Queue") then
                if view_model.selected_section then
                    local sm = view_model.song_map or TransportControl.build_song_map(snapshot)
                    local s = SongMap.find_section(sm, view_model.selected_section)
                    UISession.add_to_live_queue(ui_session, view_model.selected_section, {
                        label = s and s.label or view_model.selected_section,
                        target_position = s and s.start
                    })
                    UISession.set_last_live_control_result(ui_session, { ok = true, reason = "selected_added_to_queue" })
                else
                    UISession.set_last_live_control_result(ui_session, { ok = false, reason = "no_selected_section" })
                end
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Add Current to Queue") then
                UISession.add_to_live_queue(ui_session, snapshot.current_section, { target_position = snapshot.position })
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Add Next to Queue") then
                UISession.add_to_live_queue(ui_session, snapshot.next_section, {})
            end
            
            if ImGui.Button(ctx, "Clear Queue") then
                UISession.clear_live_queue(ui_session)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Loop Selected") then
                if view_model.selected_section then
                    local sm = view_model.song_map or TransportControl.build_song_map(snapshot)
                    local s = SongMap.find_section(sm, view_model.selected_section)
                    UISession.toggle_infinite_loop(ui_session, view_model.selected_section, {
                        label = s and s.label or view_model.selected_section,
                        target_position = s and s.start
                    })
                end
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Loop Current") then
                UISession.toggle_infinite_loop(ui_session, snapshot.current_section, { target_position = snapshot.position })
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Clear Loop") then
                UISession.disable_infinite_loop(ui_session)
            end

            -- Queue items list
            local q_items = LiveQueue.get_items(ui_session.live_queue)
            for i, item in ipairs(q_items) do
                ImGui.Text(ctx, LiveQueue.format_item(item, i))
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "USE##u" .. i) then
                    local q = ui_session.live_queue
                    local it = table.remove(q.items, i)
                    table.insert(q.items, 1, it)
                    UISession.set_live_queue(ui_session, q)
                end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "RM##r" .. i) then
                    UISession.remove_from_live_queue(ui_session, i)
                end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "^##up" .. i) then
                    UISession.move_live_queue_item_up(ui_session, i)
                end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "v##dn" .. i) then
                    UISession.move_live_queue_item_down(ui_session, i)
                end
            end

            local last_live = UISession.get_last_live_control_result(ui_session)
            if last_live then
                ImGui.Text(ctx, "Last Live Action: " .. tostring(last_live.reason))
            end

            -- 5. Operator Panel
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
                if result.ok and view_model.active_intent_source == "live_queue" then
                    LiveQueue.pop(ui_session.live_queue)
                end
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
                if result.ok and view_model.active_intent_source == "live_queue" then
                    LiveQueue.pop(ui_session.live_queue)
                end
                UISession.disarm_execution(ui_session)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Loop Current (instant)") then
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

            -- 6. Section Cues
            render_separator()
            ImGui.Text(ctx, "Section Cues")
            ImGui.Text(ctx, "Cues file: " .. tostring(cue_path))
            ImGui.Text(ctx, "Cues are visual/planned only. No MIDI is sent.")
            
            local ui_cues = view_model.ui_cues or {}
            for _, line in ipairs(UIRuntime.get_cue_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            if ImGui.Button(ctx, "Add Note to Current") then
                CueModel.add_placeholder_cue(cue_store, snapshot.current_section, "note")
                UISession.mark_cues_dirty(ui_session)
                UISession.set_last_cue_result(ui_session, { ok = true, reason = "cue_added_unsaved" })
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Add MIDI Placeholder to Current") then
                CueModel.add_placeholder_cue(cue_store, snapshot.current_section, "midi_placeholder")
                UISession.mark_cues_dirty(ui_session)
                UISession.set_last_cue_result(ui_session, { ok = true, reason = "cue_added_unsaved" })
            end
            
            if ImGui.Button(ctx, "Add Note to Selected") then
                if view_model.selected_section then
                    CueModel.add_placeholder_cue(cue_store, view_model.selected_section, "note")
                    UISession.mark_cues_dirty(ui_session)
                    UISession.set_last_cue_result(ui_session, { ok = true, reason = "cue_added_unsaved" })
                else
                    UISession.set_last_cue_result(ui_session, { ok = false, reason = "no_selected_section" })
                end
            end
            
            if ImGui.Button(ctx, "Save Cues") then
                local res = CueStore.save(cue_store, cue_path)
                if res.ok then UISession.clear_cues_dirty(ui_session) end
                UISession.set_last_cue_result(ui_session, res)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Reload Cues") then
                local res = CueStore.load(cue_path)
                if res.ok then 
                    cue_store = res.store 
                    UISession.clear_cues_dirty(ui_session)
                    UISession.set_last_cue_result(ui_session, { ok = true, reason = "cues_reloaded" })
                else
                    UISession.set_last_cue_result(ui_session, res)
                end
            end

            -- List cues for current section with management buttons
            local scues = CueModel.get_cues_for_section(cue_store, snapshot.current_section)
            for _, c in ipairs(scues) do
                ImGui.Text(ctx, UICues.format_cue(c))
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, (c.enabled and "DISABLE" or "ENABLE") .. "##ec" .. c.id) then
                    CueModel.set_cue_enabled(cue_store, c.id, not c.enabled)
                    UISession.mark_cues_dirty(ui_session)
                    UISession.set_last_cue_result(ui_session, { ok = true, reason = "cue_enabled_set_unsaved" })
                end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "RM##rc" .. c.id) then
                    CueModel.remove_cue(cue_store, c.id)
                    UISession.mark_cues_dirty(ui_session)
                    UISession.set_last_cue_result(ui_session, { ok = true, reason = "cue_removed_unsaved" })
                end
            end

            local last_cue = UISession.get_last_cue_result(ui_session)
            if last_cue then
                ImGui.Text(ctx, "Last Cue Action: " .. tostring(last_cue.reason))
                if last_cue.ok == false and last_cue.error then
                    ImGui.TextColored(ctx, 0xFF0000FF, "Error: " .. tostring(last_cue.error))
                end
            end

            -- 7. MIDI Cue Preview
            render_separator()
            ImGui.Text(ctx, "MIDI Cue Preview")
            ImGui.Text(ctx, "MIDI dry-run only. No MIDI is sent.")
            local m_prev = view_model.midi_preview or {}
            for _, line in ipairs(UIRuntime.get_midi_preview_lines(view_model)) do
                ImGui.Text(ctx, line)
            end

            if ImGui.Button(ctx, "Dry Run Current MIDI") then
                local evs = MidiCueModel.build_events_for_section(cue_store, snapshot.current_section)
                local res = MidiDryRun.run(evs, { source = "current", section_id = snapshot.current_section })
                UISession.set_last_midi_dry_run_result(ui_session, res)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Dry Run Next MIDI") then
                local evs = MidiCueModel.build_events_for_section(cue_store, snapshot.next_section)
                local res = MidiDryRun.run(evs, { source = "next", section_id = snapshot.next_section })
                UISession.set_last_midi_dry_run_result(ui_session, res)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Dry Run Active MIDI") then
                local target = view_model.active_intent and view_model.active_intent.target_section
                local evs = MidiCueModel.build_events_for_section(cue_store, target)
                local res = MidiDryRun.run(evs, { source = "active_target", section_id = target })
                UISession.set_last_midi_dry_run_result(ui_session, res)
            end

            -- Display events for current section
            if m_prev.current and #m_prev.current.events > 0 then
                ImGui.Text(ctx, "Current Section MIDI Events:")
                for _, e in ipairs(m_prev.current.events) do
                    ImGui.Text(ctx, "- " .. UIMidiPreview.format_event_line(e))
                end
            end
            if m_prev.current and #m_prev.current.invalid > 0 then
                ImGui.TextColored(ctx, 0xFF0000FF, "Current Section INVALID MIDI:")
                for _, e in ipairs(m_prev.current.invalid) do
                    ImGui.TextColored(ctx, 0xFF0000FF, "- " .. UIMidiPreview.format_event_line(e))
                end
            end

            -- 8. Mixer / Stems
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

            -- 9. Debug
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
                ImGui.Text(ctx, "MIDI Preview Diagnostics")
                for _, line in ipairs(UIRuntime.get_midi_preview_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end

                render_separator()
                ImGui.Text(ctx, "Cues Diagnostics")
                for _, line in ipairs(UIRuntime.get_cue_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end

                render_separator()
                ImGui.Text(ctx, "Live Control Diagnostics")
                for _, line in ipairs(UIRuntime.get_live_control_lines(view_model)) do
                    ImGui.Text(ctx, line)
                end

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
