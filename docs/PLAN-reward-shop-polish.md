# PLAN: Reward & Shop Polish (M3.1)

Polishing the M3 Reward & Economy system to ensure consistent state synchronization, clear product ownership visibility, and a premium "Cozy Gamified Medical" UX.

## User Review Required

> [!IMPORTANT]
> **Backend Polish**: To implement the "Owned" status efficiently, I will modify the internal logic of `GET /rewards/shop` to include an `isOwned` boolean for each item. This avoids creating whole new endpoints while providing the necessary data.
> **Single Ownership**: Items will be considered "owned" once. The "Buy" button will be disabled and replaced with an "Owned" badge once purchased.

## Proposed Changes

### [Backend] (services/backend)

#### [MODIFY] [RewardController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/RewardController.ts)
- Update `getShopItems` to query `UserInventory` for the current user and attach an `isOwned` flag to each item.

#### [MODIFY] [RewardService.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/RewardService.ts)
- Resolve lint errors by re-generating Prisma client (`npx prisma generate`).
- Standardize error responses (ensure `400` status for insufficient funds).

---

### [Student App] (apps/student_app)

#### [MODIFY] [reward_entities.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/reward/domain/entities/reward_entities.dart)
- Update `ShopItem` entity to include `isOwned` field.

#### [MODIFY] [reward_repository.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/reward/data/repositories/reward_repository.dart)
- Update repository to parse the new `isOwned` field from the API.

#### [MODIFY] [reward_providers.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/reward/presentation/providers/reward_providers.dart)
- Add an `initialFetch` guard to prevent redundant balance re-fetching.
- Invalidate `shopItemsProvider` after a successful purchase to refresh "Owned" status.

#### [MODIFY] [shop_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/reward/presentation/pages/shop_screen.dart)
- Add "Owned" badge UI.
- Disable "Buy" button for owned items.
- Add explanatory header text: "Earn Stethoscope points by answering questions correctly, then spend them here to customize your study space."
- Improve SnackBar messages for insufficient points and network errors.

---

### [Shared Types] (packages/shared-types)

#### [MODIFY] [index.ts](file:///c:/Users/shuba/Desktop/Med_buddy/packages/shared-types/src/index.ts)
- Update `ShopItemDto` to include `isOwned?: boolean`.

## Verification Plan

### Automated Verification
- Run `npx prisma generate` to verify schema/client sync.
- Run `flutter analyze` to check for type errors in the student app.

### Manual Verification
1. **Initial Sync**: Open Study feature; verify points load correctly (not 0 placeholder).
2. **Point Earning**: Answer a question; verify the points pill in the TopBar updates immediately.
3. **Shop Purchase**:
    - Buy an item; verify balance decreases.
    - Verify item card immediately shows "Owned".
    - Try to buy with 0 points; verify "Not enough Stethoscope points..." SnackBar.
4. **Persistence**: Close and reopen the app; verify "Owned" status and balance are preserved.
