# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is an innovative medical education platform that successfully merges rigorous clinical learning with a relaxing "Cozy Competence" aesthetic. By integrating gamified study sessions, an interactive isometric virtual room, and a thoughtful pastel palette (Sage Green `#8CAA8C`, Warm Clay `#C48B76`), the application proactively combats medical student burnout.

While the foundation built in Flutter is robust and visually appealing, our comprehensive audit reveals key opportunities to streamline the user experience. The current implementation heavily relies on immersive 3D/isometric elements (via `RoomWidget`) and modal overlays (`ContextualShopSheet`, `ClinicDirectorySheet`), which occasionally introduce cognitive friction during intense study tasks or straightforward navigation.

Our core recommendation centers on a **Refinement Strategy**. By decoupling the visually heavy 3D elements from high-focus areas (like the `QuizSessionScreen`), establishing a persistent global HUD for immediate navigation, and unifying the tactile/audio feedback system (`CozyHaptics`, `AudioProvider`), ArborMed can transform from a beautifully complex application into a seamlessly intuitive learning ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Evaluating against Nielsen's 10 Usability Heuristics highlights specific strengths and pain points:

*   **Visibility of System Status:**
    *   *Strengths:* Dynamic updates to gamified elements provide excellent positive reinforcement.
    *   *Weaknesses:* Background synchronization or heavy local database (`Drift`) operations during transitions (e.g., `QuizLoadingScreen`) lack granular visual feedback, occasionally causing the app to feel unresponsive.
*   **Match Between System and Real World:**
    *   *Strengths:* The nomenclature (e.g., "Medical Supply Cabinet", earning "Stethoscopes") creates a highly relatable and enjoyable environment for medical students.
*   **User Control and Freedom:**
    *   *Weaknesses:* The heavy reliance on modal bottom sheets (like `ClinicDirectorySheet`) limits deep linking and forces users to continuously dismiss overlays to return to the main hub.
*   **Consistency and Standards:**
    *   *Weaknesses:* There is a visible dichotomy between standard 2D Flutter routing and the 3D interaction model of the `RoomWidget`. Users must sometimes physically pan a 3D room to access settings, which breaks standard mobile navigation paradigms.
*   **Aesthetic and Minimalist Design:**
    *   *Weaknesses:* The isometric room, while stunning, remains active and visible behind high-cognitive-load screens (like the `QuizFeedbackOverlay`). This layered approach introduces visual clutter and unnecessary computational overhead during critical learning moments.

### 2.2 Content and Architecture
*   **Information Architecture (IA):** The current IA is slightly buried. Core actions like navigation require navigating through the 3D hub or opening specific sheets. A flatter hierarchy for primary actions is needed.
*   **Content Organization:** Within the `QuizSessionScreen`, the content layout is generally strong. However, success states (e.g., `ConfettiOverlay`, `CoinParticle`) occasionally obstruct the educational explanations displayed in the `QuizFeedbackOverlay`, forcing the user to wait for animations to finish before reviewing their mistakes.

### 2.3 Visual Design
*   **Color & Typography:** The implementation of the "Cozy Competence" palette (`#8CAA8C`, `#F4F1ED`, `#D2B48C`, `#C48B76`) is highly effective and consistently applied via `cozy_theme.dart`. The use of `GoogleFonts.figtree` ensures excellent readability across diverse device sizes.
*   **Interactivity & Feedback:** The application boasts a custom `CozyButton` with built-in squish animations and integrations with `CozyHaptics` and `AudioProvider`. However, standard Flutter widgets (like standard ListTiles in settings) do not consistently inherit these custom interactions, leading to a fragmented tactile experience.

## 3. Recommendations (Refine Strategy)

We recommend a targeted **Refinement Strategy** focused on reducing cognitive load during study and flattening the navigation hierarchy, without sacrificing the beloved "Cozy Competence" aesthetic.

### 3.1 Prioritized Recommendations

**High Priority: Implement a "Focus Mode" for Quiz Sessions**
*   **Issue:** Running the complex `RoomWidget` in the background of the `QuizSessionScreen` increases visual noise, distracts from the clinical stem, and drains mobile battery.
*   **Solution:** Introduce a distinct transition when entering a quiz. The 3D room should fade out, replaced by a solid, calming background. The `RoomWidget` should be explicitly paused/unloaded from the widget tree.
*   **Rationale:** Reduces cognitive overload. Medical board questions require intense concentration; the UI must support, not compete with, this focus state.

**High Priority: Centralized, Persistent Global HUD**
*   **Issue:** Relying on physical 3D panning or contextual sheets (`ContextualShopSheet`, `ClinicDirectorySheet`) for core navigation is inefficient for daily power users.
*   **Solution:** Implement a persistent, collapsible 2D Bottom Navigation Bar or global HUD floating above the `RoomWidget`. This HUD should contain quick-access icons for: Dashboard/Room, Study/Quizzes, Shop, and Profile/Analytics.
*   **Rationale:** Balances the immersive gamification of the 3D room with the pragmatic need for standard, fast mobile navigation.

**Medium Priority: Unify Tactile and Audio Feedback**
*   **Issue:** The delightful squish, haptic (`CozyHaptics.lightTap()`), and audio (`AudioProvider`) feedback of the `CozyButton` is not universally applied to all interactive elements.
*   **Solution:** Conduct a codebase-wide audit of `GestureDetector` and `InkWell` widgets. Abstract the interaction logic from `CozyButton` into a reusable `CozyPressable` wrapper, ensuring every tap in the app yields the same satisfying feedback.
*   **Rationale:** Consistency in micro-interactions is crucial for premium app feel and reinforcing the "Cozy" brand identity.

**Low Priority: Streamline Animation Overlays in Quizzes**
*   **Issue:** `ConfettiOverlay` and `CoinParticle` animations occasionally block the crucial `QuizFeedbackOverlay` text.
*   **Solution:** Confine celebratory animations to the top 20% of the screen or route them behind the feedback modal. Ensure that the explanation text is always immediately readable upon answering.
*   **Rationale:** Prioritizes learning efficiency over gamification flair during the review phase.

## 4. Domain Strategy

*   **Current State:** The backend operates as a Node.js/PostgreSQL API, serving the Flutter client across multiple platforms.
*   **Recommendation:**
    *   **Primary Domain (`arbormed.app`):** Serve the marketing landing page and the Flutter Web build directly from the root domain to maximize user acquisition and frictionless onboarding.
    *   **API Subdomain (`api.arbormed.app`):** Dedicate this to the Node.js backend and Socket.IO servers to allow for independent scaling of the game logic and real-time multiplayer features.
    *   **Admin Subdomain (`admin.arbormed.app`):** Host the `AdminResponsiveShell` here. Isolating the administrative and content management tools enhances security and allows for a separate, un-gamified UI specifically tailored for educators and data entry.

## 5. New Features

1.  **"On-Call" Pomodoro Timer (Focus Tool):**
    *   Integrate a study timer directly into the HUD. Activating "On-Call" mode dims the isometric room lighting to an evening aesthetic, starts playing lo-fi ambient tracks via the `AudioProvider`, and disables non-essential notifications (like friend requests).
2.  **The "Morbidity & Mortality" (M&M) Review Room:**
    *   Rather than a standard list view for reviewing missed questions, create a specific interactive object in the user's 3D room (e.g., a dusty filing cabinet or a specialized "Review Desk"). Clicking this object launches a focused session targeting only previously failed questions, turning mistake review into a tactile, spatial activity.
3.  **Collaborative "Grand Rounds" (Multiplayer Study):**
    *   Leverage the existing Socket.IO infrastructure used for PvP duels to create a cooperative mode. Users can invite friends to their isometric room. Once gathered, they can initiate a "Grand Rounds" session where they collectively answer challenging clinical cases, sharing the Stethoscope rewards if the group achieves a passing consensus.
