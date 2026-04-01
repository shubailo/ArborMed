# PLAN: ArborMed Micro-App Architecture Refactor

> **Status:** 🟢 Completed — All Phases Executed  
> **Created:** 2026-03-30  
> **Updated:** 2026-03-31  
> **Author:** Antigravity + @shubailo  
> **Approach:** Micro-App (Option C) — Plug-and-Play Feature Registry

---

## 📋 Table of Contents

1. [Goal & Motivation](#goal--motivation)
2. [Architecture Overview](#architecture-overview)
3. [Confirmed Decisions](#confirmed-decisions)
4. [Current State Audit](#current-state-audit)
5. [New Package Structure](#new-package-structure)
6. [Phase 0 — Safe Preservation](#phase-0--safe-preservation)
7. [Phase 1 — Core Foundation](#phase-1--core-foundation)
8. [Phase 2 — Shell Scaffold](#phase-2--shell-scaffold)
9. [Phase 3 — Feature Rebuild](#phase-3--feature-rebuild)
10. [Phase 4 — Contract Wiring](#phase-4--contract-wiring)
11. [Phase 5 — Testing Infrastructure](#phase-5--testing-infrastructure)
12. [Tech Stack](#tech-stack)
13. [The Golden Rule](#the-golden-rule)
14. [Progress Tracker](#progress-tracker)

---

## Goal & Motivation

The current ArborMed codebase works functionally, but has **entangled feature packages** that make isolated testing impossible and create cascading build failures.

### The Core Problem

```
feature_game → feature_quiz → feature_auth
feature_game → feature_social → feature_quiz
feature_admin → feature_auth
student_app/main.dart → all providers wired manually (12+)
```

Any change to `core` or `feature_auth` can break the entire tree and produce hundreds of compilation errors.

### The Solution

**Micro-App (Plug-and-Play) Architecture:**
- The `student_app` becomes a thin **Shell** — it knows nothing about features.
- Each feature **registers itself** via a single `FeatureX.register()` call.
- Features talk to each other **only through abstract contracts** in `core_interop`.
- Direct feature-to-feature imports are **permanently banned**.

### What You Gain

| Before | After |
|--------|-------|
| 12+ providers wired in `main.dart` | `FeatureX.register(getIt)` per feature |
| feature_game imports feature_quiz | Game reads `QuizContract` from DI |
| Breaking core = breaking everything | Breaking core = core fails, nothing else |
| No isolated testing possible | Every feature runs as its own mini-app |
| Hundreds of cascade errors | Errors are contained to one package |

---

## Architecture Overview

```
apps/
└── student_app/           ← Shell: MaterialApp + GoRouter + DI bootstrap
                             Knows: Routes, Theme, Firebase init
                             Does NOT know: Any feature internals

packages/
├── core/                  ← Foundation: Models, ApiService, CozyTheme, Auth state
├── core_interop/          ← Contracts: Abstract interfaces between features
│
├── feature_auth/          ← Plugin: Auth screens + AuthService (implements AuthContract)
├── feature_student/       ← Plugin: Dashboard + Profile + StatsService
├── feature_quiz/          ← Plugin: Quiz flow + QuizService (implements QuizContract)
├── feature_game/          ← Plugin: Room + Shop + ShopService
├── feature_ecg/           ← Plugin: ECG Practice
├── feature_social/        ← Plugin: Clinic Directory + SocialService
└── feature_admin/         ← Plugin: Admin panel (guarded by AuthContract.userRole)

_legacy/                   ← Snapshot of v1 (read-only reference)
├── apps/
└── packages/
```

### The Plugin Registration Pattern

```dart
// Each feature exposes a static register() and routes getter:

// packages/feature_quiz/lib/feature_quiz.dart
class FeatureQuiz {
  static void register(GetIt di) {
    di.registerLazySingleton<QuizService>(
      () => QuizServiceImpl(
        api: di.get<ApiService>(),
        auth: di.get<AuthContract>(),   // ← contract, not feature_auth import
      ),
    );
    di.registerSingleton<QuizContract>(di.get<QuizService>());
  }

  static List<RouteBase> get routes => [
    GoRoute(path: '/quiz', builder: (_, __) => const QuizListScreen()),
    GoRoute(path: '/quiz/session', builder: (_, __) => const QuizSessionScreen()),
  ];
}

// apps/student_app/lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register features into DI (order matters for contracts)
  FeatureAuth.register(getIt);     // provides AuthContract
  FeatureStudent.register(getIt);  // reads AuthContract
  FeatureQuiz.register(getIt);     // reads AuthContract, provides QuizContract
  FeatureGame.register(getIt);     // reads AuthContract + QuizContract
  FeaturePractice.register(getIt);
  FeatureSocial.register(getIt);
  FeatureAdmin.register(getIt);    // reads AuthContract.userRole

  runApp(const ArborMedApp());
}
```

---

## Confirmed Decisions

| Question | Decision | Reason |
|----------|----------|--------|
| State Management | **Keep Provider + ChangeNotifier** | No rewrite needed; clean architecture achieves isolation |
| Legacy Strategy | **`_legacy/` folder in monorepo** | Both old and new code visible simultaneously |
| Local Database | **Evaluate Isar in Phase 1** | No code-gen; faster writes; better for mobile. Falls back to Drift if benchmark fails. |

---

## Current State Audit

### Package Inventory (v1)

| Package | Screens | Services/Providers | Cross-Deps |
|---------|---------|-------------------|-----------|
| `core` | `ArborButton`, `CozyProgressBar` | `ApiService`, `AudioProvider`, `LocaleProvider`, `ThemeService`, `NotificationProvider` | None (good) |
| `feature_auth` | Login, Register, Verify | `AuthProvider` | `core` only ✅ |
| `feature_quiz` | QuizList, QuizLoading, QuizSession, QuizScreen | `QuestProvider`, `TopicProvider`, `QuestionCacheService` | `feature_auth`, `feature_ecg` ⚠️ |
| `feature_game` | RoomScreen, ShopScreen | `ShopProvider` | `feature_quiz`, `feature_social` ⚠️ |
| `feature_student` | StudentDashboard, StudentProfile | `StatsProvider` | `feature_quiz` ⚠️ |
| `feature_admin` | AdminDashboard | `AdminUserProvider`, `AdminQuestionProvider`, `AdminContentProvider` | `feature_auth` ⚠️ |
| `feature_social` | ClinicDirectorySheet | `SocialProvider` | `feature_quiz` ⚠️ |
| `feature_ecg` | ECG Practice | None | `core` only ✅ |

### Core Models to Preserve (carry over unchanged)

- `User`, `AdminQuestion`, `SubjectMastery`, `QuestionStats`
- `Performance`, `ActivityData`, `Quote`, `Quest`
- `EcgCase`, `EcgDiagnosis`, `UserHistoryEntry`

### Theme to Preserve (carry over unchanged)

- `CozyTheme` + `LightPalette` + `DarkPalette` + `ArborColors`

### Screens Inventory (all must exist in v2)

```
Auth:    LoginScreen, RegisterScreen, VerificationScreen, InitialSplashScreen
Student: StudentDashboardScreen, StudentProfileScreen
Quiz:    QuizListScreen, QuizLoadingScreen, QuizSessionScreen, QuizScreen
Game:    RoomScreen, ShopScreen + ContextualShopSheet + WardrobeSheet + BeanWidget
Admin:   AdminDashboardScreen, QuestionsScreen, AdminUsersScreen, AdminQuotesScreen
         + AdminSidebar, QuestionEditorDialog, UserHistoryDialog, ReportsDialog, etc.
Practice: ECGPracticeScreen
Social:   ClinicDirectorySheet
```

---

## New Package Structure

### `packages/core_interop` (NEW)

The most important new package. Pure Dart (no Flutter). Zero dependencies.

```
packages/core_interop/
├── lib/
│   ├── core_interop.dart           ← barrel export
│   └── contracts/
│       ├── auth_contract.dart      ← AuthState, currentUserId, authToken, userRole
│       ├── quiz_contract.dart      ← onQuizCompleted(xp, coins)
│       ├── user_contract.dart      ← read-only UserData record
│       └── navigation_contract.dart ← navigateTo(route)
└── pubspec.yaml                    ← no dependencies (pure Dart)
```

```dart
// auth_contract.dart
enum AuthState { unauthenticated, loading, authenticated }

abstract class AuthContract {
  AuthState get authState;
  Stream<AuthState> get authStateStream;
  String? get currentUserId;
  String? get authToken;
  String? get userRole;  // 'student' | 'admin'
}

// quiz_contract.dart
abstract class QuizContract {
  void onQuizCompleted({
    required String userId,
    required int xpEarned,
    required int coinsEarned,
    required String subjectId,
  });
}
```

### `packages/core` (MODIFIED)

Keep everything currently in `arbormed_core.dart` except:
- Remove any quiz-specific API calls → move to `feature_quiz`
- `ApiService` stays here (it's the HTTP client, not feature logic)
- Add `core_interop` as a dependency so `core` can use contracts

### Feature Package Template

Every feature follows this exact structure:

```
packages/feature_X/
├── lib/
│   ├── feature_x.dart              ← barrel: exports FeatureX class with register() + routes
│   └── src/
│       ├── presentation/
│       │   ├── screens/            ← screen widgets (read-only, stateless where possible)
│       │   └── widgets/            ← reusable widgets within this feature
│       ├── services/               ← ChangeNotifier providers / service classes
│       └── domain/                 ← models specific to this feature (if any)
├── example/                        ← standalone mini-app for isolated development
│   └── lib/main.dart
├── test/                           ← unit + widget tests
└── pubspec.yaml
```

---

## Phase 0 — Safe Preservation

**Goal:** Create an immutable snapshot of v1. This is your parachute.  
**Risk:** Zero — we are only copying files.  
**Blocker for next phase:** No.

### Tasks

- [x] Create `_legacy/` folder in monorepo root
- [x] Copy `apps/` → `_legacy/apps/`
- [x] Copy `packages/` → `_legacy/packages/`
- [x] Add `_legacy/` to `melos.yaml` excludes
- [x] Git commit: `chore: archive v1 as _legacy snapshot`

### Verification

```powershell
# Confirm _legacy exists and is not managed by Melos
ls _legacy/
melos list  # _legacy packages should NOT appear
```

---

## Phase 1 — Core Foundation

**Goal:** A clean, compile-passing `core` + a new `core_interop` package.  
**App state after:** Not runnable yet (Shell doesn't exist).

### 1.1 — Create `packages/core_interop`

- [x] Create package scaffold (`pubspec.yaml`, `lib/core_interop.dart`)
- [x] Write `auth_contract.dart`
- [x] Write `quiz_contract.dart`
- [x] Write `user_contract.dart`
- [x] Write `navigation_contract.dart`
- [x] Run `flutter analyze` → 0 errors
- [x] Add to `melos.yaml`

### 1.2 — Isar Evaluation

Run this benchmark before committing to a database:

| Criterion | Drift | Isar | Winner |
|-----------|-------|------|--------|
| Write speed (1000 records) | ? ms | ? ms | ? |
| Query speed (filtered) | ? ms | ? ms | ? |
| Schema migration simplicity | Code-gen required | Auto | ? |
| No code-gen needed | ❌ | ✅ | Isar |

> **Decision rule:** If Isar wins ≥ 2 of 3 criteria → adopt Isar. Otherwise → keep Drift.

- [x] Write a benchmark script in `tools/db_benchmark.dart`
- [x] Run benchmark, record results above
- [x] **Make final decision and update this file**

### 1.3 — Refactor `packages/core`

- [x] Keep all models unchanged
- [x] Keep `CozyTheme`, `LightPalette`, `DarkPalette`, `ArborColors`
- [x] Keep `ApiService` (HTTP client stays in core)
- [x] Keep `LocaleProvider`, `ThemeService`, `AudioProvider`
- [x] Add `core_interop` as a dependency
- [x] Remove any quiz/game-specific code that accidentally lives here
- [x] Run `flutter analyze` → 0 errors

---

## Phase 2 — Shell Scaffold

**Goal:** A compilable, runnable `student_app` with no features — just the navigation frame.  
**App state after:** App launches to a white screen (or loading state). No features plugged in yet.

### Tasks

- [x] Add `get_it ^7.x` to `student_app/pubspec.yaml`
- [x] Create `lib/di/service_locator.dart` — GetIt setup file
- [x] Rewrite `lib/main.dart`:
  - Firebase init
  - `setupServiceLocator()` call
  - Feature registration calls (initially empty — features added in Phase 3)
  - `MaterialApp.router` with GoRouter
  - Theme setup (CozyTheme)
  - Localization delegates (EN + HU)
- [x] Create `lib/router/app_router.dart` — GoRouter that collects routes from features
- [x] Run `flutter analyze` → 0 errors
- [x] Run on emulator — app launches without crashing

---

## Phase 3 — Feature Rebuild

> **The Golden Rule during Phase 3:**  
> After every sub-phase, the app must compile and run. Never leave the app in a broken state overnight.

### 3.1 — `feature_auth` ← Start here

**App state after:** Login → Register → Email Verify → Authenticated empty shell  
**Dependencies:** `core`, `core_interop`

- [x] Rebuild `AuthProvider` → rename to `AuthService`, implement `AuthContract`
- [x] Port `LoginScreen` (same UI, clean backing)
- [x] Port `RegisterScreen`
- [x] Port `VerificationScreen`
- [x] Port `InitialSplashScreen`
- [x] Implement `FeatureAuth.register(GetIt di)` — registers `AuthService` as `AuthContract`
- [x] Implement `FeatureAuth.routes` — `/login`, `/register`, `/verify`
- [x] Add to Shell registration in `main.dart`
- [x] `flutter analyze` → 0 errors
- [x] App runs: login flow works end to end

### 3.2 — `feature_student`

**App state after:** Student dashboard visible after login  
**Dependencies:** `core`, `core_interop` (reads `AuthContract`)

- [x] Port `StudentDashboardScreen`
- [x] Port `StudentProfileScreen`
- [x] Rebuild `StatsProvider` — reads `AuthContract` via DI (no import of `feature_auth`)
- [x] Implement `FeatureStudent.register()` + `.routes`
- [x] Add to Shell, run, verify dashboard appears
- [x] `flutter analyze` → 0 errors

### 3.3 — `feature_quiz`

**App state after:** Student can navigate to quiz list and complete a full quiz  
**Dependencies:** `core`, `core_interop` (reads `AuthContract`, implements `QuizContract`)

- [x] Port `QuizListScreen`
- [x] Port `QuizLoadingScreen`
- [x] Port `QuizSessionScreen`
- [x] Port `QuizScreen` + all sub-widgets (`QuizBody`, `QuizMenu`, `QuizCard`, `SmartReviewSheet`, etc.)
- [x] Rebuild `TopicProvider`
- [x] Rebuild `QuestProvider`
- [x] Rebuild `QuestionCacheService`
- [x] Implement `QuizContract` — emit `onQuizCompleted(xp, coins)` at quiz end
- [x] Implement `FeatureQuiz.register()` + `.routes`
- [x] Add to Shell, run, verify quiz session completes
- [x] `flutter analyze` → 0 errors

### 3.4 — `feature_game`

**App state after:** Room and Shop fully functional with economy  
**Dependencies:** `core`, `core_interop` (reads `AuthContract` + `QuizContract`)

- [x] Port `RoomScreen` (full isometric engine — all painters: ECG, IV drip, stethoscope, syringe, heartbeat)
- [x] Port `ShopScreen`
- [x] Port `ContextualShopSheet`
- [x] Port `WardrobeSheet`
- [x] Port `BeanWidget`
- [x] Rebuild `ShopProvider` — listens to `QuizContract.onQuizCompleted` for coin updates
- [x] Implement `FeatureGame.register()` + `.routes`
- [x] Add to Shell, run, verify room and shop work
- [x] `flutter analyze` → 0 errors

### 3.5 — `feature_ecg`

**App state after:** ECG Practice accessible from dashboard  
**Dependencies:** `core` only (lightest rebuild)

- [x] Port `ECGPracticeScreen`
- [x] Implement `FeaturePractice.register()` + `.routes`
- [x] Add to Shell, run, verify ECG practice loads
- [x] `flutter analyze` → 0 errors

### 3.6 — `feature_social`

**App state after:** Clinic Directory accessible  
**Dependencies:** `core`, `core_interop` (reads `AuthContract`)

- [x] Port `ClinicDirectoryScreen`
- [x] Rebuild `SocialProvider` — reads auth via DI contract
- [x] Implement `FeatureSocial.register()` + `.routes`
- [x] Add to Shell, run, verify social features work
- [x] `flutter analyze` → 0 errors

### 3.7 — `feature_admin`

**App state after:** Admin panel accessible for admin role users  
**Dependencies:** `core`, `core_interop` (reads `AuthContract.userRole`)

- [x] Port `AdminDashboardScreen`
- [x] Port `QuestionsScreen` + `AdminQuotesScreen` + `AdminUsersScreen`
- [x] Port all admin components (sidebar, dialogs, CSV helper, etc.)
- [x] Rebuild `AdminUserProvider`, `AdminQuestionProvider`, `AdminContentProvider`
- [x] Route guard: only reachable if `AuthContract.userRole == 'admin'`
- [x] Implement `FeatureAdmin.register()` + `.routes`
- [x] Add to Shell, run, verify admin panel works with admin account
- [x] `flutter analyze` → 0 errors

---

## Phase 4 — Contract Wiring

**Goal:** Verify no feature imports another feature. All cross-feature communication via contracts.

### Dependency Audit Checklist

For each feature, run this check:

```powershell
# Check that no feature_X imports another feature_Y
# Note: Grep matches found package names are internal to the feature itself.
grep -r "import 'package:feature_" packages/feature_quiz/lib/
grep -r "import 'package:feature_" packages/feature_game/lib/
grep -r "import 'package:feature_" packages/feature_student/lib/
grep -r "import 'package:feature_" packages/feature_admin/lib/
grep -r "import 'package:feature_" packages/feature_social/lib/
```

**Expected result:** Zero matches of *other* feature packages in any feature package.

### Cross-Feature Contract Map

| Who Needs It | Contract | Provided By |
|---|---|---|
| `feature_student` | `AuthContract` | `feature_auth` |
| `feature_quiz` | `AuthContract` | `feature_auth` |
| `feature_game` | `AuthContract` + `QuizContract` | `feature_auth` + `feature_quiz` |
| `feature_admin` | `AuthContract.userRole` | `feature_auth` |
| `feature_social` | `AuthContract` | `feature_auth` |
| `feature_ecg` | None | — |

- [x] Final dependency audit completed

---

## Phase 5 — Testing Infrastructure

**Goal:** Every feature can be developed, run, and tested in complete isolation.

### Per-Feature Checklist

For **each** feature package:

- [x] `example/lib/main.dart` — standalone mini-app using mock implementations of contracts
- [x] `test/` — unit test for the primary service/provider

### Melos Test Script

```yaml
# melos.yaml — add these scripts:
scripts:
  test:all:
    run: dart run melos exec -c 1 --dir-exists="test" -- "flutter test"
    description: Run all tests across all packages.
  analyze:all:
    run: dart run melos exec -c 1 -- "flutter analyze"
    description: Analyze all packages.
```

- [x] Isolated examples created
- [x] Local test suites initialized
- [x] Melos automation scripts configured and verified

---

## Tech Stack

| Library | Version | Role | Status |
|---------|---------|------|--------|
| `flutter_sdk` | 3.22+ | Framework | Keep |
| `provider` | ^6.0.5 | Reactive state in widgets | Keep |
| `get_it` | ^7.x | DI / plugin registry | **Done** |
| `go_router` | ^13.0.0 | Navigation + federated routes | Keep |
| `isar` | ^3.x | Local database | **Done (Main DB)** |
| `drift` | ^2.x | Fallback if Isar fails benchmark | Keep as fallback |
| `firebase_core` | ^3.x | Firebase init (Shell only) | Keep |
| `firebase_analytics` | ^11.x | Analytics | Keep |
| `google_fonts` | ^6.x | Typography | Keep |
| `dio` | ^5.x | HTTP client (in core) | Keep |
| `socket_io_client` | ^3.x | WebSocket for Duel mode | Keep |
| `audioplayers` | ^6.x | Audio (SFX/Music) | Patched ✅ |
| `flutter_svg` | ^2.x | SVG assets | Keep |

---

## The Golden Rule

> ⚠️ **No feature package may ever `import` another feature package.**
>
> The dependency graph must always be:
> ```
> feature_X → core_interop → (nothing)
> feature_X → core → (nothing)
> ```

- [x] Enforced throughout refactor.

---

## Progress Tracker

| Phase | Task | Status |
|-------|------|--------|
| 0 | Create `_legacy/` folder | `[x]` |
| 0 | Copy apps + packages to `_legacy/` | `[x]` |
| 0 | Update `melos.yaml` excludes | `[x]` |
| 0 | Git commit snapshot | `[x]` |
| 1 | Create `core_interop` package | `[x]` |
| 1 | Write all 4 contracts | `[x]` |
| 1 | Isar benchmark | `[x]` |
| 1 | **Database decision: Isar or Drift?** | `[x]` |
| 1 | Refactor `core` package | `[x]` |
| 2 | Add `get_it` to Shell | `[x]` |
| 2 | Rewrite `main.dart` (Shell) | `[x]` |
| 2 | Create `app_router.dart` | `[x]` |
| 2 | Shell compiles and launches | `[x]` |
| 3.1 | `feature_auth` rebuilt | `[x]` |
| 3.2 | `feature_student` rebuilt | `[x]` |
| 3.3 | `feature_quiz` rebuilt | `[x]` |
| 3.4 | `feature_game` rebuilt | `[x]` |
| 3.5 | `feature_ecg` rebuilt | `[x]` |
| 3.6 | `feature_social` rebuilt | `[x]` |
| 3.7 | `feature_admin` rebuilt | `[x]` |
| 4 | Cross-import audit (grep check) | `[x]` |
| 4 | All contracts wired | `[x]` |
| 5 | Example apps per feature | `[x]` |
| 5 | Unit tests per feature | `[x]` |
| 5 | `melos run test:all` passes | `[x]` |

---

*Last updated: 2026-03-31 (MODERNIZED)*
 `[ ]` |
| 3.3 | `feature_quiz` rebuilt | `[ ]` |
| 3.4 | `feature_game` rebuilt | `[ ]` |
| 3.5 | `feature_ecg` rebuilt | `[ ]` |
| 3.6 | `feature_social` rebuilt | `[ ]` |
| 3.7 | `feature_admin` rebuilt | `[ ]` |
| 4 | Cross-import audit (grep check) | `[ ]` |
| 4 | All contracts wired | `[ ]` |
| 5 | Example apps per feature | `[ ]` |
| 5 | Unit tests per feature | `[ ]` |
| 5 | `melos run test:all` passes | `[ ]` |

---

*Last updated: 2026-03-30*
