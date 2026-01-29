# PLAN-agoom-gamified
> **Status**: DRAFT
> **Goal**: Implement "Option A" Gamification (Shop, Inventory, Fixed-Slot Decoration)
> **Dependencies**: Relies on `PLAN-agoom-unified` (Auth & Coins must exist).

## 1. Overview
This plan focuses on the **"Visual Loop"**:
1.  **Earn**: User gets Coins from Quizzes (Already done).
2.  **Shop**: User buys Medical Equipment & Decor from a "Clipboard" catalog.
3.  **Build**: User unlocks new Rooms (Wards) and places items in fixed slots.
4.  **The Bean**: A central avatar that lives in the room.

## 2. Architecture Changes

### Backend (PostgreSQL)
We need new tables to track what exists (Global Catalog) and what the user owns (Inventory).

**New Tables:**
*   `items`: The global catalog.
    *   `type`: 'equipment' (functional), 'decor' (cosmetic), 'wall' (posters).
    *   `slot_type`: 'floor_left', 'floor_right', 'desk', 'wall', 'ceiling'.
    *   `price`: Cost in coins.
    *   `asset_path`: String (e.g., 'assets/items/plant.png').
*   `user_items`: What the user bought.
    *   `is_placed`: Boolean.
    *   `placed_at_room_id`: ID of the room it is in.
    *   `placed_at_slot`: String (e.g., 'desk').
*   `user_rooms`: Which rooms the user has unlocked (e.g., 'Cardio Wing').

### Mobile (Flutter)
*   **Asset Management**: Need a folder `assets/images/items/` with generic placeholders for MVP.
*   **State Management**: `ShopProvider` to handle fetching catalog and buying.
*   **UI Components**:
    *   `RoomWidget`: A `Stack` that renders Background + Slots + Bean.
    *   `ShopScreen`: Tabbed view (Equipment | Decor | Rooms).
    *   `InventorySheet`: A bottom sheet to select items for a slot.

## 3. Task Breakdown

### Phase 1: Backend "Mall" (Schema & API)
- [ ] **Schema Migration**: Create `items`, `user_items`, `user_rooms` tables. <!-- id: 18 -->
- [ ] **Seed Shop**: Insert 10 initial items (Stethoscope, Plant, Rug, Diploma) and 3 Rooms (Exam, Cardio, Neuro). <!-- id: 19 -->
- [ ] **Shop Endpoints**:
    -   `GET /shop/items`: List catalog.
    -   `POST /shop/buy`: Deduct coins, add to `user_items`. <!-- id: 20 -->
- [ ] **Inventory Endpoints**:
    -   `GET /user/inventory`: Get owned items.
    -   `POST /user/equip`: Place item in a slot (update `user_items`). <!-- id: 21 -->

### Phase 2: Frontend Logic (The Wallet)
- [ ] **ShopProvider**: Implement `fetchCatalog`, `buyItem`, `equipItem`. <!-- id: 22 -->
- [ ] **Coin Sync**: Ensure buying an item immediately updates the Coin Balance in `AuthProvider`. <!-- id: 23 -->

### Phase 3: UI Implementation (The Room)
- [ ] **Room View**: Create `RoomScreen` with specific `Positioned` slots (Bg, Desk, Floor, Wall). <!-- id: 24 -->
- [ ] **The Bean**: Add a static "Medical Bean" image in the center. <!-- id: 25 -->
- [ ] **Inventory Interaction**: Tapping an empty slot opens the `InventorySheet`. <!-- id: 26 -->

### Phase 4: UI Implementation (The Shop)
- [ ] **Shop Screen**: "Clipboard" UI with Tabs. Grid of items with "Buy" buttons. <!-- id: 27 -->
- [ ] **Room Swiper**: Allow swiping left/right to move between unlocked rooms (MVP: 1 Room first). <!-- id: 28 -->

### Phase 5: Verification
- [ ] **End-to-End**: Earn coins in Quiz -> Buy Plant in Shop -> Place Plant in Room. <!-- id: 29 -->

## 4. Asset Requirements (Placeholders OK)
*   `bean_doctor.png`
*   `room_bg_exam.png`
*   `item_plant.png`
*   `item_diploma.png`
*   `item_stethoscope.png`
