--[[
    bootstrap.lua
    Responsabilidade: Checagem de ambiente, dependências e setup inicial de caminhos.
--]]

local bootstrap = {}

function bootstrap.check_dependencies()
    -- TODO: Checar se ReaImGui está instalado
    -- TODO: Checar se SWS Extension está instalada (se aplicável)
    -- TODO: Retornar true se tudo estiver OK
    return true
end

function bootstrap.setup_paths()
    -- TODO: Adicionar caminhos relativos ao package.path para os requires
end

return bootstrap
