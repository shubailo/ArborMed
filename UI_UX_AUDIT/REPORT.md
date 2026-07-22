# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed aims to be a next-generation medical education platform, offering "Cozy Competence" to reduce student burnout through a blend of clinical accuracy and relaxed aesthetics. The platform uses a Flutter frontend, providing offline-first learning via `Drift` and robust gamification powered by a Node.js/PostgreSQL backend with `Socket.IO` for real-time duels.

While the foundation is strong—benefiting from a consistent pastel color palette (Sage Green `#8CAA8C`, Soft Clay `#C48B76`, Ivory Cream `#FDFCF8`) and readable typography (`GoogleFonts.figtree`)—the current UI architecture suffers from cognitive overload. The interplay between the immersive isometric `RoomWidget` and high-focus study modes creates friction. Our audit recommends a strategic **refinement** rather than a full redesign. By decoupling the 3D exploration from the core quiz loop and standardizing micro-interactions (`CozyHaptics`), we can significantly improve usability and user retention.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, we assessed the core learning workflows:

*   **Visibility of System Status:**
    *   *Observation:* Gamification stats (streaks, coins) are highly visible. However, heavy local data loads (e.g., parsing large question banks via `Drift` in `QuizLoadingScreen`) lack detailed progress bars, leaving users uncertain if the app has frozen.
*   **Match Between System and Real World:**
    *   *Observation:* The platform excels here. Using terms like "Clinical" and metaphors like the "Medical Supply Cabinet" for the shop effectively bridges the gap between medical training and gamified learning.
*   **User Control and Freedom:**
    *   *Observation:* Users navigating deep into the `RoomWidget` via contextual sheets (like `ContextualShopSheet` or `ClinicDirectorySheet`) often find it difficult to quickly return to their primary task—studying. The navigation lacks a persistent "escape hatch" to the core study loop.
*   **Aesthetic and Minimalist Design:**
    *   *Observation:* The isometric room in `room_screen.dart` is charming but visually heavy. When layered beneath intensive tasks like ECG analysis (`ECGCase` challenges) or Duel Mode, it competes for the user's attention and increases cognitive load.

### 2.2 Content and Architecture
*   **Information Architecture (IA):** The current IA relies heavily on spatial navigation within the 3D `RoomWidget`. While this is engaging, it obscures direct paths to high-yield actions. A user wanting to simply "Resume Last Study Session" must hunt for the correct interaction point rather than having a clear, immediate call-to-action on launch.
*   **Content Organization:** During quizzes, the stem (question text) is appropriately emphasized. However, when feedback is presented (`QuizFeedbackOverlay`), it occasionally overlaps with celebratory animations (`ConfettiOverlay`, `CoinParticle`), creating a chaotic visual experience during a critical learning moment.

### 2.3 Visual Design
*   **Color & Typography:** The "Cozy Competence" palette (`#8CAA8C`, `#C48B76`, `#FDFCF8`) is well-executed and effectively reduces the stark, stressful feel of traditional medical software. `GoogleFonts.figtree` provides excellent readability across various screen sizes.
*   **Interactivity & Feedback:** There is a noticeable inconsistency in tactile feedback. While dedicated components like `CozyButton` utilize `CozyHaptics` and `AudioProvider` effectively, standard interactive widgets (like `ListTile` or raw `GestureDetector`s) do not, leading to an uneven user experience.

## 3. Recommendations (Refine Strategy)

A full redesign is **not recommended**, as the core aesthetics and gamification systems are well-aligned with the target audience. Instead, a targeted **refinement strategy** is advised.

### 3.1 Prioritized Recommendations

**High Priority: Isolate Focus Modes from the Isometric Hub**
*   *Issue:* The computational and visual weight of the `RoomWidget` distracts from core study tasks (`QuizSessionScreen`).
*   *Solution:* Transition users entirely out of the 3D room into a dedicated, clean 2D interface for studying. Use a solid `#FDFCF8` background with minimal distractions.
*   *Rationale:* Reduces cognitive overload during high-stress board prep, aligning with the "Cozy Competence" ethos.
*   *Reference:* See `WIREFRAMES/quiz_session.svg`.

**Medium Priority: Implement a Centralized Quick-Action HUD**
*   *Issue:* Spatial navigation within the `RoomWidget` is too slow for power users seeking immediate access to the shop or friends list.
*   *Solution:* Add a persistent, collapsible 2D HUD overlay at the bottom of the `RoomWidget` screen, offering direct links to the Shop, Settings, and Study Modes.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.
*   *Reference:* See `WIREFRAMES/dashboard.svg`.

**Medium Priority: Systematize Haptic and Audio Feedback**
*   *Issue:* Inconsistent interaction feedback breaks immersion.
*   *Solution:* Conduct a codebase-wide audit to ensure all interactive elements trigger appropriate `CozyHaptics.lightTap()` or `mediumTap()` and corresponding `AudioProvider` sound effects.
*   *Rationale:* Standardizing these micro-interactions reinforces the premium, tactile feel of the platform.

**Low Priority: Enhance Empty States in Contextual Sheets**
*   *Issue:* Error or empty states (e.g., `_buildErrorView` in the shop) are currently generic and break the themed experience.
*   *Solution:* Introduce custom illustrations (e.g., a delayed medical supply truck) and themed copy to maintain immersion even during connectivity or loading issues.
*   *Rationale:* Turns frustrating moments into delightful brand touchpoints.

## 4. Domain Strategy

*   **Current Architecture:** Flutter handles the cross-platform client (Mobile/Web), communicating with a Node.js/PostgreSQL backend.
*   **Proposed Structure:**
    *   **Primary Domain (`arbormed.app` or `arbormed.com`):** Should serve as the marketing landing page, highlighting features and driving conversions.
    *   **App Subdomain (`app.arbormed.com`):** Host the Flutter Web application here for frictionless browser-based access without requiring app store installation.
    *   **API Subdomain (`api.arbormed.com`):** Dedicated routing for the backend services.
    *   **Admin Subdomain (`admin.arbormed.com`):** Isolate the `AdminResponsiveShell` and content management systems here for enhanced security and access control.

## 5. New Features

1.  **"On-Call" Deep Focus Timer:**
    *   *Concept:* Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, it dims the `RoomWidget` lighting, starts ambient lo-fi medical beats via `AudioProvider`, and mutes non-critical notifications.
    *   *Value:* Directly supports the "burnout prevention" goal by encouraging structured, healthy study habits.
2.  **Spatial "Morbidity & Mortality" Review Board:**
    *   *Concept:* Instead of a flat list for reviewing missed questions, add a specific interactive object (like a whiteboard or filing cabinet) within the user's `RoomWidget`. Clicking it opens a dedicated review mode for past mistakes.
    *   *Value:* Deepens the gamification by tying learning outcomes to spatial objects in the user's customized environment.
3.  **Co-op Ward Rounds (Synchronous Social Study):**
    *   *Concept:* Leverage the existing `Socket.IO` duel infrastructure to create cooperative study sessions. Users can invite friends to their room, and they must collectively answer clinical vignettes to earn shared rewards.
    *   *Value:* Reduces the isolation of medical studying and fosters a supportive community.
