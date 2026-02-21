# Room HUD & Frontend Modularity Refactor

## Overview
Reorganize the Room HUD (`CozyActionsOverlay`) layout to a cohesive space-aware scheme based on the Focus-Friend-like layout, and cleanly modularize the Flutter frontend folder structure to ensure maintainability and separation of concerns. This is a UI/architecture-only task on the Flutter `student_app`. No backend logic or SM-2 behavior changes will be made.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
1. The `CozyActionsOverlay` implements the new visual layout with three distinct interaction zones: Bottom-Left (Profile/Social), Bottom-Center (Study/Smart Review), and Bottom-Right (Settings/Decorate).
2. The `lib/` directory is reorganized into `core/`, `screens/`, and `features/` per the specifications.
3. Core UI components (`cozy_panel.dart`, `cozy_button.dart`, etc.) are centralized in `lib/core/ui/`.
4. Feature modules (`study`, `reward`, `room`, `progress`, `social`) are fully isolated in their domains.
5. `flutter analyze` runs clean with no broken imports or architecture regressions.

## Tech Stack
- **Framework**: Flutter (Dart)
- **Architecture**: Modular structure grouping by feature (Data, Domain, Presentation)

## File Structure (Target)
```text
lib/
  core/
    theme/ (app_theme.dart, cozy_theme.dart)
    audio/ (audio_manager.dart)
    network/ (api_client.dart, interceptors/)
    ui/ (cozy_panel.dart, cozy_button.dart, cozy_badge.dart, cozy_modal_scaffold.dart, cozy_icon_button.dart)
  screens/ (room_shell_screen.dart, study_shell_screen.dart, progress_shell_screen.dart)
  features/
    study/ (data/, domain/, presentation/)
    reward/ (data/, domain/, presentation/)
    room/ (data/, domain/, presentation/)
    progress/ (data/, domain/, presentation/)
    social/ (data/, domain/, presentation/)
```

## Task Breakdown

### Task 1: Initialize Core Folders and UI Components
- **Agent**: `mobile-developer`
- **Skills**: `clean-code`, `mobile-design`
- **Priority**: High
- **Dependencies**: None
- **INPUT**: Current `lib/` directory structure.
- **OUTPUT**: `lib/core/` structured created. Shared UI components (`cozy_panel.dart`, `cozy_button.dart`, `cozy_badge.dart`, `cozy_modal_scaffold.dart`, `cozy_icon_button.dart`) moved to `lib/core/ui/`.
- **VERIFY**: Run `flutter analyze` tracking structural moves (ignoring screen imports for this task).

### Task 2: Reorganize Feature Modules and Shells
- **Agent**: `mobile-developer`
- **Skills**: `clean-code`
- **Priority**: High
- **Dependencies**: Task 1
- **INPUT**: Current `lib/features/` and root screen usages.
- **OUTPUT**:
  - `lib/screens/` containing `room_shell_screen.dart`, `study_shell_screen.dart`, `progress_shell_screen.dart` (or similarly grouped entry points).
  - Feature directories inside `lib/features/` separated strictly (`study/`, `reward/`, `room/`, `progress/`, `social/`) with `data/`, `domain/`, `presentation/` subfolders aligned.
- **VERIFY**: Inspect directory tree to match the Target File Structure blueprint.

### Task 3: Resolve Import Errors Across the Codebase
- **Agent**: `mobile-developer`
- **Skills**: `bash-linux`, `clean-code`
- **Priority**: High
- **Dependencies**: Task 2
- **INPUT**: Reorganized directory structure with broken imports.
- **OUTPUT**: Correctly updated import paths in all Dart files referencing moved components or shells.
- **VERIFY**: `flutter pub get` succeeds. `flutter analyze` returns 0 issues or no structurally-related errors.

### Task 4: Refactor HUD Layout (`CozyActionsOverlay`)
- **Agent**: `mobile-developer`
- **Skills**: `mobile-design`
- **Priority**: High
- **Dependencies**: Task 3
- **INPUT**: Current `cozy_actions_overlay.dart`.
- **OUTPUT**: 
  - Overhauled `cozy_actions_overlay.dart` located in `lib/features/room/presentation/` leveraging `cozy_button.dart` and `cozy_icon_button.dart`.
  - **Position Left**: Profile/Stats (bottom) + Social Directory (above).
  - **Position Center**: Primary Study Button + Contextual Smart Review button attached/beside it.
  - **Position Right**: Settings (bottom) + Decorate/Room Edit (above).
  - Declarative wiring: Connects to correct feature routers/providers without containing business logic.
- **VERIFY**: Execute `flutter test` or check visual rendering manually ensuring layout aligns with specification. All 6 buttons trigger assigned interactions.

### Task 5: Edge Cases for Visual Details (Safe Areas / States)
- **Agent**: `mobile-developer`
- **Skills**: `mobile-design`
- **Priority**: Medium
- **Dependencies**: Task 4
- **INPUT**: Fully structured app UI.
- **OUTPUT**: Implementation of `SafeArea` usage at the bottom avoiding system gestures. Proper handling for Smart Review badge visibility mapping (state updates without janky jumps).
- **VERIFY**: Confirm that state updates correctly show/hide Smart Review and UI correctly avoids bottom system indicator.

## ✅ PHASE X: Verification Checklist
- [ ] Project File Structure layout matched target.
- [ ] No Business Logic in Overlay (`CozyActionsOverlay` is strictly declarative).
- [ ] Routing Validation (6 directional buttons operate seamlessly).
- [ ] Lint: `flutter analyze` passes clean.
- [ ] Runtime: Hot-reload stable, gesture interaction safe at bottom.
