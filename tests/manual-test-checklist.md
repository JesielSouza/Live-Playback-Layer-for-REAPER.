# Manual Test Checklist: MVP Operations

This checklist ensures the Live Playback Layer works correctly inside REAPER.

## 1. UI Initialization
- [ ] Open `reaper_ui.lua`.
- [ ] UI shows "Operator Panel".
- [ ] Debug sections are hidden.
- [ ] Playback status correctly shows "stopped" if not playing.

## 2. Intent Confirmation
- [ ] Place cursor in a section (e.g., VERSE_1).
- [ ] UI shows "Next Target" correctly (e.g., CHORUS_1).
- [ ] Click "Confirm Intent".
- [ ] "Confirmation" status changes to "CONFIRMED".
- [ ] Move cursor to another section; "Confirmation" should revert to "NOT CONFIRMED".

## 3. Cursor Movement (Stopped)
- [ ] Place cursor in VERSE_1.
- [ ] Click "Confirm Intent".
- [ ] Click "Arm".
- [ ] Click "Move Cursor".
- [ ] REAPER cursor should move to CHORUS_1.
- [ ] Execution Armed should revert to `false`.
- [ ] Last Execution should show `cursor_move_executed`.

## 4. Seek/Jump (During Playback)
- [ ] Start playback in REAPER.
- [ ] Click "Confirm Intent" for next section.
- [ ] Click "Arm".
- [ ] Click "Jump/Seek Now".
- [ ] REAPER playback should immediately jump to the target section.
- [ ] Execution Armed should revert to `false`.
- [ ] Last Execution should show `seek_executed`.

## 5. Loop Current
- [ ] While playing a section, click "Arm".
- [ ] Click "Loop Current".
- [ ] REAPER playback should jump back to the start of the current section.

## 6. Manual Transport
- [ ] Click "Arm".
- [ ] Click "Play".
- [ ] REAPER should start playing.
- [ ] Click "Stop".
- [ ] REAPER should stop (Panic Stop). Note: "Stop" does not require arming.

## 7. Safety Audits
- [ ] Confirm no automatic jumps happen at region boundaries.
- [ ] Confirm no markers or regions are created or deleted.
- [ ] Confirm `Main_OnCommand` is not triggered (no unexpected actions).
- [ ] Toggle "Show Debug" and confirm technical data is accurate.
