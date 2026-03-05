# UI/UX Audit Report: ArborMed

## Executive Summary
**ArborMed** is a cross-platform gamified medical education application. Its primary goal is to lower student anxiety while maintaining rigorous academic standards through a "Cozy Competence" approach. The core loop involves studying (via adaptive quizzes), earning rewards (Stethoscopes/Coins), and building/customizing a personal virtual clinic.

This audit evaluates the current state of the application's UI/UX, focusing primarily on the Flutter-based `student_app` and providing a foundational strategy for the currently unbuilt `prof-dashboard` (Next.js web app).

The overall visual design in `student_app` successfully achieves its "cozy" mandate through soft color palettes (Sage Green, Soft Clay, Ivory Cream), playful isometric graphics, and satisfying micro-interactions (confetti, haptics, "liquid" buttons). However, there are areas where usability, information architecture, and accessibility can be refined to better serve the high-stress target demographic.

## Analysis

### 1. Heuristic Evaluation (Nielsen's 10 Usability Heuristics)
*   **Visibility of System Status:**
    *   *Strengths:* The `QuizSessionScreen` effectively uses a `CozyProgressBar` and particle effects to show progress. The `RoomScreen` clearly shows placed vs. unplaced items.
    *   *Weaknesses:* Background sync status (local-first architecture) is not always visible to the user.
*   **Match Between System and Real World:**
    *   *Strengths:* The "Medical Supply Dispatch Terminal" (Shop) and terminology like "Stethoscopes" for currency map well to the medical theme.
*   **User Control and Freedom:**
    *   *Weaknesses:* The quiz flow (`QuizBody`) heavily relies on auto-submission for single-choice questions. While efficient, an accidental tap cannot be undone easily before the next question loads, potentially frustrating users on a streak.
*   **Consistency and Standards:**
    *   *Strengths:* `CozyTheme` enforces a strict, consistent visual language across buttons (`CozyButton`, `LiquidButton`), panels (`CozyPanel`), and typography (`Figtree`, `NotoSans`).
*   **Error Prevention:**
    *   *Weaknesses:* In the `ShopScreen`, buying an item currently deducts coins immediately. A confirmation step for high-value items could prevent buyer's remorse.
*   **Aesthetic and Minimalist Design:**
    *   *Strengths:* The UI is generally clean, avoiding the cluttered "firehose" feel typical of medical apps.

### 2. Content and Architecture Analysis
*   **Student App:** The primary navigation model relies on modal/overlay transitions from a persistent `RoomScreen` background. This is immersive but can make accessing secondary features (like stats or settings) feel buried if not carefully placed on the main HUD.
*   **Professor Dashboard:** Currently non-existent. The architecture needs to prioritize high-density data visualization (student performance, cohort analytics) over gamification.

### 3. Visual Design Analysis
*   **Color Palette:** The shift from stark hospital whites/blues to warm earth tones (Ivory, Sage, Clay) is highly effective for anxiety reduction.
*   **Typography:** The pairing of `Figtree` (geometric, friendly headers) and `Noto Sans` (highly legible body text for complex medical terms) is an excellent choice.
*   **Components:** The `LiquidButton` and `CozyButton` implementations show strong attention to detail with custom drop shadows, scaled squish animations, and integrated haptic feedback.

## Recommendations

### Student App Refinements

1.  **Quiz Interaction: Reversible Auto-Submit**
    *   *Issue:* Auto-submitting single-choice questions can lead to frustrating accidental errors, breaking streaks.
    *   *Solution:* Implement a subtle "Undo" toast or a very brief delay (e.g., 500ms) with a visual countdown before the answer is locked in, allowing the user to change their mind.
    *   *Rationale:* Reduces anxiety around "fat-fingering" an answer.

2.  **Shop Interface: Purchase Confirmation & Preview**
    *   *Issue:* Immediate deduction of currency upon tapping "Buy" in `ShopScreen`.
    *   *Solution:* Add a small confirmation dialog for items costing over a certain threshold. Allow users to "preview" how an item looks in their room before buying.
    *   *Rationale:* Enhances user control and error prevention.

3.  **Accessibility: Contrast and Text Sizing**
    *   *Issue:* While the palette is cozy, low-contrast combinations (e.g., soft gray on ivory) might be difficult for visually impaired users.
    *   *Solution:* Ensure all critical text meets WCAG AA contrast ratios. Ensure the app respects the OS-level "Larger Text" settings, particularly for long clinical vignettes.
    *   *Rationale:* Medical students study in various lighting conditions (e.g., bright wards, dark call rooms); high accessibility is critical.

### Professor Dashboard Strategy (Next.js)

Since the `prof-dashboard` is currently a placeholder, here is a strategic proposal for its UI/UX:

1.  **Design Language: "Clinical Clarity"**
    *   *Concept:* While the student app is "cozy", the professor dashboard should be "professional but approachable".
    *   *Execution:* Retain the ArborMed typography (`Figtree`/`Noto Sans`) and brand colors (Sage green for accents), but use a cleaner, higher-density layout suitable for desktop data analysis. Avoid heavy gamification elements (no isometric rooms).

2.  **Key Views:**
    *   **Cohort Overview:** A dashboard showing overall class mastery levels across different topics (e.g., Haematology, Cardiology) using heatmaps or bar charts.
    *   **Student Drill-Down:** Detailed view of individual student performance, highlighting areas where they are stuck (based on the SM-2 algorithm data).
    *   **Content Manager:** An interface to add/edit questions, utilizing the existing Bloom's Taxonomy structure. Needs clear WYSIWYG editors for medical imagery (ECGs, X-rays).

## Domain Strategy

*   **Recommendation:** Use a subdomain approach.
    *   `app.arbormed.com` (or similar) for the web build of the `student_app`.
    *   `admin.arbormed.com` or `faculty.arbormed.com` for the `prof-dashboard`.
*   *Rationale:* The audiences and tech stacks (Flutter Web vs. Next.js) are completely distinct. Subdomains allow for independent scaling, deployment, and distinct authentication flows (e.g., SSO for faculty vs. standard auth for students).

## New Features

1.  **"Study Groups" (Co-op Mode)**
    *   *Concept:* While "Duel Mode" exists for PvP, introduce a cooperative mode where students pool their knowledge to diagnose complex, multi-step clinical cases together.
    *   *UX Impact:* Fosters collaboration and reduces isolation, aligning with the "cozy" ethos better than pure competition.

2.  **Ambient Study Timer (Pomodoro integration)**
    *   *Concept:* Integrate a Pomodoro-style timer directly into the `RoomScreen`. While the timer runs, the isometric avatar appears to be studying, and ambient lo-fi medical sounds (like a gentle heart monitor or quiet clinic hum) play.
    *   *UX Impact:* Encourages healthy study habits and leverages the existing "cozy" environment as a focus tool, not just a game.
