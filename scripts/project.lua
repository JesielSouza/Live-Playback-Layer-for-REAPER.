--[[
    project.lua
    Responsabilidade: Interações globais com o projeto REAPER (.RPP aberto).
--]]

local project = {}

function project.is_open()
    -- TODO: Checar se existe um projeto carregado
    return false
end

function project.get_bpm()
    -- TODO: Retornar o BPM do projeto
    return 120
end

function project.get_track_by_name(name)
    -- TODO: Buscar e retornar track pointer baseado no nome
    return nil
end

return project
