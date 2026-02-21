# PLAN: Global Audio Updates & Admin Settings

## Goal
Ensure a consistent and polished audio experience across the entire application by adding missing sound effects (SFX) to interactive elements, removing redundant sound triggers, and providing audio controls in the Admin area.

## 1. Analysis & Gaps Identified

### SFX Gaps (Missing Click Sound)
- **Quiz Portals**:
  - `PressableAnswerButton`: Quiz option buttons are currently silent.
  - `MatchingRenderer`: Selection of items in matching questions is silent.
  - `RelationAnalysisRenderer`: Toggles for statement truth values are silent.
  - `QuizMenu`: Subject cards, grid options (Subjects, ECG, Cases), and back buttons.
- **Profile View**:
  - `ProfilePortal`: Nickname edit icon, bottom navigation tabs (Profile/Activity), and "Change Password" tile.
  - `ActivityView`: Date navigation arrows (left/right), timeframe selectors (Day/Week/Month), and the "Start" button for mistake review.
  - `CozyDialogSheet`: Tapping outside to close the dialog is currently silent in many views.
- **Settings View**:
  - `Switch` toggles: Currently only some play sounds.
  - `Slider` interactions: Often silent.
  - `ExpansionTile`: The "Select Track" header is silent.
- **Renderer**:
  - Image Zoom: Tapping on a question image to zoom is silent.

### Redundancy (Double Sound)
- `CozyButton` and `LiquidButton`: These widgets explicitly call `playSfx('click')` but also use `PressableMixin` which ALREADY calls it. This creates a double-tap sound.

### Admin Zone
- `AdminSettingsDialog`: Currently lacks audio controls (Music/SFX toggles).
- `AdminShell`: Pauses music on entry and resumes on exit, which is correct, but needs to honor the global audio state.

---

### Global Strategy: Centralization over Manual Addition
Instead of adding SFX manually to every `GestureDetector`, we will:
1.  **Leverage `PressableMixin`**: Ensure all custom interactive widgets use `handleTapUp` from the Mixin, which is the "Global Source of Truth" for the click sound.
2.  **Clean up Redundancy**: Remove explicit `playSfx` calls from widgets that already use `PressableMixin` (like `CozyButton` and `LiquidButton`).
3.  **Refactor Silent Widgets**: Convert simple `GestureDetector` buttons in Profile, Quiz, and Admin into standard `CozyButton` variants or wrap them with `PressableMixin` to inherit the sound and physical feedback.

## 2. Proposed Changes

### [Component] Base & Mixin Cleanup
- **[MODIFY] [pressable_mixin.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/cozy/pressable_mixin.dart)**: Verify `handleTapUp` is the primary sound trigger.
- **[MODIFY] [cozy_button.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/cozy/cozy_button.dart)**: Remove redundant explicit `playSfx` calls.
- **[MODIFY] [liquid_button.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/cozy/liquid_button.dart)**: Remove redundant explicit `playSfx` calls.

### [Component] Refactoring for Centralized SFX
- **[MODIFY] [pressable_answer_button.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/cozy/pressable_answer_button.dart)**: Refactor to use `PressableMixin` so it gains the click sound automatically (it currently manages its own `_isPressed` state).
- **[MODIFY] [quiz_menu.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/quiz/quiz_menu.dart)**: Replace manual `GestureDetector` logic with `PressableMixin` or `CozyButton` for grid options and subject cards.
- **[MODIFY] [profile_portal.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/profile/profile_portal.dart)**: Update bottom navigation to use `LiquidButton` or wrap with `PressableMixin`.
- **[MODIFY] [activity_view.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/profile/activity_view.dart)**: Wrap date arrows and timeframe buttons in `PressableMixin`.

### [Component] Admin Audio Settings
- **[MODIFY] [admin_settings_dialog.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/components/admin_settings_dialog.dart)**: 
  - Add **Music Volume Slider** & **SFX Toggle** (mirroring the main Settings logic).
  - Refactor its internal "Options" to use a centralized interactive widget that plays sound.

---

## 3. Verification Plan

### Manual Checklist
- [ ] **Quiz**: Each option tap in MCQs plays a sound.
- [ ] **Matching**: Each item tap plays a sound.
- [ ] **Profile**: Switching between Profile and Activity tabs plays a sound.
- [ ] **Profile**: Changing date in Activity view plays a sound.
- [ ] **Settings**: All toggles (Theme, Language, etc.) play a sound.
- [ ] **Admin**: Entering Admin zone pauses music, and Admin Settings now show audio toggles.
- [ ] **General**: `CozyButton` and `LiquidButton` play exactly ONE sound.

## 4. Risks & Dependencies
- **AudioContext**: Ensure `playSfx` doesn't interrupt background music (handled by `AudioProvider` via `mixWithOthers`).
- **Performance**: High frequency taps (e.g., in Matching) should be snappy. `audioplayers` usually handles this fine on mobile.
