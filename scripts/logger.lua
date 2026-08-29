--[[
    logger.lua
    Responsabilidade: Gravação de logs locais (JSONL) para auditoria.
    Logger Core JSONL isolado, sem acoplamento.
--]]

local utils = require("scripts.utils")

local logger = {}

-- Constant Levels
logger.LEVELS = {
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR"
}

-- Internal state
local config = {
    file_path = nil,
    file_handle = nil
}
local events_memory = {}

function logger.new(options)
    local instance = {
        config = { file_path = options and options.file_path, file_handle = nil },
        events_memory = {}
    }
    -- Expose methods on the instance if needed, but the prompt asks for module-level singleton mainly.
    -- We provide a singleton interface for the main application but allow instances for flexibility.
    return instance
end

function logger.configure(options)
    if type(options) == "table" then
        if options.file_path ~= config.file_path then
            if config.file_handle then
                config.file_handle:close()
                config.file_handle = nil
            end
            if options.file_path ~= nil then
                config.file_path = options.file_path
            else
                config.file_path = nil
            end
        end
    end
end

function logger.get_events()
    return events_memory
end

function logger.clear()
    events_memory = {}
end

-- Normalize level function
local function normalize_level(level, payload)
    local upper_level = type(level) == "string" and level:upper() or "INFO"
    if logger.LEVELS[upper_level] then
        return upper_level
    end
    -- Invalid level
    if type(payload) == "table" then
        payload.invalid_level = level
    end
    return logger.LEVELS.INFO
end

function logger.create_event(level, event, payload)
    local p = type(payload) == "table" and payload or {}
    local norm_level = normalize_level(level, p)

    return {
        ts = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        level = norm_level,
        event = type(event) == "string" and event or "UNKNOWN_EVENT",
        payload = p
    }
end

function logger.log(level, event, payload)
    local event_record = logger.create_event(level, event, payload)
    table.insert(events_memory, event_record)
    return event_record
end

function logger.info(event, payload)
    return logger.log(logger.LEVELS.INFO, event, payload)
end

function logger.warn(event, payload)
    return logger.log(logger.LEVELS.WARN, event, payload)
end

function logger.error(event, payload)
    return logger.log(logger.LEVELS.ERROR, event, payload)
end

function logger.serialize_event(event_record)
    if type(event_record) ~= "table" then return "" end
    return utils.to_json(event_record)
end

function logger.serialize_events(events)
    if type(events) ~= "table" then return "" end
    local lines = {}
    for _, event_record in ipairs(events) do
        table.insert(lines, logger.serialize_event(event_record))
    end
    return table.concat(lines, "\n")
end

function logger.write_line(line)
    if not config.file_path then
        return true -- No file path configured, do not fail
    end

    if not config.file_handle then
        local file, err = io.open(config.file_path, "a")
        if not file then
            return false, err
        end
        config.file_handle = file
    end

    config.file_handle:write(line .. "\n")
    config.file_handle:flush()
    return true
end

function logger.flush()
    if not config.file_path or #events_memory == 0 then
        -- We clear memory as an implicit behavior of flushing if there is nowhere to write or nothing to write
        logger.clear()
        return true
    end

    local payload = logger.serialize_events(events_memory)

    if not config.file_handle then
        local file, err = io.open(config.file_path, "a")
        if not file then
            return false, err
        end
        config.file_handle = file
    end

    config.file_handle:write(payload .. "\n")
    config.file_handle:flush()

    logger.clear()
    return true
end

function logger.close()
    if config.file_handle then
        config.file_handle:close()
        config.file_handle = nil
    end
end

-- Backward compatibility for checking structure, though this module is mostly rewritten.
function logger.write_raw(line)
    return logger.write_line(line)
end

return logger
