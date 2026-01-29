# PLAN-agoom-unified

> **Status**: APPROVED (Option B)
> **Architecture**: Unified Backbone (Flutter + Node.js/Postgres)

## 1. Overview
This plan implements the **AGOOM (Adaptive Gamified Oriented Medical-learning)** platform using a "Unified Backbone" approach.
-   **Clients**: Flutter Mobile App (Premium UI/Animations)
-   **Backend**: Node.js + Express + PostgreSQL (dockerized)
-   **Logic**: Adaptive Engine moves to the Backend for centralized control and analytics.

## 2. Success Criteria
1.  **Backend Live**: Node.js API running with connected PostgreSQL (Docker).
2.  **Schema Validated**: Relational tables for Users, Questions, Topics, and ExamSessions.
3.  **Adaptive Engine API**: Endpoint `GET /next-question` returns intelligently selected questions based on Bloom/History.
4.  **Mobile MVP**: Flutter app installs, authenticates, and plays a full quiz session via the API.
5.  **Gamification**: Student dashboard displays real stats from the SQL DB.

## 3. Tech Stack
| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Mobile** | **Flutter** | High-fidelity animations (Bean character), cross-platform, "Game" feel. |
| **Backend** | **Node.js + Express** | User requested standard stack. Unified logic for Web/Mobile. |
| **Database** | **PostgreSQL** | Relational integrity for complex medical taxonomies and question banks. |
| **Infra** | **Docker** | Easy local database orchestration. |
| **Auth** | **JWT / Custom** | Simple stateless auth for MVP (or Clerk if specified previously, sticking to custom/JWT for "Backend" control unless Auth provider specified). *Decision: Custom JWT for now to match Express standard.* |

## 4. File Structure
```
med_buddy/
├── backend/                # Node.js + Express
│   ├── src/
│   │   ├── config/         # DB connection
│   │   ├── controllers/    # Route handlers
│   │   ├── services/       # Business Logic (Adaptive Engine here)
│   │   ├── models/         # SQL definitions
│   │   └── routes/
│   ├── tests/
│   ├── docker-compose.yml
│   └── package.json
├── mobile/                 # Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/       # API Clients (Http)
│   │   ├── models/         # Dart Models
│   │   ├── screens/
│   │   └── widgets/
│   └── pubspec.yaml
└── PLAN-agoom-unified.md
```

## 5. Task Breakdown

### Phase 1: Foundation (Backend & DB)
- [ ] **Setup Backend Project**: Init `backend` folder, `package.json`, install `express`, `pg`, `dotenv`. <!-- id: 1 -->
- [ ] **Docker Postgres**: Create `docker-compose.yml` for PostgreSQL. Verify connection. <!-- id: 2 -->
- [ ] **Database Schema**: Create SQL migration for `users`, `topics`, `questions`, `quiz_sessions`, `responses`. <!-- id: 3 -->
- [ ] **Seed Data**: Insert the 6 Medical Topics and 10 dummy questions with Bloom/Difficulty ratings. <!-- id: 4 -->

### Phase 2: Core API (The "Brain")
- [ ] **Auth Endpoints**: Implement `POST /auth/register` and `POST /auth/login` (JWT). <!-- id: 5 -->
- [ ] **Adaptive Engine Service**: Port logic from Guide (Section 2) to Node.js.
    -   *Logic*: Calculate `next_bloom` and `next_difficulty` based on recent `responses`. <!-- id: 6 -->
- [ ] **Quiz Endpoints**:
    -   `POST /quiz/start` (Create session)
    -   `GET /quiz/next` (Uses Adaptive Engine)
    -   `POST /quiz/answer` (Record response & update stats) <!-- id: 7 -->

### Phase 3: Mobile Setup (Flutter)
- [ ] **User Action**: Install Flutter SDK (Pre-requisite). <!-- id: 8 -->
- [ ] **Init Mobile App**: Run `flutter create mobile`. <!-- id: 9 -->
- [ ] **Project Structure**: Create folders `screens`, `services`, `models` matching Guide. <!-- id: 10 -->
- [ ] **Dependencies**: Add `http` (for API), `provider` (state), `fl_chart` (radar). <!-- id: 11 -->

### Phase 4: Mobile Implementation
- [ ] **API Client**: Create `ApiService` in Dart to talk to Node.js backend (replace Firebase calls). <!-- id: 12 -->
- [ ] **Auth Screens**: Login/Register UI connecting to `POST /auth/login`. <!-- id: 13 -->
- [ ] **Dashboard**: Display User Stats (API call) with mocked Radar Chart initially. <!-- id: 14 -->
- [ ] **Quiz Flow**:
    -   Fetch Question (loading state)
    -   Display Options
    -   Submit Answer
    -   Show Feedback <!-- id: 15 -->

### Phase 5: Verification (Phase X)
- [ ] **Backend Tests**: Jest tests for Adaptive Logic (ensure level increases on correct answers). <!-- id: 16 -->
- [ ] **E2E Test**: Manual walkthrough: Register -> Start Quiz -> Answer 3 Correct -> Verify Difficulty Increase. <!-- id: 17 -->

## ✅ PHASE X COMPLETE
- Lint: [ ]
- Security: [ ]
- Build: [ ]
