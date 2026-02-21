# PLAN: Prof Analytics 2.0 (M5)

Comprehensive professor-facing dashboard with historical mastery data, Bloom-level breakdown by topic, and student engagement metrics.

## Proposed Changes

### Backend (services/backend)

#### [MODIFY] [AnalyticsController.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/controllers/AnalyticsController.ts)
- Add `getMasteryOverTime(req, res)` method.
- Add `getTopicBloomBreakdown(req, res)` method.
- Add `getEngagement(req, res)` method.

#### [MODIFY] [AnalyticsService.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/AnalyticsService.ts)
- Implement `calculateMasteryOverTime(courseId)`:
    - Aggregate `StudyEvent` or `UserMastery` data by date.
    - Calculate average mastery per day for the entire course duration.
- Implement `calculateTopicBloomBreakdown(courseId)`:
    - Group performance by `topicId` and `bloomLevel`.
    - Calculate `correctRate` and `avgMastery`.
- Implement `calculateEngagement(courseId)`:
    - Aggregate `StudyEvent` counts (questions per day).
    - Aggregate `Purchase` data and `UserRoomItem` customization rates.

#### [MODIFY] [routes.ts](file:///c:/Users/shuba/Desktop/Med_buddy/services/backend/src/services/routes.ts)
- Register the new endpoints. (Need to find the exact route file)

---

### Prof Dashboard (apps/prof-dashboard)

#### [MODIFY] [package.json](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/package.json)
- Add `recharts` dependency.

#### [NEW] [MasteryOverTimeChart.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/components/charts/MasteryOverTimeChart.tsx)
- Recharts LineChart showing mastery progress over time.

#### [NEW] [TopicBloomBreakdownChart.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/components/charts/TopicBloomBreakdownChart.tsx)
- Recharts Stacked BarChart showing Bloom levels per topic.

#### [NEW] [EngagementOverview.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/components/charts/EngagementOverview.tsx)
- Informational cards for engagement metrics.

#### [MODIFY] [page.tsx](file:///c:/Users/shuba/Desktop/Med_buddy/apps/prof-dashboard/src/app/courses/[courseId]/page.tsx)
- Integrate new components into the layout.
- Implement data fetching for the new endpoints.

---

## Verification Plan

### Automated Tests
- Create unit tests for the new `AnalyticsService` methods to ensure correct aggregation logic.
- Run `npm test` in `services/backend`.
- Run `turbo run build` to ensure no regression in types or build process.

### Manual Verification
- **Backend**:
    - Use `curl` or Postman to verify the JSON structure of the new endpoints:
        - `GET /analytics/course/:courseId/mastery-over-time`
        - `GET /analytics/course/:courseId/topic-bloom-breakdown`
        - `GET /analytics/course/:courseId/engagement`
- **Frontend**:
    - Navigate to the Course page in `prof-dashboard`.
    - Verify charts render correctly with data.
    - Check tooltips and legend alignment.
