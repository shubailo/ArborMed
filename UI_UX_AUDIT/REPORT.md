# ArborMed UI/UX Audit Report

## Executive Summary
ArborMed is a medical education platform aiming to reduce burnout through a "Cozy Competence" aesthetic, blending clinical rigor with gamification. This audit assesses the mobile app UI/UX, built with Flutter, based on the provided design language and screenshots (`login`, `dashboard`, `quiz`, and `activity`).

Overall, the app succeeds in its goal of providing a low-stress, "cozy" environment. The color palette (sage greens, ivory, warm clay) effectively lowers the high cognitive load typically associated with board prep. However, there are opportunities to improve accessibility, clarify navigation affordances, and deepen the connection between the gamified elements and the core learning loop.

## Analysis

### Heuristic Evaluation
*   **Visibility of System Status:** Strong. The dashboard clearly displays the user's current resources (stethoscopes/coins and streak/fire). The quiz interface features a prominent progress bar ("0 / 20" Level Progress).
*   **Match Between System and Real World:** Good use of medical metaphors (stethoscopes for currency, medical bag for shop/inventory, ECG badge for profile). The isometric "Virtual Clinic" is an engaging real-world parallel.
*   **Consistency and Standards:** Excellent. The app adheres strictly to its custom `CozyTheme`, utilizing consistent typography (Figtree for headers, Noto Sans for body) and button shapes across all screens.
*   **User Control and Freedom:** The UI relies heavily on icon-only buttons on the dashboard, which may obscure navigation for new users until they learn the system.
*   **Aesthetic and Minimalist Design:** The UI is exceptionally clean. The use of soft shadows (`shadowSmall`, `shadowMedium`), subtle gradients, and rounded corners creates a paper-like, tactile feel.

### Content and Architecture
*   **Information Architecture (IA):** The dashboard serves as the central hub, with the isometric room as the focal point. Interactive elements surround the room. However, the hierarchy of these icons (Phone, Bag, Badge, Gear) is entirely flat, making it unclear which actions are primary versus secondary, aside from the prominent "Start Session" button.
*   **Modal Usage:** The Activity and Profile screens appear to open as modals/bottom sheets over the dashboard. This keeps the user grounded in their "room" but can feel cramped if too much data (like the Activity Trend chart) is displayed.

### Visual Design
*   **Color Palette:** The `CozyTheme` utilizes an Ivory Cream background (`#FDFCF8`), Sage Green primary (`#8CAA8C`), and warm text colors (`#4A3728`, `#8D6E63`). This is highly effective at reducing eye strain compared to stark white/blue clinical apps.
*   **Typography:** The combination of Figtree (geometric, friendly) for headings and Noto Sans (highly legible) for body text is an excellent choice for an educational app.
*   **Accessibility:** Contrast ratios between the text (`textPrimary`, `textSecondary`) and the `paperWhite` backgrounds are generally good. However, some icon-only buttons lack visible text labels, which could impact usability for visually impaired users or those unfamiliar with the iconography.

## Recommendations

1.  **Add Semantic Labels & Tooltips to Dashboard Navigation**
    *   **Issue:** The dashboard relies on icon-only interactive widgets (phone, medical bag, ID badge, gear). While thematic, their exact functions aren't immediately obvious to new users.
    *   **Solution:** Wrap these `GestureDetector` or `InkWell` icons in `Tooltip` widgets to provide semantic labels for screen readers and descriptions on long-press/hover. Consider adding subtle, small text labels beneath the icons.
    *   **Rationale:** Improves accessibility and reduces cognitive load during onboarding.

2.  **Enhance the "Empty State" of the Isometric Room**
    *   **Issue:** In the `dashboard.png` screenshot, the isometric room is completely empty. While this gives a blank slate, it feels stark compared to the "cozy" promise.
    *   **Solution:** Provide a default, low-tier item (e.g., a simple potted plant or a basic desk) to anchor the room immediately.
    *   **Rationale:** Instills the concept of the customizable space immediately and provides immediate visual warmth.

3.  **Clarify the Activity Modal Navigation**
    *   **Issue:** In the `activity.png` modal, the "Profile" and "Activity" toggle buttons look like primary action buttons (like "Start Session"), which might confuse users into thinking they navigate away rather than switching tabs within the modal.
    *   **Solution:** Change the visual treatment of these tab switches to look more like a standard segmented control or a tab bar, rather than standalone elevated buttons.
    *   **Rationale:** Standardizes the UI pattern for switching views, aligning with expected mobile behaviors.

4.  **Increase Contrast on the Quiz "True/False" Buttons**
    *   **Issue:** The unselected True/False buttons in the quiz interface have a very low-contrast outline and background.
    *   **Solution:** Darken the border slightly or add a subtle background tint (`paperCream` or a low-opacity `primary`) to make them stand out more clearly as interactive targets against the main card.
    *   **Rationale:** Ensures users can quickly identify actionable areas, crucial during timed or high-stress study sessions.

## Domain Strategy
Given that ArborMed consists of a cross-platform Flutter application (`apps/student_app`) and a Next.js web application (`apps/prof-dashboard`), a unified domain strategy is recommended:
*   **Primary Domain (`arbormed.com`):** Should host the marketing site and landing page, explaining the philosophy and features.
*   **Student Web App (`app.arbormed.com`):** The Flutter web build for students who prefer studying on desktop without installing an app.
*   **Professor/Admin Dashboard (`dashboard.arbormed.com` or `prof.arbormed.com`):** The Next.js application for educators and content creators.
Separating the web applications onto subdomains keeps routing clean, allows for independent deployment scales, and isolates the authentication contexts.

## New Features

1.  **"Study Lofi" Integrated Audio Player**
    *   To double down on the "Cozy" aesthetic and Flow state, integrate a simple, non-intrusive audio player that streams curated, royalty-free lofi medical beats. This can be toggled from the dashboard and runs during the quiz.

2.  **Interactive Room Hotspots**
    *   Instead of just relying on the UI icons around the edges, allow users to tap items *inside* the isometric room to trigger actions. For example, tapping the desk opens the quiz session, tapping a bookshelf opens past topics, and tapping a calendar opens the activity streak.

3.  **Collaborative "Study Rooms" (Asynchronous Multiplayer)**
    *   While "Duel Mode" is high-intensity PvP, add a low-intensity social feature where users can visit their friends' decorated rooms and leave "Kudos" (which grants a tiny amount of Stethoscopes), fostering a supportive community.
