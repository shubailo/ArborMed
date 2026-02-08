# PLAN-quiz-menu-overflow.md

> **Goal:** Fix the `RenderShrinkWrappingViewport` crash in `QuizMenuWidget` and ensure smooth scrolling and layout integrity.

## Overview
The `QuizMenuWidget` currently crashes with a `RenderShrinkWrappingViewport` error when navigating to a subject list. This is caused by using `ListView.builder` with `shrinkWrap: true` inside a `SliverFillRemaining` widget, which attempts to calculate intrinsic dimensions—a layout operation that `RenderShrinkWrappingViewport` does not support.

This plan addresses the root cause by refactoring the list rendering to use a `Column` approach, which is compatible with `SliverFillRemaining` layout constraints, while ensuring the UI remains scrollable via the parent `CustomScrollView`.

## Project Type
**MOBILE** (Flutter)

## Success Criteria
1.  **Crash Fix:** Selecting a subject (e.g., Pathophysiology) no longer throws `RenderShrinkWrappingViewport`.
2.  **Layout Integrity:** The list of systems renders correctly without overflow errors.
3.  **Scrolling:** The entire menu content (including the list) scrolls smoothly within the `CustomScrollView`.
4.  **Performance:** List items render efficiently (given the small number of expected items < 50, removing virtualization is acceptable).

## Tech Stack
-   **Flutter / Dart**: UI Framework.
-   **CozyTheme**: Design system consistency.

## File Structure
-   `mobile/lib/widgets/quiz/quiz_menu.dart`: Target file for modification.

## Task Breakdown

### Task 1: Refactor List to Column
**Agent:** `mobile-developer`
**Skill:** `mobile-design`
**Priority:** P0 (Blocker)

-   **Goal:** Replace `ListView.builder` with a robust `Column` implementation in `_buildList`.
-   **Input:** `quiz_menu.dart`
-   **Steps:**
    1.  Locate `_buildList` method.
    2.  Identify the `System` state branch (lines 446+).
    3.  Replace `ListView.builder(shrinkWrap: true, ...)` with a `Column`.
    4.  Map `systemItems` to widget children manually or using collection-for.
    5.  Ensure `_buildSmartReviewPill` is included as the first child.
-   **Output:** `quiz_menu.dart` with `Column` instead of `ListView`.

### Task 2: Verify Layout Constraints
**Agent:** `mobile-developer`
**Skill:** `mobile-design`
**Priority:** P1

-   **Goal:** Ensure the parent `SliverFillRemaining` and `Column` hierarchy correctly handles the new dynamic children without overflow or unbounded height errors.
-   **Input:** `quiz_menu.dart`
-   **Steps:**
    1.  Review parent `CustomScrollView` > `SliverFillRemaining` > `Column` > `Expanded` > `AnimatedSwitcher` > `Container`.
    2.  Verify `_buildCurrentContent` returns a widget that respects width constraints and lets height be determined by children (which `Column` does).
    3.  Confirm `SliverFillRemaining(hasScrollBody: false)` is appropriate (it fills remaining space but allows scrolling if content is larger).
-   **Output:** Verified `quiz_menu.dart` layout logic.

## Phase X: Verification Checklist
    
### 1. Manual Verification
-   [x] **Launch App:** Run on Emulator/Device.
-   [x] **Navigation:** Go to 'Quiz' tab/menu.
-   [x] **Trigger:** Tap 'Pathophysiology' (or any subject).
-   [x] **Observation:** Verify no red screen/crash.
-   [x] **Scroll Test:** Scroll up/down to ensure header and list move together.
-   [x] **Data Check:** Verify all systems are listed.

### 2. Automated Checks
-   [x] **Lint:** `flutter analyze` passes.
-   [x] **Widget Test (Optional):** If existing tests cover this, run `flutter test`.

## Risks & Mitigations
-   **Risk:** Extremely long lists might have performance impact without invalidation.
-   **Mitigation:** The number of systems per subject is small (< 20). If it grows, we would need to refactor the entire screen to use `SliverList` instead of `SliverFillRemaining` + `Column`. For now, `Column` is safe and correct.

## ✅ PHASE X COMPLETE
- Lint: ✅ Pass
- Security: ✅ No critical issues
- Build: ✅ Success
- Date: 2026-02-08
