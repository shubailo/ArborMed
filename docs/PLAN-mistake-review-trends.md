# PLAN: Mistake Review & Activity Trends

Implement two legacy-inspired student-side learning tools: **Mistake Review** (focused error correction) and **Activity Trends** (visual progress tracking).

## User Review Required

> [!IMPORTANT]
> Please provide feedback on the following implementation details:
> 1. **Selection Logic**: Should we prioritize the 14-day recent mistakes or all-time frequent mistakes?
> 2. **Session Persistence**: Once recent mistakes are cleared, do we show "All caught up" or dip into older history?
> 3. **Chart Style**: Preferred visualization (Combined Bar/Line or separate cards)?
> 4. **SM-2 Impact**: Confirm that Mistake Review *should* update the primary spaced repetition intervals (`UserMastery`).
> 5. **Session Type**: New `StudySession` or just a metadata tag?

## Proposed Changes

### [Component] Backend - Study & Analytics

#### [MODIFY] [AdaptiveEngineService.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/AdaptiveEngineService.ts)
- Update `getNextQuestion` to accept a `mode` parameter.
- Implement specialized sub-selection logic for `mode === 'MISTAKE_REVIEW'`:
  - Query `StudyEvent` for incorrect answers by this user.
  - Join with `Question` and `UserMastery`.
  - Prioritize recent/unresolved errors.

#### [MODIFY] [StudyController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/StudyController.ts)
- Update `getNext` to pass `mode` from query parameters to the engine.

#### [NEW] [student-analytics-service.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/StudentAnalyticsService.ts)
- Create specialized service for student-facing analytics.
- Implement `getActivityTrends(userId, courseId)` with day-by-day aggregation of question counts and accuracy.

#### [MODIFY] [AnalyticsController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/AnalyticsController.ts)
- Add route `GET /analytics/user/:userId/course/:courseId/activity-trends`.

---

### [Component] Flutter - Data Layer

#### [MODIFY] [study_remote_data_source.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/study/data/datasources/study_remote_data_source.dart)
- Support `mode` parameter in `getNextQuestion` API call.

#### [MODIFY] [ApiClient](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/core/network/api_client.dart)
- Add method `getActivityTrends(String userId, String courseId)`.

#### [MODIFY] [ProgressRepository](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/progress/domain/repositories/progress_repository.dart)
- Define `getActivityTrends` method.

---

### [Component] Flutter - UI/UX

#### [NEW] [mistake_review_intro_panel.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/study/presentation/widgets/mistake_review_intro_panel.dart)
- CozyPanel with explanation and "Start" button.

#### [NEW] [activity_trends_panel.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/progress/presentation/widgets/activity_trends_panel.dart)
- Chart visualization using `fl_chart` or custom painter.
- Range toggles (7d / 30d).

#### [MODIFY] [progress_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/apps/student_app/lib/features/progress/presentation/pages/progress_screen.dart)
- Integrate `ActivityTrendsPanel` at the top.
- Add "Review Mistakes" CTA if accuracy is below a threshold.

## Verification Plan

### Automated Tests
- **Backend**: `npm run test` for `AdaptiveEngineService` sub-selection.
- **Backend**: Integration test for `activity-trends` endpoint.

### Manual Verification
1. Log in as a student with existing study history.
2. Navigate to "Progress".
3. Verify Activity Trends chart renders with correct data.
4. Tap "Review Mistakes".
5. Verify the study session starts with a "Mistake Review" badge.
6. Complete the session and verify the "All caught up" screen.
