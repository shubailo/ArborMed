# ArborMed UI/UX Audit Report

## Executive Summary
This report analyzes the UI/UX of ArborMed, a gamified medical education platform. The focus is on the mobile student app frontend, specifically assessing usability, visual design, and the gamified ecosystem.
The analysis is based on the provided UI screenshots, `docs/images/dashboard.png` in particular, as well as an exploration of the Flutter codebase.
Overall, ArborMed presents a cohesive, visually appealing "Cozy Competence" aesthetic. The isometric environment is engaging, but several usability and accessibility improvements can refine the user experience, particularly concerning navigation clarity, interactive states, and contrast.

## Analysis

### Heuristic Evaluation
*   **Visibility of System Status:** The user's progress (coins, streak) is clearly visible in the HUD. However, interactive elements within the 3D room might lack clear affordances to indicate they are clickable.
*   **Match Between System and Real World:** The medical metaphors (Stethoscopes as currency, isometric clinic) are strong and appropriate for the target audience.
*   **User Control and Freedom:** The UI provides an 'Equip' and 'Done Equipping' mode, allowing users to customize their space freely. The navigation (Network, Profile, Settings) is accessible, although the icons rely heavily on custom assets without persistent text labels.
*   **Consistency and Standards:** The color palette and iconography are consistent, maintaining the cozy vibe. However, relying purely on tooltips (long-press in mobile contexts) for icon buttons can hinder discoverability.
*   **Aesthetic and Minimalist Design:** The isometric room takes center stage, and the HUD elements are floating, keeping the interface uncluttered. The design is highly aesthetic.

### Content and Architecture Analysis
*   The primary screen (`RoomScreen`) serves as both a dashboard and an interactive environment.
*   Navigation relies on floating action buttons placed in the bottom corners (`CozyActionsOverlay`).
*   The "Start Session" button is prominent and centered, clearly indicating the primary call to action.

### Visual Design
*   **Cozy Palette:** The application utilizes warm, muted colors (`#FDFCF8`, `#8CAA8C`, `#F5D78E`) which successfully create a low-stress environment.
*   **Typography:** It uses legible fonts (Figtree/NotoSans) which match the branding.
*   **Iconography:** Custom icons are used, which fit the theme perfectly. The dashboard buttons have a skeuomorphic/hand-drawn feel.

## Recommendations

1.  **Enhance Icon Button Discoverability and Accessibility**
    *   **Issue:** The bottom navigation buttons (Network, Profile, Equip, Settings) use icon assets without text labels visible by default (relying on tooltips). On mobile devices, tooltips are not easily discoverable.
    *   **Solution:** While maintaining the custom assets, consider adding small, elegant text labels beneath the icons, or ensure the tooltip triggers quickly upon a light tap if long-press is the default. Also, ensure proper `Semantics` widgets are wrapped around these buttons for screen readers. Since `CozyHubButton` wraps a `Tooltip`, adding a `Semantics` label with the same text is crucial.
    *   **Rationale:** Improves usability by explicitly stating the function of each button without requiring exploration.

2.  **Improve Affordances for Interactive Room Objects**
    *   **Issue:** In the isometric room, it might not be immediately obvious which objects are interactive (e.g., the desk) vs purely decorative.
    *   **Solution:** Implement a subtle hover effect (for web) or a slight pulsating glow on interactive elements, or a "hint" overlay when the user enters the room.
    *   **Rationale:** Reduces cognitive load by guiding users to interactive elements.

3.  **Refine "Start Session" Button Contrast**
    *   **Issue:** The "Start Session" button uses a muted green (`#8CAA8C`) with white text. Depending on the background overlay, the contrast might occasionally fall below WCAG standards.
    *   **Solution:** Slightly darken the green tone for the button background or apply a subtle drop shadow to the text to ensure legibility across all ambient lighting conditions in the room.
    *   **Rationale:** Ensures accessibility and usability for all users, particularly those with visual impairments.

4.  **Feedback for the "Like" Action**
    *   **Issue:** When visiting another clinic, the user can "Like" it. The current feedback is a localized heart animation.
    *   **Solution:** The current implementation in `CozyActionsOverlay` is good, but ensure the "Cooldown" snackbar uses a contrasting color to the main theme to stand out as a system message.
    *   **Rationale:** Clear system feedback prevents user frustration.

## Domain Strategy
Given the architecture, keeping the web application on `app.arbormed.com` and the landing page on `www.arbormed.com` is a standard and effective strategy. The backend APIs should run on `api.arbormed.com`.

## New Features

*   **Mini-Map or Quick Navigation:** If the isometric room becomes large or spans multiple areas, a simple mini-map or a quick-jump menu could aid navigation.
*   **Achievements Showcase:** Allow users to place specific trophies or certificates in their room based on their clinical mastery level or duel victories.
*   **Day/Night Cycle Toggle:** While the ambient overlay changes based on the time of day, allowing users to manually toggle or override this (e.g., forcing a "Night Study" mode with a desk lamp focus) could enhance the cozy atmosphere.
