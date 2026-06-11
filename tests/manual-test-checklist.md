# Manual Test Checklist: Sprint v0.7 Section Cues

This checklist ensures the v0.7 Section Cues features work correctly inside REAPER.

## 1. Cues Initialization
- [ ] Open `reaper_ui.lua`.
- [ ] UI shows "Section Cues" section.
- [ ] `live_playback_cues.lua` is created in the project folder.
- [ ] Summary line shows correct counts (starts at 0).
- [ ] Warning "No MIDI is sent" is visible.

## 2. Cue Management (Current Section)
- [ ] Click "Add Note to Current".
- [ ] A new cue appears under "Current Section Cues".
- [ ] Check `live_playback_cues.lua` and confirm it contains the new cue data.
- [ ] Click "DISABLE" on the cue. Status changes to `[OFF]`.
- [ ] Click "ENABLE" on the cue. Status changes to `[ON]`.
- [ ] Click "Add MIDI Placeholder to Current". Confirm it appears as a different type.

## 3. Cue Management (Selection)
- [ ] Select a non-current section in the Song Map (e.g., CHORUS_1).
- [ ] Click "Add Note to Selected".
- [ ] Confirm the cue is added.
- [ ] Make the selected section the Active Target (e.g., Confirm it).
- [ ] Confirm the cue appears in the "Active Target Cues" list.

## 4. Persistence
- [ ] Add a few cues.
- [ ] Click "Save Cues".
- [ ] Restart the script and confirm the cues are still there.
- [ ] Click "Reload Cues" and confirm the UI remains consistent.

## 5. Safety & Integrations
- [ ] Confirm that adding/disabling cues does NOT trigger any REAPER transport action.
- [ ] Confirm that no MIDI messages are emitted (if you have a monitor).
- [ ] Confirm that Song Map, Live Control, and Mixer features still work correctly.
- [ ] Confirm no REAPER Regions or Markers are changed.
