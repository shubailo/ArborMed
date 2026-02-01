# PLAN: Dynamic Motivational Quotes

## Overview
Replace the static study break text with dynamic, time-synced motivational quotes. This feature includes a backend management system for admins and an automatic rotation mechanism that updates the quote every 10 minutes.

- **Project Type**: FULL-STACK (Mobile + Backend)
- **Primary Agents**: `backend-specialist`, `mobile-developer`

## User Review Required
> [!IMPORTANT]
> **Quote Rotation**: Every student will see the same quote at the same time. The rotation is handled by the server using the formula: `index = (current_time / 10min) % total_quotes`.

## Proposed Changes

### [Component] Backend (Node.js/Express)
Summary: Add a new `quotes` table and endpoints for rotation and admin management.

#### [NEW] [013_motivational_quotes.sql](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/data/013_motivational_quotes.sql)
- Create `quotes` table: `id`, `text`, `author`, `created_at`.
- Seed with initial medical-themed motivational quotes.

#### [MODIFY] [quizRoutes.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/routes/quizRoutes.js)
- `GET /api/quiz/quote`: Public endpoint for current rotation.
- `GET /api/quiz/admin/quotes`: Admin list.
- `POST /api/quiz/admin/quotes`: Admin create.
- `DELETE /api/quiz/admin/quotes/:id`: Admin delete.

#### [MODIFY] [quizController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/quizController.js)
- Implement `getCurrentQuote` using time-based index calculation.
- Implement CRUD operations for admin management.

---

### [Component] Mobile (Flutter)
Summary: Update the UI to fetch/display quotes and add an admin management screen.

#### [NEW] [admin_quotes_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/admin_quotes_screen.dart)
- List-view of current quotes.
- Ability to add new quotes or swipe to delete.

#### [MODIFY] [admin_shell.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/admin_shell.dart)
- Add "Quotes" to the navigation menu.
- Register `AdminQuotesScreen`.

#### [MODIFY] [quiz_menu.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/quiz/quiz_menu.dart)
- Replace static `Text` with a self-refreshing quote widget.
- Implement local caching + default list as a fallback.

## Verification Plan

### Automated Tests
- `python .agent/skills/testing-patterns/scripts/test_runner.py` (Backend unit tests for rotation logic).

### Manual Verification
1.  **Admin Check**: Open Admin Panel -> Quotes. Add a test quote. Verify it appears in the list.
2.  **Display Check**: Open Study Break screen. Verify a quote is displayed.
3.  **Rotation Check**: Wait 10 minutes or manually shift server clock (if testing) to verify quote changes.
4.  **Offline Check**: Turn off wifi. Verify fallback quote is displayed.
