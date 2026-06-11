--[[
    ui_runtime.lua
    Pure read-only view model builder for runtime UI rendering.
--]]

local UIRuntime = {}
local TransportControl = require("scripts.transport_control")
local TransportAdapter = require("scripts.transport_adapter")
local TransportGate = require("scripts.transport_gate")
local TransportPreflight = require("scripts.transport_preflight")
local TransportReadiness = require("scripts.transport_readiness")
local PreExecutionAudit = require("scripts.pre_execution_audit")
local SafetyDashboard = require("scripts.safety_dashboard")
local UISession = require("scripts.ui_session")
local SongMap = require("scripts.song_map")
local UITimeline = require("scripts.ui_timeline")
local TrackAdapter = require("scripts.track_adapter")
local TrackCatalog = require("scripts.track_catalog")
local UIMixer = require("scripts.ui_mixer")
local MixerState = require("scripts.mixer_state")
local UISetlist = require("scripts.ui_setlist")
local SetlistModel = require("scripts.setlist_model")
local ProjectLoadAdapter = require("scripts.project_load_adapter")
local UILiveControl = require("scripts.ui_live_control")
local CueModel = require("scripts.cue_model")
local UICues = require("scripts.ui_cues")

local function text_or_nil(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function bool_label(value)
    return value == true and "true" or "false"
end

local function position_label(value)
    if type(value) ~= "number" then
        return "nil"
    end

    return string.format("%.2fs", value)
end

local function copy_list(values)
    local out = {}

    if type(values) ~= "table" then
        return out
    end

    for _, value in ipairs(values) do
        table.insert(out, value)
    end

    return out
end

local function playback_state_label(status)
    if status.is_playing then return "playing" end
    if status.is_paused then return "paused" end
    if status.is_recording then return "recording" end
    if status.reaper_available then return "stopped" end
    return "unknown"
end

function UIRuntime.format_status_line(view_model)
    view_model = view_model or {}

    return table.concat({
        text_or_nil(view_model.app_state),
        text_or_nil(view_model.current_section),
        text_or_nil(view_model.next_section),
        text_or_nil(view_model.decision)
    }, "  ")
end

local function apply_labels(view_model)
    view_model.current_position_label = position_label(view_model.current_position)
    view_model.read_only_label = bool_label(view_model.read_only)
    view_model.validation_label = text_or_nil(view_model.validation_status)
        .. " / ok="
        .. bool_label(view_model.validation_ok)
    view_model.diagnostics_label = "sections="
        .. tostring(view_model.section_count or 0)
        .. " events="
        .. tostring(view_model.logger_event_count or 0)
    if view_model.transport_intent_preview then
        local intent = view_model.transport_intent_preview
        view_model.transport_intent_label = "Transport Intent: "
            .. tostring(intent.action or "nil")
            .. " -> "
            .. tostring(intent.target_section or "nil")
            .. " (dry-run)"
    else
        view_model.transport_intent_label = "Transport Intent: nil -> nil (dry-run)"
    end
    view_model.status_line = UIRuntime.format_status_line(view_model)
end

function UIRuntime.build_view_model(snapshot, ui_session, mixer_state, options)
    options = options or {}
    local adapter_capabilities = TransportAdapter.get_capabilities({})
    local project_load_capabilities = ProjectLoadAdapter.get_capabilities({})
    local session_state = UISession.get_state(ui_session)
    local playback_status = TransportControl.get_playback_status({})
    local current_mixer_state = MixerState.get_state(mixer_state)
    
    local song_map = SongMap.build(snapshot)
    if session_state.selected_section then
        SongMap.select_section(song_map, session_state.selected_section)
    end
    local timeline = UITimeline.build(song_map, {})

    -- Live Control model
    local ui_live_control = UILiveControl.build(session_state.live_queue, session_state.loop_mode, song_map, {})

    -- Track Scan and Mixer logic
    local track_scan = options.track_scan_override
    if not track_scan and not options.disable_track_scan then
        track_scan = TrackAdapter.scan_tracks({})
    end
    local track_catalog = TrackCatalog.build(track_scan)
    local mixer = UIMixer.build(track_catalog, current_mixer_state)

    -- Setlist logic
    local setlist = options.setlist_override
    local ui_setlist = UISetlist.build(setlist, {})
    local current_song = SetlistModel.get_current_song(setlist)

    -- Cues logic
    local cue_store = options.cue_store_override
    local active_intent, active_intent_source = TransportControl.resolve_active_intent(snapshot, ui_session)
    local ui_cues = UICues.build(cue_store, song_map, active_intent, {})

    if type(snapshot) ~= "table" then
        local transport_gate_result = TransportGate.evaluate(nil, nil)
        local simulation_result = TransportControl.simulate_intent(nil, nil, {
            enabled = false,
            manual_confirmed = false
        })
        local preflight_report = TransportPreflight.build_report(
            nil,
            transport_gate_result,
            simulation_result,
            session_state
        )
        local safety_dashboard = SafetyDashboard.build(
            preflight_report,
            transport_gate_result,
            simulation_result,
            session_state
        )
        local seek_plan = TransportControl.build_seek_plan(nil, nil, {})
        local transport_readiness = TransportReadiness.build({
            adapter_capabilities = adapter_capabilities,
            gate_result = transport_gate_result,
            preflight_report = preflight_report,
            safety_dashboard = safety_dashboard,
            seek_plan = seek_plan,
            ui_session_state = session_state
        })
        local pre_execution_audit = PreExecutionAudit.build({
            runtime_snapshot = {},
            intent = nil,
            ui_session_state = session_state,
            gate_result = transport_gate_result,
            simulation_result = simulation_result,
            preflight_report = preflight_report,
            safety_dashboard = safety_dashboard,
            adapter_capabilities = adapter_capabilities,
            seek_plan = seek_plan,
            readiness = transport_readiness
        })
        local view_model = {
            ok = false,
            read_only = true,
            title = "Live Playback Layer",
            app_state = nil,
            validation_status = nil,
            validation_ok = false,
            reaper_available = false,
            current_position = nil,
            current_section = nil,
            previous_section = nil,
            next_section = nil,
            decision = nil,
            section_count = 0,
            logger_event_count = 0,
            status_line = "",
            current_position_label = "nil",
            read_only_label = "true",
            validation_label = "nil / ok=false",
            diagnostics_label = "sections=0 events=0",
            transport_intent_preview = nil,
            transport_intent_label = "Transport Intent: nil -> nil (dry-run)",
            transport_confirmation_label = "Manual Confirmation",
            transport_execution_enabled = false,
            transport_confirmation_required = true,
            manual_confirmation_active = false,
            confirmed_action = session_state.confirmed_action,
            confirmed_target_section = session_state.confirmed_target_section,
            confirmation_count = session_state.confirmation_count,
            transport_gate_result = transport_gate_result,
            simulation_result = simulation_result,
            preflight_report = preflight_report,
            safety_dashboard = safety_dashboard,
            adapter_capabilities = adapter_capabilities,
            project_load_capabilities = project_load_capabilities,
            seek_plan = seek_plan,
            transport_readiness = transport_readiness,
            pre_execution_audit = pre_execution_audit,
            execution_armed = session_state.execution_armed,
            last_execution_result = session_state.last_execution_result,
            last_project_load_result = session_state.last_project_load_result,
            debug_visible = session_state.debug_visible,
            playback_status = playback_status,
            song_map = song_map,
            timeline = timeline,
            live_queue = session_state.live_queue,
            loop_mode = session_state.loop_mode,
            ui_live_control = ui_live_control,
            last_live_control_result = session_state.last_live_control_result,
            track_scan = track_scan,
            track_catalog = track_catalog,
            mixer = mixer,
            last_mixer_result = current_mixer_state.last_mixer_result,
            setlist = setlist,
            ui_setlist = ui_setlist,
            current_song = current_song,
            current_song_project_path = current_song and current_song.project_path or nil,
            current_song_has_project = SetlistModel.song_has_project(current_song),
            last_setlist_result = session_state.last_setlist_result,
            cue_store = cue_store,
            ui_cues = ui_cues,
            last_cue_result = session_state.last_cue_result,
            cues_dirty = session_state.cues_dirty,
            operator_summary = {
                playback = playback_state_label(playback_status),
                current_section = "nil",
                target_section = "nil",
                target_position = "nil",
                confirmation_status = "NOT CONFIRMED",
                execution_armed = false,
                last_execution_reason = nil,
                last_execution_executed = nil,
                safety_note = "Manual actions only. No automatic jumps."
            },
            warnings = {},
            errors = { "missing_snapshot" }
        }
        apply_labels(view_model)
        return view_model
    end

    local transport_intent = TransportControl.build_intent("go_next", snapshot, { dry_run = true })
    local loop_current_intent = TransportControl.build_loop_current_intent(snapshot)
    
    local active_intent, active_intent_source = TransportControl.resolve_active_intent(snapshot, ui_session)
    
    local manual_confirmed = UISession.is_transport_confirmed(ui_session, active_intent)
    local transport_gate_result = TransportGate.evaluate(active_intent, snapshot, {
        enable_transport = false,
        require_manual_confirmation = true,
        manual_confirmed = manual_confirmed,
        allow_project_mutation = false
    })
    local simulation_result = TransportControl.simulate_intent(active_intent, snapshot, {
        enabled = false,
        manual_confirmed = manual_confirmed
    })
    local preflight_report = TransportPreflight.build_report(
        active_intent,
        transport_gate_result,
        simulation_result,
        session_state
    )
    local safety_dashboard = SafetyDashboard.build(
        preflight_report,
        transport_gate_result,
        simulation_result,
        session_state
    )
    local seek_plan = TransportControl.build_seek_plan(active_intent, snapshot, {})
    local transport_readiness = TransportReadiness.build({
        adapter_capabilities = adapter_capabilities,
        gate_result = transport_gate_result,
        preflight_report = preflight_report,
        safety_dashboard = safety_dashboard,
        seek_plan = seek_plan,
        ui_session_state = session_state
    })
    local pre_execution_audit = PreExecutionAudit.build({
        runtime_snapshot = snapshot,
        intent = active_intent,
        ui_session_state = session_state,
        gate_result = transport_gate_result,
        simulation_result = simulation_result,
        preflight_report = preflight_report,
        safety_dashboard = safety_dashboard,
        adapter_capabilities = adapter_capabilities,
        seek_plan = seek_plan,
        readiness = transport_readiness
    })
    local view_model = {
        ok = snapshot.ok == true,
        read_only = true,
        title = "Live Playback Layer",
        app_state = snapshot.app_state,
        validation_status = snapshot.validation_status,
        validation_ok = snapshot.validation_ok == true,
        reaper_available = snapshot.reaper_available == true,
        current_position = snapshot.position,
        current_section = snapshot.current_section,
        previous_section = snapshot.previous_section,
        next_section = snapshot.next_section,
        decision = snapshot.decision,
        section_count = snapshot.section_count or 0,
        logger_event_count = snapshot.logger_event_count or 0,
        status_line = "",
        current_position_label = "",
        read_only_label = "",
        validation_label = "",
        diagnostics_label = "",
        transport_intent_preview = transport_intent,
        loop_current_intent = loop_current_intent,
        active_intent = active_intent,
        active_intent_source = active_intent_source,
        transport_intent_label = "",
        transport_confirmation_label = "Manual Confirmation",
        transport_execution_enabled = false,
        transport_confirmation_required = true,
        manual_confirmation_active = manual_confirmed,
        confirmed_action = session_state.confirmed_action,
        confirmed_target_section = session_state.confirmed_target_section,
        confirmation_count = session_state.confirmation_count,
        transport_gate_result = transport_gate_result,
        simulation_result = simulation_result,
        preflight_report = preflight_report,
        safety_dashboard = safety_dashboard,
        adapter_capabilities = adapter_capabilities,
        project_load_capabilities = project_load_capabilities,
        seek_plan = seek_plan,
        transport_readiness = transport_readiness,
        pre_execution_audit = pre_execution_audit,
        execution_armed = session_state.execution_armed,
        last_execution_result = session_state.last_execution_result,
        last_project_load_result = session_state.last_project_load_result,
        debug_visible = session_state.debug_visible,
        playback_status = playback_status,
        song_map = song_map,
        timeline = timeline,
        live_queue = session_state.live_queue,
        loop_mode = session_state.loop_mode,
        ui_live_control = ui_live_control,
        last_live_control_result = session_state.last_live_control_result,
        selected_section = session_state.selected_section,
        track_scan = track_scan,
        track_catalog = track_catalog,
        mixer = mixer,
        last_mixer_result = current_mixer_state.last_mixer_result,
        setlist = setlist,
        ui_setlist = ui_setlist,
        current_song = current_song,
        current_song_project_path = current_song and current_song.project_path or nil,
        current_song_has_project = SetlistModel.song_has_project(current_song),
        last_setlist_result = session_state.last_setlist_result,
        cue_store = cue_store,
        ui_cues = ui_cues,
        last_cue_result = session_state.last_cue_result,
        cues_dirty = session_state.cues_dirty,
        operator_summary = {
            playback = playback_state_label(playback_status),
            current_section = text_or_nil(snapshot.current_section),
            next_target = text_or_nil(transport_intent.target_section),
            selected_target = text_or_nil(session_state.selected_section),
            active_target = text_or_nil(active_intent.target_section),
            active_source = active_intent_source,
            queue_count = #session_state.live_queue.items,
            loop_enabled = session_state.loop_mode.enabled,
            target_position = position_label(seek_plan.target_position),
            confirmation_status = manual_confirmed and "CONFIRMED" or "NOT CONFIRMED",
            execution_armed = session_state.execution_armed == true,
            last_execution_reason = session_state.last_execution_result and session_state.last_execution_result.reason or nil,
            last_execution_executed = session_state.last_execution_result and session_state.last_execution_result.executed or nil,
            safety_note = "Manual actions only. No automatic jumps."
        },
        warnings = copy_list(snapshot.warnings),
        errors = copy_list(snapshot.errors)
    }

    apply_labels(view_model)
    return view_model
end

function UIRuntime.get_section_cards(view_model)
    view_model = view_model or {}

    return {
        { label = "Current Section", value = text_or_nil(view_model.current_section), emphasis = true },
        { label = "Previous Section", value = text_or_nil(view_model.previous_section) },
        { label = "Next Section", value = text_or_nil(view_model.next_section), emphasis = true },
        { label = "Decision", value = text_or_nil(view_model.decision), emphasis = true },
        { label = "App State", value = text_or_nil(view_model.app_state) },
        { label = "Validation", value = text_or_nil(view_model.validation_label) },
        { label = "Position", value = text_or_nil(view_model.current_position_label), emphasis = true },
        { label = "Read Only", value = text_or_nil(view_model.read_only_label) }
    }
end

function UIRuntime.get_diagnostics_lines(view_model)
    view_model = view_model or {}

    local lines = {
        "Section Count: " .. tostring(view_model.section_count or 0),
        "Logger Event Count: " .. tostring(view_model.logger_event_count or 0)
    }

    if view_model.frame_count ~= nil then
        table.insert(lines, "Frame Count: " .. tostring(view_model.frame_count))
    end

    table.insert(lines, "Diagnostics: " .. text_or_nil(view_model.diagnostics_label))

    return lines
end

function UIRuntime.get_read_only_warning()
    return "No transport actions are triggered."
end

function UIRuntime.get_execution_control_lines(view_model)
    view_model = view_model or {}
    local result = view_model.last_execution_result

    local lines = {
        "Execution Armed: " .. bool_label(view_model.execution_armed == true)
    }

    if result then
        table.insert(lines, "Last Execution:")
        table.insert(lines, "- Executed: " .. bool_label(result.executed == true))
        table.insert(lines, "- Reason: " .. text_or_nil(result.reason))
        if result.target_position then
            table.insert(lines, "- Target Position: " .. position_label(result.target_position))
        end
    else
        table.insert(lines, "Last Execution: none")
    end

    return lines
end

function UIRuntime.get_operator_lines(view_model)
    view_model = view_model or {}
    local summary = view_model.operator_summary or {}

    local lines = {
        "Playback: " .. tostring(summary.playback or "unknown"),
        "Current Section: " .. tostring(summary.current_section or "nil"),
        "Next Target: " .. tostring(summary.next_target or "nil"),
        "Selected Target: " .. tostring(summary.selected_target or "none"),
        "Active Source: " .. tostring(summary.active_source or "nil"),
        "Active Target: " .. tostring(summary.active_target or "nil"),
        "Queue Count: " .. tostring(summary.queue_count or 0),
        "Infinite Loop: " .. (summary.loop_enabled and "ON" or "OFF"),
        "Target Position: " .. tostring(summary.target_position or "nil"),
        "Confirmation: " .. tostring(summary.confirmation_status or "NOT CONFIRMED"),
        "Execution Armed: " .. bool_label(summary.execution_armed == true)
    }

    if summary.last_execution_reason ~= nil then
        table.insert(lines, "Last Execution: executed=" .. bool_label(summary.last_execution_executed == true)
            .. " reason=" .. tostring(summary.last_execution_reason))
    end

    table.insert(lines, "Safety: " .. tostring(summary.safety_note or "Manual actions only. No automatic jumps."))

    return lines
end

function UIRuntime.get_timeline_lines(view_model)
    view_model = view_model or {}
    local timeline = view_model.timeline or {}
    local lines = { "Song Map" }
    
    for _, block in ipairs(UITimeline.get_blocks(timeline)) do
        local range = ""
        if block.start and block.end_pos then
            range = string.format(" %.1f-%.1f", block.start, block.end_pos)
        end
        table.insert(lines, UITimeline.format_block(block) .. range)
    end
    
    return lines
end

function UIRuntime.get_mixer_lines(view_model)
    view_model = view_model or {}
    local mixer = view_model.mixer or {}
    local lines = { "Mixer" }
    
    for _, row in ipairs(UIMixer.get_track_rows(mixer)) do
        table.insert(lines, row.label)
    end
    
    return lines
end

function UIRuntime.get_mixer_summary_lines(view_model)
    view_model = view_model or {}
    local mixer = view_model.mixer or {}
    return UIMixer.get_summary_lines(mixer)
end

function UIRuntime.get_setlist_lines(view_model)
    view_model = view_model or {}
    local ui_setlist = view_model.ui_setlist or {}
    return UISetlist.get_summary_lines(ui_setlist)
end

function UIRuntime.get_project_load_lines(view_model)
    view_model = view_model or {}
    local lines = {
        "Project Load",
        "Current song project: " .. text_or_nil(view_model.current_song_project_path),
        "Project linked: " .. bool_label(view_model.current_song_has_project == true)
    }
    
    local res = view_model.last_project_load_result
    if res then
        table.insert(lines, "Last Project Load: reason=" .. tostring(res.reason))
    end
    
    return lines
end

function UIRuntime.get_live_control_lines(view_model)
    view_model = view_model or {}
    local ui = view_model.ui_live_control or {}
    return UILiveControl.get_lines(ui)
end

function UIRuntime.get_cue_lines(view_model)
    view_model = view_model or {}
    local ui_cues = view_model.ui_cues or {}
    local lines = copy_list(ui_cues.summary_lines)
    
    table.insert(lines, "Cues Unsaved Changes: " .. bool_label(view_model.cues_dirty == true))

    if #ui_cues.current_cues > 0 then
        table.insert(lines, "Current Section Cues:")
        for _, c in ipairs(ui_cues.current_cues) do
            table.insert(lines, "- " .. UICues.format_cue(c))
        end
    end
    
    return lines
end

function UIRuntime.get_transport_preview_lines(view_model)
    view_model = view_model or {}
    local intent = view_model.transport_intent_preview or {}

    return {
        view_model.transport_intent_label or "Transport Intent: nil -> nil (dry-run)",
        "Target Section: " .. text_or_nil(intent.target_section),
        "Dry Run: " .. bool_label(intent.dry_run ~= false),
        "Executable: " .. bool_label(intent.executable == true),
        "Reason: " .. text_or_nil(intent.reason)
    }
end

function UIRuntime.get_transport_confirmation_lines(view_model)
    view_model = view_model or {}
    local intent = view_model.transport_intent_preview or {}
    local status = view_model.manual_confirmation_active == true and "CONFIRMED" or "NOT CONFIRMED"

    return {
        "Status: " .. status,
        "Confirmed Action: " .. text_or_nil(view_model.confirmed_action),
        "Confirmed Target: " .. text_or_nil(view_model.confirmed_target_section),
        "Count: " .. tostring(view_model.confirmation_count or 0),
        "Action: " .. text_or_nil(intent.action),
        "Target: " .. text_or_nil(intent.target_section),
        "Mode: DRY RUN",
        "Execution: DISABLED",
        "Confirmation: visual only"
    }
end

function UIRuntime.get_transport_gate_lines(view_model)
    view_model = view_model or {}
    local gate_result = view_model.transport_gate_result or {}
    local checks = gate_result.checks or {}

    return {
        "Executable: " .. bool_label(gate_result.executable == true),
        "Blocked: " .. bool_label(gate_result.blocked == true),
        "Reason: " .. text_or_nil(gate_result.reason),
        "Transport Enabled: " .. bool_label(checks.transport_enabled == true),
        "Manual Confirmation: " .. bool_label(checks.manual_confirmation_ok == true),
        "Mutation Allowed: " .. bool_label(checks.project_mutation_allowed == true)
    }
end

function UIRuntime.get_transport_simulation_lines(view_model)
    view_model = view_model or {}
    local result = view_model.simulation_result or {}

    return {
        "Simulated: " .. bool_label(result.simulated == true),
        "Executed: " .. bool_label(result.executed == true),
        "Message: " .. text_or_nil(result.message),
        "Target Section: " .. text_or_nil(result.target_section)
    }
end

function UIRuntime.get_transport_preflight_lines(view_model)
    view_model = view_model or {}
    local report = view_model.preflight_report or {}

    return {
        "Status: " .. text_or_nil(report.status),
        "Action: " .. text_or_nil(report.action),
        "Target Section: " .. text_or_nil(report.target_section),
        "Manual Confirmed: " .. bool_label(report.manual_confirmed == true),
        "Gate Executable: " .. bool_label(report.gate_executable == true),
        "Gate Reason: " .. text_or_nil(report.gate_reason),
        "Simulation OK: " .. bool_label(report.simulation_ok == true),
        "Simulation Message: " .. text_or_nil(report.simulation_message),
        "Summary: " .. text_or_nil(report.summary)
    }
end

function UIRuntime.get_safety_dashboard_lines(view_model)
    view_model = view_model or {}
    local dashboard = view_model.safety_dashboard or {}
    local lines = {
        "Safety Level: " .. text_or_nil(dashboard.safety_level),
        "Transport Real Enabled: " .. bool_label(dashboard.transport_real_enabled == true),
        "Execution Blocked: " .. bool_label(dashboard.execution_blocked ~= false),
        "Manual Confirmation Active: " .. bool_label(dashboard.manual_confirmation_active == true),
        "Gate Reason: " .. text_or_nil(dashboard.gate_reason),
        "Preflight Status: " .. text_or_nil(dashboard.preflight_status),
        "Simulation Message: " .. text_or_nil(dashboard.simulation_message),
        "Guarantees:"
    }

    for _, guarantee in ipairs(dashboard.guarantees or {}) do
        table.insert(lines, "- " .. tostring(guarantee))
    end

    return lines
end

function UIRuntime.get_transport_adapter_lines(view_model)
    view_model = view_model or {}
    local capabilities = view_model.adapter_capabilities or {}

    return {
        "Backend: " .. text_or_nil(capabilities.backend),
        "Real Transport Supported: " .. bool_label(capabilities.real_transport_supported == true),
        "Real Transport Enabled: " .. bool_label(capabilities.real_transport_enabled == true),
        "Can Play Stop: " .. bool_label(capabilities.can_play_stop == true),
        "Can Seek: " .. bool_label(capabilities.can_seek == true),
        "Can Mutate Project: " .. bool_label(capabilities.can_mutate_project == true),
        "Reason: " .. text_or_nil(capabilities.reason)
    }
end

function UIRuntime.get_seek_plan_lines(view_model)
    view_model = view_model or {}
    local plan = view_model.seek_plan or {}

    return {
        "Action: " .. text_or_nil(plan.action),
        "Current Section: " .. text_or_nil(plan.current_section),
        "Target Section: " .. text_or_nil(plan.target_section),
        "Target Position: " .. text_or_nil(plan.target_position),
        "Seek Required: " .. bool_label(plan.seek_required == true),
        "Locked: " .. bool_label(plan.locked == true),
        "Reason: " .. text_or_nil(plan.reason)
    }
end

function UIRuntime.get_transport_readiness_lines(view_model)
    view_model = view_model or {}
    local report = view_model.transport_readiness or {}
    local checks = report.checks or {}
    local blockers = report.blockers or {}
    local lines = {
        "Status: " .. text_or_nil(report.status),
        "Ready: " .. bool_label(report.ready == true),
        "Summary: " .. text_or_nil(report.summary),
        "Checks:",
        "- adapter_supported: " .. bool_label(checks.adapter_supported == true),
        "- adapter_enabled: " .. bool_label(checks.adapter_enabled == true),
        "- gate_executable: " .. bool_label(checks.gate_executable == true),
        "- preflight_simulated: " .. bool_label(checks.preflight_simulated == true),
        "- safety_not_blocked: " .. bool_label(checks.safety_not_blocked == true),
        "- seek_plan_ok: " .. bool_label(checks.seek_plan_ok == true),
        "- seek_plan_unlocked: " .. bool_label(checks.seek_plan_unlocked == true),
        "- manual_confirmed: " .. bool_label(checks.manual_confirmed == true),
        "Blockers:"
    }

    for _, blocker in ipairs(blockers) do
        table.insert(lines, "- " .. tostring(blocker))
    end

    return lines
end

function UIRuntime.get_pre_execution_audit_lines(view_model)
    view_model = view_model or {}
    local audit = view_model.pre_execution_audit or {}
    local blockers = audit.blockers or {}
    local lines = {
        "Audit Status: " .. text_or_nil(audit.audit_status),
        "Generated: " .. bool_label(audit.generated == true),
        "Action: " .. text_or_nil(audit.action),
        "Current Section: " .. text_or_nil(audit.current_section),
        "Target Section: " .. text_or_nil(audit.target_section),
        "Target Position: " .. text_or_nil(audit.target_position),
        "Manual Confirmed: " .. bool_label(audit.manual_confirmed == true),
        "Gate Reason: " .. text_or_nil(audit.gate_reason),
        "Simulation Message: " .. text_or_nil(audit.simulation_message),
        "Preflight Status: " .. text_or_nil(audit.preflight_status),
        "Safety Level: " .. text_or_nil(audit.safety_level),
        "Adapter Locked: " .. bool_label(audit.adapter_locked == true),
        "Seek Locked: " .. bool_label(audit.seek_locked == true),
        "Readiness Status: " .. text_or_nil(audit.readiness_status),
        "Execution Allowed: " .. bool_label(audit.execution_allowed == true),
        "Summary: " .. text_or_nil(audit.summary),
        "Blockers:"
    }

    for _, blocker in ipairs(blockers) do
        table.insert(lines, "- " .. tostring(blocker))
    end

    return lines
end

return UIRuntime
