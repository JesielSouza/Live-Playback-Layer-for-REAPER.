--[[
    ui_session.lua
    In-memory UI session state. This module does not call REAPER APIs and does
    not trigger transport actions.
--]]

local UISession = {}

local function apply_defaults(session)
    session.transport_confirmed = false
    session.confirmed_action = nil
    session.confirmed_target_section = nil
    session.confirmation_count = 0
    return session
end

function UISession.create()
    return apply_defaults({})
end

function UISession.reset(session)
    return apply_defaults(session or {})
end

function UISession.confirm_transport(session, intent)
    session = session or UISession.create()

    if type(intent) ~= "table" or intent.ok ~= true then
        return session
    end

    session.transport_confirmed = true
    session.confirmed_action = intent.action
    session.confirmed_target_section = intent.target_section
    session.confirmation_count = (session.confirmation_count or 0) + 1

    return session
end

function UISession.clear_transport_confirmation(session)
    session = session or UISession.create()
    session.transport_confirmed = false
    session.confirmed_action = nil
    session.confirmed_target_section = nil
    session.confirmation_count = session.confirmation_count or 0
    return session
end

function UISession.is_transport_confirmed(session, intent)
    if type(session) ~= "table" or session.transport_confirmed ~= true then
        return false
    end

    if type(intent) ~= "table" then
        return false
    end

    return intent.action == session.confirmed_action
        and intent.target_section == session.confirmed_target_section
end

function UISession.get_state(session)
    session = session or {}

    return {
        transport_confirmed = session.transport_confirmed == true,
        confirmed_action = session.confirmed_action,
        confirmed_target_section = session.confirmed_target_section,
        confirmation_count = session.confirmation_count or 0
    }
end

return UISession
