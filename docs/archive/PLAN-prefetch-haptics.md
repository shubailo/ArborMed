# PLAN: Snappy UX (Pre-fetching & Haptics)

This plan outlines the implementation of a "Recursive Pre-fetching" system for questions and Haptic Feedback for user errors.

## � Architectural Decisions
1. **Storage**: **`QuestionCacheService` (Dedicated)**. A singleton service responsible for managing the question queue, fetching data, and handling errors.
2. **Logic Placement**: **Smart Queue (Internal)**. The `QuizSessionScreen` will notify the service of progress; the service will internally calculate the delta and trigger fetches. This keeps the UI clean.
3. **Network Resilience**: **Strict (Retry with Backoff)**. If a fetch fails, we retry aggressively to ensure the user never hits an empty queue during a session.

---

## 🛠 Proposed Changes

### 1. Haptic Foundation (Tier 1) - `DONE`
- [x] Add `HapticFeedback.vibrate()` on incorrect answers in `QuizSessionScreen`.

### 2. Initial Pre-fetching (Tier 2)
- **File**: `lib/services/stats_provider.dart`
- **Action**: Add `preFetchData()` method to fetch summary and activity (today/week).
- **File**: `lib/services/auth_provider.dart`
- **Action**: Trigger `statsProvider.preFetchData()` after successful login or refreshUser.

### 3. QuestionCacheService (Tier 3)
- **New File**: `lib/services/question_cache_service.dart`
- **Action**:
    - `Queue<Map<String, dynamic>> _cache`
    - `Future<void> init(int topicId)` (Fetches initial 10).
    - `Future<Map<String, dynamic>> next()` (Pops from queue).
    - `void notifyAnswered()` (Handles our internal counter and the 5/5 trigger).
    - `_fetchMore(int count)` with infinite retry logic until success.

### 4. QuizSessionScreen Integration
- Replace direct `_apiService.get('/quiz/next')` with `_cacheService.next()`.
- Call `_cacheService.notifyAnswered()` on successful submission.

---

## ✅ Verification Plan

### Automated
- `flutter analyze` to ensure no syntax errors with `HapticFeedback` or new service.
- Mock API tests for background pre-fetching triggers.

### Manual
- Verify vibration on a physical Android/iOS device.
- Monitor network tab in DevTools to confirm background fetches trigger every 5 answers.
