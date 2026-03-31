# PLAN: Remaining Features Refactor (Admin, Practice, Social)

## Overview
Rebuilding the final three modules (`feature_admin`, `feature_practice`, `feature_social`) and implementing the `IsarSeedingService` to migrate legacy data to the new modular architecture.

## Project Type
**MOBILE**

## Success Criteria
- [ ] Admin Module provides a working CMS for Isar questions and user roles.
- [ ] ECG Practice Module accurately renders organic waveforms and rewards XP.
- [ ] Clinic Directory (Social) displays facilities without map integration.
- [ ] `IsarSeedingService` successfully bulk-inserts legacy data into Isar.
- [ ] Codebase maintains 0 cross-feature imports.

## Tech Stack
- Dart / Flutter SDK (3.22+)
- **Isar** NoSQL (Local DB Migration)
- Provider + GetIt + GoRouter

## File Structure
```
packages/
├── feature_admin/        ← Question/User CMS
├── feature_practice/     ← ECG Waveform engine & challenges
├── feature_social/       ← Clinic Directory
└── core/
    └── lib/src/database/seeding/isar_seeding_service.dart
```

## Task Breakdown

### Phase 1: feature_practice (ECG Engine)
**Task 1.1: Practice Foundation**
- **Agent**: `mobile-developer`
- **Skill**: `clean-code`
- **INPUT**: `feature_practice` scaffold.
- **OUTPUT**: `PracticeService` handling ECG case progression.
- **VERIFY**: Unit tests pass for `PracticeService` state.

**Task 1.2: ECG Painter Port**
- **Agent**: `mobile-developer`
- **Skill**: `mobile-design`
- **INPUT**: Legacy `ECGMonitorPainter`.
- **OUTPUT**: Ported and themed `ECGMonitorPainter`.
- **VERIFY**: Renders cleanly on emulator with no jank.

### Phase 2: feature_social (Clinic Directory)
**Task 2.1: Social Scaffold**
- **Agent**: `mobile-developer`
- **Skill**: `clean-code`
- **INPUT**: `feature_social` scaffold.
- **OUTPUT**: `SocialService` and `ClinicDirectoryScreen`.
- **VERIFY**: List renders successfully and integrates with GoRouter.

### Phase 3: feature_admin (CMS & Users)
**Task 3.1: Admin Scaffold & Auth guard**
- **Agent**: `mobile-developer`
- **Skill**: `clean-code`
- **INPUT**: `feature_admin` and `AuthContract`.
- **OUTPUT**: `AdminDashboard` restricted to `admin` role.
- **VERIFY**: Non-admin users redirected, admins can view dashboard.

**Task 3.2: Question CMS**
- **Agent**: `database-architect`
- **Skill**: `database-design`
- **INPUT**: Isar `QuestionCollection`.
- **OUTPUT**: CRUD screens for Questions via `AdminService`.
- **VERIFY**: Can create/edit/delete a question via Admin UI.

**Task 3.3: IsarSeedingService**
- **Agent**: `mobile-developer`
- **Skill**: `clean-code`
- **INPUT**: Legacy JSON files and new `DatabaseService`.
- **OUTPUT**: `IsarSeedingService` to bulk load data.
- **VERIFY**: After run, Isar contains >0 questions and ECG cases.

## Phase X: Verification
- [ ] Checklist: No purple hex, used standard themes.
- [ ] Scripts: `flutter analyze` passes across all packages.
- [ ] Build: `melos bootstrap` succeeds.
- [ ] Run & Test: All features navigable from Shell without crashes.
- Date: [Pending]
