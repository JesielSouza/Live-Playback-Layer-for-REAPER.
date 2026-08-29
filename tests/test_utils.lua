local utils = require("scripts.utils")

local function run_utils_tests()
    print("Running utils tests...\n")

    -- 1. Happy paths: removing spaces
    assert(utils.trim("hello") == "hello", "Test 1 failed")
    assert(utils.trim("  hello") == "hello", "Test 2 failed")
    assert(utils.trim("hello  ") == "hello", "Test 3 failed")
    assert(utils.trim("  hello  ") == "hello", "Test 4 failed")
    assert(utils.trim("  hello world  ") == "hello world", "Test 5 failed")
    print("Tests 1-5 passed: basic trimming works")

    -- 2. Edge cases: tabs and newlines, empty string, all spaces
    assert(utils.trim("") == "", "Test 6 failed")
    assert(utils.trim("   ") == "", "Test 7 failed")
    assert(utils.trim("\thello\t") == "hello", "Test 8 failed")
    assert(utils.trim("\nhello\n") == "hello", "Test 9 failed")
    assert(utils.trim(" \t\n hello world \n\t ") == "hello world", "Test 10 failed")
    print("Tests 6-10 passed: edge cases and whitespace variants work")

    -- 3. Error condition handling: passing non-strings
    assert(utils.trim(nil) == nil, "Test 11 failed")
    assert(utils.trim(42) == 42, "Test 12 failed")
    assert(utils.trim(true) == true, "Test 13 failed")

    local t = {}
    assert(utils.trim(t) == t, "Test 14 failed")
    print("Tests 11-14 passed: non-string values pass through unmodified")

    -- Testing other functions in utils to be comprehensive (optional, but good practice)
    -- utils.split
    local s1 = utils.split("a,b,c", ",")
    assert(#s1 == 3 and s1[1] == "a" and s1[2] == "b" and s1[3] == "c", "Test 15 failed")
    local s2 = utils.split("hello", "")
    assert(#s2 == 5 and s2[1] == "h" and s2[5] == "o", "Test 16 failed")

    -- utils.upper_snake
    assert(utils.upper_snake("hello world") == "HELLO_WORLD", "Test 17 failed")
    assert(utils.upper_snake("  hello \t world  ") == "HELLO_WORLD", "Test 18 failed")

    -- utils.shallow_copy
    local orig = {a = 1, b = 2}
    local copy = utils.shallow_copy(orig)
    assert(copy ~= orig, "Test 19 failed")
    assert(copy.a == 1 and copy.b == 2, "Test 20 failed")

    -- utils.to_json (basic)
    assert(utils.to_json(42) == "42", "Test 21 failed")
    assert(utils.to_json("test") == '"test"', "Test 22 failed")
    assert(utils.to_json(true) == "true", "Test 23 failed")
    assert(utils.to_json(nil) == "null", "Test 24 failed")

    print("\nUtils tests passed successfully!")
end

run_utils_tests()
