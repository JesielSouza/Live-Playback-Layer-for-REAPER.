# Live Playback Layer for REAPER

A safety-first playback control layer for REAPER, designed for live performance.

## Features

*   **Operator Mode**: A simplified UI for live operation.
*   **Section Awareness**: Automatic detection of current and next sections based on project Regions.
*   **Safety Gates**: Multiple layers of validation before any real transport action is taken.
*   **Explicit Execution**: No automatic jumps. All actions (Move, Seek, Play, Stop) require explicit operator intent.
*   **Dry-run Validation**: Every intent is simulated and audited before execution is even allowed to be armed.

## How to Use

1.  **Prepare your Project**:
    *   Create **Regions** for each section of your song (e.g., "INTRO", "VERSE_1", "CHORUS_1").
    *   Ensure regions are contiguous and well-named.
2.  **Open the Script**:
    *   In REAPER, go to `Actions > Show action list`.
    *   Search for `reaper_ui.lua` (you must have added this project folder to your REAPER scripts or used ReaPack).
    *   Run the script.
3.  **Operator Workflow**:
    *   **Confirm Intent**: Click to confirm the detected "Next Target". This is a safety step to ensure you know where the cursor will go.
    *   **Arm**: Click to enable execution. This "unlocks" the real transport buttons.
    *   **Move Cursor**: Moves the edit cursor to the target section (playback must be stopped or it will move the edit cursor without seeking).
    *   **Jump/Seek Now**: Immediately seeks playback to the target section.
    *   **Loop Current**: Re-triggers the start of the current section.
    *   **Play/Stop**: Manual transport control.
    *   **Clear**: Resets confirmation and disarms execution.

## Safety Guarantees

*   **No `Main_OnCommand`**: We use specific REAPER APIs for transport, avoiding side effects from custom shortcuts.
*   **Limited API Whitelist**: Only `SetEditCurPos`, `OnPlayButton`, `OnStopButton`, `GetPlayState`, and `GetPlayPosition` are used for real actions.
*   **Locked by Default**: The layer starts in a read-only state. Real actions require explicit Confirmation + Arming.
*   **Automatic Disarm**: The session is disarmed automatically after any execution attempt.

## Technical Details

Built with Lua and ReaImGui. The architecture separates the **Runtime** (read-only snapshot) from the **Transport Adapter** (real REAPER calls) via a **Safety Gate** and **Simulator**.

See `docs/ARCHITECTURE.md` for more information.
