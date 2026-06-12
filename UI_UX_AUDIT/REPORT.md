# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring muted pastel palettes, robust typography (Figtree/Google Fonts), and a local-first architecture—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (Stethoscopes) and streaks update dynamically.
*   **Match Between System and Real World:**
    *   *Positive:* The terminology cleverly match the medical student reality while keeping it playful.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation relies on the `RoomWidget` and `CozyActionsOverlay`. While immersive, it obscures direct paths to high-yield actions.
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`, warm browns `#D2B48C`, creamy backgrounds `#F4F1ED`) strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` is modern and readable.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `AudioProvider` is integrated, its application is inconsistent across standard Flutter widgets like standard `ListTile` or `GestureDetector` that aren't wrapped in `CozyButton` or `CozyHubButton`.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Implement a solid, themed background (e.g., `#F4F1ED` with subtle watermark patterns) for the Quiz Session. The room should pause or unload when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions).

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must pan around the 3D room to find specific modules. The current HUD (`CozyActionsOverlay`) scatters actions on the bottom left and bottom right corners.
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons (using components like `CozyHubButton`) to major app sections, grouping the `network`, `profile`, `equip`, and `settings` around the central `StartSessionHero`.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.

**Medium Priority: Standardize Audio Feedback**
*   *Issue:* Inconsistent application of audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers an audio SFX, similarly to how `CozyHubButton` does.
*   *Rationale:* Essential for the "Cozy" tactile feel the brand promises.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (or similar) should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific area of the user's room (e.g., a "Filing Cabinet") where they physically click to review past mistakes.
3.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing Socket.IO duel infrastructure, but in a cooperative mode.
