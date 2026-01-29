# PLAN-bean-avatar
> **Status**: DRAFT
> **Goal**: Implement "The Living Bean" Avatar & Wardrobe System
> **Dependencies**: `PLAN-smart-shop` (Shop infrastructure exists).

## 1. Overview
We are giving the Bean an identity. Users can buy and equip items to customize their "Study Buddy".
1.  **Wardrobe Entry**: Access via the Profile HUD button.
2.  **Layered Bean**: The Bean is constructed of layers: `Body` (Base) -> `Outfit` (Body) -> `Accessory` (Head/Hand).
3.  **Avatar Shop**: A specialized section of the shop for "Skins".

## 2. Architecture Changes

### Backend (PostgreSQL)
**Data Updates:**
*   `items` Table: Add items with `type='skin'` and `slot_type` in ['skin_color', 'head', 'body', 'hand'].
*   `user_items`: No schema change needed, but `placed_at_slot` will store 'head', 'body', etc. when `placed_at_room_id` is NULL (or a special "Avatar" room ID, e.g., 0).

**API Logic:**
*   `GET /shop/inventory?type=skin`: Fetch equipped avatar items.

### Mobile (Flutter)
**State Management (`ShopProvider`):**
*   `avatarConfig`: A Map/Object storing current equipped items (`{head: item, body: item}`).
*   `fetchAvatar()`: Helper to load the current look.

**UI Components:**
*   `BeanWidget`: A `Stack` that renders images in order:
    1.  Base Bean (Color/Skin)
    2.  Body (Lab Coat, Scrub)
    3.  Head (Hat, Glasses)
    4.  Hand (Stethoscope, Coffee)
*   `WardrobeSheet`: Similar to `ContextualShopSheet`, but filters for `type='skin'`.
*   `ProfileModal`: Displays the large Bean + Stats.

## 3. Task Breakdown

### Phase 1: Avatar Data (Backend)
- [ ] **Seed Skins**: Insert "Blue Bean" (Skin), "Lab Coat" (Body), "Stethoscope" (Hand), "Party Hat" (Head).
- [ ] **API Check**: Verify `GET /shop/items?type=skin` returns these.

### Phase 2: The Visual Bean (Mobile)
- [ ] **Asset Prep**: Create placeholder images for layers (`bean_base.png`, `item_coat.png`).
- [ ] **BeanWidget**: Create a reusable widget that takes `equippedItems` and renders the stack.
- [ ] **Room Integration**: Replace the "Yellow Box" in `RoomWidget` with `BeanWidget`.

### Phase 3: The Wardrobe (Interaction)
- [ ] **Avatar State**: Update `ShopProvider` to track `avatarItems`.
- [ ] **Wardrobe UI**: Create `WardrobeSheet` (Tabbed: Head | Body | Hand).
- [ ] **Equip Logic**: Clicking an item in Wardrobe updates `user_items` (Equip) and refreshes `BeanWidget`.

## 4. Verification Plan
- **Manual Flow**:
    1.  Open Profile -> see Default Bean.
    2.  Click "Edit Appearance".
    3.  Buy "Lab Coat" -> Bean wears Lab Coat.
    4.  Close Profile -> Bean in Room is wearing Lab Coat.
