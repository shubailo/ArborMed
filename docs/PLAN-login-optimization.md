# PLAN: Hybrid Login Optimization (A+B)

This plan implements a high-performance, seamless login flow combining server-side CPU optimizations (Option A) with client-side perceptual speed (Option B).

## Phase 1: Engine Upgrades (Option A)

### 🚀 Backend Speed
- **[MODIFY] [authController.js](file:///C:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/authController.js)**:
  - Replace `bcrypt` with `crypto.SHA256` for **Refresh Tokens**.
  - Add timing logs to track handshake latency.

### 🛡️ Connectivity & Flexibility
- **[MODIFY] [api_service.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/services/api_service.dart)**:
  - Use `String.fromEnvironment('API_URL')` for dynamic server targeting.
  - Implement a 15-second `timeout` to handle slow cellular/Wi-Fi transitions.

## Phase 2: Perceptual Speed (Option B)

### 🏎️ Instant Entry
- **[MODIFY] [login_screen.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/auth/login_screen.dart)**:
  - Trigger navigation to `DashboardScreen` the moment the `User` object is received, without waiting for inventory/stats.

### 🌊 Background Loading
- **[MODIFY] [room_screen.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/room_screen.dart)**:
  - Initialize fetches for inventory, summary, and stats in the background.
  - Use "Skeleton" states or subtle fades for interactive furniture items that load after room entry.

## Phase 3: Developer DX
- **Action**: Provide a documentation block on how to run/build with the new dynamic IP.

## Phase 4: Cloud Deployment (Render)

- **[NEW] [render.yaml](file:///C:/Users/shuba/Desktop/Med_buddy/render.yaml)**: Configuration for one-click deployment to Render.
- **Action**: Help user set up Environment Variables on Render dashboard.
- **Action**: Provide the final `API_URL` for the production build.

## Verification Checklist

### 🧪 Automated Checks
- [ ] `flutter analyze` passes.
- [ ] Backend benchmark: `POST /auth/login` processing time < 200ms (excluding network).

### 📱 Manual Verification
- [ ] Tapping "Login" shows the Room within ~500ms on a fast network.
- [ ] Offline/Timeout: App clearly notifies user after 15s instead of hanging.
