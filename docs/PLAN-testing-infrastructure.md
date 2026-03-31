# PLAN: ArborMed Testing & Integration Infrastructure

> **Status:** 🟡 Planned  
> **Created:** 2026-03-31  
> **Author:** Antigravity (project-planner)  
> **Project Type:** MOBILE  

---

## 📋 Overview
This plan outlines the completion of Phase 5 of the ArborMed Micro-App Refactor. With all features rebuilt and contracts wired, the final step is to ensure rigorous isolated testing and complete end-to-end (E2E) verification. We will add example applications, unit/widget tests for the core modules, and ensure monorepo scripts can validate the entire project seamlessly.

## 🎯 Success Criteria
1. **Isolated Execution:** Every feature package contains an `example/lib/main.dart` that runs independently from the Shell app using mocked interop contracts.
2. **High Test Coverage:** `feature_auth`, `feature_student`, `feature_quiz`, and `feature_game` possess comprehensive unit and widget tests.
3. **Monorepo Automation:** Executing `melos run test:all` and `melos run analyze:all` passes across all packages with zero errors.
4. **Integration Confirmed:** An E2E smoke test inside the `student_app` proves that completing a task (e.g., a Quiz) correctly resolves cross-feature contracts (e.g., granting XP in Student profile and Coins in Game shop).

## 💻 Tech Stack
- **Flutter SDK (3.22+)**: Framework
- **melos**: Monorepo script management and task running
- **flutter_test**: Core test framework
- **mocktail**: Elegant mocking library for isolating `core_interop` contracts during tests

## 📂 File Structure
```
packages/feature_*/
├── example/
│   └── lib/
│       └── main.dart          ← Standalone entry point with mocked GetIt contracts
└── test/
    ├── services/
    │   └── *_service_test.dart ← Unit tests for Isar/logic layer
    └── presentation/
        └── *_screen_test.dart  ← Widget tests for UI components
melos.yaml                     ← Updated with test scripts
```

---

## 🛠️ Task Breakdown

### Task 1: Initialize Example Mini-Apps
- **Agent**: `mobile-developer`
- **Skill**: `app-builder`
- **Dependencies**: None
- **INPUT**: `packages/feature_{auth,student,quiz,game,admin}`
- **OUTPUT**: Created `example/lib/main.dart` in each package. Configured with a basic `MaterialApp` and mocked `GetIt` registrations for `core_interop` contracts to satisfy dependencies.
- **VERIFY**: Running `cd packages/feature_X/example && flutter run` successfully launches the feature's primary UI.

### Task 2: Implement Missing Test Suites
- **Agent**: `test-engineer` (or `mobile-developer` with testing skills)
- **Skill**: `testing-qa` / `unit-testing-test-generate`
- **Dependencies**: Task 1 (Mock setups can be reused)
- **INPUT**: Application logic and UI within `feature_auth`, `feature_student`, `feature_quiz`, and `feature_game`.
- **OUTPUT**: Comprehensive `test/` catalogs testing local Isar data persistence, logic services, and Widget states.
- **VERIFY**: `flutter test` completes successfully in each respective directory.

### Task 3: Setup Melos Automation
- **Agent**: `devops-engineer` or `mobile-developer`
- **Skill**: `cloud-devops` / `melos`
- **Dependencies**: Task 2
- **INPUT**: `melos.yaml` in project root.
- **OUTPUT**: Added `test:all` and `analyze:all` execution commands that automatically bootstrap and run across all `packages/*`.
- **VERIFY**: `melos run test:all` executes globally and returns an exit code of `0`.

### Task 4: E2E Smoke Test & Integration Verification
- **Agent**: `test-engineer`
- **Skill**: `webapp-testing` / `e2e-testing`
- **Dependencies**: Task 3
- **INPUT**: `apps/student_app` running in emulator.
- **OUTPUT**: Manual or automated validation ensuring Isar data flows correctly when contracts invoke callbacks across boundaries.
- **VERIFY**: 
  1. Boot `student_app`.
  2. Complete a short quiz session.
  3. Verify XP was granted on the Student Dashboard.
  4. Verify Coins were granted in the Game Wardrobe/Shop.

---

## ✅ PHASE X: Final Verification
Before considering the modular refactor officially closed, we must verify the following:

- [ ] **Lint**: `melos run analyze:all` passes perfectly.
- [ ] **Test**: `melos run test:all` passes flawlessly.
- [ ] **Build**: `flutter build apk` (or iOS equivalent) in `apps/student_app` builds without compilation errors.
- [ ] **Data Integrity**: Isar data safely persists across cold reboots.
- [ ] **Date Completed**: [TBD]
