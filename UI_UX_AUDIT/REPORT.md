# UI/UX Audit Report: ArborMed

## Executive Summary

This report presents a comprehensive UI/UX analysis of the **ArborMed** medical education platform. The analysis is based on the provided screenshots (Login, Dashboard, Profile, Quiz) and documentation. ArborMed presents a unique "Cozy Competence" design system, which is largely successful in creating a low-stress, engaging environment for medical students.

The application effectively utilizes isometric 3D illustrations, a muted pastel color palette (sage greens, dusty roses, creamy backgrounds), and rounded typography (Figtree) to establish its brand identity. However, there are areas where usability, accessibility, and visual hierarchy can be improved to further enhance the user experience and ensure a seamless learning journey. Key recommendations include improving color contrast for accessibility, refining interactive element affordances, and enhancing feedback mechanisms during quiz sessions.

## Analysis

### 1. Heuristic Evaluation (based on Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:**
    *   *Strengths:* The dashboard clearly displays current stats (Stethoscopes, XP/Fire icon) and the quiz screen shows level progress clearly with a progress bar (0/20).
    *   *Weaknesses:* During the quiz, it's not immediately obvious what happens after selecting "True" or "False" (is there immediate feedback, or does it wait for a submission?). The loading states (e.g., waiting for matchmaking in Duel mode) are not fully depicted in the provided screens but must be clearly communicated.
*   **Match between System and the Real World:**
    *   *Strengths:* The use of a "Medical Supply Shop", "Stethoscopes" as currency, and a virtual clinic environment perfectly aligns with the target audience's mental model.
    *   *Weaknesses:* None prominent based on the visual evidence.
*   **User Control and Freedom:**
    *   *Strengths:* The "X" button on the top right of the quiz screen provides a clear exit path.
    *   *Weaknesses:* It's unclear if users can pause a session or review previous answers easily within a session.
*   **Consistency and Standards:**
    *   *Strengths:* The "Cozy Competence" design system is very consistent across the provided screens. The use of rounded rectangles, consistent font styles, and the specific color palette unifies the experience.
    *   *Weaknesses:* The "Start Session" button on the dashboard and the "Profile"/"Activity" buttons on the profile modal have slightly different styling treatments (solid vs. outlined), which is acceptable for primary vs. secondary actions, but the interaction states (hover/active) must be consistent.
*   **Error Prevention:**
    *   *Strengths:* The login screen uses standard input fields.
    *   *Weaknesses:* Form validation feedback (e.g., incorrect password, invalid email format) is not shown in the static screenshots. It's crucial to provide inline, immediate validation rather than waiting for a form submission to fail.
*   **Recognition rather than Recall:**
    *   *Strengths:* The dashboard layout relies on recognizable icons (telephone, medical bag, gear) rather than forcing users to remember navigation paths. The quiz screen clearly states the current topic ("CARDIOVASCULAR SYSTEM").
    *   *Weaknesses:* The icons on the dashboard lack text labels. While stylized, a new user might not immediately know what the telephone or the ID badge represents without tooltips or labels.
*   **Flexibility and Efficiency of Use:**
    *   *Strengths:* The interface appears uncluttered, suitable for focused study.
    *   *Weaknesses:* Keyboard navigation support (especially for the quiz True/False buttons) is essential for power users studying on a desktop/web environment.
*   **Aesthetic and Minimalist Design:**
    *   *Strengths:* The app excels here. The design is clean, thematic, and avoids unnecessary visual noise, which is critical for a study tool intended to reduce cognitive load.
*   **Help Users Recognize, Diagnose, and Recover from Errors:**
    *   *Not fully assessable* from the successful path screenshots provided. Error states must be designed with the same "cozy" aesthetic to avoid inducing stress.
*   **Help and Documentation:**
    *   *Weaknesses:* There are no visible help icons or tooltips in the main UI views to explain features like the "Streak" mechanics or how "XP" is calculated directly in context.

### 2. Content and Architecture Analysis

*   **Information Architecture:** The primary flow (Home -> Start Session -> Quiz) is straightforward. The use of a modal for the Profile ensures the user isn't taken away from their "Room" context unnecessarily.
*   **Navigation:** The dashboard utilizes an environmental navigation approach (clicking objects in the room/UI). This is engaging but can risk low discoverability if the interactive areas (hitboxes) aren't clearly defined or if the objects are ambiguous.
*   **Content Organization:** The quiz screen is well-organized. The category ("CARDIOVASCULAR SYSTEM") is visually separated from the question text, and the progress is clearly indicated.

### 3. Visual Design Analysis

*   **Color Palette:** The pastel palette (creams, sage greens, warm browns) is visually pleasing and effectively reduces eye strain compared to stark white/blue typical medical apps.
*   **Typography:** The rounded sans-serif font (likely Figtree, as per guidelines) is legible and friendly. The use of all-caps for headers ("CARDIOVASCULAR SYSTEM", "START SESSION") provides good structure.
*   **Accessibility (Contrast):**
    *   *Issue:* The contrast between the sage green button background and white text (e.g., "Login", "START SESSION") appears sufficient, but the contrast of the secondary text (e.g., "Forgot Password?", "Don't have an account?") against the cream background might be slightly low for WCAG AA compliance, especially for users with visual impairments.
    *   *Issue:* The progress bar (0/20) on the quiz screen uses low-contrast grey on a slightly lighter grey/cream background, which may be difficult to read.
*   **Affordances:**
    *   The interactive elements (buttons) are clear. However, on the Dashboard, the interactive icons (phone, bag, etc.) need clear visual cues (hover states, slight glowing, or subtle animation) to indicate they are clickable.

## Recommendations

### Prioritized Actionable Improvements

1.  **Enhance Accessibility (Contrast and Labels):**
    *   **Issue:** Low contrast on secondary text and progress bars; missing text labels for generic icons.
    *   **Solution:**
        *   Darken the text color for "Forgot Password?" and "Don't have an account?".
        *   Increase the contrast of the progress bar fill and text on the quiz screen.
        *   **Crucial:** Wrap purely visual interactive elements on the Dashboard (e.g., the telephone, the ID badge) with `Tooltip(message: '...')` to provide visual hints on hover/long-press and expose them to screen readers. For generic interactive widgets, use `Semantics(button: true, label: '...')`.
    *   **Rationale:** Ensures the application is usable by all medical students, adhering to WCAG guidelines and the platform's inclusivity goals.

2.  **Improve Discoverability on the Dashboard:**
    *   **Issue:** Environmental navigation relies on recognizing unlabelled icons.
    *   **Solution:** Implement subtle pulsing animations or a slight drop shadow on interactive room objects when the user first logs in to hint at their interactivity. Add brief onboarding tooltips pointing to these items during the first session.
    *   **Rationale:** Reduces cognitive friction for new users trying to understand how to navigate their "Room".

3.  **Refine Quiz Interaction Feedback:**
    *   **Issue:** It's unclear what happens immediately after a selection.
    *   **Solution:** When a user taps "True" or "False", provide immediate visual feedback.
        *   If it's a practice mode: Briefly highlight the selected button (e.g., Green for correct, Red for incorrect) before showing the explanation or moving to the next question.
        *   If it's an exam mode: Highlight the selected button to confirm the choice before allowing the user to proceed.
    *   **Rationale:** Immediate feedback confirms user action and (in practice mode) aids the learning loop.

4.  **Keyboard Navigation Support:**
    *   **Issue:** Potentially lacking efficiency for desktop/web users.
    *   **Solution:** Ensure all primary actions (Login, Start Session, True/False, Next Question) are reachable via `Tab` and executable via `Enter` or `Space`. Allow users to use left/right arrow keys or 'T'/'F' keys for True/False selections in the quiz.
    *   **Rationale:** Significantly speeds up the study process for power users on non-mobile platforms.

5.  **Contextual Help for Metrics:**
    *   **Issue:** "Streak" and "XP" metrics on the Profile lack immediate context.
    *   **Solution:** Add small 'info' (i) icons next to "STREAK" and "XP" that, when tapped/hovered, reveal a small tooltip explaining how they are calculated (e.g., "Maintain your streak by answering 5 questions daily!").
    *   **Rationale:** Improves understanding of the gamification mechanics, increasing user motivation.

## Domain Strategy

Given the "Local-First, Cloud-Synced" architecture and the distinct parts of the ecosystem (Student App vs. Prof Dashboard vs. Backend), the following structure is recommended:

*   **Primary Marketing/Landing Page:** `arbormed.com` (Should highlight the philosophy, features, and provide download/login links).
*   **Student Web App:** `app.arbormed.com` (Hosts the Flutter web build for students).
*   **Professor Dashboard:** `admin.arbormed.com` or `faculty.arbormed.com` (Hosts the Next.js dashboard).
*   **API/Backend:** `api.arbormed.com` (For routing backend requests).

**Recommendation:** Keep the main application on a subdomain (`app.`) to allow the root domain to serve as a fast, SEO-optimized landing page without loading the heavier Flutter engine.

## New Features

1.  **"Daily Rounds" Mini-Game:** Introduce a short, 5-question daily challenge that grants bonus "Stethoscopes". This encourages daily logins (improving the streak mechanic) and provides a low-barrier entry point for studying on busy days.
2.  **Focus Mode (Pomodoro Integration):** Since the app is built around "Cozy Competence" and maintaining flow, integrate a Pomodoro timer directly into the dashboard. Students can set a 25-minute focus timer, during which notifications are suppressed, and completing the timer awards a small XP bonus.
3.  **Visualized Mastery:** Instead of just a percentage for "True Mastery Score", visualize it as a growing "Skill Tree" or a filling medical chart in the user's profile. This provides a more tangible sense of progression.
4.  **Customizable "Lofi" Audio:** Allow users to select different ambient background tracks (e.g., "Library Rain", "Cozy Cafe", "Quiet Clinic") in the settings to further enhance the atmospheric focus state.
