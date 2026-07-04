# ArborMed UI/UX Audit Report

## 1. Executive Summary
ArborMed is a highly interactive, medical education platform that creatively combines clinical rigor with a "Cozy Competence" aesthetic. Built primarily with Flutter for cross-platform delivery, its core feature set includes adaptive learning, deep gamification, and an immersive isometric room environment.

While the fundamental concept is strong, the UI/UX audit reveals friction points stemming from the dual goals of a gaming environment and a rigorous study tool. Our primary recommendation is to refine the focus states by decoupling intensive learning sessions from the demanding visual and computational load of the 3D isometric room. Streamlining micro-interactions and creating a clearer information architecture will significantly elevate the overall usability of the application.

## 2. Analysis

### 2.1 Heuristic Evaluation
Evaluated against Nielsen's 10 Usability Heuristics:
*   **Visibility of System Status:**
    *   *Strengths:* Gamification metrics (Stethoscopes as coins, current streaks) are dynamically updated and visible in the `CozyActionsOverlay` HUD.
    *   *Weaknesses:* Loading states, particularly when loading local Drift database queries, lack precise progress indicators, occasionally making the UI feel frozen.
*   **Match Between System and Real World:**
    *   *Strengths:* Medical terminologies like "Clinic" and "Medical Supply Dispatch" contextually ground the user in a familiar domain.
*   **User Control and Freedom:**
    *   *Weaknesses:* Navigation out of deep contextual sheets back to the main study area requires multiple taps. A "quick exit" or persistent back functionality is needed.
*   **Consistency and Standards:**
    *   *Weaknesses:* The UI inconsistently mixes full-screen routes and overlay modal interactions. The transition from the 3D hub to the 2D quiz can be jarring and breaks the mental model.
*   **Aesthetic and Minimalist Design:**
    *   *Weaknesses:* The isometric room in `room_screen.dart` renders a massive `InteractiveViewer`. If not decoupled properly, it adds unnecessary cognitive and computational load when rendering behind the core quiz module.

### 2.2 Content and Architecture
*   **Information Architecture:** The app leans heavily on the 3D space (`room_screen.dart`) as the primary hub, invoking secondary functions (Shop, Directory) via contextual sheets. This buries direct, high-frequency actions like "Start Quiz" or "Review Mistakes".
*   **Content Organization:** Inside the `QuizSessionScreen`, the stem is appropriately emphasized. However, hit targets for multiple-choice questions occasionally lack sufficient contrast against the background, and feedback overlays sometimes clash with decorative particles.

### 2.3 Visual Design
*   **Visual Aesthetics & Layout:** The "Cozy Competence" theme successfully leverages pastel colors (`#8CAA8C`, `#C48B76`, `#FDFCF8`) and the `Figtree` font to reduce visual stress, as confirmed in `light_palette.dart` and `StartSessionHero`.
*   **Tactile and Audio Feedback:** While `CozyHaptics` and `AudioProvider` exist, they aren't uniformly applied. Standard Flutter interactive elements (e.g., basic `ListTile`) lack these haptic reinforcements unless explicitly wrapped in custom components. `SettingsSheet` relies on explicit `playSfx('click')`.

## 3. Recommendations

### 3.1 Refine Strategy vs. Full Redesign
A full redesign is not warranted as the core aesthetic ("Cozy Competence") is unique and appealing. The strategy should focus on refining the architecture to prioritize the study loop.

### 3.2 Detailed Recommendations

**1. Decouple Study Mode from the Isometric Room (High Priority)**
*   **Description:** The 3D isometric room renders behind the active quiz session, increasing cognitive load and device battery drain.
*   **Proposed Solution:** Introduce a solid, minimal background (`#FDFCF8` with faint watermark) during `QuizSessionScreen`. Pause or completely unmount the `CozyRoomRenderer` during deep focus states.
*   **Rationale:** Medical board questions require intense concentration. Reducing visual noise will decrease cognitive fatigue. (Refer to `WIREFRAMES/quiz_session.svg`).

**2. Introduce a Persistent Navigation HUD (Medium Priority)**
*   **Description:** Navigating from the hub requires panning the isometric room to find specific functional areas (e.g., settings, friends).
*   **Proposed Solution:** Enhance the `CozyActionsOverlay` by implementing a fixed, collapsible 2D bottom or side navigation bar (HUD) providing direct access to the Quiz, Shop, Profile, and Settings, rather than relying on floating 3D buttons.
*   **Rationale:** A consistent HUD guarantees O(1) navigation to critical app functions without breaking immersion. (Refer to `WIREFRAMES/dashboard.svg`).

**3. Standardize Haptic & Audio Feedback (Medium Priority)**
*   **Description:** Inconsistent micro-interactions across the application.
*   **Proposed Solution:** Audit all `GestureDetector` and `InkWell` usages. Standardize feedback by invoking `CozyHaptics.lightTap()` and `AudioProvider` sounds on all primary and secondary buttons, similar to what is done in `CozyHubButton`.
*   **Rationale:** Uniform tactile and auditory responses are critical to maintaining the "Cozy" brand feel and reassuring users that their input was registered.

**4. Enhance Loading and Error States (Low Priority)**
*   **Description:** Empty states in the Shop and Drift database loading states lack personality and clarity.
*   **Proposed Solution:** Add playful, medical-themed empty state illustrations (e.g., "Supply truck delayed") and implement granular loading bars for database initialization.
*   **Rationale:** Keeps the user engaged and informed during system delays or failures.

## 4. Domain Strategy
*   **Current State:** API-first with a Flutter cross-platform client.
*   **Recommendation:**
    *   **Main Domain:** `arbormed.app` serves as the primary marketing site and portal.
    *   **Subdomains:**
        *   `app.arbormed.com`: Web application hosting for the Flutter Web build.
        *   `api.arbormed.com`: Backend routing (Node.js/PostgreSQL).
        *   `admin.arbormed.com`: Isolated domain for the administrative dashboard.

## 5. New Features
1.  **"On-Call" Zen Mode:** A dedicated study timer that temporarily disables gamified notifications, dims the room lighting, and plays lo-fi focus tracks.
2.  **Interactive "Filing Cabinet" Review:** Spatialize the review process by dedicating an interactive object in the isometric room where users physically "retrieve" past mistakes.
3.  **Collaborative Co-Op Study:** Extend the Socket.IO Duel Mode architecture to allow cooperative "Flashcard Marathons" in a shared isometric space.
