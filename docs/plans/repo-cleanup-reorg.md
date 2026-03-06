# Plan: Repository Reorganization

Reorganize the Med_buddy repository to move loose files from the root into a structured system.

## Project Type
**WEB + MOBILE + BACKEND** (Monorepo-style structure)

## Success Criteria
- [ ] Root directory contains only essential config files and main project folders.
- [ ] maintenance/migration scripts moved to `tools/`.
- [ ] Data and temporary files moved to `data/`.
- [ ] `question_batches/` moved to `data/`.
- [ ] `run_mobile.bat` remains in root.

## Tech Stack
- **Primary Agents**: `orchestrator`
- **Shell**: PowerShell (Windows)

## File Structure (Final)
```
Med_buddy/
├── .agent/
├── backend/
├── mobile/
├── content-engine/
├── design-system/
├── tools/ (Maintenance scripts added here)
├── data/ (JSON data and batches)
│   └── question_batches/
├── docs/ (Documentation)
├── .gitignore
├── README.MD
├── run_mobile.bat (Stays in root)
└── ... (other root config files)
```

## Task Breakdown

### Phase 1: Execution - Data Move
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---------|------|-------|--------|----------|--------------|-------------------------|
| T1.1 | Move Data Files | orchestrator | powershell-windows | P0 | None | Root files → `mkdir data` + `mv` → Files in `data/` |
| T1.2 | Move Question Batches | orchestrator | powershell-windows | P0 | T1.1 | `question_batches/` → `mv` → `data/question_batches/` |

### Phase 2: Execution - Script Move
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---------|------|-------|--------|----------|--------------|-------------------------|
| T2.1 | Move Maintenance Scripts | orchestrator | powershell-windows | P1 | None | `.py`, `.mjs` in root → `mv tools/` → Files in `tools/` |

### Phase 3: Cleanup & Path Update
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---------|------|-------|--------|----------|--------------|-------------------------|
| T3.1 | Update Path References | orchestrator | clean-code | P2 | T1.1, T2.1 | README.MD → update strings → Path links work |

### Phase X: Verification
- [ ] Run `python .agent/scripts/checklist.py .`
- [ ] Verify `run_mobile.bat` still works.
- [ ] Verify list of files in root is clean.
