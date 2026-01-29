# Plan: Shop & Clinic Layering Architecture

## 1. Context
**Goal**: Refactor the Clinic/Shop personalization system to use a "Full-Canvas Layering" approach.
**Problem**: Coordinate-based furniture placement is brittle and hard to maintain across devices.
**Solution**: Use full-screen, transparent PNGs for all assets (rooms, desks, decor). All images share the same resolution (e.g., 1080x1920) and anchor point (Center), ensuring perfect alignment without code-based positioning.

## 2. Architecture

### Core Component: `CozyRoomRenderer`
A simple widget that takes a list of equipped assets and stacks them.

```dart
Stack(
  alignment: Alignment.center,
  children: [
    Image.asset('assets/images/room/room_0.png', fit: BoxFit.contain), // Base Layer
    Image.asset('assets/images/furniture/desk_1.png', fit: BoxFit.contain), // Layer 1
    // ... potentially character layer
  ],
)
```

### Data Model: `ShopItem` extension
Items need a `category` that dictates their Z-Index (Render Order).

| Category | Z-Index | Example |
|----------|---------|---------|
| `room`     | 0       | Walls/Floor base |
| `floor_decor`| 10    | Rugs |
| `furniture`  | 20    | Desks, Bookshelves |
| `tabletop`   | 30    | Lamps, Laptops |
| `avatar`     | 50    | The user's character |

## 3. Implementation Steps

### Phase 1: Asset Verification & Setup
- [ ] Verify `mobile/assets/images/room/` exists and contains `room_0.png`.
- [ ] Verify `mobile/assets/images/furniture/` exists and contains `desk_1.png`, etc.
- [ ] Update `pubspec.yaml` to include these new directories.

### Phase 2: Domain Layer (Frontend)
- [ ] Update `ShopItem` model to include `assetPath` and `zIndex`/`category`.
- [ ] Create a static `ShopCatalog` service that lists these items (since we are creating the MVP).

### Phase 3: Clinic Renderer UI
- [ ] Create `CozyRoomRenderer` widget.
- [ ] Implement `Stack` logic with `BoxFit.contain`.

### Phase 4: Shop UI Refactor
- [ ] Update `ShopScreen` to preview changes on the `CozyRoomRenderer`.
- [ ] "Equipping" an item replaces the item in that category (e.g., clicking `desk_2` replaces `desk_1`).

### Phase 5: Persistence (Mock -> Backend)
- [ ] Store `equippedItems` in `ShopProvider`.
- [ ] (Future) Sync to Backend `UserRoom` model.

## 4. Verification
- **Visual Check**: Does `desk_1` sit perfectly on the floor of `room_0` without manual pixel adjustment?
- **Responsiveness**: Does it resize correctly on different screen sizes (while maintaining aspect ratio)?
