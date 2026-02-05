# PLAN: Seamless Loading Transitions

Transform the `QuizLoadingScreen` into a "Smart Gate" that synchronizes clinical animations with background data fetching for an instant quiz entry.

## Proposed Changes

### [Frontend] Loading Layer
#### [MODIFY] [quiz_loading_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/quiz_loading_screen.dart)
- **UI Refinement**: Remove the linear progress bar from the bottom.
- **Smart Sync**:
  - Accept a `required Future<Map<String, dynamic>> dataFuture`.
  - The animation runs for at least **3.0 seconds**.
  - If `dataFuture` is still pending after 3 seconds, the "Preparing..." animation slows down slightly but keeps playing (looping behavior).
  - Once `dataFuture` completes, the screen performs the fast fade-out.
  - Returns the fetched data to the parent via `onComplete(data)`.

### [Frontend] Entry Orchestration
#### [MODIFY] [room_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/room_screen.dart)
- **Parallel Start**: Trigger `apiService.post('/quiz/start')`, `cacheService.init()`, and the first question fetch simultaneously as a single `Future`.
- **Injection**: Pass this `Future` into the `QuizLoadingScreen`.
- **Fast Path**: Once complete, pass the pre-fetched data directly into the `QuizSessionScreen`.

### [Frontend] Quiz Session
#### [MODIFY] [quiz_session_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/quiz_session_screen.dart)
- **Constructor Injection**: Add optional `Map<String, dynamic>? initialData` and `String? sessionId`.
- **Instant Boot**: If `initialData` is present, initialize `_currentQuestion` immediately and set `_isLoading = false`.

## Verification Plan

### Manual Verification
- **Visuals**: Verify the green bar is gone from the loading screen.
- **Speed**: Verify that the transition from Loading -> Quiz has **zero circular spinner lag**.
- **Edge Case**: Simulate a slow network and verify the loading animation continues smoothly until the data arrives.
- **Failure**: Verify that if the server fails, the error message correctly appears in the Quiz Screen after the transition.
