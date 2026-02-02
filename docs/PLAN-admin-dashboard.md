## Finalized Requirements

### 1. KPI Row (Stats)
- **Total Users**: Display `stats.userStats['total_users']` instead of active students.
- **Class Average**: Display the overall correctness percentage (already calculated in existing code).
- **Class Performance**: Replace "Attendance" with **Avg Bloom Level** (`stats.userStats['avg_bloom']`).

### 2. Topic Proficiency Chart
- **Data Source**: Use `stats.sectionMastery[activeSubjectSlug]` to get a list of sections and their mastery percentages.
- **Visuals**: A vertical bar chart using `fl_chart`. X-axis = Section names, Y-axis = Mastery %.

### 3. Quick Actions
- **Download Questions**: Action to export question bank as CSV.
- **Download Users**: Action to export user performance stats as CSV.
- **Add Question**: Shortcut to navigate to the question editor.
- **Add Quote**: Shortcut to navigate to the quotes manager.
- **Send Notification**: Open a dialog to broadcast messages to students.

## Proposed Changes

### [Admin Dashboard]

#### [MODIFY] [dashboard_screen.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/dashboard_screen.dart)
- Replace masonry layout with a structured grid.
- Implement the premium header with subject dropdown (sync with `AdminQuestionsScreen` logic).
- Build the KPI Row component with trend indicators.
- Build the Quick Actions grid with the new set of tools.
- Build the `TopicProficiencyChart` component using `BarChart` from `fl_chart`.

#### [NEW] [admin_csv_helper.dart](file:///C:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/components/admin_csv_helper.dart)
- Utility to convert `AdminQuestion` and `UserStats` lists to CSV format for download.

## Verification Plan

### Manual Verification
1. Compare layout against the reference image for spacing and typography.
2. Verify KPIs update correctly when switching subjects.
3. Test CSV downloads and verify file content.
4. Verify all Quick Action buttons navigate to the correct screens/dialogs.
