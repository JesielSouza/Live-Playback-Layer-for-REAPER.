# Manual Test Checklist: Sprint v0.4 Setlist

This checklist ensures the v0.4 Setlist features work correctly inside REAPER.

## 1. Setlist Initialization
- [ ] Open `reaper_ui.lua`.
- [ ] Confirm `live_playback_setlist.lua` is created in the project folder.
- [ ] UI shows "Setlist / Songs" section at the top.
- [ ] A default card "Current Project" is visible and marked with `▶`.

## 2. Song Navigation
- [ ] Click "Add Placeholder". Confirm a second "Current Project" card appears.
- [ ] Click "Next Song".
- [ ] The `▶` prefix moves to the second song.
- [ ] The second song text is colored (Green).
- [ ] Click "Previous Song". The `▶` prefix moves back.
- [ ] Confirm a message "Project loading is not enabled" is visible.

## 3. Persistence
- [ ] Add a placeholder.
- [ ] Click "Save Setlist".
- [ ] Close REAPER and reopen the script.
- [ ] Confirm the second placeholder is still there.
- [ ] Click "Reload Setlist" and confirm the UI refreshes correctly.

## 4. Integration
- [ ] Navigate to a different song in the setlist.
- [ ] Confirm Song Map and Mixer still work for the current REAPER project.
- [ ] Confirm Transport buttons (Play/Stop) still work.

## 5. Safety Audits
- [ ] Navigating songs does NOT move the cursor or start playback.
- [ ] Saving setlist does NOT trigger REAPER commands.
- [ ] No markers or regions are created.
- [ ] No tracks are created or deleted.
- [ ] `Main_OnCommand` is not triggered.
