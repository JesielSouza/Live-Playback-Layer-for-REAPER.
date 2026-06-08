--[[
    logger.lua
    Responsabilidade: Gravação de logs locais (JSONL) para auditoria.
--]]

local logger = {}

-- TODO: Definir arquivo de destino

function logger.info(msg, data)
    -- TODO: Formatar como JSON Line e escrever em arquivo
end

function logger.error(msg, data)
    -- TODO: Formatar erro como JSON Line e escrever em arquivo
end

function logger.write_raw(line)
    -- TODO: I/O básico em arquivo de log
end

return logger
