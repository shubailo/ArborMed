# Plan: Analytics Sync & Data Repository

The user reports that analytics are not updating after quiz sessions. Currently, the system calculates stats on-the-fly by counting raw `responses` rows. This is fragile and performance-heavy.

We will transition to a **"Materialized Stats"** architecture (the "Depository" approach suggested by the user), where `user_topic_progress` becomes the single source of truth for all analytics.

## Phase 1: Data Repository Upgrade
We need to enhance the `user_topic_progress` table to store comprehensive stats, not just Bloom levels.

- **Schema Update**:
  - Add `total_answered` (INT) - *Ensure it feeds correctly*
  - Add `correct_answered` (INT)
  - Add `mastery_score` (INT) - *Running calculation of proficiency*
  - Add `sessions_completed` (INT)

## Phase 2: The "Write" Pipeline (AdaptiveEngine)
Update the `processAnswerResult` logic to strictly maintain these counters.

- **Transaction Integrity**:
  - When a user answers a question:
    - Increment `total_answered`
    - If correct, increment `correct_answered`
    - Update `mastery_score` using the weighted formula (Bloom Value / Total Value)
    - Update `last_studied_at`
- **Migration Script**:
  - Create a script to backfill `user_topic_progress` from existing `responses` rows (Self-Healing).

## Phase 3: The "Read" Pipeline (Stats API)
Rewrite `statsController.js` to read directly from `user_topic_progress`.

- **Efficiency**:
  - `getSummary`: Sum up `user_topic_progress` rows for child topics to get Parent stats.
  - `getSubjectDetail`: Read `user_topic_progress` directly for the heatmap.
- **Benefit**: Zero-latency analytics. The moment the quiz finishes, the row is updated, and the dashboard reflects it instantly.

## Phase 4: Frontend Synchronization
Ensure the mobile app refreshes this data correctly.

- **Quiz Exit Trigger**:
  - When `QuizSession` ends, trigger `Provider.of<StatsProvider>().fetchSummary()` and `fetchSubjectDetail()`.
  - Ensure `QuizMenu` also refreshes its sort order.

## Verification
- Run a quiz session.
- Verify `user_topic_progress` values in DB.
- Verify Analytics Dashboard updates immediately without 0% lag.
