## 2024-07-02 - Missing ARIA/Tooltips on IconButtons
**Learning:** Found several `IconButton` components in admin tables (`ecg_cases_table.dart`, `questions_data_table.dart`) that have no `tooltip` property. While Flutter generates some default semantics, explicitly providing a `tooltip` on icon-only buttons is crucial for both visual mouse-hover hints and screen reader accessibility (it acts as the semantic label).
**Action:** Adding missing `tooltip` properties to icon-only `IconButton` widgets is a safe, preferred micro-UX improvement.
