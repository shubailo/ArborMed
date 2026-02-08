# PLAN: Music Autostart & Fade-in

Ensure background music starts automatically with a professional fade-in effect when a medical student enters their room, providing a "cozy" atmosphere immediately.

## Project Type: MOBILE (Flutter)

## Success Criteria
- ✅ Music starts automatically upon entering `RoomWidget` (after cinematic entry).
- ✅ Music transitions from 0.0 to target volume over 2-3 seconds (Subtle Fade-in).
- ✅ Continuous playback across all game screens (Shop, Quiz, Profile).
- ✅ No "lazy initialization" delay (Audio service ready on app boot).

## Tech Stack
- **Framework**: Flutter (Provider/ChangeNotifier)
- **Audio**: `audioplayers` package
- **Haptics**: `vibration` + `HapticFeedback` (existing)

## Proposed Changes

### [Foundation]
#### [MODIFY] [main.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/main.dart)
- Set `lazy: false` for `AudioProvider` so it initializes and prepares the player immediately.

### [Services]
#### [MODIFY] [audio_provider.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/services/audio_provider.dart)
- Add `fadeIn(Duration duration)` method.
- Update `_initMusic` to prepare but not necessarily "Auto-play" at 1.0 volume immediately in constructor.
- Add protection against multiple play calls.

### [UI / HUD]
#### [MODIFY] [room_screen.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/game/room_screen.dart)
- In `_startCinematicEntry` or `initState`, trigger `audioProvider.fadeIn()`.

#### [MODIFY] [cozy_hub_button.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/widgets/hub/cozy_hub_button.dart)
- Add safety `ensureMusicPlaying()` call to button taps to recover audio context if the browser/OS blocked the initial autostart.

## Task Breakdown

### Phase 1: Foundation (P0)
- **Task**: Make `AudioProvider` non-lazy.
- **Agent**: `mobile-developer`
- **Verify**: Debug logs show `AudioProvider` initialized before login completes.

### Phase 2: Logic (P1)
- **Task**: Implement `fadeIn()` logic with Timer/Tween.
- **Agent**: `mobile-developer`
- **Verify**: Manual check of volume ramp-up.

### Phase 3: Integration (P1)
- **Task**: Connect Room entry to Audio start.
- **Agent**: `mobile-developer`
- **Verify**: Music starts when Room appears.

## Phase X: Verification Checklist
- [ ] Music starts at volume 0.0 and ramps up to 0.5 (or saved volume).
- [ ] Opening settings and changing volume works during/after fade.
- [ ] Entering Quiz from Room keeps the music playing.
- [ ] SFX "click" doesn't interrupt or glitch the music.
