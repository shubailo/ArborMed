# PLAN-pedagogical-engine.md

## Overview
This project upgrades the ArborMed adaptive learning engine from a basic Leitner system to a professional **Adaptive SM-2** algorithm with **Bloom Taxonomy** mastery weighting and **Selection Transparency**.

## Project Type: BACKEND (Service Logic)

## Success Criteria
- [ ] SM-2 Interval Calculation: Correctly handles quality (0-5) and individual Easiness Factors (EF).
- [ ] Retention Auto-Correction: EF modifier adjusts (0.85x/1.15x) based on rolling retention (last 50 reviews).
- [ ] Bloom Weighting: Mastery score calculated with Levels 1-2 (1x) and Levels 3-4 (2x). Progress capped at Level 4.
- [ ] Selection Transparency: `nextQuestion` API returns `selectionReason`.
- [ ] Schema Compatibility: Database supports new SM-2 and analytics columns.

## Tech Stack
- **Database**: PostgreSQL (Migrations for `responses`, `user_question_progress`, and `user_topic_progress`).
- **Logic**: Node.js (Service-layer refactor of `adaptiveEngine.js` and `analyticsEngine.js`).
- **Testing**: Jest (Unit tests for algorithm correctness).

## File Structure
- `services/backend/src/models/039_pedagogical_engine_upgrade.sql`: Database migration.
- `services/backend/src/services/adaptiveEngine.js`: Refactored question selection & result processing.
- `services/backend/src/services/analyticsEngine.js`: SM-2 and Mastery calculation logic.
- `services/backend/src/controllers/quizController.js`: API endpoint updates for `quality` and `selectionReason`.

## Task Breakdown

### Phase 0: Foundation (Database & Shared Types)
- **Task ID**: P3-T01
- **Name**: Database Migration
- **Agent**: `database-architect`
- **Priority**: P0
- **INPUT**: Current `responses` and `user_question_progress` schema.
- **OUTPUT**: `039_pedagogical_engine_upgrade.sql` created and applied.
- **VERIFY**: `psql` command confirms columns `quality`, `easiness_factor`, `interval_days`, `selection_reason` exist.

### Phase 1: Core Engine Implementation
- **Task ID**: P3-T02
- **Name**: Refactor SM-2 Logic
- **Agent**: `backend-specialist`
- **Priority**: P1
- **Dependencies**: P3-T01
- **INPUT**: `analyticsEngine.js` and user-specified SM-2 formula.
- **OUTPUT**: SM-2 interval and EF calculation logic.
- **VERIFY**: Unit tests verify quality 0-2 resets interval and decreases EF, while 3-5 increases them.

- **Task ID**: P3-T03
- **Name**: Implement Weighted Bloom Mastery
- **Agent**: `backend-specialist`
- **Priority**: P1
- **INPUT**: Bloom Levels 1-4 mapping (1-2: 1x, 3-4: 2x).
- **OUTPUT**: Updated `mastery_score` calculation in `adaptiveEngine.js`.
- **VERIFY**: DB query on `user_topic_progress` shows mastery increasing faster for Level 3/4 questions.

- **Task ID**: P3-T04
- **Name**: Retention Self-Correction
- **Agent**: `backend-specialist`
- **Priority**: P2
- **INPUT**: Last 50 responses for user.
- **OUTPUT**: Logic to adjust `ef_modifier` based on 85%-90% retention target.
- **VERIFY**: Logs show EF modification triggers when retention drifts.

### Phase 2: API & Transparency
- **Task ID**: P3-T05
- **Name**: Selection Transparency API
- **Agent**: `backend-specialist`
- **Priority**: P2
- **INPUT**: `quizController.js` and `adaptiveEngine.js`.
- **OUTPUT**: API response including `selectionReason` string.
- **VERIFY**: Postman/Flutter call to `/quiz/next` contains descriptive `selectionReason`.

## Phase X: Verification
- [ ] Run `python .agent/scripts/verify_all.py .`
- [ ] Verify SQL migrations are idempotent.
- [ ] Verify `quality` rating is correctly persisted in `responses`.
- [ ] Verify `SelectionReason` is human-readable and accurate.
- [ ] Manual check: Retention calculation handles users with < 50 responses gracefully.
