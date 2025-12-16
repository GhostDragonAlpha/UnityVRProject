# Controller Button Remapping System Guide

## Overview

The Controller Button Remapping System provides **unified button name mapping across different VR controller types** (Meta/Oculus Touch, Valve Index, HTC Vive, generic). This ensures your VR code works seamlessly on any controller hardware without hardcoding hardware-specific button names.

## Problem Solved

Different VR controller manufacturers use different button names:

| Action | Meta/Oculus | Valve Index | HTC Vive |
|--------|------------|------------|----------|
| Primary button | `ax_button` | `a_button` | (limited) |
| Secondary button | `by_button` | `b_button` | (limited) |
| Grip | `grip` | `grip_click` | `grip_click` |
| Menu | `menu_button` | `system` | `menu_button` |

**Before remapping**, your code had to do this:
```gdscript
if controller.is_button_pressed("ax_button"):  # Only works on Meta!
    interact()
```

**After remapping**, use semantic action names:
```gdscript
if remapper.is_action_pressed("interact", controller):  # Works on ALL controllers!
    interact()
```

## Architecture

### Components

1. **ControllerButtonRemapper** (`scripts/core/controller_button_remapper.gd`)
   - Maintains button name mappings
   - Detects controller type at runtime
   - Maps semantic actions to hardware buttons
   - Manages custom mappings and persistence

2. **VRManager Integration**
   - Instantiates and initializes the remapper
   - Emits signals with semantic action names
   - Provides access to remapper for gameplay systems

3. **SettingsManager Integration**
   - Persists controller type preference
   - Stores custom button remappings
   - Loads saved preferences on startup

### Data Flow

```
Hardware Button Press
    ↓
XRController3D.button_pressed signal
    ↓
VRManager._on_controller_button_pressed()
    ↓
ControllerButtonRemapper._reverse_map_button_name()
    ↓
Semantic Action Name (e.g., "interact")
    ↓
VRManager.controller_button_pressed.emit(hand, action_name)
    ↓
Gameplay Systems (listen to semantic actions)
```

## Semantic Actions

The remapper defines these semantic action names:

| Action | Description | Examples |
|--------|-------------|----------|
| `interact` | Primary interaction/confirmation | Scan, select, pick up |
| `menu_action` | Secondary action/cancellation | Cancel, deselect |
| `grab` | Grip/grab objects | Hold items, climbing |
| `menu` | Pause/system menu | Open settings, pause game |
| `thumbstick_click` | Thumbstick press | Sprint, boost |
| `touchpad` | Touchpad click | Alternative input |
| `grab_alt` | Alternative grip button | Secondary grab |

## Integration Steps

### Step 1: Update VRManager Initialization

In `scripts/core/vr_manager.gd`, add to `_ready()`:

```gdscript
func _ready() -> void:
    _load_deadzone_settings()
    _init_button_remapper()  # Add this line

func _init_button_remapper() -> void:
    button_remapper = ControllerButtonRemapper.new()
    button_remapper.name = "ControllerButtonRemapper"
    add_child(button_remapper)
    _log_info("Button remapping system initialized")
```

### Step 2: Add Remapper Member Variable

```gdscript
# Add to VRManager class members
var button_remapper: ControllerButtonRemapper = null
```

### Step 3: Update Button State Tracking

Replace hardcoded button checks in `_update_controller_state()`:

```gdscript
# OLD - Hardcoded button names (only works on Meta)
state["button_ax"] = controller.is_button_pressed("ax_button")
state["button_by"] = controller.is_button_pressed("by_button")

# NEW - Uses semantic actions (works on ALL controllers)
if button_remapper:
    state["interact"] = button_remapper.is_action_pressed("interact", controller)
    state["menu_action"] = button_remapper.is_action_pressed("menu_action", controller)
    state["grab"] = button_remapper.is_action_pressed("grab", controller)
```

### Step 4: Update Signal Handlers

Convert hardware button names to semantic actions:

```gdscript
func _on_controller_button_pressed(button_name: String, hand: String) -> void:
    var action_name = _reverse_map_button_name(button_name)
    controller_button_pressed.emit(hand, action_name)  # Emit semantic action

func _reverse_map_button_name(hardware_button: String) -> String:
    if not button_remapper:
        return hardware_button
    for action_name in button_remapper.button_remapping.keys():
        if button_remapper.map_button_name(action_name) == hardware_button:
            return action_name
    return hardware_button
```

### Step 5: Update SettingsManager

Add VR settings to `scripts/core/settings_manager.gd`:

```gdscript
var defaults: Dictionary = {
    "vr": {
        "enabled": true,
        "controller_type": "generic",  # Auto-detected, can be: meta, valve, htc
        "button_remappings": {}  # Custom remappings
    }
}
```

## Usage Examples

### Pattern 1: Listen to Signals (Recommended)

```gdscript
# In your gameplay script
func _ready():
    var vr_manager = ResonanceEngine.get_vr_manager()
    vr_manager.controller_button_pressed.connect(_on_action_pressed)

func _on_action_pressed(hand: String, action: String):
    match action:
        "interact":
            player.interact()
        "grab":
            player.grab()
        "menu":
            show_pause_menu()
```

**Advantages:**
- Decoupled from button input
- Works with any controller
- Easy to test with simulated actions

### Pattern 2: Poll Current State

```gdscript
# In your _process() function
func _process(delta):
    var vr_manager = ResonanceEngine.get_vr_manager()
    var remapper = vr_manager.button_remapper
    var right_controller = vr_manager.get_controller("right")

    if remapper.is_action_pressed("interact", right_controller):
        # Perform action each frame while button is held
        player.continue_interaction()
```

**When to use:**
- Continuous input (holding button)
- State-dependent behavior
- Analog stick input

### Pattern 3: Custom Remapping

```gdscript
# Let player customize button mappings
func remap_button(action_name: String, new_buttons: Array):
    var remapper = ResonanceEngine.get_vr_manager().button_remapper
    remapper.set_custom_mapping(action_name, new_buttons)
    # Automatically saves to SettingsManager
```

## Real-World Examples

### Terrain Tool (Planetary Survival)

**Before:**
```gdscript
if right_controller.is_button_pressed("ax_button"):  # Only Meta!
    activate_terrain_tool()
```

**After:**
```gdscript
if vr_manager.button_remapper.is_action_pressed("interact", right_controller):
    activate_terrain_tool()  # Works on all controllers!
```

### Crafting UI

**Before:**
```gdscript
var trigger = controller.is_button_pressed("trigger_click")
var grip = controller.is_button_pressed("grip_click")
```

**After:**
```gdscript
var confirm = remapper.is_action_pressed("interact", controller)
var grab = remapper.is_action_pressed("grab", controller)
```

### Spacecraft Controls

**Before:**
```gdscript
if controller.is_button_pressed("menu_button"):  # Non-standard on Valve
    open_menu()
```

**After:**
```gdscript
if remapper.is_action_pressed("menu", controller):
    open_menu()  # Works everywhere!
```

## Controller Type Detection

The remapper auto-detects controller type at startup by checking available buttons:

```gdscript
var remapper = vr_manager.button_remapper

# Check detected type
if remapper.current_controller_type == "valve":
    print("Using Valve Index controllers")

# Get profile info
var profile = remapper.get_controller_profile_info()
print("Available buttons: ", profile.buttons)
```

### Supported Controllers

| Type | Controllers | Auto-Detection |
|------|-------------|-----------------|
| `meta` | Quest 2/3, Rift S, Pro | Checks for ax_button, by_button |
| `valve` | Index, Base Stations | Checks for a_button, b_button |
| `htc` | Vive, Focus | Checks for touchpad_click |
| `generic` | Unknown/Fallback | Default if no match |

## Testing the System

### Unit Tests

```gdscript
# Test basic mapping
var remapper = ControllerButtonRemapper.new()
remapper.add_child(remapper)

# Test action mapping
var interact_button = remapper.map_button_name("interact")
assert(!interact_button.is_empty(), "Should map interact action")

# Test controller type detection
remapper.set_controller_type("valve")
assert(remapper.current_controller_type == "valve")

# Test custom mapping
remapper.set_custom_mapping("interact", ["a_button", "ax_button"])
assert(remapper.button_remapping["interact"]["button_names"] == ["a_button", "ax_button"])
```

### Integration Tests

```gdscript
# Test with actual VR input
func test_button_remapping_integration():
    var vr_manager = ResonanceEngine.get_vr_manager()
    assert(vr_manager.button_remapper != null, "Remapper should be initialized")

    var right_controller = vr_manager.get_controller("right")
    if right_controller:
        # Should work without errors
        var is_interact = vr_manager.button_remapper.is_action_pressed("interact", right_controller)
        print("Interact pressed: ", is_interact)
```

### Manual Testing Checklist

- [ ] Test on Meta Quest 2/3 controllers
- [ ] Test on Valve Index controllers
- [ ] Test on HTC Vive controllers
- [ ] Test on generic/unsupported controller
- [ ] Test custom button remapping
- [ ] Test settings persistence
- [ ] Test controller type auto-detection
- [ ] Test all semantic actions (interact, grab, menu, etc.)
- [ ] Test fallback behavior with missing buttons
- [ ] Test signal emission with semantic names

## Troubleshooting

### Issue: Remapper returns empty string for action

**Cause:** Button not available on this controller type

**Solution:**
1. Check controller type: `print(remapper.current_controller_type)`
2. Check available buttons: `print(remapper.get_controller_profile_info())`
3. Add fallback button to mapping or override with custom mapping

### Issue: Settings not persisting

**Cause:** SettingsManager not found or saving not called

**Solution:**
```gdscript
# Ensure SettingsManager is initialized
var manager = Engine.get_singleton("SettingsManager")
if manager:
    manager.save_settings()  # Explicit save after remapping
```

### Issue: Wrong controller type detected

**Cause:** Auto-detection doesn't work for all controllers

**Solution:**
```gdscript
# Manually set controller type
remapper.set_controller_type("valve")  # Override auto-detection
```

### Issue: Button press not triggering

**Cause:** Action name misspelled or not supported

**Solution:**
```gdscript
# Check available actions
var actions = remapper.get_action_info()
for info in actions:
    print("Available action: %s" % info.action)
```

## Performance Considerations

### Button Name Caching

The remapper caches resolved button names to avoid repeated lookups:

```gdscript
var button_name = remapper.map_button_name("interact")  # First call: does lookup
var button_name = remapper.map_button_name("interact")  # Second call: returns cached
```

Cache is cleared when:
- Controller type changes
- Custom mapping set
- `clear_cache()` called explicitly

### Impact

- Negligible (single dictionary lookup is <1ms)
- No perceptible performance impact
- Safe to call every frame

## Migration Guide

### From Hardcoded Button Names

**Old Code (brittle):**
```gdscript
# Only works on Meta
if controller.is_button_pressed("ax_button"):
    interact()
```

**New Code (portable):**
```gdscript
# Works on all controllers
if vr_manager.button_remapper.is_action_pressed("interact", controller):
    interact()
```

### From Hardcoded Actions

**Old Code:**
```gdscript
# PilotController has action_mappings dictionary
var action = _action_mappings.get(button_name)
```

**New Code:**
```gdscript
# Remapper handles mapping automatically
var action = _reverse_map_button_name(button_name)  # Returns semantic name
```

## Best Practices

1. **Use Semantic Names Throughout**
   - Never hardcode button names in game logic
   - Use remapper's semantic actions exclusively
   - Makes code controller-agnostic

2. **Listen to Signals When Possible**
   - Signals emit semantic action names
   - Decouples input from logic
   - Easier to test

3. **Allow Customization**
   - Provide button remapping in settings menu
   - Persist custom mappings automatically
   - Include accessibility options

4. **Test on Multiple Controllers**
   - Don't assume Meta controller layout
   - Test Valve Index, HTC Vive buttons
   - Verify fallback behavior

5. **Document Action Semantics**
   - Include action descriptions in UI
   - Use `get_action_info()` for display
   - Help players understand mapping

6. **Handle Missing Buttons Gracefully**
   - Check return values (empty = unavailable)
   - Provide fallback behaviors
   - Log warnings for missing actions

## File Structure

```
scripts/core/
├── controller_button_remapper.gd          # Main remapping system
├── vr_manager.gd                           # Updated to use remapper
├── vr_manager_remapping_integration.gd    # Integration guide
├── settings_manager.gd                     # VR settings storage
└── CONTROLLER_REMAPPING_GUIDE.md          # This file

scripts/player/
├── controller_remapping_examples.gd       # Usage examples
├── pilot_controller.gd                     # Can use remapper
├── terrain_tool.gd                         # Can use remapper
└── ...
```

## API Reference

See comments in `controller_button_remapper.gd` for complete API documentation.

### Key Methods

```gdscript
# Map semantic action to hardware button
map_button_name(action_name: String, controller: XRController3D = null) -> String

# Check if action is pressed
is_action_pressed(action_name: String, controller: XRController3D) -> bool

# Get float value (triggers, grips)
get_action_float(action_name: String, controller: XRController3D) -> float

# Get vector2 value (thumbsticks)
get_action_vector2(action_name: String, controller: XRController3D) -> Vector2

# Set custom mapping
set_custom_mapping(action_name: String, button_names: Array, save_to_settings: bool = true) -> void

# Set controller type
set_controller_type(controller_type: String) -> void

# Get current mappings
get_all_mappings() -> Dictionary

# Get action info for UI
get_action_info() -> Array

# Get controller profile
get_controller_profile_info(controller_type: String = "") -> Dictionary
```

## Future Enhancements

- [ ] Haptic feedback mapping
- [ ] Gesture recognition support
- [ ] Hand tracking button mapping
- [ ] Advanced customization UI
- [ ] Per-game button profiles
- [ ] Controller calibration interface
- [ ] Accessibility profiles (one-handed, limited mobility, etc.)

## Summary

The Controller Button Remapping System ensures your VR game works seamlessly across all major VR platforms without code changes. By using semantic action names instead of hardcoded button names, you create more maintainable, portable, and testable VR applications.

**Key Benefits:**
- ✅ Works on all major VR systems
- ✅ Auto-detects controller type
- ✅ Allows player customization
- ✅ Persists settings automatically
- ✅ Zero performance overhead
- ✅ Backward compatible
- ✅ Easy to integrate
