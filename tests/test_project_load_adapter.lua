local project_load_adapter = require("scripts.project_load_adapter")

local function run_project_load_adapter_tests()
    print("Running project load adapter tests...\n")

    -- 1-3 Availability
    _G.reaper = nil
    assert(project_load_adapter.is_reaper_available() == false, "Test 1 failed")
    local caps = project_load_adapter.get_capabilities()
    assert(caps.can_load_project == false, "Test 2 failed")
    
    _G.reaper = { Main_openProject = function() end }
    caps = project_load_adapter.get_capabilities()
    assert(caps.can_load_project == true, "Test 3 failed")
    print("Test 1-3 passed: Availability checks work")

    -- 4-7 Validation
    local res4 = project_load_adapter.validate_project_path("")
    assert(res4.ok == false and res4.reason == "missing_project_path", "Test 4 failed")
    
    local res5 = project_load_adapter.validate_project_path("song.txt")
    assert(res5.ok == false and res5.reason == "invalid_project_extension", "Test 5 failed")
    
    local res6 = project_load_adapter.validate_project_path("non-existent.rpp")
    assert(res6.ok == false and res6.reason == "project_file_not_found", "Test 6 failed")
    
    local test_path = "tests/tmp_project_load_test.rpp"
    local f = io.open(test_path, "w")
    f:write("REAPER_PROJECT")
    f:close()
    
    local res7 = project_load_adapter.validate_project_path(test_path)
    assert(res7.ok == true and res7.reason == "project_path_valid", "Test 7 failed")
    print("Test 4-7 passed: Path validation works")

    -- 8-14 Loading
    local res8 = project_load_adapter.load_project(test_path, { enable_project_load = false })
    assert(res8.executed == false and res8.reason == "project_load_not_enabled", "Test 8 failed")
    
    local res9 = project_load_adapter.load_project("invalid.rpp", { enable_project_load = true })
    assert(res9.executed == false and res9.reason == "project_file_not_found", "Test 9 failed")
    
    local res10 = project_load_adapter.load_project(test_path, { enable_project_load = true, dry_run = true })
    assert(res10.ok == true and res10.executed == false and res10.reason == "project_load_dry_run", "Test 10 failed")
    
    local open_called = false
    _G.reaper.Main_openProject = function(p) 
        if p == test_path then open_called = true end
    end
    
    local res13 = project_load_adapter.load_project(test_path, { enable_project_load = true })
    assert(res13.ok == true and res13.executed == true and res13.reason == "project_load_executed", "Test 13 failed")
    assert(open_called == true, "Test 13 failed: API not called")
    print("Test 8-14 passed: load_project works with gates and mock")

    -- Cleanup
    os.remove(test_path)
    _G.reaper = nil
    print("\nProject load adapter tests passed successfully!")
end

run_project_load_adapter_tests()
