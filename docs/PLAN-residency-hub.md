# PLAN-residency-hub: Clinical Residency Simulator Overhaul

## 1. Goal Description
The objective is to pivot ArborMed from a simple cosmetic room-decorator into a high-stakes **Clinical Residency Simulator**. We will merge the existing Room Builder with a "Hardcore Gamification" loop that uses professional rank, loss aversion, and utility-linked economics to drive consistent user engagement.

## 2. User Review Required

> [!IMPORTANT]
> This plan introduces **Loss Aversion (Malpractice Strikes)**. If a student fails to complete their "Daily Rounds," they will receive a strike. Cumulative strikes lead to **Rank Demotion**, which physically downgrades their room.

> [!WARNING]
> **Data Migration**: We will need to update the `ShopItem` and `User` models to support levels and rank. Existing users will restart as "Unmatched Students."

## 3. Task Breakdown

### Phase 1: Rank & Progression Infrastructure
- [ ] Define `ClinicalRank` enum (Unmatched → Intern → Resident → Attending → Chief).
- [ ] Create `RankProvider` to manage rank XP, strikes, and demotion logic.
- [ ] Update `AuthProvider` to include `currentRank` and `strikesCount`.
- [ ] Implement `schema_v2.sql` to add these fields to the backend.

### Phase 2: The Residency Hub (Room Overhaul)
- [ ] **Rank-Responsive Rooms**: Update `CozyRoomRenderer` to swap the base room asset based on current Rank.
- [ ] **Interactive Zoom**:
    - [ ] Modify `RoomScreen` to support a `zoomController`.
    - [ ] Add a specific `Hitbox` for the Desk that triggers a cinematic zoom-in.
- [ ] **Environmental Alerts**: Implement a "Red Pulse" overlay for the `CozyRoomRenderer` triggered during high-stakes events (Global Outbreaks).

### Phase 3: Mission Control (Zoomed-In Dashboard)
- [ ] [NEW] `MissionControlView`: A glassmorphic dashboard visible only when zoomed into the desk.
- [ ] **Shift Status (Rounds)**: A dynamic checklist (Daily Quiz, Smart Review, Social Consult).
- [ ] **Community Case (Trial)**: A high-fidelity progress bar showing global collaboration.

### Phase 4: Clinical Economics (Furniture Upgrades)
- [ ] Update `ShopItem` model to include `level`, `maxLevel`, and `clinicalEffect`.
- [ ] **Upgrade System**: Modify `ShopProvider` to allow upgrading placed furniture using tokens.
- [ ] **Skill Linking**: Create a mapping of Furniture Items to Quiz Lifelines (e.g., "Precision Monitor" → "Remove 2 Incorrect Answers").

## 4. Verification Plan

### Automated Tests
- Unit tests for `RankProvider` demotion logic.
- Integration tests for `ShopProvider.upgradeItem` token deduction.

### Manual Verification
- Verify Rank-up visual transition (Bunk Room → Private Suite).
- Performance audit of the camera zoom transition on low-end mobile devices.

---

[OK] Plan created: docs/PLAN-residency-hub.md

Next steps:
- Review the plan
- Run `/create` to start implementation
- Or modify plan manually
