--[[
    main.lua
    Responsabilidade: Entrypoint conceitual da Live Playback Layer.
    Expõe o bootstrap para carregar o state machine.
--]]

local Bootstrap = require("scripts.bootstrap")

local M = {}

function M.start(project_scan_override)
    return Bootstrap.initialize_app(project_scan_override)
end

return M
