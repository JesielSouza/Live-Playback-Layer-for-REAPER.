--[[
    state.lua
    Responsabilidade: Manter o estado da aplicação (State Machine) e orquestrar as camadas.
--]]

local state = {}

-- TODO: Definir os estados constantes (IDLE, SONG_LOADED, PLAYING, etc.)

function state.init()
    -- TODO: Setar estado inicial para IDLE
end

function state.get_current_state()
    -- TODO: Retornar o estado atual
    return "IDLE"
end

function state.transition(new_state, event_data)
    -- TODO: Validar se a transição é permitida
    -- TODO: Atualizar estado
    -- TODO: Chamar o logger para registrar a transição
end

return state
