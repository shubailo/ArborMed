# ArborMed Fresh UI/UX Audit Report

## 1. Executive Summary

ArborMed's unique blend of clinical education and "Cozy Competence" gamification is a standout concept in the ed-tech space. Built with Flutter, it successfully merges an isometric room simulation with rigorous study sessions. However, our comprehensive audit reveals that the current architecture forces users to navigate heavy 3D interfaces to access core educational features. This creates friction, especially for medical students who value efficiency and low cognitive load during intensive study.

Our recommendation is a targeted *refinement* rather than a full redesign. By decoupling the heavy isometric views from high-focus study modes, introducing a streamlined navigation layer, and enriching micro-interactions, ArborMed can deliver a distraction-free, highly engaging learning experience.

## 2. Analysis

### 2.1 Heuristic Evaluation
Evaluating against Nielsen's Usability Heuristics reveals several key findings:

*   **User Control and Freedom:**
    *   *Positive:* The gamified terminology ("Clinic") and the Shop are well-integrated and fun.
    *   *Negative:* Users trapped in the `QuizSessionScreen` must navigate through multiple steps to exit or pause if they trigger it accidentally, lacking a clear "Emergency Exit."
*   **Visibility of System Status:**
    *   *Positive:* Visual indicators for streaks and gamification elements are clear.
    *   *Negative:* Heavy background processes (like loading offline question banks via `Drift`) leave the `QuizLoadingScreen` stagnant without a deterministic progress bar. The `StethoscopePainter` is a nice touch but needs better progress indication.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The `RoomWidget` running behind the `QuizSessionScreen` introduces unnecessary visual and computational overhead. When trying to focus on a question stem, background elements clash with text readability.

### 2.2 Content and Architecture
*   **Information Architecture (IA):** The current IA buries crucial actions. The reliance on `ContextualShopSheet` and `ClinicDirectorySheet` overlays from the 3D hub makes navigation feel fragmented. A user should be able to jump directly from the dashboard to a quiz without traversing the room.
*   **Content Organization:** During quizzes, the layout is functional but becomes cluttered when `QuizFeedbackOverlay`, `ConfettiOverlay`, and `CoinParticle` elements all trigger simultaneously upon answering a question, muddying the "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (e.g. Sage Green `#8CAA8C`) is excellent. However, contrast in some disabled states needs improvement to meet accessibility standards.
*   **Interactivity & Feedback:** The platform has robust tools (`CozyHaptics`, `AudioProvider`), but their implementation is spotty. Not all interactive elements consistently provide the reassuring tactile and auditory feedback essential to the "Cozy" brand.

## 3. Recommendations (Refine Strategy)

A *refinement* strategy will address these friction points while preserving the core aesthetic.

### 3.1 Prioritized Recommendations

**High Priority: Isolate Study Mode from the Isometric Room**
*   *Issue:* Running the 3D `RoomWidget` behind the `QuizSessionScreen` causes cognitive overload and battery drain.
*   *Solution:* Implement a clean, solid background for all quiz sessions. The `RoomWidget` should be paused or removed from the render tree when entering focus modes.
*   *Rationale:* Maximizes concentration and readability during high-stress activities.
*   *Reference:* See `WIREFRAMES/quiz_session.svg`.

**High Priority: Streamlined 2D Navigation Bar**
*   *Issue:* Navigating the app requires panning the 3D room to find specific functional areas.
*   *Solution:* Introduce a persistent 2D bottom navigation bar overlaid on the `RoomWidget`. This HUD should offer one-tap access to the Clinic, Shop, and Study Dashboard.
*   *Rationale:* Provides an immediate, standard escape hatch and quick navigation for power users.
*   *Reference:* See `WIREFRAMES/dashboard.svg`.

**Medium Priority: Unified Feedback System**
*   *Issue:* Inconsistent use of `CozyHaptics` and `AudioProvider`.
*   *Solution:* Standardize the application of `CozyHaptics.lightTap()` and click sounds to all standard Flutter interactive elements.
*   *Rationale:* Ensures the entire app feels responsive and cohesive.

**Low Priority: Playful Error States**
*   *Issue:* The `_buildErrorView` in the shop feels disconnected from the game's lore.
*   *Solution:* Update the generic error icon with a custom illustration (e.g., an overturned Medical Supply Cabinet) and whimsical copy like "The supply truck hit a bump! Tap to re-fetch."
*   *Rationale:* Preserves immersion even when the network fails.

## 4. Domain Strategy

*   **Current State:** A unified Flutter app interacting with a backend API.
*   **Recommendation:** Keep the current structure but refine the domain deployment:
    *   **Primary Landing:** `arbormed.app` for marketing and user acquisition.
    *   **Web App:** `app.arbormed.app` hosting the Flutter Web build.
    *   **API:** `api.arbormed.app` for the Node.js/PostgreSQL backend to ensure clean separation of concerns.
    *   **Admin Dashboard:** `admin.arbormed.app` for secure, isolated content management.

## 5. New Features

1.  **"On-Call" Deep Focus Timer:**
    *   A built-in Pomodoro timer tailored for medical students. Activating it dims the isometric room, mutes non-critical notifications, and plays curated lo-fi study beats.
2.  **Diagnostic History Archive:**
    *   A new interactive object in the `RoomWidget` (like a bookshelf or filing cabinet) where users can physically browse their past mistakes and generated flashcards, turning review into an exploratory activity rather than a chore.
3.  **Study Group Lobbies:**
    *   Expand the social features by allowing users to invite peers into their customized isometric room. From here, they can initiate cooperative study sessions or flashcard duels in real-time.