# PLAN: Admin Panel Error Fixes

This plan outlines the systematic resolution of API errors, topic deletion conflicts, and UI layout issues in the Med_buddy admin panel.

## Overview
- **Goal**: Restore admin panel stability by fixing 500/409/Assertion errors.
- **Project Type**: FULL-STACK (Backend Node.js + Mobile Flutter)
- **Target Platform**: Desktop (Primary), Mobile (Forward-compatible)

## Success Criteria
- [x] Research completed.
- [ ] `/quiz/admin/questions` returns 200 OK with paginated data.
- [ ] `/stats/inventory-summary` returns 200 OK with correct hierarchy.
- [ ] Topics can be "Force Deleted" (cascading to questions and student history).
- [ ] Flutter Dropdown no longer crashes when switching Subject tabs.
- [ ] No `RenderFlex` overflows on laptop-sized screens.

## Tech Stack
- **Backend**: Node.js, Express, PostgreSQL
- **Mobile**: Flutter, Provider, Google Fonts

## Proposed File Structure Changes
No new files, modifications to existing controllers and screens.

## Task Breakdown

### Phase 1: Backend API Fixes (P0)
- **Task 1.1: Fix Column References in Quiz Controller**
    - **Agent**: `backend-specialist`
    - **File**: `backend/src/controllers/quizController.js`
    - **Input**: Current code using potentially ambiguous columns.
    - **Output**: Queries using `question_text_en`, `name_en`, etc., as per migrations 010 and 014.
    - **Verify**: `curl -X GET http://localhost:3000/api/quiz/admin/questions?page=1` returns JSON content.

- **Task 1.2: Fix Inventory Summary Hierarchy**
    - **Agent**: `backend-specialist`
    - **File**: `backend/src/controllers/statsController.js`
    - **Input**: Failing `getInventorySummary` query.
    - **Output**: Query that correctly joins `topics` p and c using `p.name_en`, `c.name_en`, and `q.bloom_level` (or `q.difficulty`).
    - **Verify**: `curl -X GET http://localhost:3000/api/stats/inventory-summary` returns hierarchical JSON.

- **Task 1.3: Update Delete Topic Logic (Force/Cascade)**
    - **Agent**: `backend-specialist`
    - **File**: `backend/src/controllers/quizController.js`
    - **Input**: Existing `deleteTopic` logic.
    - **Output**: When `force=true`, cascade delete from `responses`, `user_question_progress`, `question_performance`, and `questions` before deleting the topic.
    - **Verify**: Delete a section with 10 questions via API with `?force=true`.

- **Task 1.4: Support Sorting by Type**
    - **Agent**: `backend-specialist`
    - **File**: `backend/src/controllers/quizController.js`
    - **Input**: `adminGetQuestions` `sortMap`.
    - **Output**: Add `'type': 'q.type'` to the `sortMap` to allow server-side sorting by type.
    - **Verify**: API call with `sortBy=type` returns correctly ordered data.

### Phase 2: Mobile UI Stability (P1)
- **Task 2.1: Fix Dropdown Assertion & State Sync**
    - **Agent**: `mobile-developer`
    - **File**: `mobile/lib/screens/admin/questions_screen.dart`
    - **Input**: `_buildToolbar` Dropdown implementation.
    - **Output**: Logic that keeps `_selectedTopicId` if it exists in the new subject's sections, otherwise resets. Fixes the "There should be exactly one item" error by ensuring `value` is present in `items`.
    - **Verify**: Change subject tab from 'Pathophysiology' to 'Pathology' while a section is selected.

- **Task 2.1.1: Persist Last Selected Topic (per Subject)**
    - **Agent**: `mobile-developer`
    - **File**: `mobile/lib/screens/admin/questions_screen.dart`
    - **Input**: User requirement to "make it last checked".
    - **Output**: Memory-based map or local state that remembers the last selected section for each subject tab.
    - **Verify**: Switch from Subject A (Section A1) to Subject B (Section B1) and back to Subject A. Verify Section A1 is still selected.

- **Task 2.2: Implement Force Delete Dialog**
    - **Agent**: `mobile-developer`
    - **File**: `mobile/lib/screens/admin/questions_screen.dart`
    - **Input**: Deletion button callback.
    - **Output**: Enhanced error handling that detects 409 Conflict and shows a "Danger Zone" dialog explaining that student history will be lost.
    - **Verify**: Trigger deletion on a populated section and confirm via the new dialog.

- **Task 2.3: Resolve Layout Overflows**
    - **Agent**: `mobile-developer`
    - **File**: `mobile/lib/screens/admin/questions_screen.dart`
    - **Input**: `Column` and `Row` widgets at lines 148, 295, and table cells.
    - **Output**: Use of `Flexible`, `Expanded`, and `SingleChildScrollView` to prevent overflows on standard 13-15" laptop screens.
    - **Verify**: Visual check of the screen on desktop/web environment.

- **Task 2.4: Implement Question Type Filter & Sort**
    - **Agent**: `mobile-developer`
    - **File**: `mobile/lib/screens/admin/questions_screen.dart`
    - **Input**: `_buildToolbar` and `_buildTable`.
    - **Output**: 
        - Toggle/Dropdown for Question Type filtering in the toolbar.
        - Add `sortKey: 'type'` to the "Type" header cell in `_buildTable`.
    - **Verify**: Filter by 'Single Choice' and verify results. Click 'Type' header and verify sorting.

## Phase X: Verification Checklist
- [ ] Run `python .agent/scripts/verify_all.py .`
- [ ] Manually verify bilingual filter functionality (English searches).
- [ ] Confirm cascade delete works as expected in the database.
- [ ] Final Lint and Build check.
