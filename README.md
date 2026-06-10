# Live Playback Layer for REAPER

A safety-first playback control layer for REAPER, designed for live performance.

## Features

*   **Operator Mode**: A simplified UI for live operation.
*   **Song Map / Visual Timeline**: See your song as a sequence of blocks.
*   **Manual Section Selection**: Click any section on the Song Map to set it as the next target.
*   **Mixer / Stems**: Control your tracks directly from the UI.
    *   **Automatic Classification**: Tracks are categorized by name (Click, Guide, Drums, Bass, etc.).
    *   **Mute/Solo/Volume**: Dedicated controls for each stem.
*   **Section Awareness**: Automatic detection of current and next sections based on project Regions.
*   **Safety Gates**: Multiple layers of validation before any real transport action is taken.
*   **Explicit Execution**: No automatic jumps. All actions (Move, Seek, Play, Stop) require explicit operator intent.
*   **Dry-run Validation**: Every intent is simulated and audited before execution.

## How to Use

1.  **Prepare your Project**:
    *   Create **Regions** for each section of your song (e.g., "INTRO", "VERSE_1", "CHORUS_1").
    *   Name your **Tracks** clearly (e.g., "CLICK", "GUIDE", "DRUMS", "BASS", "KEYS", "GTR", "VOX").
2.  **Open the Script**:
    *   In REAPER, go to `Actions > Show action list`.
    *   Search for `reaper_ui.lua`.
    *   Run the script.
3.  **Operator Workflow**:
    *   **Song Map**: Visual timeline for navigation. Click to select a target.
    *   **Confirm & Arm**: The safety sequence to enable transport buttons.
    *   **Mixer**: Adjust levels and states of your stems during the performance.
    *   **Play/Stop**: Primary transport controls.

## Safety Guarantees

*   **No `Main_OnCommand`**: We use specific REAPER APIs for transport and mixer control.
*   **Limited API Whitelist**: Only authorized APIs are used for real actions.
*   **Locked by Default**: Transport actions require explicit Confirmation + Arming.
*   **Explicit Mixer**: Mixer writes only happen on explicit button clicks.

## Technical Details

Built with Lua and ReaImGui.

New layers in v0.3:
*   **TrackAdapter**: Isolates REAPER track and mixer APIs.
*   **TrackCatalog**: Classifies tracks into musical categories.
*   **UIMixer**: Models the visual mixer representation.

See `docs/ARCHITECTURE.md` for more information.
