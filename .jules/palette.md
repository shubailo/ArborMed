## 2024-06-18 - Missing Semantics in GestureDetector Widgets
**Learning:** In Flutter, custom interactive elements built using `GestureDetector` do not inherently expose button semantics to screen readers, unlike standard `ElevatedButton` or `IconButton` widgets.
**Action:** Always wrap `GestureDetector` widgets that act as buttons with `Semantics(button: true, ...)` to ensure they meet accessibility standards.
