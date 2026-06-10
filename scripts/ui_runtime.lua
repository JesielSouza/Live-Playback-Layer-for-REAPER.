--[[
    ui_runtime.lua
    Pure read-only view model builder for runtime UI rendering.
--]]

local UIRuntime = {}
local TransportControl = require("scripts.transport_control")
local TransportGate = require("scripts.transport_gate")
local TransportPreflight = require("scripts.transport_preflight")
local UISession = require("scripts.ui_session")

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

function UIRuntime.build_view_model(snapshot, ui_session)
    if type(snapshot) ~= "table" then
        local session_state = UISession.get_state(ui_session)
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
            transport_gate_result = TransportGate.evaluate(nil, nil),
            simulation_result = TransportControl.simulate_intent(nil, nil, {
                enabled = false,
                manual_confirmed = false
            }),
            preflight_report = TransportPreflight.build_report(
                nil,
                TransportGate.evaluate(nil, nil),
                TransportControl.simulate_intent(nil, nil, {
                    enabled = false,
                    manual_confirmed = false
                }),
                session_state
            ),
            warnings = {},
            errors = { "missing_snapshot" }
        }
        apply_labels(view_model)
        return view_model
    end

    local transport_intent = TransportControl.build_intent("go_next", snapshot, { dry_run = true })
    local session_state = UISession.get_state(ui_session)
    local manual_confirmed = UISession.is_transport_confirmed(ui_session, transport_intent)
    local transport_gate_result = TransportGate.evaluate(transport_intent, snapshot, {
        enable_transport = false,
        require_manual_confirmation = true,
        manual_confirmed = manual_confirmed,
        allow_project_mutation = false
    })
    local simulation_result = TransportControl.simulate_intent(transport_intent, snapshot, {
        enabled = false,
        manual_confirmed = manual_confirmed
    })
    local preflight_report = TransportPreflight.build_report(
        transport_intent,
        transport_gate_result,
        simulation_result,
        session_state
    )
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

return UIRuntime
