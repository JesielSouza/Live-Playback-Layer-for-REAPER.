local utils = require("scripts.utils")

local function run_utils_tests()
    print("Running utils tests...\n")

    -- Tests for utils.split
    local function assert_table_eq(t1, t2, msg)
        assert(#t1 == #t2, msg .. ": Length mismatch. Expected " .. #t2 .. ", got " .. #t1)
        for i = 1, #t1 do
            assert(t1[i] == t2[i], msg .. ": Element " .. i .. " mismatch. Expected '" .. tostring(t2[i]) .. "', got '" .. tostring(t1[i]) .. "'")
        end
    end

    -- 1. Standard split
    local result1 = utils.split("a,b,c", ",")
    assert_table_eq(result1, {"a", "b", "c"}, "Standard split failed")
    print("Test passed: utils.split - standard split")

    -- 2. Consecutive delimiters
    local result2 = utils.split("a,,c", ",")
    assert_table_eq(result2, {"a", "", "c"}, "Consecutive delimiters failed")
    print("Test passed: utils.split - consecutive delimiters")

    -- 3. Empty string delimiter
    local result3 = utils.split("abc", "")
    assert_table_eq(result3, {"a", "b", "c"}, "Empty string delimiter failed")
    print("Test passed: utils.split - empty string delimiter")

    -- 4. Missing delimiter (nil)
    local result4 = utils.split("abc", nil)
    assert_table_eq(result4, {"a", "b", "c"}, "Missing delimiter failed")
    print("Test passed: utils.split - missing delimiter")

    -- 5. Edge cases: nil value
    local result5 = utils.split(nil, ",")
    assert_table_eq(result5, {}, "Nil value failed")
    print("Test passed: utils.split - nil value")

    -- 6. Edge cases: invalid value type
    local result6 = utils.split(123, ",")
    assert_table_eq(result6, {}, "Invalid value type failed")
    print("Test passed: utils.split - invalid value type")

    -- 7. Magic characters
    local result7 = utils.split("a.b.c", ".")
    assert_table_eq(result7, {"a", "b", "c"}, "Magic characters failed")
    print("Test passed: utils.split - magic characters")

    -- 8. Delimiter at start
    local result8 = utils.split(",a,b", ",")
    assert_table_eq(result8, {"", "a", "b"}, "Delimiter at start failed")
    print("Test passed: utils.split - delimiter at start")

    -- 9. Delimiter at end
    local result9 = utils.split("a,b,", ",")
    assert_table_eq(result9, {"a", "b", ""}, "Delimiter at end failed")
    print("Test passed: utils.split - delimiter at end")

    -- 10. String with only delimiters
    local result10 = utils.split(",,", ",")
    assert_table_eq(result10, {"", "", ""}, "Only delimiters failed")
    print("Test passed: utils.split - only delimiters")

    -- 11. Multi-char delimiter
    local result11 = utils.split("a||b||c", "||")
    assert_table_eq(result11, {"a", "b", "c"}, "Multi-character delimiter failed")
    print("Test passed: utils.split - multi-character delimiter")

    print("\nUtils tests passed successfully!")
end

run_utils_tests()