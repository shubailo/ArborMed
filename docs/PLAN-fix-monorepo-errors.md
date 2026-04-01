# Project Plan - Monorepo Stabilization (Zero-Issue Baseline)

This plan outlines the systematic resolution of all 101 discovered analysis issues (errors, warnings, and infos) across the ArborMed modular project. The goal is a clean `flutter analyze` state to ensure long-term maintainability and full feature parity.

## 🔴 Strategy: Clean-Slate Modularization

We will prioritize **Standardization** over **Quick Fixes**. This means performing a full refactor of theme property names and synchronizing data models across all features, rather than using temporary aliases.

## Phase 1: Core Standardization (The Foundation)
**Goal**: Ensure the primary library (`arbormed_core`) and the interop layer (`core_interop`) are perfectly clean and provide a stable contract for features.

- [ ] **1.1 Theme Synchronization**:
    - Update `CozyPalette` and its implementations (`LightPalette`, `DarkPalette`) to include all modern property names (`primaryContainer`, `secondaryContainer`, etc.).
    - Purge all legacy static constants from `CozyTheme`.
- [ ] **1.2 Interop Export Audit**:
    - Verify all contracts (`QuizContract`, `StudentContract`, `GameContract`) and their supporting models are exported in `core_interop.dart`.
- [ ] **1.3 Verification**: Run `flutter analyze packages/core packages/core_interop`.

## Phase 2: Feature Package Cleanup (Component by Component)
**Goal**: Reach 0 issues in each individual feature package.

- [ ] **2.1 Feature Student**:
    - Refactor `dashboard_screen.dart` and `student_profile_screen.dart` to use standardized theme properties.
    - Resolve model property mismatches (e.g., `subjectEn` vs `subject`).
- [ ] **2.2 Feature Quiz**:
    - Fix any broken internal references in widgets like `smart_review_sheet.dart`.
    - Ensure zero cross-package imports (everything must go through `core_interop`).
- [ ] **2.3 Feature Game**:
    - Finalize the shift from `withValues` to `withOpacity` for maximum environment compatibility.
- [ ] **2.4 Verification**: Run `flutter analyze packages/feature_*`.

## Phase 3: Shell & App Integration (The Bridge)
**Goal**: Resolve errors in the main application entry point and DI registry.

- [ ] **3.1 DI Registry Fix**:
    - Add missing imports for all modular features in `service_locator.dart`.
    - Verify the singleton/lazy registration patterns match the new contracts.
- [ ] **3.2 Navigation Sync**:
    - Ensure the `AppRouter` has access to all feature-specific routes.

## Phase 4: Final Verification (The Green Board)
**Goal**: Continuous zero-issue baseline.

- [ ] **4.1 Full Monorepo Run**: `flutter analyze --no-fatal-infos --no-fatal-warnings`.
- [ ] **4.2 Example App Audit**: Fix any remaining broken references in the feature-specific example apps to enable standalone testing.

---

## 🚀 Execution Command
Run `/create` after approval to begin Phase 1.
