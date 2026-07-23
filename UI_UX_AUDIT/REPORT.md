# ArborMed UI/UX Audit Report

## 1. Executive Summary
ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system (`RoomWidget`).

While the "Cozy Competence" system—featuring muted pastel palettes (e.g., `#8CAA8C`), robust typography (Outfit/Google Fonts), and a local-first architecture (`Drift`)—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:
*   **Visibility of System Status:** Gamification elements like coins (Stethoscopes) update dynamically, but when loading large question banks locally via `Drift`, the `QuizLoadingScreen` lacks sufficient granular progress communication.
*   **Match Between System and Real World:** The terminology matches the medical student reality while keeping it playful, e.g., the "Clinic" naming.
*   **Consistency and Standards:** The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion.
*   **Aesthetic and Minimalist Design:** The isometric room, while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice (`ecg_practice_screen.dart`).

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub. This obscures direct paths to high-yield actions.
*   **Content Organization:** The Quiz interface (`quiz_session_screen.dart`) places the stem in prominent focus, but the answer option hit targets and feedback overlays occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`).

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`) adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.outfit` is modern and readable.
*   **Interactivity:** Although `CozyHaptics` and `AudioProvider` are integrated, their application is inconsistent across standard Flutter widgets.

## 3. Recommendations (Refine Strategy)

The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations
**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Implement a solid, themed background for the Quiz Session. The room should pause or unload when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload during high-stress activities.

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must pan around the 3D room to find specific modules.
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons to major app sections.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` widgets in the app. Ensure any button or card that changes state triggers a tactile response via `CozyHaptics` and `AudioProvider`.
*   *Rationale:* Essential for the tactile feel the brand promises.

**Low Priority: Simplify the Quiz Interface**
*   *Issue:* Visual clutter during the crucial "learning from mistakes" phase in `QuizSessionScreen`.
*   *Solution:* Remove or tone down `CoinParticle` and `ConfettiOverlay` animations if they conflict with feedback overlays.
*   *Rationale:* Reduces distraction.

## 4. Domain Strategy
*   **Current State:** The backend operates as an API, with Flutter handling the client side.
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (or similar) should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here.
        *   `admin.arbormed.com`: Dedicate this subdomain to the administrative portal to keep administrative traffic isolated and secure.

## 5. New Features
1.  **"Zen Mode" Study Timer:** Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Focus Sessions Analytics:** Track when users enter Zen Mode and correlate it with their performance metrics via `Drift` database, providing insights into optimal study conditions.
3.  **Collaborative Study Rooms (Social Extension):** Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing Socket.io infrastructure, but in a cooperative mode.
