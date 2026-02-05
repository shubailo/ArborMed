# PLAN: Profile Page & User System Overhaul

## Overview
Transform the "Focus Stats" analytics view into a comprehensive "User Profile" hub. This shifts the app towards a social-ready "Medical Network" by introducing unique handles and username-based login.

## Project Type: MOBILE + BACKEND
**Primary Agent:** `mobile-developer` (Cross-platform Flutter + Node.js)

## Success Criteria
- [ ] Existing users can log in using their email or their auto-generated username.
- [ ] Users can change their unique medical handle (@username).
- [ ] "Longest Streak" is automatically calculated and displayed.
- [ ] Password change is secured by "Current Password" verification.
- [ ] User ID (UUID or Numeric) is clearly visible for future friend adding.

## Tech Stack
- **Backend:** Node.js, Express, PostgreSQL
- **Mobile:** Flutter (Provider for state)

## Proposed Database Schema Changes (`007_profile_fields.sql`)
```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS username VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS display_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS avatar_id INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;

-- Migration for legacy users
UPDATE users 
SET username = split_part(email, '@', 1),
    display_name = split_part(email, '@', 1)
WHERE username IS NULL;
```

## Task Breakdown

### Phase 1: Backend (P0)
| Task ID | Component | Agent | Priority | Description |
|---------|-----------|-------|----------|-------------|
| B1 | Schema | `backender` | High | Run `007_profile_fields.sql` migration. |
| B2 | Auth | `backender` | High | Update `login` to check `WHERE email = $1 OR username = $1`. |
| B3 | Streak | `backender` | Medium | In `quizController`, update `longest_streak` if `current_streak > longest_streak`. |
| B4 | Security | `backender` | High | Implement `change-password` requiring `currentPassword`. |

### Phase 2: Mobile Core (P1)
| Task ID | Component | Agent | Priority | Description |
|---------|-----------|-------|----------|-------------|
| M1 | Provider | `mobilist` | High | Update `User` model and `refreshUser` in `AuthProvider`. |
| M2 | Auth Logic| `mobilist` | High | Update `LoginScreen` fields and labels. |

### Phase 3: Mobile UI (P2)
| Task ID | Component | Agent | Priority | Description |
|---------|-----------|-------|----------|-------------|
| U1 | Profile | `mobilist` | High | Create `ProfilePortal` based on duolingo design (ID, @handle, Stats Grid). |
| U2 | Settings | `mobilist` | Medium | Add "Account Settings" section for username/password updates. |

## Phase X: Verification
- [ ] `python .agent/skills/vulnerability-scanner/scripts/security_scan.py .`
- [ ] `npm test` (verify auth logic)
- [ ] Manual check: Login as legacy user with email, then with username.
- [ ] Manual check: Change handle and verify it updates across the system.
