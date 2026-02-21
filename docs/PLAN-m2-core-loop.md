# Project Plan: M2 - Core Loop Online (Study Flow)

## 1. Overview
The goal is to implement the M2 milestone: a complete functional study loop where a student can log in, fetch an adaptive question, answer it, and submit the result back to the server for Mastery tracking. 
Because we **already built** a highly advanced `AdaptiveEngineService` and `Prisma Schema` using Turborepo in the previous session, we will NOT downgrade the schema. Instead, we will wrap our advanced engine in the 3 requested Express REST endpoints, setup the Flutter app with Drift and Dio, and polish the Turborepo configuration.

## 2. Project Type
**FULL STACK** (Node.js Backend & Flutter Mobile)

## 3. Success Criteria
- [ ] `turbo run dev` successfully boots both the Node.js backend and a Flutter build environment.
- [ ] Backend exposes `/auth/login`, `/study/next/:userId`, and `/study/answer`.
- [ ] Flutter app uses **Dio** to fetch the next question from the backend and **Drift** to cache it locally.
- [ ] User can click "Next Question" in Flutter, see a question, tap an answer, and submit it, triggering the backend `AdaptiveEngineService.processResult`.

## 4. Tech Stack
- **Backend:** Node.js, Express, Prisma, SQLite, Turborepo
- **Mobile:** Flutter, Riverpod, Dio, Drift

## 5. Task Breakdown

### TASK 1: Backend API Exposure (Express)
- **Agent:** `backend-specialist`
- **Steps:** 
  1. Add `src/routes/study.ts` and `src/routes/auth.ts`.
  2. Implement `POST /auth/login` (mock JWT or simple guest token for now).
  3. Implement `GET /study/next/:userId` calling `AdaptiveEngineService.getNextQuestion(userId, orgId)`.
  4. Implement `POST /study/answer` calling `AdaptiveEngineService.processResult(userId, questionId, quality)`.
  5. Mount routes in `src/app.ts`.

### TASK 2: Turborepo Pipeline Adjustments
- **Agent:** `devops-engineer`
- **Steps:**
  1. Update `turbo.json` to include `"db:generate": { "dependsOn": ["^build"] }`.
  2. Map these scripts to the root `package.json` for easy access.

### TASK 3: Flutter Architecture (Drift + Dio)
- **Agent:** `mobile-developer`
- **Steps:**
  1. Install `dio`, `drift`, `drift_dev`, `sqlite3_flutter_libs` in `apps/student_app`.
  2. Create `lib/database/database.dart` with `Questions` table.
  3. Create `lib/core/network/api_client.dart` with `ApiClient` class managing `/study/next` and `/study/answer`.
  4. Run `build_runner` to generate Drift files.

### TASK 4: Flutter UI Core Loop
- **Agent:** `mobile-developer`
- **Steps:**
  1. Create a basic Login Screen that yields a token.
  2. Create `StudyScreen` with "Next Question" button and Answer selections.
  3. Wire Riverpod providers to trigger ApiClient and update UI state (feedback animation).

## 6. Verification (Phase X)
- Run `turbo run build` across the monorepo.
- Boot backend and send `curl` requests to the 3 endpoints to verify 200 OK.
- Run `flutter test` or `flutter run` on Desktop/Web to verify the UI loop does not crash and accurately calls the backend API.
