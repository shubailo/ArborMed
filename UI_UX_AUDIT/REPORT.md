# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring muted pastel palettes, robust typography (Figtree/Google Fonts), and a local-first architecture—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

1.  **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (Stethoscopes) and streaks update dynamically, providing clear feedback on user progress.
    *   *Negative:* When loading large question banks locally via `Drift`, the `QuizLoadingScreen` lacks sufficient granular progress communication, sometimes appearing frozen and leaving the user uncertain of the system's state.
2.  **Match Between System and Real World:**
    *   *Positive:* The "Medical Supply Dispatch Terminal" (Shop) and terminology ("Clinic") cleverly match the medical student reality while keeping it playful and approachable.
3.  **User Control and Freedom:**
    *   *Negative:* Users might find it difficult to quickly exit or skip certain animations or transitions within the isometric room, lacking an obvious "emergency exit" to return to a standard learning mode.
4.  **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to Quiz sometimes layers heavy 3D elements behind the quiz, distracting from the cognitive load of studying and violating platform conventions for focused tasks.
5.  **Error Prevention:**
    *   *Positive:* The use of distinct visual cues for different actions helps prevent slips.
    *   *Negative:* The heavy reliance on contextual sheets without clear visual boundaries might lead to accidental dismissals or incorrect selections in dense UI areas.
6.  **Recognition Rather Than Recall:**
    *   *Positive:* The isometric room provides spatial memory cues for accessing different features, aiding recognition.
    *   *Negative:* Key study metrics might be hidden within the `ClinicDirectorySheet` or `RoomWidget` layers, requiring users to recall where to find them rather than having them readily visible.
7.  **Flexibility and Efficiency of Use:**
    *   *Negative:* The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session"), hindering expert users.
8.  **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice or Duel Mode. Furthermore, the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.
9.  **Help Users Recognize, Diagnose, and Recover from Errors:**
    *   *Negative:* If the shop catalog fails to load (`_buildErrorView`), the error state is generic and does not offer clear guidance on how to resolve the issue.
10. **Help and Documentation:**
    *   *Positive:* The onboarding process provides an initial introduction.
    *   *Negative:* In-context help for complex gamification mechanics or specific study modes is lacking, requiring users to figure it out through trial and error.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session"). A flatter hierarchy for core learning tasks is needed.
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus. However, as noted in the heuristic evaluation, the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`, `QuizSessionScreen`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`, warm browns `#D2B48C` (to be updated), creamy backgrounds like Ivory Cream `#FDFCF8` instead of the original `#F4F1ED`) strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` is modern and readable.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated, their application is inconsistent across standard Flutter widgets like standard `ListTile` or `GestureDetector` that aren't wrapped in `CozyButton`.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Implement a solid, themed background (e.g., `#FDFCF8` with subtle watermark patterns) for the Quiz Session. The room should pause or unload when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions).
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for the focused layout.

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must pan around the 3D room to find specific modules (Shop, Friends, Settings).
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons to major app sections.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.
*   *Reference:* See `WIREFRAMES/dashboard.svg` (Top Bar HUD & Side Actions).

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers a `lightTap()` or `mediumTap()` (from `CozyHaptics`) along with the corresponding audio SFX from `AudioProvider` (or by utilizing `CozyButton`).
*   *Rationale:* Essential for the "Cozy" tactile feel the brand promises.

**Low Priority: Refine "Shop" Empty States**
*   *Issue:* If the shop catalog fails to load (`_buildErrorView`), the error state is generic.
*   *Solution:* Add a themed illustration (e.g., a broken medical supply box) and a more playful copy ("Our supply truck got a flat tire! Re-fetch Storage").
*   *Rationale:* Maintains immersion even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.ai` should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.ai`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.ai`: Host the Node.js/PostgreSQL backend here.
        *   `admin.arbormed.ai`: Dedicate this subdomain to the `AdminResponsiveShell` to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
    *   **Implementation Note:** Utilize the existing `AudioProvider` to play continuous lo-fi tracks. Add a timer overlay (e.g., `ZenTimerOverlay`) above the `RoomWidget`, and pause active `Drift` database syncing if it impacts performance.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific area of the user's room (e.g., a "Filing Cabinet") where they physically click to review past mistakes.
    *   **Implementation Note:** This can be implemented by adding a new interactive hitbox (e.g., `ReviewHitbox`) to `CozyRoomRenderer`. When tapped ( triggering `mediumTap()` via `CozyHaptics`), it opens a new `ContextualReviewSheet` pulling data from the missed questions `Drift` table.
3.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing Socket.IO duel infrastructure, but in a cooperative mode.
    *   **Implementation Note:** Leverage the current `Socket.IO` setup used for Duel Mode. We'll need a new `Co-op Lobbies` endpoint in the `PostgreSQL` backend to pair users without the wager system.
