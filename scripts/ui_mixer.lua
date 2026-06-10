--[[
    ui_mixer.lua
    Pure logic for building the UI representation of the mixer.
--]]

local UIMixer = {}

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

function UIMixer.build(track_catalog, mixer_state, options)
    options = options or {}
    local ui = {
        ok = false,
        visible = true,
        summary_lines = {},
        categories = {},
        rows = {},
        warnings = {},
        errors = {}
    }

    if not track_catalog or not track_catalog.ok then
        table.insert(ui.errors, "invalid_track_catalog")
        return ui
    end

    ui.visible = (mixer_state and mixer_state.visible ~= false)
    
    local summary = track_catalog.summary or {}
    ui.summary_lines = {
        "Mixer / Stems",
        string.format("Tracks: total=%d stems=%d click=%d guide=%d muted=%d soloed=%d",
            summary.total_tracks or 0,
            summary.stem_count or 0,
            summary.click_count or 0,
            summary.guide_count or 0,
            summary.muted_count or 0,
            summary.soloed_count or 0)
    }

    for _, cat in ipairs(CATEGORIES) do
        local tracks = track_catalog.categories[cat] or {}
        if #tracks > 0 then
            local section = {
                id = cat,
                label = CATEGORY_LABELS[cat] or cat,
                collapsed = mixer_state and mixer_state.collapsed_categories and mixer_state.collapsed_categories[cat] == true,
                track_count = #tracks,
                rows = {}
            }

            for _, t in ipairs(tracks) do
                local row = {
                    track_id = t.id,
                    display_index = t.display_index,
                    name = t.name,
                    category = cat,
                    category_label = section.label,
                    volume = t.volume,
                    volume_percent = t.volume_percent,
                    muted = t.muted,
                    soloed = t.soloed,
                    selected = mixer_state and mixer_state.selected_track_id == t.id,
                    is_click = t.is_click,
                    is_guide = t.is_guide,
                    label = UIMixer.format_track_row({
                        name = t.name,
                        category_label = section.label,
                        display_index = t.display_index,
                        volume_percent = t.volume_percent,
                        muted = t.muted,
                        soloed = t.soloed
                    })
                }
                table.insert(section.rows, row)
                table.insert(ui.rows, row)
            end
            table.insert(ui.categories, section)
        end
    end

    ui.ok = true
    return ui
end

function UIMixer.get_category_sections(ui_mixer)
    return ui_mixer and ui_mixer.categories or {}
end

function UIMixer.get_track_rows(ui_mixer)
    return ui_mixer and ui_mixer.rows or {}
end

function UIMixer.get_summary_lines(ui_mixer)
    return ui_mixer and ui_mixer.summary_lines or {}
end

function UIMixer.format_track_row(row)
    if not row then return "nil" end
    return string.format("[%s] %d %s %d%% MUTE=%s SOLO=%s",
        string.upper(row.category_label or "??"),
        row.display_index or 0,
        row.name or "unknown",
        row.volume_percent or 0,
        tostring(row.muted),
        tostring(row.soloed))
end

function UIMixer.format_category_header(category_section)
    if not category_section then return "nil" end
    return string.format("%s (%d)", category_section.label, category_section.track_count)
end

return UIMixer
