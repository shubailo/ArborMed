# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring muted pastel palettes, robust typography (Figtree/Google Fonts), and a local-first architecture—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like streaks update dynamically.
    *   *Negative:* When loading large question banks locally, the screen lacks sufficient granular progress communication, sometimes appearing frozen.
*   **Match Between System and Real World:**
    *   *Positive:* The terminology cleverly matches the medical student reality while keeping it playful.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to Quiz sometimes layers heavy 3D elements behind the quiz, distracting from the cognitive load of studying.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room, while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session").
*   **Content Organization:** The `QuizSessionScreen` correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`, `FloatingMedicalIcons`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` and `GoogleFonts.notoSans` is modern and readable.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated in some widgets (like `CozyHubButton` and `PressableAnswerButton` via `PressableMixin`), their application is inconsistent across standard Flutter widgets like standard `ListTile` or `GestureDetector` found in settings (`SettingsSheet`) and profile views that aren't using the mixin.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Ensure the `QuizSessionScreen` has an opaque, solid background rather than a translucent one, and verify the `RoomWidget` pauses its rendering when the quiz is active. Adjust the z-index ordering in `QuizSessionScreen` to ensure `QuizFeedbackOverlay` is not obscured by `ConfettiOverlay` or `FloatingMedicalIcons`.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions).
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for the focused layout.

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must navigate multiple areas of the `RoomWidget` via the `CozyActionsOverlay` which scatters interactive elements across all corners (top-left, bottom-left, bottom-right).
*   *Solution:* Refactor `CozyActionsOverlay` into a persistent, collapsible 2D HUD at the bottom of the screen containing quick-access icons (using `CozyHubButton`) to major app sections, aligned with a top unified status bar.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.
*   *Reference:* See `WIREFRAMES/dashboard.svg` (Top Bar HUD & Side Actions).

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` (like `CozyHaptics.lightTap()`) and audio cues (`AudioProvider.playSfx`) across interactive elements, specifically in UI sheets like `SettingsSheet` and general `GestureDetector` widgets.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers a `lightTap()` or `mediumTap()` along with the corresponding audio SFX, ideally by migrating them to use `PressableMixin` or `CozyButton`.
*   *Rationale:* Essential for the "Cozy" tactile feel the brand promises.

**Low Priority: Refine "Shop" Empty States**
*   *Issue:* If the shop catalog fails to load, the error state is generic.
*   *Solution:* Add a themed illustration and a more playful copy.
*   *Rationale:* Maintains immersion even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** The primary domain should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   Host the Flutter Web build on a subdomain for seamless browser access.
        *   Host the Node.js/PostgreSQL backend on an API subdomain.
        *   Dedicate a subdomain to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific area of the user's room (e.g., a "Filing Cabinet") where they physically click to review past mistakes.
3.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing Socket.IO duel infrastructure, but in a cooperative mode.