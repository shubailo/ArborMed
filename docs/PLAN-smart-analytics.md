# PLAN-smart-analytics: Deep Learning Analytics & Smart Review

> **Status:** PROPOSED
> **Goal:** Implement a prediction-based analytics engine using a Time-Decay model to provide "Smart Review" recommendations and Exam Readiness scoring.
> **UX Priority:** "Insightful & Actionable" - Don't just show data, show *what to do next*.

## 1. Overview
MedBuddy helps students pass exams. Current analytics are reactive (what did I do?). We need predictive analytics (what should I do?).
This feature introduces:
1.  **Time-Decay Model**: Tracks memory stability/retention for every topic.
2.  **Smart Review**: Daily generated quiz deck targeting "about to forget" items.
3.  **Weakness Heatmap**: Visual chart (Radar/Treemap) showing proficiency gaps.
4.  **Admin User Insights**: Detailed view for admins to monitor student readiness.

## 2. Project Type
**HYBRID**
- **Backend**: Node.js + PostgreSQL (Analytics Engine, Cron Jobs).
- **Mobile**: Flutter (Student Charts, Smart Review UI, Admin Charts).

## 3. Success Criteria
- [ ] **Algorithm**: Time-Decay model correctly identifies "stale" topics vs "mastered" topics.
- [ ] **Engagment**: Students use "Smart Review" daily.
- [ ] **Admin**: Admins can identify "at-risk" students (low retention score).
- [ ] **Performance**: Dashboard loads < 2s with heavy aggregation queries.

## 4. Tech Stack & Architecture
- **Backend (Node.js/Express)**:
    - New tables: `topic_retention`, `analytics_snapshots`.
    - Algorithm: Exponential decay based on `last_reviewed` and `last_score`.
    - API: `/api/analytics/smart-review`, `/api/analytics/readiness`.
- **Database (PostgreSQL)**:
    - Efficient aggregation queries for large datasets.
- **Mobile (Flutter)**:
    - Library: `fl_chart` for Radar/Line charts.
    - New Screens: `SmartReviewScreen`, `AnalyticsDetailScreen`.

## 5. File Structure
```
backend/
├── src/
│   ├── services/
│   │   ├── analyticsEngine.js    # [NEW] Time-decay logic
│   │   └── scheduler.js          # [MODIFY] Daily snapshots
│   ├── controllers/
│   │   └── analyticsController.js # [UPDATE]
│   └── models/
│       └── Retention.js          # [NEW]
mobile/
├── lib/
│   ├── screens/
│   │   ├── smart_review/         # [NEW]
│   │   └── admin/
│   │       └── user_detail_view.dart # [UPDATE]
│   ├── widgets/
│   │   └── charts/               # [NEW] Radar/Treemap widgets
│   └── services/
│       └── analytics_service.dart # [NEW]
```

## 6. Implementation Tasks

### Phase 1: Data & Backend (The Brain)
- [ ] **DB Schema**:
    - Add `retention_score` (0-100 float) to `user_topic_progress`.
    - Add `stability` (days until decay) to `user_topic_progress`.
- [ ] **Analytics Engine**:
    - Implement `calculateRetention(lastScore, daysSinceReview)` function.
    - Implement `updateStability(currentStability, isCorrect)` (e.g., multiplier for correct answers).
- [ ] **API Endpoints**:
    - `GET /stats/smart-review`: Returns list of questions/topics due for review.
    - `GET /stats/readiness`: Returns weighted readiness score 0-100%.

### Phase 2: Mobile UI - Student (The Feedback)
- [ ] **Smart Review Card**:
    - Add "Smart Review" card to Home Dashboard.
    - Animation: "Scanning memory..." -> "30 questions ready".
- [ ] **Analytics Detail Screen**:
    - **Radar Chart**: 5 axes (Pathology, Anat, etc.) showing Mastery vs Retention.
    - **Retention Curve**: Line graph showing estimated forgetting curve.

### Phase 3: Mobile UI - Admin (The Monitor)
- [ ] **Student Detail Update**:
    - Add "Exam Readiness" badge (Red/Yellow/Green).
    - Insert "Weakness Radar" into Admin User View.

## 7. Verification Checklist
### Automated
- [ ] **Unit Tests**: Verify `calculateRetention` drops score correctly over time (e.g., 100 -> 80 after 7 days).
- [ ] **Integration Tests**: Verify `Smart Review` fetches questions from low-retention topics.

### Manual
- [ ] **Visual Check**: Radar chart renders correctly with valid data.
- [ ] **Admin Check**: Use Admin account to view a student's analytics.
- [ ] **Performance**: Check load time of "Smart Review" generation.

## ✅ PHASE X COMPLETE
- Lint: [ ]
- Security: [ ]
- Build: [ ]
