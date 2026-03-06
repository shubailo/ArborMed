# PLAN: Hybrid Security Hardening (Passwords & Audit)

## Overview
This plan implements a hybrid security strategy focusing on proactive prevention (Strict Passwords) and reactive detection (Audit Logging).

- **Status**: 📝 PLANNING
- **Project Type**: FULL-STACK (Security)
- **Primary Agent**: `project-planner`

## Success Criteria
- [ ] Users cannot register with a password that doesn't meet complexity rules.
- [ ] Flutter UI shows a "Strength Meter" (based on Quiz progress bar style) that reacts to password input.
- [ ] Backend creates a `security_audits` table in PostgreSQL.
- [ ] sensitive actions (admin logins, role changes) are logged and sent to a placeholder webhook.

## Tech Stack
- **Backend**: Node.js/Express, PostgreSQL
- **Frontend**: Flutter
- **Security**: Regex-based entropy, Discord/Slack Webhooks

## Proposed Changes

### [Backend]
#### [MODIFY] [authController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/authController.js)
- Update `register` to enforce uppercase, number, and special character.
- Integrate audit logging call for successful logins and role changes.

#### [NEW] [auditController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/auditController.js)
- Helper to log to DB and trigger webhook.

#### [NEW] [034_security_audit_logs.sql](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/models/034_security_audit_logs.sql)
- Schema for `security_audits` table.

### [Frontend]
#### [NEW] [password_strength_meter.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/auth/password_strength_meter.dart)
- Reusable widget using `CozyTheme` and similar styling to the quiz progress bar.

#### [MODIFY] [register_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/auth/register_screen.dart)
- Integrate the strength meter and update validation logic/hints.

## Phase X: Verification
### Automated Tests
- [ ] Run `final_security_check.mjs` with updated password complexity cases.
- [ ] Verify SQL injections in audit trails.
### Manual Verification
- [ ] Register new user: Verify meter changes color (Red -> Yellow -> Green).
- [ ] Perform admin action: Verify entry appears in `security_audits` (Select * from security_audits).

---

[OK] Plan created: docs/PLAN-hybrid-security.md

Next steps:
- Review the plan
- Run `/create` to start implementation
- Or modify plan manually
