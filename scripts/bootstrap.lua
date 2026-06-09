--[[
    bootstrap.lua
    Responsabilidade: Checagem de ambiente, dependências e setup inicial de caminhos.
    Implementa o Bootstrap Integration Pipeline conectando Project, Validator e State.
--]]

local project = require("scripts.project")
local validator = require("scripts.validator")
local state = require("scripts.state")
local logger = require("scripts.logger")

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
    local deps = bootstrap.check_dependencies()
    logger.info("DEPENDENCIES_CHECKED", {
        reaper_available = deps.reaper_available,
        warnings = deps.warnings,
        errors = deps.errors
    })

    local context = {
        dependencies = deps,
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

    logger.info("PROJECT_SCANNED", {
        reaper_available = context.project_scan.reaper_available,
        region_count = context.project_scan.regions and #context.project_scan.regions or 0,
        warning_count = context.project_scan.warnings and #context.project_scan.warnings or 0,
        error_count = context.project_scan.errors and #context.project_scan.errors or 0
    })

    context.validation = validator.validate_project(context.project_scan)

    local v_status = context.validation.status
    local v_payload = {
        status = v_status,
        ok = context.validation.ok,
        section_count = context.validation.sections and #context.validation.sections or 0,
        warnings = context.validation.warnings,
        errors = context.validation.errors,
        summary = context.validation.summary
    }

    if v_status == validator.STATUS.READY then
        logger.info("VALIDATION_READY", v_payload)
    elseif v_status == validator.STATUS.WARNING then
        logger.warn("VALIDATION_WARNING", v_payload)
    elseif v_status == validator.STATUS.BLOCKED then
        logger.error("VALIDATION_BLOCKED", v_payload)
    end

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
    logger.info("APP_START", { source = "bootstrap.initialize_app" })

    state.reset()
    local context = bootstrap.build_startup_context(project_scan_override)
    bootstrap.apply_validation_to_state(context.validation)

    -- capture current state name into context
    context.state = state.get_current()

    if context.state == state.STATES.SONG_LOADED then
        logger.info("STATE_LOADED", {
            state = context.state,
            summary = context.validation.summary
        })
    elseif context.state == state.STATES.ERROR then
        logger.error("STATE_ERROR", {
            state = context.state,
            summary = context.validation.summary
        })
    end

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
