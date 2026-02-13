# PLAN: Response Time Tracking

Implement accurate response time tracking in the medical quiz app to replace hardcoded placeholders.

## Overview
Currently, the app sends a hardcoded `1000ms` or `5000ms` for every question, skewing statistics. This plan introduces a lifecycle-aware timer to track actual focused time spent on questions.

## Project Type
**MOBILE** (Flutter) + **BACKEND** (Node.js/Express)

## Success Criteria
- [ ] Average time in stats reflects actual user behavior.
- [ ] Timer pauses when the app is minimized (lifecycle aware).
- [ ] Timer restarts if the app is killed mid-question.
- [ ] Backend rejects or caps impossible response times (e.g., < 100ms or > 1 hour).

## User Review Required

> [!IMPORTANT]
> **Lifecycle Choice**: We are proceeding with **PAUSE** on minimize.
> **Persistence**: No mid-question persistence. If the app kills, the timer resets for that question.

## Proposed Changes

### Mobile (Flutter)

#### [MODIFY] [quiz_controller.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/providers/quiz_controller.dart)
- Add `Stopwatch _stopwatch`.
- Update `_setQuestion` to reset and start the stopwatch.
- Update `submitAnswer` to stop the stopwatch and send `_stopwatch.elapsedMilliseconds`.
- Add `pauseTimer()` and `resumeTimer()` methods.

#### [MODIFY] [quiz_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/quiz/quiz_screen.dart)
- Implement `WidgetsBindingObserver`.
- Hook into `didChangeAppLifecycleState`.
- Call `controller.pauseTimer()` when hidden/inactive and `controller.resumeTimer()` when resumed.

### Backend (Node.js)

#### [MODIFY] [quizController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/quizController.js)
- Update `submitAnswer` to validate `responseTimeMs`.
- Threshold: Min `100ms`, Max `3,600,000ms` (1 hour).
- If outside bounds, cap at the limit or handle as "bad data".

## Task Breakdown

### Phase 1: Foundation (Mobile)
- [ ] **Task 1: Stopwatch Implementation**
  - **Agent**: `mobile-developer`
  - **Skills**: `clean-code`, `react-patterns` (Flutter equivalent)
  - **Action**: Add `Stopwatch` to `QuizController` and integrate into start/stop flows.
  - **INPUT** → Current `QuizController`
  - **OUTPUT** → Controller sending real elapsed time.
  - **VERIFY** → Print debug logs showing elapsed time on submission.

- [ ] **Task 2: Lifecycle Awareness**
  - **Agent**: `mobile-developer`
  - **Skills**: `mobile-design`
  - **Action**: Add `WidgetsBindingObserver` to `QuizScreen` to pause/resume controller timer.
  - **INPUT** → `QuizScreen`
  - **OUTPUT** → Lifecycle-aware UI.
  - **VERIFY** → Minimize app for 10s, return, verify 10s was NOT added to total.

### Phase 2: Security & Integrity (Backend)
- [ ] **Task 3: Backend Sanity Checks**
  - **Agent**: `backend-specialist`
  - **Skills**: `api-patterns`
  - **Action**: Add range validation to `/quiz/answer` endpoint.
  - **INPUT** → `quizController.js`
  - **OUTPUT** → Validated endpoint.
  - **VERIFY** → Mock request with `1ms` and verify it gets capped or rejected.

## Phase X: Verification
- [ ] `python .agent/scripts/verify_all.py .`
- [ ] Manual check: Start question, wait 5s, minimize for 5s, resume, wait 5s, submit. Result should be ~10s.
- [ ] Manual check: Kill app mid-question, restart, verify timer starts from 0 for the same question.
