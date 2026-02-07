# Plan: User Data Isolation & Cleanup

## Overview
This plan addresses the "fully equipped room" bug where new accounts inadvertently inherit the room state and inventory of the previous user. We will implement strict user isolation in the local Drift database and a secure cleanup process during logout.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
- [ ] Logging out clears all user-specific tables (`UserItems`, `TopicProgress`, `QuestionProgress`, `SyncActions`).
- [ ] Catalog data (`Items`, `Questions`) persists for performance.
- [ ] User receives a warning if logging out with unsynced data while offline.
- [ ] Switching accounts on the same device results in a fresh, empty room for the new user.

## Tech Stack
- **Flutter** (Frontend)
- **Drift** (Local Database)
- **Provider** (State Management)
- **SharedPreferences** (Auth Tokens)

## File Structure Changes
No new files, modifications to:
- `mobile/lib/database/database.dart`: Added cleanup logic.
- `mobile/lib/services/auth_provider.dart`: Logout flow orchestration + Offline warning.
- `mobile/lib/services/shop_provider.dart`: User-filtered queries.
- `mobile/lib/services/sync_service.dart`: User-specific sync scoping.

## Task Breakdown

### Phase 1: Foundation (Database Cleanup)
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T1 | Implement DB Cleanup Method | `mobile-developer` | `clean-code` | P0 | None |
| **Input** | `database.dart` |
| **Output** | `clearUserData()` method in `AppDatabase` class. |
| **Verify** | Method exists and targets only user-specific tables. |

### Phase 2: Orchestration (Auth Flow)
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T2 | Update Logout Logic | `mobile-developer` | `clean-code` | P1 | T1 |
| **Input** | `auth_provider.dart` |
| **Output** | Logout calls `db.clearUserData()` and checks connectivity for warning. |
| **Verify** | Logout triggers a prompt if offline. |

### Phase 3: Isolation (Provider Scoping)
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T3 | User-Scoped Inventory | `mobile-developer` | `clean-code` | P1 | None |
| **Input** | `shop_provider.dart` |
| **Output** | All `UserItems` queries filtered by `userId`. |
| **Verify** | Multi-account login test shows isolated rooms. |

## Phase X: Verification
- [ ] Manual Check: Log in with Account A -> Equip items -> Log out.
- [ ] Manual Check: Log in with Account B (New) -> Verify room is EMPTY.
- [ ] Offline Test: Disable internet -> Trigger logout -> Verify warning dialog appears.
