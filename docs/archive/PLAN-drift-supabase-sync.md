# PLAN: Drift Migration & Supabase Social Sync

This plan details the transition from Isar to **Drift (SQLite)** for robust multi-platform support (Web/Mobile/Windows) and the integration of **Supabase** social features (leaderboards, room visiting, notes).

## User Review Required

> [!IMPORTANT]
> **Database Reset**: Since the server is the source of truth, we will perform a clean re-sync of data from Supabase into the new Drift database.
> **Web Compatibility**: Drift will use WASM to run in the browser, resolving the integer literal issues.

## Proposed Changes

### Phase 1: Drift Foundation
- [ ] Add `drift`, `sqlite3_flutter_libs`, `path`, and `drift_dev` to `pubspec.yaml`.
- [ ] Create `lib/database/database.dart` defining the tables:
    - `Questions` (Sourced from Supabase)
    - `TopicProgress` (Local + Cloud)
    - `QuestionProgress` (Local + Cloud)
    - `Inventory` (Items & UserItems)
    - `SyncActions` (Action queue)
- [ ] Implement `DriftService` to replace `IsarService`.

### Phase 2: Sync Engine & Supabase Integration
- [ ] Refactor `SyncService` to use Drift.
- [ ] **Periodic Down-Sync**: Daily fetch of new questions/items from Supabase.
- [ ] **Periodic Up-Sync**: Daily push of aggregated analytics (mastery, streaks) to Supabase.
- [ ] **Auth Check**: Ensure Supabase session is refreshed before sync runs.

### Phase 3: Social & Multiplayer (v1)
- [ ] **Leaderboard API**: Integration with Supabase RPCs to fetch global rankings based on local mastery scores.
- [ ] **Room Visiting Skeleton**: 
    - Fetch other users' `UserItems` and `RoomState` from Supabase.
    - Implement a "Preview Mode" for `RoomScreen`.
- [ ] **Sticky Notes**: 
    - Database table for `Notes` (userId, targetUserId, text, timestamp).
    - UI overlay in the room for reading/writing notes.

### Phase 4: Refactoring Application Logic
- [ ] Update `LocalAdaptiveEngine` to use standard SQL via Drift.
- [ ] Update `ShopProvider` for Drift integration.
- [ ] Update `QuizSessionScreen` to pull data from the new local-first SQL store.

## Verification Plan

### Automated Tests
- [ ] Migration tests: Ensure Drift tables initialize correctly on all platforms.
- [ ] Query tests: Verify SRS selection logic returns expected cards.

### Manual Verification
1. **Web Build**: Run `flutter build web` and verify no integer errors.
2. **Social Sync**: Post a "Note" in another user's room and verify it appears in Supabase.
3. **Leaderboard**: Verify your local points update the global leaderboard after a sync.
