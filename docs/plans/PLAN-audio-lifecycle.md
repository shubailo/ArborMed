# Audio Lifecycle & Auth Integration Plan

## 1. Goal Description
The current implementation of `AudioProvider` initializes background music immediately upon app launch, causing it to play on the Login Screen. Additionally, the audio continues playing when the app is minimized or closed, which is undesirable behavior.

This plan aims to:
1.  **Stop Audio on Login**: Ensure background music *only* starts after successful authentication.
2.  **Stop Audio on App Close**: Pause music when the app is minimized or backgrounded.
3.  **Resume Audio Correctly**: Resume music only if the user is authenticated and the app is in the foreground.

## 2. Architecture & Design
To achieve this "perfect" behavior, we need to make `AudioProvider` aware of two key states:
1.  **Authentication State**: Is the user logged in? (Provided by `AuthProvider`)
2.  **App Lifecycle State**: Is the app in the foreground? (Provided by `WidgetsBindingObserver`)

We will use `ChangeNotifierProxyProvider` in `main.dart` to inject `AuthProvider` updates into `AudioProvider`. This allows `AudioProvider` to react to login/logout events.

### Component Interaction
*   `AuthProvider` -> notifies -> `AudioProvider` (via ProxyProvider)
*   `WidgetsBindingObserver` -> notifies -> `AudioProvider` (via mixin)

## 3. Implementation Steps

### Phase 1: Modify `AudioProvider.dart`
*   [ ] **Remove Auto-Start**: Delete the `_initMusic()` call from the constructor.
*   [ ] **Add `WidgetsBindingObserver`**: Mixin to `AudioProvider`.
*   [ ] **Implement `didChangeAppLifecycleState`**:
    *   `paused`, `inactive`, `detached` -> Call `pauseMusic()`.
    *   `resumed` -> Call `resumeMusic()` (conditional check).
*   [ ] **Add `updateAuthState(bool isAuthenticated)`**:
    *   If `isAuthenticated` changes from `false` -> `true`: Start Music.
    *   If `isAuthenticated` changes from `true` -> `false`: Stop Music.
    *   Store `_isAuthenticated` locally to check against in `didChangeAppLifecycleState`.
*   [ ] **Cleanup**: Ensure `WidgetsBinding.instance.removeObserver(this)` is called in `dispose()`.

### Phase 2: Modify `main.dart`
*   [ ] **Update Provider Setup**:
    *   Change `ChangeNotifierProvider(create: (_) => AudioProvider())` to `ChangeNotifierProxyProvider<AuthProvider, AudioProvider>`.
    *   In `update`: Call `audio.updateAuthState(auth.isAuthenticated)`.

### Phase 3: Cleanup & Edge Cases
*   [ ] **Handle "Temporary Pause"**: Ensure the existing `_isTemporarilyPaused` logic (for Admin/Video) still works and isn't overridden by lifecycle changes.

## 4. Verification Plan

### Manual Testing Checklist
1.  **Fresh Install / Logout**:
    *   Launch App -> Login Screen.
    *   **Expectation**: Silence.
2.  **Login Flow**:
    *   Enter credentials -> Login.
    *   **Expectation**: Music fades in / starts immediately upon Dashboard load.
3.  **Backgrounding**:
    *   Press Home button (minimize app).
    *   **Expectation**: Music pauses immediately.
4.  **Resuming**:
    *   Re-open app.
    *   **Expectation**: Music resumes (if it was playing).
5.  **Screen Lock**:
    *   Lock screen.
    *   **Expectation**: Music pauses.
6.  **Logout**:
    *   Logout from Dashboard.
    *   **Expectation**: Music stops before returning to Login Screen.

## 5. Potential Pitfalls
*   **Race Conditions**: `AuthProvider` might be "authenticated" before `AudioProvider` is fully ready. `ProxyProvider`'s `update` handles this, but we need to ensure `_initMusic` logic is idempotent.
*   **Lifecycle Flakiness**: `inactive` vs `paused` can vary by platform. We will target `paused` for stopping and `resumed` for starting.
