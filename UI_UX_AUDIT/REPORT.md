# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a gamified medical education platform designed with a unique "Cozy Competence" aesthetic. The current design successfully employs isometric room elements, soft earthy color palettes, and engaging gamification loops (Study -> Earn -> Customize -> Compete) to alleviate burnout often associated with medical studies.

However, the current UI structure suffers from heavy reliance on modal overlays for core navigation (Profile, Activity, Settings), which disrupts the user flow and increases cognitive load. Additionally, contrast ratios on certain UI elements need improvement for accessibility.

This report provides a comprehensive analysis of the existing UI/UX based on usability heuristics and outlines actionable recommendations, a domain strategy, and new feature proposals to enhance user engagement and accessibility.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the application was evaluated using the provided screenshots (`login.png`, `dashboard.png`, `quiz.png`, `shop.png`, `activity.png`, `settings.png`, `profile.png`).

*   **Visibility of System Status:** Good. The user's current resources (stethoscopes/currency, fire/streaks) are clearly visible at the top of the screen in the dashboard and shop views.
*   **Match Between System and Real World:** Excellent. The use of medical-themed terminology (Ward Rounds, Clinics, Medical ID) and visuals (stethoscopes, lab coats) perfectly aligns with the target audience of medical students.
*   **User Control and Freedom:** Needs Improvement. Currently, core navigation elements like "Profile", "Activity", and "Settings" are hidden behind modal dialogs or scattered icons. Users have to open a modal, interact, and close it to return to the main dashboard.
*   **Consistency and Standards:** Good. The "Cozy Competence" aesthetic is consistently applied across the app with consistent typography, soft rounded corners, and muted color palettes.
*   **Error Prevention:** The quiz interface clearly distinguishes between correct and incorrect answers with immediate visual feedback, preventing confusion.
*   **Recognition Rather Than Recall:** The isometric room acts as a central hub, but navigating to other sections requires recalling which floating icon or gear does what. A more standard navigation paradigm would improve this.
*   **Aesthetic and Minimalist Design:** Excellent. The interface is not cluttered. The soft colors and isometric illustrations create a calming atmosphere.

### 2.2 Content and Architecture
*   **Current State:** The architecture revolves around a central isometric dashboard. Navigation is primarily icon-driven (Settings gear, Profile badge) opening large modal overlays (e.g., Activity modal, Profile modal, Settings modal).
*   **Issue:** Modal-heavy navigation can feel claustrophobic and disrupts the journey. It takes multiple taps to switch context from checking a streak (Profile modal) to starting a session (Main Dashboard) to checking a quest (Activity modal).

### 2.3 Visual Design
*   **Color Palette:** Soft greens, browns, and off-whites. It is very calming and fits the "Arbor" (tree/nature) theme.
*   **Typography:** The rounded, sans-serif font is legible and friendly.
*   **Accessibility (a11y):** Some text elements on light backgrounds (e.g., the light grey axis labels on the Activity trend chart, or white text on light green buttons) may fail WCAG AA contrast ratio requirements.

## 3. Recommendations

### 3.1 Prioritized Recommendations

**High Priority:**
1.  **Replace Modal Navigation with a Persistent Bottom Navigation Bar:**
    *   *Issue:* Overuse of modals for core views (Profile, Activity, Settings).
    *   *Solution:* Implement a standard bottom navigation bar with icons for "Home/Room", "Learn/Quiz", "Shop", and "Profile/Activity".
    *   *Rationale:* This standardizes navigation, reduces the number of taps to switch contexts, and provides immediate visibility of the app's core sections.

2.  **Improve Color Contrast for Accessibility:**
    *   *Issue:* Low contrast on secondary text and disabled buttons.
    *   *Solution:* Darken the placeholder text and axis labels. Ensure all primary buttons have a contrast ratio of at least 4.5:1 against their backgrounds.
    *   *Rationale:* Ensures the app is usable by visually impaired users and complies with standard accessibility guidelines.

**Medium Priority:**
3.  **Consolidate Profile and Activity:**
    *   *Issue:* The screenshots show "Profile" and "Activity" as tabs within the same modal.
    *   *Solution:* In the new Bottom Navigation paradigm, create a unified "Dashboard" or "Profile" screen where the activity chart and user stats (streak, XP) are visible on the same scrollable page without needing tab switches.
    *   *Rationale:* Reduces cognitive load and provides a holistic view of the user's progress.

4.  **Interactive Room Elements:**
    *   *Issue:* The isometric room looks great, but its interactivity is unclear from the static UI.
    *   *Solution:* Allow users to tap on furniture in the room to navigate. E.g., tapping the desk opens the Quiz/Study section, tapping the cabinet opens the Shop/Inventory.
    *   *Rationale:* Enhances the gamified feel and makes the "Cozy Competence" aesthetic functional.

## 4. Domain Strategy

*   **Current State:** Not explicitly defined in screenshots, but assumed to be a web/mobile app.
*   **Recommendation:** Use the primary domain (e.g., `arbormed.com`) as the marketing landing page and blog. Host the actual web application on a subdomain (e.g., `app.arbormed.com` or `learn.arbormed.com`).
*   **Rationale:** This separates marketing concerns (SEO, fast loading static pages) from the heavy application logic, allowing for independent scaling and updates.

## 5. New Features

1.  **"Night Shift" (Dark Mode):**
    *   *Concept:* Given the medical theme, a standard "Dark Mode" should be rebranded as "Night Shift".
    *   *Design:* Replace the off-white backgrounds with deep navy blues or charcoal greys. Adjust the isometric room lighting to look like a cozy night-time study session with warm desk lamp lighting.
    *   *Rationale:* Reduces eye strain during late-night study sessions, a common scenario for medical students. Fits perfectly with the thematic branding.

2.  **Social/Guild System ("Hospitals" or "Study Groups"):**
    *   *Concept:* Allow users to form small groups to contribute to shared goals or compete in the Duel mode.
    *   *Rationale:* Increases retention through social obligation and community building.

3.  **Daily "Triage" Quests:**
    *   *Concept:* Short, time-limited quizzes that appear daily.
    *   *Rationale:* Creates a daily active user (DAU) loop separate from the main study curriculum.
