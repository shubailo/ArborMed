# Plan: Codebase & Filesystem Reorganization

## 1. Goal
Streamline the project structure by consolidating scattered scripts, cleaning up the root directory, and establishing clear boundaries for tools and documentation.

## 2. Current State Analysis
- **Root Clutter**: `AGENTS.md`, `PLAN-hungarian-translation.md`, `arbormed.png` are in the root.
- **Split Scripts**:
  - `scripts/`: Contains general question processing scripts (`combine_and_validate.js`, etc.).
  - `backend/scripts/`: Contains backend-specific and utility scripts (`generate_questions.js`, `test_smtp.js`).
- **Data Staging**: `questions/` directory at root is used for pending batches but is currently empty.

## 3. Proposed Structure

### A. Consolidate Scripts -> `tools/scripts/`
Move all maintenance, generation, and translation scripts to a centralized `tools/` directory.
- `scripts/` -> `tools/scripts/`
- `backend/scripts/` -> `tools/scripts/` (unless strictly requiring backend environment, but most seem to be data processing).
  - *Exception*: `test_smtp.js` might belong in `backend/test/` or similar.

### B. Clean Root Directory
- Move `PLAN-hungarian-translation.md` -> `docs/`.
- Move `arbormed.png` -> `docs/assets/` or `design-system/assets/`.
- Keep `README.md`, `render.yaml`, `run_mobile.bat`, `AGENTS.md` (high visibility).

### C. Standardize Data Staging
- Move `questions/` -> `tools/data-staging/` or remove if no longer needed.

## 4. Execution Plan

### Step 1: Create Directories
- `tools/scripts`
- `tools/data-staging`
- `docs/assets`

### Step 2: Move Files
1.  **Docs**: Move `PLAN-hungarian-translation.md` to `docs/`.
2.  **Assets**: Move `arbormed.png` to `docs/assets/`.
3.  **Scripts**:
    - Move contents of `scripts/` to `tools/scripts/`.
    - Move contents of `backend/scripts/` to `tools/scripts/`.
      - *Note*: Need to update `require` paths in these scripts (e.g. `../src/config/db`).

### Step 3: Cleanup
- Remove empty `scripts/` folder.
- Remove empty `questions/` folder.
- Remove empty `backend/scripts/` folder if all moved.

## 5. Decision Points
> [!IMPORTANT]
> **User, please review:**
> 1.  Do you agree with moving **all** scripts to `tools/scripts/`?
> 2.  Should we keep `AGENTS.md` at the root?
