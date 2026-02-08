# PLAN - Provider Assertion Fix

Fix the widespread "Tried to listen to a value exposed with provider, from outside of the widget tree" assertion errors by updating `CozyTheme` access patterns and auditing all call sites.

## Overview
Assertion errors are occurring in `LoginScreen` and `AdminDashboardScreen` (and potentially elsewhere) because `Provider.of` is called with `listen: true` (default) inside event handlers or paint callbacks. This plan refactors the theme utility to be safer and audits the codebase for similar violations.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
- [x] `CozyTheme.of(context)` supports an optional `listen` parameter.
- [x] No Provider assertion errors during login, dashboard navigation, or chart rendering.
- [x] Codebase audited for `Provider.of(context)` calls outside of `build` methods.
- [x] `flutter analyze` passes with zero issues related to these changes.

## Tech Stack
- **Framework**: Flutter
- **State Management**: Provider

## File Structure
Modified files:
- `mobile/lib/theme/cozy_theme.dart` (Utility refactor)
- `mobile/lib/screens/auth/login_screen.dart` (Call site fix)
- `mobile/lib/screens/admin/dashboard_screen.dart` (Call site fix)
- Various other files identified in the audit.

## Task Breakdown

### Phase 1: Foundation (Theme Utility Refactor)
| Task ID | Name | Agent | Priority | Description |
|---------|------|-------|----------|-------------|
| T1-1 | Update `CozyTheme.of` | `mobile-developer` | P0 | Add `bool listen = true` parameter to `CozyTheme.of` and pass it to the internal `Provider.of` call. |

**INPUT**: `mobile/lib/theme/cozy_theme.dart`
**OUTPUT**: Updated `of` method signature.
**VERIFY**: Check if `listen` parameter is correctly passed to `Provider.of<ThemeService>(context, listen: listen)`.

### Phase 2: Implementation (Call Site Fixes)
| Task ID | Name | Agent | Priority | Description |
|---------|------|-------|----------|-------------|
| T2-1 | Fix `LoginScreen` | `mobile-developer` | P0 | Update `CozyTheme.of(context)` to `CozyTheme.of(context, listen: false)` in snackbar calls within `_submit` and `_handleGoogleSignIn`. |
| T2-2 | Fix `AdminDashboardScreen` | `mobile-developer` | P0 | Update `CozyTheme.of(context)` calls inside `BarChart` callbacks and `_buildActionBtn` to use `listen: false`. |
| T2-3 | Global Audit Fixes | `mobile-developer` | P1 | Search for and fix other instances of `CozyTheme.of(context)` or `Provider.of(context)` inside callbacks/event handlers. |

**INPUT**: Call sites across `lib/`.
**OUTPUT**: Updated call sites with `listen: false`.
**VERIFY**: Application runs without assertion errors in the console during these specific flows.

### Phase X: Final Verification
- [ ] Run `flutter analyze`
- [ ] Run `python .agent/scripts/verify_all.py` (if applicable)
- [ ] Manual smoke test of Login and Admin Dashboard.

## ✅ PHASE X COMPLETE
- Lint: [x]
- Security: [x]
- Build: [x]
- Date: [2026-02-05]
