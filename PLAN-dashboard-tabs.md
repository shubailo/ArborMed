# PLAN: Dashboard Tabs & Performance Cache

This plan outlines the implementation of a tabbed admin dashboard separated by question types (Medicine, ECG, Case Studies), with persistent filtering and a cached statistics table for performance.

## Overview
- **Project Type**: WEB (Admin Dashboard / Teacher Portal)
- **Primary Agents**: `database-architect`, `backend-specialist`, `frontend-specialist`

## Success Criteria
- [x] Socratic Gate Respected
- [ ] Admin can switch between "General", "ECG", and "Case Studies" tabs.
- [ ] Database includes a `question_performance` table for cached metrics.
- [ ] Question creation/editing supports the new `type` values.
- [ ] Dashboard filters (Search, Bloom) persist when switching tabs.
- [ ] Statistics (Success Rate, Attempts) are displayed inline in the question table.

## Tech Stack
- **Database**: PostgreSQL (new schema column + cache table)
- **Backend**: Node.js / Express (worker logic for cache sync)
- **Frontend**: Flutter Web (Provider, DataTable, Tabs)

---

## Task Breakdown

### Phase 1: Database Foundation
**Agent**: `database-architect` | **Skill**: `database-design`

| Task ID | Task Name | Dependencies | Input → Output → Verify |
|---------|-----------|--------------|-------------------------|
| T1.1 | Update Question Types | None | `questions.type` updated to allow 'ecg' and 'case_study' → SQL Migration → Row exists with new type |
| T1.2 | Create `question_performance` Table | None | Schema design → `CREATE TABLE question_performance (...)` → Table exists in DB |

### Phase 2: Backend Logic & Caching
**Agent**: `backend-specialist` | **Skill**: `nodejs-best-practices`

| Task ID | Task Name | Dependencies | Input → Output → Verify |
|---------|-----------|--------------|-------------------------|
| T2.1 | Implement Cache Sync Service | T1.2 | Logic to aggregate `responses` into `question_performance` → `syncPerformance()` function → Table populated with data |
| T2.2 | Update Admin Question API | T1.1, T2.1 | JOIN `questions` with `question_performance` → API returns `success_rate` and `attempts` → Postman check |

### Phase 3: Frontend - Tabbed Navigation
**Agent**: `frontend-specialist` | **Skill**: `frontend-design`

| Task ID | Task Name | Dependencies | Input → Output → Verify |
|---------|-----------|--------------|-------------------------|
| T3.1 | Implement Dashboard Tabs | None | Flutter `DefaultTabController` → Tabs for Medicine/ECG/Cases → UI visual confirmation |
| T3.2 | Sync Tabs with Question Types | T3.1, T2.2 | Filter API calls by `type` param → Tab clicking refreshes list for that type → Table content changes |
| T3.3 | Persistent Filter Logic | T3.1 | State management for Search/Bloom level → Persist variables across tab changes → Filters remain after switch |

### Phase 4: Frontend - Statistics Integration
**Agent**: `frontend-specialist` | **Skill**: `frontend-design`

| Task ID | Task Name | Dependencies | Input → Output → Verify |
|---------|-----------|--------------|-------------------------|
| T4.1 | UI Columns for Stats | T2.2 | Add 'Attempts' and 'Accuracy' columns to `DataTable` → Visual confirmation of metrics → Matches DB values |
| T4.2 | Visual Color Coding | T4.1 | Logic to color-code success rates (Red/Yellow/Green) → UI highlights low-performance questions → Visual check |

---

## Phase X: Final Verification

- [ ] **Security**: Verify admin-only middleware is active on new endpoints.
- [ ] **Performance**: Verify dashboard load time with 100+ questions (using cache table).
- [ ] **UX**: Verify filters correctly apply across all tabs.
- [ ] **Lint**: Run `flutter analyze` and `npm run lint`.

## Agent Assignments
- `database-architect`: Task T1.1, T1.2
- `backend-specialist`: Task T2.1, T2.2
- `frontend-specialist`: Phase 3, Phase 4
- `debugger`: Final verification and performance audit
