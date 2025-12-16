# Warning System Guide

## Overview

The WarningSystem provides audio and visual warnings for dangerous situations in Project Resonance. It monitors spacecraft state, signal strength, entropy levels, and collision courses to alert the player before critical failures occur.

## Requirements Implemented

### Requirement 42.1: Gravity Well Warnings

- Displays red warning indicator when approaching gravity wells too fast
- Plays alert sound when danger is detected
- Calculates severity based on distance and velocity
- Shows escape velocity information

### Requirement 42.2: SNR Critical Warnings

- Triggers when signal strength drops below 25%
- Pulses HUD red to indicate critical signal loss
- Plays degrading audio tone that worsens with severity
- Updates in real-time as SNR changes

### Requirement 42.3: Collision Warnings

- Performs raycast ahead of spacecraft to detect obstacles
- Calculates time to impact
- Displays proximity warning with countdown
- Shows object name and distance

### Requirement 42.4: System Failure Warnings

- Monitors entropy levels
- Triggers critical warning when entropy exceeds 75%
- Indicates imminent system failure
- Severity increases with entropy level

### Requirement 42.5: Resolution Instructions

- Every warning provides clear, actionable instructions
- Instructions are specific to the danger type
- Displayed in easy-to-read format below warning message

## Architecture

```
WarningSystem (Node3D)
├── Warning Checks (per frame)
│   ├── Gravity danger check
│   ├── SNR critical check
│   ├── Collision course check
│   └── System failure check
├── Visual Elements
│   ├── Warning indicator (flashing red panel)
│   ├── Warning message label
│   └── Resolution instructions label
├── Audio System
│   └── Alert sound player
└── Integration
    ├── Spacecraft reference
    ├── SignalManager reference
    ├── PhysicsEngine reference
    └── HUD reference (for pulsing)
```

## Warning Types

### WarningType Enum

```gdscript
enum WarningType {
    NONE,
    GRAVITY_DANGER,      # Approaching gravity well too fast
    SNR_CRITICAL,        # Signal strength below 25%
    COLLISION_WARNING,   # On collision course
    SYSTEM_FAILURE       # Entropy exceeds 75%
}
```

## Usage

### Basic Setup

```gdscript
# Create warning system
var warning_system = WarningSystem.new()
add_child(warning_system)

# Set references
warning_system.set_spacecraft(spacecraft)
warning_system.set_signal_manager(signal_manager)
warning_system.set_physics_engine(physics_engine)
warning_system.set_hud(hud)
```

### Checking Active Warnings

```gdscript
# Check if any warnings are active
if warning_system.has_active_warnings():
    var active = warning_system.get_active_warnings()
    for warning_type in active:
        var info = warning_system.get_warning_info(warning_type)
        print("Warning: %s" % info.message)
        print("Resolution: %s" % info.resolution)
        print("Severity: %.2f" % info.severity)
```

### Listening to Warning Signals

```gdscript
# Connect to warning signals
warning_system.warning_triggered.connect(_on_warning_triggered)
warning_system.warning_cleared.connect(_on_warning_cleared)
warning_system.warning_severity_changed.connect(_on_severity_changed)

func _on_warning_triggered(warning_type: WarningType, severity: float):
    print("Warning triggered: %d with severity %.2f" % [warning_type, severity])

func _on_warning_cleared(warning_type: WarningType):
    print("Warning cleared: %d" % warning_type)

func _on_severity_changed(warning_type: WarningType, severity: float):
    print("Warning severity changed: %d to %.2f" % [warning_type, severity])
```

### Manual Warning Control

```gdscript
# Clear all warnings
warning_system.clear_all_warnings()

# Enable/disable warning system
warning_system.set_enabled(false)  # Disable
warning_system.set_enabled(true)   # Enable
```

## Configuration

### Thresholds

```gdscript
# Gravity warning thresholds
warning_system.gravity_danger_distance = 500.0  # Distance in units
warning_system.gravity_danger_velocity = 100.0  # Velocity in m/s

# Collision warning time
warning_system.collision_warning_time = 5.0  # Seconds ahead to check

# Visual pulse frequency
warning_system.pulse_frequency = 2.0  # Hz

# Audio volume
warning_system.alert_volume_db = -10.0  # dB
```

### Position and Scale

```gdscript
# Position offset from camera
warning_system.warning_offset = Vector3(0, 0.5, -1.5)

# Scale of warning UI
warning_system.warning_scale = 0.6
```

## Warning Messages and Resolutions

### Gravity Danger

- **Message**: "WARNING: DANGEROUS GRAVITY APPROACH"
- **Resolution**: "Reduce velocity or change course to avoid capture\nEscape velocity: [value] m/s"

### SNR Critical

- **Message**: "CRITICAL: SIGNAL COHERENCE FAILING"
- **Resolution**: "Move closer to star nodes to regenerate signal\nAvoid damage sources"

### Collision Warning

- **Message**: "COLLISION WARNING: [time] SECONDS"
- **Resolution**: "Change course immediately or reduce velocity\nObject: [name]"

### System Failure

- **Message**: "CRITICAL: SYSTEM FAILURE IMMINENT"
- **Resolution**: "Entropy at critical levels - seek repair immediately\nAvoid further damage"

## Visual Effects

### Warning Indicator

- Flashing red panel that pulses at configured frequency
- Intensity increases with warning severity
- Emission glow effect for visibility

### Warning Labels

- Large, bold text for warning messages
- Color-coded based on severity (red for critical)
- Pulsing effect synchronized with indicator

### HUD Pulsing (SNR Critical)

- When SNR drops below 25%, the entire HUD pulses red
- Pulse intensity matches warning severity
- Provides immediate visual feedback

## Audio System

### Alert Sounds

Each warning type has a distinct alert sound:

- **Gravity**: Low-frequency warning tone
- **SNR Critical**: Degrading tone that worsens with severity
- **Collision**: Sharp, urgent beeping
- **System Failure**: Critical alarm sound

### Audio Degradation

For SNR warnings, the audio tone degrades as signal strength decreases:

- Pitch lowers with severity
- Introduces distortion and artifacts
- Simulates information loss

## Integration with Other Systems

### Signal Manager Integration

```gdscript
# Warning system listens to signal manager signals
signal_manager.signal_critical.connect(_on_signal_critical)
signal_manager.entropy_changed.connect(_on_entropy_changed)

# Automatically triggers warnings based on SNR and entropy
```

### Spacecraft Integration

```gdscript
# Warning system monitors spacecraft state
spacecraft.collision_occurred.connect(_on_collision_occurred)

# Checks velocity and position for gravity warnings
# Performs raycasts for collision detection
```

### Physics Engine Integration

```gdscript
# Gets nearest celestial body for gravity calculations
var nearest_body = physics_engine.get_nearest_celestial_body()

# Calculates escape velocity at current position
var escape_velocity = nearest_body.get_escape_velocity_at_point(position)
```

## Performance Considerations

### Update Frequency

- Warning checks run every frame in `_process()`
- Collision raycasts are performed only when moving
- Visual updates are synchronized with pulse timer

### Optimization

- Warnings are only checked when relevant (e.g., collision only when moving)
- Inactive warnings don't consume resources
- Audio is only played when warnings are first triggered

## Testing

### Unit Tests

Located in `tests/unit/test_warning_system.gd`:

- Tests each warning type triggers correctly
- Verifies thresholds are respected
- Checks resolution instructions are provided
- Tests warning clearing behavior

### Integration Tests

Located in `tests/integration/test_warning_system_integration.gd`:

- Tests integration with SignalManager
- Tests integration with Spacecraft
- Tests integration with PhysicsEngine
- Verifies end-to-end warning flow

## Troubleshooting

### Warnings Not Appearing

1. Check that references are set correctly:

   ```gdscript
   warning_system.set_spacecraft(spacecraft)
   warning_system.set_signal_manager(signal_manager)
   warning_system.set_physics_engine(physics_engine)
   ```

2. Verify warning system is enabled:

   ```gdscript
   warning_system.set_enabled(true)
   ```

3. Check that conditions actually trigger warnings:
   ```gdscript
   print("SNR: ", signal_manager.get_snr_percentage())
   print("Entropy: ", signal_manager.get_entropy())
   ```

### Audio Not Playing

1. Check audio player exists:

   ```gdscript
   print("Audio player: ", warning_system.audio_player)
   ```

2. Verify volume is not muted:
   ```gdscript
   warning_system.alert_volume_db = -10.0  # Audible level
   ```

### HUD Not Pulsing

1. Ensure HUD reference is set:

   ```gdscript
   warning_system.set_hud(hud)
   ```

2. Check that HUD has `set_warning_tint()` method:
   ```gdscript
   if hud.has_method("set_warning_tint"):
       print("HUD supports warning tint")
   ```

## Future Enhancements

### Planned Features

- Customizable warning thresholds per difficulty level
- Warning history log for debugging
- Visual trajectory prediction for collision warnings
- Haptic feedback integration for VR controllers
- Localization support for warning messages

### Extensibility

To add new warning types:

1. Add to WarningType enum:

   ```gdscript
   enum WarningType {
       # ... existing types
       NEW_WARNING_TYPE
   }
   ```

2. Create check function:

   ```gdscript
   func _check_new_warning() -> void:
       # Check conditions
       if dangerous_condition:
           _trigger_warning(
               WarningType.NEW_WARNING_TYPE,
               "WARNING MESSAGE",
               "Resolution instructions",
               severity
           )
       else:
           _clear_warning(WarningType.NEW_WARNING_TYPE)
   ```

3. Call in `_process()`:

   ```gdscript
   func _process(delta: float) -> void:
       # ... existing checks
       _check_new_warning()
   ```

4. Add audio alert:
   ```gdscript
   func _play_alert_sound(type: WarningType, severity: float) -> void:
       match type:
           # ... existing cases
           WarningType.NEW_WARNING_TYPE:
               _play_new_warning_alert(severity)
   ```

## API Reference

### Public Methods

#### set_spacecraft(craft: Spacecraft)

Set the spacecraft reference for monitoring.

#### set_signal_manager(manager: SignalManager)

Set the signal manager reference for SNR and entropy monitoring.

#### set_physics_engine(engine: PhysicsEngine)

Set the physics engine reference for gravity and collision detection.

#### set_hud(hud_ref: HUD)

Set the HUD reference for pulsing effects.

#### has_active_warnings() -> bool

Check if any warnings are currently active.

#### get_active_warnings() -> Array

Get list of all active warning types.

#### get_warning_info(type: WarningType) -> Dictionary

Get detailed information about a specific warning.

#### clear_all_warnings()

Clear all active warnings.

#### set_enabled(enabled: bool)

Enable or disable the warning system.

### Signals

#### warning_triggered(warning_type: WarningType, severity: float)

Emitted when a new warning is triggered.

#### warning_cleared(warning_type: WarningType)

Emitted when a warning is cleared.

#### warning_severity_changed(warning_type: WarningType, severity: float)

Emitted when warning severity changes.

## See Also

- [HUD Guide](HUD_GUIDE.md) - HUD system documentation
- [Signal Manager](../player/signal_manager.gd) - SNR and entropy management
- [Spacecraft](../player/spacecraft.gd) - Spacecraft physics and controls
- [Physics Engine](../core/physics_engine.gd) - Physics simulation
