# PLAN: ECG Rendering & Validation Fix

Resolve the issue where ECG analysis cells are pre-filled with "Normal" values and lack error feedback for mandatory fields.

## User Review Required

> [!IMPORTANT]
> **Blank Slate Initialization**: All dropdowns will be initialized to an empty value. Per your request, we will use a truly empty selection rather than a placeholder string where possible.

## Proposed Changes

### [Component] ECG Analysis Engine
#### [MODIFY] [ecg_practice_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/ecg_practice_screen.dart)
- **State Initialization**: Change all default finding strings (Rhythm, P-Wave, Axis, etc.) to an empty string `''`.
- **Validation State**: Introduce `bool _triedSubmit = false;` to track the user's attempt to proceed.
- **Dynamic Styling**: 
  - Update `_buildDropdown` to accept a `hasError` flag.
  - If `_triedSubmit` is true and the value is empty, wrap the dropdown in a red border (using `CozyTheme.error`).
- **Submit Logic**:
  - Update `_submit()` to check if any required string fields are empty.
  - Block submission and trigger the error state if fields are missing.
- **Reset Logic**: Update `_loadNextCase()` to ensure all values are cleared for the next challenge.

## Verification Plan

### Automated Tests
- `flutter analyze` to ensure code integrity.

### Manual Verification
- **Test 1**: Open the ECG Challenge. Verify all fields are empty.
- **Test 2**: Tap "SUBMIT ANALYSIS" immediately. Verify all empty fields highlight with a red border.
- **Test 3**: Select a value for "Rhythm". Verify that specific field's red border persists but allows valid data (or disappears if we re-evaluate live).
- **Test 4**: Finish a case and load the next. Verify the "Blank Slate" is restored.
