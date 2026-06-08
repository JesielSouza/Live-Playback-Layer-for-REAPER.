--[[
    main.lua
    Responsabilidade: Entrypoint conceitual da Live Playback Layer.
    Inicializa o bootstrap, chama o logger, state e monta o loop da UI.
--]]

local bootstrap = require("bootstrap")
local logger = require("logger")
local state = require("state")
local ui = require("ui")

local function init()
    logger.info("Initializing Live Playback Layer...")

    local is_ready = bootstrap.check_dependencies()
    if not is_ready then
        logger.error("Dependencies missing. Halting.")
        return
    end

    state.init()
    logger.info("System Ready.")
end

local function loop()
    -- TODO: Process events, update state, render UI
    ui.render()

    -- Exemplo de loop ReaScript:
    -- reaper.defer(loop)
end

-- Ponto de entrada (stub)
init()
-- loop()

return {}
