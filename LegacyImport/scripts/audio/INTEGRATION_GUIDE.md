# Moon Landing Audio System - Integration Guide

## Quick Start

The audio system for moon landing has been fully implemented. To activate it:

### 1. Add Audio Files
Place audio files in the directory structure (see `/audio/AUDIO_FILES_NEEDED.txt` for complete list):
```
audio/sfx/spacecraft/
audio/sfx/landing/
audio/sfx/walking/
audio/sfx/ui/
```

### 2. Update moon_landing.tscn

Add the MoonAudioManager node to the scene. Edit `moon_landing.tscn`:

**Add external resource:**
```gdscript
[ext_resource type="Script" path="res://scripts/audio/moon_audio_manager.gd" id="8_audio"]
```

**Add node before SceneInitializer:**
```gdscript
[node name="MoonAudioManager" type="Node" parent="."]
script = ExtResource("8_audio")
```

### 3. Update moon_landing_initializer.gd

Add audio manager to exports and initialization:

**Add export variable:**
```gdscript
@export var moon_audio_manager: MoonAudioManager = null
```

**Add to find_scene_nodes():**
```gdscript
if not moon_audio_manager:
    moon_audio_manager = get_node_or_null("../MoonAudioManager")
```

**Add to _ready() after initialize_hud():**
```gdscript
initialize_audio()
```

**Add new function:**
```gdscript
func initialize_audio() -> void:
    """Initialize the audio manager."""
    if not moon_audio_manager:
        push_warning("[MoonLandingInitializer] Moon audio manager not found - audio will not play")
        return

    var walking_controller: WalkingController = null
    if transition_system:
        walking_controller = transition_system.get_walking_controller()

    moon_audio_manager.initialize(spacecraft, walking_controller, landing_detector)
    print("[MoonLandingInitializer] Audio manager initialized")
```

## What Audio Adds to the Experience

### Immersion
- **Engine sounds** make flying the spacecraft feel powerful and responsive
- **Cockpit ambience** creates sense of being inside a vehicle
- **Footsteps** make walking on the moon tangible
- **Jetpack thrust** provides feedback for low-gravity flight
- **Breathing** reminds player they're in a space suit

### Feedback
- **Warning beeps** alert when descending too fast
- **Impact sounds** communicate landing force
- **Objective complete** rewards progress
- **Thruster bursts** confirm control inputs

### Atmosphere
- **Muffled sounds** convey the vacuum of space
- **No reverb** emphasizes isolation
- **Varied footsteps** add realism
- **Success chimes** celebrate achievements

## Audio System Features

### Dynamic Audio
- Engine pitch/volume scales with throttle
- Footstep timing matches walking speed
- Impact volume scales with velocity
- Jetpack pitch varies with fuel level

### 3D Spatial Audio
- All gameplay sounds are positional
- Sounds get quieter with distance
- UI sounds are non-positional (always same volume)

### Graceful Degradation
- System works without audio files (no crashes)
- Missing files logged to console
- Can add audio files later without code changes

### Performance
- Only 16 audio players created (well under Godot's 256 limit)
- Efficient looping for continuous sounds
- Auto-cleanup of one-shot sounds

## Audio Configuration

### Looping Sounds
In Godot Editor, for each looping sound:
1. Select file in FileSystem
2. Import tab → check "Loop"
3. Click "Reimport"

Files that need loop enabled:
- `engine_thrust_loop.ogg`
- `cockpit_ambience_loop.ogg`
- `jetpack_thrust_loop.ogg`
- `breathing_loop.ogg`

### Volume Adjustment
Default volumes are set in `MoonAudioManager`:
- Engine: -8 dB (base), 0 dB (max)
- Thrusters: -6 dB
- Footsteps: -12 dB
- Jetpack: -10 dB
- Breathing: -24 dB (very quiet)
- UI sounds: 0 dB (default)

Adjust these exports in Godot Editor if needed.

## Testing the Audio System

### Test Checklist
1. **Spacecraft Phase**
   - [ ] Press W/S → engine thrust sound
   - [ ] Hold W → pitch increases
   - [ ] Rotate (A/D/Q/E) → RCS thruster bursts
   - [ ] Background hum (cockpit ambience)

2. **Descent Phase**
   - [ ] Descend fast → warning beep
   - [ ] Get close to surface → sounds get louder

3. **Landing Phase**
   - [ ] Touch down → impact sound (volume based on speed)
   - [ ] After impact → dust settling
   - [ ] 1 second later → success chime

4. **Walking Phase**
   - [ ] Press SPACE to exit → cockpit ambience fades
   - [ ] Move → footsteps (timing matches speed)
   - [ ] Hold SPACE (jetpack) → ignition, then loop
   - [ ] Release SPACE → jetpack shutdown
   - [ ] Jump and land → landing thud
   - [ ] Breathing sound (very quiet background)

5. **Audio Quality**
   - [ ] 3D sounds fade with distance
   - [ ] No clipping or distortion
   - [ ] Smooth transitions between states
   - [ ] No audio gaps in loops

## Troubleshooting

### No Audio Playing
1. Check AudioManager autoload is enabled in project.godot
2. Check MoonAudioManager node exists in moon_landing.tscn
3. Check audio files exist in correct paths
4. Check console for missing file warnings
5. Check master volume in Godot audio settings

### Audio Cutting Out
1. Check if too many sounds playing simultaneously
2. Verify audio files are not corrupted
3. Check sample rate compatibility (44.1kHz or 48kHz)

### Looping Sounds Have Gaps
1. Ensure "Loop" is enabled in Import settings
2. Re-import the audio file
3. Check if audio file is seamless (no silence at start/end)

### Volume Too Loud/Quiet
1. Adjust export variables in MoonAudioManager
2. Check AudioServer bus volumes
3. Verify audio file levels are normalized

## Files Created

1. **scripts/audio/moon_audio_manager.gd** - Main audio manager (485 lines)
2. **MOON_LANDING_AUDIO_SYSTEM.md** - Complete documentation
3. **audio/AUDIO_FILES_NEEDED.txt** - Detailed audio file specifications
4. **scripts/audio/INTEGRATION_GUIDE.md** - This file

## Next Steps

1. **Create or source audio files** (20 files total)
2. **Update moon_landing.tscn** to include MoonAudioManager node
3. **Update moon_landing_initializer.gd** to initialize audio
4. **Test** all audio triggers in gameplay
5. **Fine-tune** volumes and pitch ranges based on playtesting
6. **Optional**: Add music layers, radio chatter, environmental audio

## Code Structure

```
MoonAudioManager
├── _ready()                    → Initialize managers, create players
├── initialize()                → Connect to gameplay systems
├── _process(delta)             → Update audio positions and state
│
├── Spacecraft Audio
│   ├── _update_spacecraft_audio()      → Engine, thrusters, ambience
│   └── _update_spacecraft_audio_positions() → 3D positioning
│
├── Walking Audio
│   ├── _update_walking_audio()         → Footsteps, jetpack, landing
│   └── _update_walking_audio_positions() → 3D positioning
│
├── Signal Handlers
│   ├── _on_thrust_applied()            → RCS thrusters
│   ├── _on_collision_occurred()        → Impact sounds
│   ├── _on_landing_detected()          → Landing sequence
│   ├── _on_walking_started()           → Walking mode audio
│   └── _on_walking_stopped()           → Return to spacecraft audio
│
└── Utility Functions
    ├── play_footstep()                 → Footstep with variation
    ├── play_warning_beep()             → Descent warning
    ├── play_objective_complete()       → Reward feedback
    └── stop_all_audio()                → Cleanup
```

## Audio Event Signals

MoonAudioManager emits signals for telemetry/debugging:
- `audio_event("footstep", intensity)`
- `audio_event("warning", intensity)`
- `audio_event("collision", speed)`
- `audio_event("landing_success", 1.0)`
- `audio_event("walking_started", 1.0)`

Connect to these for audio visualization or debugging.
