# PLAN: Quiz UI/UX Upgrade

Upgrade the Quiz UI/UX to a premium, immersive standard that balances motivation (coins/progress) with deep focus.

## Phase 0: Design Parameters
- **Materiality**: Physical Cards (elevation, defined shadows, depth).
- **Transitions**: Smooth lateral **Slide** for question changes.
- **Focus**: Optimized header weighting (coins/progress remain visible but less intrusive).

## Phase 1: Header Refinement
- Fine-tune the `CozyProgressBar` and coin counter in `quiz_session_screen.dart` to be slightly smaller and use more muted border colors while keeping the "liquid" motivation high.

## Phase 2: Immersive Question Cards
- **Physical Depth**: Update `SingleChoiceRenderer` and `TrueFalseRenderer` to use card-based layouts with `elevation` and custom `BoxShadow` for a tactile feel.
- **Tappability**: Ensure all touch targets follow the 48px minimum rule.
- **Haptic Feedback**: Integrate `HapticFeedback.lightImpact()` on selection.

## Phase 3: Fluid Motion
- **PageView Integration**: Wrap question renderers in a `PageView` within `QuizSessionScreen` to enable the "Slide" transition.
- **Custom Animation**: Implement an `AnimatedSwitcher` or `PageRouteBuilder` if `PageView` isn't suitable for the state-based fetching mechanism.

## Phase 4: Feedback & Completion
- **Feedback Sheet**: Update `FeedbackBottomSheet` to match the physical card aesthetic (elevation vs glass).
- **Explanation Styling**: Use high-contrast typography for medical explanations.

## Verification Checklist
- [ ] Header remains motivating but reduces visual noise.
- [ ] Question transitions use a smooth "Slide" effect.
- [ ] All choice buttons feel like physical, tactile cards.
- [ ] Haptic feedback works on both Android and iOS.
- [ ] No layout shifts during transitions.
