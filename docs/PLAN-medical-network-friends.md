# PLAN: Medical Network (Mutual Friends)

This plan outlines the implementation of a peer-to-peer connection system ("Colleagues") to foster social motivation and room-sharing.

## 🎯 Objectives
- Enable users to connect using unique handles and Medical IDs.
- Create a mutual-only friendship model with an request/approval flow.
- Allow "Visiting" of colleagues' rooms with social interactions (Likes and Notes).

## 🛠️ Proposed Changes

### 1. Database & Backend (P0)

#### [NEW] [008_friendships.sql](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/models/008_friendships.sql)
- Table `friendships`:
  - `requester_id` (FK to users)
  - `receiver_id` (FK to users)
  - `status` (ENUM: 'pending', 'accepted')
  - `created_at` (TIMESTAMP)
  - Unique constraint on `(requester_id, receiver_id)` to prevent duplicates.

#### [NEW] [socialController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/socialController.js)
- `searchUsers`: Search by handle (partial match) or Medical ID (exact).
- `sendRequest`: Create a 'pending' row.
- `respondToRequest`: Update status to 'accepted' or delete if declined.
- `getNetwork`: Fetch list of accepted friends and pending incoming requests.

#### [NEW] [consultationRoutes.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/routes/consultationRoutes.js)
- Endpoint for leaving "Consultation Notes" on a friend's room.

---

### 2. Mobile UI (P1)

#### [MODIFY] [clinic_directory_sheet.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/social/clinic_directory_sheet.dart)
- Transform into the main "Medical Network" hub.
- **Top Section**: Search bar with toggle for "@handle" or "Medical ID".
- **Middle Section**: "Incoming Consult Requests" (Pending requests).
- **List Section**: My Colleagues (Accepted friends).

#### [MODIFY] [room_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/room_screen.dart)
- Add "Social Overlay" when visiting a friend's room.
- Include:
  - **"Great Layout!" Like Button**: Triggers the existing 5-coin reward logic.
  - **Leave Note**: A TextButton that opens a dialog to leave a public note.

---

### 3. Verification Plan

#### Automated Tests
- `pytest` / `jest` for friendship state machine (Pending -> Accepted).
- Search accuracy for ID vs Handle.

#### Manual Verification
1. Search for a colleague by ID.
2. Send request -> Log into Friend's account -> Accept.
3. Visit Friend's room -> Leave a "Like" -> Verify they received 5 coins.
4. Leave a note -> Check if it appears on their Room wall (or profile).

## 🚀 Execution Strategy
1. **Migrations First**: Deploy the SQL changes.
2. **Social API**: Build the core request/accept logic.
3. **UI Hub**: Build the Directory/Search interface.
4. **Room Visiting**: Finalize the "Spectator mode" for social interaction.
