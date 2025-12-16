# Audio Integration Testing Guide

**Date:** 2025-12-04
**Status:** Audio files installed (100% coverage), ready for Godot integration
**Next Step:** Add MoonAudioManager to moon_landing.tscn scene

---

## Current Status

### ✅ Completed
- [x] 8 audio files installed in correct directories
- [x] Audio system coded (scripts/audio/moon_audio_manager.gd - 485 lines)
- [x] Documentation complete (AUDIO_COMPLETE.md)
- [x] File structure verified

### ⏳ Pending
- [ ] Add MoonAudioManager node to moon_landing.tscn
- [ ] Set loop flags on continuous sounds (engine_thrust_loop.ogg, jetpack_thrust_loop.ogg)
- [ ] Test audio playback in Godot editor
- [ ] Test full gameplay with audio feedback

---

## Audio Files Installed

### Quality Sounds (Permanent)
```
audio/sfx/ui/success_chime.ogg (44 KB) ✅
audio/sfx/ui/warning_beep.ogg (12 KB) ✅
audio/sfx/ui/achievement_unlock.ogg (48 KB) ✅
```

### Placeholder Sounds (Replace Later)
```
audio/sfx/spacecraft/engine_thrust_loop.ogg (14 KB) ⚠️ PLACEHOLDER
audio/sfx/landing/landing_impact_medium.ogg (33 KB) ⚠️ PLACEHOLDER
audio/sfx/walking/footstep_moon_01.ogg (20 KB) ⚠️ PLACEHOLDER
audio/sfx/walking/footstep_moon_02.ogg (20 KB) ⚠️ PLACEHOLDER
audio/sfx/walking/footstep_moon_03.ogg (20 KB) ⚠️ PLACEHOLDER
audio/sfx/walking/jetpack_thrust_loop.ogg (22 KB) ⚠️ PLACEHOLDER
```

**Total:** 8/8 files (100% coverage)
**Quality:** 3/8 files (37% permanent quality)

---

## Integration Steps

### Step 1: Open Godot Editor

**If Godot is not running:**
```bash
cd C:/godot
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot" --editor
```

**Wait for Godot to fully start** (10-15 seconds)

### Step 2: Verify Audio File Import

1. Look at the **FileSystem** panel (bottom-left of editor)
2. Navigate to `res://audio/sfx/`
3. Check all folders:
   - `spacecraft/` - should have engine_thrust_loop.ogg
   - `landing/` - should have landing_impact_medium.ogg
   - `walking/` - should have 4 files (footsteps + jetpack)
   - `ui/` - should have 3 files (success, warning, achievement)

**If files don't appear:**
- Right-click FileSystem panel → **Reload**
- Or restart Godot editor

**Preview a sound:**
- Click on an audio file (e.g., success_chime.ogg)
- Look at the **Import** tab at top
- Click the **Play** button to preview

### Step 3: Set Loop Flags on Continuous Sounds

Looping sounds need to be configured to loop seamlessly:

**engine_thrust_loop.ogg:**
1. Select `res://audio/sfx/spacecraft/engine_thrust_loop.ogg`
2. Click **Import** tab (top center)
3. Check the **Loop** checkbox
4. Click **Reimport** button
5. Verify: Play preview - should loop seamlessly

**jetpack_thrust_loop.ogg:**
1. Select `res://audio/sfx/walking/jetpack_thrust_loop.ogg`
2. Click **Import** tab
3. Check **Loop** checkbox
4. Click **Reimport**
5. Verify: Play preview - should loop seamlessly

### Step 4: Add MoonAudioManager to Scene

1. Open `moon_landing.tscn` in the editor:
   - **Scene → Open Scene** → Navigate to `res://moon_landing.tscn`
   - Or double-click `moon_landing.tscn` in FileSystem panel

2. Add MoonAudioManager node:
   - Right-click on scene root (**MoonLanding** node)
   - Select **Add Child Node**
   - Search for: **Node**
   - Select **Node** and click **Create**
   - Rename the node to: **MoonAudioManager**

3. Attach the audio manager script:
   - Select the **MoonAudioManager** node
   - In **Inspector** panel (right side), find **Script** section
   - Click folder icon next to **Script**
   - Navigate to: `res://scripts/audio/moon_audio_manager.gd`
   - Click **Open**
   - The node should now have the script attached (moon_audio_manager.gd icon)

4. Save the scene:
   - **Scene → Save Scene** (or Ctrl+S)
   - Scene is now ready with audio manager

### Step 5: Test Audio in Editor

**Quick sound test:**
1. Open the **Debugger** panel at bottom
2. Switch to **Output** tab
3. Press **F6** (Run Scene) to test moon_landing.tscn
4. Look for MoonAudioManager initialization messages:
   ```
   [MoonAudioManager] Initialized (audio files not yet loaded)
   [MoonAudioManager] Audio players created
   ```

**If you see errors:**
- Missing files: Check FileSystem panel, ensure all 8 files imported
- Script errors: Check Output tab for GDScript errors
- No output: Verify script is attached to MoonAudioManager node

### Step 6: Test Gameplay with Audio

**Controls (VR or Desktop):**
- **W/S** - Forward/Backward thrust (should hear engine sound)
- **A/D** - Left/Right thrust
- **Q/E** - Rotate left/right
- **Shift** - Boost (increases engine pitch)
- **Space** - Landing gear / Exit spacecraft

**Audio to listen for:**
1. **Engine thrust** - Plays when holding W (forward thrust)
   - Should increase pitch with throttle
   - Currently placeholder (laser sound)
   - Loop should be seamless

2. **Landing impact** - Plays when spacecraft touches Moon surface
   - Volume scales with landing speed
   - Currently placeholder (donk sound)

3. **Warning beep** - Plays when descending too fast (speed > threshold)
   - Should beep periodically when altitude < 100m and speed high
   - Quality sound (permanent)

4. **Achievement chime** - Plays when objectives completed
   - Quality sound (permanent)

**Desktop fallback mode:**
- If VR not detected, scene runs in desktop mode
- Use mouse to look around
- WASD for movement
- Audio should work identically

---

## Troubleshooting

### Audio Files Not Appearing in FileSystem

**Symptom:** audio/sfx/ folders are empty in FileSystem panel

**Solutions:**
1. Right-click FileSystem → **Reload**
2. Check actual file system:
   ```bash
   ls -la C:/godot/audio/sfx/spacecraft/
   ls -la C:/godot/audio/sfx/landing/
   ls -la C:/godot/audio/sfx/walking/
   ls -la C:/godot/audio/sfx/ui/
   ```
3. If files are missing, re-run conversion commands from AUDIO_COMPLETE.md
4. Restart Godot editor

### Audio Not Playing in Game

**Symptom:** Game runs but no audio

**Debugging steps:**
1. Check Output panel for errors:
   - Look for "Missing audio files" warnings
   - Check for GDScript errors in moon_audio_manager.gd

2. Verify MoonAudioManager initialization:
   - Should see "[MoonAudioManager] Initialized" in Output
   - Should see "[MoonAudioManager] Audio players created"

3. Check audio bus configuration:
   - **Audio → Show Audio Buses** (top menu)
   - Verify **SFX** bus exists
   - Check volume sliders are not muted (not at -INF dB)

4. Test individual sounds:
   - Open `moon_audio_manager.gd` script
   - Add debug prints in audio playback functions (e.g., `play_warning_beep()`)
   - Run scene and trigger sounds manually

### Loop Points Not Seamless

**Symptom:** Engine/jetpack sounds have audible "click" when looping

**Solutions:**
1. Verify loop flag is enabled:
   - Select audio file → Import tab → Loop checkbox
   - Click Reimport

2. Audio file may need trimming:
   - Some WAV files have silence at start/end
   - Edit in Audacity: Effect → Truncate Silence
   - Export as OGG again

3. Placeholder sounds are known to be short:
   - engine_thrust_loop.ogg: 0.79s (very short)
   - jetpack_thrust_loop.ogg: 1.47s (short)
   - Replace with longer loop sounds for better quality

### MoonAudioManager Script Not Found

**Symptom:** Script attachment fails with "Cannot open script" error

**Solutions:**
1. Verify script exists:
   ```bash
   ls -la C:/godot/scripts/audio/moon_audio_manager.gd
   ```
2. If missing, script should be at that location (485 lines)
3. Check script syntax:
   - Open script in Godot script editor
   - Look for any GDScript syntax errors
   - Fix and save

### Audio Plays But Volume Too Low/High

**Solutions:**
1. Adjust volume in audio manager script:
   - Open `scripts/audio/moon_audio_manager.gd`
   - Find `@export_group` sections with volume settings
   - Adjust `*_volume_db` values:
     - Increase: `-12.0` → `-6.0` (louder)
     - Decrease: `-12.0` → `-18.0` (quieter)
   - Save and test

2. Adjust master volume:
   - **Audio → Show Audio Buses**
   - Drag **Master** or **SFX** bus volume slider
   - Test in real-time while game is running

---

## Expected Behavior After Integration

### Engine Thrust Audio
- **Trigger:** Hold W (forward thrust)
- **Behavior:**
  - Starts playing immediately when thrust applied
  - Pitch increases with throttle (0.6 to 1.2x)
  - Volume increases with throttle (-8 dB to 0 dB)
  - Stops when thrust released
  - Loops seamlessly while active
- **Current:** Laser sound placeholder (replace later)

### Landing Impact Audio
- **Trigger:** Spacecraft touches Moon surface
- **Behavior:**
  - Plays once on contact
  - Volume scales with impact velocity
  - Minimum velocity threshold: 0.5 m/s
  - Followed by "dust settling" sound (if available)
- **Current:** Donk sound placeholder (replace later)

### Footstep Audio
- **Trigger:** Walking on Moon surface after exiting spacecraft
- **Behavior:**
  - Plays every 0.5 seconds while moving
  - Pitch varies slightly for realism (±0.2)
  - Interval scales with walking speed
  - Stops when standing still
- **Current:** Brush sound placeholder, all 3 variations identical (replace later)

### Jetpack Audio
- **Trigger:** Press Shift while in walking mode
- **Behavior:**
  - Ignition sound plays on activation
  - Thrust loop plays while jetpack active
  - Pitch scales with fuel level (0.8 to 1.2x)
  - Shutdown sound plays on deactivation
  - Loops seamlessly while active
- **Current:** Laser sound placeholder (replace later)

### Warning Beep Audio
- **Trigger:** Descending too fast (speed > 1.5x threshold, altitude < 100m)
- **Behavior:**
  - Beeps periodically while condition active
  - Does not loop, plays discrete beep sounds
  - Stops when speed reduces or altitude increases
- **Current:** Quality sound (permanent) ✅

### Achievement/Success Audio
- **Trigger:** Completing objectives or successful landing
- **Behavior:**
  - Plays once when achievement unlocked
  - Success chime for successful landing
  - Achievement sound for unlocking objectives
  - No looping
- **Current:** Quality sounds (permanent) ✅

---

## Performance Notes

**Audio System Impact:**
- **Memory:** ~1 MB total (all 8 files loaded)
- **CPU:** Negligible (hardware-accelerated audio)
- **VR Performance:** No impact on 90 FPS target
- **Disk Space:** 232 KB total

**Audio Player Count:**
- 11 AudioStreamPlayer3D nodes (positional 3D audio)
- 5 AudioStreamPlayer nodes (UI 2D audio)
- Total: 16 audio players

**3D Audio Settings:**
- Max distance: 100 meters
- Attenuation: Inverse square law (realistic)
- Unit size: 5 meters
- All spacecraft/walking sounds use positional audio

---

## Next Steps After Testing

### If Audio Works Correctly
1. Mark integration complete ✅
2. Continue gameplay testing
3. Gather feedback on placeholder sound quality
4. Decide if replacements are needed immediately

### If Placeholder Sounds Not Acceptable
Execute **Phase 2: Quality Replacements (30 minutes)**
1. Download 4 critical high-quality files:
   - Engine thrust: https://freesound.org/people/LimitSnap_Creations/sounds/318688/
   - Landing impact: https://www.zapsplat.com/music/body-impact-hit-ground-with-a-heavy-thud-version-1/
   - Footsteps (x3): https://freesound.org/people/taure/packs/32354/
   - Jetpack: https://www.zapsplat.com/music/science-fiction-jetpack-burst-thrust/
2. Convert to OGG (ffmpeg commands in AUDIO_COMPLETE.md)
3. Replace files in audio/sfx/ directories
4. Reimport in Godot
5. Re-test

### For Complete Professional Library
Execute **Phase 3: Sonniss Library (2-3 hours)**
1. Download: https://sonniss.com/gameaudiogdc/
2. Extract all 9 parts (27.5 GB)
3. Search for specific sounds
4. Batch convert to OGG
5. Replace all placeholders + add optional sounds
6. Result: 95%+ coverage, AAA quality

---

## Testing Checklist

Before marking integration complete, verify:

- [ ] All 8 audio files appear in Godot FileSystem panel
- [ ] Loop flags set on engine_thrust_loop.ogg and jetpack_thrust_loop.ogg
- [ ] MoonAudioManager node added to moon_landing.tscn
- [ ] Script attached correctly (moon_audio_manager.gd)
- [ ] Scene runs without errors (F6)
- [ ] Engine thrust plays when pressing W
- [ ] Engine pitch increases with throttle
- [ ] Landing impact plays on touchdown
- [ ] Warning beep plays when descending too fast
- [ ] Footsteps play when walking
- [ ] Jetpack sound plays when using jetpack
- [ ] Success chime plays on successful landing
- [ ] No audio glitches or crashes
- [ ] Performance remains smooth (90 FPS in VR)

**If all items checked:** Audio integration is complete! 🎉

---

## Quick Reference Commands

**Verify files exist:**
```bash
ls -la C:/godot/audio/sfx/spacecraft/ C:/godot/audio/sfx/landing/ C:/godot/audio/sfx/walking/ C:/godot/audio/sfx/ui/
```

**Start Godot:**
```bash
cd C:/godot
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot" --editor
```

**Test scene:**
- Press **F6** in Godot editor

**Re-convert a placeholder (if needed):**
```bash
cd C:/godot/audio/Game-Sound-Effects/Sounds
ffmpeg -i laser_shot2.wav -c:a libvorbis -q:a 5 C:/godot/audio/sfx/spacecraft/engine_thrust_loop.ogg
```

---

**Generated:** 2025-12-04
**Status:** Ready for integration testing
**Estimated Testing Time:** 15-20 minutes
**Dependencies:** Godot 4.5.1, moon_landing.tscn, moon_audio_manager.gd

**Files Referenced:**
- AUDIO_COMPLETE.md - Full installation status
- moon_audio_manager.gd - Audio system implementation
- moon_landing.tscn - Main scene file
- AUDIO_DOWNLOAD_GUIDE.md - Replacement sound links
