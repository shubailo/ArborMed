## 2024-06-27 - Custom GestureDetectors missing Button Semantics
**Learning:** Icon-only interactive elements built directly with `GestureDetector` (like `CozyHubButton`) do not inherently expose button semantics to screen readers, even if they have a `Tooltip`. This causes screen readers to read the text without announcing it as an actionable button, leading to accessibility barriers.
**Action:** Always wrap custom `GestureDetector` elements in a `Semantics(button: true, label: ...)` widget to ensure screen readers correctly identify them as interactable buttons.
