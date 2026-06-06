## 2024-05-19 - Missing Tooltips on IconButtons
**Learning:** Found several places where IconButtons for "Edit" and "Delete" are missing the required `tooltip` attribute, violating the rule "always include a tooltip property on icon-only interactive widgets like IconButton". This hurts screen reader users and desktop users without mouse hover labels.
**Action:** When working on Flutter UI, ensure all `IconButton`s have a localized `tooltip` property to provide semantic labels for screen readers.
