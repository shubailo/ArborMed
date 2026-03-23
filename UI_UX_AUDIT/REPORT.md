# 🩺 ArborMed: UI/UX Audit Report

## Executive Summary
This report analyzes the UI/UX of the **ArborMed** platform, specifically focusing on the Mobile Flutter app context based on the provided repository images and documentation. ArborMed's core concept blends high-fidelity medical education with a "Cozy Competence" design system. The ecosystem features gamified elements, 3D isometric rooms, and adaptive learning mechanics to create a stress-free environment for medical board prep.

Overall, the visual design successfully communicates the brand: calm, professional, and accessible. The pastel color palette, rounded elements, and clear typographic hierarchy establish a relaxing "flow" state. The login flow, dashboard, and learning interface demonstrate a thoughtful and aesthetic approach.

However, certain areas relating to accessibility (contrast and tooltips), interaction clarity in the isometric 3D space, and navigation structure can be improved. This audit provides specific, actionable recommendations to elevate the user experience, balancing aesthetic enhancement with functional utility.

---

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:**
    *   *Positive:* The Dashboard (Home) and Quiz screens clearly display the current currency (Stethoscopes) and streak metrics (Fire icons) at the top left. The Quiz screen features a prominent, rounded progress bar.
    *   *Area for Improvement:* The 3D isometric room view on the dashboard doesn't immediately indicate interactability. Users might not realize they can tap or interact with placed items (like the desk, medical bag, or telephone) without trying to tap them first.
*   **Match Between System and the Real World:**
    *   *Positive:* The iconography effectively leverages real-world medical concepts (Stethoscopes for coins, medical bags for inventory, a clipboard for profile/stats). The "Shop" interface conceptually fits outfitting a real medical clinic.
*   **User Control and Freedom:**
    *   *Positive:* The Quiz interface provides clear, large "True" and "False" option buttons, allowing users to make their choices confidently. The inclusion of a clear "X" (close) button in the top right allows for an easy exit.
*   **Consistency and Standards:**
    *   *Positive:* The UI adheres closely to the established "Cozy Competence" system: pastel sage greens (`primary`), creamy ivory backgrounds (`background`), and soft warm browns (`textPrimary`, `textSecondary`). Buttons consistently use the primary sage green with rounded corners, and the typography (Figtree/Noto Sans) is cohesive throughout.
*   **Error Prevention:**
    *   *Positive:* Form validation exists on the login screen, and password masking with a visibility toggle (`visibility`/`visibility_off`) is correctly implemented to prevent entry errors.
*   **Aesthetic and Minimalist Design:**
    *   *Positive:* The minimalist approach is crucial for a cognitively demanding domain like medical study. The login screen is extremely clean, focusing solely on the necessary inputs. The background uses subtle, faded watermarks (bandages, pills) that add depth without causing distraction.
*   **Accessibility (WCAG Principles):**
    *   *Area for Improvement:*
        *   **Contrast:** The text color for secondary actions like "Forgot Password?" and "Create One" on the login screen uses `textSecondary` (`#8D6E63`) or `primary` (`#8CAA8C`), which may not meet strict WCAG AA contrast ratios against the ivory cream background (`#FDFCF8`), potentially alienating visually impaired users.
        *   **Tooltips/Semantics:** Icon-only buttons (like the gear icon on the dashboard) and visual elements need explicit `tooltip` or `Semantics` properties to ensure screen reader compatibility.

### 2. Content and Architecture

*   **Navigation Structure:** The primary navigation currently relies on icon buttons scattered across the bottom of the screen (e.g., settings gear in the bottom right, profile badge in the bottom left, medical bag for inventory). This scattered approach increases cognitive load and makes one-handed mobile use more difficult. A centralized, predictable navigation structure would improve wayfinding.
*   **Information Hierarchy:** The login screen prioritizes the authentication form perfectly. The dashboard prioritizes the visual 3D room space and the primary "START SESSION" call to action.

### 3. Visual Design

*   **Color Palette:** The use of sage greens, dusty roses, creamy backgrounds, and warm browns perfectly encapsulates the "Cozy Competence" vibe. It intentionally avoids the sterile, high-stress hospital blues and stark whites typical of medical apps.
*   **Typography:** The rounded sans-serif fonts (Figtree for headers, Noto Sans for body) with appropriate weight variations create a friendly, readable, and modern aesthetic.
*   **Imagery:** The 3D isometric illustrations (rooms, items) are high quality, consistent in lighting and perspective, and serve as an excellent anchor for the gamified "room" experience.

---

## Recommendations

### 1. Usability & Navigation: Centralize with a Bottom Navigation Bar
*   **Issue:** The "Dashboard" and "Shop" screens use scattered icon buttons for navigation (e.g., settings gear, profile badge, medical bag). This increases cognitive load and hides core loops.
*   **Solution:** Implement a standardized, labeled Bottom Navigation Bar.
    *   *Tabs:* Home (Room), Study (Quiz), Arena (Duel), Shop, Profile.
    *   *Action:* Move secondary actions (Settings) inside the Profile screen to declutter the primary view.
*   **Rationale:** This is a standard mobile UI pattern (Consistency and Standards) that grounds the user, provides immediate access to core loops, and improves one-handed usability.

### 2. Interaction Clarity: Visual Affordances in Isometric Rooms
*   **Issue:** It is unclear which items in the 3D isometric rooms (Dashboard/Shop) are interactable, requiring users to "guess and tap".
*   **Solution:** Introduce subtle visual cues for interactable objects.
    *   *Implementation:* Add a soft, pulsing glow or a small, floating "Cozy" indicator (e.g., a chevron or dot) above actionable zones or items.
    *   *Feedback:* Ensure every interactive element triggers the existing haptic feedback system (`CozyHaptics.lightTap()`) and an auditory cue.
*   **Rationale:** Improves discoverability and system feedback without cluttering the minimalist aesthetic.

### 3. Accessibility Enhancement: Improve Text Contrast
*   **Issue:** The 'Create One' link and 'Forgot Password?' text on the Login screen have low contrast against the cream background, failing to meet accessibility standards and making them hard to read for some users.
*   **Solution:** Update the text styles for these secondary actions.
    *   *Implementation:* Change the text color of "Forgot Password?" and "Create One" from `textSecondary` and `primary` to the darker, warmer `textPrimary` (`#4A3728`) to ensure sufficient contrast. Alternatively, add an underline to clearly signify interactability.
*   **Rationale:** Ensures inclusivity and compliance with WCAG AA guidelines.

### 4. Accessibility Enhancement: Semantic Labels and Tooltips
*   **Issue:** Icon-only interactive elements and purely visual tappable areas lack context for screen readers and hover states.
*   **Solution:**
    *   *Implementation:* Ensure all `IconButton` widgets explicitly define a descriptive `tooltip` property. For purely visual interactive components (like the 3D room items or the buddy avatar) wrapped in `GestureDetector`, wrap them in a `Tooltip` or use `Semantics(button: true, label: '...')` to expose the label to screen readers.
*   **Rationale:** Essential for users relying on assistive technologies.

### 5. Form UX: Introduce "Magic Link" Authentication
*   **Issue:** Medical students are busy, and typing complex passwords on mobile devices introduces friction during onboarding and daily login.
*   **Solution:** Add a "Send Magic Link" (passwordless) option to the Login screen alongside the traditional password form.
*   **Rationale:** Reduces the barrier to entry, minimizing cognitive load before a study session.

---

## Domain Strategy

*   **Current Architecture:** The platform features a Node.js backend (`services/backend`), a Flutter student app (`apps/student_app`), and a Next.js professor dashboard (`apps/prof-dashboard`).
*   **Recommendation:** Maintain the current single-domain structure for the core API (e.g., `api.arbormed.com`). However, the "Professor Dashboard" should be hosted on a distinct subdomain (e.g., `educators.arbormed.com` or `admin.arbormed.com`).
*   **Rationale:** The user personas (Student vs. Professor) have fundamentally different needs, security profiles, and workflows. Separating the subdomains allows for tailored routing, independent deployments, and clearer mental models.

---

## New Features (Gamification & Retention)

1.  **"Study Ambient" Mode (Audio Integration):**
    *   *Concept:* Leverage the "Cozy" aesthetic by adding a lo-fi/ambient medical soundscape player directly on the Dashboard and Study screens.
    *   *Why:* Keeps students in the "Flow" state. Ties into the visual aesthetic to create a full sensory experience.

2.  **Shared Study Rooms (Social/Multiplayer):**
    *   *Concept:* Allow users to invite a friend to "sit" in their isometric room. While both are in the room, they get a small (e.g., 5%) XP multiplier as long as both are actively answering questions.
    *   *Why:* Introduces positive peer pressure (body doubling) and social retention without the high stress of the PvP Duel mode.

3.  **Visual Progression (The "White Coat" Evolution):**
    *   *Concept:* Currently, currency buys room items. Add a personal avatar, clipboard, or stethoscope that visually evolves as the user's "True Mastery Score" increases (e.g., from a tarnished stethoscope to a shiny gold one).
    *   *Why:* Provides a highly visible, status-driven reward for deep learning (Level 3-4 questions), complementing the currency economy.
