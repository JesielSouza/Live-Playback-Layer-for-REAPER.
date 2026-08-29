--[[
    cue_store.lua
    Local persistence for section cues using Lua table files.
--]]

local CueStore = {}
local CueModel = require("scripts.cue_model")

local function normalize_path_separator(path)
    if not path then return nil end
    return path:gsub("\\", "/")
end

local function get_module_file_path()
    local info = debug.getinfo(1, "S")
    if not info or not info.source then return nil end
    
    local path = info.source
    if path:sub(1, 1) == "@" then
        path = path:sub(2)
    end
    return normalize_path_separator(path)
end

local function get_project_root_from_module_path(module_path)
    if not module_path then return nil end
    local suffix = "/scripts/cue_store.lua"
    if module_path:sub(-#suffix) == suffix then
        return module_path:sub(1, -(#suffix + 1))
    end
    return module_path:match("(.*)/")
end

function CueStore.get_default_path()
    local module_path = get_module_file_path()
    local root = get_project_root_from_module_path(module_path)
    
    local filename = "live_playback_cues.lua"
    if root and root ~= "" then
        return root .. "/" .. filename
    end
    
    return filename
end

local function escape_string(s)
    if type(s) ~= "string" then return tostring(s) end
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\"", "\\\"")
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    return s
end

function CueStore.serialize(store)
    if not store then return "return {}" end
    local lines = { "return {" }
    table.insert(lines, "  version = " .. (store.version or 1) .. ",")
    table.insert(lines, "  cues = {")
    
    for _, c in ipairs(store.cues or {}) do
        table.insert(lines, "    {")
        table.insert(lines, "      id = \"" .. escape_string(c.id or "") .. "\",")
        table.insert(lines, "      section_id = \"" .. escape_string(c.section_id or "") .. "\",")
        table.insert(lines, "      type = \"" .. escape_string(c.type or "") .. "\",")
        table.insert(lines, "      label = \"" .. escape_string(c.label or "") .. "\",")
        table.insert(lines, "      payload = \"" .. escape_string(c.payload or "") .. "\",")
        table.insert(lines, "      enabled = " .. tostring(c.enabled == true) .. ",")
        table.insert(lines, "    },")
    end
    
    table.insert(lines, "  }")
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

function CueStore.deserialize(content)
    if not content or content == "" then return nil, "empty_content" end
    local chunk, err = load(content, "cues", "t", {})
    if not chunk and type(loadstring) == "function" then
        chunk, err = loadstring(content)
    end
    
    if not chunk then return nil, err end
    
    local success, result = pcall(chunk)
    if not success then return nil, result end
    if type(result) ~= "table" then return nil, "not_a_table" end
    
    return result
end

function CueStore.exists(path)
    if not path then return false end
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

function CueStore.load(path)
    path = path or CueStore.get_default_path()
    if not CueStore.exists(path) then
        return { ok = false, reason = "cue_file_not_found", path = path, errors = { "file_not_found" } }
    end

    local f, err = io.open(path, "r")
    if not f then
        return { ok = false, reason = "cue_load_failed", path = path, error = tostring(err), errors = { "cannot_open_file" } }
    end
    local content = f:read("*a")
    f:close()

    local raw, d_err = CueStore.deserialize(content)
    if not raw then
        return { ok = false, reason = "cue_load_failed", path = path, error = tostring(d_err), errors = { "deserialize_failed" } }
    end

    local store = CueModel.normalize_store(raw)
    return { ok = true, store = store, path = path, reason = "cue_loaded" }
end

function CueStore.save(store, path)
    path = path or CueStore.get_default_path()
    local content = CueStore.serialize(store)
    local f, err = io.open(path, "w")
    if not f then
        return { 
            ok = false, 
            reason = "cue_save_failed", 
            path = path, 
            error = tostring(err),
            errors = { "cue_save_failed" } 
        }
    end
    f:write(content)
    f:close()
    return { ok = true, reason = "cue_saved", path = path }
end

function CueStore.ensure(path)
    path = path or CueStore.get_default_path()
    if CueStore.exists(path) then
        local res = CueStore.load(path)
        if res.ok then return res.store end
    end
    
    local empty = CueModel.create_empty()
    local res = CueStore.save(empty, path)
    if not res.ok then
        empty.ok = false
        empty.reason = res.reason
        empty.error = res.error
        empty.path = res.path
        table.insert(empty.errors, "cue_save_failed")
        return empty
    end
    return empty
end

return CueStore
