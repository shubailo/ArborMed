# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring muted pastel palettes, robust typography (Figtree/Google Fonts), and a local-first architecture—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (Stethoscopes) and streaks update dynamically.
    *   *Negative:* When loading large question banks locally via `Drift`, the `QuizLoadingScreen` lacks sufficient granular progress communication, sometimes appearing frozen.
*   **Match Between System and Real World:**
    *   *Positive:* The "Medical Supply Dispatch Terminal" (Shop) and terminology ("Clinic") cleverly match the medical student reality while keeping it playful.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to Quiz sometimes layers heavy 3D elements behind the quiz, distracting from the cognitive load of studying.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice or Duel Mode.
    *   *Negative:* The login screen (`login.png`) and quiz interface (`quiz.png`) exhibit low contrast ratios between text and background, violating accessibility standards.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session").
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`, warm browns `#D2B48C`, creamy backgrounds `#F4F1ED`) strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` is modern and readable. However, as noted, contrast issues persist.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated, their application is inconsistent across standard Flutter widgets like standard `ListTile` or `GestureDetector` that aren't wrapped in `CozyButton`.
*   **Iconography:** The dashboard relies heavily on icons (e.g., the telephone, the medical bag) which are ambiguous without context or labels.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Enhance Contrast and Accessibility**
*   *Issue:* The low-contrast color palette makes text difficult to read, causing eye strain during long study sessions.
*   *Solution:* Increase the contrast ratio for all text elements in `login.dart`, `quiz_screen.dart`, etc. Use a darker shade for primary text and ensure sufficient contrast for buttons. Implement a "High Contrast Mode" toggle in settings.
*   *Rationale:* Medical students study for long hours. Legibility is paramount to prevent fatigue and ensure comprehension.

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Implement a solid, themed background (e.g., `#F4F1ED` with subtle watermark patterns) for the Quiz Session. The room should pause or unload when entering a deep focus state. Add a prominent "Pause" or "Exit" button to the quiz interface.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions) and provides better user control.
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for the focused layout.

**Medium Priority: Centralized Quick-Action HUD and Labels**
*   *Issue:* Users must pan around the 3D room to find specific modules, and dashboard icons lack context.
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons to major app sections. Add small, subtle text labels beneath icons like the telephone and medical bag.
*   *Rationale:* Balances immersive 3D exploration with practical, intuitive navigation, reducing reliance on recall.
*   *Reference:* See `WIREFRAMES/dashboard.svg` (Top Bar HUD & Side Actions).

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers a `lightTap()` or `mediumTap()` along with the corresponding audio SFX.
*   *Rationale:* Essential for the "Cozy" tactile feel the brand promises.

**Low Priority: Refine "Shop" Empty States**
*   *Issue:* If the shop catalog fails to load (`_buildErrorView`), the error state is generic.
*   *Solution:* Add a themed illustration (e.g., a broken medical supply box) and a more playful copy ("Our supply truck got a flat tire! Re-fetch Storage").
*   *Rationale:* Maintains immersion even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (or similar) should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here.
        *   `admin.arbormed.com`: Dedicate this subdomain to the `AdminResponsiveShell` to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific area of the user's room (e.g., a "Filing Cabinet") where they physically click to review past mistakes.
3.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing Socket.IO duel infrastructure, but in a cooperative mode.
4.  **Detailed Performance Analytics Dashboard:**
    *   Expand the current analytics to provide deeper insights into learning trends, topic mastery over time, and predictive performance for upcoming exams.
