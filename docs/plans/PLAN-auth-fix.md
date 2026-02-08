# PLAN: Authentication and Email Verification Fix

## Overview
This plan addresses two critical failures in the ArborMed authentication system:
1. **Email OTP Delivery:** New users are not receiving verification codes because SMTP is not configured. We will configure Gmail SMTP.
2. **Google Auth Failure:** Users encounter an error after selecting an account. We will implement detailed logging and verify token compatibility.
3. **Verification Enforcement:** We will ensure email verification is required for all users.

## Project Type
**FULL STACK** (Node.js Backend + Flutter Mobile)

## Success Criteria
- [ ] Users receive a registration OTP via Gmail.
- [ ] Users cannot log in or use the app without verifying their email.
- [ ] Google Sign-In successfully creates/logs in users on the backend.
- [ ] Verification codes are no longer just logged to the console but delivered to inboxes.

## Tech Stack
- **Backend:** Node.js, Express, Nodemailer, `google-auth-library`
- **Frontend:** Flutter, `google_sign_in` package
- **Email:** Gmail SMTP with App Passwords

## File Structure
- `backend/.env` (Configuration)
- `backend/src/services/mailService.js` (Logic)
- `backend/src/controllers/authController.js` (Auth Flow)
- `mobile/lib/services/auth_provider.dart` (Frontend Enforcement)

## Task Breakdown

### Phase 1: Infrastructure & Mail Service
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T1 | Configure SMTP in `.env` | `backend-specialist` | `clean-code` | P0 | None |
| T2 | Refactor `mailService.js` for Gmail | `backend-specialist` | `nodejs-best-practices` | P0 | T1 |

**T2 INPUT→OUTPUT→VERIFY:**
- **Input:** Gmail credentials in `.env`.
- **Output:** `MailService` using `nodemailer` with Gmail transport.
- **Verify:** Run a test script to send a dummy email using the service.

### Phase 2: Google Auth Debugging
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T3 | Add Google Auth Logging | `backend-specialist` | `clean-code` | P1 | None |
| T4 | Fix Token Verification Logic | `backend-specialist` | `security-auditor` | P1 | T3 |

**T4 INPUT→OUTPUT→VERIFY:**
- **Input:** ID Token from frontend.
- **Output:** Validated user profile or clear error logs.
- **Verify:** Monitor backend console during Google Sign-In attempt.

### Phase 3: Frontend Enforcement
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T5 | Enforce Strict Verification Flow | `mobile-developer` | `react-patterns` | P0 | None |

**T5 INPUT→OUTPUT→VERIFY:**
- **Input:** `is_email_verified` flag from API.
- **Output:** Navigation block if `false`.
- **Verify:** Attempt to log in with an unverified account.

## Phase X: Verification Checklist
- [ ] SMTP connection successful (no 535 errors).
- [ ] Gmail "From" address matches `SMTP_USER`.
- [ ] Google Client ID matches exactly in `.env` and `auth_provider.dart`.
- [ ] Logout works correctly with token revocation.
- [ ] `python .agent/scripts/verify_all.py .` passes.

## ✅ PHASE X COMPLETE
- Lint: [ ]
- Security: [ ]
- Build: [ ]
- Date: 2026-02-06
