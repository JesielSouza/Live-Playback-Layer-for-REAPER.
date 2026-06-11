# Live Playback Layer for REAPER

A safety-first playback control layer for REAPER, designed for live performance.

## Features

*   **Operator Mode**: A simplified UI for live operation.
*   **Section Cues (v0.7)**: Plan and visualize notes, lyrics, and MIDI placeholders for each song section.
    *   **Persistent Storage**: Cues are saved to `live_playback_cues.lua`.
    *   **Visual-Only**: Cues are for planning and cues-viewing only in this version; no MIDI is sent.
*   **Live ReOrder Queue**: Queue up next sections on the fly without altering the project.
*   **Infinite Loop Mode**: Repeat the current or selected section indefinitely.
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
    *   **Section Cues**: Add notes or placeholders to your sections to help guide your performance.
    *   **Live Control**: Add sections to the queue or enable loops.
    *   **Song Map**: Visual navigation. Click to select a target.
    *   **Confirm & Arm**: The safety sequence to enable transport buttons.
    *   **Mixer**: Live control of stems.
    *   **Play/Stop**: Primary transport controls.

## Safety Guarantees

*   **Limited API Whitelist**: Only authorized REAPER APIs are used.
*   **Locked by Default**: Requires explicit Confirmation + Arming.
*   **Planned Cues**: Section cues are non-functional placeholders in this version.

## Technical Details

Built with Lua and ReaImGui.

New layers in v0.7:
*   **CueModel**: Logic for managing section-based performance cues.
*   **CueStore**: Persistence for cues data.
*   **UICues**: View model for rendering cues in the UI.

See `docs/ARCHITECTURE.md` for more information.
