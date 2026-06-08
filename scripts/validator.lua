--[[
    validator.lua
    Responsabilidade: Checar integridade do projeto carregado (Safe Mode Layer).
--]]

local validator = {}

function validator.check_project_structure()
    -- TODO: Verificar existência de track de click e guide
    -- TODO: Verificar se há pelo menos uma region
    return true
end

function validator.is_safe_to_play()
    -- TODO: Retornar true apenas se a validação estiver OK
    return true
end

return validator
