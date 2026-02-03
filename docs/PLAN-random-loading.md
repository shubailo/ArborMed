# PLAN: Randomized Clinical Loading Screens

This plan outlines the implementation of a modular, randomized loading system to replace the Hemmy mascot. The system will alternate between two professional medical animations: **The Vital Monitor** and **The Filling Syringe**.

## Project Type: MOBILE (Flutter)

## Success Criteria
- [ ] Randomization: 50/50 split between ECG and Syringe screens.
- [ ] Animations: Smooth 60fps ECG tracing and Syringe filling.
- [ ] Transition: "Shut off" (ECG) and "Inject" (Syringe) animations when quiz loads.
- [ ] Clinical Immersion: Status text cycler and accurate technical readouts.

## Tech Stack
- **Flutter / Dart**: Core framework.
- **CustomPainter**: For performant, low-overhead medical animations.
- **AnimationController**: For smooth transitions and liquid physics.

## File Structure
```text
lib/
├── screens/
│   └── game/
│       ├── quiz_loading_screen.dart       (Main Orchestrator)
│       ├── widgets/
│       │   ├── ecg_monitor_painter.dart    (New)
│       │   └── syringe_painter.dart        (New)
```

## Task Breakdown

### Phase 1: Foundation (The Clinical Dispatcher)
- **Task 1.1**: Define `LoadingVariant` enum and randomization logic in `QuizLoadingScreen`.
  - **Input**: `quiz_loading_screen.dart`
  - **Output**: Logic to pick a variant and a `Switch` in `build`.
  - **Verify**: Print selected variant to console.

### Phase 2: Variant Implementation - The Vital Monitor
- **Task 2.1**: Build `ECGMonitorPainter`.
  - **Input**: New file in `widgets/`.
  - **Output**: A scrolling sine-wave style heart rate line.
  - **Verify**: Visual check of tracing speed and smoothness.
- **Task 2.2**: Implement "Shut Off" transition.
  - **Input**: `AnimationController`.
  - **Output**: Line flattens and brightness dims on completion.
  - **Verify**: Screen "winks" out before quiz starts.

### Phase 3: Variant Implementation - The Filling Syringe
- **Task 3.1**: Build `SyringePainter`.
  - **Input**: New file in `widgets/`.
  - **Output**: Syringe outline with a rising liquid fill level.
  - **Verify**: Liquid level matches loading percentage.
- **Task 3.2**: Implement "Inject" transition.
  - **Input**: `AnimationController`.
  - **Output**: Plunger pushes down rapidly on completion.
  - **Verify**: Liquid disappears quickly as quiz starts.

### Phase 4: Polish & Integration
- **Task 4.1**: Create Clinical Status Cycler.
  - **Input**: List of strings, `Timer`.
  - **Output**: Rotating text (e.g., "Sterilizing equipment...").
  - **Verify**: Text changes every 1.5s regardless of variant.

## Phase X: Verification
- [ ] Restart quiz 10 times → Verify 50/50 variety.
- [ ] verify performance on low-end device (no frame drops).
- [ ] verify all "Hemmy" references are removed.
