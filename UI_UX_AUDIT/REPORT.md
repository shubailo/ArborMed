# ArborMed UI/UX Audit Report

## Executive Summary
This report provides a comprehensive analysis of the User Interface (UI) and User Experience (UX) of ArborMed, a gamified medical education platform. The application effectively combines a "Cozy Competence" isometric aesthetic with high-fidelity Flutter frontend elements. Overall, the app is visually appealing and highly unique in the medical education space, but there are several usability, accessibility, and architectural areas that can be optimized to enhance user retention, comprehension, and engagement.

Key recommendations include improving navigational clarity on the Dashboard, refining the visual hierarchy during Quiz sessions (especially Bloom's taxonomy feedback), and enhancing the accessibility of interactive elements across the platform.

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:**
    *   *Positive:* The Activity and Profile screens provide clear progress trends (e.g., bar charts for activity).
    *   *Area for Improvement:* In the Quiz UI, while the progress bar indicates current session progress, the transition between Bloom's Taxonomy levels (e.g., from 'Remember' to 'Apply') isn't always immediately obvious to the user.
*   **Match Between System and Real World:**
    *   *Positive:* The "Stethoscope" currency and "Cozy Room" items perfectly match the medical student's mental model and the app's thematic branding.
    *   *Area for Improvement:* The shop icons and categories could use clearer labels, as some isometric items might be hard to identify purely by shape at smaller resolutions.
*   **User Control and Freedom:**
    *   *Positive:* The Settings menu provides clear options to toggle notifications, music, sound effects, and sign out.
    *   *Area for Improvement:* During a quiz or study session, the ability to "pause" or "exit" without losing session progress (due to the 20-minute implicit timeout) should be more prominently displayed.
*   **Consistency and Standards:**
    *   *Positive:* The color palette (sage greens, dusty roses, creamy backgrounds, warm browns) and typography (Figtree/rounded sans-serif) are remarkably consistent across all screens.
    *   *Area for Improvement:* The "Start Session" button placement and styling varies slightly between the Dashboard and other primary screens.
*   **Error Prevention:**
    *   *Positive:* Login and Verification screens have clear input fields.
    *   *Area for Improvement:* Ensure that destructive actions (like spending currency in the Shop) have a subtle confirmation step or undo option.

### 2. Content and Architecture

*   **Information Architecture:** The app is divided into logical flows: Study, Shop/Customize, Profile/Activity, and Settings. The bottom navigation (or primary navigation pattern) seems to center around the Dashboard (Cozy Room view).
*   **Navigation:** While the isometric room is engaging, relying purely on interacting with room elements for navigation can be confusing for new users. A persistent bottom navigation bar or clearly labeled side menu for primary destinations (Study, Shop, Profile) would improve learnability.
*   **Content Organization:** The Quiz interface handles complex medical questions well, but long questions or detailed explanations (the "selectionReason" and Bloom mastery data) need careful typographic hierarchy to avoid overwhelming the user.

### 3. Visual Design

*   **Aesthetic:** The "Cozy Competence" isometric 3D illustrations are excellent and set the app apart. The muted pastel palette is calming, which is ideal for a high-stress domain like medical study.
*   **Typography:** The rounded sans-serif typography with all-caps, letter-spaced headers fits the brand well. However, body text in the Quiz section needs to ensure high contrast against the creamy backgrounds for readability.
*   **Accessibility:**
    *   Ensure that text contrast ratios meet WCAG AA standards, particularly for the muted green and brown text on cream backgrounds.
    *   The interactive elements (like the room customization slots) must be easily selectable and provide clear tactile/auditory feedback (leveraging the existing `CozyHaptics` and `AudioProvider`).

## Recommendations

### High Priority: Refine Quiz Interface and Feedback Loop
*   **Issue:** Users may not understand *why* they are seeing a specific question or how it relates to their Bloom's Taxonomy progress.
*   **Solution:** Integrate the `selectionReason` (from the Adaptive SM-2 engine) as a subtle, dismissible tooltip or 'Coach' message before or after the question. Use color-coded indicators for the current Bloom level (e.g., a small tag: "Level: Apply").
*   **Rationale:** Transparency in the pedagogical intelligence builds trust and helps the student understand their learning journey.

### High Priority: Enhance Primary Navigation
*   **Issue:** Navigating away from the Dashboard/Cozy Room to other primary areas (Shop, Profile) might lack immediate affordance if hidden behind icons or room elements.
*   **Solution:** Implement a persistent, labeled bottom navigation bar (Home, Study, Shop, Profile) alongside the isometric room interaction.
*   **Rationale:** Reduces cognitive load for users who want to quickly access a specific feature without deciphering visual metaphors.

### Medium Priority: Shop and Inventory Clarity
*   **Issue:** The "Done Equipping" UI in the Shop/Room view is clear, but browsing items might be difficult on smaller screens due to the isometric perspective.
*   **Solution:** Add a categorized, horizontal scrolling list (e.g., "Posters", "Desks") with clear text labels underneath the 3D item previews in the shop menu.
*   **Rationale:** Improves discoverability of items and encourages engagement with the Stethoscope economy.

### Medium Priority: Accessibility Enhancements
*   **Issue:** Purely visual interactive elements (like items in the room) may lack context for screen readers.
*   **Solution:** Wrap visual interactive widgets (e.g., `InteractiveViewer`, `GestureDetector` without text) in `Semantics(button: true, label: '...')` or `Tooltip(message: '...')` to expose them to assistive technologies and provide visual hints on long-press.
*   **Rationale:** Ensures the app is inclusive and meets standard accessibility guidelines.

### Low Priority: Settings & Audio Ducking
*   **Issue:** The app features background music ("Quiet Ward Rounds") and sound effects, which can clash.
*   **Solution:** Implement audio ducking (lowering music volume during SFX or UI interactions) using `AndroidAudioFocus.gainTransientMayDuck` and `AVAudioSessionOptions.duckOthers`.
*   **Rationale:** Enhances the "Cozy" atmosphere by creating a more polished, professional audio experience.

## Domain Strategy
Given that ArborMed consists of a Flutter-based mobile/web app (`apps/student_app`), a Next.js professor dashboard (`apps/prof-dashboard`), and a Node backend, the recommended domain structure is:
*   **Main Application (Students):** `app.arbormed.com` (or the primary domain if mobile-first, hosted via Flutter Web/App Links).
*   **Professor Dashboard:** `dashboard.arbormed.com` or `faculty.arbormed.com`. Separating this into a subdomain clarifies the distinct user roles and security contexts.
*   **Marketing/Landing Page:** `www.arbormed.com` (to explain the value proposition, SM-2 engine, and gamification to medical institutions and students).

## New Features
*   **Study Streaks and 'Rest Days':** Integrate a streak system that aligns with the "Cozy" aesthetic. Instead of punishing missed days, introduce "Rest Days" (e.g., a sleeping cat in the room) that maintain the streak, promoting healthy study habits and preventing burnout.
*   **Collaborative/Shared Rooms (Social Proof):** Allow students to visit each other's "Cozy Rooms" or view top-ranking students' rooms. This leans into the gamification loop without adding high-stress competition.
*   **Professor-Triggered "Care Packages":** Allow professors via the `prof-dashboard` to send bonus "Stethoscopes" or exclusive room items to students who show great improvement or high Bloom mastery.