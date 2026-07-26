# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring robust typography (`Figtree` and `notoSans` via Google Fonts), and a local-first architecture (`Drift`)—provides an excellent base, the current user interface presents friction points. Complex interactive layers risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy focusing on clarity of state, explicit user controls, and advanced study features will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (`Stethoscope`) update dynamically.
    *   *Negative:* When loading large question banks locally, the `QuizLoadingScreen` lacks sufficient granular progress communication, sometimes appearing frozen.
*   **User Control and Freedom:**
    *   *Negative:* There is no explicit "undo" action for accidental purchases of items like the `Medical Supply Cabinet` or for mistakenly initiating a study session.
*   **Match Between System and Real World:**
    *   *Positive:* The `DISPATCH TERMINAL` terminology cleverly matches the medical student reality while keeping it playful.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks.

### 2.2 Content and Architecture
*   **Information Architecture:** Navigation relies heavily on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from the 3D hub. This obscures direct paths to high-yield actions like resuming the last study session.
*   **Content Organization:** The Quiz interface places the question stem in focus, but gamification elements can sometimes clash during review.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette strictly adheres to the "Cozy Competence" guidelines (e.g., primary `Color(0xFF8CAA8C)`). The use of `GoogleFonts.figtree` for headers is modern and readable.
*   **Interactivity:** Interactive elements occasionally lack tactile feedback. Although `CozyHaptics` and `lightTap()` are available, their application across `GestureDetector` widgets is inconsistent.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture and expanding feature sets.

### 3.1 Prioritized Recommendations

**High Priority: Dynamic Environment Lighting for `RoomWidget`**
*   *Issue:* The isometric room does not reflect real-world time or user context, feeling static during extended study sessions.
*   *Solution:* Implement dynamic lighting that transitions to warmer tones based on the user's local time, enhancing the "Cozy Competence" feel.
*   *Rationale:* Reduces eye strain during late-night study sessions and strengthens the immersive environment.

**Medium Priority: Shop Purchase "Undo" Grace Period**
*   *Issue:* Accidental clicks in the `ContextualShopSheet` immediately deduct Stethoscopes.
*   *Solution:* Implement a 5-second "Undo" snackbar after a purchase before finalizing the transaction in the database.
*   *Rationale:* Supports the "Error Prevention" usability heuristic and reduces user frustration.

**Medium Priority: Enhanced Wait State Visibility**
*   *Issue:* Users are uncertain of system status during loading screens.
*   *Solution:* Add a pulsing "Preparing materials..." indicator in `QuizLoadingScreen` with an explicit cancellation option.
*   *Rationale:* Improves visibility of system status and user control.

**Low Priority: Contextual Feedback Dimming**
*   *Issue:* Gamified particles can be visually cluttered.
*   *Solution:* Automatically dim or pause particle effects (confetti/coins) when reading detailed explanations.
*   *Rationale:* Focuses user attention on the educational content during review.

## 4. Domain Strategy

*   **Current State:** The platform operates with Flutter handling the client side.
*   **Recommendation:**
    *   Keep the marketing and app routing cohesive. A future deployment should consider specific routing for the admin portal to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Daily Rounds" Mini-Games:**
    *   Short, daily diagnostic challenges (e.g., identifying a murmur from an audio snippet) that reward extra `Stethoscope` coins and keep engagement high without the commitment of a full quiz block.
2.  **Customizable Avatar Companions:**
    *   Alongside room decorations, users could unlock "pet" companions (e.g., a "Study Buddy" owl) that provide subtle visual encouragement and idle animations within `room_screen.dart`.
3.  **Progress Heatmap:**
    *   A GitHub-style contribution graph in the `ClinicDirectorySheet` or Profile area showing study activity over the past year, encouraging daily streaks visually.
