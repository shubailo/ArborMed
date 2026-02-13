# PLAN: ECG Stepped Wizard

This plan outlines the refactoring of `ECGPracticeScreen` into a multi-page wizard flow to improve clinical Focus and UX.

## Overview
Transform the "form-scroll" ECG quiz into a 4-page diagnostic wizard where the ECG remains pinned for reference while the user interprets specific clinical findings in a linear sequence.

## Success Criteria
- [ ] ECG image is pinned at the top and visible on all pages.
- [ ] 4 distinct interpretation pages are implemented (0-3).
- [ ] Page 0 only appears if clinical history is present.
- [ ] Linear "Back/Next" navigation with progress indicators.
- [ ] State is preserved across page transitions.
- [ ] Final submission only possible on the last page.

## Tech Stack
- **Framework**: Flutter
- **State Management**: Existing `StatefulWidget` + `StatsProvider`
- **Theme**: `CozyTheme` (Sage/Clay palette)

## Task Breakdown

### Phase 1: Foundation (Setup)
- [ ] **Task ID: T1** - Setup `PageController` and current page index state.
- [ ] **Task ID: T2** - Create a list of "WizardPage" models or enums to manage logical groupings.
- [ ] **Task ID: T3** - Implement a persistent Header/ECG section that does not scroll with the form.

### Phase 2: Content Refactoring
- [ ] **Task ID: T4** - Extract Page 0: **Clinical History** (Conditional).
- [ ] **Task ID: T5** - Extract Page 1: **Rhythm, Rate, Conduction**.
- [ ] **Task ID: T6** - Extract Page 2: **Axis, P-Wave, QRS, ST-T**.
- [ ] **Task ID: T7** - Extract Page 3: **Diagnosis, Management**.

### Phase 3: Navigation & UX
- [ ] **Task ID: T8** - Build a "Wizard Navigation Bar" at the bottom with dynamic "Back", "Next", and "Submit" buttons.
- [ ] **Task ID: T9** - Add a progress indicator (steps/timeline) to show current position.
- [ ] **Task ID: T10** - Implement validation check before allowing "Next" (optional but recommended for clinician training).

### Phase 4: Polish & Performance
- [ ] **Task ID: T11** - Implement smooth slide transitions between pages.
- [ ] **Task ID: T12** - Ensure "Report Card" (feedback) still works correctly after submission.

## File Structure
Modified: `mobile/lib/screens/ecg_practice_screen.dart` (Major refactor)
Potential New Widgets: `mobile/lib/widgets/ecg/ecg_wizard_step.dart` (to keep the main file manageable)

## Phase X: Verification
- [ ] Run `flutter analyze` to ensure no linting errors.
- [ ] Manually verify "Back" button preserves input data.
- [ ] Manually verify "Page 0" logic with a case that has/has not history.
- [ ] Verify validation errors highlight the correct field on the current page.
