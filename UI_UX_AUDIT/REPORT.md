# ArborMed UI/UX Audit Report

## Executive Summary

ArborMed is a gamified medical education platform aiming to reduce burnout while maintaining clinical rigor through its "Cozy Competence" aesthetics. The app leverages a mobile-first approach using Flutter, accompanied by a Node.js/PostgreSQL backend.

This audit evaluates the ArborMed codebase and available documentation against established UI/UX heuristics. The overarching goal is to enhance user engagement, reduce cognitive load, and align the interface with its cozy, focused design philosophy.

### Key Recommendations
1.  **Refine Navigation & Wayfinding:** Improve bottom navigation bar readability and active state indicators to ensure students always know their context (Home vs. Shop vs. Duel).
2.  **Enhance the "Cozy" Aesthetic Consistency:** Standardize color palettes (sage greens, dusty roses) and typography (rounded sans-serifs) across all screens to reinforce the intended calm atmosphere.
3.  **Optimize the Quiz Interface for Focus:** Streamline the adaptive quiz screen by minimizing extraneous UI elements, allowing the user to focus solely on the medical scenario and answer choices.
4.  **Improve Accessibility:** Ensure adequate contrast ratios, descriptive labels for interactive elements (especially in the Shop and Duel modes), and full screen-reader support.

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:** The app successfully indicates loading states (e.g., `quiz_loading_screen.dart`), but needs consistent feedback when syncing data locally (Drift) to the cloud.
*   **Match Between System and the Real World:** The use of medical metaphors (Stethoscopes as currency, IV Drips for loaders) is excellent and thematic. However, these metaphors must remain intuitive and not obscure functionality.
*   **User Control and Freedom:** The ability to customize the "Room" and toggle between English/Hungarian offers good control. Clear "Back" or "Cancel" options must be prominent during intense tasks like Quiz sessions.
*   **Consistency and Standards:** The "Cozy Competence" design system dictates a specific aesthetic (isometric 3D, muted pastels, rounded typography). A review of screen implementations is needed to ensure strict adherence.
*   **Error Prevention:** The quiz interface must prevent accidental double-taps on answers. Form validations during login/registration need clear, immediate inline feedback.
*   **Recognition Rather Than Recall:** The dashboard should prominently display current streaks, mastery scores, and recommended next steps, reducing the need for the user to remember their progress.

### 2. Content and Architecture

*   **Information Architecture:** The app is logically divided into primary spaces: Dashboard (Home), Study/Quiz, Shop, and Admin (for content creation).
*   **Navigation:** The primary navigation mechanism (likely a bottom navigation bar or sidebar depending on the device) needs to be persistent and clearly labeled.
*   **Onboarding:** The progression from `initial_splash_screen.dart` to `login_screen.dart` and `verification_screen.dart` suggests a standard onboarding flow. It should be augmented with a brief, interactive tutorial introducing the "Cozy Competence" concept and the core loop (Study -> Earn -> Customize).

### 3. Visual Design

*   **Color Palette:** The proposed palette (sage greens, dusty roses, creamy backgrounds, warm browns) is highly effective for reducing eye strain during long study sessions.
*   **Typography:** The use of a rounded sans-serif font (like Figtree) with all-caps, letter-spaced headers contributes to the clean, approachable vibe.
*   **Imagery & Iconography:** Isometric 3D illustrations (as seen in the Room feature) are central to the brand. Iconography should match this style—soft, slightly dimensional, and medically relevant but not sterile.

## Recommendations

### 1. Unified Navigation Strategy (Priority: High)
*   **Issue:** As the app scales (adding Duel Mode, deeper Shop mechanics), navigation can become cluttered.
*   **Solution:** Implement an adaptive navigation shell (using `go_router` or similar). On mobile, use a clean BottomNavigationBar with clear icons and labels. On larger screens (web/tablet), seamlessly transition to a NavigationRail or Sidebar.
*   **Rationale:** Consistency across platforms (mobile, web) reduces user friction.

### 2. "Focus Mode" Quiz Interface (Priority: High)
*   **Issue:** Cognitive load during medical quizzes is high; the UI should not compete for attention.
*   **Solution:** When a quiz starts, animate away non-essential UI elements (like persistent headers or navigation). Use a muted background color and present questions with high-contrast text. Implement subtle haptic feedback for correct/incorrect answers.
*   **Rationale:** Enhances the "Flow" state, a core pillar of the ArborMed philosophy.

### 3. Enhanced "Cozy Room" Interactivity (Priority: Medium)
*   **Issue:** The isometric room is a key gamification feature, but interaction might feel static.
*   **Solution:** Ensure items in the room have subtle idle animations (e.g., a softly glowing lamp, a gently swaying plant). Use the generated voxel hitboxes (`generate_voxel_hitboxes.py`) to provide precise, satisfying touch interactions that trigger tooltips or small animations.
*   **Rationale:** Increases emotional investment in the gamification loop.

### 4. Accessibility and Inclusion Overhaul (Priority: High)
*   **Issue:** Medical students have diverse needs; the app must be accessible.
*   **Solution:**
    *   Conduct a full contrast audit using tools like WCAG Color Contrast Checker.
    *   Ensure all interactive custom widgets (like the custom painters in `widgets/`) have appropriate `Semantics` wrappers.
    *   Provide an option to disable animations for users with vestibular sensitivities.
*   **Rationale:** Compliance with accessibility standards and expanding the usable audience.

## Domain Strategy

*   **Recommendation:** Maintain the main marketing and informational site on the root domain (e.g., `arbormed.com`). Host the web version of the student app on a subdomain (e.g., `app.arbormed.com`) and the admin portal on a separate, secure subdomain (e.g., `admin.arbormed.com`).
*   **Rationale:** This separates marketing concerns (SEO, fast loading static pages) from complex application state and security requirements.

## New Features

1.  **Pomodoro Study Sessions:** Integrate a Pomodoro timer directly into the Dashboard. Completing a Pomodoro cycle could grant a small XP or Stethoscope bonus, encouraging healthy study habits.
2.  **"Daily Rounds" Mini-Game:** A quick, 5-question daily challenge with a unique visual theme (e.g., a specific "ward" in the hospital) that offers higher rewards for maintaining a daily streak.
3.  **Collaborative Study Rooms:** Allow users to invite friends to their "Room" and participate in synchronized flashcard sessions, fostering community.
