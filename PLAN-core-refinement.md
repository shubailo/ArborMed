# Plan: Core Experience Refinement

**Goal**: Transform existing core functions (Quiz, Room, Navigation) from "Functional" to "Premium/State-of-the-Art" through high-polish sensory feedback and physics.

**Project Type**: MOBILE (Flutter)
**Primary Agent**: `mobile-developer`

## Success Criteria
- [ ] **Functional Haptics**: "Lub-Dub" pulses work on physical iOS/Android devices (vibration vs haptics check).
- [ ] **Asset Emergence**: Room furniture items animate into existence (smoke/pop effect) rather than instant appearance.
- [ ] **Dynamic Sloshing**: The progress bar's slosh amplitude is proportional to the value delta (big jump = big wave).
- [ ] **Elastic Room**: (COMPLETED) Room has elastic bounds and smooth snapback.

## Tech Stack
- **Framework**: Flutter (3.x)
- **State Management**: Provider
- **Physics**: Flutter `Physics` (SpringDescription), `AnimationController` with custom curves.
- **Haptics**: `vibration` or `haptic_feedback` (checking why current native calls fail).
- **Animations**: `Particle` systems or `CustomPainter` for smoke effects; `AnimatedList` or custom `Tween` for assets.

## File Structure (Affected Files)
- `mobile/lib/screens/game/room_screen.dart` (Asset loading logic)
- `mobile/lib/widgets/cozy/cozy_room_renderer.dart` (Asset rendering & animation)
- `mobile/lib/screens/game/quiz_session_screen.dart` (Haptic triggers)
- `mobile/lib/widgets/cozy/cozy_progress_bar.dart` (Fluid physics overhaul)
- `mobile/lib/services/audio_provider.dart` (Haptic sync bridge)

---

## Task Breakdown

### Phase 1: Haptic Foundation (Fix & Sync)
| ID | Task Name | Agent | Skills | Priority | Docs/Deps |
|----|-----------|-------|--------|----------|-----------|
| T1 | **The "Haptic Heartbeat" Fix** | mobile-developer | systematic-debugging | P0 | Physical device testing |
| | **INPUT**: Quiz correct/incorrect events. |
| | **OUTPUT**: Integrated `vibration` service that works on physical hardware where `HapticFeedback` may have failed. Implement 2-pulse pattern. |
| | **VERIFY**: User confirms haptics felt on device during quiz. |

### Phase 2: Dynamic Fluid Dynamics
| ID | Task Name | Agent | Skills | Priority | Docs/Deps |
|----|-----------|-------|--------|----------|-----------|
| T2 | **Impulse-Driven Slosh** | mobile-developer | performance-optimizer | P1 | `cozy_progress_bar.dart` |
| | **INPUT**: Progress percentage change (delta). |
| | **OUTPUT**: `LiquidPainter` that calculates wave amplitude based on `abs(newVal - oldVal)`. High momentum on jumps, subtle ripple on small steps. |
| | **VERIFY**: Visual review of progress bar "sloshing" harder when 5+ questions answered at once. |

### Phase 3: Aesthetic Asset Emergence
| ID | Task Name | Agent | Skills | Priority | Docs/Deps |
|----|-----------|-------|--------|----------|-----------|
| T3 | **The "Smoke & Pop" Effect** | mobile-developer | frontend-design | P1 | `cozy_room_renderer.dart` |
| | **INPUT**: Adding a new item to the room. |
| | **OUTPUT**: A `TweenAnimationBuilder` or `staggered` animation where items scale from 0.0 to 1.1 then settle to 1.0, accompanied by a brief puff of "watercolor smoke" (fading white/grey circles). |
| | **VERIFY**: Open the room; assets should appear with a "poof" animation. |

---

## Phase X: Verification
- [ ] **Lints**: `flutter analyze`
- [ ] **UX Audit**: `python .agent/skills/frontend-design/scripts/ux_audit.py .`
- [ ] **Haptic Verification**: User confirms physical feedback.
- [ ] **Visual Audit**: Fluidity check (60fps), no purple colors.
- [ ] **Final Check**: `python .agent/scripts/verify_all.py .`

## ✅ PHASE X COMPLETE
- Date: [NOT COMPLETE]
