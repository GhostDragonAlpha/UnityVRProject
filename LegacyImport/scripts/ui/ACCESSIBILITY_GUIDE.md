# AccessibilityManager Guide

## Overview

The AccessibilityManager provides comprehensive accessibility features to make Project Resonance playable for users with various accessibility needs. It implements colorblind modes, subtitles, control remapping, and motion sensitivity reduction.

## Requirements Coverage

- **Requirement 70.1**: Colorblind mode options (Protanopia, Deuteranopia, Tritanopia)
- **Requirement 70.2**: UI color adjustments when colorblind mode is enabled
- **Requirement 70.3**: Subtitles for audio cues
- **Requirement 70.4**: Complete control remapping using InputMap
- **Requirement 70.5**: Reduced motion effects when sensitivity mode is enabled

## Features

### 1. Colorblind Modes

The system supports four colorblind modes:

- **None**: Default colors (no transformation)
- **Protanopia**: Red-blind (difficulty distinguishing red from green)
- **Deuteranopia**: Green-blind (difficulty distinguishing red from green)
- **Tritanopia**: Blue-blind (difficulty distinguishing blue from yellow)

#### Color Transformation

Each colorblind mode uses a scientifically-based transformation matrix (Brettel, Viénot and Mollon CVPR 1997) to adjust colors throughout the UI:

```gdscript
# Set colorblind mode
accessibility_manager.set_colorblind_mode(AccessibilityManager.ColorblindMode.PROTANOPIA)

# Or use string
accessibility_manager.set_colorblind_mode_from_string("Protanopia")

# Get current mode
var mode = accessibility_manager.get_colorblind_mode_string()
```

#### Affected UI Elements

When a colorblind mode is active, the following UI elements are adjusted:

- HUD color indicators (velocity, SNR, warnings)
- Menu system colors
- Warning indicators
- Status displays

### 2. Subtitles

Subtitles display text for audio cues and spoken content, making the game accessible to deaf and hard-of-hearing players.

#### Enabling Subtitles

```gdscript
# Enable subtitles
accessibility_manager.set_subtitles_enabled(true)

# Check if enabled
if accessibility_manager.are_subtitles_enabled():
    print("Subtitles are on")
```

#### Displaying Subtitles

```gdscript
# Display a subtitle for 3 seconds (default)
accessibility_manager.display_subtitle("Engine thrust engaged")

# Display with custom duration
accessibility_manager.display_subtitle("Warning: Low signal strength", 5.0)

# Hide subtitle manually
accessibility_manager.hide_subtitle()
```

#### Subtitle Appearance

- Semi-transparent black background with white border
- White text with black outline for readability
- Centered at bottom of screen (80% down)
- Automatic word wrapping
- Auto-hide after specified duration

### 3. Control Remapping

Complete control remapping allows players to customize all input bindings to their preferences or accessibility needs.

#### Remapping Controls

```gdscript
# Create a new input event
var new_event = InputEventKey.new()
new_event.keycode = KEY_SPACE

# Remap an action
accessibility_manager.remap_control("jump", new_event)

# Get current mapping
var events = accessibility_manager.get_control_mapping("jump")
for event in events:
    print("Mapped to: ", event)

# Reset a single mapping
accessibility_manager.reset_control_mapping("jump")

# Reset all mappings
accessibility_manager.reset_all_control_mappings()

# Get all available actions
var actions = accessibility_manager.get_all_actions()
```

#### Integration with InputMap

The AccessibilityManager directly modifies Godot's InputMap, so all remapped controls work immediately throughout the game without requiring code changes.

### 4. Motion Sensitivity Reduction

Reduces camera shake, visual effects, and animations to prevent motion sickness or discomfort.

#### Enabling Motion Reduction

```gdscript
# Enable reduced motion
accessibility_manager.set_motion_sensitivity_reduced(true)

# Check if enabled
if accessibility_manager.is_motion_sensitivity_reduced():
    print("Motion sensitivity is reduced")
```

#### Affected Systems

When motion sensitivity reduction is enabled:

- **Camera shake**: Reduced to 30% intensity
- **Post-processing effects**: Reduced to 50% intensity
- **Lattice animations**: Reduced to 50% speed
- **Screen shake effects**: Minimized
- **Rapid camera movements**: Smoothed

## Integration with SettingsManager

The AccessibilityManager automatically integrates with SettingsManager for persistence:

```gdscript
# Settings are automatically saved when changed
accessibility_manager.set_colorblind_mode_from_string("Deuteranopia")
# ^ This automatically calls settings_manager.set_colorblind_mode()

# Settings are automatically loaded on startup
# The AccessibilityManager reads from SettingsManager in _ready()
```

## Signals

The AccessibilityManager emits signals for reactive updates:

```gdscript
# Connect to signals
accessibility_manager.colorblind_mode_changed.connect(_on_colorblind_changed)
accessibility_manager.subtitles_toggled.connect(_on_subtitles_toggled)
accessibility_manager.subtitle_displayed.connect(_on_subtitle_shown)
accessibility_manager.control_remapped.connect(_on_control_remapped)
accessibility_manager.motion_sensitivity_changed.connect(_on_motion_changed)

func _on_colorblind_changed(mode: String):
    print("Colorblind mode changed to: ", mode)

func _on_subtitles_toggled(enabled: bool):
    print("Subtitles: ", "enabled" if enabled else "disabled")

func _on_subtitle_shown(text: String, duration: float):
    print("Showing subtitle: ", text)

func _on_control_remapped(action: String, event: InputEvent):
    print("Remapped ", action, " to ", event)

func _on_motion_changed(reduced: bool):
    print("Motion sensitivity: ", "reduced" if reduced else "normal")
```

## Usage Examples

### Example 1: Settings Menu Integration

```gdscript
# In your settings menu
func _on_colorblind_option_selected(index: int):
    var modes = ["None", "Protanopia", "Deuteranopia", "Tritanopia"]
    accessibility_manager.set_colorblind_mode_from_string(modes[index])

func _on_subtitles_checkbox_toggled(enabled: bool):
    accessibility_manager.set_subtitles_enabled(enabled)

func _on_motion_checkbox_toggled(reduced: bool):
    accessibility_manager.set_motion_sensitivity_reduced(reduced)
```

### Example 2: Audio Cue with Subtitle

```gdscript
# When playing an audio cue, also show subtitle
func play_warning_sound():
    audio_manager.play_sound("warning_beep")

    # Show subtitle if enabled
    if accessibility_manager.are_subtitles_enabled():
        accessibility_manager.display_subtitle("[Warning Beep]", 2.0)
```

### Example 3: Control Remapping UI

```gdscript
# In control settings UI
func _on_remap_button_pressed(action: String):
    # Wait for player input
    var event = await get_next_input_event()

    # Remap the control
    accessibility_manager.remap_control(action, event)

    # Update UI to show new binding
    update_control_display(action)
```

### Example 4: Getting Accessibility Status

```gdscript
# Get complete accessibility status
var status = accessibility_manager.get_accessibility_status()
print("Colorblind Mode: ", status.colorblind_mode)
print("Subtitles: ", status.subtitles_enabled)
print("Motion Reduction: ", status.motion_sensitivity_reduced)
```

## Testing

### Unit Tests

Run the unit tests to verify functionality:

```bash
# Using Python test runner (requires Godot server running)
python tests/run_accessibility_test.py

# Or directly in Godot
godot --headless --script tests/unit/test_accessibility_manager.gd
```

### Manual Testing Checklist

1. **Colorblind Modes**:

   - [ ] Switch between all colorblind modes
   - [ ] Verify HUD colors change appropriately
   - [ ] Verify menu colors change appropriately
   - [ ] Verify warning colors remain distinguishable

2. **Subtitles**:

   - [ ] Enable subtitles in settings
   - [ ] Trigger various audio cues
   - [ ] Verify subtitles appear and auto-hide
   - [ ] Verify subtitle text is readable
   - [ ] Verify subtitle timing is appropriate

3. **Control Remapping**:

   - [ ] Remap a control action
   - [ ] Verify new binding works in-game
   - [ ] Verify old binding no longer works
   - [ ] Reset controls to defaults
   - [ ] Verify defaults are restored

4. **Motion Sensitivity**:
   - [ ] Enable motion sensitivity reduction
   - [ ] Trigger camera shake events
   - [ ] Verify shake is reduced
   - [ ] Verify post-processing is reduced
   - [ ] Verify animations are slower

## Architecture

### Class Structure

```
AccessibilityManager (Node)
├── Colorblind Mode System
│   ├── Mode enum (NONE, PROTANOPIA, DEUTERANOPIA, TRITANOPIA)
│   ├── Transformation matrices
│   └── Color adjustment methods
├── Subtitle System
│   ├── Subtitle UI (Control, Label, Timer)
│   └── Display/hide methods
├── Control Remapping System
│   ├── InputMap integration
│   └── Mapping storage
└── Motion Sensitivity System
    └── Effect intensity adjustments
```

### Dependencies

- **SettingsManager**: For persistence
- **HUD**: For color adjustments
- **MenuSystem**: For color adjustments
- **ResonanceEngine**: For motion effect adjustments
- **InputMap**: For control remapping

## Best Practices

1. **Always check if subtitles are enabled** before displaying them
2. **Use descriptive subtitle text** that conveys the audio information
3. **Test colorblind modes** with actual colorblind users if possible
4. **Provide clear feedback** when controls are remapped
5. **Document all remappable actions** in the game's help system
6. **Test motion reduction** with users prone to motion sickness
7. **Save accessibility settings** immediately when changed
8. **Load accessibility settings** early in the startup sequence

## Future Enhancements

Potential future improvements:

- **Font size adjustment** for subtitles
- **High contrast mode** for better visibility
- **Screen reader support** for blind users
- **Customizable subtitle position** and appearance
- **Audio description** for visual elements
- **One-handed control schemes**
- **Adjustable UI scale**
- **Color customization** beyond colorblind modes

## References

- Brettel, H., Viénot, F., & Mollon, J. D. (1997). Computerized simulation of color appearance for dichromats. _Journal of the Optical Society of America A_, 14(10), 2647-2655.
- Web Content Accessibility Guidelines (WCAG) 2.1
- Game Accessibility Guidelines (http://gameaccessibilityguidelines.com/)
