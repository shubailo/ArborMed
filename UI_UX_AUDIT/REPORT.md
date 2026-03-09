# ArborMed UI/UX Audit Report

## Executive Summary
ArborMed is a "Cozy Competence" gamified medical education platform designed for high-fidelity, low-stress learning. Overall, the app's visual identity strongly supports its mission. The warm color palette, playful yet professional typography, and isometric room design successfully create a relaxed "flow" state environment.

However, there are areas for improvement, particularly concerning visual hierarchy, interaction cues (affordances), and empty state management on the main dashboard. While a complete redesign is unnecessary, targeted refinements will significantly enhance usability and user engagement.

## Analysis

### Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, here is an evaluation of ArborMed's UI:

*   **Visibility of System Status:**
    *   *Strengths:* The quiz screen shows clear progress via a top bar ("0/20"). The profile shows streak and XP clearly.
    *   *Weaknesses:* On the dashboard, it is not immediately obvious what action the user should take to "fill" the empty isometric room. The connection between earning "stethoscopes" (coins) and populating the room could be made clearer.
*   **Match Between System and Real World:**
    *   *Strengths:* The "Medical Supply Shop" concept and currency (stethoscopes) map well to the medical student demographic. The visual representation of a clinic room is intuitive.
*   **User Control and Freedom:**
    *   *Strengths:* The login/verification flow allows easy navigation (e.g., "Change Email / Edit Details"). The quiz screen allows users to close the session ("X" button).
*   **Consistency and Standards:**
    *   *Strengths:* Colors (sage green, cream, brown text) and typography are remarkably consistent across all screens. Button styles (pill-shaped, solid vs. outlined) are used logically.
*   **Error Prevention:**
    *   *Strengths:* The verification screen uses a standard 6-digit code format, reducing input errors.
*   **Recognition Rather Than Recall:**
    *   *Strengths:* The dashboard relies on icons (stethoscope, fire for streaks) that become recognizable, though they could benefit from initial tooltips or labels for new users.
*   **Aesthetic and Minimalist Design:**
    *   *Strengths:* The design is highly minimalist, avoiding clutter and focusing the user on core tasks. The generous use of negative space contributes to the "cozy" feel.

### Content and Architecture Analysis
*   **Information Architecture:** The navigation appears flat and straightforward. Key areas (Home/Room, Profile, Activity, Settings, Shop) seem accessible from the main dashboard, likely via the bottom/side icons.
*   **Labeling:** Labels like "Start Session," "Profile," and "Activity" are clear. However, the icons on the dashboard (telephone, bag, badge, gear) lack text labels, relying entirely on user inference.

### Visual Design Analysis
*   **Color Palette:** The use of off-white/cream backgrounds, sage green accents, and dark brown text is excellent. It reduces eye strain (crucial for students studying long hours) and establishes the intended "cozy" and natural aesthetic.
*   **Typography:** The rounded, sans-serif fonts are legible and friendly, aligning perfectly with the brand.
*   **Imagery/Iconography:** The isometric room is the centerpiece. However, the icons around it (phone, bag, ID badge) feel slightly disconnected from the 3D aesthetic of the room itself.

## Recommendations

### 1. Improve Dashboard Affordances and Onboarding (High Priority)
*   **Issue:** The main dashboard (the empty isometric room) lacks clear direction for new users on how to interact with it or why it is empty. The icons surrounding the room lack labels.
*   **Solution:**
    *   Introduce a lightweight, one-time guided tour or subtle pulsing tooltips pointing to the shop icon ("Buy items to decorate your clinic!") and the "Start Session" button ("Earn stethoscopes here!").
    *   Add small, subtle text labels beneath the main navigation icons (Phone -> Contact/Help, Bag -> Shop, Badge -> Profile, Gear -> Settings).
*   **Rationale:** Improves initial user orientation and clarifies the core gameplay loop (Study -> Earn -> Decorate).

### 2. Enhance the Quiz Interface Hierarchy (Medium Priority)
*   **Issue:** On the quiz screen, the system category ("CARDIOVASCULAR SYSTEM") looks somewhat like a button due to its pill shape, while the actual question text lacks distinct visual weight.
*   **Solution:**
    *   Change the system category indicator to flat text with an underline or a subtle, non-interactive badge style (e.g., just the text with a small icon next to it, not a full bordered pill).
    *   Increase the font size or weight of the main question text slightly to ensure it is the absolute focal point.
*   **Rationale:** Clarifies interactive vs. non-interactive elements and improves readability.

### 3. Emphasize the "Streak" Mechanic (Low Priority, High Impact)
*   **Issue:** The streak is visible in the top left, but its importance to the progression system (leveling up requires streaks) isn't visually emphasized.
*   **Solution:**
    *   Add a subtle animation (e.g., a tiny spark or glow) to the fire icon when a streak is active.
    *   On the profile screen, consider adding a visual progress bar or milestone markers for the streak to show how close the user is to the next level requirement.
*   **Rationale:** Gamification relies heavily on visible progress and positive reinforcement.

### 4. Accessibility Enhancements (Ongoing)
*   **Issue:** While contrast is generally good, the light green text on the cream background (e.g., "Create One" on the login screen, "0/20" on the quiz screen) might fail WCAG contrast ratios for some visually impaired users.
*   **Solution:** Slightly darken the sage green used for text links and progress indicators to ensure they meet WCAG AA standards against the cream background. Ensure all icon-only buttons (like the dashboard icons) have `Tooltip` widgets with semantic labels implemented in the Flutter code.

## Domain Strategy
Given that ArborMed consists of a student application (Flutter) and potentially a web dashboard, the recommended structure is:

*   **Main Landing Page/Marketing:** `arbormed.com` (Showcasing features, pricing, and download links).
*   **Web App (Student Portal):** `app.arbormed.com` (Hosting the Flutter Web build).
*   **Professor/Admin Dashboard (if applicable):** `admin.arbormed.com` or `prof.arbormed.com`.
*   **API:** `api.arbormed.com`.

**Rationale:** This standard SaaS architecture cleanly separates marketing concerns from application logic and user sessions.

## New Features (Proposals)

1.  **"Lofi Study Mode" Audio integration:** Since the goal is "Cozy Competence" and a flow state, integrating a built-in, togglable lo-fi ambient music or white noise player directly into the study sessions.
2.  **Room Templates/Presets:** As users unlock many items, allow them to save "room loadouts" (e.g., "The Modern Clinic," "The Classic Library") to easily switch aesthetics.
3.  **Social/Guild "Clinics":** Allow small groups of friends to pool resources to upgrade a shared, larger isometric clinic space, fostering collaborative studying.