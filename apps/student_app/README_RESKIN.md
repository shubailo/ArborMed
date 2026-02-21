# ArborMed Legacy Re-skin: Study Buddy Flutter App

This project refactor brings the legacy **ArborMed** "Cozy Clinical" aesthetic to the Med-Buddy student app.

## Theme System
The visual style is now centralized and driven by design tokens.

- **Location**: `lib/core/theme/`
  - `app_theme.dart`: Defines the main `ThemeData` (Sage Green, Soft Clay, Ivory Cream, Warm Brown).
  - `cozy_theme.dart`: Defines custom design tokens for radii (`CozyRadius`), shadows (`CozyShadows`), and spacing.

### Adjusting Aesthetics
To change global colors or typography, modify `app_theme.dart`. All feature widgets now use `Theme.of(context)` or static tokens from `CozyTheme`.

## Room Layout Model
The room is now data-driven rather than hardcoded.

- **Model**: `lib/features/room/domain/entities/room_layout.dart`
- **Logic**: The `RoomScreen` iterates over `RoomLayout.slots` to render interactive `_RoomSlot` widgets.
- **2.5D Approximation**: Items are rendered in a centered, layered composition.

### Adding New Slots
To add a new furniture slot:
1. Open `room_layout.dart`.
2. Add a new `RoomSlot` entry to the `defaultClinical()` layout with a unique `slotId` and positioning (top/left/bottom/right).
3. Define its `allowedCategories`.

## Navigation HUD
Primary navigation has moved from the bottom bar to a floating Room-centric HUD.

- **Widget**: `lib/features/room/presentation/widgets/cozy_actions_overlay.dart`
- **Actions**:
  - **Study**: Opens the Quiz Portal (Modal).
  - **Decorate**: Opens a unified Inventory/Shop portal.
  - **Profile**: Opens student statistics.

## Study Experience
The quiz flow has been re-skinned for comfort and focus.

- **CozyPanel**: Questions slide in from the right in a rounded card.
- **LiquidButton**: Custom pill-shaped action buttons with press animations.
- **Floating Icons**: Subtle medical-themed background animations in `FloatingMedicalIcons`.
- **CozyProgressBar**: A themed, pulsing progress indicator.

## Day/Night Tinting
The room automatically applies a color tint based on the user's local system time:
- **Morning**: Warm/Golden
- **Day**: Bright/Neutral
- **Sunset**: Orange/Pink
- **Night**: Blue/Moonlight
