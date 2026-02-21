# MASTER SPEC: MED-BUDDY CORE (M2–M8)

**Repo root:** `Med_buddy/`  
**Status:** Unified core implementation including adaptive learning engine, reward system, room customization, analytics, and observability.

---

## A. Repository & Architecture

### A.1. Monorepo Structure

- **`apps/student_app`** (Flutter)
    - Clean Architecture: `lib/features/<feature>/{presentation,domain,data}`
    - **Key Features**:
        - `study/`: Core study loop with SM-2 logic and Bloom-aware navigation.
        - `reward/`: Points system (Stethoscopes) and Shop UI.
        - `room/`: Interactive "Cozy Room" for student motivation.
        - `progress/`: Visual learning progress (Bloom ladders, topic mastery).
    - `core/network`: Dio-based API client.

- **`apps/prof-dashboard`** (Next.js)
    - Recharts-based visualizations for professors.
    - **Charts**: `RetentionOverTimeChart`, `BloomUsageSummaryChart`, `MasteryOverTimeChart`, `TopicBloomBreakdownChart`, `EngagementOverviewCards`.

- **`services/backend`** (Node/Express/Prisma/SQLite)
    - **Controllers**: `StudyController`, `RewardController`, `AnalyticsController`, `ProgressController`, `RoomController`, `DebugController`.
    - **Services**: `AdaptiveEngineService` (Core SM-2 logic), `BloomProgressService` (Bloom levels), `StudySessionService` (Telemetry).

- **`packages/shared-types`**
    - `@medbuddy/shared-types`: Unified TypeScript definitions for DTOs and models across backend and dashboard.

- **`tools/content-engine`**
    - Question bank management, Zod validation, and Prisma seeding.

---

## B. Pedagogical Intelligence (The Engine)

### B.1. Adaptive SM‑2 with Retention Tuning
- **SM-2 Algorithm**: Calculates repetition intervals based on user feedback quality (0-5).
- **Retention Control**:
    - **Target**: 85%–90% retention (measured over last 7 days or 50 reviews).
    - **Self-Correcting**: Adjusts easiness factor modifier (0.85x or 1.15x) if retention drifts outside target.

### B.2. Bloom Taxonomy Mastery
- **Bloom Levels (1–6)**: Remember, Understand, Apply, Analyze, Evaluate, Create.
- **Weighted Mastery**: Overall topic score is calculated with weights:
    - Levels 1-2: 1.0x
    - Levels 3-4: 1.5x
    - Levels 5-6: 2.0x
- **Progressive Selection**: Engine prioritizes lower Bloom levels if mastery is low; higher levels unlock as foundation stabilizes.

### B.3. Transparency (Selection Reason)
- Every `nextQuestion` API call returns a `selectionReason` string explaining the pedagogical choice (e.g., "Reviewing this due to spaced repetition needs").

---

## C. Motivational Loop (Reward & Room)

### C.1. Stethoscope Economy
- **Reward Points**: Granted for answering questions (based on difficulty and correctness).
- **Shop**: Categorized items (Decor, Furniture, etc.) for Room customization.
- **Inventory**: Supports multiple instances of the same item.

### C.2. Cozy Room Customization
- **Slot-based Layout**: Fixed slots (e.g., `wall_poster_1`, `desk_left`) to maintain aesthetic coherence.
- **Category Validation**: Frontend and backend enforce category-to-slot mapping (e.g., "poster" items only in "wall" slots).

---

## D. Professional Insight (Analytics)

### D.1. Metrics for Professors
- **Course Overview**: Student readiness, weak topics, and engagement trends.
- **Retention over Time**: Monitoring cohort memory health against the 85-90% target.
- **Bloom Coverage Gap Analysis**: Visualizing how many questions exist vs. student performance across each Bloom level.

---

## E. Observability & Telemetry (M8)

### E.1. Engine Telemetry
- **EngineDecisionLog**: Non-blocking log for every adaptive choice (bloom, difficulty, reasoning, strategy variant).
- **Strategy Variant**: Global A/B flag (`ENGINE_STRATEGY_VARIANT`) recorded with every decision.

### E.2. Session Tracking
- **StudySession**: Implicit session management with a **20-minute inactivity timeout**.
- **Metrics**: Tracks session duration, questions answered, and last activity.

### E.3. Secure Debug Export
- `/debug/engine-decisions` and `/debug/study-sessions` restricted to `localhost` + `X-ADMIN-KEY`.

---

## F. Development & Staging
- **Environment Variables**:
    - `DATABASE_URL`: SQLite path.
    - `ENGINE_STRATEGY_VARIANT`: Current engine experiment group.
    - `DEBUG_API_KEY`: Key for telemetry data export.
- **Build/Verification**: `npm run build` and `npx tsc --noEmit` enforced across backend and shared packages.
