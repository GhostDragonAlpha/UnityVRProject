# Resonance Input Controller Guide

## Overview

The ResonanceInputController provides comprehensive VR controller input handling for the resonance system, enabling players to interact with objects through harmonic frequency manipulation in VR.

## Requirements Addressed

- **20.1**: Scan objects to determine harmonic frequency
- **20.2**: Emit matching frequency for constructive interference  
- **20.3**: Emit inverted frequency for destructive interference
- **20.4**: Calculate interference as sum of wave amplitudes
- **20.5**: Cancel objects through destructive interference
- **69.1-69.5**: Haptic feedback integration

## Features

### Controller Button Mappings

| Button | Action | Description |
|--------|--------|-------------|
| **Primary Trigger** (Index finger) | Scan object | Hold to scan object under crosshair/aim |
| **Secondary Trigger** (Middle finger/Grip) | Toggle mode | Switch between constructive/destructive interference |
| **A/X Button** | Emit frequency | Emit current frequency (based on mode) |
| **B/Y Button** | Quick-switch | Cycle through recently scanned frequencies |
| **Menu Button** | HUD toggle | Show/hide resonance HUD overlay |

### Hand Tracking Integration

- **Pinch gesture**: Scan objects (hold for 0.5 seconds)
- **Push gesture**: Emit frequency
- **Finger tracking**: Fine-grained control and aiming
- **Automatic fallback**: Works with or without hand tracking

### Haptic Feedback Patterns

| Action | Haptic Pattern | Intensity | Duration |
|--------|---------------|-----------|----------|
| Scan start | Light pulse | 0.4 | 0.1s |
| Scan complete | Medium pulse | 0.6 | 0.2s |
| Mode toggle | Light pulse | 0.4 | 0.1s |
| Constructive emission | Medium pulse | 0.6 | 0.5s |
| Destructive emission | Strong pulse | 0.8 | 0.5s |
| Quick-switch | Light pulse | 0.4 | 0.1s |
| Object cancellation | Strong pulse | 0.9 | 0.3s |

## Setup and Integration

### Basic Setup

```gdscript
# Add to your player scene
var resonance_input = preload("res://scenes/player/resonance_input_controller.tscn").instantiate()
add_child(resonance_input)

# Connect to resonance system
var resonance_system = $ResonanceSystem
resonance_input.set_resonance_system(resonance_system)

# Optional: Set dominant hand (default is RIGHT)
resonance_input.set_dominant_hand(ResonanceInputController.ControllerHand.LEFT)
```

### Signal Connections

```gdscript
# Connect to resonance input signals
resonance_input.object_scanned.connect(_on_object_scanned)
resonance_input.frequency_emitted.connect(_on_frequency_emitted)
resonance_input.mode_changed.connect(_on_mode_changed)
resonance_input.frequency_switched.connect(_on_frequency_switched)

func _on_object_scanned(object: Node3D, frequency: float):
    print("Scanned %s: %.2f Hz" % [object.name, frequency])
    # Update UI, play sound, etc.

func _on_frequency_emitted(frequency: float, mode: String):
    print("Emitting %.2f Hz (%s)" % [frequency, mode])
    # Show emission effects

func _on_mode_changed(mode: String):
    print("Mode changed to: %s" % mode)
    # Update UI indicator

func _on_frequency_switched(frequency: float):
    print("Switched to frequency: %.2f Hz" % frequency)
    # Update target indicator
```

## Input Configuration

### Customizing Button Mappings

```gdscript
# Change button mappings (optional)
resonance_input.scan_button = "trigger"           # Primary trigger
resonance_input.mode_toggle_button = "grip"       # Grip button
resonance_input.emit_button = "ax_button"         # A/X button
resonance_input.quick_switch_button = "by_button" # B/Y button
```

### Adjusting Input Settings

```gdscript
# Customize input behavior
resonance_input.scan_hold_time = 0.5        # Seconds to hold for scan
resonance_input.emission_cooldown = 0.2     # Seconds between emissions
resonance_input.max_recent_frequencies = 5  # Recent frequencies to remember
resonance_input.aim_assist_distance = 10.0  # Max targeting distance
resonance_input.aim_assist_angle = 15.0     # Aim assist cone angle
```

## Usage Examples

### Basic Resonance Interaction

```gdscript
# Player aims at object and holds trigger to scan
# System determines object frequency and stores it

# Player presses A/X to emit frequency
# If in constructive mode: amplifies object
# If in destructive mode: cancels object

# Player presses grip to toggle between modes
# Player presses B/Y to cycle recent frequencies
```

### Advanced Integration with UI

```gdscript
# Update UI when object is scanned
resonance_input.object_scanned.connect(_on_object_scanned)

func _on_object_scanned(object: Node3D, frequency: float):
    # Show scanned object info
    ui.show_scanned_object(object, frequency)
    
    # Highlight object in world
    object.set_outline_enabled(true)
    
    # Play scan complete sound
    audio.play_scan_sound()

# Update mode indicator
resonance_input.mode_changed.connect(_on_mode_changed)

func _on_mode_changed(mode: String):
    ui.set_mode_indicator(mode)
    
    # Change reticle color
    if mode == "constructive":
        reticle.set_color(Color.GREEN)
    else:
        reticle.set_color(Color.RED)
```

### Hand Tracking Integration

```gdscript
# Hand tracking is automatically detected and used
# Pinch gesture: Hold for 0.5s to scan
# Push gesture: Emit frequency

# Check if hand tracking is active
if resonance_input.hand_tracking_active:
    print("Using hand tracking")
else:
    print("Using controller input")
```

## State Management

### Current State Access

```gdscript
# Get current input state
var state = resonance_input.get_input_state()

print("Mode: ", state.current_mode)
print("Scanning: ", state.is_scanning)
print("Target: ", state.current_target)
print("Recent frequencies: ", state.recent_frequencies)
print("HUD visible: ", state.hud_visible)
```

### Managing Recent Frequencies

```gdscript
# Get recent frequencies
var recent = resonance_input.get_recent_frequencies()

# Clear recent frequencies
resonance_input.clear_recent_frequencies()

# Recent frequencies are automatically managed during scanning
# Most recent scans appear first in the list
```

## HUD Overlay

### Showing Resonance HUD

```gdscript
# Show/hide resonance HUD
resonance_input.set_hud_overlay_visible(true)

# Check if HUD is visible
if resonance_input.is_hud_overlay_visible():
    # Update HUD elements
    update_resonance_hud()
```

### HUD Elements

The resonance HUD typically includes:
- Current target object name
- Target frequency
- Current mode (constructive/destructive)
- Recent frequencies list
- Aim reticle with mode indicator

## Error Handling

### Checking System Availability

```gdscript
# Check if required systems are available
if resonance_input.resonance_system == null:
    print("Warning: Resonance system not found")

if resonance_input.vr_manager == null:
    print("Warning: VR manager not found")

if resonance_input.haptic_manager == null:
    print("Warning: Haptic manager not found")
```

### Handling Invalid Objects

```gdscript
# System automatically handles invalid objects
# When target object is destroyed, system will:
# - Clear current target
# - Continue with other recent frequencies
# - Log appropriate warnings
```

## Performance Considerations

- Input processing runs every frame with minimal overhead
- Raycasting uses efficient collision detection
- Haptic feedback uses cached intensity values
- State management uses dictionaries for fast lookups
- Recent frequencies list is size-limited

## Troubleshooting

### Input Not Responding

1. **Check VR manager**: Ensure VR manager is initialized and active
2. **Verify controller state**: Check if controllers are tracked and buttons are mapped
3. **Debug input state**: Use `get_input_state()` to check current state
4. **Check logs**: Look for error messages about missing systems

### Scanning Not Working

1. **Verify raycast**: Check if `_aim_raycast` is positioned correctly
2. **Check collision layers**: Ensure objects are on correct collision layers
3. **Verify distance**: Objects must be within `aim_assist_distance`
4. **Check hold time**: Ensure trigger is held for full `scan_hold_time`

### Haptic Feedback Not Working

1. **Check haptic manager**: Ensure HapticManager is initialized
2. **Verify VR mode**: Haptics only work in VR mode
3. **Check controller connection**: Ensure controllers are connected and tracked
4. **Test with other haptics**: Verify other haptic feedback works

## Integration with Existing Systems

### Resonance System Integration

```gdscript
# The input controller automatically integrates with ResonanceSystem
# All scanning and emission goes through the resonance system

# Access the resonance system directly if needed
var resonance_system = resonance_input.resonance_system

// Get tracked objects
var tracked_objects = resonance_system.get_tracked_objects()

// Get object amplitude
var amplitude = resonance_system.get_object_amplitude(object)
```

### Haptic Manager Integration

```gdscript
// Haptic feedback is automatically triggered
// Custom haptic patterns can be added:

func _on_object_cancelled(object):
    // Strong haptic for object cancellation
    resonance_input._trigger_haptic("both", 
        HapticManager.HapticIntensity.VERY_STRONG, 
        HapticManager.DURATION_MEDIUM)
```

## Best Practices

1. **Always check system availability** before using advanced features
2. **Connect to signals** for UI updates rather than polling
3. **Use recent frequencies** for quick-switching between targets
4. **Provide visual feedback** for all resonance actions
5. **Test with both controllers** and hand tracking when available
6. **Handle edge cases** like destroyed objects gracefully
7. **Log important events** for debugging and player feedback

## Example: Complete Integration

```gdscript
extends Node3D

var resonance_input: ResonanceInputController
var resonance_system: ResonanceSystem
var ui: ResonanceUI
var audio: AudioManager

func _ready():
    # Setup systems
    setup_resonance_system()
    setup_resonance_input()
    setup_ui()
    setup_audio()

func setup_resonance_system():
    resonance_system = ResonanceSystem.new()
    add_child(resonance_system)

func setup_resonance_input():
    var scene = preload("res://scenes/player/resonance_input_controller.tscn")
    resonance_input = scene.instantiate()
    add_child(resonance_input)
    
    # Configure
    resonance_input.set_resonance_system(resonance_system)
    resonance_input.set_dominant_hand(ResonanceInputController.ControllerHand.RIGHT)
    
    # Connect signals
    resonance_input.object_scanned.connect(_on_object_scanned)
    resonance_input.frequency_emitted.connect(_on_frequency_emitted)
    resonance_input.mode_changed.connect(_on_mode_changed)
    resonance_input.frequency_switched.connect(_on_frequency_switched)

func setup_ui():
    ui = $ResonanceUI
    resonance_input.set_hud_overlay_visible(true)

func setup_audio():
    audio = $AudioManager

func _on_object_scanned(object, frequency):
    ui.show_scanned_object(object, frequency)
    audio.play_scan_sound()
    update_reticle()

func _on_frequency_emitted(frequency, mode):
    ui.show_emission_indicator(frequency, mode)
    audio.play_emission_sound(mode)

func _on_mode_changed(mode):
    ui.set_mode_indicator(mode)
    update_reticle()

func _on_frequency_switched(frequency):
    ui.show_frequency_switch(frequency)
    audio.play_switch_sound()

func update_reticle():
    var mode = resonance_input.get_current_mode()
    var color = Color.GREEN if mode == ResonanceInputController.ResonanceMode.CONSTRUCTIVE else Color.RED
    ui.set_reticle_color(color)

func _process(delta):
    # Update UI elements
    if resonance_input.is_hud_overlay_visible():
        update_resonance_hud()

func update_resonance_hud():
    var target = resonance_input.get_current_target()
    var recent = resonance_input.get_recent_frequencies()
    ui.update_hud(target, recent)
```

This comprehensive guide covers all aspects of the ResonanceInputController system. For additional questions or troubleshooting, refer to the main project documentation or examine the example scenes.