--[[
    project_load_adapter.lua
    Isolates the real REAPER API for loading project files.
--]]

local ProjectLoadAdapter = {}

function ProjectLoadAdapter.is_reaper_available()
    return _G.reaper ~= nil
end

function ProjectLoadAdapter.get_capabilities()
    local available = ProjectLoadAdapter.is_reaper_available()
    local can_load = available and type(_G.reaper.Main_openProject) == "function"

    return {
        reaper_available = available,
        can_load_project = can_load,
        supports_dry_run = true,
        warnings = {},
        errors = {}
    }
end

function ProjectLoadAdapter.validate_project_path(project_path, options)
    if not project_path or project_path == "" then
        return { ok = false, reason = "missing_project_path", errors = { "missing_project_path" } }
    end

    local ext = project_path:sub(-4):lower()
    if ext ~= ".rpp" then
        return { ok = false, reason = "invalid_project_extension", errors = { "invalid_project_extension" } }
    end

    local f = io.open(project_path, "r")
    if not f then
        return { ok = false, reason = "project_file_not_found", errors = { "project_file_not_found" } }
    end
    f:close()

    return {
        ok = true,
        project_path = project_path,
        exists = true,
        extension_ok = true,
        reason = "project_path_valid",
        warnings = {},
        errors = {}
    }
end

function ProjectLoadAdapter.load_project(project_path, options)
    options = options or {}
    
    if not options.enable_project_load then
        return { ok = false, executed = false, reason = "project_load_not_enabled" }
    end

    local validation = ProjectLoadAdapter.validate_project_path(project_path, options)
    if not validation.ok then
        return { ok = false, executed = false, reason = validation.reason, errors = validation.errors }
    end

    if options.dry_run then
        return { ok = true, executed = false, dry_run = true, project_path = project_path, reason = "project_load_dry_run" }
    end

    local caps = ProjectLoadAdapter.get_capabilities()
    if not caps.reaper_available then
        return { ok = false, executed = false, reason = "reaper_not_available" }
    end

    if not caps.can_load_project then
        return { ok = false, executed = false, reason = "main_open_project_not_available" }
    end

    -- Real Action
    _G.reaper.Main_openProject(project_path)

    return {
        ok = true,
        executed = true,
        action = "load_project",
        project_path = project_path,
        reason = "project_load_executed"
    }
end

function ProjectLoadAdapter.format_result(result)
    if not result then return "nil" end
    return string.format("Action: %s, Path: %s, Result: %s, Reason: %s",
        tostring(result.action),
        tostring(result.project_path),
        tostring(result.ok),
        tostring(result.reason))
end

return ProjectLoadAdapter
