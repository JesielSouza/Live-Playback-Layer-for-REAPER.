local project = require("scripts.project")
local regions_parser = require("scripts.regions")

local function run_project_tests()
    print("Running project adapter tests...\n")

    -- 1. is_reaper_available retorna false quando _G.reaper é nil
    _G.reaper = nil
    assert(project.is_reaper_available() == false, "Test 1 failed")
    print("Test 1 passed: is_reaper_available false outside REAPER")

    -- 2. enumerate_project_regions retorna {} fora do REAPER.
    local r2 = project.enumerate_project_regions()
    assert(type(r2) == "table" and #r2 == 0, "Test 2 failed")
    print("Test 2 passed: enumerate_project_regions returns empty table outside REAPER")

    -- 3. scan_current_project não crasha fora do REAPER.
    local scan3 = project.scan_current_project()
    assert(scan3.reaper_available == false, "Test 3 failed")
    assert(type(scan3.regions) == "table" and #scan3.regions == 0, "Test 3 failed")
    assert(#scan3.warnings > 0, "Test 3 failed")
    print("Test 3 passed: scan_current_project does not crash outside REAPER")

    -- Setup mock environment for REAPER
    local original_reaper = _G.reaper
    _G.reaper = {
        GetAppVersion = function() return "6.0.0" end,
        CountProjectMarkers = function(proj) return 0, 1, 2 end, -- 1 marker, 2 regions
        EnumProjectMarkers = function(i)
            if i == 0 then
                -- retval, isrgn, pos, rgnend, name, markrgnindexnumber
                return 1, false, 0, 0, "Marker1", 1
            elseif i == 1 then
                return 1, true, 10, 20, "VALID_REGION|loop=1", 2
            elseif i == 2 then
                return 1, true, 0, 5, "EARLY_REGION|loop=0", 3
            end
            return 0, false, 0, 0, "", 0
        end
    }

    -- 4. Simulação de REAPER com uma Region válida retorna uma region normalizada.
    -- (O mock retorna duas, vamos checar a primeira válida)
    local r4 = project.get_regions_for_parser()
    assert(#r4 == 2, "Test 4 failed (expected 2 regions)")
    assert(r4[1].name == "VALID_REGION|loop=1", "Test 4 failed")
    assert(r4[1].start_pos == 10, "Test 4 failed")
    assert(r4[1].index == 2, "Test 4 failed")
    print("Test 4 passed: Mocked REAPER valid region returns normalized structure")

    -- 5. Simulação de REAPER com marker não-region ignora o marker.
    -- O mock tem o índice 0 como isrgn = false (Marker1)
    local has_marker = false
    for _, reg in ipairs(r4) do
        if reg.name == "Marker1" then has_marker = true end
    end
    assert(has_marker == false, "Test 5 failed")
    print("Test 5 passed: Non-region markers are safely ignored")

    -- 6. Simulação com duas regions fora de ordem retorna ambas no formato esperado.
    assert(r4[1].start_pos == 10 and r4[2].start_pos == 0, "Test 6 failed")
    print("Test 6 passed: Both regions are captured exactly as API returns them")

    -- 7. get_regions_for_parser nunca retorna nil.
    _G.reaper.CountProjectMarkers = function() error("Simulated API Error") end
    local r7 = project.get_regions_for_parser()
    assert(type(r7) == "table" and #r7 == 0, "Test 7 failed")
    print("Test 7 passed: get_regions_for_parser never returns nil, even on crash")

    -- Restore mock for Test 8
    _G.reaper.CountProjectMarkers = function(proj) return 0, 0, 2 end
    _G.reaper.EnumProjectMarkers = function(i)
        if i == 0 then return 1, true, 10, 20, "CHORUS|loop=inf", 1 end
        if i == 1 then return 1, true, 0, 5, "VERSE_1|next=CHORUS", 2 end
        return 0, false, 0, 0, "", 0
    end

    -- 8. Integração com Regions.parse_regions funciona usando regions simuladas.
    local raw_from_api = project.get_regions_for_parser()
    local parsed_regions = regions_parser.parse_regions(raw_from_api)

    assert(#parsed_regions.sections == 2, "Test 8 failed")
    -- parse_regions sorts by start_pos. VERSE_1 is 0, CHORUS is 10.
    assert(parsed_regions.sections[1].name == "VERSE_1", "Test 8 failed")
    assert(parsed_regions.sections[1].start_pos == 0, "Test 8 failed")
    assert(parsed_regions.sections[2].name == "CHORUS", "Test 8 failed")
    assert(parsed_regions.sections[2].meta.loop == "inf", "Test 8 failed")
    print("Test 8 passed: Integration with regions_parser works and sorts correctly")

    -- Cleanup mock
    _G.reaper = original_reaper

    print("\nProject Adapter tests passed successfully!")
end

run_project_tests()
