# PLAN: Cleanup and Optimization

## Overview
Cleaning up repository clutter and optimizing code for the MedBuddy project.

## Project Type
MOBILE (Flutter) & BACKEND (Node.js)

## Success Criteria
- [ ] 0 errors/warnings in `flutter analyze`.
- [ ] 0 temporary `.txt` / `.log` files in project roots.
- [ ] Successful `npm run build` in backend.
- [ ] Correct `CozyTheme` imports throughout the app.

## Task Breakdown

### Phase 1: Critical Repairs
- [ ] Repair `mobile/lib/widgets/quiz/quiz_menu.dart` syntax.
- [ ] Fix `CozyTheme` imports in `mobile/lib/widgets/questions/question_renderer.dart` and `mobile/lib/widgets/quiz/quiz_portal.dart`.

### Phase 2: Repository Cleanup
- [ ] Remove `mobile/*.txt` and `mobile/*.log`.
- [ ] Remove `backend/*.txt` and `backend/*.log`.
- [ ] Update `.gitignore` to include clutter patterns.

### Phase 3: Optimization
- [ ] Apply `const` to widgets.
- [ ] Review backend dependencies.

## Phase X: Verification
- [ ] `flutter analyze` passes.
- [ ] `npm run dev` starts successfully.
- [ ] `python .agent/scripts/checklist.py .` passes.
