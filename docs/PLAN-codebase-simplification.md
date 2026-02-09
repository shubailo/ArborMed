# PLAN: Codebase Simplification

## Context
The codebase has accumulated redundant UI components and cluttered backend root directories. This plan outlines how to unify internal widgets and organize maintenance scripts without breaking functionality.

---

## Phase 1: Backend Cleanup
Objective: Reduce `backend/` root from 30+ files to a clean core.

### Step 1.1: Identify Deletable Scripts
Identify one-time use scripts that are no longer needed:
- `flatten_patho.js`, `verify_flat.js`, `check_renal_temp.js`, `check_renal_system_slug.js`, `check_slugs_temp.js`, `check_slugs_fixed.js`
- Propose deletion of these.

### Step 1.2: Move Maintenance Scripts
Move remaining utility scripts to `backend/scripts/maintenance/`:
- `cleanup_users.js`
- `check_db.js`
- `apply_migration.js`
- `generate_patho_report.js`
- `generate_patho_report_v2.js`
- `FIX_NOTIFICATIONS_PERMISSIONS.sql`
- `final_lint.txt`, `lint_output.txt`, `merge_log.txt` (Move to `backend/logs/` or delete)

---

## Phase 2: Mobile Widget Unification
Objective: Unify `CozyCard` and `CozyTile` into a single, flexible design component.

### Step 2.1: Analyze Similarities
| Feature | CozyCard | CozyTile |
|---------|----------|----------|
| Background | `paperCream` | `paperWhite` |
| Radius | 24px | 16px |
| Interaction | Static | Interactive (`onTap`) |
| Extras | `PaperTexture`, `title` | Hover/Press animations |

### Step 2.2: Create `CozyPanel`
Create a unified `CozyPanel` in `lib/widgets/cozy/cozy_panel.dart` that:
- Uses `PressableMixin` for interactive states.
- Supports optional `title` and `PaperTexture`.
- Configurable radius and elevation.

### Step 2.3: Replace and Deprecate
- Replace `CozyCard` and `CozyTile` usages with `CozyPanel`.
- Remove the old files once migrations are verified.

---

## Phase 3: Verification
1. **Backend**: Verify `npm run dev` and `npm run seed` still work.
2. **Mobile**: Visual regression check on `QuizMenu`, `AnalyticsPortal`, and `QuizSessionScreen`.

---

## Agent Assignments
- **`backend-specialist`**: Backend script migration and cleanup.
- **`frontend-specialist`**: `CozyPanel` implementation and widget replacement.

## Verification Checklist
- [ ] Backend root has fewer than 10 files (excluding config).
- [ ] `CozyTile` animations use `PressableMixin` logic.
- [ ] All quiz screens render correctly with unified panel.
