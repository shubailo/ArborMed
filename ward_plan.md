# Architecture Plan: Study Wards (Collaborative Multiplayer)

## 1. Overview
The "Study Wards" feature allows up to 4 students to form a collaborative study group. They will share a customized "Ward Room" and participate in "Ward Rounds" (collaborative problem-solving on high-level clinical cases).

## 2. Backend Architecture (`services/backend`)

### A. Real-Time Collaboration (Socket.IO)
File: `src/services/socketService.js` (or a new `wardSocketService.js` to separate logic)
- **Lobby Management:**
  - `create_ward`: Generates a unique 6-character room code. The creator becomes the "Attending" (Host).
  - `join_ward`: Users join via the room code. Emits `ward_updated` to all connected clients.
  - `leave_ward`: Handles user disconnection or manual exit.

### B. Ward Rounds Gameplay Loop
- **State Management:** A new `activeWards` Map will track `roomId -> { users: [], currentCase: null, votes: {}, state: 'LOBBY' | 'PLAYING' | 'SUMMARY' }`.
- **Case Fetching:** Leverage `adaptiveEngine.js` or `db.query` to fetch Bloom Level 4 (Apply/Analyze) questions.
- **Voting Mechanism:**
  - `submit_vote`: Clients emit their chosen answer.
  - Once all votes are in, or a timer expires, the server evaluates the majority vote.
  - Emits `round_result` detailing the correct answer and distributing XP.

### C. Database Schema Updates (`src/models/schema.sql` or equivalent)
- **Table: `wards`**
  - `id` (UUID), `name` (String), `host_id` (UUID), `created_at` (Timestamp)
- **Table: `ward_members`**
  - `ward_id` (UUID), `user_id` (UUID), `joined_at` (Timestamp)
- **Table: `ward_inventory`**
  - Tracks items purchased/unlocked collectively for the Ward Room.

## 3. Frontend Architecture (`apps/student_app`)

### A. Navigation & UI (`lib/screens/game/`)
- `WardLobbyScreen`: UI for entering a code to join or creating a new ward. Displays avatars of connected members.
- `WardRoundScreen`: The core gameplay screen.
  - Displays the complex clinical case.
  - Shows real-time indicators of who has voted (without revealing the vote until the round ends).
- `WardRoomScreen`: The collaborative 3D/Isometric room, similar to the existing Cozy Room, but loading assets based on the `ward_inventory`.

### B. State Management (`lib/services/`)
- `WardProvider`: A `ChangeNotifier` that interfaces with a new `WardSocketService`.
- **Socket Client:** Expand the existing socket connection logic to handle the new `ward_*` events, updating the `WardProvider` state dynamically.

## 4. Implementation Steps
1. **Phase 1: Database & API** - Create the schema migrations and basic REST endpoints for Ward management (CRUD).
2. **Phase 2: Real-time Socket Events** - Implement the lobby and voting logic in `socketService.js`.
3. **Phase 3: Frontend Provider** - Build the `WardProvider` and connect it to the Socket.IO client.
4. **Phase 4: UI/UX** - Build the `WardLobbyScreen` and `WardRoundScreen`.
5. **Phase 5: Economy & Polish** - Implement Ward XP and exclusive Ward Decor logic.
