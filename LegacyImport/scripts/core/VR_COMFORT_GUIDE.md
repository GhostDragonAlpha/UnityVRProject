# VR Comfort System Guide

## Overview

The VRComfortSystem provides comfort features to reduce VR motion sickness during gameplay. It implements multiple comfort options that can be configured through the SettingsManager.

## Requirements

- **48.1**: Provide static cockpit reference frame
- **48.2**: Add vignetting during rapid acceleration
- **48.3**: Implement snap-turn options
- **48.4**: Create stationary mode option
- **48.5**: Save comfort preferences

## Features

### 1. Comfort Mode (Requirement 48.1)

Enables a static cockpit reference frame to provide a stable visual anchor during movement.

```gdscript
# Enable/disable comfort mode
vr_comfort_system.set_comfort_mode_enabled(true)

# Check if comfort mode is enabled
var enabled = vr_comfort_system.is_comfort_mode_enabled()
```

### 2. Vignetting Effect (Requirement 48.2)

Automatically applies a vignette (darkening of peripheral vision) during rapid acceleration to reduce motion sickness.

**How it works:**

- Tracks spacecraft acceleration in real-time
- Applies vignetting when acceleration exceeds 5 m/s²
- Maximum vignetting at 20 m/s² acceleration
- Smoothly fades in/out based on acceleration changes

```gdscript
# Enable/disable vignetting
vr_comfort_system.set_vignetting_enabled(true)

# Set maximum vignetting intensity (0.0 to 1.0)
vr_comfort_system.set_vignetting_intensity(0.7)

# Get current vignette intensity
var intensity = vr_comfort_system.get_vignette_intensity()

# Get current acceleration
var accel = vr_comfort_system.get_current_acceleration()
```

### 3. Snap Turn (Requirement 48.3)

Provides instant rotation instead of smooth turning to reduce motion sickness.

**Controls:**

- Right thumbstick left: Snap turn left
- Right thumbstick right: Snap turn right
- Cooldown: 0.3 seconds between snap turns

```gdscript
# Enable/disable snap turn
vr_comfort_system.set_snap_turn_enabled(true)

# Set snap turn angle (15-90 degrees)
vr_comfort_system.set_snap_turn_angle(45.0)

# Check if snap turn is enabled
var enabled = vr_comfort_system.is_snap_turn_enabled()
```

### 4. Stationary Mode (Requirement 48.4)

In stationary mode, the player remains stationary while the universe moves around them. This can significantly reduce motion sickness for sensitive users.

```gdscript
# Enable/disable stationary mode
vr_comfort_system.set_stationary_mode_enabled(true)

# Check if stationary mode is enabled
var enabled = vr_comfort_system.is_stationary_mode_enabled()
```

## Integration

### Initialization

The VRComfortSystem is automatically initialized by the ResonanceEngine after VRManager initialization.

```gdscript
# In ResonanceEngine
var vr_comfort_system = VRComfortSystem.new()
vr_comfort_system.initialize(vr_manager, spacecraft)
```

### Setting Spacecraft Reference

For acceleration tracking to work, the spacecraft must be set:

```gdscript
# Set spacecraft for acceleration tracking
vr_comfort_system.set_spacecraft(spacecraft_node)

# Or use the engine helper
ResonanceEngine.set_spacecraft_for_comfort_system(spacecraft_node)
```

### Settings Integration (Requirement 48.5)

The VRComfortSystem automatically loads settings from SettingsManager on initialization and responds to setting changes:

```gdscript
# Settings are automatically loaded from SettingsManager
# Changes to settings are automatically applied

# Access settings through SettingsManager
var settings = get_node("/root/SettingsManager")
settings.set_vr_comfort_mode(true)
settings.set_vr_vignetting_enabled(true)
settings.set_vr_vignetting_intensity(0.7)
settings.set_vr_snap_turn_enabled(false)
settings.set_vr_snap_turn_angle(45.0)
settings.set_vr_stationary_mode(false)
```

## Configuration

### Default Settings

```gdscript
vr_comfort_mode: true
vr_vignetting_enabled: true
vr_vignetting_intensity: 0.7
vr_snap_turn_enabled: false
vr_snap_turn_angle: 45.0
vr_stationary_mode: false
```

### Acceleration Thresholds

```gdscript
VIGNETTE_ACCEL_THRESHOLD: 5.0   # m/s² - start vignetting
VIGNETTE_ACCEL_MAX: 20.0         # m/s² - maximum vignetting
```

### Snap Turn Settings

```gdscript
SNAP_TURN_COOLDOWN_TIME: 0.3     # seconds between snap turns
```

## Signals

The VRComfortSystem emits the following signals:

```gdscript
# Emitted when comfort system is initialized
signal comfort_system_initialized

# Emitted when vignetting intensity changes
signal vignetting_changed(intensity: float)

# Emitted when snap turn is executed
signal snap_turn_executed(angle: float)

# Emitted when stationary mode is toggled
signal stationary_mode_changed(enabled: bool)
```

## Example Usage

```gdscript
# Get VR comfort system from engine
var comfort_system = ResonanceEngine.vr_comfort_system

# Connect to signals
comfort_system.vignetting_changed.connect(_on_vignetting_changed)
comfort_system.snap_turn_executed.connect(_on_snap_turn)

# Configure comfort settings
comfort_system.set_comfort_mode_enabled(true)
comfort_system.set_vignetting_enabled(true)
comfort_system.set_vignetting_intensity(0.8)
comfort_system.set_snap_turn_enabled(true)
comfort_system.set_snap_turn_angle(30.0)

# Set spacecraft for acceleration tracking
comfort_system.set_spacecraft(my_spacecraft)

# Get statistics
var stats = comfort_system.get_stats()
print("Comfort mode enabled: ", stats.comfort_mode_enabled)
print("Current vignette intensity: ", stats.vignette_intensity)
print("Current acceleration: ", stats.current_acceleration)
```

## Testing

Unit tests are available at `tests/unit/test_vr_comfort_system.gd`:

```bash
# Run tests
godot --headless --script tests/unit/test_vr_comfort_system.gd
```

## Performance Considerations

- Vignetting shader is lightweight and has minimal performance impact
- Acceleration tracking uses simple vector math
- Snap turn is instantaneous with no interpolation
- All features can be disabled individually for maximum performance

## Troubleshooting

### Vignetting not appearing

1. Check that vignetting is enabled: `comfort_system.is_vignetting_enabled()`
2. Verify spacecraft is set: `comfort_system.set_spacecraft(spacecraft)`
3. Check acceleration is above threshold (5 m/s²)
4. Ensure comfort mode is enabled

### Snap turn not working

1. Check that snap turn is enabled: `comfort_system.is_snap_turn_enabled()`
2. Verify VR controllers are connected
3. Check thumbstick input threshold (must exceed 0.7)
4. Ensure cooldown period has elapsed (0.3 seconds)

### Settings not persisting

1. Verify SettingsManager is available as autoload
2. Check that settings are being saved: `SettingsManager.save_settings()`
3. Verify settings file exists at `user://game_settings.cfg`

## Architecture

The VRComfortSystem follows these design principles:

1. **Modular**: Each comfort feature can be enabled/disabled independently
2. **Configurable**: All parameters can be adjusted through SettingsManager
3. **Automatic**: Vignetting responds automatically to acceleration
4. **Lightweight**: Minimal performance overhead
5. **Integrated**: Works seamlessly with VRManager and SettingsManager

## Future Enhancements

Potential future improvements:

- Teleport locomotion option
- Field of view reduction during movement
- Comfort grid overlay
- Customizable vignette colors
- Per-axis snap turn angles
- Acceleration-based audio cues
