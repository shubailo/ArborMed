# PLAN: UI Crash Prevention Strategy

This plan outlines a systemic approach to eliminate `RangeError` and other index-related crashes across the MedBuddy mobile application, focusing on dynamic list widgets and charts.

## Overview
Crashes related to `Index out of range` occur when UI state transitions (like data updates or filtering) happen faster than the gesture handling or rendering pipeline. We will implement global safety patterns to prevent these issues.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
- [ ] 0 `RangeError` reports during rapid timeframe switching in Analytics.
- [ ] `ListExtension.safeGet` applied to all high-risk list access points.
- [ ] Automated "Stress/Race" tests for all Bar and Radar charts.

## Tech Stack
- **Flutter/Dart**: Primary framework.
- **fl_chart**: Target for specialized safety.
- **Flutter Test**: For automated crash simulation.

## File Structure
- `mobile/lib/utils/extensions/list_extensions.dart`: [NEW] Safe access utilities.
- `mobile/test/visual/crash_simulation_test.dart`: [NEW] Automated stress tests.

## Task Breakdown

### Phase 1: Foundation (P0)
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| T1.1 | Create `SafeAccess` Extension | `mobile-developer` | `clean-code` | None |
| **INPUT** | `List<T>` | **OUTPUT** | `list.safeGet(index)` utility | **VERIFY** | Unit test for null return on out-of-bounds |

### Phase 2: Implementation - Charts (P1)
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| T2.1 | Audit `ActivityChart` | `mobile-developer` | `clean-code` | T1.1 |
| **INPUT** | `activity_chart.dart` | **OUTPUT** | Safety checks in 4 callbacks | **VERIFY** | Manual tap on edges during loading |
| T2.2 | Audit Radar/Proficiency Charts | `mobile-developer` | `clean-code` | T1.1 |
| **INPUT** | `proficiency_radar.dart` | **OUTPUT** | Safety checks in tooltips | **VERIFY** | No crashes on subject swap |

### Phase 3: Implementation - Dynamic Lists (P2)
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| T3.1 | Global Grep Audit for `[]` | `mobile-developer` | `clean-code` | T1.1 |
| **INPUT** | `lib/widgets` and `lib/screens` | **OUTPUT** | Refactors of high-risk index access | **VERIFY** | Build success |

### Phase 4: Verification (P3)
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| T4.1 | Create Crash Simulation Tests | `mobile-developer` | `testing-patterns`| T2.1 |
| **INPUT** | `BarChart` widget | **OUTPUT** | Test that pumps rapid data updates | **VERIFY** | Test passes with zero exceptions |

## Phase X: Final Verification
- [ ] Run `flutter test` on the new simulation suite.
- [ ] Manual touch-stress test on Admin Dashboard subjects.
- [ ] Verify `SafeAccess` is documented in `README.md` for team onboarding.
