## 2026-06-25 - Accessible Smart Review Cards
**Learning:** Found an interactive card built with `GestureDetector` that acts as a button but lacks accessibility semantics for screen readers. This makes it difficult for visually impaired users to understand that the card is interactive.
**Action:** Wrapped the `GestureDetector` with `Semantics(button: true, label: "Review ${item.topic}")` to provide proper context to screen readers, aligning with a11y best practices for custom interactive elements in Flutter.
