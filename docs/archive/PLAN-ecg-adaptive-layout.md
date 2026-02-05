# PLAN: Adaptive ECG Layout

Improve the desktop/tablet experience by constraining the ECG challenge to a readable central column.

## User Review Required

> [!NOTE]
> **Max Width**: I propose a max-width of **1000px** for the ECG content. This ensures the grid remains clear and the form fields don't span the entire monitor.

## Proposed Changes

### [Component] ECG UI
#### [MODIFY] [ecg_practice_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/ecg_practice_screen.dart)
- **Image Section**:
  - Wrap the image `Stack` in a `Center` and `ConstrainedBox` with `maxWidth: 1000`.
  - Add a subtle background color/pattern to the area behind the constrained image box.
- **Form Section**:
  - Wrap the `ListView` contents (or the `Container` holding it) in a `Center` and `ConstrainedBox` (maxWidth: 1000).
- **Background**:
  - Ensure the scaffold background color fills the screen while the content remains centered.

## Verification Plan

### Manual Verification
- **Tablet/Desktop View**: Resize the window and verify that the ECG image and form stop expanding after 1000px and remain centered.
- **Mobile View**: Verify that it still takes 100% width on phones.
