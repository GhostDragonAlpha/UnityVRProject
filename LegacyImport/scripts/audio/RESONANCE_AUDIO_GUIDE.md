# Resonance Audio System Integration Guide

## Overview

The Resonance Audio System provides immersive audio feedback for the resonance gameplay mechanics, featuring real-time frequency synthesis, spatial audio positioning, and dynamic audio layering.

## System Components

### 1. ResonanceAudioFeedback (`scripts/audio/resonance_audio_feedback.gd`)
Main controller that manages all resonance-related audio feedback.

**Key Features:**
- Real-time procedural audio generation
- Spatial 3D audio for scanned objects
- Dynamic layering of multiple frequencies
- Integration with ResonanceSystem signals
- Performance-optimized for 90 FPS VR target

**Exported Properties:**
- `enable_spatial_audio` - Enable 3D positional audio
- `enable_dynamic_layering` - Enable multiple frequency layering
- `max_simultaneous_frequencies` - Maximum concurrent frequencies (default: 8)
- `base_resonance_volume` - Base volume for resonance bus
- `emission_volume` - Volume for emission sounds
- `scanning_volume` - Volume for scanning sounds

### 2. ProceduralAudioGenerator (`scripts/audio/procedural_audio_generator.gd`)
Generates audio tones programmatically for real-time frequency matching.

**Enhanced Methods for Resonance:**
- `generate_realtime_tone()` - Core frequency synthesis with harmonic control
- `generate_interference_tone()` - Beating effect between two frequencies
- `generate_scanning_tone()` - Building pitch for scanning feedback
- `generate_cancellation_sound()` - Dissolution effect for object cancellation
- `generate_confirmation_chirp()` - Short confirmation sounds

### 3. SpatialAudio (`scripts/audio/spatial_audio.gd`)
3D audio positioning system for immersive VR experience.

**Features:**
- Distance attenuation with multiple models
- Doppler shift for moving objects
- Environmental reverb
- Up to 256 simultaneous audio channels

### 4. AudioManager (`scripts/audio/audio_manager.gd`)
Central audio management with caching and settings persistence.

## Integration Steps

### Step 1: Add ResonanceAudioFeedback to Scene

```gdscript
# In your main scene or ResonanceEngine setup
var resonance_audio = preload("res://scripts/audio/resonance_audio_feedback.gd").new()
add_child(resonance_audio)
```

### Step 2: Configure Audio Buses

The system automatically creates two audio buses:
- **Resonance** - Main resonance audio bus
- **ResonanceSFX** - Sound effects and interaction audio

Manual bus setup (if needed):
```gdscript
# Create resonance bus
var resonance_bus = AudioServer.get_bus_index("Resonance")
if resonance_bus == -1:
    AudioServer.add_bus()
    resonance_bus = AudioServer.bus_count - 1
    AudioServer.set_bus_name(resonance_bus, "Resonance")
    AudioServer.set_bus_send(resonance_bus, "Master")
```

### Step 3: Connect to ResonanceSystem

The system auto-detects ResonanceSystem and connects to signals:
- `object_scanned` - Plays confirmation chirp and creates spatial tone
- `interference_applied` - Updates audio based on amplitude changes
- `object_cancelled` - Plays cancellation sound and removes object tone

### Step 4: Connect to ResonanceInputController

Auto-detects input controller and responds to:
- `frequency_emitted` - Plays emission sounds (constructive/destructive)
- `emission_stopped` - Fades out emission audio
- `mode_changed` - Plays mode switch feedback
- `frequency_switched` - Plays quick-switch confirmation

## Audio Events

### Object Scanned
```gdscript
# Triggered when object is successfully scanned
# Plays: Confirmation chirp at 2x object frequency
# Creates: Spatial 3D tone at object position
```

### Frequency Emission
```gdscript
# Triggered when player emits frequency
# Constructive mode: Harmonic-rich tone
# Destructive mode: Dissonant sweep
```

### Object Cancellation
```gdscript
# Triggered when object is cancelled
# Plays: Descending dissolution sound with noise
# Removes: Object's spatial audio source
```

### Mode Switch
```gdscript
# Triggered when switching between constructive/destructive
# Constructive: Upward sweep (400Hz → 600Hz)
# Destructive: Downward sweep (600Hz → 400Hz)
```

## Spatial Audio Configuration

### Object Tone Settings
```json
{
  "loop_duration": 2.0,
  "volume_db": -10.0,
  "max_distance": 50.0,
  "attenuation_model": "inverse_square",
  "doppler_tracking": true
}
```

### Dynamic Position Updates
Object audio sources automatically update position as objects move:
```gdscript
# In _process() - updates every frame
spatial_audio.update_source_position(player, object.global_position)
```

## Dynamic Audio Layering

### Multiple Frequency Support
The system layers up to 8 simultaneous frequencies:
```gdscript
# Active frequencies are tracked automatically
active_frequencies: Array[float] = []
frequency_volumes: Dictionary = {}  # frequency: volume
```

### Ambient Resonance Layer
Background layer combines all active frequencies:
- 4-second loop duration
- Automatic volume normalization
- Smooth transitions (2.0 smoothing factor)

### Volume Ducking
When interference strength exceeds threshold:
```gdscript
# Audio ducking at 0.8 interference strength
if interference_strength > 0.8:
    # Reduce ambient layer volume
    ambient_volume *= 0.5
```

## Performance Optimization

### 90 FPS Target Compliance
- **Audio synthesis**: Pre-generated loops, real-time mixing only
- **Spatial updates**: Throttled to necessary changes only
- **Cleanup**: Automatic removal of inactive sources every 60 frames
- **Max sources**: Limited to 32 simultaneous audio sources

### Optimization Settings
```json
{
  "target_fps": 90,
  "max_audio_sources": 32,
  "cleanup_interval": 60,
  "stream_buffer_size": 4096
}
```

## Configuration File

### data/audio/resonance_sounds.json
Complete configuration including:
- Audio bus routing
- Frequency range settings (100-1000 Hz)
- Volume levels for all sound types
- Spatial audio parameters
- Performance targets

## Usage Examples

### Basic Setup
```gdscript
# Add to scene
var resonance_audio = preload("res://scripts/audio/resonance_audio_feedback.gd").new()
add_child(resonance_audio)

# Configure settings
resonance_audio.enable_spatial_audio = true
resonance_audio.max_simultaneous_frequencies = 6
resonance_audio.base_resonance_volume = 0.4
```

### Manual Audio Trigger
```gdscript
# Play custom resonance sound
var frequency = 440.0  # A4 note
var stream = procedural_generator.generate_realtime_tone(
    frequency, 
    1.0, 
    0.5, 
    harmonic_content=3
)
audio_manager.play_sfx_3d(stream, object_position)
```

### Dynamic Layering Control
```gdscript
# Add frequency to ambient layer
resonance_audio._add_active_frequency(440.0)

# Remove frequency
resonance_audio._remove_active_frequency(440.0)

# Update all layers
resonance_audio._update_ambient_resonance_layer()
```

## Testing

### Test Scene Setup
```gdscript
# Load test scene
var test_scene = preload("res://tests/test_resonance_audio.tscn").instantiate()
get_tree().root.add_child(test_scene)

# Run audio tests
test_scene.run_all_tests()
```

### Manual Testing Checklist
- [ ] Object scanning plays confirmation chirp
- [ ] Spatial audio positions match object locations
- [ ] Emission sounds differ for constructive/destructive modes
- [ ] Multiple frequencies layer without clipping
- [ ] Object cancellation plays dissolution sound
- [ ] Mode switch plays appropriate sweep
- [ ] Performance maintains 90 FPS with 8+ active frequencies
- [ ] Audio cleanup removes inactive sources properly

## Troubleshooting

### No Audio Playback
1. Verify audio buses are created: `AudioServer.get_bus_index("Resonance")`
2. Check volume levels: `AudioServer.get_bus_volume_db(bus_index)`
3. Confirm procedural generator is initialized
4. Validate signal connections to ResonanceSystem

### Performance Issues
1. Reduce `max_simultaneous_frequencies`
2. Disable `enable_dynamic_layering` for testing
3. Check active source count: `spatial_audio.get_active_source_count()`
4. Monitor FPS: `Engine.get_frames_per_second()`

### Spatial Audio Problems
1. Verify SpatialAudio system is found
2. Check listener position: `spatial_audio.get_listener()`
3. Confirm object positions are updating
4. Validate attenuation settings

## Requirements Traceability

- **20.1**: Object scanning audio feedback
- **20.2**: Constructive interference audio cues
- **20.3**: Destructive interference audio cues
- **20.4**: Wave interference pattern audio
- **20.5**: Object cancellation audio
- **65.1**: 3D spatial audio positioning
- **65.2**: Distance attenuation and mixing
- **65.3**: Doppler shift implementation
- **65.4**: Environmental reverb
- **65.5**: Multi-channel audio mixing

## Future Enhancements

- [ ] HRTF (Head-Related Transfer Function) support
- [ ] Occlusion and obstruction modeling
- [ ] Procedural reverb based on environment
- [ ] Adaptive audio quality based on performance
- [ ] Custom audio asset support alongside procedural generation