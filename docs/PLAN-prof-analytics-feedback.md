# PLAN: Engine Feedback in Prof Analytics (M6.1)

This plan documents the implementation of Milestone 6.1, which focuses on providing feedback to professors about the adaptive engine's performance (retention) and the curriculum's Bloom-level coverage and mastery.

## Proposed Changes

### Backend (services/backend)

#### [MODIFY] [AnalyticsService.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/AnalyticsService.ts)
- Implement `getRetentionOverTime(courseId: string)`:
    - Queries `StudyEvent` for the last 30 days.
    - Filters for "review" events. *Note: A review event will be defined as an event for a question that already had a corresponding UserMastery entry at the time of the event.*
    - Groups by date and calculates `correctCount / totalCount`.
    - Returns an array of `RetentionPointDto`.
- Implement `getBloomUsageSummary(courseId: string)`:
    - Queries all `Question` records for the course to calculate `questionCount` per Bloom level (1-6).
    - Queries `UserBloomMastery` to calculate `avgMasteryScore` per Bloom level (1-6).
    - Ensures all 6 levels are returned, even with 0 counts.

#### [MODIFY] [AnalyticsController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/AnalyticsController.ts)
- Add `getRetentionOverTime` method to handle `GET /analytics/course/:courseId/retention-over-time`.
- Add `getBloomUsageSummary` method to handle `GET /analytics/course/:courseId/bloom-usage-summary`.

---

### Prof Dashboard (apps/prof-dashboard)

#### [NEW] [RetentionOverTimeChart.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/components/charts/RetentionOverTimeChart.tsx)
- Use Recharts `AreaChart` or `LineChart`.
- Display a shaded `ReferenceArea` between 85% and 90% (0.85 - 0.90) to represent the target retention band.
- Plot `actualRetention` as a line.

#### [NEW] [BloomUsageSummaryChart.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/components/charts/BloomUsageSummaryChart.tsx)
- Use Recharts `ComposedChart`.
- Bar Chart for `questionCount` (Primary Y-axis).
- Line Chart for `avgMastery` (Secondary Y-axis, 0-100%).
- X-axis labeled with Bloom level names (Remember, Understand, Apply, Analyze, Evaluate, Create).

#### [MODIFY] [page.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/app/courses/[courseId]/page.tsx)
- Fetch data from the two new endpoints.
- Integrate the new charts into the layout:
    - `RetentionOverTimeChart` placed near "Mastery Growth".
    - `BloomUsageSummaryChart` placed as a new section for Bloom usage insights.

## Verification Plan

### Automated Tests
- [ ] Backend: Manual verification of endpoint JSON response using `curl` or a test script.
- [ ] Backend: Check that retention calculations correctly handle cases with no review events on certain days (should return 0 or omit).

### Manual Verification
- [ ] Open the Prof Dashboard course page.
- [ ] Verify `RetentionOverTimeChart` shows the shaded target band (85-90%).
- [ ] Verify `BloomUsageSummaryChart` correctly displays all 6 Bloom levels, including those with 0 questions.
- [ ] Check Tooltips for correct data mapping.
