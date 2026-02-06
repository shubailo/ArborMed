# PLAN-seamless-sync: Seamless Background Synchronization

> **Status:** APPROVED
> **Goal:** Replace manual download button with an invisible, smart background sync that ensures offline readiness without user improved.
> **UX Priority:** "Invisible but Trustworthy"

## 1. Core Strategies
- **Smart Sync**: Prioritize content based on user's current context (Recent subjects -> Active topic -> Everything else).
- **Subtle Indication**: Use a "hollow vs. solid" or "subtle glow" visual metaphor to indicate offline readiness. No big "Download" buttons.
- **Conflict Resolution**: **Server Wins**. If local progress conflicts with server history during sync, server state is authoritative to prevent integrity issues.

## 2. Architecture

### A. Sync Service (`SyncService.dart`)
- [ ] **Smart Queue**:
    - `syncPriorityContent()`: Fetches context-aware data (e.g., questions for the last 3 accessed topics).
    - `syncFullContent()`: Low-priority background task (using `WorkManager` or simple timer when idle) to trickle-download the rest.
- [ ] **Conflict Logic**: Update `_performAction` to respect Server authoritative timestamps.

### B. UI / UX (`QuizMenuWidget.dart`)
- [ ] **Remove Button**: Delete `TopicDownloadButton`.
- [ ] **Visual Indicator**:
    - Add a subtle status icon (e.g., `cloud_done_rounded` vs `cloud_queue_rounded` or a green dot) next to the topic name.
    - Animation: Pulse softly when syncing in background.

### C. State Management
- [ ] **`offline_topics` Preference**: SyncService maintains a list of fully downloaded topic slugs.
- [ ] **Reactive Updates**: UI listens to `SyncService.downloadProgress` (or similar stream) to update indicators in real-time.

## 3. Implementation Tasks

### Phase 1: Service Layer (Smart Sync)
- [ ] **Refactor `SyncService`**:
    - Remove `downloadTopicQuestions` manual trigger.
    - Implement `syncSmartContent()`:
        1. Fetch user's "Recent Topics" list from StatsProvider/Backend.
        2. Auto-fetch questions for those topics first.
    - Implement `syncBackgroundLoop()`:
        1. Periodically check for missing topics.
        2. Download in chunks (limit 50 questions/request) to avoid blocking main thread.

### Phase 2: UI Refinement (Best UX)
- [ ] **Modify `QuizMenuWidget`**:
    - Replace Download Button with `OfflineBadge` widget.
    - `OfflineBadge` listens to Sync status.
    - **Design**:
        - *Online + Synced*: Solid Check (Green/Accent).
        - *Online + Syncing*: Rotating Loader (Tiny, grey).
        - *Offline + Synced*: Solid Check.
        - *Offline + Not Synced*: Greyed out / "Connect to play" tooltip.

### Phase 3: Conflict Resolution
- [ ] **Update Sync Logic**:
    - When pushing `QUIZ_RESULT`, check server response.
    - If server says "Stale State", force-update local state from server response.

## 4. Verification
- **Test Case 1 (Smart Start)**: Open app. Watch network logs. Should see "Recent Topics" fetching immediately.
- **Test Case 2 (Idle Sync)**: Leave app open. Verify low-priority topics eventually appear in DB.
- **Test Case 3 (Offline UX)**: Airplane mode. Verify "Offline Ready" topics are playable, others are disabled/indicated clearly.
