## 2024-07-06 - Missing Tooltips on Icon-Only Buttons
**Learning:** Found multiple instances of icon-only `IconButton`s missing `tooltip` attributes in admin table components (e.g., `QuestionsDataTable`, `ECGCasesTable`). This makes them inaccessible to screen readers and unclear to users without icon familiarity.
**Action:** Always add descriptive `tooltip` properties to `IconButton` widgets when they lack visible text labels, especially in data tables and interactive lists.
