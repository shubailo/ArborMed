## 2024-04-07 - Accessibility of Admin Action Buttons
**Learning:** Icon-only buttons used for administrative actions (like editing, deleting, closing, and pagination) often lack tooltips, which are critical for accessibility. Without tooltips, screen readers cannot properly announce the purpose of these buttons.
**Action:** Always add `tooltip:` properties to `IconButton`s, especially in administrative or dashboard views where space constraints often lead to the use of icon-only buttons.
