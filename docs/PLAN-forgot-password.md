# PLAN-forgot-password

## Overview
Implement a modern "Forgot Password" feature using a 6-digit OTP (One Time Password) sent via email. Users will request a code, enter it in the app, and then be allowed to set a new password.

**Project Type**: MOBILE + BACKEND (Full Stack)

## Success Criteria
- [ ] User can initiate reset by entering email in a modal.
- [ ] User receives a 6-digit OTP (logged to console in dev).
- [ ] User can verify OTP and update password in a single flow.
- [ ] Incorrect or expired OTPs are rejected.

## Tech Stack
- **Backend**: Node.js, Express, PostgreSQL, Nodemailer.
- **Mobile**: Flutter, Provider, SharedPreferences.

## File Structure Changes
### Backend
- [NEW] `src/services/mailService.js`: Email sending logic.
- [NEW] `src/models/010_otp_table.sql`: Database schema for OTP storage.
- [MODIFY] `src/controllers/authController.js`: Added OTP and Reset logic.
- [MODIFY] `src/routes/authRoutes.js`: Exposed new endpoints.

### Mobile
- [MODIFY] `lib/services/auth_provider.dart`: API bridge for OTP flows.
- [MODIFY] `lib/screens/auth/login_screen.dart`: UI for the forgot password modal.
- [NEW] `lib/widgets/auth/forgot_password_modal.dart`: Reusable modal component.

---

## Task Breakdown

### Phase 1: Backend Foundation (P0)
- **Task 1.1**: Create OTP Table
  - **Agent**: `backend-specialist`
  - **Skill**: `database-design`
  - **Input**: User IDs
  - **Output**: Table `password_resets` (id, user_id, otp_hash, expires_at)
  - **Verify**: `SELECT` from table in database.
- **Task 1.2**: Implement Mail Service
  - **Agent**: `backend-specialist`
  - **Skill**: `nodejs-best-practices`
  - **Input**: Recipient, Subject, Body
  - **Output**: `mailService.js` with console logging fallback.
  - **Verify**: Call mock send and check server logs.

### Phase 2: Auth Logic (P1)
- **Task 2.1**: OTP Request Controller
  - **Agent**: `backend-specialist`
  - **Skill**: `api-patterns`
  - **Input**: Email
  - **Output**: Endpoint `POST /auth/request-otp`
  - **Verify**: Hit with Postman, check if OTP is saved in DB and printed in console.
- **Task 2.2**: Password Reset Controller
  - **Agent**: `backend-specialist`
  - **Skill**: `security-auditor`
  - **Input**: Email, OTP, New Password
  - **Output**: Endpoint `POST /auth/reset-password`
  - **Verify**: Successful login with new password after reset.

### Phase 3: Mobile UI (P2)
- **Task 3.1**: AuthProvider Integration
  - **Agent**: `mobile-developer`
  - **Skill**: `react-patterns` (Flutter variant)
  - **Input**: Backend Endpoints
  - **Output**: `requestOTP` and `resetPassword` methods.
  - **Verify**: Methods return success/error from API.
- **Task 3.2**: Forgot Password Modal
  - **Agent**: `mobile-developer`
  - **Skill**: `frontend-design`
  - **Input**: LoginScreen
  - **Output**: Interactive modal with two steps (Email -> OTP/New Pass).
  - **Verify**: Visual check of modal and success snackbars.

---

## Phase X: Verification
- [ ] **Security**: Verify OTP expires after 10 minutes.
- [ ] **UX**: Modal handles loading states and error messages gracefully.
- [ ] **E2E**: Complete flow from "Forgot Password" to successful login.
- [ ] **Lints**: Run `flutter analyze` and `npm run lint`.
