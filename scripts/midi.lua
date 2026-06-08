--[[
    midi.lua
    Responsabilidade: Escutar e mapear triggers MIDI externos (pedais, teclados).
--]]

local midi = {}

function midi.listen()
    -- TODO: Checar se há novos eventos MIDI na fila ou verificar action context
end

function midi.map_trigger(note_or_cc, action_id)
    -- TODO: Associar uma nota/CC a uma ação interna (ex: Next Section)
end

return midi
