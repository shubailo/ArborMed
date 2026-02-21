# Codebase Simplification Plan

This plan outlines the systematic refinement of the `Med-Buddy` codebase to improve clarity, maintainability, and type safety, following the principles of the `@code-simplifier` agent.

## Goal
Improve code quality by standardizing patterns, removing redundant logic (error handling), and enforcing strict types across the monorepo.

## Proposed Changes

### [Component] Backend Refinement (`services/backend`)

#### Patterns & Consistency
- **Standard Methods**: Convert class property arrow functions in controllers to standard class methods.
- **Error Handling**: Remove explicit `try/catch` blocks in controllers; rely on the global `errorMiddleware`.
- **Function Keyword**: Prefer `function` for top-level utility functions.

#### Type Safety
- **Strict Service Returns**: Define interfaces for all service methods in `AdaptiveEngineService` and `RewardService` to replace `any`.
- **Typed Express Locals**: Ensure `req.user` usage is properly typed (via declaration merging or explicit casting).

### [Component] Professor Dashboard Refinement (`apps/prof-dashboard`)

#### UI Clarity
- **Component Patterns**: Ensure all functional components use the `function` keyword and have explicit `Props` types.
- **Data Fetching**: Consolidate `useEffect` fetch patterns into reusable hooks or cleaner async functions.

---

## Verification Plan

### Automated Tests
- `npm run test` in `services/backend` to ensure business logic integrity.
- `npx tsc --noEmit` in both backend and dashboard to verify strict typing.

### Manual Verification
1. **API Error Handling**: Verify that removing `try/catch` correctly feeds errors to the global middleware and returns JSON.
2. **Dashboard Rendering**: Verify that component refactors don't break the Next.js hydration or data flow.
