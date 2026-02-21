# Plan: StudyScreen UI Redesign (Option A + C Hybrid)

## 1. Overview
The goal is to refactor the current `StudyScreen` in the existing Flutter application (`apps/student-app`) into a clean, card-based Quiz UI with an asymmetric typographic flow. It must follow a strict State Machine (Loading → Question → Submitting → Feedback → Error) and prepare the UI for future Gamification/Economy features (e.g., Shop, Animations). 

**Design Strategy:**
- Hybrid of **Option A** (Familiar separate card/answer layout) and **Option C** (Modern typography, asymmetric focus).
- Deeply integrates the `mobile-developer` and `frontend-specialist` principles (no safe-harbor "boring" UI, crisp borders, AA contrast, tactile feedback).

## 2. Project Type
**MOBILE** (Flutter)
Primary Agent: `@mobile-developer`
Supporting Concepts: `@frontend-specialist` (Design/Typography)

## 3. Success Criteria
- [ ] UI is split into clean, isolated components (`StudyBody`, `QuestionCard`, `AnswerOption`, `ProgressBar`, `TopStudyBar`).
- [ ] State Machine transitions seamlessly between `Loading`, `ShowingQuestion`, `Submitting`, `Feedback`, and `Error`.
- [ ] No regressions in core M2 logic (Riverpod providers, Drift caching, Dio calls function exactly as before).
- [ ] Visuals pass the "Template Test" (Crisp borders, strong typography, not just another rounded-corner SaaS template).
- [ ] Interactive elements (Answer options) provide immediate visual and haptic feedback (tactile vibration) and have correct touch targets (>= 48dp).

## 4. Tech Stack & State Management
- **Framework:** Flutter (Student App)
- **State Management:** Riverpod (`StudyState` provider already handles the logic, we just map it to the UI).
- **Styling:** Custom Flutter Widgets with a defined medical color palette (Off-white backgrounds, deep/crisp accents, Emerald Green for correct answers, Ruby Red for incorrect).
- **Animations:** Implicit animations (`AnimatedSwitcher`, `AnimatedContainer`) for state transitions and feedback pulses.

## 5. File Structure Modifications

Changes will be scoped to the `apps/student-app/lib/screens/study/` and `apps/student-app/lib/widgets/study/` directories (assuming standard structure).

```text
apps/student-app/lib/
├── screens/study/
│   ├── study_screen.dart        (Main screen, Scaffold, AppBar)
│   └── study_body.dart          (ConsumerWidget handling the State Machine switch)
├── widgets/study/
│   ├── study_top_bar.dart       (Progress bar + Score/Stethoscope icon)
│   ├── question_card.dart       (The central typographic card)
│   ├── answer_option.dart       (Custom button with states: normal, selected, correct, incorrect)
│   ├── feedback_panel.dart      (Optional: area for "Correct! Aldosterone..." text)
│   └── study_error_view.dart    (Friendly offline/error state)
```

## 6. Task Breakdown

### Task 1: Component Extraction & Skeleton
- **Goal:** Create the empty widget files and set up the basic `StudyScreen` structure.
- **Agent:** `@mobile-developer`
- **Output:** `study_screen.dart` scaffolded, `study_body.dart` with a `switch` statement for the UI states (returning placeholders).

### Task 2: Implement `QuestionCard` & Typography
- **Goal:** Build the asymmetric, floating question card with crisp borders (e.g., 1px solid, small radius) and strong typography.
- **Agent:** `@mobile-developer`
- **Output:** `question_card.dart` displaying the Topic Chip and Question text cleanly.

### Task 3: Implement `AnswerOption` Interactions
- **Goal:** Create the interactive answer buttons handling the 4 visual states (Idle, Selected, Correct, Incorrect). Add strong haptic feedback (vibration/tactile response) when an answer is selected.
- **Agent:** `@mobile-developer`
- **Output:** `answer_option.dart` with AnimatedContainer for background/border changes, and tactile feedback (haptic tap via `HapticFeedback`).

### Task 4: State Machine Integration (`StudyBody`)
- **Goal:** Connect the Riverpod state to the UI components. Handle auto-submission logic and transitions.
- **Agent:** `@mobile-developer`
- **Output:** `study_body.dart` dynamically rendering `Loading`, `QuestionCard + AnswerOptions`, `Submitting` (disabled options + spinner), and `Feedback`.

### Task 5: Top Bar, Progress, & Gamification Hooks
- **Goal:** Implement the `StudyTopBar` with a thin progress line and the Stethoscope score counter.
- **Agent:** `@mobile-developer`
- **Output:** A top bar that updates based on session progress and prepares for future animated increments.

## 7. Phase X: Verification
- [ ] **Linting:** Run `flutter analyze` - no warnings.
- [ ] **Formatting:** Run `flutter format .`
- [ ] **Manual Testing:**
  1. Open the Study flow.
  2. Verify Loading spinner appears.
  3. Verify Question Card renders properly even with long text (test scrolling/overflow).
  4. Select an answer; verify `Submitting` state (buttons disabled).
  5. Verify `Feedback` state highlights correctly (Green/Red) and displays explanation text.
  6. Tap 'Next' (or wait for auto-transition) to load the next question.
- [ ] **Offline Test:** Turn off network, verify Drift cache fallback or friendly Error Screen.
- [ ] **Design Verification:** Check against Safe Harbor (No boring generic shapes; has personality).
