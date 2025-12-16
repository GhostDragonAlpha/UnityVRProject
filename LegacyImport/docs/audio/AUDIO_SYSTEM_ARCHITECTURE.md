# Audio System Architecture

## Overview

SpaceTime's audio system provides immersive 3D spatial audio designed for VR experiences, real-time procedural audio generation, dynamic game state feedback, and specialized resonance gameplay mechanics. The architecture consists of five interconnected subsystems working in concert to deliver a rich, physics-based audio experience.

## System Components

### 1. AudioManager (Central Hub)
**File:** `C:/godot/scripts/audio/audio_manager.gd`

Central coordinator for all audio operations in the game. Manages loading, caching, playback, mixing, and settings persistence.

**Key Responsibilities:**
- Audio file loading and caching via ResourceLoader
- Volume control across multiple buses (Master, Music, SFX, Ambient)
- Music playback with fade-in/fade-out transitions
- Settings persistence using ConfigFile
- Integration point for all subsystems

**Audio Bus Architecture:**
- **Master Bus**: Global volume control
- **Music Bus**: Background music tracks
- **SFX Bus**: Sound effects and one-shots
- **Ambient Bus**: Environmental ambient sounds
- **Spatial Bus**: 3D positioned sounds (managed by SpatialAudio)
- **Resonance Bus**: Resonance gameplay audio (managed by ResonanceAudioFeedback)
- **Feedback Bus**: Game state audio feedback (managed by AudioFeedback)

**Performance:**
- Supports up to 256 simultaneous audio channels via AudioBusLayout
- Automatic cleanup of finished one-shot sounds
- Resource caching to minimize disk I/O

### 2. SpatialAudio (3D Audio Engine)
**File:** `C:/godot/scripts/audio/spatial_audio.gd`

Manages 3D spatial audio positioning with distance attenuation, Doppler shift, and environmental reverb for VR immersion.

**Key Features:**
- **3D Positioning**: AudioStreamPlayer3D for accurate spatial placement
- **Distance Attenuation**: Four attenuation models (inverse, inverse square, linear, exponential)
- **Doppler Shift**: Realistic pitch changes for moving sources
- **Environmental Reverb**: Room-based reverb simulation via AudioEffectReverb
- **VR Integration**: Automatic XRCamera3D listener detection

**Audio Source Management:**
- Maximum 256 simultaneous sources
- Automatic cleanup of finished sounds
- Dynamic source creation and removal
- Position tracking for moving sources

**VR-Specific Optimizations:**
- Automatic listener tracking via XRCamera3D
- Binaural audio support through Godot's 3D audio engine
- Low-latency playback for haptic/audio synchronization

### 3. ProceduralAudioGenerator (Real-time Synthesis)
**File:** `C:/godot/scripts/audio/procedural_audio_generator.gd`

Generates audio waveforms procedurally for testing and dynamic gameplay audio. Creates AudioStreamWAV files programmatically.

**Synthesis Capabilities:**
- **Sine Waves**: Pure tones at specified frequencies
- **Harmonic Series**: Complex tones with overtones
- **White Noise**: Random noise generation
- **Frequency Sweeps**: Smooth frequency transitions
- **Interference Patterns**: Beating effects between frequencies
- **Enveloped Sounds**: ADSR-style amplitude shaping

**Resonance-Specific Generators:**
- Real-time frequency tones with dynamic parameters
- Interference/beating tone generation
- Scanning tones with exponential sweeps
- Cancellation dissolution sounds
- Confirmation chirps

**Use Cases:**
- Placeholder audio during development
- Dynamic resonance feedback tones
- UI confirmation sounds
- Real-time frequency visualization

**Important:** These are simple procedural sounds for testing only. Replace with proper audio assets for production.

### 4. ResonanceAudioFeedback (Gameplay Audio)
**File:** `C:/godot/scripts/audio/resonance_audio_feedback.gd`

Provides immersive audio feedback for the resonance gameplay mechanic, where players use frequency matching and wave interference.

**Core Features:**
- **Frequency Matching Audio**: Real-time tones matching scanned object frequencies
- **Spatial Object Tones**: 3D audio sources attached to scanned objects
- **Emission Sounds**: Differentiated audio for constructive vs. destructive modes
- **Dynamic Layering**: Composite ambient layer of all active frequencies
- **Interference Feedback**: Volume and pitch changes based on wave interference strength

**Signal-Based Integration:**
Connects to ResonanceSystem and ResonanceInputController via signals:
- `object_scanned`: Create spatial tone for scanned object
- `interference_applied`: Adjust volume/pitch based on interference
- `object_cancelled`: Fade out and remove object's tone
- `frequency_emitted`: Play emission sound
- `mode_changed`: Audio cue for constructive/destructive switch

**Audio Buses:**
- **Resonance**: Main resonance audio bus
- **ResonanceSFX**: Sound effects for scanning/emission

**Performance Considerations:**
- Maximum 8 simultaneous active frequencies for dynamic layering
- Real-time synthesis of composite ambient tones
- Efficient spatial audio source pooling
- Automatic position updates for moving objects

### 5. AudioFeedback (Game State Feedback)
**File:** `C:/godot/scripts/audio/audio_feedback.gd`

Provides continuous audio feedback based on game state: velocity, entropy, gravity wells, and signal coherence.

**Feedback Types:**

1. **Base Harmonic Tone (432 Hz)**
   - Constant reference tone when idle
   - Modulated by all other feedback types

2. **Doppler Shift (Velocity)**
   - Pitch shift based on spacecraft velocity
   - Up to 20% pitch increase at maximum speed
   - Realistic motion feedback

3. **Entropy Effects**
   - Bit-crushing/distortion with increasing entropy
   - Drive and pre-gain increase with entropy level
   - Simulates signal degradation

4. **Gravity Well Effects**
   - Bass-heavy distortion near celestial bodies
   - Volume boost within 10x body radius
   - Immersive gravitational presence

5. **SNR Effects (Signal-to-Noise Ratio)**
   - Audio dropouts at low SNR (<25%)
   - Static noise introduction at low SNR (<50%)
   - Simulates communication degradation

**Audio Effects Used:**
- `AudioEffectDistortion`: For entropy and gravity feedback
- `AudioEffectPitchShift`: For Doppler shift

## Integration Flow

```
┌─────────────────┐
│  AudioManager   │ (Central Coordinator)
│  (Autoload)     │
└────────┬────────┘
         │
         ├──> SpatialAudio ──> VR Camera (XRCamera3D)
         │         │
         │         └──> AudioStreamPlayer3D nodes (up to 256)
         │
         ├──> ResonanceAudioFeedback
         │         │
         │         ├──> ProceduralAudioGenerator (tone synthesis)
         │         ├──> SpatialAudio (3D object tones)
         │         └──> ResonanceSystem (signal connections)
         │
         └──> AudioFeedback
                   │
                   ├──> Spacecraft (velocity, position)
                   └──> SignalManager (entropy, SNR)
```

## Initialization Order

The audio system is initialized as part of the ResonanceEngine subsystem startup (Phase 5):

1. **AudioManager** initializes first (autoload)
   - Setup audio buses
   - Create music player
   - Load saved settings
   - Apply volume levels

2. **SpatialAudio** initializes
   - Setup spatial/reverb buses
   - Find VR camera listener
   - Configure attenuation models

3. **ProceduralAudioGenerator** initializes (as needed)
   - No initialization required (stateless)

4. **AudioFeedback** initializes
   - Setup feedback bus and effects
   - Generate/load base harmonic tone
   - Find spacecraft and signal manager references

5. **ResonanceAudioFeedback** initializes
   - Setup resonance-specific buses
   - Create audio players
   - Connect to resonance system signals
   - Find spatial audio and audio manager

## Audio Bus Layout

```
Master (0 dB)
├── Music (-3 dB)
│   └── Music Player
├── SFX (0 dB)
│   └── Sound Effects
├── Ambient (-6 dB)
│   └── Ambient Sounds
├── Spatial (0 dB)
│   ├── 3D Audio Sources
│   └── Reverb (-3 dB)
│       └── [AudioEffectReverb]
├── Resonance (-10 dB)
│   ├── Object Tones
│   └── ResonanceSFX (-1 dB)
│       └── Scanning/Emission Sounds
└── Feedback (-10 dB)
    ├── [AudioEffectDistortion]
    ├── [AudioEffectPitchShift]
    └── Base Tone + State Feedback
```

## VR Audio Considerations

### Binaural Audio
- Godot 4.x provides built-in binaural audio through AudioStreamPlayer3D
- XRCamera3D automatically serves as the audio listener
- No additional configuration needed for basic spatial audio

### Performance Targets
- Audio processing must not interfere with 90 FPS VR target
- Use audio bus effects sparingly (max 2-3 per bus)
- Limit simultaneous AudioStreamPlayer3D nodes to 64 for performance
- Use spatial audio reference distance wisely to cull distant sources

### Latency Considerations
- Haptic feedback synchronized with audio events
- ResonanceAudioFeedback connects to haptic system for resonance interactions
- Audio playback latency typically 10-20ms on modern VR systems

### Comfort Features
- Avoid sudden volume spikes (use fade-in/fade-out)
- Bass frequencies should be moderate to prevent nausea
- Audio cues should complement visual cues, not override them

## Performance Optimization

### Memory Management
- AudioManager caches loaded streams to avoid repeated disk I/O
- One-shot sounds automatically cleaned up after playback
- SpatialAudio periodically removes inactive sources (every 60 frames)

### CPU Optimization
- Procedural generation should be used sparingly (cache results)
- Limit active frequencies in dynamic layering (max 8)
- Use simpler attenuation models for better performance
- Disable Doppler tracking when not needed

### Audio Pool Management
```gdscript
# SpatialAudio manages a pool of AudioStreamPlayer3D nodes
# Maximum: 256 channels (configurable)
# Automatic cleanup when limit reached
# Oldest inactive sources removed first
```

## Common Patterns

### Playing a 3D Sound
```gdscript
# Get audio manager
var audio_mgr = get_node("/root/AudioManager")

# Play 3D sound at position
audio_mgr.play_sfx_3d("res://data/audio/explosion.ogg",
                      explosion_position,
                      volume_db)
```

### Creating a Looping Ambient Source
```gdscript
# Get spatial audio system
var spatial = audio_mgr.get_spatial_audio()

# Create looping source
var stream = audio_mgr.load_audio("res://data/audio/ambient/engine_idle.tres")
var source = spatial.play_looping_sound(stream, engine_position, -5.0)

# Later, update position
spatial.update_source_position(source, new_position)

# When done, remove
spatial.remove_audio_source(source)
```

### Adjusting Volume Levels
```gdscript
# Set master volume (0.0 to 1.0)
audio_mgr.set_master_volume(0.8)

# Set music volume
audio_mgr.set_music_volume(0.6)

# Settings automatically saved to user://audio_settings.cfg
```

### Generating Procedural Audio
```gdscript
var generator = ProceduralAudioGenerator.new()

# Generate a 440 Hz tone for 2 seconds
var tone = generator.generate_sine_tone(440.0, 2.0, 0.5)

# Play it
var player = AudioStreamPlayer.new()
player.stream = tone
add_child(player)
player.play()
```

## Debugging Audio Issues

### Common Problems

1. **No sound playing**
   - Check volume levels: `AudioManager.get_master_volume()`
   - Verify audio bus setup: Check AudioServer bus count
   - Ensure AudioStreamPlayer/3D is child of a node in scene tree
   - Check if audio files are loaded correctly

2. **3D audio not positioned correctly**
   - Verify XRCamera3D is in scene and active
   - Check `SpatialAudio.listener` is set correctly
   - Ensure AudioStreamPlayer3D `global_position` is set
   - Verify attenuation model and unit_size/max_distance

3. **Crackling or distortion**
   - Check for volume clipping (multiple loud sources)
   - Reduce distortion effect drive values
   - Increase audio buffer size in project settings

4. **Performance issues**
   - Count active AudioStreamPlayer3D sources
   - Disable Doppler tracking if not needed
   - Reduce reverb room size and wet level
   - Check for memory leaks (use `SpatialAudio.cleanup_inactive_sources()`)

### Diagnostic Methods
```gdscript
# Check active source count
var count = spatial_audio.get_active_source_count()
print("Active audio sources: ", count)

# Check if audio is muted
if audio_mgr.is_muted():
    print("Audio is muted!")

# Get current volumes
print("Master: ", audio_mgr.get_master_volume())
print("Music: ", audio_mgr.get_music_volume())
print("SFX: ", audio_mgr.get_sfx_volume())

# Check listener
var listener = spatial_audio.get_listener()
if listener:
    print("Listener: ", listener.name, " at ", listener.global_position)
```

## Future Enhancements

### Planned Features
- Real-time audio synthesis using AudioStreamGenerator
- Advanced reverb zones with environmental presets
- Occlusion and obstruction for 3D audio
- Audio visualization for debugging
- Audio event system for timeline-based audio

### Performance Improvements
- Audio source pooling and reuse
- LOD system for distant audio sources
- Adaptive quality based on frame rate
- Multi-threaded audio generation

## Requirements Coverage

This audio system fulfills the following project requirements:

**Core Audio (Req 65.x):**
- 65.1: Load and cache audio files using ResourceLoader
- 65.2: Manage sound playback and mixing via AudioManager
- 65.3: Control volume levels via AudioServer
- 65.4: Handle audio streaming for music
- 65.5: Mix up to 256 simultaneous channels using AudioBusLayout

**Resonance Audio (Req 20.x):**
- 20.1: Play frequency tones matching scanned objects
- 20.2: Spatial audio for 3D object positioning
- 20.3: Dynamic layering of active resonance frequencies
- 20.4: Interference feedback through volume/pitch modulation
- 20.5: Mode-specific audio (constructive vs. destructive)

**Game State Feedback (Req 27.x):**
- 27.1: Play 432Hz harmonic base tone when idle
- 27.2: Pitch-shift audio with velocity (Doppler)
- 27.3: Apply bit-crushing effects with entropy
- 27.4: Add bass-heavy distortion in gravity wells
- 27.5: Introduce dropouts and static at low SNR

## Related Documentation

- [Spatial Audio Guide](SPATIAL_AUDIO_GUIDE.md) - VR spatial audio implementation
- [API Reference](API_REFERENCE.md) - Complete API documentation
- [CLAUDE.md](../../CLAUDE.md) - Project overview and development workflow
- [HTTP_API.md](../../addons/godot_debug_connection/HTTP_API.md) - Remote audio control endpoints
