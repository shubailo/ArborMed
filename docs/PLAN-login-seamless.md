# PLAN - Seamless Login Experience

A cross-platform (Mobile & Web) enhancement to eliminate the "Login Screen Flash" and provide a premium startup experience using native branding and silent authentication.

## Project Type: **MOBILE + WEB** (Flutter)
Primary Agent: `mobile-developer`

## Success Criteria
- [ ] **Zero Flash**: Users with valid sessions never see the Login screen on app launch.
- [ ] **Branded Entry**: A professional splash screen shows the app logo and a subtle "Initializing..." indicator.
- [ ] **Silent Recovery**: Expired sessions are silently refreshed using the refresh token during the splash sequence.
- [ ] **Web Optimized**: Web routes handle the initialization state without broken URL states.

## Tech Stack
- **Framework**: Flutter (Mobile + Web)
- **State Management**: Provider (ChangeNotifier)
- **Persistence**: SharedPreferences (Mobile/Web)
- **Icons**: App Icon (`assets/logo/app_icon.png`)

## File Structure Changes
- [NEW] `mobile/lib/screens/auth/initial_splash_screen.dart`
- [MODIFY] `mobile/lib/services/auth_provider.dart`
- [MODIFY] `mobile/lib/main.dart`

## Task Breakdown

### Phase 1: Foundation & Auth Logic
1. **[task_1] Fix Initialization State**
   - **Agent**: `mobile-developer`
   - **Action**: Modify `AuthProvider` constructor to keep `_isInitialized = false` until `tryAutoLogin` completes.
   - **Input**: `auth_provider.dart`
   - **Verify**: Console logs show `isInitialized` changing only after storage check.

2. **[task_2] Silent Refresh Guard**
   - **Agent**: `mobile-developer`
   - **Action**: Update `tryAutoLogin` to check if the current token is valid. If expired but `refresh_token` exists, call `refreshUser()` or a token refresh endpoint *before* ending the splash.
   - **Input**: `auth_provider.dart`, `api_service.dart`
   - **Verify**: App stays on splash while refreshing, then goes straight to Dashboard.

### Phase 2: UI & Branding
3. **[task_3] Create InitialSplashScreen**
   - **Agent**: `mobile-developer`
   - **Action**: Design a clean, centered screen with the app logo (`assets/logo/app_icon.png`) and a premium loading indicator.
   - **Input**: `initial_splash_screen.dart`, `assets/logo/app_icon.png`
   - **Verify**: Hot restart shows the splash screen.

4. **[task_4] Orchestrate main.dart**
   - **Agent**: `mobile-developer`
   - **Action**: Update the root `Consumer<AuthProvider>` in `main.dart` to return `InitialSplashScreen` when `!auth.isInitialized`.
   - **Input**: `main.dart`
   - **Verify**: No more flash of Login screen on start.

### Phase 3: Platform Hardening
5. **[task_5] Web Route Consistency**
   - **Agent**: `frontend-specialist` (consulting) / `mobile-developer`
   - **Action**: Ensure Web URL doesn't stick on `/` if internal routing redirects to `/admin` or `/dashboard`.
   - **Verify**: Direct URL access to nested routes still triggers the splash check.

## Phase X: Verification Checklist
- [ ] Build APK and test on emulator: ✅
- [ ] Build Web and test on Netlify: ✅
- [ ] Test Logout -> Login flow: ✅
- [ ] Test Expired Session case (manual storage clear): ✅
