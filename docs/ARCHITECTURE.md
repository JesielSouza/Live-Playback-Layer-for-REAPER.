# Architecture: Live Playback Layer for REAPER

## Design Principles

1.  **Safety-First**: The system must never take an action that wasn't explicitly confirmed by the operator.
2.  **Read-Only Runtime**: The UI logic works with a "Snapshot" of the project, never calling REAPER APIs directly to mutate state during render loops.
3.  **Explicit Transport**: All mutations happen in the **Transport Adapter**, which acts as a controlled gatekeeper for REAPER APIs.
4.  **No `Main_OnCommand`**: We avoid using generic command triggers to ensure predictable behavior and avoid interference with user keybindings.

## Core Components

### 1. Runtime (`scripts/runtime.lua`)
Builds a complete, read-only snapshot of the current REAPER state (cursor position, play state, regions, etc.).

### 2. Transport Control (`scripts/transport_control.lua`)
Analyzes the snapshot and build "Intents" (e.g., "Go to Next Section"). It uses the **Transport Simulator** and **Safety Gate** to determine if an action is safe and valid.

### 3. Transport Adapter (`scripts/transport_adapter.lua`)
The only module allowed to call "Real" REAPER transport APIs. It implements a strict whitelist:
- `SetEditCurPos(pos, moveview, seekplay)`: For cursor moves and seeks.
- `OnPlayButton()`: For manual playback start.
- `OnStopButton()`: For manual playback stop.
- `GetPlayState()` / `GetPlayPosition()`: For status monitoring.

### 4. UI Session (`scripts/ui_session.lua`)
Manages in-memory UI state that isn't stored in REAPER, such as "Is the current intent confirmed?" and "Is execution armed?".

### 5. Reaper UI (`scripts/reaper_ui.lua`)
The ReaImGui-based interface. It has two modes:
- **Operator Mode**: Simplified view for live use.
- **Debug Mode**: Technical view for diagnostics and audit.

## Execution Flow

1.  **Build Snapshot**: Every frame, the system reads REAPER state.
2.  **Evaluate Intent**: The system determines the logical "Next Section".
3.  **Confirm**: The user clicks "Confirm Intent".
4.  **Arm**: The user clicks "Arm".
5.  **Execute**: The user clicks a transport button (Move/Seek/Play).
6.  **Disarm**: The session automatically disarms after execution.
