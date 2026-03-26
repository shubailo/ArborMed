# 🩺 ArborMed: UI/UX Audit Report

## Executive Summary
This report analyzes the UI/UX of the **ArborMed** platform (specifically focusing on the Mobile Flutter app context). ArborMed's core concept blends high-fidelity medical education with a "Cozy Competence" design system. The ecosystem features gamified elements, 3D isometric rooms, and adaptive learning mechanics to create a stress-free environment for medical board prep.

Overall, the visual design successfully communicates the brand: calm, professional, and accessible. The pastel color palette, rounded elements, and clear typographic hierarchy establish a relaxing "flow" state.

However, certain areas relating to accessibility, interaction clarity, and gamified progress visualization can be improved. This audit provides specific, actionable recommendations, balancing aesthetic enhancement with functional utility.

---

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:**
    *   *Positive:* The "Dashboard" displays the current currency/streak cleanly (Stethoscopes/Fire icons).
    *   *Area for Improvement:* The isometric room view doesn't immediately indicate interactability. Users may not realize they can tap/drag items.
*   **Match Between System and the Real World:**
    *   *Positive:* The icons match medical/real-world concepts (Stethoscopes for coins, medical bags, clipboards).
    *   *Positive:* The "Shop" interface conceptually fits outfitting a real medical clinic.
*   **User Control and Freedom:**
    *   *Positive:* The "Forgot Password" flow is handled within a clean modal dialog, allowing users to cancel easily.
*   **Consistency and Standards:**
    *   *Positive:* The UI adheres closely to the "Cozy Competence" system (pastel greens, creams, warm browns, rounded sans-serif typography). Buttons consistently use the primary sage green.
*   **Error Prevention:**
    *   *Positive:* Form validation exists on the login screen (e.g., password length, empty fields).
*   **Aesthetic and Minimalist Design:**
    *   *Positive:* The minimalist approach prevents cognitive overload, critical for a stressful domain like medical study. The login screen is extremely clean.
*   **Accessibility (WCAG principles):**
    *   *Area for Improvement:* Interactive icon-only buttons (like the gear icon on the dashboard) lack visible labels. While they might have semantics under the hood, standardizing visual tooltips or labels on long-press/hover is crucial. Contrast ratios on placeholder text ("Email or Username") may be slightly low against the cream background.

### 2. Content and Architecture

*   **Navigation:** The primary navigation appears to rely heavily on icon buttons scattered around the screen (Dashboard: settings, profile, medical bag). A centralized, predictable navigation structure (like a bottom navigation bar or a prominent hamburger menu) could improve wayfinding.
*   **Information Hierarchy:** The login screen prioritizes the form perfectly. The dashboard prioritizes the visual room space.

### 3. Visual Design

*   **Color Palette:** The use of sage greens, dusty roses, creamy backgrounds, and warm browns perfectly encapsulates the "Cozy Competence" vibe. It avoids sterile hospital blues/whites.
*   **Typography:** The rounded sans-serif font (likely Figtree or similar) with all-caps, letter-spaced headers is friendly and readable.
*   **Imagery:** The 3D isometric illustrations are high quality, consistent, and serve as an excellent anchor for the gamified "room" experience.

---

## Recommendations

### 1. Usability & Navigation: Introduce a Bottom Navigation Bar
*   **Issue:** The "Dashboard" and "Shop" screens use scattered icon buttons for navigation (e.g., settings gear in the bottom right, profile badge in the bottom left, medical bag for inventory). This scattered approach increases cognitive load and makes one-handed mobile use harder.
*   **Solution:** Implement a standardized Bottom Navigation Bar with labels.
    *   *Tabs:* Home (Room), Study (Quiz), Duel (Arena), Shop, Profile.
    *   *Move secondary actions* (Settings) inside the Profile screen.
    *   *Code Reference:* Ensure navigation elements use standard Flutter Material/Cupertino components for native accessibility.
*   **Rationale:** Standard mobile pattern (Heuristic: Consistency and Standards). It grounds the user and provides immediate access to core loops (Study -> Earn -> Shop).

### 2. Interaction Clarity: Visual Affordances in Isometric Rooms
*   **Issue:** It's unclear which items in the 3D isometric rooms (Dashboard/Shop) are interactable.
*   **Solution:** Introduce subtle visual cues for interactable objects.
    *   *Option A:* A soft, pulsing glow around objects that can be tapped (e.g., tapping the desk opens study stats).
    *   *Option B:* A small, floating "Cozy" icon indicator above actionable zones.
    *   *Code Reference:* Wrap visual interactive elements (like `InteractiveViewer` or purely visual `GestureDetector` widgets) in a `Tooltip(message: '...')` to provide visual hints on hover/long-press and automatically expose the message to screen readers via semantics.
*   **Rationale:** Improves discoverability and system feedback without cluttering the minimalist aesthetic.

### 3. Accessibility & Inclusivity Enhancement
*   **Issue:** Icon-only buttons (like the settings gear or the password visibility toggle) can be ambiguous. Generic interactive widgets can be poorly announced by screen readers. The 'Create One' link on the login screen has low contrast compared to primary text.
*   **Solution:**
    *   Ensure all `IconButton` widgets without accompanying text explicitly define the `tooltip` property (e.g., `tooltip: 'Settings'`).
    *   To improve accessibility for generic interactive widgets (like `GestureDetector` or `InkWell`), wrap them in `Semantics(button: true, label: '...')` rather than `Tooltip`. This ensures screen readers announce them properly without enforcing intrusive visual popups on mobile long-press.
    *   When adding accessibility labels to dynamically mapped widgets, use available contextual variables (e.g., 'Interact with $name') instead of generic static text.
    *   Increase the contrast of the "Create One" and "Forgot Password?" text slightly to ensure WCAG AA compliance against the cream background.
*   **Rationale:** Essential for users relying on screen readers or those with visual impairments. Follows platform-specific best practices for accessibility.

### 4. Form UX: "Magic Link" Authentication
*   **Issue:** Medical students are busy. Typing passwords on mobile is friction.
*   **Solution:** Add a "Send Magic Link" option to the Login screen alongside the traditional password form.
*   **Rationale:** Reduces friction to entry, minimizing cognitive load before a study session.

---

## Domain Strategy

*   **Current State:** The architecture implies a monolithic backend (`services/backend`) and a single frontend app (`apps/student_app`). The repository also contains an `apps/prof-dashboard`.
*   **Recommendation:** Maintain the current single-domain structure for the core API (e.g., `api.arbormed.com`). However, the "Professor Dashboard" (`apps/prof-dashboard`) should be hosted on a distinct subdomain (e.g., `educators.arbormed.com` or `admin.arbormed.com`).
*   **Rationale:** The user personas (Student vs. Professor) have fundamentally different needs, security profiles, and workflows. Separating the subdomains allows for tailored routing, independent deployments, and clearer mental models for users.

---

## New Features (Gamification & Retention)

1.  **"Study Ambient" Mode (Audio Integration):**
    *   *Concept:* Leverage the "Cozy" aesthetic by adding a lo-fi/ambient medical soundscape player directly on the Dashboard and Study screens.
    *   *Why:* Keeps students in the "Flow" state. Ties into the visual aesthetic to create a full sensory experience.
2.  **Shared Study Rooms (Social/Multiplayer):**
    *   *Concept:* Allow users to invite a friend to "sit" in their isometric room. While both are in the room, they get a small (e.g., 5%) XP multiplier as long as both are actively answering questions.
    *   *Why:* Introduces positive peer pressure (body doubling) and social retention without the high stress of the PvP Duel mode.
3.  **Visual Progression (The "White Coat" Evolution):**
    *   *Concept:* Currently, currency buys room items. Add a personal avatar/clipboard/stethoscope that visually evolves as the "True Mastery Score" increases (e.g., tarnished stethoscope -> shiny -> gold).
    *   *Why:* Provides a highly visible, status-driven reward for deep learning (Level 3-4 questions), complementing the currency economy.
