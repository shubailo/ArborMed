# PLAN-smart-shop
> **Status**: DRAFT
> **Goal**: Implement "Contextual Preview" Shop & "Smart" Decor Features
> **Dependencies**: `PLAN-gamification-ui-logic` (Basic Shop exists).

## 1. Overview
We are transforming the Shop from a separate list into an immersive **"Decorator Mode"**.
1.  **Contextual Trigger**: Tapping a (+) on a slot opens a curated window for *that* specific spot.
2.  **Preview First**: Tapping an item "ghosts" it into the room. User confirms to buy/place.
3.  **Smart Features**: Items have "Themes" (Sets) and "Unlock Requirements" (Mastery).

## 2. Architecture Changes

### Backend (PostgreSQL)
**Table Updates:**
*   `items` Table:
    *   `theme` (VARCHAR, e.g., 'Modern', 'Vintage', 'Cardio').
    *   `unlock_req` (JSONB, e.g., `{"mastery": {"subject": "cardiovascular", "level": 5}}`).
    *   `set_id` (INT, optional) -> for "Set Bonuses" later.

**API logic:**
*   `GET /shop/items`: Add filters:
    *   `?slot_type=` (e.g., 'desk' -> returns only desk items).
    *   `?theme=` (optional).

### Mobile (Flutter)
**State Management (`ShopProvider`):**
*   `isDecorating` (bool): Toggles the (+) markers.
*   `previewItem` (UserItem?): The item currently being "ghosted" (not yet bought/placed).

**UI Components:**
*   `RoomWidget`:
    *   **Overlay Layer**: Renders animated `FloatingActionButton` (+) over empty slots when `isDecorating` is true.
    *   **Ghost Layer**: Renders `previewItem` semi-transparently if set.
*   `ContextualShopSheet`:
    *   **Floating Window**: A draggable or bottom sheet.
    *   **Tabs**: Filter by Theme (All, Cozy, Clinical).
    *   **Grid**: Shows items. Locked items show Lock Icon + Requirement Toast on tap.
    *   **Action Bar**: "Buy for 50 🪙" button appears only when a new item is previewed.

## 3. Task Breakdown

### Phase 1: Smart Data (Backend)
- [ ] **Migration 004**: Add `theme` and `unlock_req` to `items`.
- [ ] **Seed Smart Items**: Add "Cardio Wall Chart" (Req: Cardio Lvl 3) and "Vintage Lamp" (Theme: Vintage).
- [ ] **API Update**: Ensure `GET /shop/items` supports `slot_type` filtering.

### Phase 2: Core Interaction (The "+")
- [ ] **Decoration Mode**: Add "Paint Roller" toggle in `DashboardScreen`.
- [ ] **Slot Markers**: Update `RoomWidget` to show (+) buttons on empty slots when active.
- [ ] **Sheet UI**: Create `ContextualShopSheet` that fetches items *only* for the clicked slot.

### Phase 3: Preview Logic (The "Ghost")
- [ ] **Preview State**: Logic in `ShopProvider` to hold a temporary `previewItem`.
- [ ] **Visuals**: Render the ghost item in the room (Opacity 0.7).
- [ ] **Buy Cycle**: Update "Buy" button to: `Buy API` -> `Equip API` -> `Clear Preview`.

### Phase 4: Smart Constraints (The "Lock")
- [ ] **Lock Logic**: Frontend checks `user.mastery` vs `item.unlock_req`.
- [ ] **UI Feedback**: Gray out locked items. Show "Requires Level X" message.

## 4. Verification Plan
- **Manual Flow**:
    1.  Click "Decorate" -> See (+) markers.
    2.  Click Desk (+) -> See Desk Items.
    3.  Tap "Vintage Lamp" -> See it on Desk (Ghost).
    4.  Tap "Buy" -> Coins deduct, Lamp becomes solid.
    5.  Tap "Cardio Chart" (Locked) -> See "Locked" message.
