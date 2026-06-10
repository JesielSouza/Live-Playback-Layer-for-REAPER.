--[[
    song_map.lua
    Core logic for building a normalized map of song sections.
--]]

local SongMap = {}

local function get_sections_source(snapshot)
    if type(snapshot) ~= "table" then return nil end
    return snapshot.sections 
        or (snapshot.validation and snapshot.validation.sections)
        or (snapshot.context and snapshot.context.validation and snapshot.context.validation.sections)
end

local function normalize_section(raw, index, snapshot)
    local id = tostring(raw.id or raw.key or raw.name or ("section_" .. index))
    local name = tostring(raw.name or raw.id or raw.key or id)
    local label = tostring(raw.label or name)
    
    local start = raw.start or raw.start_time or raw.start_position or raw.start_pos or raw.position or raw.region_start
    local end_pos = raw["end"] or raw.end_time or raw.end_position or raw.end_pos or raw.region_end
    
    local duration = nil
    if type(start) == "number" and type(end_pos) == "number" then
        duration = end_pos - start
    end
    
    local loop = (raw.loop == true or raw.loop == 1 or raw.loop == "1")
    
    local is_current = (snapshot.current_section ~= nil and (id == snapshot.current_section or name == snapshot.current_section))
    local is_next = (snapshot.next_section ~= nil and (id == snapshot.next_section or name == snapshot.next_section))

    return {
        id = id,
        key = raw.key or raw.id,
        name = name,
        label = label,
        start = start,
        end_pos = end_pos,
        duration = duration,
        loop = loop,
        next = raw.next,
        is_current = is_current,
        is_next = is_next,
        is_selected = false
    }
end

function SongMap.build(runtime_snapshot)
    local map = {
        ok = false,
        sections = {},
        current_section = runtime_snapshot and runtime_snapshot.current_section,
        next_section = runtime_snapshot and runtime_snapshot.next_section,
        selected_section = nil,
        errors = {},
        warnings = {}
    }

    local source = get_sections_source(runtime_snapshot)
    if not source or type(source) ~= "table" then
        table.insert(map.errors, "no_sections_found")
        return map
    end

    for i, raw in ipairs(source) do
        table.insert(map.sections, normalize_section(raw, i, runtime_snapshot))
    end

    map.ok = #map.sections > 0
    return map
end

function SongMap.get_sections(song_map)
    return song_map and song_map.sections or {}
end

function SongMap.find_section(song_map, section_id_or_name)
    if not song_map or not section_id_or_name then return nil end
    for _, s in ipairs(song_map.sections) do
        if s.id == section_id_or_name or s.key == section_id_or_name or s.name == section_id_or_name or s.label == section_id_or_name then
            return s
        end
    end
    return nil
end

function SongMap.select_section(song_map, section_id_or_name)
    if not song_map then return nil end
    for _, s in ipairs(song_map.sections) do
        if s.id == section_id_or_name or s.key == section_id_or_name or s.name == section_id_or_name then
            s.is_selected = true
            song_map.selected_section = s.id
        else
            s.is_selected = false
        end
    end
    return song_map
end

function SongMap.build_intent_for_section(song_map, section_id_or_name)
    local section = SongMap.find_section(song_map, section_id_or_name)
    if not section then
        return { ok = false, reason = "section_not_found", errors = { "section_not_found" } }
    end

    if type(section.start) ~= "number" then
        return { ok = false, reason = "missing_target_position", errors = { "missing_target_position" } }
    end

    return {
        ok = true,
        dry_run = false,
        action = "jump_to_section",
        current_section = song_map.current_section,
        target_section = section.name,
        target_position = section.start,
        decision = "MANUAL_SECTION_TARGET",
        executable = false,
        reason = "manual_section_target",
        warnings = {},
        errors = {}
    }
end

function SongMap.build_loop_current_intent(song_map)
    if not song_map or not song_map.current_section then
        return { ok = false, reason = "no_current_section" }
    end
    
    local current = SongMap.find_section(song_map, song_map.current_section)
    if not current or type(current.start) ~= "number" then
        return { ok = false, reason = "missing_target_position" }
    end

    return {
        ok = true,
        dry_run = false,
        action = "loop_current",
        current_section = song_map.current_section,
        target_section = current.name,
        target_position = current.start,
        decision = "LOOP_CURRENT_INTENT",
        executable = false,
        reason = "loop_current_intent",
        warnings = {},
        errors = {}
    }
end

function SongMap.format_section_label(section)
    if not section then return "nil" end
    return section.label or section.name or section.id or "unknown"
end

function SongMap.get_summary(song_map)
    if not song_map then return { section_count = 0 } end
    return {
        section_count = #song_map.sections,
        current_section = song_map.current_section,
        next_section = song_map.next_section,
        selected_section = song_map.selected_section
    }
end

return SongMap
