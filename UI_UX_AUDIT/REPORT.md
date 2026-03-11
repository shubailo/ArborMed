# ArborMed UI/UX Audit Report

## Executive Summary
This report analyzes the UI/UX of the ArborMed frontend application (Flutter-based). ArborMed is a gamified medical education platform featuring adaptive learning, an isometric customizable clinic (room), and a cozy, stress-free aesthetic ("Cozy Competence"). The audit assesses the current implementation, identifies areas for improvement in usability, visual design, and user flow, and provides actionable recommendations.

## Analysis

### Information Architecture & Flow
- **Onboarding:** The entry point is clearly defined through splash, login, and registration screens. The flow includes email verification.
- **Core Loop:** The primary user journey centers around a persistent isometric room (`RoomWidget` in `dashboard_screen.dart`). From this hub, users can launch quiz sessions, customize their room, visit other users' rooms, and view their profile.
- **Navigation Paradigm:** Instead of traditional tab bars or drawer navigation, ArborMed employs modal overlays and dialogs originating from the central isometric room view (e.g., `QuizFloatingWindow`, `ContextualShopSheet`).

### Visual Design & Aesthetics ("Cozy Competence")
- **Theme System:** A custom theme engine (`CozyTheme`) drives the visual identity, utilizing warm, low-stress color palettes (Sage Green, Soft Clay, Ivory Cream) and rounded, friendly typography (`Figtree`, `NotoSans`).
- **Isometric Room:** The central feature is a 2.5D isometric room rendered using `InteractiveViewer` for panning and zooming. Items and avatars are dynamically placed based on grid coordinates.
- **Animations:** The app makes heavy use of fluid animations, including floating background icons, cinematic room entry zooms, and interactive "pressable" widgets (`CozyButton`, `PressableAnswerButton`).

### Heuristic Evaluation
1. **Visibility of System Status:** Good. Loading indicators are used during network requests (e.g., fetching questions, logging in). The dynamic time-of-day ambient overlay in the room provides subtle context.
2. **Match Between System and Real World:** Strong. Medical themes are abstracted into accessible concepts (coins are "stethoscopes", users manage a "clinic").
3. **User Control and Freedom:** Needs improvement. The heavy reliance on modal overlays can sometimes trap users if dismissal paths aren't clearly visible or easily tappable.
4. **Consistency and Standards:** The custom design language is consistently applied via `CozyTheme`, though some standard Flutter dialogs or generic widgets might occasionally break the immersion if not fully customized.
5. **Aesthetic and Minimalist Design:** High. The design deliberately avoids visual clutter to maintain focus.

## Recommendations

### 1. Refine the Isometric Room Interaction
**Issue:** Free panning in the `InteractiveViewer` combined with a custom snapback logic can feel slightly disjointed if the user expects a standard map-like interaction. The manual calculation for centering might jitter on different screen sizes.
**Recommendation:** Ensure the boundary margins and snapback thresholds scale dynamically with the screen size. Add subtle visual indicators (like edge arrows) when the user has panned far from the center to guide them back, rather than solely relying on an automatic snap.

### 2. Streamline Modal Navigation
**Issue:** Heavy use of `showGeneralDialog` and `showDialog` for core features (Profile, Quiz Selection, Settings) creates a stack of overlays. Managing state across these overlays can become complex and might lead to a confusing "back" stack for the user.
**Recommendation:** For major sections like Profile or the main Quiz Menu, consider sliding panels or dedicated screens with custom transition animations instead of full-screen opaque modals. This preserves the feeling of the room being "behind" the UI while offering a more standard navigation mental model.

### 3. Improve Quiz Accessibility and Readability
**Issue:** During high-stress quiz sessions, the contrast of text on stylized backgrounds must be carefully managed.
**Recommendation:** Implement an explicit "High Contrast Mode" toggle within the settings that overrides the cozy palette with starker blacks and whites specifically for question text and answer choices, aiding legibility for visually impaired users or those studying in bright environments.

### 4. Enhance the "Visit" Experience
**Issue:** When visiting another user's clinic, the UI changes (e.g., "Leave Note" replaces the Quiz button). The state transition might not be immediately obvious beyond the top-left badge.
**Recommendation:** Introduce a distinct screen border or a slight shift in the ambient lighting tint when in "Visiting" mode to clearly separate it from the user's own home state.

## Domain Strategy
Given the app is primarily a Flutter application distributed across platforms (Mobile/Web), the current monolithic repository structure (`apps/student_app`, `services/backend`) is appropriate. If the web version serves as a primary marketing tool, consider a landing page on the main domain (e.g., `arbormed.com`) and hosting the web app on a subdomain (e.g., `app.arbormed.com`).

## New Features

### 1. Focus Mode (Pomodoro Integration)
Integrate a built-in Pomodoro timer directly into the HUD. When active, ambient lo-fi medical-themed study beats play (leveraging the existing `AudioProvider`), and notifications for social features (like incoming duels or notes) are temporarily silenced to encourage deep work.

### 2. Interactive Study Buddies
Expand the `BeanWidget` avatar functionality. Allow the user to tap the avatar to receive a quick motivational quote, a high-yield medical fact of the day, or a reminder about their current streak.
