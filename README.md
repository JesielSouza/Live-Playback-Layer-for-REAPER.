# Live Playback Layer for REAPER

A safety-first playback control layer for REAPER, designed for live performance.

## Features

*   **Operator Mode**: A simplified UI for live operation.
*   **Setlist / Song Cards (v0.4)**: Manage your repertoire with a local setlist.
    *   **Persistent Storage**: Setlist is saved to `live_playback_setlist.lua`.
    *   **Song Metadata**: Track title, artist, BPM, key, and duration.
    *   **Navigation**: Quick jump between songs in the setlist.
*   **Song Map / Visual Timeline**: See your song as a sequence of blocks.
*   **Manual Section Selection**: Click any section on the Song Map to set it as the next target.
*   **Mixer / Stems**: Control your tracks directly from the UI.
    *   **Automatic Classification**: Tracks are categorized by name.
    *   **Mute/Solo/Volume**: Dedicated controls for each stem.
*   **Section Awareness**: Automatic detection of current and next sections.
*   **Safety Gates**: Multiple layers of validation before any real transport action.
*   **Explicit Execution**: No automatic jumps. All actions require explicit operator intent.

## How to Use

1.  **Prepare your Project**:
    *   Create **Regions** for each section.
    *   Name your **Tracks** clearly.
2.  **Setlist Management**:
    *   The script creates a default `live_playback_setlist.lua` in your project folder.
    *   Use the UI to navigate between songs.
    *   *Note: Automatic project loading is not enabled yet. Navigation is logical only.*
3.  **Open the Script**: Run `reaper_ui.lua`.
4.  **Operator Workflow**:
    *   **Confirm & Arm**: Safety sequence for transport.
    *   **Mixer**: Live control of stems.
    *   **Song Map**: Visual navigation.

## Safety Guarantees

*   **Limited API Whitelist**: Only authorized REAPER APIs are used.
*   **Locked by Default**: Requires explicit Confirmation + Arming.
*   **Explicit Mixer**: Writes happen only on button clicks.

## Technical Details

Built with Lua and ReaImGui.

New layers in v0.4:
*   **SetlistModel**: Logic for song and list management.
*   **SetlistStore**: Persistence using Lua table serialization.
*   **UISetlist**: View model for song cards.

See `docs/ARCHITECTURE.md` for more information.
