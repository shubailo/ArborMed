# PLAN: Local-First Architecture Transition

This plan outlines the migration of MedBuddy to a local-first system using Isar Database. This will allow the app to work offline, with background synchronization to the cloud.

## Overview
- **Goal**: Move quiz and shop logic to the mobile app for offline resilience.
- **Primary Tech**: Isar Database (Local), Flutter (Logic), Supabase/Node (Sync).
- **Core Strategy**: Batch-fetch questions, local SRS/Adaptive logic, and "Sync Actions" queue for data consistency.

## Success Criteria
- [ ] Quiz works without internet (using cached questions).
- [ ] Room/Shop works without internet (using local inventory).
- [ ] "Last sync wins" conflict resolution works across devices.
- [ ] App size increase remains below 20MB.

## Tech Stack
- **Database**: `isar` (NoSQL, high performance).
- **Sync**: `WorkManager` (Android) or period background fetch for "Up-sync".
- **Logic**: Ported `AdaptiveEngine` from JS to Dart.

## Task Breakdown

### Phase 1: Foundation (Isar & Models)
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| F1 | Install Isar & Core deps | `mobile-developer` | `clean-code` | P0 | None |
| F2 | Define Local Models | `mobile-developer` | `clean-code` | P0 | F1 |
| F3 | Initialize Isar Service | `mobile-developer` | `clean-code` | P0 | F2 |

### Phase 2: Core (Logic Porting)
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| C1 | Port SRS/Leitner Logic | `mobile-developer` | `python-patterns` | P1 | F3 |
| C2 | Port Bloom Climber Logic | `mobile-developer` | `python-patterns` | P1 | C1 |
| C3 | Local Inventory Manager | `mobile-developer` | `clean-code` | P1 | F3 |

### Phase 3: Sync System (Hybrid Model)
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| S1 | Batch Download Service | `mobile-developer` | `api-patterns` | P1 | F3 |
| S2 | Sync Action Queue | `mobile-developer` | `clean-code` | P1 | S1 |
| S3 | Last-Sync-Wins Resolver | `mobile-developer` | `clean-code` | P1 | S2 |

### Phase 4: UI Integration
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| U1 | Switch ShopProvider to Isar | `mobile-developer` | `react-patterns` | P1 | C3 |
| U2 | Switch QuizSession to Local Engine | `mobile-developer` | `react-patterns` | P1 | C2 |
| U3 | Background Sync Toast/Status | `mobile-developer` | `frontend-design` | P2 | S2 |

## Phase X: Verification
- [ ] Run `flutter test` for local logic.
- [ ] Manual test: Offline purchase & equip.
- [ ] Manual test: Offline quiz session & post-online sync.
- [ ] Verify database state in Supabase after sync.

## ✅ PHASE X COMPLETE
- Status: [ ]
- Date: [ ]
