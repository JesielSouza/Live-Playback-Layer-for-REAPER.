local logger = require("scripts.logger")

local function run_logger_tests()
    print("Running logger tests...\n")

    local TMP_FILE = "tests/tmp_logger_output.jsonl"
    os.remove(TMP_FILE) -- Clean up before test
    logger.configure({ file_path = nil })
    logger.clear()

    -- 1. clear clears events
    logger.info("TEST", {a=1})
    assert(#logger.get_events() == 1, "Test 1a failed")
    logger.clear()
    assert(#logger.get_events() == 0, "Test 1b failed")
    print("Test 1 passed: logger.clear() clears events")

    -- 2. info creates INFO event
    local e_info = logger.info("START", {ok = true})
    assert(e_info.level == "INFO", "Test 2 failed")
    assert(e_info.event == "START", "Test 2 failed")
    assert(e_info.payload.ok == true, "Test 2 failed")
    print("Test 2 passed: logger.info() creates event with INFO level")

    -- 3. warn creates WARN event
    local e_warn = logger.warn("LOW_MEM", {})
    assert(e_warn.level == "WARN", "Test 3 failed")
    assert(e_warn.event == "LOW_MEM", "Test 3 failed")
    print("Test 3 passed: logger.warn() creates event with WARN level")

    -- 4. error creates ERROR event
    local e_error = logger.error("CRASH", {code = 500})
    assert(e_error.level == "ERROR", "Test 4 failed")
    assert(e_error.event == "CRASH", "Test 4 failed")
    print("Test 4 passed: logger.error() creates event with ERROR level")

    -- 5. log with BAD level normalizes to INFO and preserves invalid_level
    local e_bad = logger.log("WEIRD", "ALIENS", {foo = "bar"})
    assert(e_bad.level == "INFO", "Test 5 failed")
    assert(e_bad.payload.invalid_level == "WEIRD", "Test 5 failed")
    assert(e_bad.payload.foo == "bar", "Test 5 failed")
    print("Test 5 passed: invalid level normalizes to INFO and sets invalid_level")

    -- 6. serialize_event generates correct JSON string structure
    local e_ser = logger.create_event("INFO", "PING", {num = 42, bool = false, text = "hi", nil_val = nil})
    local json_str = logger.serialize_event(e_ser)
    assert(string.find(json_str, '"level":"INFO"'), "Test 6 failed")
    assert(string.find(json_str, '"event":"PING"'), "Test 6 failed")
    assert(string.find(json_str, '"payload":{'), "Test 6 failed")
    assert(string.find(json_str, '"num":42'), "Test 6 failed")
    assert(string.find(json_str, '"bool":false'), "Test 6 failed")
    assert(string.find(json_str, '"text":"hi"'), "Test 6 failed")
    print("Test 6 passed: serialize_event generates expected JSON structure")

    -- 7. Strings with quotes and escapes serialize properly
    local e_esc = logger.create_event("INFO", "QUOTE", {text = 'say "hello"'})
    local json_esc = logger.serialize_event(e_esc)
    assert(string.find(json_esc, '\\"hello\\"'), "Test 7 failed")
    print("Test 7 passed: string escaping handles quotes correctly")

    -- 8. serialize_events serializes multiple lines
    local evs = {
        logger.create_event("INFO", "E1", {}),
        logger.create_event("WARN", "E2", {})
    }
    local multi = logger.serialize_events(evs)
    local num_lines = 1
    for i in string.gmatch(multi, "\n") do
        num_lines = num_lines + 1
    end
    assert(num_lines == 2, "Test 8 failed")
    print("Test 8 passed: serialize_events handles multiple records")

    -- 9. write_line without file_path doesn't fail
    local w_res = logger.write_line("hello")
    assert(w_res == true, "Test 9 failed")
    print("Test 9 passed: write_line without file_path handles safely")

    -- 10. flush with file_path writes lines
    logger.clear()
    logger.configure({ file_path = TMP_FILE })
    logger.info("MSG1", {a = 1})
    logger.info("MSG2", {b = 2})

    local flush_res, flush_err = logger.flush()
    assert(flush_res == true, "Test 10 failed")

    local f = io.open(TMP_FILE, "r")
    assert(f ~= nil, "Test 10 failed (file not created)")
    local content = f:read("*a")
    f:close()

    assert(string.find(content, "MSG1"), "Test 10 failed")
    assert(string.find(content, "MSG2"), "Test 10 failed")
    print("Test 10 passed: flush writes to configured file path")

    -- 11. flush clears memory correctly
    assert(#logger.get_events() == 0, "Test 11 failed")
    print("Test 11 passed: flush clears memory automatically")

    -- Cleanup
    os.remove(TMP_FILE)

    print("\nLogger tests passed successfully!")
end

run_logger_tests()
