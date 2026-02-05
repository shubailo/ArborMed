# PLAN: Shop Overhaul & Button Fixes

Refine the Shop UI using the "High-End Clinical Clipboard" aesthetic while maintaining the existing watercolor/brown colorscheme. This plan also addresses critical functional bugs in the Buy and Equip cycles.

## User Review Required

> [!IMPORTANT]
> **Functional Fix**: The current "Equip" button fails because it confuses local Database IDs with Server IDs. I will unify this to use consistent local-first lookups.
> **Haptic Feedback**: I propose adding "Lub-Dub" (heartbeat) haptics to successful purchases. Do you approve?

## Proposed Changes

### 1. Data Logic & Reliability (ShopProvider)
- **ID Unification**: Update `equipItem` and `unequipItem` to handle items that haven't been assigned a `serverId` yet (offline-first).
- **Sync Optimization**: Ensure `fetchInventory` is called immediately after a successful `buyItem` to prevent stale UI states.
- **Button Debouncing**: Prevent multiple rapid taps on 'Buy' which could lead to duplicate purchases.

---

### 2. UI/UX Refinement (ShopScreen)
- **Typography Swap**: Replace default fonts with **Figtree** (Headings) and **Noto Sans** (Body) for a professional medical look.
- **Clipboard Header**: Enhance the clipboard "clip" with realistic metallic gradients and watercolor textures.
- **Item Cards**:
    - Use `SyncedScaleWrapper` for all shop tiles to give them the same "elastic" feedback as the room furniture.
    - Add "New" or "Sale" badges where applicable.
- **Shop Detail Sheet**: (Optional) Tapping an item opens a bottom sheet showing a larger preview and more detailed "Medical Specs" (description).

---

### 3. Premium Components (New Widgets)
- **[NEW] CozyButton**: A custom button widget that:
    - Uses the current brown/emerald palette but with watercolor-style rounded edges.
    - Includes a "Medical Pulse" animation when loading.
    - Responsive hover and tap states.

## Verification Plan

### Automated Tests
- `flutter analyze` to ensure no syntax regressions.
- Logic Test: Verify that purchasing an item immediately enables the "Equip" button without a manual refresh.

### Manual Verification
1. **Purchase Flow**: Buy an item, verify coins deduct correctly, and the button changes to "USE".
2. **Equip Flow**: Tap "USE", verify the item persists in the room after navigation.
3. **Offline Test**: Place the app in Airplane mode and verify buttons still handle local database state correctly.
