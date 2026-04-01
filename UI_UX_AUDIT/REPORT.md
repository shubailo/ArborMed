# UI/UX Audit Report: ArborMed

## Executive Summary

This report provides a comprehensive UI/UX analysis of **ArborMed**, a gamified medical education platform designed for medical students. The application utilizes a "Cozy Competence" isometric aesthetic, blending clinical learning (via quizzes and adaptive learning paths) with progression mechanics such as a medical supply shop and customizable clinic rooms.

Overall, the visual design successfully establishes a calm, welcoming environment. However, there are significant opportunities to improve usability, accessibility, and feedback mechanisms. Key recommendations focus on improving visual contrast, refining the quiz experience for better state communication, optimizing the shop layout for readability, and enhancing the visibility of core gamification elements (e.g., the Research Grant Progress Bar).

---

## 1. Analysis

### 1.1 Heuristic Evaluation
Based on Nielsen's 10 Usability Heuristics, the following observations were made:

*   **Visibility of System Status (Score: 3/5):**
    *   *Observation:* The progress bars (e.g., "Level Progress" in quizzes) are present, but their contrast is extremely low against the background, making it hard to read the current state quickly.
    *   *Observation:* Gamification tracking (coins and XP) lacks clear, immediate feedback when earned.
*   **Match Between System and Real World (Score: 5/5):**
    *   *Observation:* The use of medical-themed terminology (e.g., "Research Grants," "Clinical Supply Crates") and iconography (stethoscopes, EKGs) effectively matches the target audience's mental model.
*   **User Control and Freedom (Score: 4/5):**
    *   *Observation:* Navigation between screens (Profile, Activity, Shop) is generally clear, but exiting the quiz screen (the "X" icon) could be made more prominent.
*   **Consistency and Standards (Score: 4/5):**
    *   *Observation:* The isometric aesthetic and cozy color palette are consistently applied across the Dashboard, Shop, and Profile.
    *   *Observation:* Button styling (pill-shaped) is consistent, though the "disabled" vs "enabled" states need stronger visual differentiation.
*   **Error Prevention & Recovery (Score: 3/5):**
    *   *Observation:* In quizzes, it's not immediately clear how a wrong answer affects the overall session (e.g., the future "Heart/Stamina" system needs clear upfront UI indicating remaining attempts).
*   **Recognition Rather Than Recall (Score: 4/5):**
    *   *Observation:* The Shop screen visually displays the items clearly, reducing the need to remember item names.
*   **Aesthetic and Minimalist Design (Score: 4.5/5):**
    *   *Observation:* The "cozy" aesthetic is well-executed, avoiding cluttered interfaces and keeping cognitive load manageable.

### 1.2 Content and Architecture Analysis
*   **Information Architecture:** The division of sections (Quiz/Study, Profile/Social, Shop/Customization) is logical. The `student_app` orchestrates these modules cleanly.
*   **Hierarchy:** The Profile screen has good hierarchy, highlighting the User, Level/XP, and actions. However, the Quiz screen's hierarchy slightly buries the topic ("Cardiovascular System") compared to the question text.

### 1.3 Visual Design Analysis
*   **Color Palette:** The soft, earthy tones (creams, muted greens, soft blues) are excellent for reducing study anxiety.
*   **Typography:** The font choices are friendly and readable, but the weight/color of secondary text (like the $0$ counters for coins/XP) suffers from poor contrast against the cream/grey backgrounds.
*   **Iconography:** The icons (stethoscope for coins, fire for streaks) are thematic and easily recognizable.

---

## 2. Recommendations

### 2.1 Improve Contrast and Accessibility
*   **Issue:** The top status bar items (Coins, XP, and Level Progress) use a light grey/beige color on a slightly lighter background. This fails WCAG accessibility guidelines for contrast.
*   **Proposed Solution:** Darken the text and icon colors for the currency counters. Add a subtle shadow or a slightly darker pill background to make them pop out from the main screen background.
*   **Rationale:** Users need to effortlessly track their progression metrics, especially in a gamified environment where these metrics are the primary reward.

### 2.2 Enhance Quiz State Feedback
*   **Issue:** In the quiz screen, the True/False buttons have identical styling. When a user selects an answer, the feedback loop (correct vs incorrect) needs to be instantaneous and visually distinct.
*   **Proposed Solution:** Implement clear color-coding for selected states (e.g., turning the button a solid, darker thematic color upon selection, then flashing green/red for correct/incorrect before transitioning).
*   **Rationale:** Immediate, clear feedback is crucial for learning environments to reinforce knowledge and correct misconceptions without ambiguity.

### 2.3 Visualize Gamification Systems
*   **Issue:** The `economy_proposal.md` mentions a "Research Grant Progress Bar" to handle fractional coin earnings (soft cap). This critical gamification loop needs a clear visual representation.
*   **Proposed Solution:** Implement a small, circular progress indicator directly wrapping or adjacent to the Stethoscope (Coin) icon in the top header. As questions are answered, the ring fills up, pulsing when a full coin is granted.
*   **Rationale:** This visualizes progress during the "soft cap" phase, keeping the user motivated even when individual questions no longer yield a full coin.

### 2.4 Optimize Shop Interface Layout
*   **Issue:** The Shop currently displays items in an isometric view, but as the inventory grows (e.g., Seasonal Decors, Special Wards), finding specific items will become tedious.
*   **Proposed Solution:** Introduce categorical filtering (e.g., "Desks," "Decor," "Consumables," "Seasonal") in the Shop interface. For the "Clinical Supply Crates," ensure the animation for opening them is prominent and satisfying to justify the coin sink.
*   **Rationale:** Reduces cognitive load and makes navigating the primary coin sink easier for the user.

---

## 3. Domain Strategy

*   **Current State:** The application is a Flutter-based platform, currently conceptualized as a unified application.
*   **Recommendation:** Keep the application on a primary domain (e.g., `app.arbormed.com`) as a Single Page Application (SPA) / PWA for web users, while maintaining native mobile builds. The seamless transition between studying (quizzes) and playing (shop/customization) is critical; separating these onto different subdomains would disrupt the core gamification loop.

---

## 4. Proposed New Features

1.  **"Peer Review" Mode:** A social feature where students can view and "like" other players' decorated clinic rooms. Earning a "like" generates a small coin drip (as proposed in the economy doc), driving social engagement.
2.  **Study Analytics Dashboard:** A visual breakdown of performance by medical system (e.g., Cardiovascular vs. Respiratory) integrated into the Profile screen, helping students identify their weak areas.
3.  **Thematic "Ward" Expansions:** As players reach high levels, allow them to unlock and decorate entirely new room templates (e.g., an ER triage room or a pediatric ward) to act as a massive late-game coin sink.
4.  **Streak Protection "Equip":** A visual representation of the "Streak Freeze" item (from the economy doc) that the user can visibly "equip" on their profile, showing others they have a safety net active.