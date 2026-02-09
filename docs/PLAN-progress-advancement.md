# PLAN - Progress Advancement System

Fixed and enhanced progress tracking to ensure "perfect" advancement logic and a premium user experience.

## Goal
Resolve the "stuck at 1/20" bug and implement strict consecutive streak tracking for Bloom Level advancement, coupled with enhanced visual rewards.

## User Requirements
- **Server Authority**: The server is the source of truth; local DB (Drift) is secondary.
- **Zero Start**: All users start the new counter at 0.
- **Strict Consecutive**: Progress resets to 0 immediately upon a wrong answer.
- **Premium Feedback**: Add a "special" celebration for Level Up events.

---

## Phase 1: Database Migration (Backend)
### [NEW] `backend/migrations/20260209_add_level_correct_count.sql`
- Add column `level_correct_count` (INTEGER, DEFAULT 0) to `user_topic_progress`.
- No data backfill needed (start at 0 for everyone).

## Phase 2: Core Logic Update (Backend)
### [MODIFY] `backend/src/services/adaptiveEngine.js`
- **Method**: `processAnswerResult`
    - If `isCorrect` is true:
        - Increment `level_correct_count`.
        - If `level_correct_count >= 20`, trigger promotion and **reset `level_correct_count` to 0**.
    - If `isCorrect` is false:
        - **Reset `level_correct_count` to 0** (consecutive logic).
- **Method**: `getNextQuestion`
    - Ensure `streakProgress` always uses `level_correct_count / 20.0`.

## Phase 3: Premium UI Feedback (Mobile)
### [MODIFY] `mobile/lib/screens/game/quiz_session_screen.dart`
- Intercept the `PROMOTION` or `LEVEL_UNLOCKED` event from the server response.
- Trigger a custom `LevelUpOverlay` (new widget) that features:
    - Slower, more dense confetti.
    - A scale-up "LEVEL UP" text with a glow effect.
    - Sound effect enhancement (Haptic feedback + higher-pitched success chime).

## Phase 4: Verification & Testing
### Manual Tests
- [ ] Answer 20 questions correctly in a row; verify progress bar fills and resets on Level Up.
- [ ] Answer 5 correctly (bar at 25%), then 1 incorrectly; verify bar resets to 0%.
- [ ] Verify "Level Up" overlay displays correctly.
- [ ] Verify progress persists after app restart (server fetch).

---

## Agent Assignments
- **Backend Specialist**: Database migration & Adaptive Engine logic.
- **Frontend Specialist**: Level-up overlay & Quiz Session UI polish.
- **Antigravity**: Coordination and verification.
