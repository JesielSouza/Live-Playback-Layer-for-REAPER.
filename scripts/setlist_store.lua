--[[
    setlist_store.lua
    Local persistence for the setlist using Lua table files.
--]]

local SetlistStore = {}
local SetlistModel = require("scripts.setlist_model")

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
    -- Expecting something like ".../scripts/setlist_store.lua"
    local suffix = "/scripts/setlist_store.lua"
    if module_path:sub(-#suffix) == suffix then
        return module_path:sub(1, -(#suffix + 1))
    end
    -- Fallback: just return the directory containing the module
    return module_path:match("(.*)/")
end

function SetlistStore.get_default_path()
    local module_path = get_module_file_path()
    local root = get_project_root_from_module_path(module_path)
    
    local filename = "live_playback_setlist.lua"
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

function SetlistStore.serialize(setlist)
    if not setlist then return "return {}" end
    local lines = { "return {" }
    table.insert(lines, "  version = " .. (setlist.version or 1) .. ",")
    table.insert(lines, "  current_song_id = \"" .. escape_string(setlist.current_song_id or "") .. "\",")
    table.insert(lines, "  songs = {")
    
    for _, s in ipairs(setlist.songs or {}) do
        table.insert(lines, "    {")
        table.insert(lines, "      id = \"" .. escape_string(s.id or "") .. "\",")
        table.insert(lines, "      title = \"" .. escape_string(s.title or "") .. "\",")
        table.insert(lines, "      artist = \"" .. escape_string(s.artist or "") .. "\",")
        table.insert(lines, "      key = \"" .. escape_string(s.key or "") .. "\",")
        if s.bpm then
            table.insert(lines, "      bpm = " .. s.bpm .. ",")
        else
            table.insert(lines, "      bpm = nil,")
        end
        table.insert(lines, "      duration = \"" .. escape_string(s.duration or "") .. "\",")
        table.insert(lines, "      project_path = \"" .. escape_string(s.project_path or "") .. "\",")
        table.insert(lines, "      notes = \"" .. escape_string(s.notes or "") .. "\",")
        table.insert(lines, "    },")
    end
    
    table.insert(lines, "  }")
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

function SetlistStore.deserialize(content)
    if not content or content == "" then return nil, "empty_content" end
    local chunk, err = load(content, "setlist", "t", {})
    if not chunk and type(loadstring) == "function" then
        -- Fallback for older Lua environments if needed, but "t" is safer
        chunk, err = loadstring(content)
    end
    
    if not chunk then return nil, err end
    
    local success, result = pcall(chunk)
    if not success then return nil, result end
    if type(result) ~= "table" then return nil, "not_a_table" end
    
    return result
end

function SetlistStore.exists(path)
    if not path then return false end
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

function SetlistStore.load(path)
    path = path or SetlistStore.get_default_path()
    if not SetlistStore.exists(path) then
        return { ok = false, reason = "setlist_file_not_found", path = path, errors = { "file_not_found" } }
    end

    local f, err = io.open(path, "r")
    if not f then
        return { ok = false, reason = "setlist_load_failed", path = path, error = tostring(err), errors = { "cannot_open_file" } }
    end
    local content = f:read("*a")
    f:close()

    local raw, d_err = SetlistStore.deserialize(content)
    if not raw then
        return { ok = false, reason = "setlist_load_failed", path = path, error = tostring(d_err), errors = { "deserialize_failed" } }
    end

    local setlist = SetlistModel.normalize_setlist(raw)
    return { ok = true, setlist = setlist, path = path, reason = "setlist_loaded" }
end

function SetlistStore.save(setlist, path)
    path = path or SetlistStore.get_default_path()
    local content = SetlistStore.serialize(setlist)
    local f, err = io.open(path, "w")
    if not f then
        return { 
            ok = false, 
            reason = "setlist_save_failed", 
            path = path, 
            error = tostring(err),
            errors = { "setlist_save_failed" } 
        }
    end
    f:write(content)
    f:close()
    return { ok = true, reason = "setlist_saved", path = path }
end

function SetlistStore.ensure(path)
    path = path or SetlistStore.get_default_path()
    if SetlistStore.exists(path) then
        local res = SetlistStore.load(path)
        if res.ok then return res.setlist end
    end
    
    local default = SetlistModel.create_default()
    local res = SetlistStore.save(default, path)
    if not res.ok then
        -- Return a setlist-like object that indicates failure via errors/warnings
        -- so the UI can at least show what happened
        default.ok = false
        default.reason = res.reason
        default.error = res.error
        default.path = res.path
        table.insert(default.errors, "setlist_save_failed")
        return default
    end
    return default
end

return SetlistStore
