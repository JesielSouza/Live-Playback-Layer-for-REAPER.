-- Script to run pure Lua tests without external framework.
-- Ensure we can load scripts relative to the repository root.

local function setup_path()
    local path = string.gsub(debug.getinfo(1).source, "^@(.+/)[^/]+$", "%1")
    package.path = package.path .. ";" .. path .. "../?.lua"
end

setup_path()

-- Run tests
require("tests.test_regions")
print("--------------------------------------------------")
require("tests.test_project")
print("--------------------------------------------------")
require("tests.test_state")
print("--------------------------------------------------")
require("tests.test_validator")
print("--------------------------------------------------")
require("tests.test_bootstrap")
print("--------------------------------------------------")
require("tests.test_logger")
print("--------------------------------------------------")
require("tests.test_debug_runner")
print("--------------------------------------------------")
require("tests.test_navigation")
print("--------------------------------------------------")
require("tests.test_position")
print("--------------------------------------------------")
require("tests.test_runtime")
print("--------------------------------------------------")
require("tests.test_reaper_smoke_test")
