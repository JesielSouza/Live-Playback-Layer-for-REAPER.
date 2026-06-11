# Manual Test Checklist: Sprint v0.6 Live Control

This checklist ensures the v0.6 Live Control features work correctly inside REAPER.

## 1. Live Queue Management
- [ ] UI shows "Live Control" section.
- [ ] Select a section and click "Add Selected to Queue". Confirm it appears in the queue list.
- [ ] Click "Add Next to Queue". Confirm the automatic next section is added.
- [ ] Click "^" (Up) on a queue item. Confirm it moves up.
- [ ] Click "v" (Down) on a queue item. Confirm it moves down.
- [ ] Click "RM" (Remove) on an item. Confirm it is removed.
- [ ] Click "Clear Queue". Confirm the list is empty.

## 2. Infinite Loop Mode
- [ ] Click "Loop Current". Confirm "Infinite Loop: ON" appears with the current section.
- [ ] Operator Panel shows "Active Source: infinite_loop" and "Active Target" matching the loop.
- [ ] Click "Clear Loop". Confirm "Infinite Loop: OFF".
- [ ] Select a section and click "Loop Selected". Confirm it enables loop for that section.

## 3. Execution Priority
- [ ] With nothing selected/queued: Active Source is "next_section".
- [ ] Select a section: Active Source becomes "selected_section".
- [ ] Add an item to queue: Active Source becomes "live_queue".
- [ ] Enable loop: Active Source becomes "infinite_loop".
- [ ] Confirm + Arm + Move/Jump follows this priority.

## 4. Operational Flow
- [ ] Add a section to the queue.
- [ ] Confirm + Arm + Jump/Seek Now.
- [ ] REAPER jumps to the section.
- [ ] Success: The first item should be automatically removed from the queue.
- [ ] Failure (e.g., disarmed before click): Item remains in queue.
- [ ] Enable Infinite Loop. Confirm + Arm + Jump. Loop should remain active after execution.

## 5. Safety Audits
- [ ] Confirm that adding to queue or enabling loop does NOT move the cursor or start playback.
- [ ] Confirm that no REAPER Regions are created, deleted, or reordered.
- [ ] `Main_OnCommand` is not triggered.
- [ ] Mixer and Setlist features still work as expected.
