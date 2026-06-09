--[[
    validator.lua
    Responsabilidade: Checar integridade do projeto carregado (Safe Mode Layer).
--]]

local regions_parser = require("scripts.regions")
local validator = {}

-- Constant Statuses
validator.STATUS = {
    READY = "ready",
    WARNING = "warning",
    BLOCKED = "blocked"
}

-- Constant Errors
validator.ERRORS = {
    MISSING_PROJECT_SCAN = "missing_project_scan",
    PROJECT_SCAN_ERROR = "project_scan_error",
    MISSING_REGIONS = "missing_regions",
    NO_VALID_SECTIONS = "no_valid_sections",
    INVALID_REGION_TIMING = "invalid_region_timing"
}

-- Constant Warnings
validator.WARNINGS = {
    REAPER_NOT_AVAILABLE = "reaper_not_available",
    PARSER_WARNING = "parser_warning",
    INVALID_REGIONS_IGNORED = "invalid_regions_ignored",
    REGIONS_OUT_OF_ORDER = "regions_out_of_order",
    DUPLICATE_SECTION_NAMES = "duplicate_section_names"
}

function validator.validate_project(project_scan)
    local result = {
        ok = false,
        status = validator.STATUS.BLOCKED,
        errors = {},
        warnings = {},
        sections = {},
        summary = ""
    }

    -- 1. Check if project_scan was provided
    if not project_scan or type(project_scan) ~= "table" then
        table.insert(result.errors, validator.ERRORS.MISSING_PROJECT_SCAN)
        result.summary = "Validation failed: missing project scan data."
        return result
    end

    -- 2. Check for project scan errors
    if project_scan.errors and #project_scan.errors > 0 then
        table.insert(result.errors, validator.ERRORS.PROJECT_SCAN_ERROR)
        for _, err in ipairs(project_scan.errors) do
            table.insert(result.errors, "upstream: " .. err)
        end
        result.summary = "Validation failed: project scan reported errors."
        return result
    end

    -- 3. Pass upstream warnings (like REAPER not available)
    if project_scan.warnings and #project_scan.warnings > 0 then
        for _, warn in ipairs(project_scan.warnings) do
            if warn == "REAPER is not available. Running in simulated or disconnected environment." then
                table.insert(result.warnings, validator.WARNINGS.REAPER_NOT_AVAILABLE)
            else
                table.insert(result.warnings, "upstream: " .. warn)
            end
        end
    end

    -- 4. Check if regions list exists and is not empty
    if not project_scan.regions or type(project_scan.regions) ~= "table" or #project_scan.regions == 0 then
        table.insert(result.errors, validator.ERRORS.MISSING_REGIONS)
        result.summary = "Validation failed: no regions found in the project."
        return result
    end

    -- Check if regions are somewhat ordered before parsing (heuristic)
    local out_of_order = false
    local last_pos = -1
    for _, reg in ipairs(project_scan.regions) do
        if reg.start_pos and reg.start_pos < last_pos then
            out_of_order = true
        end
        if reg.start_pos then
            last_pos = reg.start_pos
        end
    end
    if out_of_order then
        table.insert(result.warnings, validator.WARNINGS.REGIONS_OUT_OF_ORDER)
    end

    -- 5. Parse regions using the regions parser
    local parsed = regions_parser.parse_regions(project_scan.regions)

    if parsed.invalid and #parsed.invalid > 0 then
        table.insert(result.warnings, validator.WARNINGS.INVALID_REGIONS_IGNORED)
    end

    -- Check for parser warnings across all valid sections
    local has_parser_warnings = false
    local name_counts = {}
    local duplicate_names = false

    if parsed.sections then
        for _, sec in ipairs(parsed.sections) do
            if sec.warnings and #sec.warnings > 0 then
                has_parser_warnings = true
            end
            if sec.name then
                name_counts[sec.name] = (name_counts[sec.name] or 0) + 1
                if name_counts[sec.name] > 1 then
                    duplicate_names = true
                end
            end

            -- Basic timing check
            if type(sec.start_pos) == "number" and type(sec.end_pos) == "number" then
                 if sec.start_pos >= sec.end_pos then
                     table.insert(result.errors, validator.ERRORS.INVALID_REGION_TIMING)
                 end
            end
        end
    end

    if has_parser_warnings then
        table.insert(result.warnings, validator.WARNINGS.PARSER_WARNING)
    end

    if duplicate_names then
        table.insert(result.warnings, validator.WARNINGS.DUPLICATE_SECTION_NAMES)
    end

    -- 6. Check if we ended up with any valid sections
    if not parsed.sections or #parsed.sections == 0 then
        table.insert(result.errors, validator.ERRORS.NO_VALID_SECTIONS)
        result.summary = "Validation failed: no valid sections could be parsed."
        return result
    end

    -- If there's an INVALID_REGION_TIMING error, return blocked
    for _, err in ipairs(result.errors) do
         if err == validator.ERRORS.INVALID_REGION_TIMING then
             result.summary = "Validation failed: one or more valid regions have start_pos >= end_pos."
             return result
         end
    end


    -- 7. Determine final status
    result.sections = parsed.sections
    if #result.errors > 0 then
        result.status = validator.STATUS.BLOCKED
        result.ok = false
        result.summary = "Validation failed with errors."
    elseif #result.warnings > 0 then
        result.status = validator.STATUS.WARNING
        result.ok = true
        result.summary = "Validation passed with warnings."
    else
        result.status = validator.STATUS.READY
        result.ok = true
        result.summary = "Validation passed successfully."
    end

    return result
end

-- Backward compatibility for checking structure, though this module is mostly rewritten.
function validator.check_project_structure()
    return true
end

function validator.is_safe_to_play()
    return true
end

return validator
