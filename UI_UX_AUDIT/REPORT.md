# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a gamified medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" aesthetic—featuring muted pastel palettes and clean typography (Figtree/Google Fonts)—provides a welcoming atmosphere, the current user interface has significant friction points. The integration of complex interactive layers, such as the persistent 3D isometric room behind quizzes, risks overwhelming the user during high-cognitive-load tasks. Our audit indicates that a refinement strategy focusing on better visual hierarchy, decoupled study modes, and clearer navigation will significantly elevate the platform's educational efficacy.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against its core learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (Stethoscopes) and streak counters update dynamically and provide clear feedback.
    *   *Negative:* Loading large question banks locally lacks granular progress communication, sometimes leaving users unsure if the app is frozen.
*   **Match Between System and Real World:**
    *   *Positive:* The "Medical Supply Dispatch Terminal" (Shop) cleverly matches the medical student reality while maintaining a playful tone.
*   **Consistency and Standards:**
    *   *Negative:* The navigation model mixes contextual modal sheets with full-screen routing in a confusing manner. Transitioning from the Dashboard to the Quiz leaves heavy 3D elements in the background, distracting from the study content.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`) is computationally and visually heavy. Running it beneath intensive tasks like timed quizzes creates visual noise and cognitive overload.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation relies heavily on contextual sheets invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (e.g., "Resume Last Study Session").
*   **Content Organization:** The Quiz interface correctly places the question stem in focus. However, answer options and feedback overlays sometimes overlap with floating decorative particles, creating visual clutter during the crucial review phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`, warm browns `#D2B48C`, creamy backgrounds `#F4F1ED`) strictly adheres to the "Cozy Competence" guidelines. `GoogleFonts.figtree` is modern, readable, and well-utilized.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Audio cues and haptics are inconsistent across standard Flutter widgets.

## 3. Recommendations (Refine Strategy)

A full redesign is unnecessary. The focus should be on refining the existing architecture to prioritize learning outcomes.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   **Issue:** Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise, distracts from learning, and drains battery.
*   **Solution:** Implement a solid, distraction-free themed background (e.g., `#F4F1ED` with subtle watermark patterns) for the Quiz Session. The 3D room should unload when entering a deep focus state.
*   **Rationale:** Reduces cognitive overload during high-stress activities like answering board-style questions.

**Medium Priority: Centralized Quick-Action HUD**
*   **Issue:** Users must pan around the 3D room to find specific modules (Shop, Friends, Settings).
*   **Solution:** Introduce a persistent, collapsible 2D HUD at the bottom of the screen containing quick-access icons to major app sections.
*   **Rationale:** Balances the immersive 3D exploration with the practical need for fast navigation.

**Medium Priority: Standardize Haptic & Audio Feedback**
*   **Issue:** Inconsistent application of haptics and audio cues across interactive elements.
*   **Solution:** Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any interactive element provides consistent tactile (`lightTap()`) and audio (`playSfx('click')`) feedback.
*   **Rationale:** Essential for the "Cozy" tactile feel the brand promises and improves accessibility.

**Low Priority: Improve Error States**
*   **Issue:** The error state in the Shop module is generic.
*   **Solution:** Add a themed illustration (e.g., a broken medical supply box) and playful copy ("Our supply truck got a flat tire! Re-fetch Storage").
*   **Rationale:** Maintains immersion even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here.
        *   `admin.arbormed.com`: Dedicate this subdomain to the admin interface to keep administrative traffic isolated.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific area of the user's room (e.g., a "Filing Cabinet") where they physically click to review past mistakes.
3.  **Collaborative Study Rooms:**
    *   Allow players to invite friends to their custom isometric room for synchronous, cooperative "Flashcard Marathons".
