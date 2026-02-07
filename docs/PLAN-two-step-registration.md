# Two-Step Registration (Pending Stage) Plan

## 🎯 Goal
Refactor the user registration flow to prevent "zombie" or "fake" accounts in the main `users` table. The new flow will store registration data in a temporary `pending_registrations` table and only create a `User` record after successful email verification.

## 👤 Users
- New users signing up for the app.
- Existing users (verifying email for password reset - separate flow, but related logic).

## 📦 Scope
- **Backend:**
    - Create `pending_registrations` table.
    - Modify `/auth/register` to save to `pending_registrations` instead of `users`.
    - Create new/modify `/auth/verify-registration` endpoint to finalize account creation.
    - Handle `pending_registrations` cleanup (optional: manual or ttl).
- **Mobile App:**
    - Update `RegisterScreen` to handle successful registration without login (no token).
    - Update `VerificationScreen` to call the new verification endpoint which returns the Auth Token/User upon success.
    - Handle navigation: Register -> Verify -> Dashboard (Login).

## 🏗️ Architecture Changes

### Database
New Table: `pending_registrations`
- `email` (PK/Unique)
- `username`
- `password_hash`
- `display_name`
- `otp`
- `expires_at` (TIMESTAMP)

### API Endpoints
1.  **POST `/auth/register`**
    - Input: `email`, `password`, `username`
    - Logic:
        - Check `users`: If exists -> Error "Email/Username taken".
        - Check `pending_registrations`:
            - If exists: Update (overwrite/resend OTP).
            - If new: Insert.
        - Send Email OTP.
    - Response: `{ message: "OTP sent" }` (No Token).

2.  **POST `/auth/verify-registration`** (New/Modified)
    - Input: `email`, `otp`
    - Logic:
        - Check `pending_registrations` for match & expiry.
        - **Transaction:**
            - Insert into `users`.
            - Generate Tokens.
            - Delete from `pending_registrations`.
    - Response: `{ user, token, ... }` (Login success).

## ✅ Verification Plan

### Manual Verification
1.  **Register:**
    - Use a fresh email.
    - Check DB: `users` table should be empty for this email. `pending_registrations` should have it.
    - App: Navigate to Verification Screen.
2.  **Verify:**
    - Enter correct OTP.
    - Check DB: `users` table now has the record. `pending_registrations` is cleared.
    - App: Automatically logs in and navigates to Dashboard.
3.  **Invalid OTP:**
    - Verify error handling on the Verification Screen.
4.  **Resend:**
    - Verify resend functionality (updates `pending_registrations` OTP/Expiry).

### Migration Strategy
- Since this is a dev/staging environment currently, we can just create the new table. Existing `users` are unaffected. New registrations follow the new flow.

## 📝 Task Breakdown

### Phase 1: Database & Backend
- [ ] Create `pending_registrations` migration/table.
- [ ] Update `authController.register` logic.
- [ ] Implement `authController.verifyRegistration`.

### Phase 2: Mobile App
- [ ] Update `AuthProvider.register` to not expect a token immediately.
- [ ] Update `RegisterScreen` navigation logic.
- [ ] Update `VerificationScreen` to use `verifyRegistration` (handling token reception).

### Phase 3: Cleanup & Polish
- [ ] Ensure "Resend OTP" works for pending registrations.
- [ ] Verify error messages are user-friendly.
