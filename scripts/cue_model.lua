--[[
    cue_model.lua
    Pure logic for section cues data management.
--]]

local CueModel = {}

local VALID_TYPES = {
    note = true,
    midi_placeholder = true,
    lyric_placeholder = true,
    light_placeholder = true
}

function CueModel.create_empty()
    return {
        version = 1,
        cues = {},
        warnings = {},
        errors = {}
    }
end

function CueModel.normalize_cue(cue, index)
    if type(cue) ~= "table" then cue = {} end
    local id = tostring(cue.id or "cue_" .. index)
    local section_id = tostring(cue.section_id or "")
    local c_type = tostring(cue.type or "note")
    
    if not VALID_TYPES[c_type] then
        c_type = "note"
    end

    local default_label = "Cue " .. index
    if c_type == "note" then default_label = "Note cue"
    elseif c_type == "midi_placeholder" then default_label = "MIDI cue placeholder"
    elseif c_type == "lyric_placeholder" then default_label = "Lyric cue placeholder"
    elseif c_type == "light_placeholder" then default_label = "Light cue placeholder"
    end

    return {
        id = id,
        section_id = section_id,
        type = c_type,
        label = tostring(cue.label or default_label),
        payload = tostring(cue.payload or ""),
        enabled = cue.enabled ~= false
    }
end

function CueModel.normalize_store(raw)
    local store = CueModel.create_empty()
    if type(raw) ~= "table" then return store end

    store.version = tonumber(raw.version) or 1
    local raw_cues = raw.cues or {}
    
    for i, c in ipairs(raw_cues) do
        local normalized = CueModel.normalize_cue(c, i)
        if c.type and not VALID_TYPES[c.type] then
            table.insert(store.warnings, "invalid_cue_type_normalized: " .. tostring(c.type))
        end
        table.insert(store.cues, normalized)
    end

    return store
end

function CueModel.validate(store)
    local result = { ok = true, warnings = {}, errors = {} }
    if not store then return { ok = false, errors = { "nil_store" } } end

    local ids = {}
    for i, c in ipairs(store.cues) do
        if not c.section_id or c.section_id == "" then
            result.ok = false
            table.insert(result.errors, "missing_section_id at index " .. i)
        end
        if ids[c.id] then
            result.ok = false
            table.insert(result.errors, "duplicate_cue_id: " .. tostring(c.id))
        end
        ids[c.id] = true
        if not VALID_TYPES[c.type] then
            result.ok = false
            table.insert(result.errors, "invalid_cue_type: " .. tostring(c.type))
        end
    end

    return result
end

function CueModel.get_cues(store)
    return store and store.cues or {}
end

function CueModel.get_cues_for_section(store, section_id)
    local out = {}
    if not store or not section_id then return out end
    for _, c in ipairs(store.cues) do
        if c.section_id == section_id then
            table.insert(out, c)
        end
    end
    return out
end

function CueModel.get_enabled_cues_for_section(store, section_id)
    local out = {}
    if not store or not section_id then return out end
    for _, c in ipairs(store.cues) do
        if c.section_id == section_id and c.enabled then
            table.insert(out, c)
        end
    end
    return out
end

function CueModel.add_cue(store, cue)
    if not store or not cue then return store end
    local index = #store.cues + 1
    local normalized = CueModel.normalize_cue(cue, index)
    table.insert(store.cues, normalized)
    return store
end

function CueModel.add_placeholder_cue(store, section_id, cue_type)
    if not store then return nil end
    local index = #store.cues + 1
    local id = "cue_" .. os.time() .. "_" .. index
    local cue = {
        id = id,
        section_id = section_id,
        type = cue_type or "note",
        enabled = true
    }
    return CueModel.add_cue(store, cue)
end

function CueModel.remove_cue(store, cue_id)
    if not store or not cue_id then return { ok = false, reason = "missing_id" } end
    local index = nil
    for i, c in ipairs(store.cues) do
        if c.id == cue_id then
            index = i
            break
        end
    end

    if index then
        table.remove(store.cues, index)
        return { ok = true, store = store, reason = "cue_removed" }
    end
    return { ok = false, store = store, reason = "cue_not_found" }
end

function CueModel.set_cue_enabled(store, cue_id, enabled)
    if not store or not cue_id then return { ok = false, reason = "missing_id" } end
    for _, c in ipairs(store.cues) do
        if c.id == cue_id then
            c.enabled = (enabled == true)
            return { ok = true, store = store, reason = "cue_enabled_set" }
        end
    end
    return { ok = false, store = store, reason = "cue_not_found" }
end

function CueModel.get_cue_by_id(store, cue_id)
    if not store or not cue_id then return nil end
    for _, c in ipairs(store.cues) do
        if c.id == cue_id then return c end
    end
    return nil
end

function CueModel.get_summary(store)
    local cues = CueModel.get_cues(store)
    local enabled = 0
    local disabled = 0
    for _, c in ipairs(cues) do
        if c.enabled then enabled = enabled + 1 else disabled = disabled + 1 end
    end
    return {
        cue_count = #cues,
        enabled_count = enabled,
        disabled_count = disabled
    }
end

return CueModel
