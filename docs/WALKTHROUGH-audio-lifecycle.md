# Audio Lifecycle Fix Verification

## Changes Implemented
1.  **Stop Audio on Login**: Removed `_initMusic()` from `AudioProvider` constructor.
2.  **Auth-Based Playback**: Added `updateAuthState` to `AudioProvider` and wired it in `main.dart` via `ChangeNotifierProxyProvider`. Music now only starts when `isAuthenticated` is true.
3.  **Lifecycle Management**: Mixed in `WidgetsBindingObserver` to `AudioProvider`. Music pauses on `didChangeAppLifecycleState` (paused/detached/inactive) and resumes on `resumed`.

## Verification Steps
Please manually verify the following behaviors on your device/emulator:

### 1. Launch & Login
*   **Action**: Launch the app.
*   **Expected**: The Login Screen should be **SILENT**.
*   **Action**: Log in.
*   **Expected**: Background music should **START** (fade in) upon reaching the Dashboard.

### 2. Backgrounding
*   **Action**: Minimize the app (press Home).
*   **Expected**: Music should **STOP** immediately.
*   **Action**: Open another app (e.g., Chrome).
*   **Expected**: Music should remain **STOPPED**.
*   **Action**: Return to Arbor Med.
*   **Expected**: Music should **RESUME**.

### 3. Logout
*   **Action**: Tap Logout in the drawer/profile.
*   **Expected**: Music should **STOP** before or as the Login Screen appears.

### 4. Admin Panel (Regression Test)
*   **Action**: Navigate to Admin Panel.
*   **Expected**: Music should **PAUSE** (existing functionality preserved).
*   **Action**: Return to Dashboard.
*   **Expected**: Music should **RESUME**.
