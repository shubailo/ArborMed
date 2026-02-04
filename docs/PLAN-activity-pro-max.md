# PLAN: Activity Page Redesign & Functional Upgrade (Pro Max)

Upgrade the User Activity page into a high-performance, sensory-rich academic dashboard that prioritizes mistake-based learning and clinical aesthetics.

## User Review Required

> [!IMPORTANT]
> **Functional Scope**: "Review Mistakes" is filtered by the currently active timeframe (Day/Week/Month).
> **Fixed Standard**: Daily Goal is locked to 50 questions for consistency.
> **Sensory Elements**: Haptic feedback and subtle glow effects will be added to data interactions.

## Proposed Changes

---

### Phase 1: Backend Intelligence
Update the analytics layer to support granular mistake retrieval and performance trends.

#### [MODIFY] [statsController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/statsController.js)
- **Mistake Engine**: Implement `getMistakesByTimeframe` to return specific missed question IDs.
- **Label Logic**: Update `getActivity` to return localized day/date names for the X-axis.

#### [MODIFY] [statsRoutes.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/routes/statsRoutes.js)
- Register route: `GET /api/stats/mistakes`.

---

### Phase 2: Pro Max Visualization
Transform the charts into interactive, "Cozy" clinical tools.

#### [MODIFY] [activity_chart.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/analytics/activity_chart.dart)
- **Cozy Canvas**: `paperCream` background + `PaperTexture` overlay.
- **Fluid UI**:
  - Use `sageGradient` for bars.
  - Implement **Glow Shadows** on selected bars.
  - Add **Haptic Pulse** triggers on bar selection.
- **Loading UX**: Implement `CozyChartSkeleton` with shimmering sage gradients.

#### [MODIFY] [activity_view.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/profile/activity_view.dart)
- **Daily Prescription**: A prominent "Call to Action" card for finishing daily goals.
- **Bullet Chart**: Replace circles with a medical-style linear Bullet Chart for goals.
- **Leaf Streaks**: Growing sage leaf animation for consistency tracking.
- **Inky Ripple**: Custom ripple effects for the "Review Mistakes" button.

---

### Phase 3: Interactive Services & Logic

#### [MODIFY] [stats_provider.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/services/stats_provider.dart)
- New method `fetchMistakesForReview()` to trigger custom quiz sessions.
- State management for Daily Goals and active timeframe filters.

---

## Verification Plan

### Automated Tests
- `npm run test`: Verify `getMistakesByTimeframe` returns correct IDs for a test user.

### Manual Verification
1. **Sensory Test**: Confirm haptic feedback triggers on both Android and iOS (if applicable).
2. **Visual Audit**: Compare chart styling against `CozyCard` and `CozyTheme` palette.
3. **Logic Loop**: Miss 3 questions → Go to Activity → Tap "Review Mistakes" → Ensure those 3 questions appear.
4. **Shimmer Test**: Throttled network test to observe `CozyChartSkeleton`.

---

## Agent Assignments
- **Backend Specialist**: Phase 1
- **Frontend Specialist**: Phase 2 (Design Focus)
- **Mobile Developer**: Phase 2 (Haptics/Logic) & Phase 3
