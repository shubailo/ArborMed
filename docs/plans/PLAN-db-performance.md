# Plan - Database Performance Optimizations

Address unindexed foreign keys and unused indexes identified by Supabase to optimize query performance and reduce write overhead.

## Overview
Based on Supabase lint reports, several tables have foreign keys without covering indexes, which impacts join performance. Additionally, we have identified at least one unused index that can be removed.

## Project Type: BACKEND (Database Optimization)

## Success Criteria
- [ ] No "Unindexed foreign keys" warnings in Supabase for the identified columns.
- [ ] No "Unused index" warning for `admin_audit_log`.
- [ ] `lint_db_indexes.js` correctly identifies missing indices in local/staging environments.
- [ ] All indexes created successfully with zero downtime (`CONCURRENTLY`).

## Tech Stack
- **Database**: PostgreSQL (Supabase/AWS)
- **Tooling**: Node.js (for the linting script)
- **SQL**: DDL for index management

## File Structure
```
backend/
├── src/
│   ├── models/
│   │   └── 023_supabase_performance_optimizations.sql
│   └── scripts/
│       └── lint_db_indexes.js
```

## Task Breakdown

### Phase 1: Analysis & Tooling
| ID | Task | Agent | Priority |
|----|------|-------|----------|
| P1-1 | Create `lint_db_indexes.js` diagnostic script | `backend-specialist` | High |
| P1-2 | Verify script identifies all current issues | `backend-specialist` | High |

### Phase 2: Implementation
| ID | Task | Agent | Priority |
|----|------|-------|----------|
| P2-1 | Create `023_supabase_performance_optimizations.sql` with `CONCURRENTLY` | `backend-specialist` | High |
| P2-2 | Add `DROP INDEX` for `idx_admin_audit_log_admin_id` | `backend-specialist` | Medium |

### Phase 3: Verification
| ID | Task | Agent | Priority |
|----|------|-------|----------|
| P3-1 | Execute migration script against target database | `devops-engineer` | High |
| P3-2 | Run `lint_db_indexes.js` to confirm resolution | `test-engineer` | High |

## Phase X: Final Verification
- [ ] Run `node backend/src/scripts/lint_db_indexes.js` and verify 0 issues found.
- [ ] Check Supabase Dashboard for updated lint status.
- [ ] Verify no table locks occurred during index creation.

---
**Status**: 🗓️ Planning Complete
