# UI/UX Audit Report: ArborMed

## 1. Executive Summary

ArborMed is a "Cozy Competence" gamified medical education platform featuring a robust local-first, cloud-synced architecture (Flutter, Node.js). The application heavily leans into a serene, atmospheric environment (ivory/sage palette, isometric view) to reduce student burnout. Overall, the current UI is visually appealing and aligns strongly with the "cozy" brand identity.

However, there are opportunities to enhance usability, accessibility, and the visual hierarchy—especially within the primary "Room/Dashboard" and key interaction hubs—to ensure a friction-free experience for users deep in study sessions. The primary focus of this audit is improving the Dashboard (Room Screen) interaction models and refining the cozy aesthetics for clarity.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen’s Usability Heuristics:
- **Visibility of System Status:** The dashboard uses status pills (top-left) to clearly indicate coins (Stethoscopes) and streaks. The real-time notification badge on the Network icon is effective.
- **Match Between System and Real World:** The "Medical Supply Shop" and "Stethoscopes" as currency fit the mental model of medical students perfectly.
- **User Control and Freedom:** Users can pan around the isometric room. There is an "auto-center" fallback when panning too far, which is a great safety net. However, exiting "Visit" or "Equip" modes could be more prominently signaled.
- **Consistency and Standards:** The color palette (Sage, Clay, Ivory) and typography (Figtree for headers) are consistent across the components analyzed.
- **Aesthetic and Minimalist Design:** The isometric room is beautifully minimalist. However, floating UI elements can sometimes feel disjointed from the physical space they overlay.

### 2.2 Content and Architecture
- The main `RoomScreen` serves as a complex hub. It overlays several UI pieces (Top-Left Status, Top-Right Like, Bottom-Left/Right Actions, Center Hero button).
- Action clustering is logical (Bottom-Left = Social/Profile, Bottom-Right = Modes/Settings), but distributing four identical circular buttons across two opposite corners creates a somewhat dispersed visual scan path.

### 2.3 Visual Design
- **Palette:** The `LightPalette` uses a calming `Ivory Cream (#FDFCF8)` background and `Sage Green (#8CAA8C)` primary. This successfully evokes a "cozy clinic" vibe.
- **Typography:** The use of Figtree and Quicksand (seen in the 'Office of...' tag) provides friendly, highly legible text.
- **Components:** The `CozyHubButton` uses image assets with fallback icons. The lack of drop shadows (removed in code) on the main hub buttons and the `StartSessionHero` flattens the UI, which might reduce their perceived clickability (affordance) over the 3D isometric background.

## 3. Recommendations

### R1: Consolidate the Action Hub (Dock)
- **Issue:** The four main navigation buttons (Network, Profile, Equip, Settings) are split between the bottom-left and bottom-right corners, forcing the user's eyes to jump across the screen.
- **Solution:** Group these navigation items into a unified, floating "Dock" at the bottom of the screen, similar to iOS or standard mobile OS docks, positioned just beneath the "START SESSION" hero button or wrapping it.
- **Rationale:** A centralized dock reduces cognitive load, speeds up navigation, and creates a more cohesive "control center" distinct from the 3D room.

### R2: Enhance Button Affordance
- **Issue:** The `StartSessionHero` and `CozyHubButton` explicitly have `boxShadow: []` (empty). Against a potentially busy 3D isometric background, floating flat UI elements can blend in.
- **Solution:** Reintroduce a subtle, soft shadow (using `palette.shadowSmall` or `coloredShadow`) to the main floating action buttons.
- **Rationale:** Shadows lift the UI off the 3D canvas, clearly separating the interactive HUD from the non-interactive (or differently interactive) room elements.

### R3: Improve the "Visit Mode" Context
- **Issue:** When visiting another player's room, the "Home" and "Like" buttons appear, and the "Start Session" button changes to "Add Note". While functional, the overall screen state doesn't drastically signal that you are no longer in your own room.
- **Solution:** Introduce a subtle screen border or a persistent top banner when in "Visit Mode" to clearly frame the experience as being outside the user's home base.
- **Rationale:** Prevents mode confusion, a common usability trap.

### R4: Accessibility - Contrast in Overlays
- **Issue:** The ambient overlays in `RoomScreen` (e.g., `Color(0xFFF5D78E).withValues(alpha: 0.08)` for morning) are aesthetic, but overlaying these on top of the UI might slightly affect the contrast of text elements.
- **Solution:** Ensure the `IgnorePointer` ambient overlay is placed *behind* the HUD layer (Status pills, Buttons) in the `Stack`, rather than over everything. (Currently, it seems correctly placed behind the HUD, but this should be strictly enforced for any future weather/lighting effects).

## 4. Domain Strategy
- **Current:** The platform appears to be an app (`student_app`).
- **Recommendation:** If a web version is deployed (as noted by `flutter run -d chrome`), host the primary application at `app.arbormed.com` or `play.arbormed.com`. Keep the marketing and documentation (the "Why") on the root domain `arbormed.com`. This separation of concerns prevents the heavy web app assets from slowing down the landing page SEO.

## 5. New Features

### F1: "Focus Mode" (Pomodoro Integration)
- **Concept:** Since ArborMed emphasizes preventing burnout, integrate a native Pomodoro timer into the Dashboard. When activated, the room lighting dims, a Lo-Fi beat plays, and the user enters a dedicated 25-minute study sprint.
- **Why:** Aligns perfectly with the "Cozy Competence" brand, offering practical utility beyond standard quizzing.

### F2: Ambient Room Interactions
- **Concept:** Allow users to tap objects in their room for micro-interactions (e.g., tapping a coffee cup shows steam, tapping a plant waters it for +1 XP).
- **Why:** Deepens the connection to the virtual space, turning the dashboard into a "living" pet rather than just a static menu.
