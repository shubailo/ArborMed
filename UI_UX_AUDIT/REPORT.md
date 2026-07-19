# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification (e.g., earning "Stethoscopes"), and an interactive isometric "Room" system via the `RoomWidget`.

While the "Cozy Competence" system—featuring muted pastel palettes (Sage greens `#8CAA8C`), robust typography (`GoogleFonts.figtree`), and a local-first architecture using `Drift`—provides an excellent base, the current user interface presents friction points. Complex interactive layers, such as the persistent isometric room rendering behind `QuizSessionScreen` and `ContextualShopSheet`, risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (`Stethoscopes`) and streaks update dynamically and clearly.
    *   *Negative:* When loading large question banks locally via `Drift`, the loading screens lack sufficient granular progress communication, sometimes appearing frozen and leaving users in doubt.
*   **Match Between System and Real World:**
    *   *Positive:* The "Shop" and terminology like "Clinic" clearly and cleverly match the medical student reality while keeping it playful and engaging.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to `QuizSessionScreen` sometimes layers heavy 3D elements behind the quiz, distracting from the cognitive load of studying.
*   **User Control and Freedom:**
    *   *Negative:* When users open the `ClinicDirectorySheet`, they lack a clear "Quick Exit" to return immediately to their last study state, often requiring multiple taps to dismiss nested sheets.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice or Duel Mode.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session"). Users must pan around to find the right entry points.
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays occasionally overlap with floating decorative particles. This creates visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette strictly adheres to the "Cozy Competence" guidelines, heavily featuring `#8CAA8C`. However, text contrast within cards using these background colors sometimes falls below WCAG 2.1 AA standards. The use of `GoogleFonts.figtree` is modern, highly legible, and fits the medical context well.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated, their application is inconsistent across standard Flutter widgets. While `CozyButton` properly fires haptics and audio, standard `ListTile` or `GestureDetector` elements that aren't wrapped in a `CozyButton` often provide no feedback, breaking immersion.

## 3. Recommendations (Refine Strategy)

Given the strong foundation of ArborMed, a full redesign is unnecessary. The focus should be on *refining* the existing architecture, optimizing performance, and standardizing components.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains device battery rapidly.
*   *Solution:* Implement a solid, themed background for the Quiz Session. The room renderer should be paused or entirely unloaded when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload and physical device strain during high-stress activities (answering board-style questions).
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for the focused layout.

**High Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must physically pan around the 3D room to find specific modules (Shop, Friends, Settings), increasing interaction cost.
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons to major app sections.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.
*   *Reference:* See `WIREFRAMES/dashboard.svg` (Top Bar HUD & Side Actions).

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers a `CozyHaptics.lightTap()` or `CozyHaptics.mediumTap()` along with the corresponding audio SFX from `AudioProvider`. Consider migrating raw `GestureDetector` widgets to `CozyButton`.
*   *Rationale:* Essential for maintaining the "Cozy" tactile feel the brand promises.

**Low Priority: Refine "Shop" Empty States**
*   *Issue:* If the shop catalog fails to load (`_buildErrorView`), the error state is generic and breaks immersion.
*   *Solution:* Add a themed illustration (e.g., a broken medical supply box) and a more playful copy ("Our supply truck got a flat tire! Re-fetch Storage").
*   *Rationale:* Maintains immersion and a polished feel even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as a Node.js API with a PostgreSQL database, while Flutter handles the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (or similar) should serve as the primary marketing site and entry point.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here to cleanly separate client and server infrastructure.
        *   `admin.arbormed.com`: Dedicate this subdomain to the `AdminResponsiveShell` to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts via `AudioProvider`, and notifications are muted to encourage deep focus.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific interactive area of the user's room (e.g., a "Filing Cabinet" item) where they physically tap to review past mistakes, seamlessly integrated with the `Drift` local database for instant loading.
3.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing `Socket.IO` duel infrastructure, but configured for a cooperative mode rather than PvP.
4.  **Daily Challenge Widget:**
    *   Implement a quick-start "Daily Challenge" button inside the `Clinic` that bypasses standard category selection and jumps straight into a curated 10-question set based on the adaptive learning algorithm, rewarding bonus `Stethoscopes`.
