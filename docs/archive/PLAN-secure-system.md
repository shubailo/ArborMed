# PLAN: Secure System Hardening (Comprehensive)

This plan implements a high-security architecture for MedBuddy, moving beyond simple fixes to a "Defense-in-Depth" model.

## 1. Overview
Hardening the Node.js backend and Supabase database. Transitioning from superuser access to Least Privilege, implementing Row Level Security (RLS) with role-based hierarchies, and upgrading to a Refresh Token security model.

## 2. Project Type
**HYBRID (Mobile + Backend)**

## 3. Success Criteria
1. **Secrets**: `JWT_SECRET` rotated and `JWT_REFRESH_SECRET` implemented.
2. **Database**: Backend connected via `med_buddy_app` role (non-superuser).
3. **RLS**: Policies implemented for Student (own data) and Teacher (assigned students) roles.
4. **Auth**: Refresh Token + Short-lived Access Token flow functional on Mobile.

## 4. Tech Stack
| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Auth** | JWT (HS256) | Standard; upgraded with Refresh Tokens. |
| **DB Identity** | Postgres Roles | Least Privilege separation. |
| **DB Protection** | Postgres RLS | Enforcement at the record level. |

## 5. Task Breakdown

### Phase 1: Identity & Secrets (Immediate)
- [ ] **Task 1: Secret Rotation & Generation**
    - *Agent*: `security-auditor`
    - *Input*: `backend/.env`
    - *Action*: Generate secure `JWT_SECRET` and `JWT_REFRESH_SECRET`.
- [ ] **Task 2: Least Privilege DB Role**
    - *Agent*: `database-architect`
    - *Action*: Create `med_buddy_app` user with restricted permissions to `public` schema. Update `DATABASE_URL`.

### Phase 2: Database Hardening (RLS & Roles)
- [ ] **Task 3: Enable RLS & Define Roles**
    - *Agent*: `database-architect`
    - *Action*: Create `017_enable_rls.sql`. Define `student` and `teacher` app roles.
- [ ] **Task 4: Implement Complex RLS Policies**
    - *Agent*: `security-auditor`
    - *Action*: Create policies for `users`, `quiz_sessions`, `responses`.
    - *Logic*: Users access own data; Teachers access data of students in their cohort (to be defined in `cohorts` table).

### Phase 3: Advanced Authentication (API & Mobile)
- [ ] **Task 5: Refresh Token Backend**
    - *Agent*: `backend-specialist`
    - *Action*: Update `authController.js` and `authMiddleware.js`. Create `refresh_tokens` table.
- [ ] **Task 6: Mobile Auth Update**
    - *Agent*: `mobile-developer`
    - *Action*: Update `api_service.dart` and `auth_provider.dart` to handle token refresh automatically.

### Phase 4: Performance & Cleanup
- [ ] **Task 7: Secondary Indexes**
    - *Agent*: `database-architect`
    - *Action*: Implement missing indexes from audit.

## Phase X: Verification
- [ ] **Security Scan**: `python .agent/skills/vulnerability-scanner/scripts/security_scan.py .`
- [ ] **Auth Stress Test**: Verify tokens expire correctly and refresh without user intervention.
- [ ] **RLS Bypass Check**: Verify restricted user cannot access `postgres_role` or other user's data.
