# PLAN-student-ecg-ui

## Goal
Overhaul the Student ECG Practice Mode to match the Admin's "7+2" workflow, featuring a single-page scrollable UI, delayed feedback (report card), and timer-based gamification.

## Tasks
- [ ] **Scaffold UI**: Replace Wizard with Single-Page Scrollable Form (Reuse Admin layouts where possible)
    - [ ] Create Zoomable `ECGViewer` (Top split) and `ECGForm` (Bottom split)
    - [ ] Implement steps: Rhythm, Rate, Conduction, Axis, P-Wave, QRS, ST-T
    - [ ] Add "Submit" floating action button (FAB)
- [ ] **State Management**:
    - [ ] Track `startTime` on load.
    - [ ] Track `userFindings` map (mirroring `findings_json`).
- [ ] **Grading Engine (Delayed Feedback)**:
    - [ ] Implement `ScoreCalculator`:
        - [ ] Accuracy Check: Compare User vs Gold Standard for all fields.
        - [ ] Time Factor: <60s = 5★, <120s = 4★, <300s = 3★, >300s = 1★.
- [ ] **Report Card UI**:
    - [ ] Build Result Dialog showing:
        - [ ] Stethoscope Rating (1-5).
        - [ ] Time Taken.
        - [ ] Detailed "Missed" list (e.g., "Rate: You said 60, Actual 75").

## Done When
- [ ] User can scroll continuously through all 9 steps.
- [ ] Submitting a correct case in <1 min awards 5 stethoscopes.
- [ ] Submitting incorrect data shows a detailed correction list.
