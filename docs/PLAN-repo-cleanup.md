# Project Plan: Repo Cleanup (Consolidation)

**Overview**:  
Consolidate backend seeding logic into a single `seed_manager.js` tool and clean up the repository root by checking utility scripts into a dedicated `tools/` folder. This reduces "script sprawl" and improves developer experience.

**Project Type**: BACKEND + DEVOPS
**Success Criteria**:
- [ ] Root directory free of loose `.py`/`.txt` files (moved to `tools/`).
- [ ] Single entry point for seeding: `npm run seed [options]`.
- [ ] Old seed scripts archived in `backend/src/scripts/archive/`.
- [ ] Documentation moved to `docs/`.

## File Structure
```
/
├── tools/                  # [NEW] Utility scripts (python, batch, etc)
├── docs/                   # [NEW] Documentation files
└── backend/
    └── src/
        └── scripts/
            ├── seed_manager.js  # [NEW] Unified entry point
            └── archive/         # [NEW] Old scripts
```

## Task Breakdown

### Phase 1: Root Cleanup (Safe)
**Agent**: `devops-engineer`  
**Skill**: `bash-linux` / `powershell-windows`

- [x] **Task 1.1**: Create `tools/` directory.
    - *Input*: None
    - *Output*: `tools/` folder.
    - *Verify*: `Test-Path tools/`
- [x] **Task 1.2**: Move root utility scripts to `tools/`.
    - *Input*: `analyze_hitboxes.py`, `generate_sfx.py`, `run_mobile.bat`, etc.
    - *Output*: Clean root.
    - *Verify*: Root contains only project-level files (.gitignore, README, etc).

### Phase 2: Documentation Organization
**Agent**: `project-planner`

- [x] **Task 2.1**: Move root `.md` files to `docs/`.
    - *Input*: `create bloom level 1 questions.md`, etc.
    - *Output*: Organized `docs/` folder.
    - *Verify*: `docs/` contains manual files.

### Phase 3: Backend Consolidation
**Agent**: `backend-specialist`  
**Skill**: `nodejs-best-practices`

- [x] **Task 3.1**: Create `backend/src/scripts/archive/`.
    - *Input*: None
    - *Output*: Folder created.
- [x] **Task 3.2**: Create `backend/src/scripts/seed_manager.js`.
    - *Input*: Logic from existing `seed*.js` files.
    - *Output*: Unified script using `commander` or simple args.
    - *Logic*: Switch statement to run `full`, `users`, `questions`, etc.
    - *Verify*: `node src/scripts/seed_manager.js --help` works.
- [x] **Task 3.3**: Update `backend/package.json`.
    - *Input*: `npm run seed` script.
    - *Output*: `"seed": "node src/scripts/seed_manager.js"`
    - *Verify*: `npm run seed` executes safely.
- [x] **Task 3.4**: Archive old scripts.
    - *Input*: `seed_full.js`, `seedDetailedPathology.js`, etc.
    - *Output*: Moved to `archive/`.

## Phase X: Verification
- [x] `npm run seed --help` returns usage info.
- [x] Root directory is clean.
- [ ] Backend server still starts (`npm run dev`).

## ✅ PHASE X COMPLETE
- Lint: [ ]
- Security: [ ]
- Build: [ ]
