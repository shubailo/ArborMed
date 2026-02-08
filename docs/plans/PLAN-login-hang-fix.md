# PLAN: Login Hang & Performance Fix

This plan addresses two critical issues:
1.  **Connectivity/Hang**: The "infinite spinner" suggesting the phone cannot reach the server or the server is crashing.
2.  **Performance**: The underlying slowness described as "very slow" once it does connect.

## Phase 1: Diagnostics & Connectivity

### 🛡️ Connectivity & Dynamic URLs
- **Issue**: Hardcoded IP `10.65.175.41` is brittle and fails when switching networks.
- **Action**: Switch to using `String.fromEnvironment('API_URL')` in `ApiService`.
- **Action**: Provide the user with the `flutter build apk --dart-define=API_URL=...` command for easy switching.
- **Action**: Add a 15-second timeout to all requests to prevent "infinite" hangs.

### 📝 Enhanced Logging
- **Action**: Add `debugPrint` and `console.log` at every stage of the login handshake (Request Start -> Table Query -> Bcrypt Start -> Bcrypt End -> Token Gen -> Response).

## Phase 2: Performance Optimization (Backend)

### 🏎️ CPU Bottleneck Removal
- **[MODIFY] [authController.js](file:///C:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/authController.js)**:
  - Replace `bcrypt.hash` with `crypto.createHash('sha256')` for **Refresh Tokens**. (Since these are random entropy strings, SHA-256 is secure and ~100x faster than Bcrypt tokens).
  - Preserve `bcrypt` for user passwords.

## Phase 3: Mobile UX Optimization

### 🌊 Parallel Orchestration
- **[MODIFY] [room_screen.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/room_screen.dart)**:
  - Parallelize `fetchInventory`, `preFetchData`, and `fetchSummary` to prevent waterfall delays.

## Verification Checklist

### 🧪 Automated Checks
- [ ] `flutter analyze` passes.
- [ ] Backend starts without errors.
- [ ] `http` package timeout implemented and verified.

### 📱 Manual Verification
- [ ] "Login" button gives a timeout error instead of an infinite spinner if unreachable.
- [ ] Login completes in < 800ms on a successful connection.
