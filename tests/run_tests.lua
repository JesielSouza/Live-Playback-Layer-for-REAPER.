-- Script to run pure Lua tests without external framework.
-- Ensure we can load scripts relative to the repository root.

local function setup_path()
    local path = string.gsub(debug.getinfo(1).source, "^@(.+/)[^/]+$", "%1")
    package.path = package.path .. ";" .. path .. "../?.lua"
end

setup_path()

-- Run tests
require("tests.test_regions")
