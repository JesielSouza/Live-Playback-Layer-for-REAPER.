--[[
    ui_setlist.lua
    Pure logic for building the UI representation of the setlist.
--]]

local UISetlist = {}
local SetlistModel = require("scripts.setlist_model")

function UISetlist.build(setlist, options)
    options = options or {}
    local ui = {
        ok = false,
        cards = {},
        current_song_id = setlist and setlist.current_song_id,
        summary_lines = {},
        warnings = {},
        errors = {}
    }

    if not setlist then
        table.insert(ui.errors, "nil_setlist")
        return ui
    end

    local songs = SetlistModel.get_songs(setlist)
    for i, s in ipairs(songs) do
        local is_current = (s.id == setlist.current_song_id)
        local card = {
            id = s.id,
            display_index = i,
            title = s.title,
            artist = s.artist,
            key = s.key,
            bpm = s.bpm,
            duration = s.duration,
            project_path = s.project_path,
            notes = s.notes,
            is_current = is_current,
            has_project_path = (s.project_path ~= nil and s.project_path ~= ""),
            label = UISetlist.format_card({
                title = s.title,
                artist = s.artist,
                key = s.key,
                bpm = s.bpm,
                duration = s.duration,
                is_current = is_current,
                index = i
            })
        }
        table.insert(ui.cards, card)
    end

    ui.summary_lines = UISetlist.format_summary(ui)
    ui.ok = true
    return ui
end

function UISetlist.get_cards(ui_setlist)
    return ui_setlist and ui_setlist.cards or {}
end

function UISetlist.get_current_card(ui_setlist)
    if not ui_setlist then return nil end
    for _, c in ipairs(ui_setlist.cards) do
        if c.is_current then return c end
    end
    return nil
end

function UISetlist.get_summary_lines(ui_setlist)
    return ui_setlist and ui_setlist.summary_lines or {}
end

function UISetlist.format_card(card)
    if not card then return "nil" end
    local prefix = card.is_current and "▶ " or "  "
    local bpm_text = card.bpm and string.format(" | %d BPM", card.bpm) or ""
    local key_text = (card.key and card.key ~= "") and string.format(" | Key %s", card.key) or ""
    local duration_text = (card.duration and card.duration ~= "") and string.format(" | %s", card.duration) or ""

    return string.format("%s%d. %s — %s%s%s%s",
        prefix,
        card.index or 0,
        card.title or "unknown",
        card.artist or "Unknown",
        key_text,
        bpm_text,
        duration_text)
end

function UISetlist.format_summary(ui_setlist)
    if not ui_setlist then return { "Setlist: none" } end
    local current = UISetlist.get_current_card(ui_setlist)
    local current_index = current and current.display_index or 0
    local total = #ui_setlist.cards

    return {
        "Setlist",
        string.format("Songs: %d", total),
        string.format("Current: %s", current and current.title or "none"),
        string.format("Previous: %s", (current_index > 1) and "yes" or "no"),
        string.format("Next: %s", (current_index > 0 and current_index < total) and "yes" or "no")
    }
end

return UISetlist
