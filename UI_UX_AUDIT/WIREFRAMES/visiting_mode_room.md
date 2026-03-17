# Wireframe Outline: "Room Hub" (Improved Social Indication)

**Objective:** Clearly delineate when the user is visiting another student's "Clinic" versus their own, avoiding mode confusion.

## Screen Layout: `RoomWidget` (Visiting Mode Active)

**State:**
-   `isVisiting = true`
-   The user is viewing the isometric room of another player.

### Overlay / Border
*   **Aesthetic Border:** Instead of just a badge, a subtle, themed border surrounds the entire screen. For example, a soft, semi-transparent gold or "medical blue" line (e.g., `#64B5F6`, `alpha: 0.15`). This provides immediate, peripheral context that the user is "elsewhere."

### Top-Left (Social Badge)
*   **Badge Design:** A pill-shaped container, elevated (`shadowMedium`), anchored to the top-left corner.
*   **Content:**
    *   **Icon:** A small avatar icon or "medical cross" (`Icons.medical_services_outlined`).
    *   **Text:** "Visiting Dr. [Name]" (Bold, `Figtree`, White text).
    *   **Background Color:** `primary` (Sage Green) or a distinct "Social" color to contrast with the room background.

### Top-Right (Actions)
*   **"Return Home" Button:** A prominent button.
    *   **Icon:** `Icons.home_rounded`
    *   **Text:** "Go Back"
    *   **Style:** `CozyButtonVariant.primary` (Solid fill).
    *   **Action:** Triggers `social.stopVisiting(context)` and pans the camera back to the user's room coordinates or loads their instance.

### Center/Room (The Iso Metric View)
*   **Interaction Restrictions:**
    *   The "Decorate" or "Shop" UI is completely hidden or visually disabled (grayed out).
    *   Tapping on furniture does *not* open the `ContextualShopSheet`.
    *   The user's own Avatar (`BeanWidget`) is either absent or rendered differently (e.g., as a smaller "guest" icon) to emphasize they are visiting.

### Bottom/Footer (Social Actions)
*   **"Leave a Note" (Consultation):** A clearly labeled button (replacing the "Start Quiz" button).
    *   **Icon:** `Icons.note_add_outlined`
    *   **Text:** "Consultation"
    *   **Style:** A distinct color (e.g., the `accent` color - Soft Clay) to draw attention to the social feature.
    *   **Action:** Opens the "Leave a Note" dialog (`_showLeaveNoteDialog`).
*   **"Like" or "Kudos":** A smaller, secondary button next to the "Leave a Note" button.
    *   **Icon:** `Icons.thumb_up_outlined` (turns solid when liked).
    *   **Action:** Triggers `social.likeRoom`.

## Key Interactions

1.  **Entering Visiting Mode:** When tapping a user from the `ClinicDirectorySheet`, the transition should be distinct. A brief "Traveling to [Name]'s Clinic..." loading screen or a sweeping camera pan creates the mental model of movement.
2.  **Leaving Visiting Mode:** Pressing "Return Home" smoothly transitions the user back to their own fully interactive space, removing the borders and restoring the Shop/Quiz UI.
3.  **Social Affordances:** The "Consultation" and "Like" buttons should be the primary calls to action at the bottom of the screen, replacing the core loop (Quiz/Decorate) actions.