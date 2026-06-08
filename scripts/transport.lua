--[[
    transport.lua
    Responsabilidade: Controle de posição do playhead e ações de transporte.
--]]

local transport = {}

function transport.play()
    -- TODO: Enviar comando de Play nativo do REAPER
end

function transport.stop()
    -- TODO: Enviar comando de Stop nativo do REAPER
end

function transport.jump_to(time_pos)
    -- TODO: Mover o edit cursor para a posição e garantir que não haja estalo
end

function transport.toggle_loop()
    -- TODO: Criar ou remover time selection / loop points ao redor da section atual
end

function transport.panic()
    -- TODO: Mute master imediatamente e parar reprodução (Stop limpo)
end

return transport
