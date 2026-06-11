# Architecture: Live Playback Layer for REAPER

## Design Principles

1.  **Safety-First**: No action without explicit operator confirmation.
2.  **Read-Only Runtime**: Logic works with a "Snapshot" of state.
3.  **Isolated Adapters**: REAPER API calls are centralized and whitelisted.
4.  **Logical Performance Layers**: Cues, Queue, and Loop modes are purely logical and do not mutate the project structure (Regions).

## Core Components

### 1. Section Cues Layer (Sprint v0.7)
- **Cue Model (`scripts/cue_model.lua`)**: Logic for managing section-based performance cues (notes, lyric placeholders, MIDI markers).
- **Cue Store (`scripts/cue_store.lua`)**: Persistence using Lua table serialization (`live_playback_cues.lua`).
- **UI Cues (`scripts/ui_cues.lua`)**: View model for rendering cues, grouped by section and filtered by current/next/active target.

### 2. Live Control Layer
- **Live Queue**: Manages a logical queue of next sections.
- **Loop Mode**: Manages the infinite loop state for a section.

### 3. Setlist Layer
- **Setlist Model / Store**: Logic and persistence for song list management.

### 4. Runtime (`scripts/runtime.lua`)
Builds a complete, read-only snapshot of the current REAPER state.

### 5. Song Map (`scripts/song_map.lua`)
Normalizes song sections from various project sources (Regions).

### 6. Mixer Layer
Classifies and controls project tracks (Mute, Solo, Volume).

### 7. Transport Control (`scripts/transport_control.lua`)
The dispatcher for operational intents, resolving the "Active Target" based on priority.

### 8. Transport Adapter (`scripts/transport_adapter.lua`)
Whitelisted REAPER transport APIs.

### 9. UI Session (`scripts/ui_session.lua`)
Manages transient UI state.

### 10. Reaper UI (`scripts/reaper_ui.lua`)
The ReaImGui-based interface.

## Cue Management

Cues are stored independently of the song project file. They are linked to sections by their ID/Name. This allows for reusable production planning that survives project reloads or region renames, provided the IDs remain consistent.
In this version (v0.7), cues are for visualization only and do not trigger any external events.
