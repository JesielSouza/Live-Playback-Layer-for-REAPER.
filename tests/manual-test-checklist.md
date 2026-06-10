# Manual Test Checklist: Sprint v0.2 Visuals

This checklist ensures the v0.2 features work correctly inside REAPER.

## 1. Song Map Rendering
- [ ] UI shows "Song Map" section.
- [ ] Sections are rendered as blocks (Buttons).
- [ ] Each block shows the correct Region name.
- [ ] The current section has a `> ` prefix.
- [ ] The automatic next section has a `>> ` prefix.

## 2. Manual Selection
- [ ] Click on any non-current block.
- [ ] The clicked block gets a `* ` prefix.
- [ ] Operator Panel shows "Selected Target: [name]".
- [ ] Operator Panel shows "Active Target: [name]" matching your selection.
- [ ] "Confirmation" status is "NOT CONFIRMED".

## 3. Workflow with Selection
- [ ] Select a section.
- [ ] Click "Confirm Intent".
- [ ] "Confirmation" status changes to "CONFIRMED".
- [ ] Click "Arm".
- [ ] Click "Jump/Seek Now".
- [ ] REAPER jumps to the selected section.
- [ ] Confirmation and Arming are reset.

## 4. Clear Selection
- [ ] Select a section.
- [ ] Click "Clear".
- [ ] `* ` prefix disappears from the block.
- [ ] "Selected Target" becomes "none".
- [ ] "Active Target" reverts to the automatic next section.

## 5. Playback States
- [ ] Start Playback: UI shows "PLAYBACK: PLAYING".
- [ ] Pause Playback: UI shows "PLAYBACK: PAUSED".
- [ ] Stop Playback: UI shows "PLAYBACK: STOPPED".

## 6. Safety Audits
- [ ] Selecting a section does NOT move the cursor or start playback.
- [ ] Confirming does NOT move the cursor or start playback.
- [ ] Arming does NOT move the cursor or start playback.
- [ ] No markers or regions are created or deleted.
- [ ] `Main_OnCommand` is not triggered.
