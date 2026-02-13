# PLAN: ECG Submission Fix (Mobile Web)

## Overview
This plan addresses the "Grey Screen of Death" occurring after submitting an ECG analysis on mobile browsers (Android). The investigation indicates a runtime crash during the rendering of the results screen, likely caused by a type mismatch or null pointer exception when accessing nested JSON findings.

## Project Type: MOBILE (Flutter)

## Success Criteria
- [x] ECG analysis submission completes without a grey screen.
- [x] "Case Review" screen renders correctly for all ECG cases.
- [x] Missing or malformed database fields show "N/A" or fallbacks instead of crashing.
- [x] Secondary diagnoses and clinical management render safely.

## Tech Stack
- **Frontend**: Flutter (3.2x)
- **State Management**: Provider
- **Design System**: CozyTheme (Custom)

## File Structure
- `lib/screens/ecg_practice_screen.dart`: Primary logic for submission and report rendering.
- `lib/services/stats_provider.dart`: Model definitions for `ECGCase` and `ECGDiagnosis`.

## Task Breakdown

### Phase 1: Logic & Calculation Safety
| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 1.1 | **Robust Submission Calculation** | `mobile-developer` | `clean-code` | P0 |
| **Input** | `_submit()` method parameters |
| **Output** | Null-safe calculation of scores and intervals |
| **Verify** | No crash when `standard_findings_json` is partially null or empty |

### Phase 2: UI & Rendering Safety
| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 2.1 | **Type-Safe Report Card Rendering** | `mobile-developer` | `frontend-design` | P0 |
| **Input** | `_buildReportCard()` and `_feedbackReport` map |
| **Output** | UI widgets with null-safe accessors (e.g. `?.`, `??`) |
| **Verify** | Report card displays even if backend sanitizes `diagnosis_id` |

| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 2.2 | **Management & Secondary Dx Guards** | `mobile-developer` | `clean-code` | P1 |
| **Input** | `findings['management']` and `secondary_diagnoses_ids` |
| **Output** | Conditional rendering with `if (data is Map)` checks |
| **Verify** | No crash for cases without management or secondary findings |

## Phase X: Verification
- [ ] **Lint Check**: Run `flutter analyze` to ensure no new issues.
- [ ] **Manual Audit**: Verify that all `detailed.entries` in the report card use safe accessors.
- [ ] **Smoke Test**: Submit ECGs with various findings (all empty, all full, partial).
- [ ] **UX Audit**: Ensure the "Grey Screen" is replaced by at least an error message if something critical fails.

## ✅ Phase X Completion Marker
- Pending implementation.
