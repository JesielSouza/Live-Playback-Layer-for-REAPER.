# Architecture: Live Playback Layer for REAPER

## Design Principles

1.  **Safety-First**: The system never takes an action without explicit operator confirmation.
2.  **Read-Only Runtime**: UI logic works with a "Snapshot", avoiding direct API calls during render.
3.  **Explicit Transport**: Mutations are centralized in the **Transport Adapter**.
4.  **Operator Focus**: UI is designed for live use (Sprint v0.2/v0.3).
5.  **Isolations**: REAPER API calls are isolated in specialized Adapters.

## Core Components

### 1. Runtime (`scripts/runtime.lua`)
Builds a complete, read-only snapshot of the current REAPER state.

### 2. Song Map (`scripts/song_map.lua`)
Normalizes song sections from various project sources (Regions). It handles state for current, next, and manually selected sections.

### 3. UI Timeline (`scripts/ui_timeline.lua`)
A pure model that prepares the Song Map for visual rendering.

### 4. Mixer Layer (Sprint v0.3)
- **Track Adapter (`scripts/track_adapter.lua`)**: Isolates REAPER track and mixer APIs (Mute, Solo, Volume).
- **Track Catalog (`scripts/track_catalog.lua`)**: Classifies project tracks into categories like Click, Guide, Drums, etc.
- **Mixer State (`scripts/mixer_state.lua`)**: Manages mixer UI visibility and selections.
- **UI Mixer (`scripts/ui_mixer.lua`)**: Prepares the track catalog for visual rendering in the UI.

### 5. Transport Control (`scripts/transport_control.lua`)
The dispatcher for operational intents. It builds intents and delegates execution to the transport adapter.

### 6. Transport Adapter (`scripts/transport_adapter.lua`)
The module allowed to call REAPER transport APIs: `SetEditCurPos`, `OnPlayButton`, `OnStopButton`, `GetPlayState`, `GetPlayPosition`.

### 7. UI Session (`scripts/ui_session.lua`)
Manages transient UI state (confirmations, arming, manual selection).

### 8. Reaper UI (`scripts/reaper_ui.lua`)
The ReaImGui-based interface.
- **Operator Mode**: Main panel with Song Map, Transport controls, and Mixer.
- **Debug Mode**: Hidden technical diagnostic data.

## Workflow v0.3

1.  **Snap**: Read REAPER state and Scan Tracks.
2.  **Map**: Build Song Map, UI Timeline, and Track Catalog.
3.  **Mix**: Render the Mixer for live control of stems.
4.  **Select**: User can click a block to select a manual target.
5.  **Confirm & Arm**: Safety-first workflow for transport.
6.  **Execute**: Trigger transport or mixer action.
