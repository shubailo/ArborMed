# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform combining clinical rigor with deep gamification. Built locally with Flutter, the app employs an interactive isometric room to maintain a "Cozy Competence" atmosphere.

While the current implementation—featuring a robust offline `Drift` database, real-time `Socket.IO` duels, and pastel green highlights (`#8CAA8C`)—creates a strong foundation, the core study loops are occasionally overshadowed by heavy UI layers. Our audit suggests a *refinement* strategy focused on simplifying contextual navigation, isolating study modes from the `RoomWidget`, and providing clearer feedback during loading and error states to improve cognitive focus.

## 2. Analysis

### 2.1 Heuristic Evaluation
Using Nielsen's Usability Heuristics, we assessed core user flows:

*   **Visibility of System Status:**
    *   *Positive:* Stethoscopes and progress metrics update dynamically.
    *   *Negative:* When loading heavy datasets via `Drift`, the `QuizLoadingScreen` provides limited visual feedback, risking user abandonment.
*   **Consistency and Standards:**
    *   *Negative:* The navigation model mixes modal sheets (like `ContextualShopSheet` and `ClinicDirectorySheet`) with full-screen transitions. Invoking these over the 3D `RoomWidget` creates cognitive friction compared to standard tab-based navigation.
*   **User Control and Freedom:**
    *   *Negative:* Complex feedback overlays, such as `QuizFeedbackOverlay`, overlap with playful elements like `ConfettiOverlay` and `CoinParticle`, making it difficult to clearly read the answer stem when reviewing missed questions.

### 2.2 Content and Architecture
*   **Information Architecture:** The primary hub heavily relies on interacting with 3D elements in the `RoomWidget`. Important actions require excessive tapping through sheets rather than persistent top-level navigation.
*   **Content Organization:** The hierarchy of the "Medical Supply Shop" works well for gamification, but error states (like `_buildErrorView` when the shop fails to load) lack sufficient contextual help or recovery actions.

### 2.3 Visual Design
*   **Color & Typography:** The typography (using `GoogleFonts.figtree`) is highly readable and scalable for accessibility. The primary sage green (`#8CAA8C`) aligns perfectly with a calming, medical aesthetic.
*   **Interactivity:** The integration of tactile and auditory feedback (`CozyHaptics` and `AudioProvider`) is solid, but inconsistent. It's properly applied to `CozyButton`, but missing from some basic list tiles and gesture detectors.

## 3. Recommendations (Refine Strategy)

A full redesign is not required. Instead, we recommend a *refinement* strategy that addresses visual noise and navigational friction.

### 3.1 Prioritized Recommendations

**High Priority: Isolate Quiz Sessions from the Isometric Room**
*   *Issue:* The 3D `RoomWidget` creates unnecessary visual and processing load when layered under the intensive `QuizSessionScreen`.
*   *Solution:* Transition the Quiz Session to a clean, 2D focused layout, pausing the isometric engine entirely.
*   *Rationale:* Reduces cognitive overload and battery drain during core learning tasks.
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for a focused layout.

**Medium Priority: Unified Top-Level Navigation HUD**
*   *Issue:* Relying on the `RoomWidget` for primary routing obscures quick actions.
*   *Solution:* Implement a floating, 2D HUD overlay that remains persistent at the bottom of the screen, providing one-tap access to the Shop, Clinic Directory, and Settings.
*   *Rationale:* Bridges the gap between an immersive gamified experience and standard app usability.
*   *Reference:* See `WIREFRAMES/dashboard.svg` for HUD integration.

**Medium Priority: Standardize Haptics**
*   *Issue:* Inconsistent tactile feedback outside of `CozyButton`.
*   *Solution:* Create a global mixin for interactive elements that automatically triggers `CozyHaptics` and `AudioProvider` cues on tap.
*   *Rationale:* Reinforces the tactile, high-fidelity feel of the platform.

**Low Priority: Improve Error States in Shop**
*   *Issue:* The `_buildErrorView` in the Shop is a generic failure state.
*   *Solution:* Replace it with a branded empty state (e.g., an empty supply box illustration) with a clear retry action.
*   *Rationale:* Maintains the "Cozy" immersion even when network requests fail.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (or similar) should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here.
        *   `admin.arbormed.com`: Dedicate this subdomain to the `AdminResponsiveShell` to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Flow State" Mode:** A dedicated, distraction-free study environment that automatically dims the screen, mutes non-critical notifications, and plays built-in lo-fi audio tracks via `AudioProvider`.
2.  **Interactive Study Notebook:** Instead of standard text lists, users unlock a virtual "Notebook" item in the `ContextualShopSheet` that visually curates their hardest topics using `Drift` data.
3.  **Mentorship Duels:** An extension of the `Socket.IO` duel mode allowing higher-level students to challenge lower-level students with a handicap, fostering community teaching rather than just competition.
