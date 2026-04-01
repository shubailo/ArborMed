# PLAN: Fix App Loading & Initialization Strategy

This plan ensures the app transitions correctly from the initial splash screen to the appropriate destination (Home or Auth) based on the current session state.

## 🔴 User Review Required

> [!IMPORTANT]
> **Conditional Navigation**: The app will now check `AuthContract` for an active session. If found, it will bypass the role selection and go directly to the respective dashboard.
> 
> **Service Resilience**: I will implement "Fail-Safe" loading for non-critical assets (like the shop catalog) so the app can still boot even if a JSON fetch fails.

---

## Phase 1: Navigation Infrastructure

### [MODIFY] [app_router.dart](file:///c:/Users/shuba/Desktop/ArborMed/apps/student_app/lib/router/app_router.dart)
- Implement a `redirect` handler or an `initialLocation` logic that triggers a session check.
- Update the `/` route to be a dedicated `SplashScreen` widget instead of an inline `Scaffold`.

---

## Phase 2: Feature Initialization

### [MODIFY] [auth_service.dart](file:///c:/Users/shuba/Desktop/ArborMed/packages/feature_auth/lib/src/services/auth_service.dart)
- Ensure a robust `checkSession()` method exists that verifies local tokens or persistence.

### [MODIFY] [game_service.dart](file:///c:/Users/shuba/Desktop/ArborMed/packages/feature_game/lib/src/services/game_service.dart)
- Wrap `_loadCatalog()` in a `try-catch` that ensures `_isLoading` is set to `false` even on failure, preventing initialization loops.

---

## Phase 3: Splash Screen Implementation

### [NEW] `packages/core/lib/src/ui/splash_screen.dart`
- Create a reusable, beautiful splash screen that:
  - Triggers the dependency check.
  - Negotiates the transition to `/auth` or `/student/home`.
  - Handles the "No forced timeout" policy as requested.

---

## Verification Plan

### Manual Verification
1. **Fresh Install**: Confirm it lands on `/auth` (Role Selection).
2. **Persistence**: Log in, restart app. Confirm it lands on the **Home** screen.
3. **Resilience**: Manually break `shop_manifest.json` path. Confirm app still boots to Home.
4. **Logs**: Verify `✅ Initialized: auth state [authenticated|unauthenticated]` in console.

### Automated Tests
- None planned for this UI/Navigation phase, focusing on manual integration.
