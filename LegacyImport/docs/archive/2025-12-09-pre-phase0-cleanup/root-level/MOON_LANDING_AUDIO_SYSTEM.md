# Moon Landing Audio System

## Overview

A comprehensive audio system has been implemented for the moon landing experience to make it immersive and fun. The system includes spacecraft sounds, landing impact audio, moon walking footsteps, jetpack sounds, and UI feedback.

## Architecture

### MoonAudioManager (`scripts/audio/moon_audio_manager.gd`)

The MoonAudioManager is the central audio coordinator for the moon landing scene. It:
- Manages all audio playback for spacecraft, landing, and walking
- Connects to existing systems (AudioManager, SpatialAudio, Spacecraft, WalkingController, LandingDetector)
- Dynamically adjusts audio based on gameplay state (throttle, velocity, fuel levels)
- Uses 3D positional audio for spatial immersion
- Provides UI feedback sounds for objectives and warnings

### Integration Points

The audio manager integrates with:
1. **Spacecraft** - Engine thrust, RCS thrusters, cockpit ambience
2. **LandingDetector** - Landing impact, dust settling, success chimes
3. **WalkingController** - Footsteps, jetpack thrust, landing thuds, breathing
4. **MoonHUD** - Objective completion, warnings, notifications

## Audio Categories

### 1. Spacecraft Audio (3D Positional)

**Engine Thrust Loop** (`res://audio/sfx/spacecraft/engine_thrust_loop.ogg`)
- Continuous loop when throttle > 0
- Pitch varies with throttle (0.6 to 1.2)
- Volume scales logarithmically with throttle
- 3D positional at spacecraft location

**RCS Thruster Burst** (`res://audio/sfx/spacecraft/rcs_thruster_burst.ogg`)
- Plays when rotation controls are active
- Short burst sound for directional thrusters
- Higher pitch (1.2) for crisp feel

**Cockpit Ambience Loop** (`res://audio/sfx/spacecraft/cockpit_ambience_loop.ogg`)
- Quiet background hum when in spacecraft
- Fades out when exiting to walking mode
- Volume: -18 dB
- Creates sense of being inside a pressurized cabin

**Landing Gear Deploy** (`res://audio/sfx/spacecraft/landing_gear_deploy.ogg`)
- Mechanical sound (currently unused, placeholder for future feature)

### 2. Landing Audio (3D Positional)

**Landing Impact Sounds**
- `res://audio/sfx/landing/landing_impact_soft.ogg` - Gentle touchdown (< 2 m/s)
- `res://audio/sfx/landing/landing_impact_medium.ogg` - Normal landing (2-4 m/s)
- `res://audio/sfx/landing/landing_impact_hard.ogg` - Hard landing (> 4 m/s)
- Volume scales with impact velocity
- Slight pitch variation (-0.1 to +0.1) for variety

**Dust Settling** (`res://audio/sfx/landing/dust_settling.ogg`)
- Plays after landing impact
- Gentle swooshing sound of moon dust falling
- Volume: -10 dB

**Success Chime** (`res://audio/sfx/ui/success_chime.ogg`)
- Plays 1 second after successful landing
- Positive feedback for player
- 2D UI sound (non-positional)

### 3. Moon Walking Audio (3D Positional)

**Footstep Sounds**
- `res://audio/sfx/walking/footstep_moon_01.ogg`
- `res://audio/sfx/walking/footstep_moon_02.ogg`
- `res://audio/sfx/walking/footstep_moon_03.ogg`
- Muffled, crunchy sounds (space suit on moon regolith)
- Play at intervals based on walking speed
- Pitch variation: ±0.2 for natural variation
- Volume: -12 dB
- Should sound like: boots on gravel/sand but muffled by lack of atmosphere

**Jetpack Thrust Loop** (`res://audio/sfx/walking/jetpack_thrust_loop.ogg`)
- Continuous loop when jetpack is firing
- Pitch varies with fuel level (0.8 to 1.2)
- Volume: -10 dB
- Whooshing rocket sound

**Jetpack Ignition** (`res://audio/sfx/walking/jetpack_ignition.ogg`)
- Short burst when jetpack starts
- Higher volume for impact (-5 dB)

**Jetpack Shutdown** (`res://audio/sfx/walking/jetpack_shutdown.ogg`)
- Winding down sound when jetpack stops
- Volume: -8 dB

**Landing Thud** (`res://audio/sfx/walking/landing_thud.ogg`)
- Plays when landing after a jump
- Volume scales with fall velocity
- Pitch variation for variety
- Muffled thump sound

**Breathing Loop** (`res://audio/sfx/walking/breathing_loop.ogg`)
- Ambient breathing sound in helmet
- Very quiet: -24 dB
- Creates sense of being in a space suit
- Optional but adds immersion

### 4. UI Audio (2D Non-Positional)

**Objective Complete** (`res://audio/sfx/ui/objective_complete.ogg`)
- Positive feedback when objectives completed
- Pleasant chime or beep
- Triggers on: landing, exiting spacecraft, jump count, distance explored

**Warning Beep** (`res://audio/sfx/ui/warning_beep.ogg`)
- Periodic beep when descending too fast
- Alert player to danger
- Plays when: altitude < 100m AND velocity > 1.5x safe landing threshold

**Notification** (`res://audio/sfx/ui/notification.ogg`)
- Gentle sound for non-critical events
- Softer than warning beep

## Audio File Specifications

### Format
- **Container**: OGG Vorbis (`.ogg` files)
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Depth**: 16-bit
- **Channels**: Mono for 3D positional sounds, Stereo for UI sounds

### Loop Configuration
Looping sounds need loop points set in Godot:
- `engine_thrust_loop.ogg` - seamless loop
- `cockpit_ambience_loop.ogg` - seamless loop
- `jetpack_thrust_loop.ogg` - seamless loop
- `breathing_loop.ogg` - seamless loop

### Sound Design Guidelines

**Spacecraft Sounds:**
- Low rumble for engine thrust
- Metallic, hissing for RCS thrusters
- Gentle electronic hum for cockpit ambience

**Landing Sounds:**
- Dull thud (no atmosphere for sharp cracks)
- Dust whooshing (subtle, not like Earth wind)

**Moon Walking:**
- Footsteps should be muffled, crunchy
- NO echo or reverb (vacuum of space)
- Jetpack should sound like small rocket engine
- Breathing should be rhythmic, quiet

**UI Sounds:**
- Clean, synthetic tones
- Not too loud or jarring
- Positive for success, urgent for warnings

## Implementation Status

### Completed
- [x] MoonAudioManager script created
- [x] Audio player nodes defined (3D and 2D)
- [x] Integration with Spacecraft (thrust, velocity, collision signals)
- [x] Integration with LandingDetector (landing signal)
- [x] Integration with WalkingController (walking, jetpack, jumping)
- [x] Dynamic audio adjustment (pitch, volume based on gameplay)
- [x] Footstep timing based on movement speed
- [x] Jetpack audio with fuel-based pitch variation
- [x] Landing impact with velocity-based volume
- [x] Warning beeps for unsafe descent

### Pending
- [ ] Actual audio files need to be created/sourced
- [ ] MoonAudioManager node needs to be added to moon_landing.tscn
- [ ] MoonLandingInitializer needs to be updated to initialize audio manager
- [ ] Test all audio triggers in gameplay
- [ ] Fine-tune volume levels and pitch ranges
- [ ] Add audio file loading logic
- [ ] Connect HUD objective signals to audio feedback

## Integration Instructions

### Step 1: Add Audio Files
Create the following directory structure and add audio files:

```
audio/
├── sfx/
│   ├── spacecraft/
│   │   ├── engine_thrust_loop.ogg
│   │   ├── rcs_thruster_burst.ogg
│   │   ├── cockpit_ambience_loop.ogg
│   │   └── landing_gear_deploy.ogg
│   ├── landing/
│   │   ├── landing_impact_soft.ogg
│   │   ├── landing_impact_medium.ogg
│   │   ├── landing_impact_hard.ogg
│   │   └── dust_settling.ogg
│   ├── walking/
│   │   ├── footstep_moon_01.ogg
│   │   ├── footstep_moon_02.ogg
│   │   ├── footstep_moon_03.ogg
│   │   ├── jetpack_thrust_loop.ogg
│   │   ├── jetpack_ignition.ogg
│   │   ├── jetpack_shutdown.ogg
│   │   ├── landing_thud.ogg
│   │   └── breathing_loop.ogg
│   └── ui/
│       ├── objective_complete.ogg
│       ├── warning_beep.ogg
│       ├── notification.ogg
│       └── success_chime.ogg
```

### Step 2: Update moon_landing.tscn
Add MoonAudioManager node to the scene:

```gdscript
[node name="MoonAudioManager" type="Node" parent="."]
script = ExtResource("8_audio")  # Path to moon_audio_manager.gd
```

### Step 3: Update MoonLandingInitializer
Add audio manager initialization in `moon_landing_initializer.gd`:

```gdscript
@export var moon_audio_manager: MoonAudioManager = null

# In find_scene_nodes():
if not moon_audio_manager:
    moon_audio_manager = get_node_or_null("../MoonAudioManager")

# In _ready():
initialize_audio()

# Add new function:
func initialize_audio() -> void:
    if not moon_audio_manager:
        push_warning("[MoonLandingInitializer] Moon audio manager not found - audio will not play")
        return

    var walking_controller: WalkingController = null
    if transition_system:
        walking_controller = transition_system.get_walking_controller()

    moon_audio_manager.initialize(spacecraft, walking_controller, landing_detector)
    print("[MoonLandingInitializer] Audio manager initialized")
```

### Step 4: Load Audio Files
In MoonAudioManager, call `load_audio_files()` after audio files are added:

```gdscript
func _ready() -> void:
    _get_manager_references()
    _create_audio_players()

    # Load actual audio files if they exist
    load_audio_files()
```

### Step 5: Configure Audio in Godot Editor
For each looping sound in the audio/ directory:
1. Select the audio file in FileSystem
2. In Import tab, check "Loop"
3. Click "Reimport"

## Testing Checklist

- [ ] Engine thrust sound plays when holding W/S
- [ ] Engine pitch increases with throttle
- [ ] RCS thrusters fire when rotating (A/D/Q/E)
- [ ] Cockpit ambience plays continuously in spacecraft
- [ ] Landing impact plays when touching moon surface
- [ ] Impact volume scales with landing velocity
- [ ] Success chime plays after successful landing
- [ ] Dust settling sound plays after landing
- [ ] Warning beep plays when descending too fast
- [ ] Footsteps play when walking on moon
- [ ] Footstep timing matches walking speed
- [ ] Jetpack ignition plays when starting jetpack
- [ ] Jetpack thrust loop plays while flying
- [ ] Jetpack shutdown plays when stopping jetpack
- [ ] Landing thud plays when hitting ground after jump
- [ ] Breathing ambience plays while walking
- [ ] Cockpit ambience fades out when exiting spacecraft
- [ ] All 3D sounds are positional (louder when close)
- [ ] No audio plays from missing files (graceful degradation)

## Audio Budget

The system creates the following audio players:
- 3D Players (positional): 11
  - Spacecraft: 4
  - Landing: 2
  - Walking: 5
- 2D Players (UI): 5
  - UI sounds: 3
  - Success chime: 1
  - Breathing: 1

**Total: 16 audio players**

This is well within Godot's audio performance limits (256 channels) and provides rich immersive audio without overwhelming the audio bus.

## Future Enhancements

- Add radio chatter/mission control audio
- Add spacecraft creaking sounds during high-G maneuvers
- Add helmet HUD beeps and tones
- Add music layers that adapt to gameplay state
- Add environmental audio (solar wind when on surface)
- Add audio occlusion (muffled sounds through spacecraft hull)
- Add Doppler shift for fast-moving objects
- Add reverb zones for enclosed spaces
- Add haptic feedback synced with audio (VR controllers)

## Notes

- All 3D sounds use inverse square distance attenuation for realism
- Moon has no atmosphere, so no reverb or echo effects
- Sounds should be muffled/dampened compared to Earth
- Footsteps need to sound distinct from Earth footsteps
- Jetpack should sound powerful but not overwhelming
- UI sounds should be pleasant and non-intrusive
- Audio system gracefully handles missing files (won't crash if audio not found)
