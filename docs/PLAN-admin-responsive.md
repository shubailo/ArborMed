# Project Plan: Admin Responsive Redesign (Option B)

**Overview**:  
Transform the existing Admin Panel into a responsive, productivity-focused "Command Center" that works beautifully on both Desktop (Teacher's primary tool) and Mobile. The design will adapt dynamically: high-density "Split Views" and "Masonry Grids" on large screens, and familiar "Stack Support" on mobile.

**Project Type**: MOBILE (Flutter)
**Strategy**: Responsive Refactor
**Success Criteria**:
- [ ] **Shell**: Shows `NavigationRail` (Collapsible) on Desktop, `BottomNavigationBar` on Mobile.
- [ ] **Dashboard**: Uses `flutter_staggered_grid_view` for a "Bento Box" layout.
- [ ] **Questions**: Desktop shows "Master-Detail" (List left, Review right). Mobile uses standard list.
- [ ] **Data**: Bulk Upload via CSV (Simple loop processing).

## Tech Stack
- **Flutter**: Core framework.
- **Provider**: State management.
- **flutter_staggered_grid_view**: For the dynamic "Bento Box" dashboard layout (Recommended for Teachers).
- **Material 3**: For `NavigationRail`, `SegmentedButton`.

## File Structure
```
mobile/lib/
├── screens/
│   └── admin/
│       ├── responsive/
│       │   ├── admin_responsive_shell.dart  # [NEW] Handles Rail vs BottomBar
│       │   └── split_view_scaffold.dart     # [NEW] Reusable Master-Detail layout
│       ├── components/
│       │   ├── dashboard_masonry.dart       # [NEW] Staggered Grid for KPIs
│       │   └── question_preview_card.dart   # [NEW] Shared Component
│       ├── dashboard_screen.dart            # [UPDATE] Uses Masonry on Desktop
│       └── questions_screen.dart            # [UPDATE] Uses SplitView on Desktop
```

## Task Breakdown

### Phase 1: Responsive Foundation
**Agent**: `mobile-developer`

- [ ] **Task 1.1**: Install `flutter_staggered_grid_view`.
    - *Action*: `flutter pub add flutter_staggered_grid_view`.
- [ ] **Task 1.2**: Create `AdminResponsiveShell`.
    - *Input*: `LayoutBuilder`.
    - *Logic*: If `width > 900`, show `NavigationRail` (Left). Else, show `BottomNavigationBar`.
    - *Feature*: Rail should be collapsible (Icon only vs Icon+Text) for "Focus Mode".

### Phase 2: The "Bento" Dashboard
**Agent**: `mobile-developer`

- [ ] **Task 2.1**: Implement `DashboardMasonry`.
    - *Design*: Create distinct "Tiles": `KpiTile` (Small), `ChartTile` (Large), `ListTile` (Medium).
    - *Logic*: Use `StaggeredGrid.count` to arrange them.
- [ ] **Task 2.2**: Integrate `SegmentedButton`.
    - *Feature*: Toggle between "Overview", "Topics", "ECG".
    - *Effect*: Animates the Masonry tiles to show relevant data.

### Phase 3: Split-View Questions (The "Commander" View)
**Agent**: `mobile-developer`

- [ ] **Task 3.1**: Create `QuestionPreviewCard`.
    - *Goal*: A pure UI widget that renders a `Question` exactly as a student sees it.
- [ ] **Task 3.2**: Refactor `QuestionsScreen` for Split View.
    - *Logic*: 
        - **Mobile**: `ListView` -> Tap -> Open `EditDialog`.
        - **Desktop**: `Row(Flex 1 (List) | Flex 2 (Preview))`.
        - *Selection*: Tapping a question in the list updates the Preview pane instantly.
- [ ] **Task 3.3**: Batch Upload Action.
    - *UI*: "Upload CSV" button in the "Action Bar".
    - *Flow*: File Picker -> Parse -> Loading Indicator -> Refresh List.

### Phase 4: Notifications (Quick Win)
**Agent**: `backend-specialist`

- [ ] **Task 4.1**: Simple Notification Sender.
    - *UI*: FAB in `AdminResponsiveShell` (Desktop: Top Right, Mobile: Bottom Right).
    - *Action*: Send push notification to all users.

## Phase X: Verification
- [ ] **Responsive**: Resize window from 400px to 1200px. Shell transitions smoothly.
- [ ] **Dashboard**: Titles rearrange in the Masonry layout without error.
- [ ] **Preview**: Editing a question in split View updates the preview instantly.
- [ ] **Upload**: Uploading 50 lines of CSV works and refreshes the list.

## ✅ PHASE X COMPLETE
- Lint: [ ]
- Security: [ ]
- Build: [ ]
