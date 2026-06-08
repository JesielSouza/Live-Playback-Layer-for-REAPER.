--[[
    config.lua
    Responsabilidade: Manter configurações em memória (Settings do operador).
--]]

local config = {}

-- TODO: Definir tabela padrão de configurações (paths, mapeamentos padrão, cores UI)

function config.load(filepath)
    -- TODO: Sobrescrever configs padrão lendo arquivo JSON local
end

function config.get(key)
    -- TODO: Retornar o valor
    return nil
end

return config
