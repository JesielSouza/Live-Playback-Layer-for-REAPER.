--[[
    regions.lua
    Responsabilidade: Parse e extração de metadados das Regions nativas.
--]]

local utils = require("scripts.utils")

local regions = {}

-- Validation helpers
function regions.is_valid_loop(value)
    return value == "0" or value == "1" or value == "inf"
end

function regions.is_valid_jump_quant(value)
    return value == "immediate" or value == "bar" or value == "section_end"
end

function regions.is_valid_allow_prev(value)
    return value == "0" or value == "1"
end

-- Allowed fields
local allowed_fields = {
    loop = true,
    next = true,
    color = true,
    midi_scene = true,
    jump_quant = true,
    allow_prev = true,
    notes = true
}

-- Parses a single region raw name
function regions.parse_region_name(raw_name)
    local result = {
        valid = false,
        id = nil,
        name = nil,
        meta = {
            loop = "0",
            jump_quant = "bar",
            allow_prev = "1"
        },
        warnings = {}
    }

    if not raw_name or type(raw_name) ~= "string" then
        table.insert(result.warnings, "missing_section_name")
        return result
    end

    local tokens = utils.split(raw_name, "|")

    if #tokens == 0 or utils.trim(tokens[1]) == "" then
        table.insert(result.warnings, "missing_section_name")
        return result
    end

    local raw_section_name = utils.trim(tokens[1])
    result.name = raw_section_name
    result.id = utils.upper_snake(raw_section_name)
    result.valid = true

    for i = 2, #tokens do
        local token = utils.trim(tokens[i])
        if token ~= "" then
            local equals_idx = token:find("=")
            if not equals_idx then
                table.insert(result.warnings, "invalid_token_format: " .. token)
            else
                local key = utils.trim(token:sub(1, equals_idx - 1))
                local val = utils.trim(token:sub(equals_idx + 1))

                if not allowed_fields[key] then
                    table.insert(result.warnings, "unknown_field: " .. key)
                else
                    if key == "loop" then
                        if regions.is_valid_loop(val) then
                            result.meta.loop = val
                        else
                            table.insert(result.warnings, "invalid_loop_value: " .. val)
                            result.meta.loop = "0"
                        end
                    elseif key == "jump_quant" then
                        if regions.is_valid_jump_quant(val) then
                            result.meta.jump_quant = val
                        else
                            table.insert(result.warnings, "invalid_jump_quant_value: " .. val)
                            result.meta.jump_quant = "bar"
                        end
                    elseif key == "allow_prev" then
                        if regions.is_valid_allow_prev(val) then
                            result.meta.allow_prev = val
                        else
                            table.insert(result.warnings, "invalid_allow_prev_value: " .. val)
                            result.meta.allow_prev = "1"
                        end
                    else
                        -- Generic strings
                        result.meta[key] = val
                    end
                end
            end
        end
    end

    return result
end

-- Processes a list of raw region tables
function regions.parse_regions(raw_regions)
    local result = {
        sections = {},
        invalid = {},
        warnings = {}
    }

    if not raw_regions or type(raw_regions) ~= "table" then
        return result
    end

    for _, raw_region in ipairs(raw_regions) do
        local parsed = regions.parse_region_name(raw_region.name)

        if parsed.valid then
            -- Copy over standard region data
            parsed.start_pos = raw_region.start_pos
            parsed.end_pos = raw_region.end_pos
            parsed.index = raw_region.index
            table.insert(result.sections, parsed)

            -- Accumulate warnings
            for _, w in ipairs(parsed.warnings) do
                table.insert(result.warnings, "Region index " .. tostring(raw_region.index) .. ": " .. w)
            end
        else
            table.insert(result.invalid, raw_region)
            for _, w in ipairs(parsed.warnings) do
                table.insert(result.warnings, "Region index " .. tostring(raw_region.index) .. ": " .. w)
            end
        end
    end

    -- Sort valid sections by start_pos
    table.sort(result.sections, function(a, b)
        local start_a = a.start_pos or 0
        local start_b = b.start_pos or 0
        return start_a < start_b
    end)

    return result
end

return regions
