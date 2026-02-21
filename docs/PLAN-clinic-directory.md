# Plan: Clinic Directory & Visiting Rooms (Read-only)

## Overview
Implement a read-only social layer for the Flutter student app (Med-Buddy) and required backend APIs. It includes a Clinic Directory to browse other students in the course, and a Visiting Rooms feature to view another student's clinic layout and Bean without modification abilities.

## Project Type
MOBILE (Flutter App) + BACKEND (Node.js/Prisma API)

## Success Criteria
- [ ] Backend exposes `/social/course/:courseId/clinic-directory` and `/social/room/:userId/preview?courseId=...`.
- [ ] API routes enforce access control (course membership) and are read-only.
- [ ] Clinic directory UI is accessible from `CozyActionsOverlay`.
- [ ] Users can view other students' clinic rooms (read-only mode) reusing existing `RoomLayout` logic.
- [ ] No editing, no dragging/dropping, and no purchases are possible in a visiting room.

## Tech Stack
- **Backend:** Node.js, Express, Prisma (TypeScript) - for defining the social endpoints and querying user rooms.
- **Mobile:** Flutter, Dart - for connecting to the remote APIs and rendering the read-only directory and room UI.

## File Structure
**Backend:**
- `services/backend/src/routes/socialRoutes.ts`
- `services/backend/src/controllers/SocialController.ts`
- `services/backend/src/services/SocialService.ts`

**Mobile:**
- `apps/student_app/lib/features/social/data/social_remote_data_source.dart`
- `apps/student_app/lib/features/social/data/repositories/social_repository.dart`
- `apps/student_app/lib/features/social/presentation/widgets/clinic_directory_panel.dart`
- `apps/student_app/lib/features/social/presentation/pages/visiting_room_view.dart`

## Task Breakdown

### 1. Backend Data Structures & Service Layer
- **Agent**: `backend-specialist`
- **Skills**: `nodejs-best-practices`, `api-patterns`
- **Priority**: P1
- **INPUT**: `SocialService.ts` to implement querying users per course, and retrieving room layout data without sensitive fields.
- **OUTPUT**: Two service methods for `getClinicDirectory` and `getRoomVisit`.
- **VERIFY**: Unit tests check course-membership and that only non-sensitive data (e.g., `displayName`, `overallMasteryBand`, `roomLayout`, `roomItems`) are returned.

### 2. Backend Routes & Controllers
- **Agent**: `backend-specialist`
- **Skills**: `api-patterns`
- **Priority**: P1
- **Dependencies**: 1
- **INPUT**: Integrate new Social endpoints.
- **OUTPUT**:
  - `GET /social/course/:courseId/clinic-directory`
  - `GET /social/room/:userId/preview?courseId=...`
- **VERIFY**: Access endpoints with authorization tokens. Verify they return structured payloads as defined in the spec.

### 3. Flutter Data & Repository Layer
- **Agent**: `mobile-developer`
- **Skills**: `mobile-design`
- **Priority**: P2
- **Dependencies**: 2
- **INPUT**: Add remote data sources for the custom endpoints.
- **OUTPUT**: `getClinicDirectory(courseId)` and `getRoomVisit(userId, courseId)` added to `social_remote_data_source.dart` and the repository layer.
- **VERIFY**: App can successfully decode the provided DTO instances via automated or manual testing.

### 4. Flutter Clinic Directory UI
- **Agent**: `mobile-developer`
- **Skills**: `mobile-design`, `clean-code`
- **Priority**: P2
- **Dependencies**: 3
- **INPUT**: Add "Clinic Directory" entry point to `CozyActionsOverlay`. Create `ClinicDirectoryPanel`.
- **OUTPUT**: HUD button opens a simple Ivory/Sage popup containing the list (student avatar, display name, mastery band) using state layer to load data.
- **VERIFY**: Tapping the directory opens the list correctly without obscuring the background entirely.

### 5. Flutter Visiting Room View (Read-Only)
- **Agent**: `mobile-developer`
- **Skills**: `mobile-design`, `clean-code`
- **Priority**: P2
- **Dependencies**: 4
- **INPUT**: Feed standard `RoomLayout` rendering widget with read-only state based on `RoomVisitDto`.
- **OUTPUT**: Full-screen or modal showing the visited layout and Bean. Hide "Decorate" and "Shop" tools. Disable drag/drop interactions. Provide a native "Back" button to return.
- **VERIFY**: Ensure drag-and-drop does not trigger state updates and there is no route to modify the external room.

## ✅ Phase X
- [ ] **Lint and Formatting**: `npm run lint` and `npx tsc --noEmit` pass correctly.
- [ ] **Security**: No data leaked to other clients except permitted display fields.
- [ ] **Integration Test**: Passes backend integration tests verifying course isolation.
- [ ] **UX Check**: The Directory respects the Cozy Theme.
- [ ] **Functional App Test**: Check that opening directory and visiting room works flawlessly on the UI without modifying user data.
