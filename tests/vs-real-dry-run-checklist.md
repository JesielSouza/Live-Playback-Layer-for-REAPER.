# VS Real Dry Run Checklist

Use this checklist to validate the current read-only Runtime UI during a Virtual Soundcheck or real rehearsal. This phase does not implement playback control.

## 1. REAPER Preparation
- [ ] REAPER is installed.
- [ ] ReaPack is installed.
- [ ] ReaImGui is installed.
- [ ] A project is open.
- [ ] `scripts/reaper_ui.lua` is loaded in the Action List.
- [ ] `scripts/reaper_smoke_test.lua` is loaded in the Action List.

## 2. Test Project Preparation
- [ ] Create or confirm these Regions:
  - `INTRO|loop=0|next=VERSE_1`
  - `VERSE_1|loop=0|next=CHORUS_1`
  - `CHORUS_1|loop=1|next=ENDING`
  - `ENDING|loop=0`

## 3. Read-Only Validation
- [ ] Run the smoke test.
- [ ] Confirm `Validation Status: ready`.
- [ ] Confirm `State: SONG_LOADED`.
- [ ] Confirm `Section Count: 4`.
- [ ] Confirm no transport action was triggered.

## 4. UI Validation
- [ ] Run `scripts/reaper_ui.lua`.
- [ ] Confirm the `Live Playback Layer` window opens.
- [ ] Confirm `Read Only: true`.
- [ ] Confirm these UI sections are visible:
  - Status
  - Position
  - Navigation
  - Diagnostics
- [ ] Confirm Frame Count increases.

## 5. Manual Cursor Validation
Move the cursor manually to each section and record the runtime state.

| Cursor Target | Current Section | Previous Section | Next Section | Decision | Pass |
| --- | --- | --- | --- | --- | --- |
| INTRO |  |  |  |  | [ ] |
| VERSE_1 |  |  |  |  | [ ] |
| CHORUS_1 |  |  |  |  | [ ] |
| ENDING |  |  |  |  | [ ] |

## 6. Real VS Validation
- [ ] Open a real project or a safe copy.
- [ ] Do not trigger playback through the product.
- [ ] Move the cursor manually only.
- [ ] Confirm real sections are recognized.
- [ ] Confirm warnings or blocked status appear when the Region schema is wrong.
- [ ] Record naming or structure gaps.

## 7. GO Criteria
- [ ] UI opens without crashing.
- [ ] Runtime updates when the cursor moves.
- [ ] Sections are recognized correctly.
- [ ] No transport is triggered.
- [ ] No project mutation occurs.

## 8. NO-GO Criteria
- [ ] UI crashes.
- [ ] Validation is blocked without a clear reason.
- [ ] Current Section is incorrect.
- [ ] Decision is incorrect.
- [ ] Any transport action is triggered.
- [ ] Any unauthorized project mutation occurs.

## 9. Result Record
- Date:
- Project:
- Operator:
- REAPER version:
- ReaImGui version:
- Result:
- Observed issues:
- Next action:
