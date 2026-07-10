# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system powered by `RoomWidget`.

While the "Cozy Competence" system—featuring muted pastel palettes, robust typography (Figtree/Google Fonts), and a local-first architecture (via `Drift`)—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like streaks update dynamically.
    *   *Negative:* When loading large question banks locally via `Drift`, the `QuizLoadingScreen` lacks sufficient granular progress communication, sometimes appearing frozen. A progressive loading bar or skeleton screen is needed.
*   **Match Between System and Real World:**
    *   *Positive:* The "Shop" and terminology cleverly match the medical student reality while keeping it playful.
*   **User Control and Freedom:**
    *   *Negative:* Users in the middle of a `QuizSessionScreen` lack a clear "Emergency Exit" or pause function that saves their exact state.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions (`ContextualShopSheet`, `ClinicDirectorySheet`) vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to Quiz sometimes layers heavy 3D elements behind the quiz.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice or Duel Mode.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session"). A hybrid approach is necessary.
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage Green `#8CAA8C`, Soft Clay `#C48B76`, Ivory Cream `#FDFCF8`) defined in `light_palette.dart` strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` is modern, readable, and appropriately scaled.
*   **Interactivity & Accessibility:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated via `CozyButton`, their application is inconsistent across standard Flutter widgets. Furthermore, contrast ratios on disabled states need auditing for WCAG AA compliance.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room (Focus Mode)**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise, distracts from learning, and drains device battery.
*   *Solution:* Implement a solid, themed background (e.g., `#FDFCF8` with subtle watermark patterns) for the Quiz Session. The 3D room engine must pause rendering or completely unload when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions).
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for the focused layout proposal.

**High Priority: Centralized Quick-Action Navigation HUD**
*   *Issue:* Users must manually pan around the 3D room to find specific modules, increasing interaction cost for daily tasks.
*   *Solution:* Introduce a persistent, collapsible 2D Navigation HUD at the bottom or side of the `RoomWidget` containing quick-access icons to major app sections.
*   *Rationale:* Balances the immersive 3D exploration with the practical, fast-paced needs of a student checking their daily streak.
*   *Reference:* See `WIREFRAMES/dashboard.svg` for the Top Bar HUD & Side Actions layout.

**Medium Priority: Standardize Haptic & Audio Feedback Ecosystem**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements creates a disjointed experience.
*   *Solution:* Conduct a systematic audit of all `GestureDetector` and `InkWell` widgets. Ensure any button or card that changes state triggers a `CozyHaptics.lightTap()` or `mediumTap()` synced with the corresponding `AudioProvider` SFX.
*   *Rationale:* Essential for grounding the "Cozy" tactile feel the brand promises.

**Low Priority: Refine Empty & Error States**
*   *Issue:* Error states in the shop lack thematic styling.
*   *Solution:* Add a themed illustration and a more playful copy ("Our supply truck got a flat tire! Tap to dispatch a new one.").
*   *Rationale:* Maintains immersion and reduces frustration during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as a Node API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` should serve as the primary marketing site and entry point.
    *   **Subdomain Architecture:**
        *   `app.arbormed.com`: Host the compiled Flutter Web application here for seamless, no-install browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend services.
        *   `admin.arbormed.com`: Dedicate this subdomain exclusively to the `AdminResponsiveShell` to keep administrative and content management traffic isolated and secure.

## 5. New Features

1.  **"Zen Mode" Pomodoro Timer Integration:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim to an evening setting, lo-fi background music begins, and all non-critical notifications are locally muted.
2.  **Interactive "Review Clinic" Physicalization:**
    *   Instead of a standard flat list for reviewing missed questions, populate a specific area of the user's 3D room (e.g., a "Filing Cabinet" or "Desk") where they must physically navigate and tap to review past mistakes, blending spatial memory with factual recall.
3.  **Collaborative Co-op Study Rooms:**
    *   Extend the existing Socket.IO duel infrastructure. Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" in a cooperative mode rather than PvP.
4.  **Desktop Power-User Hotkeys:**
    *   Implement comprehensive keyboard listener support (e.g., spacebar for 'next question', numbers 1-5 for multiple-choice selections, 'H' for hint) to drastically improve efficiency for web and desktop users.