# PLAN - Fix Furniture Visibility when Visiting

## Overview
**Goal**: Fix the bug where visiting a friend's room in the "Medical Network" displays the current user's furniture instead of the friend's (or an empty room if the friend has no items).

**Context**: 
- Currently, `ShopProvider` relies on `_visitedInventory.isNotEmpty` as a proxy for "is visiting". 
- If a friend has an empty inventory, `_visitedInventory` is empty, causing the app to fall back to `_inventory` (the user's own items).
- This creates a confusing user experience where the user sees their own room when visiting a friend.

## Success Criteria
1.  **Empty Room Visibility**: Visiting a friend with NO furniture must show a default empty room (ID 100) and NO furniture items.
2.  **Friend's Room**: Visiting a friend WITH furniture must show their specific furniture.
3.  **Return Home**: Keeping the "Stop Visiting" or back navigation flow must correctly restore the user's own room and furniture.
4.  **No Regressions**: The user's own room must still load correctly upon app start and when not visiting.

## Project Type
**MOBILE** (Flutter)

## Tech Stack
-   **Language**: Dart
-   **Framework**: Flutter
-   **State Management**: Provider (`ShopProvider`, `SocialProvider`)
-   **Database**: Drift (SQLite) - *No schema changes required*

## File Structure & Impact
-   **Core Logic**: `mobile/lib/services/shop_provider.dart`
-   **UI**: `mobile/lib/screens/game/room_screen.dart` (Indirectly affected via Provider consumers)

## Task Breakdown

### Phase 1: State Management Refactor
**Agent**: `mobile-developer`
**Skill**: `flutter-state-management`

| Task ID | Task Name | Description | Priority | Verification |
| :--- | :--- | :--- | :--- | :--- |
| **TASK-1** | Add `_isVisiting` State | Add `bool _isVisiting` to `ShopProvider` to explicitly track visiting status, independent of inventory size. Initialize to `false`. | **P0** | Search usages of `_isVisiting` finds matches. |
| **TASK-2** | Update Visiting Logic | Modify `fetchRemoteInventory(int userId)` to set `_isVisiting = true` at the START of the method. Modify `clearVisitedInventory()` to set `_isVisiting = false`. | **P0** | Visiting triggers flag flip. |

### Phase 2: Logic Implementation
**Agent**: `mobile-developer`
**Skill**: `clean-code`

| Task ID | Task Name | Description | Verification |
| :--- | :--- | :--- | :--- |
| **TASK-3** | Update `currentRoom` Getter | Modify `currentRoom` to check `_isVisiting`. If `true` AND `_visitedInventory` is empty, return Default Room (ID 100). Do NOT fall back to `_inventory`. | Getter returns ID 100 when visiting empty user. |
| **TASK-4** | Update `equippedItems` Getter | Modify `equippedItemsAsShopItems` to check `_isVisiting`. If `true` AND `_visitedInventory` is empty, return empty list. Do NOT fall back to `_inventory`. | Getter returns [] when visiting empty user. |
| **TASK-5** | Update `avatarConfig` Getter | Modify `avatarConfig` to check `_isVisiting`. If `true` AND `_visitedInventory` is empty, return default/null config. | Avatar doesn't show user's clothes on friend. |

## Phase X: Verification Plan

### Manual Verification Checklist
- [ ] **Scenario A: Visit Friend with Furniture** -> Verify friend's items appear.
- [ ] **Scenario B: Visit New User (Empty)** -> Verify ROOM IS EMPTY (Default floor). Verify NO user items appear.
- [ ] **Scenario C: Return Home** -> Click "Stop Visiting" or "Back". Verify OWN items reappear.
- [ ] **Scenario D: App Restart** -> Verify own items load correctly on cold start.

### Automated Checks
- [ ] Run `flutter analyze` to ensure no new lint errors.
