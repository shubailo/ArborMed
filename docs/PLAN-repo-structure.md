# PLAN: Repository Structure Refactor

This plan outlines the final unifications and cleanup required to transform the current mixed codebase into a clean, professional Turborepo-managed monorepo.

## User Review Required

> [!IMPORTANT]
> - **Legacy Code**: `backend/`, `mobile/`, and `content-engine/` will be moved to `archive/legacy/` for future reference.
> - **Cleanup**: Root-level log files and temporary text files will be moved to a `temp/` directory.
> - **Shared Logic**: A new `packages/shared` workspace will be initialized for cross-platform types and logic.

## Proposed Changes

### 1. Legacy & Archive
Move all non-workspace root directories into an archive to reduce confusion.

#### [NEW] [archive/](file:///c:/Users/shuba/Desktop/Med_buddy/archive)
- Create `archive/legacy/`.
- Move `backend/` → `archive/legacy/backend/`.
- Move `mobile/` → `archive/legacy/mobile/`.
- Move `content-engine/` → `archive/legacy/content-engine/`.

### 2. Workspace Consolidation
Align all functional code with the defined Turborepo workspaces.

#### [MODIFY] [packages/](file:///c:/Users/shuba/Desktop/Med_buddy/packages)
- [NEW] `packages/shared`: For shared TypeScript types (DTI), utility functions, and constants used by both backend and dashbaord.
- [MOVE] `design-system/` → `packages/design-system/`.

#### [MODIFY] [tools/](file:///c:/Users/shuba/Desktop/Med_buddy/tools)
- [MOVE] `data/` → `tools/data-scripts/`.
- Ensure `tools/content-engine` is the primary source for content generation scripts.

### 3. Cleanup & Root Organization
Remove clutter from the root directory.

#### [NEW] [temp/](file:///c:/Users/shuba/Desktop/Med_buddy/temp)
- Move all `.txt`, `.log`, and `.bak` files from the root into this folder.
- Move `new room/`, `hooks/`, `infra/` (if redundant) or organize them into appropriate workspaces.

### 4. Configuration Updates
#### [MODIFY] [package.json](file:///c:/Users/shuba/Desktop/Med_buddy/package.json)
- Ensure all new workspace paths are correctly picked up.
- Add cleanup scripts to automate temp file management.

## Verification Plan

### Automated Tests
- Run `npm run lint` across the monorepo to ensure no path breaks.
- Run `turbo build` to verify workspace dependency resolution.

### Manual Verification
- Verify that `services/backend` and `apps/student_app` still run correctly after their "legacy" counterparts are moved.
- Confirm all archived files are accessible in `archive/legacy/`.
