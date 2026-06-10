# Architecture: Live Playback Layer for REAPER

## Design Principles

1.  **Safety-First**: The system never takes an action without explicit operator confirmation.
2.  **Read-Only Runtime**: UI logic works with a "Snapshot", avoiding direct API calls during render.
3.  **Explicit Transport**: Mutations are centralizad in the **Transport Adapter**.
4.  **Operator Focus**: UI is designed for live use (Sprint v0.2).

## Core Components

### 1. Runtime (`scripts/runtime.lua`)
Builds a complete, read-only snapshot of the current REAPER state.

### 2. Song Map (`scripts/song_map.lua`)
Normalizes song sections from various project sources (Regions). It handles state for current, next, and manually selected sections.

### 3. UI Timeline (`scripts/ui_timeline.lua`)
A pure model that prepares the Song Map for visual rendering, determining block states and weights.

### 4. Transport Control (`scripts/transport_control.lua`)
The dispatcher for operational intents. It builds intents (automatic next, manual selection, loop) and delegates execution to the adapter.

### 5. Transport Adapter (`scripts/transport_adapter.lua`)
The only module allowed to call "Real" REAPER transport APIs:
- `SetEditCurPos`
- `OnPlayButton()` / `OnStopButton()`
- `GetPlayState()` / `GetPlayPosition()`

### 6. UI Session (`scripts/ui_session.lua`)
Manages transient UI state (confirmations, arming, manual selection).

### 7. Reaper UI (`scripts/reaper_ui.lua`)
The ReaImGui-based interface.
- **Operator Mode**: Main panel with Song Map and transport buttons.
- **Debug Mode**: Hidden technical diagnostic data.

## Workflow v0.2

1.  **Snap**: Read REAPER state.
2.  **Map**: Build Song Map and UI Timeline.
3.  **Select**: User can click a block to select a manual target.
4.  **Intent**: System evaluates the "Active Target" (Selection > Next).
5.  **Confirm & Arm**: Explicit workflow for safety.
6.  **Execute**: Trigger transport action.
