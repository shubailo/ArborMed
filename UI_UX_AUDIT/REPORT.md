# ArborMed UI/UX Audit Report

## 1. Executive Summary

This report provides a comprehensive UI/UX analysis of **ArborMed**, a gamified medical education platform. The application effectively implements its "Cozy Competence" design philosophy, utilizing a soft, isometric aesthetic to reduce student burnout while maintaining clinical rigor. The overall user interface is intuitive, aesthetically pleasing, and highly consistent. However, there are notable areas for improvement regarding accessibility (specifically color contrast), visual hierarchy of destructive actions, and user feedback mechanisms.

By addressing these usability and accessibility heuristics, ArborMed can further elevate its user experience, ensuring that learning remains the primary focus without unnecessary cognitive load or frustration.

---

## 2. Analysis

### 2.1 Initial Assessment
ArborMed features a robust UI built with Flutter, heavily relying on custom styling, rounded corners, soft shadows, and an earthy/pastel color palette (greens, browns, creams). The system effectively gamifies the learning experience using an interactive isometric "clinic" and detailed progression tracking.

### 2.2 Heuristic Evaluation (Nielsen's 10 Usability Heuristics)
*   **Visibility of System Status:** Generally good. Modals clearly indicate the user's current context (e.g., Settings, Activity). However, the Activity chart lacks sufficient visual distinction to clearly communicate data at a glance.
*   **Match Between System and Real World:** Excellent. The terminology ("Ward Rounds", "Clinic") and visual metaphors (isometric medical furniture) align perfectly with the target audience of medical students.
*   **User Control and Freedom:** Good. The Verification screen provides a "Change Email / Edit Details" escape hatch. Settings provide granular control over the environment (Music vs. SFX).
*   **Consistency and Standards:** High. The app consistently uses its custom typography, rounded button shapes, and thematic colors across all screens (Login, Settings, Activity, Shop).
*   **Error Prevention:** The Verification input field restricts and displays the character count (`0/6`), guiding the user before submission.

### 2.3 Content and Architecture
The navigation relies heavily on modular overlays and bottom sheet modals (e.g., Settings and Activity popping up over the main dashboard). This keeps the user anchored in their "virtual clinic" environment without feeling lost in deep navigation trees.

### 2.4 Visual Design
The "Cozy" aesthetic is well-executed.
*   **Typography:** Playful yet legible, fitting the gamified nature.
*   **Color Palette:** Soft greens, creams, and earthy browns reduce eye strain, which is crucial for long study sessions.
*   **Imagery:** The isometric 3D art (as seen in the Shop/Clinic view) is high quality and creates a relaxing atmosphere.

### 2.5 Specific Use Cases
*   **Verification (`verification.png`):** Clean layout. The email icon is clear. Secondary actions ("Resend Code", "Change Email") are appropriately de-emphasized as text links.
*   **Settings (`settings.png`):** Well-organized with clear toggle switches and a slider for volume. The music track selection is a delightful touch.
*   **Activity (`activity.png`):** Segmented controls (Day/Week/Month/Quests) are intuitive. However, the data visualization fails accessibility standards.
*   **Shop/Clinic (`shop.png`):** The isometric view is engaging. The "DONE EQUIPPING" button is clear and anchors the screen well.

---

## 3. Actionable Recommendations

### Recommendation 1: Improve Data Visualization Contrast
*   **Issue:** In the Activity trend chart (`activity.png`), the inactive/empty bar placeholders (representing 0 or future days) are a very faint off-white against a cream background. This fails WCAG contrast guidelines and is difficult to see.
*   **Solution:** Darken the placeholder bars slightly (e.g., a soft beige or light brown) to ensure they are discernible. Ensure the active data points (currently red) maintain a high contrast ratio against the background.
*   **Rationale:** Users must be able to parse their progress instantly without squinting or struggling to differentiate UI elements from the background.

### Recommendation 2: Adjust Visual Hierarchy of Destructive Actions
*   **Issue:** In the Settings modal (`settings.png`), the "SIGN OUT" button is styled as a massive, solid, brightly colored block. It draws the most visual attention on the screen.
*   **Solution:** Demote the "SIGN OUT" button to a secondary or tertiary button style (e.g., an outlined button or a simple bold text link in a muted red/brown).
*   **Rationale:** Primary solid buttons should be reserved for the most frequent or desired actions. Logging out is a destructive/terminal action that should be accessible but not visually dominant, preventing accidental clicks.

### Recommendation 3: Implement Clear Disabled States
*   **Issue:** On the Verification screen (`verification.png`), the "Verify & Continue" button appears fully active even when the input shows `0/6` characters entered.
*   **Solution:** Visually dim or gray out the button (and disable its interaction) until the user has entered a valid 6-digit code.
*   **Rationale:** Prevents premature submissions, reduces server-side error handling, and provides immediate visual feedback to the user about what is required to proceed.

### Recommendation 4: Enhance Accessibility for Interactive Elements
*   **Issue:** The isometric Shop/Clinic view and other gamified screens rely heavily on visual exploration without explicit text labels.
*   **Solution:** Ensure all interactive isometric objects (bed, cabinet, computer) and background watermark icons have semantic labels and `Tooltip` wrappers implemented in Flutter for screen readers.
*   **Rationale:** Accessibility is crucial in educational software to ensure no student is left behind due to visual or motor impairments.

---

## 4. Domain Strategy

Given the monorepo structure containing both `student_app` (Flutter) and `prof-dashboard` (Next.js), a subdomain strategy is highly recommended:
*   **`arbormed.com`**: The main landing page/marketing site detailing the pedagogy, features, and pricing.
*   **`app.arbormed.com`**: The web-hosted version of the Flutter student application (if Web is supported), or redirecting to mobile app store links.
*   **`dashboard.arbormed.com`**: The Next.js Professor/Admin dashboard for analytics, curriculum management, and institutional oversight.
*   **Rationale:** This cleanly separates the marketing funnel, the student experience, and the administrative tools, allowing for independent scaling, authentication scopes, and targeted updates.

---

## 5. New Features

### 5.1 "Pomodoro" Focus Sessions
*   **Concept:** Leverage the existing "Quiet Ward Rounds" ambient music tracks by adding a built-in Focus Timer (e.g., 25 minutes study, 5 minutes rest).
*   **UX Implementation:** A small floating widget in the Clinic view that expands into a timer, suppressing non-critical notifications while active.

### 5.2 Interactive Clinic Trivia
*   **Concept:** Allow users to tap on objects in their customized clinic (e.g., the anatomy poster, the examination bed) in the isometric view.
*   **UX Implementation:** Tapping triggers a quick, low-stakes "Trivia of the Day" related to that object, rewarding the user with a small amount of in-game currency. This makes the cosmetic items feel alive and educational.

### 5.3 Social Learning & Duels Leaderboard
*   **Concept:** Since the app features real-time PvP duels, exposing social competition can drive engagement.
*   **UX Implementation:** Add a "Social" or "Leaderboard" tab in the Activity modal, allowing students to see their friends' study streaks or duel rankings, leaning into the "Competence" aspect of the app's philosophy.
