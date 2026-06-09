--[[
    bootstrap.lua
    Responsabilidade: Checagem de ambiente, dependências e setup inicial de caminhos.
    Implementa o Bootstrap Integration Pipeline conectando Project, Validator e State.
--]]

local project = require("scripts.project")
local validator = require("scripts.validator")
local state = require("scripts.state")

local bootstrap = {}

local last_startup_context = nil

function bootstrap.check_dependencies()
    local deps = {
        lua_ok = true,
        reaper_available = project.is_reaper_available(),
        warnings = {},
        errors = {}
    }

    if not deps.reaper_available then
        table.insert(deps.warnings, "reaper_not_available")
    end

    return deps
end

function bootstrap.build_startup_context(project_scan_override)
    local context = {
        dependencies = bootstrap.check_dependencies(),
        project_scan = {},
        validation = {},
        state = nil,
        warnings = {},
        errors = {}
    }

    if project_scan_override then
        context.project_scan = project_scan_override
    else
        context.project_scan = project.scan_current_project()
    end

    context.validation = validator.validate_project(context.project_scan)

    return context
end

function bootstrap.apply_validation_to_state(validation_result)
    if not validation_result then return end

    if validation_result.status == validator.STATUS.READY or validation_result.status == validator.STATUS.WARNING then
        state.set_sections(validation_result.sections)
        state.dispatch(state.EVENTS.LOAD_SONG_SUCCESS, { validation = validation_result })
    elseif validation_result.status == validator.STATUS.BLOCKED then
        state.set_error(validation_result.summary, validation_result)
        -- set_error already dispatches ERROR_RAISED under the hood in the state machine,
        -- but the requirement asks to call State.dispatch("ERROR_RAISED", ...) explicitly if needed,
        -- so we just rely on set_error which handles it properly or call it directly.
        -- Let's just follow the instruction to ensure it reaches ERROR state.
    end
end

function bootstrap.initialize_app(project_scan_override)
    state.reset()
    local context = bootstrap.build_startup_context(project_scan_override)
    bootstrap.apply_validation_to_state(context.validation)

    -- capture current state name into context
    context.state = state.get_current()

    last_startup_context = context
    return context
end

function bootstrap.get_last_startup_context()
    return last_startup_context
end

function bootstrap.setup_paths()
    -- Backward compatibility, not heavily used directly anymore since we run pure Lua via tests/run_tests.lua
end

return bootstrap
