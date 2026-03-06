# Project Plan: ArborMed Hybrid Transition (Option B)

## 🔴 Overview
Az ArborMed 2.0 ökoszisztéma áthelyezése egy hibrid monorepo struktúrába. A megoldás ötvözi a **PNPM Workspaces** (Node.js/Next.js) és a **Melos** (Flutter/Dart) előnyeit, lehetővé téve a hatékony kereszt-platformos fejlesztést és kódmegosztást.

## 🔴 Project Type
**WEB & MOBILE & BACKEND** (Hybrid Monorepo)

## 🔴 Success Criteria
1.  **Hybrid Orchestration**: PNPM kezeli a Node.js függőségeket és workspace-eket, a Melos pedig a Flutter csomagokat.
2.  **Incremental Migration**: A meglévő `backend/` és `mobile/` kódok sikeres átmozgatása törés nélkül.
3.  **Shared Types**: Egy közös `packages/shared-types` létrehozása, amit a Backend és a (későbbi) Next.js Dashboard is használ.
4.  **Verified Environment**: Minden komponens buildelhető és tesztelhető az új struktúrában.

## 🔴 Tech Stack
-   **Monorepo Core**: PNPM Workspaces (Node ecosystem)
-   **Flutter Management**: Melos
-   **Mobile**: Flutter (Student App)
-   **Web**: Next.js (Professor Dashboard)
-   **Backend**: Node.js/Express + PostgreSQL
-   **Shared**: TypeScript (Type definitions)

## 🔴 File Structure
```text
ArborMed/
├── apps/
│   ├── student_app/         # Flutter (átmozgatva a mobile/-ból)
│   └── prof-dashboard/      # Next.js (Phase 4)
├── services/
│   └── backend/             # Express API (átmozgatva a backend/-ből)
├── packages/
│   ├── shared-types/        # Node.js/TS megosztott típusok
│   ├── core/                # Flutter megosztott logika
│   └── features/            # Flutter moduláris funkciók
├── pnpm-workspace.yaml      # PNPM konfiguráció
├── melos.yaml               # Melos konfiguráció
├── package.json             # Root scripts (pnpm, melos hívások)
└── docs/
    └── PLAN-arbormed-hybrid-transition.md
```

## 🔴 Task Breakdown

### Phase 1: Infrastructure Setup (P0)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-01 | Cleanup & Prepare | `devops-engineer` | `bash-linux` | P0 | None | **INPUT**: Hibás `apps` és build mappák. <br>**OUTPUT**: Tiszta gyökér. <br>**VERIFY**: `apps`, `prof-dashboard` (root) törölve. |
| TASK-02 | PNPM Workspace Init | `orchestrator` | `nodejs-best-practices` | P0 | TASK-01 | **INPUT**: Root. <br>**OUTPUT**: `pnpm-workspace.yaml`, gyökér `package.json`. <br>**VERIFY**: `pnpm install` lefut hiba nélkül. |
| TASK-03 | Melos Integration | `mobile-developer` | `dart-patterns` | P0 | TASK-02 | **INPUT**: Root. <br>**OUTPUT**: `melos.yaml`. <br>**VERIFY**: `melos --version` és bootstrap parancsok elérhetők a gyökérből. |

### Phase 2: Inkrementális Migráció (P0)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-04 | Migrate Backend | `backend-specialist` | `clean-code` | P0 | TASK-02 | **INPUT**: `backend/` mappa. <br>**OUTPUT**: `services/backend/`. <br>**VERIFY**: API health check sikeres. |
| TASK-05 | Migrate Student App | `mobile-developer` | `mobile-design` | P0 | TASK-03 | **INPUT**: `mobile/` mappa. <br>**OUTPUT**: `apps/student_app/`. <br>**VERIFY**: Flutter analyze és build sikeres. |

### Phase 3: Shared Logic & Types (P1)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-06 | Shared Types Repo | `backend-specialist` | `api-patterns` | P1 | TASK-04 | **INPUT**: Backend DTO-k. <br>**OUTPUT**: `packages/shared-types`. <br>**VERIFY**: Backend importálja a közös típusokat. |

## 🔴 Phase X: Verification
- [ ] `pnpm recursive install` sikeres.
- [ ] `melos bootstrap` sikeres.
- [ ] Backend elindul és elérhető.
- [ ] Student App buildelhető.
- [ ] `verify_all.py` hiba nélkül lefut.
