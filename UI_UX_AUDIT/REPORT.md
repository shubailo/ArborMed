# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring muted pastel palettes (e.g., `#8CAA8C`), robust typography (Figtree/Google Fonts), and a local-first architecture (Drift)—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (stethoscope) and streaks update dynamically.
    *   *Negative:* When loading large question banks locally via `Drift`, the `QuizLoadingScreen` lacks sufficient granular progress communication, sometimes appearing frozen.
*   **Match Between System and Real World:**
    *   *Positive:* The "MEDICAL SUPPLY" (Shop) and terminology cleverly match the medical student reality while keeping it playful.
*   **User Control and Freedom:**
    *   *Negative:* The reliance on deep contextual sheets (`ClinicDirectorySheet`, `ContextualShopSheet`) inside the `RoomWidget` can make it difficult for users to quickly exit back to the main study loop.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to Quiz sometimes layers heavy 3D elements behind the quiz, distracting from the cognitive load of studying.
*   **Error Prevention:**
    *   *Positive:* Gamified mechanics provide clear guardrails, preventing users from making destructive actions without confirmation.
*   **Recognition Rather Than Recall:**
    *   *Negative:* Users are required to remember where specific functions are located within the 3D room, increasing cognitive load.
*   **Flexibility and Efficiency of Use:**
    *   *Negative:* Power users lack quick shortcuts to access their most used features (e.g., jumping straight to "Duel Mode" or specific quizzes) without navigating the 3D room.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice or Duel Mode. The quiz overlays (`QuizFeedbackOverlay`, `ConfettiOverlay`, `CoinParticle`) add to visual clutter.
*   **Help Users Recognize, Diagnose, and Recover from Errors:**
    *   *Negative:* If the shop catalog fails to load (`_buildErrorView`), the error state might not provide actionable steps for recovery beyond just showing an error.
*   **Help and Documentation:**
    *   *Negative:* While the platform is generally intuitive, there is no contextual help available during complex interactions like Duel Mode setup.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session").
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`) strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` is modern and readable.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated, their application is inconsistent across standard Flutter widgets like standard `ListTile` or `GestureDetector` that aren't wrapped in `CozyButton`.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Implement a solid, themed background for the Quiz Session. The room should pause or unload when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions).

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must pan around the 3D room to find specific modules (Shop, Friends, Settings).
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons to major app sections.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers a `lightTap()` along with the corresponding audio SFX.
*   *Rationale:* Essential for the "Cozy" tactile feel the brand promises.

**Low Priority: Refine "Shop" Empty States**
*   *Issue:* If the shop catalog fails to load (`_buildErrorView`), the error state is generic.
*   *Solution:* Add a themed illustration and a more playful copy.
*   *Rationale:* Maintains immersion even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API with a PostgreSQL (`pg`) database, with Flutter handling the client side.
*   **Recommendation:**
    *   **Primary Backend:** The API is currently accessible via `med-buddy-lrri.onrender.com`.
    *   **Admin Access:** Ensure the `AdminResponsiveShell` is securely isolated, potentially on a separate protected route or subdomain.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing `socket_io_client` duel infrastructure, but in a cooperative mode.
