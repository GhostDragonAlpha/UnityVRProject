# HUD System Guide

## Overview

The HUD (Heads-Up Display) system provides a 3D VR-friendly interface that displays critical spacecraft information to the player. The HUD is implemented as a collection of Label3D nodes and 3D meshes that float in front of the player's view.

## Requirements Implemented

This implementation satisfies the following requirements from the design specification:

### Requirement 39.1: Velocity Display

- **Display velocity magnitude and direction using Label3D**
- Shows current speed in m/s
- Shows normalized direction vector (x, y, z)
- Updates in real-time as spacecraft moves

### Requirement 39.2: Light Speed Percentage

- **Show percentage of light speed with color coding**
- Displays current speed as percentage of c (speed of light)
- Color coding:
  - Green: < 50% of c (safe speeds)
  - Yellow: 50-80% of c (high speeds)
  - Red: > 80% of c (approaching relativistic speeds)

### Requirement 39.3: SNR Health Display

- **Display SNR percentage with health bar using ProgressBar**
- Shows signal strength as a percentage
- Visual 3D health bar that scales with SNR
- Color coding:
  - Green: > 50% SNR (healthy)
  - Yellow: 25-50% SNR (warning)
  - Red: < 25% SNR (critical)

### Requirement 39.4: Escape Velocity Comparison

- **Show escape velocity comparison in gravity wells**
- Only visible when near celestial bodies
- Compares current velocity to escape velocity
- Color coding:
  - Green: Above escape velocity (can escape)
  - Yellow: 80-100% of escape velocity (close)
  - Red: Below 80% of escape velocity (captured)

### Requirement 39.5: Time Information

- **Display time multiplier and simulated date**
- Shows current time acceleration factor (1x, 10x, 100x, etc.)
- Displays simulated date in UTC format
- Highlights time multiplier in yellow when accelerated

## Architecture

### Class Structure

```gdscript
class_name HUD extends Node3D
```

The HUD is a Node3D that can be positioned in 3D space, typically in front of the player's camera in VR.

### Key Components

1. **Label3D Elements**: Text displays for all information
2. **MeshInstance3D**: 3D health bar for SNR visualization
3. **System References**: Connections to spacecraft, signal manager, time manager, and relativity manager
4. **Update System**: Configurable update frequency to balance performance and responsiveness

### Data Flow

```
Game Systems → HUD._update_hud_data() → HUD._update_hud_display() → Visual Elements
     ↓
  Signals → Signal Handlers → Reactive Updates
```

## Usage

### Basic Setup

```gdscript
# Create HUD instance
var hud = HUD.new()
add_child(hud)

# Position HUD in front of camera
hud.position = Vector3(0, 0.2, -1.5)

# Connect to game systems
hud.set_spacecraft(spacecraft)
hud.set_signal_manager(signal_manager)
hud.set_time_manager(time_manager)
hud.set_relativity_manager(relativity_manager)
```

### Integration with VR

The HUD is designed to work in VR by:

- Using Label3D nodes with billboard mode enabled
- Positioning elements at comfortable viewing distance
- Using no_depth_test to ensure visibility
- Scaling appropriately for VR viewing

### Positioning

The HUD can be attached to the VR camera or positioned in world space:

```gdscript
# Attach to VR camera
var xr_camera = get_node("/root/XROrigin3D/XRCamera3D")
xr_camera.add_child(hud)
hud.position = Vector3(0, 0.2, -1.5)  # Offset from camera
```

## Configuration

### Update Frequency

Control how often the HUD updates:

```gdscript
hud.update_frequency = 10.0  # 10 updates per second
```

Higher frequencies provide smoother updates but use more CPU. Default is 10 Hz, which provides good responsiveness while maintaining performance.

### HUD Offset and Scale

Adjust positioning and size:

```gdscript
hud.hud_offset = Vector3(0, 0.2, -1.5)  # Position relative to camera
hud.hud_scale = 0.5  # Scale factor for all elements
```

### Color Thresholds

The color coding thresholds are defined as constants but can be modified:

```gdscript
const CRITICAL_THRESHOLD: float = 0.25  # 25%
const WARNING_THRESHOLD: float = 0.50   # 50%
```

## API Reference

### Public Methods

#### System References

```gdscript
func set_spacecraft(craft: Spacecraft) -> void
func set_signal_manager(manager: SignalManager) -> void
func set_time_manager(manager: TimeManager) -> void
func set_relativity_manager(manager) -> void
func set_nearest_celestial_body(body: CelestialBody) -> void
```

#### Visibility Control

```gdscript
func show_hud() -> void
func hide_hud() -> void
func toggle_hud() -> void
```

### Signals

The HUD listens to signals from game systems:

- `spacecraft.velocity_changed` - Updates velocity display
- `signal_manager.snr_changed` - Updates SNR display
- `signal_manager.signal_critical` - Triggers critical warnings
- `signal_manager.signal_low` - Triggers low signal warnings
- `time_manager.time_acceleration_changed` - Updates time multiplier
- `time_manager.simulation_date_changed` - Updates date display

## Display Elements

### Velocity Display

- **Position**: Upper left
- **Format**: "Velocity: XXX.X m/s"
- **Direction**: "(X.XX, Y.YY, Z.ZZ)"
- **Color**: Cyan (normal)

### Light Speed Display

- **Position**: Center left
- **Format**: "Speed: XX.XX% of c"
- **Color**: Green → Yellow → Red (based on speed)

### SNR Display

- **Position**: Middle left
- **Format**: "Signal: XXX%"
- **Health Bar**: 3D bar that scales horizontally
- **Color**: Green → Yellow → Red (based on SNR)

### Escape Velocity Display

- **Position**: Lower center left
- **Format**: "Escape: XXX.X m/s (Current: XXX.X m/s)"
- **Visibility**: Only shown near celestial bodies
- **Color**: Green → Yellow → Red (based on comparison)

### Time Display

- **Position**: Bottom left
- **Format**:
  - "Time: Xx" (multiplier)
  - "Date: YYYY-MM-DD HH:MM:SS UTC"
- **Color**: Cyan (normal), Yellow (accelerated)

## Performance Considerations

### Update Frequency

The HUD uses a configurable update frequency (default 10 Hz) to balance responsiveness and performance:

```gdscript
var _update_interval: float = 0.1  # 10 Hz
```

This means the HUD updates 10 times per second, which is sufficient for most gameplay while minimizing CPU usage.

### Label3D Optimization

Label3D nodes are relatively lightweight, but the HUD uses several optimizations:

- Billboard mode for automatic facing
- No depth test for consistent visibility
- Render priority to ensure proper layering
- Unshaded materials for health bar (no lighting calculations)

### Signal-Based Updates

The HUD uses both polling (regular updates) and signal-based reactive updates:

- Regular updates: Gather data every frame, display every 0.1s
- Signal updates: React immediately to critical events (SNR critical, etc.)

## Testing

### Unit Tests

Unit tests are located in `tests/unit/test_hud.gd` and cover:

- HUD creation
- Element existence
- Display formatting
- Color coding logic
- Health bar scaling
- Visibility toggling

Run unit tests:

```bash
godot --headless --script tests/unit/test_hud.gd
```

### Integration Tests

Integration tests are located in `tests/integration/test_hud_integration.gd` and test:

- Integration with spacecraft
- Integration with signal manager
- Integration with time manager
- Real-time updates
- Scenario cycling

Run integration test by opening the scene in Godot:

```
tests/integration/test_hud_integration.tscn
```

## Troubleshooting

### HUD Not Visible

1. Check that HUD is added to scene tree
2. Verify position is in front of camera
3. Ensure `visible` property is true
4. Check that camera is rendering the layer

### Data Not Updating

1. Verify system references are set correctly
2. Check that signals are connected
3. Ensure update frequency is not too low
4. Verify game systems are updating

### Performance Issues

1. Reduce update frequency
2. Disable unused display elements
3. Check for excessive signal emissions
4. Profile with Godot's performance monitor

## Future Enhancements

Potential improvements for future versions:

1. **Customizable Layout**: Allow users to reposition HUD elements
2. **Additional Metrics**: Add more spacecraft statistics
3. **Animations**: Smooth transitions for value changes
4. **Warnings**: Pulsing effects for critical states
5. **Themes**: Different color schemes for accessibility
6. **Localization**: Support for multiple languages
7. **VR Comfort**: Adjustable distance and opacity
8. **Minimap**: Add navigation assistance

## Related Systems

- **Spacecraft** (`scripts/player/spacecraft.gd`): Provides velocity data
- **SignalManager** (`scripts/player/signal_manager.gd`): Provides SNR data
- **TimeManager** (`scripts/core/time_manager.gd`): Provides time data
- **RelativityManager** (`scripts/core/relativity.gd`): Provides light speed calculations
- **CelestialBody** (`scripts/celestial/celestial_body.gd`): Provides escape velocity data

## References

- Godot Label3D Documentation: https://docs.godotengine.org/en/stable/classes/class_label3d.html
- VR Best Practices: https://docs.godotengine.org/en/stable/tutorials/vr/index.html
- Project Resonance Design Document: `.kiro/specs/project-resonance/design.md`
- Project Resonance Requirements: `.kiro/specs/project-resonance/requirements.md`
