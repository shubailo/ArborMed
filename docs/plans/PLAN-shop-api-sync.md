# PLAN: Shop API Synchronization & Modernization

## Overview
This plan implements a "never-again" fix for API path mismatches by centralizing endpoint management on the mobile side and unifying the backend route structure.

## Decisions
- **Centralization**: All mobile endpoints will live in `ApiEndpoints`.
- **Path Strategy**: Unified `/shop/` base path for all shop/inventory actions.
- **Naming**: Standardized on `equip` and `unequip` for both items and furniture.

## Proposed Changes

### Mobile

#### [NEW] [api_endpoints.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/constants/api_endpoints.dart)
Create a central registry for all API paths.

#### [MODIFY] [shop_provider.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/services/shop_provider.dart)
Refactor all API calls to use `ApiEndpoints` and update paths to the `/shop/` namespace.

### Backend

#### [MODIFY] [shopRoutes.js](file:///C:/Users/shuba/Desktop/Med_buddy/backend/src/routes/shopRoutes.js)
Ensure all inventory-related logic is mounted under `/shop`. (Verified: currently mounted as `/shop`).

#### [MODIFY] [inventoryController.js](file:///C:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/inventoryController.js)
Ensure function names and logic align with the `equip`/`unequip` terminology.

## Task Breakdown

### Phase 1: Foundation (Mobile)
- [ ] **Task 1.1**: Create `lib/constants/api_endpoints.dart`.
- [ ] **Task 1.2**: Audit `ShopProvider.dart` and migrate `buyItem`, `fetchInventory`, `equipItem`, `unequipItem` to use constants.

### Phase 2: Refinement (Backend)
- [ ] **Task 2.1**: Audit `shopRoutes.js` for any lingering `/inventory` terminology.
- [ ] **Task 2.2**: Verify `inventoryController.js` logic for consistency.

### Phase 3: Verification
- [ ] **Step 1**: Run `npm run migrate` (ensure 032 is applied).
- [ ] **Step 2**: Manually test the "Modern Workstation" equipment flow.
- [ ] **Step 3**: Verify logs for `/shop/equip` and `/shop/unequip` success.
