# PROJECT PLAN: Admin Actions & Medical Inbox

## CONTEXT
The MedBuddy application needs a way for administrators to manage user roles (student/admin), delete users, and send direct messages. Students need a centralized "Medical Inbox" (Pager) to receive these admin alerts as well as peer consultation notes.

## PHASE 1: SYSTEM ARCHITECTURE
- **Backend**: Update PostgreSQL schema to include a `notifications` table. Implement role-based action routes in `adminRoutes.js`.
- **Frontend**: Transition the simple "Medical Network" sheet into a complex `NetworkPortal` with a 2-page tab system.

## PHASE 2: TASK BREAKDOWN

### 1. Backend & DB
- Create table `notifications` (user_id, message, type, is_read).
- Create `adminController.js` for role switching and deletion.
- Create merged Inbox endpoint (Admin messages + Peer notes).

### 2. Flutter Social Refactor
- Create `NotificationProvider` for state management.
- Build `PagerView` for the Social hub.
- Design `PagerItem` widget for different notification types.

### 3. Admin Panel Update
- Update `AdminUsersScreen` with a dual-tab layout (Students vs Admins).
- Implement Contextual Action Buttons in the user table.

## PHASE 3: VERIFICATION
- [ ] Promote student -> Admin access check.
- [ ] Admin message -> Notification list check.
- [ ] Mark notification as read -> persistence check.
