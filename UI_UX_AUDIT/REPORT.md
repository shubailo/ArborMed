# 🩺 ArborMed: UI/UX Audit Report

## Executive Summary
This report analyzes the UI/UX of the **ArborMed** platform, focusing on the visual design language, gamified elements, and usability of the mobile Flutter application. ArborMed's core concept blends high-fidelity medical education with a "Cozy Competence" design system. The ecosystem features 3D isometric rooms and adaptive learning mechanics to create a stress-free environment for medical board prep.

Overall, the visual design successfully communicates the brand: calm, professional, and accessible. The pastel color palette, rounded elements, and clear typographic hierarchy establish a relaxing "flow" state.

However, certain areas relating to accessibility, interaction clarity, and navigation can be improved. This audit provides specific, actionable recommendations, balancing aesthetic enhancement with functional utility.

---

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:**
    *   *Positive:* The "Dashboard", "Profile" and "Activity" screens display the current currency (Stethoscopes) and streak (Fire icons) clearly at the top. The Quiz screen clearly shows the level progress bar (e.g. 0/20) and the current topic (e.g. CARDIOVASCULAR SYSTEM).
    *   *Area for Improvement:* In the "Dashboard" isometric room view, it doesn't immediately indicate interactability. Users may not realize they can tap/drag items or how to customize the room.
*   **Match Between System and the Real World:**
    *   *Positive:* The icons match medical/real-world concepts (Stethoscopes for coins, medical bags, clipboards with caduceus, rotary phone).
*   **User Control and Freedom:**
    *   *Positive:* The quiz interface provides clear True/False options and an easy way to exit (the 'X' button in the top right). The profile/activity toggle is a clear, reversible action.
*   **Consistency and Standards:**
    *   *Positive:* The UI adheres closely to the "Cozy Competence" system (pastel greens, creams, warm browns, rounded sans-serif typography). Buttons consistently use the primary sage green (e.g., "Login", "START SESSION", "ACTIVITY").
*   **Error Prevention:**
    *   *Positive:* The login form uses standard clear input fields with placeholder text. The password field includes a visibility toggle to prevent typos.
*   **Aesthetic and Minimalist Design:**
    *   *Positive:* The minimalist approach prevents cognitive overload, critical for a stressful domain like medical study. The login screen and quiz interface are extremely clean and focused. The activity chart is subtle and well-integrated.
*   **Accessibility (WCAG principles):**
    *   *Area for Improvement:* Interactive icon-only buttons (like the gear icon, the medical bag, the clipboard, and the phone on the dashboard) lack visible labels. The contrast ratio on the placeholder text ("Email or Username") and the "Forgot Password?" / "Create One" text may be slightly low against the cream background.

### 2. Content and Architecture

*   **Navigation:** The primary navigation on the dashboard relies on large, scattered icon buttons around the screen. While thematic, it might be less intuitive than a standard navigation bar. The "Profile" and "Activity" screens use a modal/bottom-sheet style overlay over the dashboard, which is a nice contextual pattern.
*   **Information Hierarchy:** The screens prioritize the primary action perfectly. The login screen focuses on the form, the dashboard focuses on the "START SESSION" button and the room, and the quiz screen focuses on the question card. The activity screen uses a clear tab system (DAY, WEEK, MONTH, QUESTS) to organize data.

### 3. Visual Design

*   **Color Palette:** The use of sage greens, dusty roses, creamy backgrounds, and warm browns perfectly encapsulates the "Cozy Competence" vibe. It avoids sterile hospital blues/whites, creating a much more inviting atmosphere.
*   **Typography:** The rounded sans-serif font (likely Figtree or similar) with all-caps, letter-spaced headers (e.g., "CARDIOVASCULAR SYSTEM", "ACTIVITY TREND") is friendly, modern, and highly readable.
*   **Imagery:** The 3D isometric illustration of the room is high quality, consistent with the lighting and perspective, and serves as an excellent anchor for the gamified experience. The 2D icons (bag, phone, etc.) have a charming, slightly hand-drawn or cel-shaded quality that fits the aesthetic.

---

## Recommendations

### 1. Usability & Navigation: Standardized Navigation or Clearer Icons
*   **Issue:** The "Dashboard" uses large, scattered 2D icons (clipboard, phone, bag, gear) for navigation around the 3D room. This might confuse new users about what each icon does before tapping it.
*   **Solution:**
    *   *Option A:* Add subtle, cohesive text labels below each icon (e.g., "Profile", "Records", "Shop", "Settings").
    *   *Option B:* Transition to a minimalist bottom navigation bar that integrates these actions more conventionally while keeping the 3D room as the main viewport.
*   **Rationale:** Standardizing navigation patterns reduces cognitive load (Heuristic: Consistency and Standards) and ensures users can immediately find the shop or their profile.

### 2. Interaction Clarity: Visual Affordances in Isometric Rooms
*   **Issue:** It's unclear how the user interacts with the empty isometric room on the Dashboard.
*   **Solution:** Introduce subtle visual cues for customization.
    *   Display a faint grid or "placement nodes" on the floor/walls when the user enters a "Decorate" mode.
    *   Add a subtle pulsing effect or a small "plus" icon in the center of the room to prompt the first interaction (e.g., placing a desk).
*   **Rationale:** Improves discoverability and system feedback without cluttering the minimalist aesthetic, guiding the user into the gamified core loop.

### 3. Accessibility & Inclusivity Enhancements
*   **Issue:** Icon-only buttons can be ambiguous, and some text contrast appears low.
*   **Solution:**
    *   Ensure all `IconButton` or visual interactive elements (like the gear, bag, phone, clipboard) explicitly define the `tooltip` or `Semantics` property with descriptive text for screen readers (e.g., `Tooltip(message: 'Settings')`).
    *   Increase the color contrast slightly for the "Forgot Password?", "Create One", and input placeholder text to ensure WCAG AA compliance. Darken the warm brown or sage green used for these elements.
*   **Rationale:** Essential for users relying on screen readers or those with visual impairments, ensuring the "Cozy" aesthetic doesn't compromise usability.

### 4. UI Polish: Activity Chart Clarity
*   **Issue:** In the "Activity" modal, the bar chart uses very faint, almost invisible bars for empty days, and a single colored bar for the active day. The y-axis labels (0, 3, 6, 9, 12) are also very light.
*   **Solution:** Slightly increase the opacity or contrast of the empty bars and the axis labels to make the chart structure clearer at a glance, while maintaining the soft aesthetic.
*   **Rationale:** Improves data readability and ensures users can easily interpret their learning trends.

---

## Domain Strategy

*   **Current State:** The architecture implies a monolithic backend (`services/backend`), a student frontend (`apps/student_app`), and a professor dashboard (`apps/prof-dashboard`).
*   **Recommendation:** Maintain the primary domain for the student application and marketing (e.g., `arbormed.com` or `app.arbormed.com`). Host the Professor Dashboard on a distinct subdomain (e.g., `educators.arbormed.com` or `admin.arbormed.com`).
*   **Rationale:** The user personas (Student vs. Professor) have fundamentally different needs, security profiles, and workflows. Separating the subdomains allows for tailored routing, independent deployments, and clearer mental models for users, while keeping the core API unified.

---

## New Features (Gamification & Retention)

1.  **"Study Ambient" Mode (Audio Integration):**
    *   *Concept:* Leverage the "Cozy" aesthetic by adding a lo-fi/ambient medical soundscape player directly on the Dashboard and Study screens.
    *   *Why:* Keeps students in the "Flow" state. Ties into the visual aesthetic to create a full sensory experience, reducing study anxiety.
2.  **Visual Progression of the "Medical ID":**
    *   *Concept:* The Profile modal shows a standard avatar icon. Allow users to unlock and equip different borders, badges, or titles for their ID card based on their "True Mastery Score" or specific milestones.
    *   *Why:* Provides a highly visible, status-driven reward for deep learning, complementing the currency economy and adding a personalized touch to the profile.
3.  **Interactive Room Elements (Mini-interactions):**
    *   *Concept:* Once items are placed in the 3D room, allow tiny, satisfying interactions. Tapping a plant might make it rustle; tapping a lamp turns it on/off; tapping the rotary phone might play a short, encouraging voicenote.
    *   *Why:* Deepens the "Cozy" feeling and gives users a reason to linger and relax in their digital space between intense study sessions.
