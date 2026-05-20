## 2024-05-20 - Icon-only buttons lacking tooltips in Data Tables
**Learning:** Icon-only buttons (like `IconButton` with `Icon` child) in Flutter need `tooltip` properties to be accessible to screen readers, especially in data-heavy components like `DataTable` rows where actions repeat.
**Action:** Always provide semantic labels via `tooltip` or `Semantics` wrapper for icon-only buttons. Use built-in `MaterialLocalizations` where applicable to avoid manual translations for common actions (e.g. `deleteButtonTooltip`).
