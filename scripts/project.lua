--[[
    project.lua
    Responsabilidade: Interações globais com o projeto REAPER (.RPP aberto) e extração de Regions.
    Atua como um adapter seguro, retornando dados normalizados e suportando execução fora do REAPER.
--]]

local project = {}

-- Checa de forma segura se o ambiente possui a global reaper e funções mínimas
function project.is_reaper_available()
    if type(_G.reaper) == "table" then
        if type(_G.reaper.CountProjectMarkers) == "function" and type(_G.reaper.EnumProjectMarkers) == "function" then
            return true
        end
    end
    return false
end

-- Tenta obter a versão do REAPER, se disponível
function project.get_reaper_version()
    if project.is_reaper_available() and type(_G.reaper.GetAppVersion) == "function" then
        return _G.reaper.GetAppVersion()
    end
    return nil
end

-- Enumera todos os markers e regions brutos diretamente da API do REAPER
function project.enumerate_project_regions()
    local raw_entries = {}

    if not project.is_reaper_available() then
        return raw_entries
    end

    -- API REAPER: retval, num_markers, num_regions = reaper.CountProjectMarkers(proj)
    local ret, num_markers, num_regions = _G.reaper.CountProjectMarkers(0)
    local total_count = num_markers + num_regions

    for i = 0, total_count - 1 do
        -- API REAPER: retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = _G.reaper.EnumProjectMarkers(i)

        if isrgn then
            table.insert(raw_entries, {
                name = name,
                start_pos = pos,
                end_pos = rgnend,
                index = markrgnindexnumber
            })
        end
    end

    return raw_entries
end

-- Garante a estrutura correta (redundante se enumerate já retorna certo, mas útil para simulações ou expansões)
function project.normalize_reaper_region(raw_region)
    return {
        name = raw_region.name or "",
        start_pos = raw_region.start_pos or 0,
        end_pos = raw_region.end_pos or 0,
        index = raw_region.index or 0
    }
end

-- Orquestra a busca e garante o formato para o parser. Nunca retorna nil.
function project.get_regions_for_parser()
    local result = {}

    local success, raw_entries = pcall(project.enumerate_project_regions)

    if not success or type(raw_entries) ~= "table" then
        return result
    end

    for _, entry in ipairs(raw_entries) do
        table.insert(result, project.normalize_reaper_region(entry))
    end

    return result
end

-- Varre o projeto e consolida o status da integração
function project.scan_current_project()
    local result = {
        reaper_available = project.is_reaper_available(),
        reaper_version = project.get_reaper_version(),
        regions = {},
        warnings = {},
        errors = {}
    }

    if not result.reaper_available then
        table.insert(result.warnings, "REAPER is not available. Running in simulated or disconnected environment.")
        return result
    end

    local success, regions_data = pcall(project.get_regions_for_parser)

    if not success then
        table.insert(result.errors, "Failed to enumerate regions from REAPER API.")
    else
        result.regions = regions_data
    end

    return result
end

return project
