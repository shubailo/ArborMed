# Hybrid Synchronization + Offline Quiz Implementation

## Goal
Implement a robust "Hybrid" synchronization strategy to resolve offline data loss issues, AND enable a seamless offline quiz experience.

### Core Sync (Shop/Room)
- **Transactions (Buying)**: Use a strict FIFO Queue to ensure currency integrity.
- **State (Equipping)**: Use a "Last Write Wins" State Snapshot to ensure the room always looks correct.
- **Trigger**: Sync on **App Start** AND **Network Restoration**.

### Quiz System
- **Download Strategy**: Explicitly allow users to download topics for offline play.
- **Offline First**: Quiz session *always* prioritizes local DB, removing fragile API fallbacks during gameplay.

## Project Type
- **Mobile** (Flutter)
- **Backend** (Node.js)

## Success Criteria
1.  **Offline Buy**: User buys item offline → Deducts gold locally → Syncs transaction when online.
2.  **Offline Equip**: User equips Item A, then Item B offline → Online state reflects Item B.
3.  **Quiz Download**: User can click "Download" on a topic, see progress, and play offline.
4.  **No Lag**: Quiz session loads instantly from local DB without waiting for network.
5.  **App Start Sync**: Sync triggers immediately when opening the app (if online).

## Tech Stack
- **Flutter**: `provider`, `drift`, `connectivity_plus`, `dio`.
- **Backend**: Node.js, PostgreSQL.

## File Structure & Changes
- `mobile/lib/services/sync_service.dart`: Hybrid logic + `downloadTopic` method.
- `mobile/lib/providers/room_provider.dart`: Update for room syncing.
- `mobile/lib/screens/quiz/topic_detail_screen.dart`: Add Download Button UI.
- `mobile/lib/screens/game/quiz_session_screen.dart`: Remove API fallback, strictly usage `LocalAdaptiveEngine`.

## Task Breakdown

### Phase 1: Backend Preparation
- [ ] **Task 1: Verify/Add Room Sync Endpoint**
    - **Action**: Check `backend` for a bulk update endpoint (e.g., set full room items). If missing, create `POST /room/sync`.
    - **Verify**: `curl -X POST /room/sync -d '{ "items": [...] }'` updates DB accurately.
    - **Agent**: `backend-specialist`

### Phase 2: Mobile Refactor (SyncService)
- [ ] **Task 2: Split Sync Logic**
    - **Action**: Modify `SyncService` to handle `QUEUE_STRICT` (Buy) and `STATE_LATEST` (Equip).
    - **Verify**: Code review shows distinct handling paths.
    - **Agent**: `mobile-developer`

- [ ] **Task 3: Implement App Start Trigger**
    - **Action**: Add `SyncService.init()` call in `main.dart`. Ensure it runs `processQueue` immediately if online.
    - **Verify**: Logs show "Triggering sync..." on app launch.
    - **Agent**: `mobile-developer`

### Phase 3: Mobile Implementation (Providers)
- [ ] **Task 4: Update Shop/Room Providers**
    - **Action**: Update `Shop` and `Room` providers to use the new `SyncService` methods.
    - **Verify**: Equipping 5 items offline results in ONLY 1 pending network request.
    - **Agent**: `mobile-developer`

### Phase 4: Quiz Offline Readiness
- [ ] **Task 5: Implement Download Topic UI**
    - **Action**: In `TopicDetailScreen`, add a "Download" button. Call `SyncService.syncQuestions(slug)`. Show progress/completion status.
    - **Verify**: Tapping download fetches questions and populates local DB (verified via Drift Inspector or logs).
    - **Agent**: `mobile-developer`

- [ ] **Task 6: Strict Offline Quiz Session**
    - **Action**: Update `QuizSessionScreen` to REMOVE the `_apiService.get()` fallback. It should rely 100% on `LocalAdaptiveEngine`. If DB empty, show "Download Required" error.
    - **Verify**: Turn off WiFi. Open quiz. It loads instantly if downloaded.
    - **Agent**: `mobile-developer`

## Phase X: Verification
- [ ] **Lint Check**: `flutter analyze`
- [ ] **Test Case 1 (Buy)**: Offline Buy -> Online Syncs Transaction.
- [ ] **Test Case 2 (Equip)**: Offline Equip x5 -> Online Syncs Latest State.
- [ ] **Test Case 3 (Quiz)**: Download "Cardiology". Go Airplane Mode. Play 10 questions.
