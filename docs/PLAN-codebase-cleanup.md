# 🧹 PLAN: Systematic Codebase Cleanup & Optimization

## 📋 Context
- **Goal**: Optimize codebase by removing unused code, applying safe automated fixes, and pruning legacy artifacts (Sync, local-first logic).
- **Strategy**: **Strict Cleanup** (remove commented blocks) with **Interactive Confirmation** (ask before deleting files).
- **Scope**: Mobile (Flutter), Backend (Node.js), and Root Directory.

## ⚠️ User Confirmation (Socratic Gate)
- [x] **Automated Fixes**: Confirmed (`dart fix --apply`).
- [x] **Strict Cleanup**: Confirmed (remove commented-out blocks).
- [x] **Deletion Strategy**: Interactive (ask before file deletion).

---

## 🚀 Phase 1: Automated Optimization (Mobile)
Focus on safe, automated cleanups using Flutter's built-in tools.
- [ ] **Run `dart fix --apply`**: Automatically resolves deprecated APIs and unused imports.
- [ ] **Run `flutter analyze`**: Identify remaining issues (dead code, unused variables).
- [ ] **Optimize Imports**: Sort and remove unused imports in all files.
- [ ] **Format Code**: Run `dart format .` for consistent style.

## 🧹 Phase 2: Legacy Code Removal (Strict)
Manually target and remove commented-out blocks leftover from the "Online-Truth" migration.
- [ ] **Audit `main.dart`**: Remove commented `SyncService` initialization.
- [ ] **Audit `auth_provider.dart`**: Remove commented legacy sync methods.
- [ ] **Audit `quiz_menu.dart`**: Remove commented offline checks.
- [ ] **Audit `database.dart`**: Remove commented-out table definitions (SyncActions).
- [ ] **General Scan**: Search for `// TODO: Remove` or `// Legacy` comments and clean up.

## 📉 Phase 3: Root & Asset Pruning (Interactive)
Identify and propose validation for root-level clutter.
- [ ] **Scan Root Directory**: List all `.xlsx`, `.csv`, `.txt` files.
- [ ] **Propose Deletion**: Ask user which temporary data files to keep.
- [ ] **Scan `assets/`**: Identify unused images/icons (using `unused_assets` package if available, or manual check).

## 🛠️ Phase 4: Backend Cleanup
Ensure no dead routes or controllers remain.
- [ ] **Audit `routes/`**: specific check for `/sync` related routes.
- [ ] **Audit `models/`**: Check for `SyncActions` model or unused migrations.
- [ ] **Consolidate**: Ensure `quizController.js` and `shopController.js` are the only active sources of truth.

## ✅ Phase 5: Verification
- [ ] **Mobile Build**: `flutter build apk --debug` must succeed.
- [ ] **Static Analysis**: `flutter analyze` must return 0 issues.
- [ ] **Backend Start**: `npm start` must run without crashes or legacy warnings.
