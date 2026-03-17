# Wireframe Outline: "Focus Mode" Quiz Interface

**Objective:** Provide a distraction-free, high-contrast study environment within the ArborMed app while maintaining the core "Cozy Competence" aesthetic.

## Screen Layout: `QuizSessionScreen` (Focus Mode Active)

**State:**
-   `isFocusMode = true`
-   Background animations (`FloatingMedicalIcons`) are **hidden** or **paused**.
-   The overall background color dims slightly (e.g., `#EFEBE9` -> `#D7CCC8` with a dark overlay) to increase contrast for the central content.

### Header (Top 15%)
*   **Left:** A subtle "Exit" (`X`) icon.
*   **Center:** A clean, horizontal Progress Bar (`CozyProgressBar`). No pulsing or decorative elements. The text indicates `Question 5 of 20`.
*   **Right:** A "Focus Mode" toggle switch (currently ON). The icon is a simple eye (`Icons.visibility_off_outlined`) or a moon.

### Content Area (Middle 70%)
*   **Main Card:** A single, large, high-contrast card (`paperWhite` background, `shadowSmall`).
*   **Question Text:** Large, legible typography (`displayMedium`, `Figtree`). The text color is deep brown (`#3E2723`).
*   **Options:** Vertical list of buttons.
    *   **State: Default:** Light gray/cream background with dark text. No borders.
    *   **State: Hover/Focus:** Slight elevation, border color shifts to `Sage Green` (`primary`).
    *   **State: Selected:** Background changes to a very pale green, border becomes solid `primary`.
*   *(Crucial change for Focus Mode: Animations for selecting/submitting an answer are fast and functional, not playful.)*

### Footer / Action Area (Bottom 15%)
*   **Center/Right:** A prominent, pill-shaped "Submit" or "Next" button.
    *   The button color is `primary` (Sage Green).
    *   Text is bold white (`labelLarge`, `Figtree`).
*   **Feedback (Post-Submission):** If correct, a minimal green checkmark appears briefly next to the button. If incorrect, a red 'X'.
    *   *No confetti or coin explosions in Focus Mode.*
    *   The UI prioritizes speed over celebration.

## Key Interactions

1.  **Toggle Focus Mode:** Pressing the toggle in the header smoothly transitions between the standard, playful UI (with floating icons, confetti, etc.) and this stripped-down, high-contrast view.
2.  **Keyboard Navigation:** Continues to function (Spacebar to submit/next). The focus state on the buttons must be highly visible (e.g., a solid outline) in Focus Mode.
3.  **Result State:** When the user completes the quiz, the app should automatically transition back out of Focus Mode to display the results screen and celebrate their earnings. Focus Mode is purely for the active testing phase.