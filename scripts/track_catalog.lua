--[[
    track_catalog.lua
    Classifies tracks by name and prepares the mixer model.
--]]

local TrackCatalog = {}

local CATEGORIES = {
    "click", "guide", "drums", "bass", "keys", "guitars", "vocals", "pads", "tracks", "other"
}

local CATEGORY_LABELS = {
    click = "Click",
    guide = "Guide",
    drums = "Drums",
    bass = "Bass",
    keys = "Keys",
    guitars = "Guitars",
    vocals = "Vocals",
    pads = "Pads",
    tracks = "Tracks",
    other = "Other"
}

function TrackCatalog.classify_track_name(name)
    if not name then return "other" end
    local n = string.lower(name)

    if string.find(n, "click") or string.find(n, "clk") or string.find(n, "metronome") or string.find(n, "metro") then
        return "click"
    end
    if string.find(n, "guide") or string.find(n, "cue") or string.find(n, "guia") then
        return "guide"
    end
    if string.find(n, "drum") or string.find(n, "drums") or string.find(n, "bateria") or string.find(n, "perc") or string.find(n, "percussion") then
        return "drums"
    end
    if string.find(n, "bass") or string.find(n, "baixo") then
        return "bass"
    end
    if string.find(n, "key") or string.find(n, "piano") or string.find(n, "synth") or string.find(n, "organ") then
        return "keys"
    end
    if string.find(n, "guitar") or string.find(n, "gtr") or string.find(n, "viol") or string.find(n, "electric") or string.find(n, "acoustic") then
        return "guitars"
    end
    if string.find(n, "vocal") or string.find(n, "vox") or string.find(n, "bv") or string.find(n, "choir") or string.find(n, "voz") then
        return "vocals"
    end
    if string.find(n, "pad") or string.find(n, "ambient") or string.find(n, "ambience") then
        return "pads"
    end
    if string.find(n, "track") or string.find(n, "stem") or string.find(n, "loop") or string.find(n, "sequence") then
        return "tracks"
    end

    return "other"
end

function TrackCatalog.normalize_track(raw)
    if not raw then return nil end
    local category = TrackCatalog.classify_track_name(raw.name)
    
    local volume_percent = 0
    if type(raw.volume) == "number" then
        volume_percent = math.floor(raw.volume * 100 + 0.5)
    end

    local is_click = (category == "click")
    local is_guide = (category == "guide")
    -- is_stem: true for drums, bass, keys, guitars, vocals, pads, tracks
    local is_stem = not is_click and not is_guide and (category ~= "other")

    return {
        id = raw.id,
        display_index = raw.display_index,
        name = raw.name,
        category = category,
        category_label = CATEGORY_LABELS[category] or "Other",
        volume = raw.volume,
        volume_percent = volume_percent,
        muted = raw.muted == true,
        soloed = raw.soloed == true,
        is_click = is_click,
        is_guide = is_guide,
        is_stem = is_stem,
        ui_label = string.format("[%s] %s", CATEGORY_LABELS[category] or "??", raw.name or "??")
    }
end

function TrackCatalog.build(track_scan_result)
    local catalog = {
        ok = false,
        tracks = {},
        categories = {},
        summary = {
            total_tracks = 0,
            click_count = 0,
            guide_count = 0,
            stem_count = 0,
            muted_count = 0,
            soloed_count = 0
        },
        warnings = {},
        errors = {}
    }

    if not track_scan_result or not track_scan_result.ok then
        catalog.errors = track_scan_result and track_scan_result.errors or { "no_scan_data" }
        return catalog
    end

    for _, cat in ipairs(CATEGORIES) do
        catalog.categories[cat] = {}
    end

    for _, raw in ipairs(track_scan_result.tracks or {}) do
        local normalized = TrackCatalog.normalize_track(raw)
        table.insert(catalog.tracks, normalized)
        table.insert(catalog.categories[normalized.category], normalized)

        catalog.summary.total_tracks = catalog.summary.total_tracks + 1
        if normalized.is_click then catalog.summary.click_count = catalog.summary.click_count + 1 end
        if normalized.is_guide then catalog.summary.guide_count = catalog.summary.guide_count + 1 end
        if normalized.is_stem then catalog.summary.stem_count = catalog.summary.stem_count + 1 end
        if normalized.muted then catalog.summary.muted_count = catalog.summary.muted_count + 1 end
        if normalized.soloed then catalog.summary.soloed_count = catalog.summary.soloed_count + 1 end
    end

    catalog.ok = true
    return catalog
end

function TrackCatalog.get_tracks(catalog)
    return catalog and catalog.tracks or {}
end

function TrackCatalog.get_by_category(catalog, category)
    if not catalog or not catalog.categories then return {} end
    return catalog.categories[category] or {}
end

function TrackCatalog.get_click_tracks(catalog)
    return TrackCatalog.get_by_category(catalog, "click")
end

function TrackCatalog.get_guide_tracks(catalog)
    return TrackCatalog.get_by_category(catalog, "guide")
end

function TrackCatalog.get_stem_tracks(catalog)
    local stems = {}
    for _, cat in ipairs({ "drums", "bass", "keys", "guitars", "vocals", "pads", "tracks" }) do
        local list = TrackCatalog.get_by_category(catalog, cat)
        for _, t in ipairs(list) do table.insert(stems, t) end
    end
    return stems
end

function TrackCatalog.get_summary(catalog)
    return catalog and catalog.summary or {}
end

return TrackCatalog
