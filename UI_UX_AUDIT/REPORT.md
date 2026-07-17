# ArborMed Comprehensive UI/UX Audit & Redesign Strategy

## 1. Executive Summary

ArborMed distinguishes itself by integrating intense board preparation with a "Cozy Competence" gamified experience. While the platform excels in architectural foundations—using Flutter for seamless cross-platform delivery and Drift for local-first robustness—the user interface struggles to separate deep focus from rich gamification.

This audit reveals that while the pastel aesthetic and the core features (like the virtual clinic) are appealing, cognitive overload frequently occurs during critical learning paths. We recommend a substantial refinement approach that simplifies navigation, enforces stricter visual hierarchies during study sessions, and ensures haptic feedback is natively integrated across all interactive components.

## 2. Analysis

### 2.1 Heuristic Evaluation
*   **User Control and Freedom:**
    *   *Positive:* The robust local database (`Drift`) enables instant offline use and syncing.
    *   *Negative:* Users locked into the `QuizSessionScreen` lack an obvious "pause and exit" emergency hatch without losing state.
*   **Flexibility and Efficiency of Use:**
    *   *Negative:* Heavy reliance on `ContextualShopSheet` and `ClinicDirectorySheet` to navigate from the `RoomWidget` creates deep menu trees. There is no flattened "quick access" for power users who just want to resume studying.
*   **Error Prevention and Recovery:**
    *   *Negative:* The `QuizFeedbackOverlay` can sometimes be obscured by gamification animations (like the coin drops), preventing users from reading explanations of their mistakes.

### 2.2 Content and Architecture
*   **Information Architecture:** The transition between "Management Mode" (the Room) and "Focus Mode" (the Quiz) is too fluid. The 3D isometric environment rendered by `RoomWidget` persists behind the `QuizSessionScreen`, which dilutes the focus required for high-yield questions.
*   **Layout Structure:** The bottom navigation paradigm is fragmented across the app. Action overlays rely on floating bubbles instead of a standard bottom app bar, which defies typical mobile app conventions and increases cognitive load.

### 2.3 Visual Design
*   **Typography:** The application brilliantly utilizes Google Fonts (`Figtree` for headers, `Noto Sans` for body). It provides a clean, modern aesthetic.
*   **Color Palette:** The primary sage green (`#8CAA8C`) and warm earth tones perfectly encapsulate the "Cozy" brand.
*   **Micro-interactions:** While custom components like `CozyButton` and `LiquidButton` offer excellent physical feedback via the `PressableMixin`, standard framework widgets (like standard cards and list tiles) feel rigid and unresponsive in comparison.

## 3. Recommendations

We recommend an aggressive refinement strategy to polish the existing implementation without rewriting the core engine.

### 3.1 Prioritized Recommendations

**High Priority: Isolate the Cognitive Load (Quiz Session Redesign)**
*   *Issue:* The 3D room running behind the quiz causes visual distraction and battery drain.
*   *Solution:* Introduce a solid, minimal background for the `QuizSessionScreen`. Pause the `RoomWidget` rendering loop entirely when a quiz starts.
*   *Rationale:* Medical students require extreme focus. The gamification should reward the study session *after* it ends, not distract during it.

**Medium Priority: Unified Bottom Navigation HUD**
*   *Issue:* Finding specific tools (like the network directory or shop) requires hunting around the 3D room.
*   *Solution:* Implement a sleek, semi-transparent 2D bottom navigation bar in the `RoomWidget` that persists across states, giving one-tap access to Quizzes, Shop, and Profile.
*   *Rationale:* Improves navigation speed and aligns with established UX mental models.

**Medium Priority: Universal Tactile Response**
*   *Issue:* Inconsistent haptics break immersion.
*   *Solution:* Extend the `PressableMixin` architecture to all interactive surfaces, ensuring every tap yields a `lightTap()` or `mediumTap()` response.
*   *Rationale:* Consistency in micro-interactions reinforces perceived app quality.

**Low Priority: Contextual Error States**
*   *Issue:* Generic error messages when offline.
*   *Solution:* Create custom illustrations (e.g., a sleeping medical mascot) for offline states or empty shop inventories.

## 4. Domain Strategy

*   **Primary Domain:** `arbormed.app` serves as the perfect top-level domain for the marketing and product landing page.
*   **Subdomain Architecture:**
    *   `app.arbormed.app`: The primary web entry point hosting the Flutter Web build.
    *   `api.arbormed.app`: Dedicated endpoint for the Node.js/PostgreSQL infrastructure.
    *   `admin.arbormed.app`: Isolated administrative portal.

## 5. New Features

1.  **"Flow State" Timer:**
    *   A native Pomodoro widget built into the main dashboard. When active, it triggers a system-wide "Do Not Disturb" aesthetic, dimming the room and prioritizing study queues.
2.  **The "Morbidity & Mortality" Review Board:**
    *   Transform the basic missed-questions list into a dedicated, clickable "Case Review File Cabinet" inside the user's virtual room, gamifying the review process.
3.  **Synchronous Study Lobbies:**
    *   Leverage the existing `socket.io` infrastructure used for duels to create cooperative, real-time study lobbies where friends can answer questions together in a shared virtual room.
