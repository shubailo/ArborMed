```markdown
1. *Optimize O(N) double iteration in `_buildDetailActions` in `apps/student_app/lib/features/shop/widgets/contextual_shop_sheet.dart`.*
   - Use `replace_with_git_merge_diff` to replace `.any()` and `.firstWhere()` double scan with a manual `for` loop that safely returns the item in a single $O(N)$ scan without introducing new dependencies or causing null-safety crashes when the item isn't found. This prevents redundant traversing on UI re-renders for every selected item view. Add a comment explaining the `⚡ Bolt` optimization.
2. *Document the specific critical learning in Bolt's journal (`.jules/bolt.md`).*
   - Append a new journal entry acknowledging that using `.any()` followed immediately by `.firstWhere()` with the same condition causes an unnecessary double scan ($O(N+N)$) which can be eliminated with a single `for` loop that captures the item and its existence simultaneously, particularly in UI rendering functions where iteration impacts layout calculation.
3. *Run testing and linting to verify that the change functions perfectly.*
   - Navigate to `apps/student_app` and run `dart format lib/features/shop/widgets/contextual_shop_sheet.dart`.
   - Run `flutter analyze lib/features/shop/widgets/contextual_shop_sheet.dart` to ensure clean code without missing returns or null-safety warnings.
4. *Complete pre commit steps to ensure proper testing, verification, review, and reflection are done.*
5. *Submit the Pull Request using `⚡ Bolt: [performance improvement]` title format.*
```
