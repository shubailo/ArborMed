## 2024-06-13 - [Add button semantics to GestureDetector widgets]
**Learning:** Custom interactive elements in Flutter built using `GestureDetector` do not inherently expose button semantics (like 'button' role or labels) to screen readers (e.g., VoiceOver or TalkBack), causing major accessibility issues for visually impaired users.
**Action:** Always wrap `GestureDetector` widgets that function as buttons in a `Semantics` widget with `button: true` and an appropriate `label`.
