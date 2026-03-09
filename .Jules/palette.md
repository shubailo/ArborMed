## 2024-05-24 - [Password Visibility Toggle]
**Learning:** Users often struggle with password entry on mobile devices when `obscureText` is strictly enforced without a way to verify their input. Adding a visibility toggle is a standard, expected UX pattern that prevents frustration during login and registration.
**Action:** Always include a suffix icon with `Icons.visibility` / `Icons.visibility_off` and a semantic tooltip ("Show password" / "Hide password") on password fields to enhance usability and accessibility.

## 2024-06-03 - [Keyboard Form Submission]
**Learning:** Adding `TextInputAction` to form fields and handling `onFieldSubmitted` greatly improves keyboard navigation and usability, allowing users to submit forms directly from the keyboard without breaking their flow. It is particularly important on mobile devices where the keyboard covers half the screen.
**Action:** Always specify `textInputAction: TextInputAction.next` for intermediate fields and `textInputAction: TextInputAction.done` with `onFieldSubmitted` on the final field of a form.

## 2025-03-04 - [Missing Tooltips on Icon Buttons]
**Learning:** Icon-only buttons (like `IconButton`) across the app often lacked `tooltip` properties. This causes severe accessibility issues as screen readers announce them poorly, and desktop/web users lack hover context for what the button does.
**Action:** Always include a clear, descriptive `tooltip` property on any `IconButton` or icon-only interactive element to ensure it is accessible and understandable.
## 2025-03-08 - Missing Tooltips on Interactive Avatars and Full-Screen Images
**Learning:** In the student app, many interactive visual components (like the buddy avatar in the room screen, or the full-screen interactive ECG viewer) use raw `GestureDetector` widgets without any semantic labels or tooltips. This is a common accessibility issue for components that are purely visual without text or standard iconography.
**Action:** When implementing or reviewing purely visual interactive components (e.g. `GestureDetector` wrapped around `InteractiveViewer` or custom widgets like `BeanWidget`), always wrap them in a `Tooltip` widget. This provides critical semantic labeling for screen readers and helpful hover text for pointer-based interactions.
