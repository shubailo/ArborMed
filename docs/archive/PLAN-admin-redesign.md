# Project Plan: Admin Enhancement (Direct Integration)

**Overview**:  
Enhance the existing "Classic" Admin Panel by injecting powerful features (Preview, Batch Upload, Segmented Analytics) without altering the familiar navigation or layout.

**Project Type**: MOBILE (Flutter)
**Strategy**: Restore & Extend
**Success Criteria**:
- [ ] **Questions**: "Preview Mode" toggle in Edit Dialog shows exact student view.
- [ ] **Data**: new "Batch Upload" button (CSV) in Questions screen.
- [ ] **Analytics**: Segmented view (Summary / Topics / ECG / Cases) in Dashboard.
- [ ] **Notifications**: Simple "Send Notification" tool.

## File Structure
```
mobile/lib/
├── screens/
│   └── admin/
│       ├── widgets/
│       │   ├── question_preview_card.dart  # [NEW]
│       │   └── question_edit_dialog.dart   # [REFINE]
│       ├── dashboard_screen.dart           # [UPDATE: Segments]
│       └── questions_screen.dart           # [FULL RESTORE + Upload]
```

## Task Breakdown

### Phase 1: Restoration (Completed)
**Agent**: `mobile-developer`
- [x] **Task 1.1**: Restore `admin_shell.dart`.
- [x] **Task 1.2**: Restore `dashboard_screen.dart`.
- [ ] **Task 1.3**: Fully rebuild `questions_screen.dart` with standard CRUD logic (currently a stub).

### Phase 2: Question Power Tools
**Agent**: `mobile-developer`

- [ ] **Task 2.1**: Implement `QuestionPreviewCard`.
    - *Input*: `Question` model.
    - *Output*: UI matching `QuizCard` (Student View).
- [ ] **Task 2.2**: Update `QuestionEditDialog`.
    - *Feature*: Add "Preview" Switch.
    - *Logic*: When true, flip card to show `QuestionPreviewCard`.
- [ ] **Task 2.3**: Implement Batch Upload UI.
    - *Feature*: IconButton in `QuestionsScreen` AppBar.
    - *Action*: Pick CSV -> Parse -> API Call.

### Phase 3: Dashboard Segments
**Agent**: `frontend-specialist`

- [ ] **Task 3.1**: Add `SegmentedButton` to `DashboardScreen`.
    - *Options*: Summary, Topics, ECG, Cases.
- [ ] **Task 3.2**: Filter Analytics Data.
    - *Logic*: Update graphs/KPIs based on selected segment.

### Phase 4: Notifications (Simple)
**Agent**: `backend-specialist` + `mobile-developer`

- [ ] **Task 4.1**: Create `NotificationService` (Backend stub).
- [ ] **Task 4.2**: Add "Send Notification" FAB to Admin Shell.
    - *Action*: Simple dialog (Title, Body, "Send to All").

## Phase X: Verification
- [ ] **Preview**: Toggling preview matches student UI exactly.
- [ ] **Upload**: CSV upload handles errors gracefully.
- [ ] **Segments**: Switching dashboard tabs updates numbers.

## ✅ PHASE X COMPLETE
- Lint: [ ]
- Security: [ ]
- Build: [ ]
