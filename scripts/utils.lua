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

return utils
