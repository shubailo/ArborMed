# Plan: Authentication Restoration

## Overview
The authentication system is currently broken due to a failed Google Sign-In implementation that has also impacted the legacy username/password flow. This plan details the steps to completely remove the Google Sign-In integration and restore the stability and functionality of the original authentication method.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
1.  **Google Sign-In Removed**: No traces of `google_sign_in` package or code in the app.
2.  **Clean Build**: App compiles without errors or warnings related to missing auth packages.
3.  **Functional Login**: Users can successfully log in using username/email and password.
4.  **Error Handling**: Appropriate error messages are displayed for invalid credentials (instead of crashing or silence).

## Tech Stack
*   **Flutter**: Mobile framework
*   **Provider**: State management (`AuthProvider`)
*   **SharedPreferences**: Local storage for tokens
*   **http**: API communication

## File Structure
```
mobile/
├── lib/
│   ├── providers/
│   │   └── auth_provider.dart  <-- CRITICAL: Core logic to fix
│   ├── screens/
│   │   └── auth/
│   │       └── login_screen.dart <-- CRITICAL: UI to clean up
│   └── services/
│       └── api_service.dart    <-- VERIFY: Ensure token handling is correct
├── pubspec.yaml                <-- CRITICAL: Remove dependency
```

## Task Breakdown

### Phase 1: Cleanup (Remove Google Sign-In)

- [ ] **Task 1: Remove Dependency**
    - **Agent**: `mobile-developer`
    - **Action**: Remove `google_sign_in` from `mobile/pubspec.yaml`.
    - **Verify**: Run `flutter pub get` to ensure no resolution errors.

- [ ] **Task 2: Clean `AuthProvider`**
    - **Agent**: `mobile-developer`
    - **Action**: Remove `GoogleSignIn` imports, initialization, `signInWithGoogle`, and `completeSocialProfile` methods from `mobile/lib/providers/auth_provider.dart`.
    - **Verify**: No compilation errors in `auth_provider.dart`.

- [ ] **Task 3: Clean `LoginScreen`**
    - **Agent**: `mobile-developer`
    - **Action**: Remove the Google Sign-In button and any related UI logic from `mobile/lib/screens/auth/login_screen.dart`.
    - **Verify**: UI builds without the button.

### Phase 2: Restoration (Fix Legacy Auth)

- [ ] **Task 4: Debug & Fix `login()` Logic**
    - **Agent**: `mobile-developer`
    - **Action**: 
        - Review `AuthProvider.login()` for logical errors.
        - Add robust logging (before request, on success, on error).
        - Ensure `_apiService` is correctly initialized and token setters are called.
        - Verify `_saveAuthData` is working.
    - **Verify**: Logs show successful token storage upon login.

- [ ] **Task 5: Verify `ApiService` Integration**
    - **Agent**: `mobile-developer`
    - **Action**: Ensure `ApiService` correctly attaches tokens to subsequent requests.
    - **Verify**: API calls after login include the `Authorization` header.

## Phase X: Verification

### manual_verification
- [x] **Build Check**: Run `flutter run` on an emulator/device.
- [x] **Login Test**: Enter valid credentials -> Verify redirection to Home.
- [x] **Login Error Test**: Enter invalid credentials -> Verify error snackbar/alert.
- [x] **Persistance Test**: Restart app -> Verify user remains logged in.

### automated_verification
- [x] **Lint Check**: `flutter analyze` passes clean.
- [x] **Test Runner**: Run existing unit tests (if any) for auth.

## ✅ PHASE X COMPLETE
- Build: ✅ Success
- Login: ✅ Verified by User
- Date: 2026-02-07
