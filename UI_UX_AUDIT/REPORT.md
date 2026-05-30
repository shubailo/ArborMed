# ArborMed UI/UX Audit Report

## 1. Executive Summary

ArborMed is a high-fidelity medical education platform aiming to merge clinical rigor with "Cozy Competence" aesthetics to prevent medical student burnout. The current implementation utilizes Flutter for the frontend, bringing together study modes, deep gamification, and an interactive isometric "Room" system.

While the "Cozy Competence" system—featuring muted pastel palettes, robust typography (Figtree/Google Fonts), and a local-first architecture—provides an excellent base, the current user interface presents friction points. Complex interactive layers (such as the persistent isometric room behind quizzes and shops) risk overwhelming the core learning loop. Our audit indicates that a *refinement* strategy (as opposed to a full redesign) focusing on improved onboarding, visual hierarchy during learning sessions, and smoother micro-interactions will elevate the platform from a "quiz app with a room" to a truly cohesive educational ecosystem.

## 2. Analysis

### 2.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the app was evaluated against key learning journeys:

*   **Visibility of System Status:**
    *   *Positive:* Gamification elements like coins (Stethoscopes) and streaks update dynamically.
    *   *Negative:* When loading large question banks locally via `Drift`, the `QuizLoadingScreen` lacks sufficient granular progress communication, sometimes appearing frozen.
*   **Match Between System and Real World:**
    *   *Positive:* The "Medical Supply Dispatch Terminal" (Shop) and terminology ("Clinic") cleverly match the medical student reality while keeping it playful.
*   **Consistency and Standards:**
    *   *Negative:* The mixture of modal/overlay interactions vs. full-screen routing for the `RoomWidget` creates navigation confusion. For instance, the transition from Dashboard to Quiz sometimes layers heavy 3D elements behind the quiz, distracting from the cognitive load of studying.
*   **Aesthetic and Minimalist Design:**
    *   *Negative:* The isometric room (`room_screen.dart`), while central to the "Cozy Competence" theme, is computationally and visually heavy when running beneath intensive tasks like timed ECG practice or Duel Mode.

### 2.2 Content and Architecture
*   **Information Architecture:** The navigation heavily relies on contextual sheets (e.g., `ContextualShopSheet`, `ClinicDirectorySheet`) invoked from a 3D hub (`RoomWidget`). While immersive, it obscures direct paths to high-yield actions (like "Resume Last Study Session").
*   **Content Organization:** The Quiz interface correctly places the stem (question text) in prominent focus, but the answer option hit targets and feedback overlays (`QuizFeedbackOverlay`) occasionally overlap with floating decorative particles (`ConfettiOverlay`, `CoinParticle`), creating visual clutter during the crucial "learning from mistakes" phase.

### 2.3 Visual Design
*   **Color & Typography:** The pastel palette (Sage greens `#8CAA8C`, warm browns `#D2B48C`, creamy backgrounds `#F4F1ED`) strictly adheres to the "Cozy Competence" guidelines. The use of `GoogleFonts.figtree` is modern and readable.
*   **Interactivity:** Interactive elements lack sufficient tactile feedback natively. Although `CozyHaptics` and `AudioProvider` are integrated, their application is inconsistent across standard Flutter widgets like standard `ListTile` or `GestureDetector` that aren't wrapped in `CozyButton`.

## 3. Recommendations (Refine Strategy)

Given the strong foundation, a full redesign is unnecessary. The focus should be on *refining* the existing architecture.

### 3.1 Prioritized Recommendations

**High Priority: Decouple Study Mode from Isometric Room**
*   *Issue:* Running the 3D/Isometric `RoomWidget` behind the `QuizSessionScreen` increases visual noise and drains battery.
*   *Solution:* Implement a solid, themed background (e.g., `#F4F1ED` with subtle watermark patterns) for the Quiz Session. The room should pause or unload when entering a deep focus state.
*   *Rationale:* Reduces cognitive overload during high-stress activities (answering board-style questions).
*   *Reference:* See `WIREFRAMES/quiz_session.svg` for the focused layout.

**Medium Priority: Centralized Quick-Action HUD**
*   *Issue:* Users must pan around the 3D room to find specific modules (Shop, Friends, Settings).
*   *Solution:* Introduce a persistent, collapsible 2D HUD at the bottom of the `RoomWidget` containing quick-access icons to major app sections.
*   *Rationale:* Balances the immersive 3D exploration with the practical need for fast navigation.
*   *Reference:* See `WIREFRAMES/dashboard.svg` (Top Bar HUD & Side Actions).

**Medium Priority: Standardize Haptic & Audio Feedback**
*   *Issue:* Inconsistent application of `CozyHaptics` and audio cues across interactive elements.
*   *Solution:* Audit all `GestureDetector` and `InkWell` widgets in the app. Ensure any button or card that changes state triggers a `lightTap()` or `mediumTap()` along with the corresponding audio SFX.
*   *Rationale:* Essential for the "Cozy" tactile feel the brand promises.

**Low Priority: Refine "Shop" Empty States**
*   *Issue:* If the shop catalog fails to load (`_buildErrorView`), the error state is generic.
*   *Solution:* Add a themed illustration (e.g., a broken medical supply box) and a more playful copy ("Our supply truck got a flat tire! Re-fetch Storage").
*   *Rationale:* Maintains immersion even during technical failures.

## 4. Domain Strategy

*   **Current State:** The backend operates as an API, with Flutter handling the client side (Mobile/Web).
*   **Recommendation:**
    *   **Primary Domain:** `arbormed.app` (or similar) should serve as the marketing site and web app portal.
    *   **Subdomain Strategy:**
        *   `app.arbormed.com`: Host the Flutter Web build here for seamless browser access.
        *   `api.arbormed.com`: Host the Node.js/PostgreSQL backend here.
        *   `admin.arbormed.com`: Dedicate this subdomain to the `AdminResponsiveShell` to keep administrative traffic isolated and secure.

## 5. New Features

1.  **"Zen Mode" Study Timer:**
    *   Integrate a Pomodoro-style timer directly into the Study Dashboard. When activated, the isometric room lights dim, background lo-fi music starts, and notifications are muted.
2.  **Interactive "Review" Clinic:**
    *   Instead of a standard list for reviewing missed questions, populate a specific area of the user's room (e.g., a "Filing Cabinet") where they physically click to review past mistakes.
3.  **Collaborative Study Rooms (Social Extension):**
    *   Allow players to invite friends to their custom isometric room. While hanging out, they can trigger synchronous "Flashcard Marathons" using the existing Socket.IO duel infrastructure, but in a cooperative mode.
### 2.4 Error Prevention (Usability & Stability)
*   **Unsafe Iterable Lookups:** Throughout the application (e.g., in `screens/admin/questions_screen.dart`, `screens/admin/ecg_editor_dialog.dart`, and `features/shop/providers/shop_provider.dart`), there are numerous instances of using the `.firstWhere()` method on iterables without providing an `orElse` fallback.
    *   *Issue:* In Dart, if `.firstWhere()` fails to find a matching element and lacks an `orElse` callback, it throws a `StateError`. This can lead to unhandled exceptions and sudden UI crashes (e.g., if a requested diagnosis ID or topic slug is not found in the loaded data).

### 2.5 Accessibility (a11y)
*   **Missing Semantic Labels:** Many interactive, icon-only widgets across the application (particularly `IconButton` instances in admin screens like `admin_quotes_screen.dart` and `clinic_directory_sheet.dart`) lack the `tooltip` property.
    *   *Issue:* Without `tooltip`, these buttons lack semantic labels for screen readers and do not provide hover text for web/desktop users, degrading the experience for users with visual impairments or relying on mouse navigation.

---

### 3.2 Additional Recommendations (Expanded)

**High Priority: Audit and Implement Tooltips for IconButtons**
*   *Issue:* Lack of `tooltip` properties on `IconButton` widgets reduces accessibility.
*   *Solution:* Conduct a codebase-wide audit of all `IconButton` usages (especially in the `apps/student_app/lib/screens/admin/` and `features/social/` directories). Ensure every `IconButton` without an explicit text label includes a concise, localized `tooltip` property (e.g., `tooltip: "Edit Quote"`).
*   *Rationale:* Essential for screen reader support and improving hover interactions on web/desktop builds, ensuring compliance with basic accessibility standards.

**High Priority: Prevent Crashes from Unsafe Lookups**
*   *Issue:* Unsafe `.firstWhere()` lookups risk throwing `StateError` and crashing the UI.
*   *Solution:* Migrate all `.firstWhere()` calls that lack an `orElse` to use Dart 3's native `.firstOrNull` (or provide a safe `orElse` fallback). For example, change `stats.topics.firstWhere((topic) => ...)` to `stats.topics.where((topic) => ...).firstOrNull`.
*   *Rationale:* Graceful degradation is a core UX principle. Failing to find an item should result in a missing visual element or fallback UI, not a fatal app crash.

---

### 5. New Features (Continued)

4.  **"Focus Mode Analytics" Dashboard:**
    *   *Concept:* Introduce a dedicated section in the profile that visualizes the user's "deep work" metrics based on time spent in the new "Zen Mode" or "Quiz Session" (without the isometric room background).
    *   *Value:* Reinforces the "Cozy Competence" philosophy by rewarding focused, distraction-free study time, helping students track their resilience against burnout.
