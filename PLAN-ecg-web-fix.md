# PLAN: ECG Web "Grey Screen" Fix

## Overview
This plan addresses the "grey screen" crash on Flutter Web during ECG case submission and icon management. The root cause is the usage of `dart:io` and `Platform.is...` checks in UI-related code, which are incompatible with the web environment.

- **Project Type**: MOBILE (Flutter)
- **Problem**: Runtime crash due to `Unsupported operation: Platform._operatingSystem` on web.

## Success Criteria
- [ ] ECG Case Editor opens, picks image, and saves without crashing on web.
- [ ] Icon Manager opens, picks image, and uploads without crashing on web.
- [ ] List views refresh correctly after save operations.
- [ ] No `dart:io` or `Platform` references remain in non-conditionally imported UI files.

## Tech Stack
- **Flutter / Dart**
- **package:flutter/foundation.dart** (for `kIsWeb` and `defaultTargetPlatform`)
- **ImagePicker** (already used, needs web-safe preview)

## Task Breakdown

### Phase 1: Foundation & Utilities
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| T1.1 | Audit `ApiService` for Platform usage | `mobile-developer` | clean-code | None |
| T1.2 | Refactor `ApiService` to use `defaultTargetPlatform` | `mobile-developer` | clean-code | T1.1 |

**T1.2 INPUT → OUTPUT → VERIFY**
- **INPUT**: `mobile/lib/services/api_service.dart`
- **OUTPUT**: Removed `dart:io`, added `package:flutter/foundation.dart`, replaced `Platform.isAndroid` with `defaultTargetPlatform == TargetPlatform.android`.
- **VERIFY**: No `dart:io` import remains in the file.

### Phase 2: UI Dialog Fixes
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| T2.1 | Fix `ECGEditorDialog` web compatibility | `mobile-developer` | mobile-design | T1.2 |
| T2.2 | Fix `IconManagerDialog` web compatibility | `mobile-developer` | mobile-design | T1.2 |

**T2.1 INPUT → OUTPUT → VERIFY**
- **INPUT**: `mobile/lib/screens/admin/ecg_editor_dialog.dart`
- **OUTPUT**: Replaced `Image.file` with logic checking `kIsWeb`. Use `Image.network(file.path)` for web preview.
- **VERIFY**: Pick an image in the editor; the preview should render without a crash.

### Phase X: Final Verification
- [ ] **Lint Check**: Run `flutter analyze` ensuring no imports of `dart:io` in the affected files.
- [ ] **Web Runtime Check**: Manually test the ECG "Save 7+2 Case" flow in a web browser.
- [ ] **Mobile Regression**: Ensure image picking/saving still works on mobile (Android/iOS).

## Agent Assignments
- **Primary Agent**: `mobile-developer` (handles all mobile/web-shared Flutter code).
- **Consultant**: `project-planner` (plan structure).
