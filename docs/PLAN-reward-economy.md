# PLAN: M3 Reward & Economy System

This plan outlines the implementation of a Reward & Economy system for MedBuddy, enabling students to earn "Stethoscope-points" from study sessions and spend them in a shop.

## User Review Required

> [!NOTE]
> **Decisions from Socratic Gate:**
> 1. **Model Reuse**: Reusing and extending `ShopItem`, `UserInventory`, and `UserRoomItem`.
> 2. **Mastery vs. Reward**: `User` model will get a `rewardBalance` field for Stethoscope-points.
> 3. **Design Vibe**: "Cozy / Gamified medical" - warm, friendly, student room feel with soft accents.
> 4. **Points Cap**: No cap for M1. Points mapping is encapsulated for future tuning.

## Proposed Changes

---

### Backend (`services/backend`)

#### [MODIFY] [schema.prisma](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/prisma/schema.prisma)
- Add `rewardBalance` field (Int, default 0) to `User` model.
- Add `Purchase` model (id, userId, shopItemId, pricePaid, createdAt) to track transaction history (audit trail).
- Add `key`, `description`, `isActive` to `ShopItem`.
- Ensure `UserInventory` and `UserRoomItem` remain integrated with the system.

#### [NEW] [RewardController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/RewardController.ts)
- `GET /rewards/balance/:userId`: Fetch or init reward balance.
- `GET /rewards/shop`: List active shop items.
- `POST /rewards/purchase`: Process item purchase with balance check.

#### [MODIFY] [StudyController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/StudyController.ts)
- Integrate reward calculation in `submitAnswer`.

#### [NEW] [RewardService.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/RewardService.ts)
- Logic for calculating points from quality (0-5) and updating balance.

---

### Shared Types (`packages/shared-types`)

#### [MODIFY] [index.ts](file:///c:/Users/shuba/Desktop/Med_buddy/packages/shared-types/src/index.ts)
- Add `RewardBalanceDto`, `ShopItemDto`, `PurchaseRequestDto`, `PurchaseDto`.

---

### Student App (`apps/student_app`)

#### [NEW] [features/reward](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/reward)
- **Domain**: `RewardBalance`, `ShopItem` entities and related usecases.
- **Data**: `RewardRepository` with Dio implementation.
- **Presentation**: `ShopScreen`, `ShopItemCard`, and Riverpod/Bloc state management.

#### [MODIFY] [study_top_bar.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/study/presentation/widgets/study_top_bar.dart)
- Bind the "Score Pill" to the real `RewardBalance` instead of hardcoded '5'.

---

## Verification Plan

### Automated Tests
- **Backend**: Run `curl` or Postman requests to verify:
    - Balance init (0 for new user).
    - Study answer → Balance increase.
    - Purchase success → Balance decrease.
    - Purchase failure (insufficient points) → 400 Error.
- **Prisma**: Run `npx prisma validate` and `npx prisma generate`.

### Manual Verification
1. Open Student App, go to Study.
2. Answer questions with quality 4-5.
3. Check `StudyTopBar` for updated points.
4. Go to `ShopScreen`, verify items list.
5. Purchase an item, verify points decrease and "Bought" feedback.
