# Plan: Update README.md

## Overview
Update the `README.md` to reflect the current state of the project. The project has evolved to support Web (via Flutter Web/Netlify) and now includes distinct `content-engine` and `design-system` components that need documentation.

## Project Type
- **MOBILE** (Flutter)
- **WEB** (Flutter Web)
- **BACKEND** (Node.js)

## Success Criteria
1.  **Web Support**: Clearly stated as a supported platform with deployment details (Netlify).
2.  **New Components**: `content-engine` and `design-system` are documented in the Architecture section.
3.  **Command Updates**: "Getting Started" includes instructions for running the Web version.
4.  **Accuracy**: "Medical Cases" feature is NOT invited yet.

## File Structure

```text
README.md  <-- TARGET
```

## Tech Stack
-   **Mobile/Web**: Flutter 3.x
-   **Backend**: Node.js + Express + Supabase
-   **Content Engine**: Node.js
-   **Tools**: Python

## Task Breakdown

### 1. Update Introduction & Vision
-   [ ] Update "Cross-platform" to explicitly mention **Mobile + Web + Desktop**.
-   [ ] Ensure "Medical Cases" is **NOT** mentioned.

### 2. Update Architecture Section
-   [ ] Add **Content Engine**: Describe it as a Node.js tool for managing medical content (questions/data).
-   [ ] Add **Design System**: Describe the modular design assets (`medbuddy`, `medbuddy-quiz`, etc.).
-   [ ] Update **Technical Architecture** to include `Flutter Web` specifics if any (e.g., specific renderers).

### 3. Update Getting Started (Web)
-   [ ] Add `Flutter Web` running instructions:
    ```bash
    flutter run -d chrome
    ```
-   [ ] Mention Netlify deployment workflow (briefly).

### 4. General Maintenance
-   [ ] Review for outdated terms or file paths.
-   [ ] standard maintenance check.

## Phase X: Verification
-   [ ] **Visual Check**: Read the final README to ensure flow and clarity.
-   [ ] **Command Check**: Verify `flutter run -d chrome` works (if env allows, otherwise assume standard).
