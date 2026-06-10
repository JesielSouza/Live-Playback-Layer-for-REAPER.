--[[
    track_adapter.lua
    Isolates REAPER track and mixer APIs.
--]]

local TrackAdapter = {}

function TrackAdapter.is_reaper_available()
    return _G.reaper ~= nil
end

function TrackAdapter.get_capabilities()
    local available = TrackAdapter.is_reaper_available()
    local r = available and _G.reaper or {}

    return {
        reaper_available = available,
        can_scan_tracks = available and type(r.CountTracks) == "function",
        can_read_track_names = available and type(r.GetTrackName) == "function",
        can_read_volume = available and type(r.GetMediaTrackInfo_Value) == "function",
        can_set_volume = available and type(r.SetMediaTrackInfo_Value) == "function",
        can_read_mute = available and type(r.GetMediaTrackInfo_Value) == "function",
        can_set_mute = available and type(r.SetMediaTrackInfo_Value) == "function",
        can_read_solo = available and type(r.GetMediaTrackInfo_Value) == "function",
        can_set_solo = available and type(r.SetMediaTrackInfo_Value) == "function",
        can_create_delete_tracks = false,
        warnings = {},
        errors = {}
    }
end

function TrackAdapter.scan_tracks(options)
    local caps = TrackAdapter.get_capabilities()
    if not caps.can_scan_tracks then
        return { ok = false, tracks = {}, count = 0, reason = "reaper_not_available" }
    end

    local r = _G.reaper
    local track_count = r.CountTracks(0)
    local tracks = {}

    for i = 0, track_count - 1 do
        local track = r.GetTrack(0, i)
        if track then
            local _, name = r.GetTrackName(track)
            if not name or name == "" then
                name = "Track " .. (i + 1)
            end

            local volume = r.GetMediaTrackInfo_Value(track, "D_VOL")
            local muted = r.GetMediaTrackInfo_Value(track, "B_MUTE") == 1
            local soloed = r.GetMediaTrackInfo_Value(track, "I_SOLO") > 0

            local volume_db = nil
            if volume and volume > 0 then
                volume_db = 20 * math.log(volume, 10)
            elseif volume == 0 then
                volume_db = -120 -- representation for -inf
            end

            table.insert(tracks, {
                id = i,
                display_index = i + 1,
                name = name,
                category = "unknown", -- to be classified by TrackCatalog
                volume = volume,
                volume_db = volume_db,
                muted = muted,
                soloed = soloed,
                is_click = false,
                is_guide = false,
                is_stem = false,
                raw_ptr = track -- stored for session use but hidden from UI logic
            })
        end
    end

    return {
        ok = true,
        tracks = tracks,
        count = #tracks,
        warnings = {},
        errors = {}
    }
end

function TrackAdapter.set_track_mute(track_id, muted, options)
    options = options or {}
    if not options.enable_mixer_write then
        return { ok = false, executed = false, reason = "mixer_write_not_enabled" }
    end

    local caps = TrackAdapter.get_capabilities()
    if not caps.reaper_available then
        return { ok = false, executed = false, reason = "reaper_not_available" }
    end

    if not caps.can_set_mute then
        return { ok = false, executed = false, reason = "set_track_info_not_available" }
    end

    local r = _G.reaper
    local track = r.GetTrack(0, track_id)
    if not track then
        return { ok = false, executed = false, reason = "track_not_found" }
    end

    r.SetMediaTrackInfo_Value(track, "B_MUTE", muted and 1 or 0)

    return {
        ok = true,
        executed = true,
        action = "set_track_mute",
        track_id = track_id,
        value = muted,
        reason = "track_mute_set"
    }
end

function TrackAdapter.set_track_solo(track_id, soloed, options)
    options = options or {}
    if not options.enable_mixer_write then
        return { ok = false, executed = false, reason = "mixer_write_not_enabled" }
    end

    local caps = TrackAdapter.get_capabilities()
    if not caps.reaper_available then
        return { ok = false, executed = false, reason = "reaper_not_available" }
    end

    if not caps.can_set_solo then
        return { ok = false, executed = false, reason = "set_track_info_not_available" }
    end

    local r = _G.reaper
    local track = r.GetTrack(0, track_id)
    if not track then
        return { ok = false, executed = false, reason = "track_not_found" }
    end

    -- I_SOLO: 0=none, 1=solo, 2=solo-in-place
    r.SetMediaTrackInfo_Value(track, "I_SOLO", soloed and 1 or 0)

    return {
        ok = true,
        executed = true,
        action = "set_track_solo",
        track_id = track_id,
        value = soloed,
        reason = "track_solo_set"
    }
end

function TrackAdapter.set_track_volume(track_id, volume, options)
    options = options or {}
    if not options.enable_mixer_write then
        return { ok = false, executed = false, reason = "mixer_write_not_enabled" }
    end

    local caps = TrackAdapter.get_capabilities()
    if not caps.reaper_available then
        return { ok = false, executed = false, reason = "reaper_not_available" }
    end

    if not caps.can_set_volume then
        return { ok = false, executed = false, reason = "set_track_info_not_available" }
    end

    if type(volume) ~= "number" then
        return { ok = false, executed = false, reason = "invalid_volume_type" }
    end

    -- Clamp 0.0 to 2.0 (approx +6dB)
    local clamped_volume = math.max(0.0, math.min(2.0, volume))

    local r = _G.reaper
    local track = r.GetTrack(0, track_id)
    if not track then
        return { ok = false, executed = false, reason = "track_not_found" }
    end

    r.SetMediaTrackInfo_Value(track, "D_VOL", clamped_volume)

    return {
        ok = true,
        executed = true,
        action = "set_track_volume",
        track_id = track_id,
        value = clamped_volume,
        reason = "track_volume_set"
    }
end

function TrackAdapter.format_track(track)
    if not track then return "nil" end
    return string.format("[%d] %s (vol=%.2f, mute=%s, solo=%s)", 
        track.display_index or 0, 
        track.name or "unknown", 
        track.volume or 0, 
        tostring(track.muted), 
        tostring(track.soloed))
end

function TrackAdapter.format_result(result)
    result = result or {}
    return string.format("Action: %s, Track: %s, Result: %s, Reason: %s", 
        tostring(result.action), 
        tostring(result.track_id), 
        tostring(result.ok), 
        tostring(result.reason))
end

return TrackAdapter
