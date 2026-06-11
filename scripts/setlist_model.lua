--[[
    setlist_model.lua
    Pure logic for setlist and song data management.
--]]

local SetlistModel = {}

function SetlistModel.create_empty()
    return {
        version = 1,
        current_song_id = nil,
        songs = {},
        warnings = {},
        errors = {}
    }
end

function SetlistModel.create_default()
    local setlist = SetlistModel.create_empty()
    SetlistModel.add_song(setlist, {
        id = "song_1",
        title = "Current Project",
        artist = "Unknown",
        key = "",
        bpm = nil,
        duration = "",
        project_path = "",
        notes = ""
    })
    return setlist
end

function SetlistModel.normalize_song(song, index)
    if type(song) ~= "table" then song = {} end
    local id = tostring(song.id or "song_" .. index)
    local title = song.title
    if not title or title == "" then
        title = "Untitled Song " .. index
    end

    return {
        id = id,
        title = title,
        artist = tostring(song.artist or "Unknown"),
        key = tostring(song.key or ""),
        bpm = tonumber(song.bpm),
        duration = tostring(song.duration or ""),
        project_path = tostring(song.project_path or ""),
        notes = tostring(song.notes or ""),
        display_index = index
    }
end

function SetlistModel.normalize_setlist(raw)
    local setlist = SetlistModel.create_empty()
    if type(raw) ~= "table" then return setlist end

    setlist.version = tonumber(raw.version) or 1
    
    local raw_songs = raw.songs or {}
    for i, s in ipairs(raw_songs) do
        table.insert(setlist.songs, SetlistModel.normalize_song(s, i))
    end

    local current_id = raw.current_song_id
    if current_id and SetlistModel.get_songs(setlist)[1] then
        local found = false
        for _, s in ipairs(setlist.songs) do
            if s.id == current_id then
                found = true
                break
            end
        end
        if found then
            setlist.current_song_id = current_id
        else
            setlist.current_song_id = setlist.songs[1].id
            table.insert(setlist.warnings, "current_song_not_found")
        end
    elseif #setlist.songs > 0 then
        setlist.current_song_id = setlist.songs[1].id
    end

    return setlist
end

function SetlistModel.get_songs(setlist)
    return setlist and setlist.songs or {}
end

function SetlistModel.get_current_song(setlist)
    if not setlist or not setlist.current_song_id then return nil end
    for _, s in ipairs(setlist.songs) do
        if s.id == setlist.current_song_id then return s end
    end
    return nil
end

function SetlistModel.get_song_by_id(setlist, song_id)
    if not setlist or not song_id then return nil end
    for _, s in ipairs(setlist.songs) do
        if s.id == song_id then return s end
    end
    return nil
end

function SetlistModel.set_current_song(setlist, song_id)
    if not setlist then return end
    for _, s in ipairs(setlist.songs) do
        if s.id == song_id then
            setlist.current_song_id = song_id
            return true
        end
    end
    return false
end

function SetlistModel.get_next_song(setlist)
    if not setlist or not setlist.current_song_id then return nil end
    local current_index = nil
    for i, s in ipairs(setlist.songs) do
        if s.id == setlist.current_song_id then
            current_index = i
            break
        end
    end
    if current_index and current_index < #setlist.songs then
        return setlist.songs[current_index + 1]
    end
    return nil
end

function SetlistModel.get_previous_song(setlist)
    if not setlist or not setlist.current_song_id then return nil end
    local current_index = nil
    for i, s in ipairs(setlist.songs) do
        if s.id == setlist.current_song_id then
            current_index = i
            break
        end
    end
    if current_index and current_index > 1 then
        return setlist.songs[current_index - 1]
    end
    return nil
end

function SetlistModel.move_next(setlist)
    local next_song = SetlistModel.get_next_song(setlist)
    if next_song then
        setlist.current_song_id = next_song.id
        return { ok = true, setlist = setlist, current_song = next_song, reason = "song_moved_next" }
    end
    return { ok = false, setlist = setlist, reason = "no_next_song" }
end

function SetlistModel.move_previous(setlist)
    local prev_song = SetlistModel.get_previous_song(setlist)
    if prev_song then
        setlist.current_song_id = prev_song.id
        return { ok = true, setlist = setlist, current_song = prev_song, reason = "song_moved_previous" }
    end
    return { ok = false, setlist = setlist, reason = "no_previous_song" }
end

function SetlistModel.add_song(setlist, song)
    if not setlist then return end
    local index = #setlist.songs + 1
    local normalized = SetlistModel.normalize_song(song, index)
    table.insert(setlist.songs, normalized)
    if not setlist.current_song_id then
        setlist.current_song_id = normalized.id
    end
    return setlist
end

function SetlistModel.remove_song(setlist, song_id)
    if not setlist then return end
    local index = nil
    for i, s in ipairs(setlist.songs) do
        if s.id == song_id then
            index = i
            break
        end
    end

    if not index then
        table.insert(setlist.warnings, "song_id_to_remove_not_found")
        return setlist
    end

    table.remove(setlist.songs, index)
    
    -- Re-normalize indices
    for i, s in ipairs(setlist.songs) do
        s.display_index = i
    end

    if setlist.current_song_id == song_id then
        if #setlist.songs > 0 then
            setlist.current_song_id = setlist.songs[1].id
        else
            setlist.current_song_id = nil
        end
    end

    return setlist
end

function SetlistModel.reorder_song(setlist, song_id, direction)
    if not setlist then return { ok = false } end
    local index = nil
    for i, s in ipairs(setlist.songs) do
        if s.id == song_id then
            index = i
            break
        end
    end

    if not index then return { ok = false, reason = "song_not_found" } end

    if direction == "up" and index > 1 then
        setlist.songs[index], setlist.songs[index-1] = setlist.songs[index-1], setlist.songs[index]
    elseif direction == "down" and index < #setlist.songs then
        setlist.songs[index], setlist.songs[index+1] = setlist.songs[index+1], setlist.songs[index]
    else
        return { ok = false, reason = "cannot_move_further" }
    end

    -- Re-normalize indices
    for i, s in ipairs(setlist.songs) do
        s.display_index = i
    end

    return { ok = true, setlist = setlist }
end

function SetlistModel.set_song_project_path(setlist, song_id, project_path)
    local song = SetlistModel.get_song_by_id(setlist, song_id)
    if not song then
        return { ok = false, reason = "song_not_found" }
    end

    song.project_path = tostring(project_path or "")
    return { ok = true, setlist = setlist, song = song, reason = "song_project_path_set" }
end

function SetlistModel.song_has_project(song)
    if not song then return false end
    return type(song.project_path) == "string" and song.project_path ~= ""
end

function SetlistModel.get_summary(setlist)
    local current = SetlistModel.get_current_song(setlist)
    return {
        song_count = setlist and #setlist.songs or 0,
        current_song_id = setlist and setlist.current_song_id,
        current_title = current and current.title,
        has_next = SetlistModel.get_next_song(setlist) ~= nil,
        has_previous = SetlistModel.get_previous_song(setlist) ~= nil
    }
end

function SetlistModel.validate(setlist)
    local result = { ok = true, warnings = {}, errors = {} }
    if not setlist then return { ok = false, errors = { "nil_setlist" } } end

    local ids = {}
    for _, s in ipairs(setlist.songs) do
        if ids[s.id] then
            result.ok = false
            table.insert(result.errors, "duplicate_song_id")
        end
        ids[s.id] = true
    end

    return result
end

return SetlistModel
