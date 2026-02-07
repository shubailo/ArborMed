# PLAN: Quiz System Stability and Standardisation

This plan outlines a robust, multi-layered fix for the "Coming Soon" and related data inconsistency issues in the Quiz system. It focuses on schema standardisation, improved frontend state management, and proactive database health monitoring.

## 🎯 Success Criteria
- [ ] Database `questions` table uses `is_active` instead of `active` (Standardised).
- [ ] Quiz Menu reflects "Loading" states correctly without flickers or premature "Coming Soon" messages.
- [ ] A diagnostic tool exists to verify topic hierarchy and question availability.
- [ ] No regression in quiz performance or data integrity.

## 🛠️ Tech Stack
- **Backend**: Node.js, Express, PostgreSQL
- **Frontend**: Flutter (Provider)
- **Tooling**: Node.js (Diagnostic scripts)

## 📁 Proposed File Changes

### 1. Database & Schema
- [NEW] `backend/src/models/022_standardize_active_column.sql`: Migration to rename `active` to `is_active`.

### 2. Backend Logic
- [MODIFY] `backend/src/services/adaptiveEngine.js`: Update all queries to the new column name.
- [MODIFY] `backend/src/controllers/quizController.js`: Update Admin CRUD logic.
- [MODIFY] `backend/src/controllers/statsController.js`: Review `getSubjectDetail` logic.

### 3. Frontend (Mobile)
- [MODIFY] `mobile/lib/services/stats_provider.dart`: Implementation of `QuizState` enum and logic.
- [MODIFY] `mobile/lib/widgets/quiz/quiz_menu.dart`: Visual handling of states (Loading, Success, Empty, Error).

### 4. Tooling
- [NEW] `backend/src/scripts/health_check.js`: Automated integrity script.

---

## 📝 Task Breakdown

### Phase 1: Foundation (Backend & DB)
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| `B-001` | Rename `active` column | `database-architect` | database-design | None |
| `B-002` | Update Backend references | `backend-specialist` | nodejs-best-practices | `B-001` |
| `B-003` | Update Admin Question CRUD | `backend-specialist` | nodejs-best-practices | `B-002` |

### Phase 2: Frontend State Refactor (Mobile)
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| `F-001` | Define `QuizState` pattern | `mobile-developer` | mobile-design | None |
| `F-002` | Refactor `StatsProvider` | `mobile-developer` | mobile-design | `F-001` |
| `F-003` | Update `QuizMenu` UI | `mobile-developer` | mobile-design | `F-002` |

### Phase 3: Integrity & Tooling
| Task ID | Name | Agent | Skills | Dependencies |
|---------|------|-------|--------|--------------|
| `T-001` | Create `health_check.js` | `backend-specialist` | nodejs-best-practices | None |
| `T-002` | Add health check to dev flow | `devops-engineer` | nodejs-best-practices | `T-001` |

---

## ✅ Phase X: Final Verification
- [ ] Run `python .agent/scripts/verify_all.py .`
- [ ] Manual Check: Switch to Clinical Pathology -> Verify no "Coming Soon" flicker.
- [ ] Manual Check: Run `node src/scripts/health_check.js` -> Verify all subjects pass.
- [ ] Manual Check: Add a question via Admin -> Verify `is_active` defaults to true.

Next steps: Review the plan and run `/create` to start implementation.
