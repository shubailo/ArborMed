# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed aims to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The Flutter frontend effectively combines study modes with deep gamification within an interactive isometric "Room" system (`RoomWidget`).

While the current foundation is strong—featuring muted pastel palettes (e.g., `#8CAA8C`, `#D2B48C`, `#F4F1ED`) and a local-first architecture powered by `Drift`—the user experience suffers from friction in micro-interactions and visual hierarchy. Complex overlapping elements risk overwhelming the learning process. We recommend a *refinement* strategy focused on optimizing the focus state during studying, standardizing feedback, and improving layout transitions, rather than a full redesign.

## 2. Analysis

### 2.1 Heuristic Evaluation
Evaluating against key usability heuristics reveals:

*   **Visibility of System Status:**
    *   *Negative:* When querying large local question banks via `Drift`, the `QuizLoadingScreen` fails to provide granular feedback, causing anxiety that the app has frozen.
*   **Match Between System and Real World:**
    *   *Positive:* The use of real-world analogies like the "Clinic" (`ClinicDirectorySheet`) grounds the experience in a relatable medical context.
*   **Consistency and Standards:**
    *   *Negative:* Navigation paradigms are mixed. `ContextualShopSheet` and `ClinicDirectorySheet` utilize bottom sheet overlays, while other areas disrupt the 3D space.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The active `RoomWidget` running continuously behind intensive tasks degrades battery and introduces unnecessary cognitive load.

### 2.2 Content and Architecture
*   **Information Architecture:** The primary hub (`RoomWidget`) is highly immersive but buries administrative or quick-access actions. The `AdminResponsiveShell` is cleanly separated for desktop/mobile admin use, but student navigation lacks a unified 2D HUD.
*   **Content Organization:** Inside the quiz, the stem is well-placed. However, the `QuizFeedbackOverlay` occasionally conflicts visually with floating gamification assets (`ConfettiOverlay`, `CoinParticle`), creating a cluttered post-answer state.

### 2.3 Visual Design
*   **Color & Typography:** The "Cozy Competence" palette (`#8CAA8C`, `#F4F1ED`) succeeds in feeling calming and professional.
*   **Interactivity:** The `CozyButton` provides excellent tactile feel, integrating `CozyHaptics` and `AudioProvider`. However, these are not universally applied to all tappable widgets, resulting in uneven interactive feedback.

## 3. Recommendations (Refine Strategy)

A full redesign would abandon the effective "Cozy Competence" theme. Instead, we propose targeted refinements to elevate the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Isolate the Deep Work Environment**
*   *Issue:* The `RoomWidget` continues to render beneath study sessions, increasing cognitive and computational load.
*   *Solution:* Transition to a minimalist, solid 2D background (`#F4F1ED`) during active study mode.
*   *Rationale:* Reduces distraction during critical learning phases.
*   *Reference:* `WIREFRAMES/quiz_session.svg`

**Medium Priority: Global 2D Quick-Action HUD**
*   *Issue:* Immersive 3D navigation slows down high-yield paths (e.g., jumping straight to the clinic).
*   *Solution:* Implement a persistent bottom or top HUD over the `RoomWidget` for instant access to common destinations.
*   *Rationale:* Provides a reliable escape hatch and fast navigation without breaking immersion.
*   *Reference:* `WIREFRAMES/dashboard.svg`

**Medium Priority: Universal Haptic/Audio Feedback**
*   *Issue:* Inconsistent application of `AudioProvider` and `CozyHaptics` outside of `CozyButton`.
*   *Solution:* Audit and wrap raw `GestureDetector` widgets with standard feedback mixins to ensure a cohesive tactile feel across the app.
*   *Rationale:* Reinforces the polished, responsive nature of the UI.

## 4. Domain Strategy

*   **Current State:** A decoupled architecture with a Flutter client and backend API.
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` for marketing and web app access.
    *   **Subdomain Strategy:**
        *   `app.arbormed.app`: The primary Flutter Web client.
        *   `api.arbormed.app`: The Node.js/PostgreSQL backend services.
        *   `admin.arbormed.app`: Dedicated environment for the `AdminResponsiveShell` to isolate staff operations.

## 5. New Features

1.  **"Focus State" Transition:**
    *   A smooth, automated dimming of the `RoomWidget` that activates a Pomodoro timer during study blocks.
2.  **Interactive "Review" Hub:**
    *   A physical object in the 3D room (e.g., a desk calendar) that opens a specialized review clinic for missed questions, making review feel less like a chore.
3.  **Collaborative Quizzing Spaces:**
    *   Allow users to visit a friend's room and initiate synchronous quiz sessions, building on the existing socket infrastructure.
