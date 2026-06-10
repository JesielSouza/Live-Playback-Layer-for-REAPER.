# Manual Test Checklist: Sprint v0.3 Mixer

This checklist ensures the v0.3 Mixer features work correctly inside REAPER.

## 1. Track Detection & Classification
- [ ] Rename a track to "CLICK". Confirm it appears in the "Click" category.
- [ ] Rename a track to "GUIA". Confirm it appears in the "Guide" category.
- [ ] Rename a track to "BATERIA". Confirm it appears in the "Drums" category.
- [ ] Confirm all stem categories (Bass, Keys, etc.) work as expected based on names.

## 2. Mixer Rendering
- [ ] UI shows "Mixer / Stems" section.
- [ ] Summary line shows correct counts for total/stems/click/guide.
- [ ] "Hide Mixer" hides the section. "Show Mixer" shows it.
- [ ] Categories are collapsible.

## 3. Mixer Controls
- [ ] Click "MUTE" on a track. Confirm the track in REAPER is muted.
- [ ] Click "UNMUTE" on a track. Confirm it is unmuted.
- [ ] Click "SOLO" on a track. Confirm it is soloed in REAPER.
- [ ] Click "UNSOLO" on a track. Confirm it is un-soloed.
- [ ] Click "V-" on a track. Confirm volume decreases in REAPER.
- [ ] Click "V+" on a track. Confirm volume increases.

## 4. Operational Persistence
- [ ] Last Mixer Action shows details of the last click (action, track, value).
- [ ] Song Map and Transport buttons still work while the mixer is visible.

## 5. Safety Audits
- [ ] Changing mixer levels does NOT move the cursor or start playback.
- [ ] Mixer actions do NOT require "Arm" (as designed for live speed).
- [ ] No tracks are created, deleted, or reordered.
- [ ] No markers or regions are created or deleted.
- [ ] `Main_OnCommand` is not triggered.
