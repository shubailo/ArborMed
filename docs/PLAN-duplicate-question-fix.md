# Plan: Duplicate Question Fix & Bloom Buffer

**Goal**: Eliminate duplicate questions during a quiz session and enhance the engine to provide a smoother, more distinct transition between Bloom Levels.

**Project Type**: MOBILE (Flutter)
**Primary Agent**: `mobile-developer`

## Success Criteria
- [ ] **No Repeats**: A question ID seen in the current session is NEVER shown again until the session/topic is restarted.
- [ ] **History-Aware Exclusion**: Every pre-fetch request sent by the client includes the full history of the current session in the `exclude` parameter.
- [ ] **Bloom Buffer Distinction**: When pre-fetching for the *next* level (e.g., Level 2 while at Level 1), the engine strictly avoids pulling content from the current level.
- [ ] **Pre-fetch Resilience**: Fallback direct-API calls (cache misses) also use the session history to exclude repeats.

## Tech Stack
- **Framework**: Flutter
- **State Management**: Provider (`QuestionCacheService`)
- **API**: Internal REST API (`/quiz/next`)

## File Structure (Affected Files)
- `mobile/lib/services/question_cache_service.dart` (Core Logic)
- `mobile/lib/screens/game/quiz_session_screen.dart` (Fallback handling)

---

## Task Breakdown

### Phase 1: Client-Side "Deep Memory" Fix
| ID | Task Name | Agent | Skills | Priority | Docs/Deps |
|----|-----------|-------|--------|----------|-----------|
| T1 | **Session History Implementation** | mobile-developer | clean-code | P0 | `QuestionCacheService.dart` |
| | **INPUT**: Popped questions from the queue. |
| | **OUTPUT**: A `Set<int> _sessionHistory` that stores every ID shown. |
| | **VERIFY**: Check that `next()` adds the ID to the set and `init()` clears it. |

| ID | Task Name | Agent | Skills | Priority | Docs/Deps |
|----|-----------|-------|--------|----------|-----------|
| T2 | **Global Exclusion Sync** | mobile-developer | api-patterns | P0 | - |
| | **INPUT**: Pre-fetch and Fallback API calls. |
| | **OUTPUT**: All outgoing `/quiz/next` requests join `_sessionHistory` with `_currentLevelQueue` and `_nextLevelQueue` IDs in the `exclude` parameter. |
| | **VERIFY**: API logs show growing `exclude` strings as the session progresses. |

### Phase 2: Bloom-Buffer Enhancement
| ID | Task Name | Agent | Skills | Priority | Docs/Deps |
|----|-----------|-------|--------|----------|-----------|
| T3 | **Cross-Level Insulation** | mobile-developer | adaptive-logic | P1 | - |
| | **INPUT**: Predictive fetch for `BloomLevel + 1`. |
| | **OUTPUT**: Logic that ensures predictive fetches never accidentally pull questions already in the current-level queue. |
| | **VERIFY**: Level 2 pre-fetch batch contains zero Level 1 question IDs. |

---

## Phase X: Verification
- [ ] **Stress Test**: Answer 30+ questions in one session; verify zero duplicates.
- [ ] **Pre-fetch Check**: Verify `exclude` parameter reflects both seen and waiting IDs.
- [ ] **Transition Check**: Verify Level-Up happens seamlessly without repeat "Intro" questions.
- [ ] **Lints**: `flutter analyze`
- [ ] **Final Check**: `python .agent/scripts/verify_all.py .`

## ✅ PHASE X COMPLETE
- Date: [NOT COMPLETE]
