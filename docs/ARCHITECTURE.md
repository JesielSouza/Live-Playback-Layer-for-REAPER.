# Architecture: Live Playback Layer for REAPER

## Design Principles

1.  **Safety-First**: No action without explicit operator confirmation.
2.  **Read-Only Runtime**: Logic works with a "Snapshot" of state.
3.  **Isolated Adapters**: REAPER API calls are centralized and whitelisted.
4.  **Local-First Persistence**: State is saved in Lua table files for speed and safety.

## Core Components

### 1. Setlist Layer (Sprint v0.4)
- **Setlist Model (`scripts/setlist_model.lua`)**: Pure logic for song list management, normalization, and navigation.
- **Setlist Store (`scripts/setlist_store.lua`)**: Handles persistence. Serializes setlist data into a Lua table file (`live_playback_setlist.lua`) that can be loaded using `loadfile`.
- **UI Setlist (`scripts/ui_setlist.lua`)**: Prepares song metadata for display as cards in the UI.

### 2. Runtime (`scripts/runtime.lua`)
Builds a complete, read-only snapshot of the current REAPER state.

### 3. Song Map (`scripts/song_map.lua`)
Normalizes song sections from various project sources (Regions).

### 4. Mixer Layer (`scripts/track_adapter.lua` etc.)
Classifies and controls project tracks (Mute, Solo, Volume).

### 5. Transport Control (`scripts/transport_control.lua`)
Dispatcher for operational intents.

### 6. Transport Adapter (`scripts/transport_adapter.lua`)
Whitelisted REAPER transport APIs.

### 7. UI Session (`scripts/ui_session.lua`)
Manages transient UI state (confirmations, arming, selection).

### 8. Reaper UI (`scripts/reaper_ui.lua`)
The ReaImGui-based interface.

## Persistence Strategy

We use Lua tables for persistence to avoid external JSON dependencies. 
- **Serialization**: Manually traverses the setlist table and builds a string.
- **Deserialization**: Uses Lua's `load` or `loadstring` in a controlled environment.
- **Security**: Persistence files are local to the project and intended for configuration only.
