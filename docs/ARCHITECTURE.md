# Architecture: Live Playback Layer for REAPER

## Design Principles

1.  **Safety-First**: No action without explicit operator confirmation.
2.  **Read-Only Runtime**: Logic works with a "Snapshot" of state.
3.  **Isolated Adapters**: REAPER API calls are centralized and whitelisted.
4.  **Logical Re-Ordering**: Performance-time changes (Queue/Loop) are purely logical and do not mutate the project structure (Regions).

## Core Components

### 1. Live Control Layer (Sprint v0.6)
- **Live Queue (`scripts/live_queue.lua`)**: Manages a logical queue of next sections. Allows adding, removing, and reordering.
- **Loop Mode (`scripts/loop_mode.lua`)**: Manages the infinite loop state for a section.
- **UI Live Control (`scripts/ui_live_control.lua`)**: Prepares queue and loop states for visual rendering.

### 2. Setlist Layer
- **Setlist Model / Store**: Logic and persistence for song list management.
- **UI Setlist**: View model for song cards.

### 3. Runtime (`scripts/runtime.lua`)
Builds a complete, read-only snapshot of the current REAPER state.

### 4. Song Map (`scripts/song_map.lua`)
Normalizes song sections from various project sources (Regions).

### 5. Mixer Layer
Classifies and controls project tracks (Mute, Solo, Volume).

### 6. Transport Control (`scripts/transport_control.lua`)
The dispatcher for operational intents. It resolves the "Active Target" based on a priority system:
1. Infinite Loop
2. Live Queue
3. Selected Section
4. Next Natural Section

### 7. Transport Adapter (`scripts/transport_adapter.lua`)
Whitelisted REAPER transport APIs.

### 8. UI Session (`scripts/ui_session.lua`)
Manages transient UI state (confirmations, arming, selection, queue, loop).

### 9. Reaper UI (`scripts/reaper_ui.lua`)
The ReaImGui-based interface.

## Active Intent Resolution

The system dynamically determines the next destination (Active Target) every frame:
- If a **Loop** is active, it points to that section.
- Else if the **Queue** has items, it points to the first item.
- Else if a **Selection** exists, it points to the selected section.
- Else it falls back to the **Next** logical section in the project.
