# Plan: UI/UX Refresh (The Hybrid Model)

**Goal**: Elevate MedBuddy from "Functionally Cozy" to "Premium Gamified Learning".
**Strategy**: Combine the sophisticated "Gentle Clinic" aesthetic (soft gradients, organic textures) with "Medi-Quest" gamification (juicy feedback, particle effects).

## Phase 1: The Visual Foundation ("Gentle Clinic")
Upgrade the core design system tokens.

- [ ] **Semantic Gradients**
    - [ ] Update `CozyTheme` to replace flat colors with `LinearGradient`.
    - [ ] Define `sageGradient` (Sage -> Mint) and `clayGradient` (Clay -> Terra).
- [ ] **Smart Shadows**
    - [ ] Create `CozyShadows` class.
    - [ ] Implement "Colored Shadows" logic (shadow color = 40% opacity of box color).
- [ ] **Typography Tuning**
    - [ ] Enable `FontWeight.w900` for headers vs `w400` body for higher contrast.

## Phase 2: Interaction Design ("The Juice")
Make the app feel alive under the finger.

- [ ] **Squishy Buttons**
    - [ ] Refactor `CozyButton` to use `ScaleTransition`.
    - [ ] Logic: On tap down, scale to 0.95. On tap up, spring back to 1.0.
- [ ] **Haptic Feedback**
    - [ ] Add `HapticFeedback.mediumImpact()` to all primary actions (Answer Submit, Buy Item).
    - [ ] Add `HapticFeedback.selectionClick()` to scroll items.

## Phase 3: Gamification FX ("Medi-Quest")
Visual rewards for progress.

- [ ] **Liquid Progress Bars**
    - [ ] Replace standard linear progress with `LiquidLinearProgressIndicator`.
    - [ ] Effect: Bar "sloshes" as it fills up.
- [ ] **Particle Engine**
    - [ ] Create `ConfettiOverlay` widget.
    - [ ] Trigger on `LEVEL_UNLOCKED` and `MASTERY_GAINED` events.
- [ ] **Combo Popup**
    - [ ] Create animated text overlay that floats up + fades out for "STREAK x5!" events.

## Phase 4: Integration & Polish
Apply the new system to key screens.

- [ ] **Quiz Session Retrofit**
    - [ ] Apply Squishy Buttons to Options.
    - [ ] Add Confetti to Level Up.
- [ ] **Hub/Room Retrofit**
    - [ ] Apply Gradients to HUD elements.
    - [ ] Update Navigation Bar with new shadows.

## Verification
- [ ] Visual Check: Do buttons feel satisfying?
- [ ] Visual Check: Are shadows colored correctly?
- [ ] Performance: Ensure particles don't drop FPS below 55.
