# UI/UX Audit Report: ArborMed

## Executive Summary
ArborMed is a medical education platform that successfully blends clinical rigor with a "Cozy Competence" design philosophy. The current UI employs a soothing pastel palette, isometric 3D illustrations, and clean typography to reduce the cognitive load associated with rigorous medical studying. While the visual aesthetic is highly polished and cohesive, there are opportunities to improve accessibility, clarity of navigation, and overall usability—particularly regarding interactive elements within the dashboard and shop interfaces.

## Analysis

### 1. Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the application was evaluated as follows:

*   **Visibility of System Status:** The app does a good job showing the user's currency (stethoscopes) and streak (fire icon) prominently on the dashboard. However, when placing furniture in the room (as seen in `shop.png`), the system status (e.g., "Equipping Mode Active") could be clearer beyond just the "Done Equipping" button.
*   **Match Between System and Real World:** The use of a virtual clinic and medical equipment (stethoscopes for currency, doctor's bag for inventory) aligns perfectly with the target audience's mental model.
*   **Consistency and Standards:** The color palette (sage greens, creamy backgrounds, warm browns) and typography (rounded sans-serif, all-caps headers) are consistent across the login, dashboard, and shop screens.
*   **Recognition Rather Than Recall:** On the dashboard, several icons (telephone, ID badge, doctor's bag, gear) are used without text labels. This relies heavily on recall. Users might struggle to remember the function of each icon without interacting with it.
*   **Aesthetic and Minimalist Design:** The UI is clean and avoids clutter. The minimalist approach supports the "Cozy Competence" goal of preventing burnout. However, the faint background watermark icons in the shop view slightly detract from the minimalist focus.

### 2. Content and Architecture Analysis
*   **Login Screen:** The information hierarchy is clear and logical. The path to log in, recover a password, or create an account is straightforward.
*   **Dashboard:** The central focus is the isometric room, which serves as a personalized hub. The primary action ("Start Session") is well-placed and visually distinct. Secondary actions are arranged around the periphery.
*   **Shop/Equip Screen:** The space prioritizes the visual representation of the room. The layout of the isometric grid is effective for placing items.

### 3. Visual Design Analysis
*   **Color Palette:** Excellent use of muted pastels. The sage green (`#88A586` roughly) used for primary buttons provides good contrast against the creamy background and evokes a calming, organic feel.
*   **Typography:** The rounded sans-serif font (Figtree/Google Fonts) is friendly and readable. The letter-spaced, all-caps styling on buttons ("START SESSION", "DONE EQUIPPING") adds a touch of modern professionalism.
*   **Imagery:** The 3D isometric models are high quality and consistent in style, reinforcing the gamified aspect of the platform.
*   **Accessibility:**
    *   Contrast on secondary text links like "Forgot Password?" and "Create One" on the login screen appears slightly low against the background and should be verified against WCAG AA standards.
    *   The use of `Tooltip` for interactive elements (e.g., the buddy avatar) can be intrusive on mobile devices.

## Recommendations

### 1. Enhance Dashboard Navigation Clarity
*   **Issue:** The bottom navigation icons on the dashboard (telephone, ID badge, doctor's bag, gear) lack text labels, making their purpose ambiguous to new users.
*   **Solution:** Add subtle, clear text labels beneath or next to each icon. Alternatively, use a more standard bottom navigation bar with integrated icons and text.
*   **Rationale:** Improves recognition over recall and reduces the cognitive friction of guessing what a button does.

### 2. Improve Interactive Element Accessibility (Code Level)
*   **Issue:** The codebase currently uses `Tooltip` for wrapping some interactive widgets (like the buddy avatar), which isn't ideal for mobile touch interfaces and can interfere with screen readers.
*   **Solution:** Replace `Tooltip` wrappers on purely visual interactive elements (like `GestureDetector`) with `Semantics(button: true, label: '...')`. Ensure all icon-only buttons (like `IconButton`) have explicitly defined `tooltip` properties for screen reader accessibility.
*   **Rationale:** Aligns with standard Flutter accessibility best practices for mobile and web applications, ensuring the app is usable by all students.

### 3. Refine the Shop / Edit Mode Interface
*   **Issue:** The "Done Equipping" screen (`shop.png`) features faint background watermark icons that add visual noise without providing utility.
*   **Solution:** Remove the background watermark icons during "Edit/Equip" mode to keep the focus entirely on the isometric room and the items being placed.
*   **Rationale:** Reduces visual clutter and adheres strictly to the minimalist "Cozy Competence" aesthetic.

### 4. Adjust Login Screen Contrast
*   **Issue:** The "Forgot Password?" and "Create One" text links may fall below the 4.5:1 contrast ratio requirement against the light background.
*   **Solution:** Darken the text color for these links slightly, or add an underline to clearly indicate they are interactive links, even if color perception is diminished.
*   **Rationale:** Ensures WCAG accessibility compliance for users with visual impairments.

## Domain Strategy
Given that ArborMed is an integrated platform with both a student app (Flutter) and a professor dashboard (Next.js), a unified domain strategy is recommended:
*   **Main Landing Page:** `arbormed.com` (Marketing, features, sign up)
*   **Student App (Web version):** `app.arbormed.com` (Hosts the Flutter Web build)
*   **Professor Dashboard:** `prof.arbormed.com` or `admin.arbormed.com` (Hosts the Next.js app)
*   **Backend API:** `api.arbormed.com`
This subdomain structure clearly separates the different user contexts while maintaining a strong, cohesive brand identity.

## Proposed New Features

1.  **"Focus Mode" Dashboard Toggle:** A quick toggle that hides all UI elements (currency, streak, secondary buttons) except the isometric room and the "Start Session" button, allowing for distraction-free preparation before a study session.
2.  **Interactive Room Elements:** Beyond just placing furniture, allow users to tap on placed items for functional shortcuts (e.g., tapping the bookshelf opens a "Study History" or "Library" view; tapping the calendar opens a "Study Schedule"). This deepens the integration between the gamified room and the educational tools.
3.  **Dynamic Ambient Lighting:** Shift the lighting of the isometric room based on the user's local time (e.g., warm sunset tones in the evening, bright crisp light in the morning) to enhance the atmospheric "Cozy" feel and reduce eye strain at night.