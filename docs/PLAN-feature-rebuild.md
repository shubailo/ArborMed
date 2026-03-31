# PLAN-feature-rebuild: Phase 3 Modular Migration

This plan details the "From Scratch" reconstruction of the core ArborMed features into independent, modular packages. Each feature will maintain 1:1 parity with legacy v1 logic but benefit from the new Micro-App architecture (GetIt + Isar + core_interop).

## Goal
Systematically port the Quiz, Student, and Game modules while enforcing strict modular boundaries and migrating all local storage from SQLite (Drift) to NoSQL (Isar).

## User Decisions
- **Quiz Engine**: Simplified, unified `UnifiedQuestionRenderer` for faster implementation.
- **ID Strategy**: Map legacy `int id` directly to Isar `Id` for long-term maintainability.
- **UI Design**: 1:1 parity with legacy design using `CozyTheme` tokens (no design refresh yet).
- **Game State**: Store furniture positioning directly in **Isar** collections instead of JSON strings.

---

## Phase 1: Database Architecture (Isar)
*Agent: database-architect*

- [ ] Define `Question` and `Topic` collections in `packages/core`.
- [ ] Define `QuestionStats` and `StudentProfile` collections.
- [ ] Define `FurnitureItem` collection (with x, y, z positions).
- [ ] Implement `DatabaseService` methods for CRUD on these collections.

## Phase 2: Quiz Module (Phase 3.2)
*Agent: mobile-developer*

- [ ] Initialize `packages/feature_quiz`.
- [ ] Implement `QuizService` (Isar logic for question fetching).
- [ ] Implement `UnifiedQuestionRenderer` (Simplified layout).
- [ ] Port `QuizScreen` UI (Legacy parity).
- [ ] Register `QuizContract` and `QuizRoutes`.

## Phase 3: Student Module (Phase 3.3)
*Agent: mobile-developer*

- [ ] Initialize `packages/feature_student`.
- [ ] Implement `StatsService` (Isar-backed progress calculation).
- [ ] Port `Dashboard` and `Profile` screens.
- [ ] Register routes.

## Phase 4: Game Module (Phase 3.4)
*Agent: mobile-developer + database-architect*

- [ ] Initialize `packages/feature_game`.
- [ ] Implement `ShopProvider/Service` (Isar-backed).
- [ ] Port `RoomScreen` and `ShopScreen` UI.
- [ ] Implement Isar-based item positioning logic.

## Phase 5: Verification & Integration
*Agent: test-engineer*

- [ ] Run `flutter analyze` across all new packages.
- [ ] Verify cross-module communication (e.g., Quiz completion awarding XP to Student Profile).
- [ ] Manual smoke test in Shell app.

---

## Verification Checklist
- [ ] `packages/feature_quiz` compiles with 0 errors.
- [ ] `packages/feature_student` compiles with 0 errors.
- [ ] `packages/feature_game` compiles with 0 errors.
- [ ] Isar database persists data between app restarts.
