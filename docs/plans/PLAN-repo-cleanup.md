# PLAN: Repository Cleanup & Debris Removal

This plan outlines the steps for a comprehensive cleanup of the ArborMed repository to improve maintainability and developer focus.

## Goal
Reduce noise by archiving old documentation, consolidating root utility scripts, and purging redundant data artifacts.

## User Review Required
> [!IMPORTANT]
> Please confirm if you want the following files **DELETED** or **ARCHIVED**:
> 1. `docs/PLAN-*.md` (42 files) -> Proposed: Archive to `docs/archive/`
> 2. Root `.js` scripts -> Proposed: Move to `tools/utility/`
> 3. `backend/src/scripts/archive/` -> Proposed: **DELETE** (Redundant)
> 4. `mobile/analyze_results.txt` -> Proposed: **DELETE**

## Proposed Changes

### Phase 1: Documentation Archival
- [x] Create directory `docs/archive/`
- [x] Move all `docs/PLAN-*.md` files (except this one) to `docs/archive/`
- [x] Move any `VERIFICATION-*.md` files to `docs/archive/`

### Phase 2: Script Consolidation
- [x] Create directory `tools/utility/`
- [x] Move `check_active.js`, `check_db.js`, `check_subjects.js`, `cleanup_subjects.js`, `debug_sections.js` to `tools/utility/`
- [x] Ensure `run_mobile.bat` remains in root (if used frequently) or move to `tools/`.

### Phase 3: Redundant Archive Purge
- [x] Delete `backend/src/scripts/archive/` directory and its 17 constituent files.
- [x] Remove `QUESTION_TEMPLATE.csv` from root.

### Phase 4: Temp File Removal
- [x] Delete `mobile/analyze_results.txt`.
- [x] Delete `mobile/lib/c:\Users\shuba\Desktop\Med_buddy\.antigravityignore` (if malformed).

## Verification Plan
### Automated Verification
- [ ] `ls -R` to verify the root directory is clean.
- [ ] Verify `docs/archive` contains the historical plans.

### Manual Verification
- [ ] User confirms the repository feels "lighter" and only contains currently active work.
