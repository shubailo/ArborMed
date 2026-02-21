# Plan: Fix Music Provider Issues

The user reported that the music provider in the mobile app is not continuous, stops after SFX sounds, and doesn't start automatically with the app.

## Proposed Changes

### `AudioProvider.dart`

#### [MODIFY] [audio_provider.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/services/audio_provider.dart)
- **Robust Looping**:
    - Update `_setupStateWatcher` to explicitly restart playback if `PlayerState.completed` is reached.
    - Consistency: Ensure `ReleaseMode.loop` is set on every `play()` call.
- **Improved Audio Context (Mixing)**:
    - Change iOS category to `AVAudioSessionCategory.ambient`.
    - Explicitly set `AudioContext` on both `_musicPlayer` and `_sfxPlayer`.
- **Startup Fix**:
    - Trigger `ensureMusicPlaying` earlier during initialization if authenticated.
- **SFX Management**:
    - Refine `playSfx` to prevent interruptions.

## Verification Plan

### Manual Verification
1. **Startup Test**: Open app while logged in -> Music starts.
2. **SFX Mixing Test**: Play music + click buttons -> SFX plays, music continues.
3. **Continuity Test**: Let track end -> Loops.
4. **Auth Toggle Test**: Log out/in -> Music stops/starts.
