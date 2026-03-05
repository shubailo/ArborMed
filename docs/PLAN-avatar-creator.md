# PLAN: Premium SVG Avatar Creator

> [!NOTE]
> This plan outlines the replacement of the legacy "Bean" character with a modular, high-quality SVG-based Avatar Creator ("Studio") that follows the app's established "Clipboard" aesthetic.

## 🎯 Objective
Create a robust, scalable, and premium avatar customization system that supports monetization (Fitting Room) and future gameplay expansion (Pose/Expression states).

## 📊 Phase 1: Data Model & Backend Architecture
- **Schema Update**:
  - `[ ]` Add `avatar_config` (JSONB) to `users` table.
  - `[ ]` Add `has_received_founders_pack` (BOOLEAN) to `users` table.
  - `[ ]` Add `is_free` (BOOLEAN) to `items` table.
- **Migration Strategy**:
  - `[ ]` Backend-driven trigger: grant 500 coins to users with detected legacy items.
  - `[ ]` Set `has_received_founders_pack` to `true` to prevent duplicate rewards.
- **Validation**:
  - `[ ]` Strictly server-authoritative save flow.
  - `[ ]` Missing ID fallback mapping (silent fallback to `null` + server logging).

## 🎨 Phase 2: Asset Standardization & Rendering
- **SVG Engine**:
  - `[ ]` Develop `AvatarRenderer` using `flutter_svg`.
  - `[ ]` Standardize assets to `200x200` viewBox with 10px safety margins.
  - `[ ]` Implement dynamic color injection for brand-approved Skin/Hair palettes.
- **Performance**:
  - `[ ]` Implement `RepaintBoundary` for the character stack.
  - `[ ]` Pre-render rasterized thumbnails for the Studio selection grid.

## 📋 Phase 3: The Avatar Studio (UI/UX)
- **UI Architecture**:
  - `[ ]` "Clipboard" style full-screen modal (matches `ShopScreen` aesthetics).
  - `[ ]` Horizontal category navigation + scrollable item grid.
- **Logic**:
  - `[ ]` **Fitting Room**: Live preview of all items (owned or unowned).
  - **Save Flow**: Calculate total cost of unowned items. Block if insufficient funds.
  - `[ ]` **Revert**: Session-level "Undo to Last Saved" button.
  - `[ ]` **Offline Status**: Allow local edits, block "Save" with instructive banner.

## 🔄 Phase 4: Integration & Cleanup
- **Integration Points**:
  - `[ ]` Update `ProfilePortal` to use `AvatarRenderer`.
  - `[ ]` Add Founder Reward banner to Profile.
  - `[ ]` Update `RoomScreen` to render the new customizable character.
- **Cleanup**:
  - `[ ]` "Big-bang" removal of `bean_widget.dart` and Hemmy assets.
  - `[ ]` Sweep achievements/copy for legacy character references.

## ✅ Verification Checklist (QA)
1. `[ ]` **Purchase Flow**: Wear unowned item -> "Buy & Save" shows total -> Confirm -> Balance updates -> Item owned.
2. `[ ]` **Migration**: Detect legacy user -> 500 coins granted -> Banner shown -> Re-login works.
3. `[ ]` **Failure Handling**: Mid-edit network loss -> Save blocked with banner -> Network restored -> Save retries successfully.
4. `[ ]` **Art Alignment**: 5 canonical configs (Default, Max Accessories, Different tones) render perfectly inside the `200x200` frame.
5. `[ ]` **Persistence**: Close app -> Re-open -> Last saved avatar is displayed globally.
