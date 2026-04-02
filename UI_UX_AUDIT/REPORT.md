# UI/UX Audit Report: ArborMed

## 1. Executive Summary

ArborMed leverages a unique "Cozy Competence" isometric aesthetic that provides a highly engaging, gamified experience for medical education. The 3D room environments establish a relaxing atmosphere that contrasts with the high-stress nature of medical studies. While the visual design is a strong differentiator and successfully creates an immersive environment, there are key areas where usability, accessibility, and navigational clarity can be improved to ensure the application is as functional as it is beautiful.

## 2. Analysis

### 2.1 Heuristic Evaluation
*   **Visibility of System Status:** The top bar counters (Stethoscopes and Streaks) as seen in `dashboard.png` provide good passive status. However, it is not immediately clear if these are interactive.
*   **User Control and Freedom:** In the `settings.png` screen, controls are clear (toggles, sliders). However, navigation back to the main screen relies on implicit gestures or clicking outside the modal, which could be confusing for some users.
*   **Error Prevention & Accessibility:**
    *   **Contrast (WCAG AA):** Some text elements, particularly placeholder text in `login.png` and `verification.png` or subdued text on the pale backgrounds, may fall short of WCAG AA contrast ratios.
    *   **Iconography:** Icon-only buttons (such as the password visibility toggle in the login screen, or the settings gear in the dashboard) require explicit `aria-labels` or tooltip support for screen readers, and dynamically updating text (e.g., "Show password" -> "Hide password").

### 2.2 Content and Architecture
*   **Navigation (`dashboard.png` / `activity.png`):** The primary navigation relies on interacting with the 3D environment or the bottom action buttons ("START SESSION", Profile/Settings icons). For new users or on smaller mobile screens, a standard sticky bottom navigation bar (Home, Shop, Activity, Profile) might provide more predictable and faster traversal between core areas without breaking the immersion of the main viewport.
*   **Settings Grouping (`settings.png`):** The settings modal groups Notifications, Audio, and "Sign Out" together. "Sign Out" is a destructive action and is styled well as a distinct block, but grouping account-level actions separately from device-level preferences (Audio/Notifications) might improve logical flow.

### 2.3 Visual Design
*   **Isometric Environments (`shop.png`, `dashboard.png`):** The 3D isometric rooms are stunning and effectively support the "Cozy Competence" theme. The color palette is soothing (pastels, earth tones).
*   **Interactive vs. Decorative Elements:** Because the 3D backgrounds are detailed, it can occasionally be difficult to distinguish which elements are interactive buttons and which are just scenery.
    *   *Recommendation:* Implement a standardized elevation/shadow system or a subtle glowing outline for interactive UI elements (like the "START SESSION" button or clickable items in the shop) to clearly separate them from the background decorations.

## 3. Recommendations

1.  **Enhance Accessibility & Contrast:**
    *   *Issue:* Low contrast text and missing context for screen readers.
    *   *Solution:* Audit all text colors against the background to ensure at least a 4.5:1 ratio for normal text. Ensure all icon-only buttons (like settings gear, password toggle) have dynamic, descriptive tooltips.
2.  **Clarify Interactive Elements:**
    *   *Issue:* Blending of UI buttons with the isometric background.
    *   *Solution:* Apply a consistent drop shadow or distinct border treatment to all primary and secondary action buttons to make them "pop" off the canvas.
3.  **Improve Main Navigation:**
    *   *Issue:* Relying on scattered icons (bottom left, bottom right) for navigation can increase cognitive load.
    *   *Solution:* Introduce a simplified, sticky bottom navigation bar for mobile web/app users to standardize movement between Dashboard, Shop, Activity, and Settings.
4.  **Clarify Top Bar Counters:**
    *   *Issue:* Unclear if Stethoscope/Streak counters are buttons.
    *   *Solution:* If they are clickable (e.g., to buy more currency or view streak history), add a subtle hover effect or a chevron to indicate interactivity. If static, ensure the design clearly communicates them as read-only badges.

## 4. Domain Strategy

**Recommendation: Unified Domain (`app.arbormed.com`)**
Given that ArborMed functions as a cohesive web application (likely a PWA based on the Flutter architecture), it is highly recommended to keep the core application on a single, unified domain or subdomain rather than splitting functionality (like the shop or activity tracker) across different subdomains. A single domain ensures seamless state management, faster client-side routing, and a continuous, uninterrupted Progressive Web App experience.

## 5. New Features

1.  **Interactive Tutorial / Onboarding Mode:**
    *   Given the unique isometric interface, new users would benefit from an interactive tutorial that highlights clickable areas in the 3D room (e.g., a pulsing spotlight on the desk to start a session, or on the shelf to access the shop).
2.  **Dark Mode / Night Shift Variant:**
    *   To align with the "Cozy" aesthetic and support users studying late at night, introduce a Dark Mode variant. This would involve shifting the pastel/earth tones to deeper, richer hues (e.g., deep navy, warm lamp-light accents in the isometric rooms) while maintaining the soothing atmosphere.
