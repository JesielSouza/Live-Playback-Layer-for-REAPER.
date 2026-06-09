local validator = require("scripts.validator")

local function run_validator_tests()
    print("Running validator tests...\n")

    -- Helper to check if a value is in a table
    local function has_value(tab, val)
        for index, value in ipairs(tab) do
            if value == val then
                return true
            end
        end
        return false
    end

    -- 1. Missing project scan
    local r1 = validator.validate_project(nil)
    assert(r1.ok == false, "Test 1 failed")
    assert(r1.status == validator.STATUS.BLOCKED, "Test 1 failed")
    assert(has_value(r1.errors, validator.ERRORS.MISSING_PROJECT_SCAN), "Test 1 failed")
    print("Test 1 passed: missing_project_scan")

    -- 2. Project scan error
    local scan_err = {
        errors = {"some API failure"},
        regions = {}
    }
    local r2 = validator.validate_project(scan_err)
    assert(r2.ok == false, "Test 2 failed")
    assert(r2.status == validator.STATUS.BLOCKED, "Test 2 failed")
    assert(has_value(r2.errors, validator.ERRORS.PROJECT_SCAN_ERROR), "Test 2 failed")
    print("Test 2 passed: project_scan_error")

    -- 3. Missing regions
    local scan_noregions = {
        regions = {}
    }
    local r3 = validator.validate_project(scan_noregions)
    assert(r3.ok == false, "Test 3 failed")
    assert(r3.status == validator.STATUS.BLOCKED, "Test 3 failed")
    assert(has_value(r3.errors, validator.ERRORS.MISSING_REGIONS), "Test 3 failed")
    print("Test 3 passed: missing_regions")

    -- 4. No valid sections (only invalid regions)
    local scan_invalid = {
        regions = {
            { name = "  ", start_pos = 10, end_pos = 20, index = 1 }
        }
    }
    local r4 = validator.validate_project(scan_invalid)
    assert(r4.ok == false, "Test 4 failed")
    assert(r4.status == validator.STATUS.BLOCKED, "Test 4 failed")
    assert(has_value(r4.errors, validator.ERRORS.NO_VALID_SECTIONS), "Test 4 failed")
    assert(has_value(r4.warnings, validator.WARNINGS.INVALID_REGIONS_IGNORED), "Test 4 failed")
    print("Test 4 passed: no_valid_sections and invalid_regions_ignored")

    -- 5. Invalid region timing (start >= end)
    local scan_timing = {
        regions = {
            { name = "INTRO", start_pos = 20, end_pos = 10, index = 1 }
        }
    }
    local r5 = validator.validate_project(scan_timing)
    assert(r5.ok == false, "Test 5 failed")
    assert(r5.status == validator.STATUS.BLOCKED, "Test 5 failed")
    assert(has_value(r5.errors, validator.ERRORS.INVALID_REGION_TIMING), "Test 5 failed")
    print("Test 5 passed: invalid_region_timing")

    -- 6. Regions out of order
    local scan_order = {
        regions = {
            { name = "CHORUS", start_pos = 20, end_pos = 30, index = 1 },
            { name = "VERSE", start_pos = 10, end_pos = 20, index = 2 }
        }
    }
    local r6 = validator.validate_project(scan_order)
    -- It should actually be valid, just with a warning
    assert(r6.ok == true, "Test 6 failed")
    assert(r6.status == validator.STATUS.WARNING, "Test 6 failed")
    assert(has_value(r6.warnings, validator.WARNINGS.REGIONS_OUT_OF_ORDER), "Test 6 failed")
    print("Test 6 passed: regions_out_of_order")

    -- 7. Duplicate section names
    local scan_dup = {
        regions = {
            { name = "INTRO", start_pos = 0, end_pos = 10, index = 1 },
            { name = "INTRO", start_pos = 10, end_pos = 20, index = 2 }
        }
    }
    local r7 = validator.validate_project(scan_dup)
    assert(r7.ok == true, "Test 7 failed")
    assert(r7.status == validator.STATUS.WARNING, "Test 7 failed")
    assert(has_value(r7.warnings, validator.WARNINGS.DUPLICATE_SECTION_NAMES), "Test 7 failed")
    print("Test 7 passed: duplicate_section_names")

    -- 8. Parser warning
    local scan_pw = {
        regions = {
            { name = "VERSE|loop=abc", start_pos = 0, end_pos = 10, index = 1 }
        }
    }
    local r8 = validator.validate_project(scan_pw)
    assert(r8.ok == true, "Test 8 failed")
    assert(r8.status == validator.STATUS.WARNING, "Test 8 failed")
    assert(has_value(r8.warnings, validator.WARNINGS.PARSER_WARNING), "Test 8 failed")
    print("Test 8 passed: parser_warning")

    -- 9. REAPER not available warning passed down from project_scan
    local scan_rn = {
        warnings = { "REAPER is not available. Running in simulated or disconnected environment." },
        regions = {
            { name = "OUTRO", start_pos = 0, end_pos = 10, index = 1 }
        }
    }
    local r9 = validator.validate_project(scan_rn)
    assert(r9.ok == true, "Test 9 failed")
    assert(r9.status == validator.STATUS.WARNING, "Test 9 failed")
    assert(has_value(r9.warnings, validator.WARNINGS.REAPER_NOT_AVAILABLE), "Test 9 failed")
    print("Test 9 passed: reaper_not_available")

    -- 10. Fully valid and READY
    local scan_ok = {
        regions = {
            { name = "VERSE|loop=1", start_pos = 0, end_pos = 10, index = 1 },
            { name = "CHORUS", start_pos = 10, end_pos = 20, index = 2 }
        }
    }
    local r10 = validator.validate_project(scan_ok)
    assert(r10.ok == true, "Test 10 failed")
    assert(r10.status == validator.STATUS.READY, "Test 10 failed")
    assert(#r10.errors == 0, "Test 10 failed")
    assert(#r10.warnings == 0, "Test 10 failed")
    assert(#r10.sections == 2, "Test 10 failed")
    print("Test 10 passed: completely valid ready status")

    print("\nValidator tests passed successfully!")
end

run_validator_tests()
