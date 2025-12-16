# Jetpack Visual and Audio Effects

This document describes the jetpack effects system for the SpaceTime VR project.

## Overview

The jetpack effects system provides immersive visual, audio, and haptic feedback for the jetpack mechanic in walking mode. Effects scale dynamically based on thrust amount and fuel level, creating a responsive and engaging experience.

## Components

### 1. JetpackEffects (jetpack_effects.gd)

**Location:** `scripts/player/jetpack_effects.gd`

The main effects manager that creates and updates:
- **Particle Systems:** Thrust flame, smoke, sparks, and ground dust
- **Audio:** Thrust loop, ignition, shutdown, low fuel warning, and sputter sounds
- **Haptic Feedback:** VR controller vibration scaled by thrust intensity
- **Environmental Effects:** Ground dust clouds and physics push forces

**Key Methods:**
- `start_effects()` - Activates all effect systems
- `stop_effects()` - Deactivates all effect systems
- `update_thrust_effects(thrust_amount, fuel_percent)` - Updates effects based on current state
- `set_quality_level(quality)` - Adjusts particle counts for performance (0=Low, 1=Medium, 2=High)

### 2. WalkingController Integration

The `WalkingController` creates and manages the `JetpackEffects` instance:
- Effects node is positioned at feet level (`Vector3(0, -0.9, 0)`)
- Automatically starts/stops effects when jetpack activates/deactivates
- Updates effects every physics frame with current thrust and fuel values

**Integration Methods:**
- `setup_jetpack_effects()` - Creates JetpackEffects node (called in _ready)
- `update_jetpack_effects()` - Updates effects each frame (called in _physics_process)

## Particle Systems

### Thrust Particles
- **Count:** 150 particles
- **Lifetime:** 0.75 seconds
- **Speed:** 5-15 m/s
- **Direction:** Downward cone (30° spread)
- **Color:** Orange to dark red gradient
- **Scales with:** Thrust amount (0-100%)

### Flame Particles (Core)
- **Count:** 50 particles
- **Lifetime:** 0.5 seconds
- **Speed:** 15-22.5 m/s (faster than thrust)
- **Direction:** Tight downward cone (10° spread)
- **Color:** Bright white-yellow to orange gradient
- **Purpose:** Bright core flame for realism

### Smoke Particles
- **Count:** 35 particles
- **Lifetime:** 3.0 seconds
- **Speed:** 1-3 m/s
- **Direction:** Wide spread (45°)
- **Color:** Gray gradient (fades in and out)
- **Scales with:** Thrust amount × 0.7

### Spark Particles
- **Count:** 30 particles
- **Lifetime:** 0.2 seconds
- **Triggered when:** Thrust > 80%
- **Behavior:** One-shot burst with random directions
- **Color:** Yellow-white to orange-red

### Ground Dust Particles
- **Count:** 50 particles
- **Triggered when:** Distance to ground < 2.0m
- **Shape:** Ring emission pattern
- **Direction:** Outward and upward
- **Color:** Dust/sand colored
- **Purpose:** Environmental interaction feedback

## Audio System

### Thrust Sound (Continuous)
- **Type:** Looping
- **Pitch Range:** 0.8 - 1.2 (scales with thrust)
- **Volume Range:** -20dB to 0dB (scales with thrust)
- **Distance:** Max 50m attenuation
- **Behavior:** Plays while thrust > 10%

### Ignition Sound
- **Type:** One-shot
- **Volume:** -5dB
- **Trigger:** When jetpack activates
- **Purpose:** Start-up feedback

### Shutdown Sound
- **Type:** One-shot
- **Volume:** -8dB
- **Trigger:** When jetpack deactivates
- **Purpose:** Power-down feedback

### Low Fuel Warning
- **Type:** Looping
- **Volume:** -12dB
- **Trigger:** Fuel < 20%
- **Purpose:** Critical fuel warning

### Sputter Sound
- **Type:** Intermittent
- **Trigger:** Fuel < 20% AND thrust > 10%
- **Purpose:** Engine struggling at low fuel

## Haptic Feedback

**VR Controller Vibration:**
- **Base Intensity:** 0.3 (30%)
- **Max Intensity:** 0.7 (70%)
- **Frequency Range:** 50-200 Hz
- **Update Rate:** Continuous while thrust active
- **Applied to:** Both controllers simultaneously

**Scaling:**
```gdscript
intensity = base_intensity + (thrust_amount * (max_intensity - base_intensity))
frequency = base_frequency + (thrust_amount * (max_frequency - base_frequency))
```

## Fuel-Based Visual Changes

The thrust color shifts based on remaining fuel:

| Fuel Level | Color | Visual Effect |
|------------|-------|---------------|
| > 50% | Bright orange/white | Efficient, bright flame |
| 20-50% | Orange | Normal operation |
| < 20% | Blue-tinted | Sputtering, inefficient combustion |

This provides visual feedback about fuel state without checking UI.

## Environmental Effects

### Ground Force Application
- **Radius:** 3.0m
- **Strength:** 5.0 units (scales with thrust)
- **Affected Objects:** RigidBody3D nodes
- **Purpose:** Push nearby physics objects away from thrust

### Overheat System
- **Threshold:** 5.0 seconds of continuous thrust
- **Effect:** Visual warnings, reduced efficiency
- **Cooldown:** 50% faster than heat buildup
- **Status:** Currently placeholder (visual effects TODO)

## Performance Optimization

### Quality Levels

**Low (0):**
- Thrust: 75 particles
- Smoke: 17 particles
- Sparks: 15 particles

**Medium (1):**
- Thrust: 112 particles
- Smoke: 26 particles
- Sparks: 22 particles

**High (2):**
- Thrust: 150 particles
- Smoke: 35 particles
- Sparks: 30 particles

**Set via:**
```gdscript
jetpack_effects.set_quality_level(2)  # High quality
```

## HTTP API Testing Endpoints

The jetpack effects can be tested remotely via HTTP API:

### Test Effects
```bash
curl -X POST http://127.0.0.1:8080/jetpack/test_effects \
  -H "Content-Type: application/json" \
  -d '{
    "intensity": 0.8,
    "fuel_percent": 30.0,
    "duration": 3.0
  }'
```

**Parameters:**
- `intensity` (required): Thrust amount (0.0-1.0)
- `fuel_percent` (optional): Fuel percentage (0-100, default: 50)
- `duration` (optional): Test duration in seconds (default: 2.0)

### Test Sound
```bash
curl -X POST http://127.0.0.1:8080/jetpack/test_sound \
  -H "Content-Type: application/json" \
  -d '{
    "sound_type": "thrust",
    "volume": 0.7,
    "pitch": 1.2
  }'
```

**Parameters:**
- `sound_type` (required): "thrust", "ignition", "shutdown", "warning", or "sputter"
- `volume` (optional): Volume (0.0-1.0, default: 0.7)
- `pitch` (optional): Pitch scale (0.5-2.0, default: 1.0)

### Get Effects Status
```bash
curl http://127.0.0.1:8080/jetpack/effects_status
```

**Returns:**
```json
{
  "status": "success",
  "jetpack_effects": {
    "active": true,
    "thrust": 0.8,
    "fuel_percent": 35.0,
    "warning_level": 1,
    "distance_to_ground": 5.2,
    "overheated": false,
    "particle_counts": {
      "thrust": 150,
      "smoke": 35,
      "sparks": 30
    }
  },
  "walking_controller": {
    "is_active": true,
    "jetpack_enabled": true,
    "jetpack_firing": true,
    "current_fuel": 35.0,
    "max_fuel": 100.0,
    "fuel_percent": 35.0,
    "in_flight_mode": false,
    "current_gravity": 9.8
  }
}
```

### Set Quality Level
```bash
curl -X POST http://127.0.0.1:8080/jetpack/set_quality \
  -H "Content-Type: application/json" \
  -d '{"quality": 2}'
```

**Parameters:**
- `quality` (required): Quality level (0=Low, 1=Medium, 2=High)

## Usage Example

### In Code
```gdscript
# In walking_controller.gd
func _physics_process(delta: float) -> void:
    # ... physics code ...

    # Jetpack effects are updated automatically
    update_jetpack_effects()
```

### Manual Control (for testing)
```gdscript
# Get reference to effects
var effects = walking_controller.get_node("JetpackEffects")

# Start effects
effects.start_effects()

# Update with specific values
effects.update_thrust_effects(0.75, 50.0)  # 75% thrust, 50% fuel

# Stop effects
effects.stop_effects()

# Change quality
effects.set_quality_level(1)  # Medium quality
```

## Implementation Details

### Particle Process Materials

Particles use `ParticleProcessMaterial` for GPU-accelerated simulation:
- **Emission Shapes:** Sphere, ring (for ground dust)
- **Forces:** Gravity, damping
- **Color Ramps:** Gradient textures for color over lifetime
- **Scale Curves:** Size variation over lifetime

### Audio Generation

Currently using `AudioStreamGenerator` for procedural audio. Future improvements:
- Replace with pre-recorded audio samples
- Add sound variation for realism
- Implement proper thrust noise synthesis

### Haptic Integration

Haptics use the OpenXR haptic action system via `HapticManager`:
- Continuous effects renewed every frame
- Scales intensity and frequency with thrust
- Applied to both controllers for full immersion

## Known Issues and TODOs

1. **Audio Streams:** Procedural audio needs replacement with actual sound files
2. **Overheat Effects:** Visual heat distortion shader not yet implemented
3. **Particle Textures:** Using colored quads instead of proper sprite textures
4. **Performance:** Ground dust raycast could be optimized
5. **VR Haptics:** Frequency parameter currently not fully utilized in OpenXR

## Future Enhancements

1. **Afterburner Mode:** High-intensity boost with unique effects
2. **Damage Effects:** Spark and smoke increase when jetpack is damaged
3. **Environmental Variants:** Different particle colors based on planet atmosphere
4. **Trails:** Persistent smoke trails for high-speed flight
5. **Controller Lights:** Color-code controller LEDs by fuel level
6. **Spatial Audio:** 3D positioning based on player orientation

## References

**Related Files:**
- `scripts/player/walking_controller.gd` - Main controller integration
- `scripts/player/jetpack_effects.gd` - Effects implementation
- `scripts/core/haptic_manager.gd` - Haptic feedback system
- `scripts/audio/audio_manager.gd` - Audio management
- `addons/godot_debug_connection/jetpack_api_extension.gd` - HTTP API endpoints

**Related Requirements:**
- Jetpack thrust mechanic (walking_controller.gd)
- VR haptic feedback (haptic_manager.gd)
- Spatial audio (audio_manager.gd)
- Particle effects system (Godot GPUParticles3D)

---

**Last Updated:** 2025-12-02
**Version:** 1.0
**Author:** SpaceTime Development Team
