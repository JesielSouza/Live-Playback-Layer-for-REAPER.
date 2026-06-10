# Live Playback Layer for REAPER

A safety-first playback control layer for REAPER, designed for live performance.

## Features

*   **Operator Mode**: A simplified UI for live operation.
*   **Song Map / Visual Timeline**: See your song as a sequence of blocks.
*   **Manual Section Selection**: Click any section on the Song Map to set it as the next target.
*   **Section Awareness**: Automatic detection of current and next sections based on project Regions.
*   **Safety Gates**: Multiple layers of validation before any real transport action is taken.
*   **Explicit Execution**: No automatic jumps. All actions require explicit operator intent.
*   **Dry-run Validation**: Every intent is simulated and audited before execution.

## How to Use

1.  **Prepare your Project**:
    *   Create **Regions** for each section of your song (e.g., "INTRO", "VERSE_1", "CHORUS_1").
    *   Ensure regions are contiguous and well-named.
2.  **Open the Script**:
    *   In REAPER, go to `Actions > Show action list`.
    *   Search for `reaper_ui.lua`.
    *   Run the script.
3.  **Operator Workflow**:
    *   **Song Map**: The visual timeline shows all sections.
        *   `> SECTION`: Current playing section.
        *   `>> SECTION`: Automatic next target.
        *   `* SECTION`: Manually selected target.
    *   **Manual Selection**: Click any block in the Song Map to select a specific section to jump to.
    *   **Confirm Intent**: Click to confirm the "Active Target" (either the automatic next or your selection).
    *   **Arm**: Click to enable execution.
    *   **Move Cursor**: Moves the edit cursor to the target section.
    *   **Jump/Seek Now**: Immediately seeks playback to the target section.
    *   **Loop Current**: Re-triggers the start of the current section.
    *   **Play/Stop**: Manual transport control.
    *   **Clear**: Resets confirmation, selection, and disarms execution.

## Safety Guarantees

*   **No `Main_OnCommand`**: We use specific REAPER APIs for transport.
*   **Limited API Whitelist**: Only `SetEditCurPos`, `OnPlayButton`, `OnStopButton`, `GetPlayState`, and `GetPlayPosition` are used for real actions.
*   **Locked by Default**: Real actions require explicit Confirmation + Arming.
*   **Automatic Disarm**: The session is disarmed automatically after any execution attempt.

## Technical Details

Built with Lua and ReaImGui. The architecture separates the **Runtime** (read-only snapshot) from the **Transport Adapter** (real REAPER calls) via a **Safety Gate** and **Simulator**.

New layers in v0.2:
*   **SongMap**: Normalizes sections from project regions.
*   **UITimeline**: Models the visual representation of the song structure.

See `docs/ARCHITECTURE.md` for more information.
