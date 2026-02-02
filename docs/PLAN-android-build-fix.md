# Plan: Android Build Fix

Systematic upgrade of the Android build environment to resolve dependencies and build a fresh APK.

## Overview
The Android build is currently failing because modern Flutter plugins (like `audioplayers_android`) require updated SDK and NDK versions that exceed the project's current configuration. This plan upgrades the entire stack—Gradle, AGP, Kotlin, SDK, and NDK—to ensure compatibility and future-proof the build process.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
- Clean `flutter build apk --release` execution.
- No "deprecated" or "unsupported version" warnings in the Gradle log.
- APK successfully generated in `build/app/outputs/flutter-apk/app-release.apk`.

## Tech Stack
- **Gradle**: 8.12 (Latest stable for high AGP compatibility)
- **AGP**: 8.9.1 (Required for modern Android API 36 support)
- **Kotlin**: 2.1.0 (Latest stable for optimized compiles)
- **Java**: JDK 21 (Modern LTS standard)
- **Android SDK**: 36 (Highest version for plugin compatibility)
- **Android NDK**: 27.0.12077973 (Required by NDK-dependent plugins)

## File Structure (Affected Files)
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/settings.gradle`
- `android/build.gradle`
- `android/app/build.gradle`

## Task Breakdown

### Phase 1: Infrastructure Upgrade (P0)

| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---------|------|-------|--------|----------|--------------|-------------------------|
| T1 | Upgrade Gradle | `devops-engineer` | `powershell-windows` | P0 | None | Modify `gradle-wrapper.properties` → `distributionUrl` updated to 8.12 → Run `./gradlew -v` on Windows |
| T2 | Upgrade AGP | `devops-engineer` | `nodejs-best-practices` | P0 | T1 | Modify `settings.gradle` → `com.android.application` version set to 8.9.1 → `flutter pub get` succeeds |
| T3 | Upgrade Kotlin | `mobile-developer` | `clean-code` | P0 | None | Modify `build.gradle` → `ext.kotlin_version` set to 2.1.0 → Build script compiles |
| T4 | Upgrade Java | `devops-engineer` | `clean-code` | P0 | T2 | Modify `build.gradle` → `JavaVersion.VERSION_21` applied → `./gradlew help` succeeds |
| T5 | Update SDK/NDK | `mobile-developer` | `clean-code` | P0 | T2 | Modify `app/build.gradle` → `compileSdk`, `targetSdk`, `ndkVersion` updated → `flutter analyze` passes |

### Phase 2: Build & Verification (P1)

| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---------|------|-------|--------|----------|--------------|-------------------------|
| T6 | Build APK | `mobile-developer` | `webapp-testing` | P1 | T1-T5 | `flutter clean` && `flutter build apk --release` → Build log 100% success → APK file exists |

## Phase X: Verification
- [ ] Gradle version check: `gradlew -v` should show 8.12
- [ ] Build Log: No "dropped support" warnings
- [ ] APK File: `app-release.apk` present in output folder
- [ ] Final Analyze: `flutter analyze` returns 0 issues
