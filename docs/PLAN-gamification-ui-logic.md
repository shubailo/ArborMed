# PLAN-gamification-ui-logic
> **Status**: APPROVED
> **Goal**: Implement "Clinic-First" UI Redesign & "Mastery x Streak" Game Logic
> **Dependencies**: `PLAN-agoom-gamified` (Backend tables must exist).

## 1. Overview
This plan upgrades the minimal MVP into the "Focus Friend" inspired experience.
1.  **UI Redesign**: Implementing the custom HUD (Top Stats, Bottom Profile/Settings/Decorate).
2.  **Game Logic**: Implementing `Coins = Base * Streak * Mastery` formula.
3.  **Profile**: A dedicated "Doctor ID" screen with Subject Mastery tracking.
4.  **Bean Customization**: Allow equipping items on the Bean avatar.

## 2. Architecture Changes

### Backend (PostgreSQL)
We need to track user behavior deeply.

**New/Modified Tables:**
*   `users`: Add columns:
    *   `streak_count` (INTEGER, Default 0)
    *   `last_active_date` (TIMESTAMP)
*   `user_mastery`: New Table.
    *   `user_id` (FK)
    *   `subject` (VARCHAR, e.g., 'Cardiology')
    *   `proficiency` (INTEGER, 0-100)
    *   `level` (INTEGER, 1-10)
*   `items` (Data Update): Add `type='skin'` items for Bean customization.

**API Logic:**
*   `POST /quiz/submit`: This is the engine.
    *   ON CORRECT: `Streak++`, `Mastery +5`.
    *   ON WRONG: `Mastery -2`.
    *   REWARD: Calculate `Base (10) * StreakMultiplier * MasteryMultiplier`.

### Mobile (Flutter)
*   **Layout**: Move away from `Scaffold` standard `appBar/bottomNavigationBar`. Use a full-screen `Stack`.
*   **HUD Layer**:
    *   `TopBar`: Animated "Coin Pill" and "Streak Flame".
    *   `BottomControls`: Floating Action Buttons (FABs) for Profile, Decorate, Settings.
*   **Profile Sheet**: A detailed modal showing stats.
*   **BeanEditor**: A specific mode of the Inventory system filtering for `type='skin'`.

## 3. Task Breakdown

### Phase 1: Database & Logic (The Engine)
- [ ] **Migration 003**: Add `streak_count` to users and create `user_mastery` table.
- [ ] **Seed Mastery**: Create initial mastery records for user (Cardio, Neuro, etc.).
- [ ] **Logic Update**: Create helper function `calculateReward(streak, mastery)` in backend.
- [ ] **API Endpoint**: Create/Update `POST /quiz/complete` to use new logic and return detailed reward breakdown.

### Phase 2: Mobile HUD (The Look)
- [ ] **Main Layout**: Refactor `DashboardScreen` to use `Stack`.
- [ ] **Top Bar Widget**: Create `StatusHud` (Coins + Streak).
- [ ] **Bottom Controls**: Create `ClinicControls` (Profile Icon Left, Settings/Paint Right).
- [ ] **Navigation**: "Focus" button logic (Center).

### Phase 3: Profile & Bean Editor (The Identity)
- [ ] **Profile Service**: Fetch user mastery stats.
- [ ] **Profile UI**: Create `DoctorProfileModal` (Avatar + Stats Bars).
- [ ] **Bean Slots**: Add `bean_body` slot to `items` table constraints/enums.
- [ ] **Editor UI**: Allow clicking Bean to open "Wardrobe" (Inventory filtered by skins).

### Phase 4: Integration
- [ ] **Connect**: Link the "Focus" button to a mock Quiz result that triggers the new reward logic.
- [ ] **Verify**: Ensure Streak resets if `last_active_date` > 24h (Backend Job or Lazy Check).

## 4. Verification Plan
- **Manual Test**:
    1.  User has 0 streak. Answer correctly -> Get 10 coins.
    2.  Manually set Streak to 5 in DB. Answer correctly -> Get 15 coins (1.5x).
    3.  Open Profile -> See Mastery bars.
    4.  Click Bean -> Change Hat/Skin.
