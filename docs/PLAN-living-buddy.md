# PLAN-living-buddy
> **Status**: DRAFT
> **Goal**: Bring "Hemmy" (Blood Drop Buddy) to life with motion and interactivity.
> **Dependencies**: `PLAN-isometric-room` (Grid math exists).

## 1. Overview
We are transforming the static "Bean" into **Hemmy**, a blood drop that autonomously wanders the clinic.
1.  **Vector Rendering**: Use `CustomPaint` for Hemmy to ensure he looks crisp at any zoom level and can be easily animated (stretching/morphing).
2.  **Autonomous Wander**: Hemmy will slide between empty isometric tiles on a timer.
3.  **Expressive State**: Blinking, bobbing during movement, and happy reactions to user taps.

## 2. Architecture Changes

### Mobile (Flutter)
**Visuals (`HemmyWidget`)**:
- A replacement for the simple `BeanWidget`.
- Uses `CustomPainter` to draw the teardrop shape + limbs.
- Supports `isWalking` and `isHappy` flags to trigger internal animations.

**Movement Logic (`BuddyWanderService`)**:
- A new service or logic within `ShopProvider` (or a dedicated `BuddyProvider`).
- **Timer**: Every 10s, picks a random `x`, `y` from `IsoService.GRID_SIZE`.
- **Validation**: Ensures the tile is not occupied by furniture.
- **States**: `targetX`, `targetY`, and `currentX`, `currentY`.

**UI Integration (`RoomWidget`)**:
- Wrap `HemmyWidget` in an `AnimatedPositioned` widget.
- Map the `currentX`/`currentY` to screen coordinates using `IsoService.gridToScreen`.

## 3. Task Breakdown

### Phase 1: The Visual Hemmy
- [ ] **HemmyPainter**: Implement drawing logic for the blood drop shape.
- [ ] **Layering Support**: Ensure "Wardrobe" items (Hats/Glasses) still sit correctly on the new shape.
- [ ] **Idle Animations**: Subtle "breathing" scale animation.

### Phase 2: Isometric Locomotion
- [ ] **Wander State**: Add `buddyX` and `buddyY` to `ShopProvider`.
- [ ] **Pathing Logic**: A simple function to pick a valid adjacent or random tile.
- [ ] **Animated Transit**: Connect the provider state to `AnimatedPositioned` in the room view.

### Phase 3: Personality
- [ ] **Tap Reaction**: Add `GestureDetector` to Hemmy. Tapping makes him jump/wave.
- [ ] **Blink Timer**: Periodic eye-swap animation.
- [ ] **Movement Bob**: Add a vertical "hop" while he is sliding to a new tile.

## 4. Verification Plan
- **Manual Flow**:
    1.  Open Clinic -> Observe Hemmy standing still at (0,0).
    2.  Wait 10s -> Verify Hemmy slides smoothly to a new tile.
    3.  Tap Hemmy -> Verify happy animation plays.
    4.  Place furniture on his path -> Verify he avoids walking into it (Collision check).
