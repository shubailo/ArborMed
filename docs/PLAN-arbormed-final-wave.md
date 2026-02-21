# ArborMed 2.0 Final Wave Plan

## Overview
Implement the final major feature wave for the ArborMed 2.0 Student App release.
**Goals:** Add Daily Prescription tracking, Smart Review recommendations, an animated "Living Bean" companion, and a non-intrusive Ambient Audio system using legacy assets. All changes must seamlessly integrate with the existing Cozy Clinical aesthetic, Mistake Review, and Social features.

**User Decisions Incorporated:**
- **Ambient Audio:** Mix with other system audio (duck/mix). Do not pause external music/podcasts. Include a global on/off toggle.
- **Smart Review:** Act as a prominent alternative CTA (not a strict override) next to "Start Quiz" to maintain user agency.
- **Daily Prescription:** Compute daily reset using the client's local timezone (client sends timezone offset or local 'today' date to backend).

## Project Type
**MOBILE** (Primary) with minor **BACKEND** enhancements.
- Primary Agent: `mobile-developer`
- Secondary Agent: `backend-specialist`

## Success Criteria
1. **Daily Prescription:** Shows accurate question progress based on local user time. Tap shows explanatory panel. Color shifts to Sage Green on completion.
2. **Smart Review:** Appears prominently next to Start Quiz when appropriate (low accuracy + mistakes exist). Correctly routes to Mistake Review.
3. **Living Bean:** Idle breathing animation runs smoothly. Bean reacts to taps. Mood updates based on streak/daily progress.
4. **Ambient Audio:** Legacy cozy clinical audio loop plays when enabled and mixes well with external audio apps. UI clicks trigger successfully.
5. **Stability:** SM-2 engine logic and professor dashboard backend contracts are untouched and unbroken.

## Tech Stack
- **Flutter:** Mobile UI, state management (Riverpod), animations, audio playback (`audioplayers` or `just_audio` with `mixWithOthers` config).
- **Node.js / Express / Prisma:** Lightweight calculation endpoint for daily question counts.

## File Structure (Planned Changes)
- `apps/student_app/lib/features/progress/` -> Add Daily Prescription UI components and providers
- `apps/student_app/lib/features/room/presentation/widgets/` -> Update Room HUD CTAs and `BeanAvatarWidget` animations
- `apps/student_app/lib/core/audio/` -> New `AudioManager` service
- `services/backend/src/routes/` & `controllers/` -> Add `GET /analytics/user/:userId/course/:courseId/daily-prescription`
- `services/backend/src/services/` -> Add daily prescription calculation logic

## Task Breakdown

### Task 1: Backend - Daily Prescription Endpoint
- **Agent:** `backend-specialist`
- **Skills:** `api-patterns`
- **Priority:** P1
- **INPUT:** Request to fetch daily prescription with user ID, course ID, and local timezone offset.
- **OUTPUT:** `GET /analytics/user/:userId/course/:courseId/daily-prescription` endpoint returning `answeredToday` and `targetQuestions` (e.g., default 40).
- **VERIFY:** Manual test via Postman/cURL confirming successful payload calculation based on provided timezone offset over the midnight boundary.

### Task 2: Flutter - Audio Manager & Assets
- **Agent:** `mobile-developer`
- **Skills:** `mobile-design`
- **Priority:** P1
- **INPUT:** Existing legacy audio assets (ambient loops, UI clicks) in the archive folder.
- **OUTPUT:** `AudioManager` standardizing `just_audio` or similar, configured to **mix with other apps**. Add a global mute toggle in Settings/HUD.
- **VERIFY:** Start background music (like Spotify) on emulator/device, open app, confirm ArborMed audio plays softly without pausing the external music.

### Task 3: Flutter - Living Bean Animation & Mood
- **Agent:** `mobile-developer`
- **Skills:** `mobile-design`
- **Priority:** P2
- **INPUT:** Static `BeanAvatarWidget`.
- **OUTPUT:** Refactored `BeanAvatarWidget` with idle breathing animation, tap reactions, and a mood state derived heuristically from app data.
- **VERIFY:** Bean animates naturally without dropping frames, reacts to clicks, and changes expression based on current mock/real data (e.g. happy for completed goals).

### Task 4: Flutter - Daily Prescription Bar
- **Agent:** `mobile-developer`
- **Skills:** `mobile-design`
- **Priority:** P2
- **INPUT:** Backend Daily Prescription endpoint, Room HUD widget.
- **OUTPUT:** A pill-shaped progress bar layered in the Room HUD showing local completion rate. Tapping displays info panel.
- **VERIFY:** Bar fills visually correctly according to fetched data; turns Sage Green upon 100% completion.

### Task 5: Flutter - Smart Review CTA
- **Agent:** `mobile-developer`
- **Skills:** `mobile-design`
- **Priority:** P2
- **INPUT:** Room HUD layout, activity trend/mistake data.
- **OUTPUT:** A prominent "Smart Review" button rendered alongside the normal "Start Quiz" button when triggered by data rules. Routes properly.
- **VERIFY:** Button appears when `hasRecentMistakes` and `<85%` accuracy conditions are met. Clicking routes into `MistakeReviewIntroPanel`.

## ✅ PHASE X: Verification Checklist
- [ ] Lint: `npm run lint` and `flutter analyze` pass.
- [ ] Build: Backend and Flutter builds succeed.
- [ ] No regressions in SM-2 spacing algorithm execution.
- [ ] No standard template layouts used (mobile-design rules applied).
- [ ] Audio respects the mix/duck requirement and does not pause Spotify/podcasts.
- [ ] Date: [Current Date]
