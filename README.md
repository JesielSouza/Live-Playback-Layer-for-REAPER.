# Live Playback Layer for REAPER

A safety-first playback control layer for REAPER, designed for live performance.

## Features

*   **Operator Mode**: A simplified UI for live operation.
*   **Live ReOrder Queue (v0.6)**: Queue up next sections on the fly without altering the project.
*   **Infinite Loop Mode (v0.6)**: Repeat the current or selected section indefinitely.
*   **Setlist / Song Cards**: Manage your repertoire with a local setlist.
*   **Song Map / Visual Timeline**: See your song as a sequence of blocks.
*   **Manual Section Selection**: Click any section on the Song Map to set it as a target.
*   **Mixer / Stems**: Control your tracks directly from the UI.
*   **Section Awareness**: Automatic detection of current and next sections.
*   **Safety Gates**: Multiple layers of validation before any real transport action.
*   **Explicit Execution**: No automatic jumps. All actions require explicit operator intent.

## How to Use

1.  **Prepare your Project**: Create Regions for each section.
2.  **Open the Script**: Run `reaper_ui.lua`.
3.  **Operator Workflow**:
    *   **Live Control**:
        *   **Add to Queue**: Queue up sections to be played in sequence.
        *   **Infinite Loop**: Toggle loop for the current or a selected section.
    *   **Song Map**: Visual navigation. Click to select a target.
    *   **Confirm & Arm**: The safety sequence to enable transport buttons.
    *   **Mixer**: Live control of stems.
    *   **Play/Stop**: Primary transport controls.

## Safety Guarantees

*   **Limited API Whitelist**: Only authorized REAPER APIs are used.
*   **Locked by Default**: Requires explicit Confirmation + Arming.
*   **No Region Mutation**: Live Queue and Loop Mode are purely logical and do not change your project Regions.

## Technical Details

Built with Lua and ReaImGui.

New layers in v0.6:
*   **LiveQueue**: Logic for managing a sequence of upcoming sections.
*   **LoopMode**: Logic for infinite repetition of sections.
*   **UILiveControl**: View model for live performance controls.

See `docs/ARCHITECTURE.md` for more information.
