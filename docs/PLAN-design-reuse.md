# PLAN: Design Reuse (Legacy → 2.0)

This plan outlines the extraction, refactor, and placement of high-value UI components from the archived ArborMed app into the current ArborMed 2.0 student app.

## 🔴 CRITICAL RULES
1. **NO BUSINESS LOGIC:** All reused widgets must be stripped of legacy state management (Providers, Services).
2. **PURE UI:** Widgets should be `StatelessWidget` when possible, using constructor parameters and callbacks.
3. **COZY THEME:** All hardcoded colors/styles must be replaced with `AppTheme` or `CozyTheme` tokens.
4. **NO RUNTIME CHANGES:** This plan is for analysis and mapping; no existing behavior in 2.0 should be broken.

## 1. ANALYSIS RESULTS

### 1.1 Core UI Candidates (Pure or Low Coupling)
- `CozyButton`: Multi-variant action button with squish feedback.
- `CozyPanel`: Versatile card/tile container with optional title "labels".
- `CozyProgressBar`: Medical-styled progress indicator.
- `FloatingMedicalIcons`: Animated background decorator.
- `ECGMonitorPainter`: Custom painter for the heartbeat wave.

### 1.2 Feature-Specific Candidates (High Refactor needed)
- `BeanWidget`: The character avatar. Needs to be decoupled from legacy `ShopProvider`.
- `CozyDialogSheet`: The modal system. Needs to be integrated with 2.0 navigation/portals.
- `CozyRoomRenderer`: Isometric room grid handler.

## 2. PROPOSED MAPPING

### 2.1 Core UI (lib/core/ui/)
| Legacy Component | Target File | Type | Refactor Notes |
|------------------|-------------|------|----------------|
| `CozyButton` | `cozy_button.dart` | Generic | Remove `AudioProvider` & `HapticService` direct calls. Use callbacks. |
| `CozyPanel` | `cozy_panel.dart` | Generic | Decouple from legacy `CozyTheme.of`. Use 2.0 `Theme.of(context)`. |
| `CozyProgressBar` | `cozy_progress_bar.dart` | Generic | Simplify animation logic. |
| `FloatingMedicalIcons` | `floating_medical_icons.dart`| Generic | Optimize asset loading; use 2.0 asset paths. |

### 2.2 Feature: Room (lib/features/room/)
| Legacy Component | Target File | Type | Refactor Notes |
|------------------|-------------|------|----------------|
| `ECGMonitorPainter` | `widgets/ecg_monitor_widget.dart` | Featured | Wrap in a widget that handles the `AnimationController` internally. |
| `BeanWidget` | `widgets/bean_avatar_widget.dart` | Featured | Conver to `StatelessWidget`. Pass `BeanConfig` as a simple DTO. |
| `CozyRoomRenderer` | `widgets/room_isometric_grid.dart`| Featured | Simplify to handle just the visual layout of items. |

### 2.3 Feature: Study (lib/features/study/)
| Legacy Component | Target File | Type | Refactor Notes |
|------------------|-------------|------|----------------|
| `QuestionRenderer` | `widgets/legacy_question_card.dart` | Featured | Extract the "paper" visual style without the quiz logic. |

## 3. THEME INTEGRATION

### 3.1 New Tokens in `lib/core/theme/`
- **Shadows**: Add `CozyShadows.small` and `CozyShadows.medium` to `AppTheme`.
- **Gradients**: Add `CozyGradients.sage`, `CozyGradients.clay`, and `CozyGradients.magic`.
- **Colors**: Ensure `paperWhite` (#FFFFFF) and `paperCream` (#FFFDF5) are present.

## 4. VERIFICATION PLAN

### Manual Verification
- [ ] Create a "UI Gallery" page in the app (internal only) to verify all ported widgets.
- [ ] Visual Diff: Compare legacy app screenshots with 2.0 implementations.
- [ ] Interaction Check: Ensure "squish" buttons and "breathing" Bean work as expected.

### Automated Tests
- [ ] Widget Tests: `flutter test` for `CozyButton` and `CozyPanel` to ensure they respond to theme changes.
- [ ] Golden Tests: Generate screenshots of custom painters (`ECGMonitor`) for pixel-perfect verification.
