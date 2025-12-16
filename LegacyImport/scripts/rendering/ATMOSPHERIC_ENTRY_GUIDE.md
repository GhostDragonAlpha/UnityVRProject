# Atmospheric Entry System Guide

## Overview

The Atmospheric Entry System provides realistic atmospheric effects during planetary descent and ascent, including drag forces, heat effects, and audio/visual feedback.

## Requirements Implemented

- **54.1**: Apply atmospheric drag forces based on velocity and density
- **54.2**: Render heat shimmer and plasma effects using shaders
- **54.3**: Increase audio intensity with rumbling and wind sounds
- **54.4**: Apply heat damage at excessive speeds
- **54.5**: Reverse effects when exiting atmosphere

## Architecture

### Components

1. **AtmosphereSystem** (`scripts/rendering/atmosphere_system.gd`)

   - Main system managing all atmospheric effects
   - Applies drag forces directly to spacecraft
   - Manages visual and audio effects

2. **Heat Shimmer Shader** (`shaders/heat_shimmer.gdshader`)

   - Creates distortion effects during high-speed entry
   - Adds plasma glow overlay
   - Intensity-based activation

3. **TransitionSystem Integration** (`scripts/player/transition_system.gd`)
   - Activates atmosphere system when entering atmosphere
   - Updates effects based on altitude
   - Deactivates when exiting

## Physics

### Drag Force Calculation

The system implements the standard aerodynamic drag formula:

```
F_drag = 0.5 * ρ * v² * C_d * A
```

Where:

- `ρ` (rho) = atmospheric density (kg/m³)
- `v` = velocity magnitude (m/s)
- `C_d` = drag coefficient (dimensionless, default 0.5)
- `A` = cross-sectional area (m², default 10.0)

The drag force always opposes the velocity direction:

```gdscript
drag_direction = -velocity.normalized()
drag_force = drag_direction * drag_magnitude
```

### Heat Damage

Heat damage is applied when speed exceeds the threshold (default 500 m/s):

```gdscript
speed_ratio = (speed - heat_damage_threshold) / heat_damage_threshold
heat_damage = speed_ratio * max_heat_damage * atmosphere_ratio
```

Heat damage increases linearly with:

- Speed above threshold
- Atmospheric density

## Visual Effects

### Heat Shimmer

- **Activation**: When speed > 80% of heat damage threshold
- **Intensity**: Scales with speed and atmosphere density
- **Effect**: Screen-space distortion with plasma glow
- **Shader Parameters**:
  - `intensity`: 0.0 to 1.0
  - `time_scale`: Animation speed
  - `plasma_color`: RGB color of plasma effect

### Plasma Particles

- **Activation**: When speed > heat damage threshold and atmosphere ratio > 0.3
- **Amount**: Scales with heat intensity
- **Position**: Follows spacecraft
- **Appearance**: Orange/red glowing particles

## Audio Effects

### Rumble Audio

- **Purpose**: Low-frequency atmospheric entry sound
- **Volume**: Scales with atmosphere density and speed
- **Pitch**: Increases with speed (0.7 to 1.3)
- **Activation**: When atmosphere ratio > 0.05

### Wind Audio

- **Purpose**: High-frequency wind/air resistance sound
- **Volume**: Scales with atmosphere density and speed
- **Pitch**: Increases with speed (0.8 to 1.3)
- **Activation**: When atmosphere ratio > 0.05

## Usage

### Basic Setup

```gdscript
# In your main scene or engine coordinator
var atmosphere_system = AtmosphereSystem.new()
add_child(atmosphere_system)

# When spacecraft enters atmosphere
atmosphere_system.activate(planet, spacecraft)

# In physics process, update effects
var atmosphere_ratio = calculate_atmosphere_ratio(altitude)
atmosphere_system.update_effects(atmosphere_ratio, spacecraft.linear_velocity)

# When exiting atmosphere
atmosphere_system.deactivate()
```

### Integration with TransitionSystem

The TransitionSystem automatically manages the atmosphere system:

```gdscript
# Initialize with atmosphere system reference
transition_system.initialize(spacecraft, lod_manager, floating_origin, atmosphere_system)

# System automatically:
# - Activates when entering atmosphere
# - Updates effects based on altitude
# - Deactivates when exiting
```

### Customization

Adjust parameters in the AtmosphereSystem:

```gdscript
atmosphere_system.drag_coefficient = 0.7  # Increase drag
atmosphere_system.cross_sectional_area = 15.0  # Larger spacecraft
atmosphere_system.heat_damage_threshold = 600.0  # Higher threshold
atmosphere_system.max_heat_damage = 15.0  # More damage
```

## Signals

### drag_applied(force: Vector3)

Emitted when drag force is applied to spacecraft.

### heat_damage_applied(damage: float)

Emitted when heat damage is applied.

### atmosphere_effects_updated(intensity: float)

Emitted each frame with overall effect intensity.

## Testing

### Unit Tests

Run unit tests to verify individual components:

```bash
# Run from Godot editor
# Open: tests/unit/test_atmosphere_system.gd
# Click "Run Scene"
```

Tests verify:

- Drag force calculation accuracy
- Heat damage threshold behavior
- Visual effect intensity scaling
- Audio effect activation
- Proper deactivation

### Integration Tests

Run integration tests to verify complete flow:

```bash
# Run from Godot editor
# Open: tests/integration/test_atmospheric_entry.gd
# Click "Run Scene"
```

Tests verify:

- Complete entry sequence
- Effect coordination
- State transitions
- Requirement compliance

## Performance Considerations

### Optimization Tips

1. **Audio Streaming**: Use compressed audio formats for wind/rumble sounds
2. **Particle Count**: Adjust plasma particle count based on performance
3. **Shader Complexity**: Heat shimmer shader is screen-space, minimal cost
4. **Update Frequency**: Effects update every frame, but smoothed with lerp

### Performance Targets

- Drag calculation: < 0.1ms per frame
- Visual effects: < 0.5ms per frame
- Audio effects: < 0.2ms per frame
- Total overhead: < 1ms per frame

## Troubleshooting

### No Drag Force Applied

**Problem**: Spacecraft not slowing down in atmosphere

**Solutions**:

- Verify spacecraft reference is passed to `activate()`
- Check spacecraft is a RigidBody3D
- Ensure atmosphere_ratio > 0
- Verify velocity > 0.1 m/s

### No Visual Effects

**Problem**: Heat shimmer or plasma not visible

**Solutions**:

- Check speed > heat_damage_threshold \* 0.8
- Verify atmosphere_ratio > 0.3
- Ensure shaders are loaded correctly
- Check heat_shimmer_mesh is child of camera

### No Audio

**Problem**: Rumble or wind sounds not playing

**Solutions**:

- Verify audio files are loaded
- Check audio bus "SFX" exists
- Ensure atmosphere_ratio > 0.05
- Verify AudioStreamPlayer3D nodes are created

### Excessive Heat Damage

**Problem**: Spacecraft taking too much damage

**Solutions**:

- Increase `heat_damage_threshold`
- Decrease `max_heat_damage`
- Reduce atmospheric density
- Slow down entry speed

## Future Enhancements

Potential improvements for future versions:

1. **Variable Atmospheric Composition**: Different drag coefficients per planet
2. **Altitude-Based Density**: Exponential density falloff with altitude
3. **Angle of Attack**: Drag varies with spacecraft orientation
4. **Ablative Heat Shield**: Consumable heat protection
5. **Sonic Boom**: Audio effect when crossing sound barrier
6. **Contrails**: Visual trail effect in atmosphere
7. **G-Force Effects**: Visual feedback for acceleration forces

## References

- Aerodynamic Drag: https://en.wikipedia.org/wiki/Drag_equation
- Atmospheric Entry: https://en.wikipedia.org/wiki/Atmospheric_entry
- Heat Shield Design: https://en.wikipedia.org/wiki/Heat_shield
- Godot Physics: https://docs.godotengine.org/en/stable/tutorials/physics/
