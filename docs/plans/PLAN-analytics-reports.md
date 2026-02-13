# Analytics & Reporting Implementation Plan

## Goal Description
Implement a robust **User Reporting System** to crowdsource quality control for the Question Bank, and enhance the **Admin Question Details** view with statistical insights (difficulty, failure rates) to help administrators identify problematic content.

## User Review Required
> [!NOTE]
> **Data Privacy**: Reports are anonymous to other users but visible to admins. Standard behavior.
> **Reporting Categories**: We will use: "Wrong Answer", "Typo / Grammar", "Explanation Unclear", "Broken Image/UI".

## Proposed Changes

### Database Schema
#### [NEW] [036_question_reports.sql](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/models/036_question_reports.sql)
- Create `question_reports` table:
    - `id`, `question_id`, `user_id`, `reason_category`, `description` (optional), `status` ('pending', 'resolved', 'ignored'), `created_at`.
- Add `report_count` to `questions` table (cached counter for performance). (Optional, or just join count).
- Create `question_stats` table (Optional) or just query `responses` aggregation. *Decision*: Aggregation on `responses` is fine for now, but maybe materialize `difficulty_index` on `questions` for sorting.

### Backend (Node.js)
#### [NEW] [reportController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/reportController.js)
- `submitReport`: Record user report.
- `getReports`: Fetch reports for a question (Admin).
- `resolveReport`: Mark report as resolved.

#### [MODIFY] [adminController.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/controllers/adminController.js)
- Enhance `getAdminQuestions` to include `report_count` and detailed stats (`difficulty`, `avg_time`).

### Mobile (Student)
#### [MODIFY] [question_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/question_renderer.dart)
- Add "Report Issue" button (Icon: `Icons.flag_outlined`) to `QuestionHeader` or floating action button.
- Open `ReportIssueDialog`.

#### [NEW] [report_issue_dialog.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/report_issue_dialog.dart)
- Simple form with Reason Dropdown and Description text field.

### Mobile (Admin)
#### [MODIFY] [questions_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/questions_screen.dart)
- Update `_buildPreviewPanel` ("Question Details"):
    - **Add "Analytics" Section**:
        - Show "Difficulty Score" (Success Rate).
        - Show "Average Time".
        - **Warning Banner**: "High Failure Rate Detected" if success < 30%.
    - **Add "Reports" Section**:
        - List active reports.
        - Button to "Dismiss" or "Edit Question".

## Verification Plan

### Automated Tests
- Backend `test_reports.js`: Verify report submission and retrieval.
- DB Schema validation: Check table creation and constraints.

### Manual Verification
1.  **Student Flow**:
    -   Log in as student.
    -   Open a quiz question -> Tap "Report".
    -   Submit "Typo" report.
    -   Verify success message.
2.  **Admin Flow**:
    -   Log in as admin.
    -   Go to Question Bank -> Find reported question.
    -   Open Details Panel.
    -   Verify "Reports" section shows the new report.
    -   Verify "Difficulty" stats are visible.
