# PLAN-quiz-ui-fix.md - Quiz UI & Animation Restoration

The goal is to resolve a critical logic bug where correct True/False answers are marked incorrect due to backend shuffling, and to restore/enhance the "beautifully animated" feel of the quiz buttons using consistent premium patterns.

## 🔍 Context & Debugging
- **Color Glitch**: Backend shuffles `true_false` options. Frontend expects Fixed Order (0=True, 1=False) for comparison fallbacks. When shuffled, "Hamis" at index 0 fails both label and index-based checks.
- **Animation Regression**: `Transform.scale` was implemented without an animation driver (like `AnimatedScale`), causing instant transitions which feel "disappeared" or broken compared to previous versions.

## 🛠️ Proposed Changes

### 1. Backend: Stabilization
- **[MODIFY] [TrueFalseType.js](file:///c:/Users/shuba/Desktop/Med_buddy/backend/src/services/questionTypes/TrueFalseType.js)**
  - Set `shouldShuffleOptions` to `false`. True/False should ALWAYS be [Igaz, Hamis].

### 2. Mobile: Logic Resilience
- **[MODIFY] [true_false_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/true_false_renderer.dart)**
  - Improve `isOptionCorrect` comparison to better handle localized strings and values.
  - Ensure labels map correctly to `'true'`/`'false'` regardless of index.

### 3. Mobile: Premium Animation (Beautiful Buttons 2.0)
- **[MODIFY] [single_choice_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/single_choice_renderer.dart)**
- **[MODIFY] [multiple_choice_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/multiple_choice_renderer.dart)**
- **[MODIFY] [true_false_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/true_false_renderer.dart)**
- **[MODIFY] [relation_analysis_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/relation_analysis_renderer.dart)**
- **[MODIFY] [matching_renderer.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/questions/matching_renderer.dart)**

**Implementation Pattern:**
Replace `Transform.scale` with `AnimatedScale`:
```dart
AnimatedScale(
  scale: isSelected ? 1.05 : 1.0,
  duration: const Duration(milliseconds: 400),
  curve: Curves.elasticOut,
  child: AnimatedContainer(...)
)
```
- Update `AnimatedContainer` curve to `Curves.easeOutCubic` for smoother color transitions.
- Synchronize durations for a cohesive "pop" effect.

## ✅ Verification Plan

### Automated
- Run `flutter analyze` to ensure no syntax errors.

### Manual
1. **Verification of Correctness**:
   - Start a Cardiovascular quiz (Hungarian).
   - Find a True/False question.
   - Click "Hamis" (if correct). Verify it turns **Green immediately**.
2. **Animation Feel**:
   - Tap options in Single Choice and True/False.
   - Verify that the scale transform is **smooth and bouncy**, not instant.
   - Verify that the selection feels "premium" as per `ui-ux-pro-max` Master.
