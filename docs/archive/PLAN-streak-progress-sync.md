# PLAN: Streak-Based Level Progress

Switch the progress bar to track the "20 Consecutive Correct" streak for Level Promotion, ensuring a more dynamic and less "stale" experience.

## Proposed Changes

### [Backend] Adaptive Engine
#### [MODIFY] [adaptiveEngine.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/services/adaptiveEngine.js)
- **New Metric**: Expose `current_streak` as `streakProgress` (streak / 20.0) in the question metadata.
- **Consistency**: Ensure `streak` and `streakProgress` are included in both `getNextQuestion` and `processAnswerResult`.

### [Frontend] Quiz Session
#### [MODIFY] [quiz_session_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/quiz_session_screen.dart)
- **Bar Metric**: Update `_levelProgress` to use the `streakProgress` from the server.
- **Monotonic Guard**:
  - Store `_knownStreak` in local state.
  - If a pre-fetched question has a lower streak than `_knownStreak`, do NOT jump the bar backward (only allow it to stay or move forward).
- **Celebration**:
  - Add a "Lvl Up!" toast/overlay when the `PROMOTION` event is received.
- **Reset Logic**: Reset streak/bar to 0 on `PROMOTION` or `DEMOTION`.

## Verification Plan

### Manual Verification
- **Correct Streak**: Answer questions correctly and verify the bar moves 1/20th (5%) each time.
- **Wrong Answer**: Verify the bar resets to 0% immediately upon a wrong answer (as streak resets).
- **Promotion**: Verify the celebration triggers at 20 correct, and the bar resets for the new level.
- **Cache Check**: Verify "Next" tapping doesn't cause the bar to flicker or jump to an old value.
