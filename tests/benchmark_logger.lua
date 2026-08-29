local logger = require("scripts.logger")
local os = require("os")

local TMP_FILE = "tests/benchmark_output.jsonl"
logger.configure({ file_path = TMP_FILE })

local function run_benchmark()
    os.remove(TMP_FILE)

    local start_time = os.clock()
    for i = 1, 10000 do
        logger.write_line("Line " .. i)
    end
    local end_time = os.clock()

    print("write_line Time taken: " .. (end_time - start_time) .. " seconds")

    os.remove(TMP_FILE)

    start_time = os.clock()
    for i = 1, 10000 do
        logger.info("BENCHMARK", { iteration = i })
        logger.flush()
    end
    end_time = os.clock()

    print("flush Time taken: " .. (end_time - start_time) .. " seconds")

    os.remove(TMP_FILE)
end

run_benchmark()
