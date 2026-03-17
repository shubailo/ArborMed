# UI/UX Audit Report: ArborMed

## Executive Summary

ArborMed is a high-fidelity, gamified medical education platform designed with a unique "Cozy Competence" aesthetic. Built on a Local-First Flutter (Frontend) and Node.js/PostgreSQL (Backend) stack, the application seamlessly merges rigorous academic board preparation (via a custom SM-2 adaptive algorithm) with a rewarding, low-stress virtual environment.

This UI/UX audit analyzes the repository's frontend presentation, user journeys, visual design system, and overall usability. The objective is to identify friction points and propose actionable improvements to enhance the focus state of learners, improve accessibility, and deepen engagement without overwhelming the user.

**Key Findings:**
- The "Cozy Competence" design system (isometric rooms, pastel sage/clay palette) is highly effective at reducing cognitive load.
- The use of dynamic, interactive environments (e.g., `RoomWidget`) provides an excellent anchor for the user journey.
- There are opportunities to improve accessibility (e.g., contrast ratios, screen reader semantics for non-text interactive elements).
- Navigation between the room (hub) and the quiz (core loop) is functional but could benefit from refined transition states and clearer cognitive mapping.

**Top Recommendations:**
1.  **Refine Accessibility:** Enhance tooltips, focus states, and contrast ratios on interactive elements.
2.  **Optimize the Hub-to-Quiz Flow:** Smooth the transition from the relaxed `RoomWidget` to the intense `QuizSessionScreen` using progressive disclosure and micro-interactions.
3.  **Enhance Onboarding:** Introduce a guided, contextual onboarding flow for first-time users to understand the economy and study systems.
4.  **Strengthen Economy UI:** Make the connection between studying (earning) and customizing (spending) more visually prominent.

---

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)

*   **Visibility of System Status:** Generally strong. `DashboardScreen` and `RoomWidget` use background loading (`_startCinematicEntry`, background fetches) to present a smooth entry. The use of `QuizLoadingScreen` manages expectations during data fetching. However, error states (e.g., failed network requests in the quiz flow) need to ensure they don't break the "cozy" immersion.
*   **Match Between System and Real World:** Excellent. The medical theme is deeply integrated ("Stethoscopes" as currency, "Consultations" for social notes, "Office of..." for profiles). The isometric room acts as a physical metaphor for a study space.
*   **User Control and Freedom:** Good. Users can freely pan and zoom in the `RoomWidget`. The `InteractiveViewer` implementation includes a clever "Light Roebound Snapback" to prevent users from getting lost in empty space. The ability to exit a quiz or preview mode (`CozyButton` to "QUIT PREVIEW") is clearly marked.
*   **Consistency and Standards:** Strong adherence to the internal "Cozy Theme" (`cozy_theme.dart`). Colors, typography (Figtree/Noto Sans), and button styles are centralized. However, ensuring that all interactive elements (like custom `ItemGraphic` or `BeanWidget`) have consistent hover/active states across platforms (especially Web/Desktop) is crucial.
*   **Error Prevention:** The login flow (`login_screen.dart`) includes basic validation and a clear path for unverified emails. The use of `CozyTheme.inputDecoration` standardizes form fields.
*   **Recognition Rather Than Recall:** The `RoomWidget` uses visual blueprints (`isBlueprint`, `isGhost`) to hint at placement options during decoration, reducing the need to remember where items can go.
*   **Flexibility and Efficiency of Use:** The `QuizSessionScreen` implements a keyboard listener (`LogicalKeyboardKey.space`) to advance/submit questions, which is a massive efficiency boost for power users on Desktop/Web.
*   **Aesthetic and Minimalist Design:** The UI leans heavily into its aesthetic, sometimes at the risk of being slightly busy (confetti, coins, floating icons, 3D room). Balancing these elements so they don't distract from the core task (studying) is vital.
*   **Help Users Recognize, Diagnose, and Recover from Errors:** The login screen handles the `email_not_verified` exception gracefully by redirecting to the `VerificationScreen`.
*   **Help and Documentation:** While the repository is well-documented, the in-app experience for a *new* user discovering the mechanics (wager system, mastery score) needs an explicit, integrated tutorial.

### 2. Content and Architecture

*   **Information Architecture (IA):** The app uses a Hub-and-Spoke model. The `RoomWidget` (Home/Hub) is the center, with spokes leading to `QuizSessionScreen`, `ProfilePortal`, `ShopSheet`, and `ClinicDirectory`. This is an effective pattern for games but requires clear paths back to the center.
*   **Navigation:** Currently relies on modal overlays and `showGeneralDialog` for menus (e.g., `QuizFloatingWindow`, `ProfilePortal`). This keeps the user anchored in their "Room" context, which is good for immersion.
*   **The Core Loop:** Study (Quiz) -> Earn (Coins) -> Customize (Room). The UI must clearly reinforce this loop. Currently, the transition from answering a question correctly to earning a coin (`_spawnCoinParticle`) is visceral and rewarding.

### 3. Visual Design

*   **Color Palette (`cozy_theme.dart`):** The palette (Sage Green, Soft Clay, Ivory Cream, Warm Brown text) is exceptionally well-chosen for reducing eye strain during long study sessions.
*   **Typography:** The pairing of `Figtree` (Geometric, friendly headers) and `Noto Sans` (Highly readable body text) supports both the gamified aesthetic and the need for dense medical text legibility.
*   **Imagery & Graphics:** The use of 3D isometric assets (`ItemGraphic`) and floating medical icons creates a distinct brand identity. The dynamic ambient overlay (`_getAmbientOverlay`) based on the time of day is a superb touch that enhances the feeling of a living environment.

---

## Recommendations

### Priority 1: Usability & Accessibility Enhancements

**1.1 Improve Interactive Element Semantics (Accessibility)**
*   **Issue:** Many custom interactive widgets (e.g., `GestureDetector` on the `BeanWidget` or `ItemGraphic` in the isometric room) lack semantic labels for screen readers.
*   **Solution:** Wrap visually-driven interactive elements without explicit text labels in `Semantics(button: true, label: '...Description...')`. If an element also benefits from a visual tooltip for mouse users (e.g., on Web/Desktop), use `Tooltip(message: '...')`, which automatically provides semantics.
*   **Rationale:** Ensures the app is usable by visually impaired medical students and complies with standard accessibility guidelines.

**1.2 High-Contrast Mode Toggle**
*   **Issue:** The low-contrast pastel palette, while "cozy," may fail WCAG AA contrast requirements for some text elements (e.g., `textSecondary` on `paperWhite`).
*   **Solution:** Introduce an explicit "High Contrast" toggle in the settings that deepens the browns and darkens the greens to ensure all text passes a 4.5:1 contrast ratio against its background.
*   **Rationale:** Medical study apps require extended reading; legibility cannot be compromised for aesthetics.

### Priority 2: Core Loop & Navigation Refinements

**2.1 Progressive Disclosure Onboarding**
*   **Issue:** A new user dropped into the `RoomWidget` might not immediately understand the relationship between the Quiz Portal, the Shop, and their Avatar.
*   **Solution:** Implement a contextual, step-by-step onboarding overlay on first login.
    *   *Step 1:* Highlight the Quiz Portal ("Start here to learn and earn Stethoscopes").
    *   *Step 2:* Highlight the Coin HUD ("Track your earnings").
    *   *Step 3:* Highlight the Shop/Decorate button ("Spend earnings to upgrade your clinic").
*   **Rationale:** Reduces initial friction and clearly communicates the core value proposition and gamification loop.

**2.2 Refine the Quiz Entry Transition**
*   **Issue:** The transition from the relaxed `RoomWidget` to the intense `QuizSessionScreen` currently uses a `FadeTransition` via `QuizLoadingScreen`.
*   **Solution:** Create a more thematic transition. For example, a "zooming in" effect on the Quiz Portal or a medical chart flipping open, bridging the gap between the 3D world and the 2D study interface.
*   **Rationale:** Smooths the cognitive shift from "play/relax" mode to "focus/study" mode.

**2.3 Clearly Delineate 'Decorate' vs. 'Visit' Modes**
*   **Issue:** In `RoomWidget`, `isDecorating` and `isVisiting` states share the same visual space.
*   **Solution:** When `isVisiting` is true, explicitly dim or disable interactive elements that belong only to the host (like the user's own shop inventory). The current top-left badge is good; add a subtle visual border (e.g., a soft gold glow) around the screen to indicate "You are in another player's space."
*   **Rationale:** Prevents mode confusion and clearly separates personal space from social space.

### Priority 3: Visual & Gamification Polish

**3.1 Enhanced Economy Feedback**
*   **Issue:** While `_spawnCoinParticle` in `QuizSessionScreen` is great, the connection to the total bank requires the user to look at the HUD.
*   **Solution:** When a coin particle completes its animation, trigger a brief, subtle "pulse" or "glow" on the total coin counter in the `CozyActionsOverlay`. (The `PulseNotifier` in the quiz header is a good start; extend this to the main room HUD).
*   **Rationale:** Reinforces the reward loop and makes earning feel more tangible.

**3.2 "Focus Mode" for Quizzes**
*   **Issue:** The `FloatingMedicalIcons` background on the `QuizSessionScreen` might become distracting during difficult questions.
*   **Solution:** Introduce a "Deep Focus" toggle within the quiz interface that fades out the floating background icons and mutes non-essential UI elements, leaving only the question, answers, and progress bar.
*   **Rationale:** Respects the primary goal of the application (learning) by allowing users to minimize visual noise when needed.

---

## Domain Strategy

**Recommendation: Single Domain (`arbormed.app` or similar)**

Given that ArborMed is primarily an application (Flutter Web) with a connected backend, a single unified domain strategy is recommended.

*   **`arbormed.app`** (Root): A marketing landing page explaining the benefits, the "Cozy Competence" philosophy, and showcasing the mobile app.
*   **`app.arbormed.app`** (Subdomain): The deployed Flutter Web application (the student experience).
*   **`api.arbormed.app`** (Subdomain): The Node.js/Express backend API endpoint.
*   **`admin.arbormed.app`** (Subdomain): The Next.js `prof-dashboard` for content management.

**Rationale:** This structure clearly separates marketing from the application payload, allowing the marketing site to be SEO-optimized (e.g., using Next.js or Astro) while the heavy Flutter Web app lives on its own subdomain.

---

## Proposed New Features

1.  **"Study Lo-Fi" Audio Player:** Integrate an ambient, lo-fi medical-themed audio track player directly into the `RoomWidget` and `QuizSessionScreen` (extending `AudioProvider`). Users can unlock new tracks via the Shop.
2.  **Pomodoro Integration:** Add an optional Pomodoro timer to the HUD. Users earn bonus XP/Coins for completing uninterrupted 25-minute study blocks, reinforcing healthy study habits.
3.  **Collaborative Clinics (Guilds/Study Groups):** Expand the `SocialProvider` to allow groups of students to pool resources and upgrade a shared "Hospital Wing," encouraging long-term retention and social accountability.
4.  **"Daily Shift" Quests:** Replace generic quests with themed "Daily Shifts" (e.g., "Cardiology Consult: Answer 15 Cardio questions correctly"). Completing a shift grants a unique visual badge or rare furniture item.