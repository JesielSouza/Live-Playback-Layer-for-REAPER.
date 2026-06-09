--[[
    utils.lua
    Responsabilidade: Funções genéricas de auxílio (string, math, table).
--]]

local utils = {}

function utils.trim(value)
    if type(value) ~= "string" then return value end
    return value:match("^%s*(.-)%s*$")
end

function utils.split(value, delimiter)
    if type(value) ~= "string" then return {} end
    local result = {}
    -- If delimiter is empty string, return characters (not typically what we want for split, but safe fallback)
    if not delimiter or delimiter == "" then
        for i = 1, #value do
            table.insert(result, value:sub(i, i))
        end
        return result
    end

    -- Escape magic characters for string.gmatch
    local escaped_delimiter = delimiter:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local pattern = "([^" .. escaped_delimiter .. "]+)"

    -- Using a different approach for splitting to handle empty elements properly
    local start = 1
    local split_start, split_end = string.find(value, escaped_delimiter, start)

    while split_start do
        table.insert(result, string.sub(value, start, split_start - 1))
        start = split_end + 1
        split_start, split_end = string.find(value, escaped_delimiter, start)
    end
    table.insert(result, string.sub(value, start))

    return result
end

function utils.upper_snake(value)
    if type(value) ~= "string" then return "" end
    local s = utils.trim(value)
    s = s:upper()
    s = s:gsub("%s+", "_")
    return s
end

function utils.shallow_copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = v
    end
    return copy
end

function utils.to_json(value)
    local t = type(value)
    if t == "string" then
        -- Escape double quotes, backslashes, and control characters simply
        local escaped = value:gsub("\\", "\\\\")
                             :gsub("\"", "\\\"")
                             :gsub("\n", "\\n")
                             :gsub("\r", "\\r")
                             :gsub("\t", "\\t")
        return '"' .. escaped .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "nil" then
        return "null"
    elseif t == "table" then
        -- Basic check for array vs object
        local is_array = true
        local max_k = 0
        local count = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                is_array = false
                break
            end
            max_k = math.max(max_k, k)
            count = count + 1
        end
        if is_array and max_k ~= count then
            is_array = false
        end

        local parts = {}
        if is_array then
            for i = 1, max_k do
                table.insert(parts, utils.to_json(value[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            -- Object
            for k, v in pairs(value) do
                local key_str = type(k) == "string" and k or tostring(k)
                table.insert(parts, utils.to_json(key_str) .. ":" .. utils.to_json(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        -- Fallback for unsupported types
        return '"<' .. t .. '>"'
    end
end

return utils
