# PLAN: Mobile Dependency Update

This plan outlines the systematic update of core mobile dependencies to their latest stable versions to improve stability, security, and performance.

## Status: 🟢 PLANNING
**Agent:** `project-planner`
**Domain:** Mobile (Flutter)

---

## 🎯 Success Criteria
- [ ] All dependencies in `pubspec.yaml` updated to target versions.
- [ ] `flutter pub get` resolves without version conflicts.
- [ ] Application compiles successfully for Android (`debug` build).
- [ ] Core features (Auth, Database, Audio) verified in a single test cycle.

---

## 🛠️ Tech Stack Updates
| Package | Current | Target | Rationale |
|---------|---------|--------|-----------|
| `google_sign_in` | `^6.2.1` | `^7.2.0` | Fixes for Error 10 & PlatformException |
| `firebase_core` | `^4.4.0` | `^4.5.1` | Compatibility with latest Google Sign-In |
| `geolocator` | `^11.0.0` | `^14.0.2` | Improved Android 14/15 support |
| `drift` | `^2.16.0` | `^2.31.0` | Performance & Query optimization |
| `sqlite3_flutter_libs`| `^0.5.21` | `^0.5.25` | Sync with latest Drift |
| `file_picker` | `8.1.7` | `^10.3.10` | Better file handling & permission support |
| `audioplayers` | `^5.2.1` | `^6.5.1` | Modernized API & improved stability |
| `vibration` | `^2.0.1` | `^3.1.5` | Improved haptic support |

---

## 📋 Task Breakdown

### Phase 1: Dependency Bump
**Agent: `mobile-developer`**
- [ ] **Task T1**: Update `pubspec.yaml` with target versions.
  - **Input**: Current `pubspec.yaml`
  - **Output**: Updated `pubspec.yaml`
  - **Verify**: `flutter pub get` successful.
- [ ] **Task T2**: Resolve immediate version conflicts (if any).
  - **Input**: Resolution errors from `pub get`.
  - **Output**: Fine-tuned dependency constraints.
  - **Verify**: Clean `pubspec.lock` generated.

### Phase 2: API Refactoring
**Agent: `mobile-developer`**
- [ ] **Task T3**: Refactor `audioplayers` usage.
  - **Reason**: Major API changes in 6.x.
  - **Files**: `lib/services/audio_provider.dart`
  - **Verify**: No static analysis errors in `audio_provider.dart`.
- [ ] **Task T4**: Verify/Refactor `google_sign_in` usage.
  - **Files**: `lib/services/auth_provider.dart`
  - **Verify**: No static analysis errors in `auth_provider.dart`.

### Phase 3: Verification (PHASE X)
**Agent: `test-engineer`**
- [ ] **Task T5**: Full project analysis.
  - **Command**: `flutter analyze`
  - **Verify**: 0 errors/warnings (or same as baseline).
- [ ] **Task T6**: Android Debug Build.
  - **Command**: `flutter build apk --debug`
  - **Verify**: Successful compilation.
- [ ] **Task T7**: Manual Smoketest.
  - **Check**: Google Login, Audio Playback, DB Sync.

---

## ⚠️ Risks & Rollback
- **Risk**: `drift` or `geolocator` updates might require native build tool upgrades (Gradle/Kotlin).
- **Rollback**: Revert `pubspec.yaml` to previous state using `git checkout`.
