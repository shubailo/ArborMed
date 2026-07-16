# ArborMed UI/UX Audit & Enhancement Report

## 1. Executive Summary

ArborMed is a highly specialized medical education platform successfully bridging the gap between rigorous clinical material and a low-stress "Cozy Competence" aesthetic. Built on a robust Flutter frontend with local-first `Drift` persistence, it features study modules integrated with an interactive isometric room (`RoomWidget`).

While the foundational aesthetic—characterized by pastel palettes and `Figtree` typography—is well-executed, our audit identifies significant opportunities to optimize the core learning loop. The primary friction stems from cognitive overload: complex 3D environments run concurrently with high-stakes study tasks (e.g., `QuizSessionScreen`).

Our strategy focuses on **refinement and focus-enhancement**. By decoupling the immersive room from active study sessions, standardizing tactile feedback (via `CozyHaptics`), and streamlining navigation, we can dramatically improve usability and information retention without sacrificing the app's unique charm.

## 2. Analysis

### 2.1 Heuristic Evaluation
Evaluated against Nielsen's 10 Usability Heuristics:

*   **Visibility of System Status:**
    *   *Strengths:* Dynamic gamification (e.g., Stethoscope coins, streak counters) provide immediate positive reinforcement.
    *   *Weaknesses:* Local database loading via `Drift` on the `QuizLoadingScreen` lacks progressive feedback, occasionally leaving the user uncertain of system state during large bank fetches.
*   **Match Between System and Real World:**
    *   *Strengths:* Terminology like "Clinic" and the "Medical Supply Dispatch Terminal" maintain thematic immersion effectively.
*   **Consistency and Standards:**
    *   *Weaknesses:* Navigation paradigms are mixed. Transitioning between the hub (`RoomWidget`) and focused tasks like quizzes relies on overlays that can trap users or obscure critical pathways. The mixture of bottom sheets (`ContextualShopSheet`, `ClinicDirectorySheet`) and modal routes creates an unpredictable spatial map for the user.
*   **Aesthetic and Minimalist Design:**
    *   *Weaknesses:* The `RoomWidget` (in `room_screen.dart`), while central to the brand, runs constantly. When layered beneath intensive tasks like timed ECG practice, the visual and computational weight detracts from the minimalism required for deep focus.

### 2.2 Content and Architecture
*   **Information Architecture:** The reliance on contextual interactions within a 3D space obscures quick access to primary functions. A user wanting to simply resume studying must often pan or hunt for the correct interactive voxel.
*   **Content Organization:** Within the `QuizSessionScreen`, the question stem is clear, but feedback mechanisms (like `QuizFeedbackOverlay`) often clash visually with reward animations (`ConfettiOverlay`, `CoinParticle`), creating a chaotic screen state exactly when the user needs clear feedback on why an answer was incorrect.

### 2.3 Visual Design
*   **Color & Typography:** The "Cozy Competence" palette (Sage greens `#8CAA8C`, warm browns `#D2B48C`, creamy backgrounds `#F4F1ED`) is excellent. `GoogleFonts.figtree` provides exceptional legibility for dense medical text.
*   **Interactivity:** Haptic and audio feedback is inconsistent. While `CozyHaptics` and `AudioProvider` exist, they are not universally applied to all interactive elements (like generic `ListTile` or `GestureDetector` widgets), breaking the illusion of a tactile, responsive environment.

## 3. Recommendations (Refine Strategy)

A full redesign is not warranted; rather, a targeted refinement of the existing architecture will yield the highest ROI.

### 3.1 Prioritized Recommendations

**High Priority: Isolate the Deep Focus State**
*   *Issue:* The isometric `RoomWidget` running behind the `QuizSessionScreen` increases cognitive load and drains battery during the most critical phase of the app's use.
*   *Solution:* Implement a solid, distraction-free themed background (e.g., `#F4F1ED` with a subtle, static watermark) for all active study sessions. The 3D room state should be paused and hidden.
*   *Rationale:* Medical study requires intense focus. Gamification should bookend the study session, not compete with it.
*   *Reference:* See existing `WIREFRAMES/quiz_session.svg` for the intended layout.

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Finding specific modules (Shop, Friends, Settings) within the 3D space is slow.
*   *Solution:* Introduce a persistent, collapsible 2D bottom navigation HUD overlaid on the `RoomWidget`. This HUD should contain universally recognizable icons for core app sections.
*   *Rationale:* Balances the joy of 3D exploration with the practical need for immediate, predictable navigation.
*   *Reference:* See existing `WIREFRAMES/dashboard.svg`.

**Medium Priority: Universal Tactile Feedback**
*   *Issue:* Inconsistent application of haptics and sound breaks immersion.
*   *Solution:* Conduct a codebase-wide audit of all `GestureDetector` and `InkWell` components. Standardize interactions to trigger `CozyHaptics.lightTap()` or `CozyHaptics.mediumTap()` alongside synchronized audio from the `AudioProvider`.
*   *Rationale:* Consistent micro-interactions are fundamental to the "Cozy" aesthetic.

**Low Priority: Contextual Empty States**
*   *Issue:* Generic error states (e.g., failing to load the shop catalog) pull the user out of the experience.
*   *Solution:* Implement themed empty/error states with custom illustrations (e.g., a delayed medical supply truck) and playful copy.
*   *Rationale:* Turns a negative technical experience into a brand-building moment.

## 4. Domain Strategy

*   **Current State:** The platform utilizes a unified backend API serving a multi-platform Flutter client.
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (for marketing and unified web portal).
    *   **Subdomain Architecture:**
        *   `app.arbormed.app`: Hosts the compiled Flutter Web build for seamless, installation-free browser access.
        *   `api.arbormed.app`: Dedicated endpoint for the Node.js/PostgreSQL backend services.
        *   `admin.arbormed.app`: Hosts the `AdminResponsiveShell` on a segregated subdomain to isolate administrative traffic and enhance security.

## 5. Proposed New Features

1.  **"Zen Mode" Pomodoro Integration:**
    *   Build a Pomodoro-style timer into the Study Dashboard. Activation dynamically dims the isometric room lighting, initiates curated lo-fi background audio, and temporarily suppresses non-critical push notifications.
2.  **Spatial "Review Clinic":**
    *   Instead of a traditional flat list for reviewing missed questions, allocate a specific, interactable object in the user's room (e.g., a "Filing Cabinet"). Clicking this object opens a dedicated review session, making the review process feel tactile and grounded in the user's space.
3.  **Synchronous Collaborative Study (Social Expansion):**
    *   Expand the existing Socket.IO duel infrastructure to support cooperative study. Allow users to invite peers to their customized room for synchronized "Flashcard Marathons" where users tackle a shared deck together.
