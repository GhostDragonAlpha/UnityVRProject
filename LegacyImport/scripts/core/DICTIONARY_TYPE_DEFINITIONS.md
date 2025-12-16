# Dictionary Type Definitions

This document provides comprehensive type definitions for all Dictionary structures used in the Physics and VR systems. These structures are used extensively throughout the codebase and should be validated using the `DictionaryValidators` utility class.

## Table of Contents
1. [CelestialBody](#celestialbody)
2. [CollisionInfo](#collisioninfo)
3. [ControllerState](#controllerstate)
4. [ContinuousEffect](#continuouseffect)

---

## CelestialBody

**Used in:** `PhysicsEngine.celestial_bodies`

**Description:** Represents a celestial body (gravity source) in the physics simulation. Tracks the node reference, mass, radius, and cached position for efficient gravity calculations.

### Structure
```gdscript
{
  "node": Node3D,        # Reference to the 3D node representing the celestial body
  "mass": float,         # Mass in arbitrary units (used for gravity calculations)
  "radius": float,       # Radius in meters (used for escape velocity and SOI calculations)
  "position": Vector3    # Cached world position updated each frame for efficiency
}
```

### Type Constraints
- **node**: `Node3D` or `null` - The spatial node in the scene
- **mass**: `float` - Must be positive, typically > 1.0
- **radius**: `float` - Must be positive and > MIN_GRAVITY_DISTANCE (1.0)
- **position**: `Vector3` - Cached from node.global_position

### Validation
```gdscript
# In physics_engine.gd:
if not DictionaryValidators.validate_celestial_body(celestial):
    push_error("Invalid celestial body structure")
```

### Creation
```gdscript
# Using validator utility
var body = DictionaryValidators.create_celestial_body(node, mass, radius, position)

# Or manually
var body = {
    "node": sun_node,
    "mass": 1000.0,
    "radius": 696000.0,
    "position": sun_node.global_position
}
```

### Usage in PhysicsEngine
```gdscript
# Adding a celestial body
physics_engine.add_celestial_body(sun_node, 1000.0, 696000.0)

# Iterating over celestial bodies
for celestial in celestial_bodies:
    var force = calculate_gravitational_force(
        body_pos,
        body_mass,
        celestial.position,
        celestial.mass
    )

# Updating positions
physics_engine.update_celestial_positions()
```

---

## CollisionInfo

**Used in:**
- `HapticManager._on_spacecraft_collision(collision_info)`
- Signal `spacecraft.collision_occurred.emit(collision_info)`

**Description:** Contains detailed information about a collision event, including velocity at impact, collision position, surface normal, and collision depth.

### Structure
```gdscript
{
  "velocity": Vector3,      # Velocity vector at time of collision (REQUIRED)
  "position": Vector3,      # Position where collision occurred (OPTIONAL)
  "normal": Vector3,        # Surface normal at collision point (OPTIONAL)
  "depth": float,           # Penetration depth of collision (OPTIONAL)
  "collider": Node3D        # The node that was collided with (OPTIONAL)
}
```

### Type Constraints
- **velocity**: `Vector3` (REQUIRED) - The velocity vector at collision time
- **position**: `Vector3` - World position of collision point
- **normal**: `Vector3` - Unit normal vector of the surface
- **depth**: `float` - Penetration depth in meters
- **collider**: `Node3D` - Reference to the colliding object

### Validation
```gdscript
# In haptic_manager.gd:
if not DictionaryValidators.validate_collision_info(collision_info):
    push_error("Invalid collision info structure")
```

### Creation
```gdscript
# Using validator utility
var info = DictionaryValidators.create_collision_info(
    velocity,
    position,
    normal,
    depth,
    collider
)

# Or manually
var info = {
    "velocity": impact_velocity,
    "position": collision_position,
    "normal": surface_normal,
    "depth": 0.5,
    "collider": other_node
}
```

### Usage in HapticManager
```gdscript
func _on_spacecraft_collision(collision_info: Dictionary) -> void:
    var velocity = collision_info.get("velocity", Vector3.ZERO)
    var collision_velocity = velocity.length()
    trigger_collision(collision_velocity)
```

---

## ControllerState

**Used in:**
- `VRManager._left_controller_state`
- `VRManager._right_controller_state`
- `VRManager.get_controller_state(hand)`

**Description:** Represents the current state of a VR controller, including analog inputs (triggers, grips), button states, and thumbstick position.

### Structure
```gdscript
{
  "trigger": float,           # Trigger value (0.0 to 1.0) - REQUIRED
  "grip": float,              # Grip value (0.0 to 1.0) - REQUIRED
  "thumbstick": Vector2,      # Thumbstick position (-1.0 to 1.0) - REQUIRED
  "button_ax": bool,          # A/X button state - REQUIRED
  "button_by": bool,          # B/Y button state - REQUIRED
  "button_menu": bool,        # Menu button state - REQUIRED
  "thumbstick_click": bool,   # Thumbstick click/press state - REQUIRED
  "position": Vector3,        # Controller position (OPTIONAL)
  "rotation": Quaternion      # Controller rotation (OPTIONAL)
}
```

### Type Constraints
- **trigger**: `float` - Range [0.0, 1.0]
- **grip**: `float` - Range [0.0, 1.0]
- **thumbstick**: `Vector2` - Range [-1.0, 1.0] on both axes
- **button_ax**: `bool` - Left: X button, Right: A button
- **button_by**: `bool` - Left: Y button, Right: B button
- **button_menu**: `bool` - Menu/Options button
- **thumbstick_click**: `bool` - Primary click on thumbstick
- **position**: `Vector3` - Optional controller world position
- **rotation**: `Quaternion` - Optional controller world rotation

### Validation
```gdscript
# In vr_manager.gd:
if not DictionaryValidators.validate_controller_state(state):
    push_error("Invalid controller state structure")
```

### Creation
```gdscript
# Using validator utility
var state = DictionaryValidators.create_controller_state(
    trigger_value,
    grip_value,
    thumbstick_vector,
    ax_button,
    by_button,
    menu_button,
    thumbstick_click,
    position,
    rotation
)

# Or manually
var state = {
    "trigger": 0.5,
    "grip": 0.0,
    "thumbstick": Vector2(0.1, 0.2),
    "button_ax": false,
    "button_by": false,
    "button_menu": false,
    "thumbstick_click": false,
    "position": controller_transform.origin,
    "rotation": controller_transform.basis.get_rotation_quaternion()
}
```

### Usage in VRManager
```gdscript
func update_tracking() -> void:
    if left_controller and _left_controller_connected:
        _update_controller_state(left_controller, "left")

func _update_controller_state(controller: XRController3D, hand: String) -> void:
    var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state

    state["trigger"] = controller.get_float("trigger")
    state["grip"] = controller.get_float("grip")
    state["thumbstick"] = controller.get_vector2("primary")
    state["button_ax"] = controller.is_button_pressed("ax_button")
    state["button_by"] = controller.is_button_pressed("by_button")
    state["button_menu"] = controller.is_button_pressed("menu_button")
    state["thumbstick_click"] = controller.is_button_pressed("primary_click")

    if hand == "left":
        _left_controller_state = state
    else:
        _right_controller_state = state
```

---

## ContinuousEffect

**Used in:**
- `HapticManager._continuous_effects[hand][effect_name]`
- `HapticManager.start_continuous_effect()`
- `HapticManager.stop_continuous_effect()`

**Description:** Represents an ongoing haptic effect with intensity, start time, and duration information. Allows tracking multiple simultaneous haptic effects per controller.

### Structure
```gdscript
{
  "intensity": float,    # Haptic intensity (0.0 to 1.0)
  "start_time": float,   # Time when effect started (seconds since epoch)
  "duration": float      # Duration of effect in seconds (-1.0 for infinite)
}
```

### Type Constraints
- **intensity**: `float` - Range [0.0, 1.0]
- **start_time**: `float` - Time in seconds from Time.get_ticks_msec() / 1000.0
- **duration**: `float` - Positive seconds or -1.0 for continuous/infinite

### Validation
```gdscript
# In haptic_manager.gd:
if not DictionaryValidators.validate_continuous_effect(effect):
    push_error("Invalid continuous effect structure")
```

### Creation
```gdscript
# Using validator utility
var effect = DictionaryValidators.create_continuous_effect(intensity, start_time, duration)

# Or manually
var effect = {
    "intensity": 0.8,
    "start_time": Time.get_ticks_msec() / 1000.0,
    "duration": 2.0  # 2 seconds
}
```

### Usage in HapticManager
```gdscript
func start_continuous_effect(hand: String, effect_name: String, intensity: float, duration: float = -1.0) -> void:
    var current_time := Time.get_ticks_msec() / 1000.0

    var effect_data := {
        "intensity": intensity,
        "start_time": current_time,
        "duration": duration
    }

    if hand == "both":
        _continuous_effects["left"][effect_name] = effect_data.duplicate()
        _continuous_effects["right"][effect_name] = effect_data.duplicate()
    else:
        _continuous_effects[hand][effect_name] = effect_data

func _update_continuous_effects(delta: float) -> void:
    var current_time := Time.get_ticks_msec() / 1000.0

    for hand in ["left", "right"]:
        var effects: Dictionary = _continuous_effects[hand]
        var effects_to_remove: Array[String] = []

        for effect_name in effects.keys():
            var effect: Dictionary = effects[effect_name]
            var elapsed: float = current_time - effect.start_time

            # Check if effect should continue
            if elapsed >= effect.get("duration", DURATION_CONTINUOUS):
                effects_to_remove.append(effect_name)

        # Remove expired effects
        for effect_name in effects_to_remove:
            effects.erase(effect_name)
```

---

## Best Practices

### 1. Always Validate Before Use
```gdscript
# BAD - Assumes structure is correct
func use_data(data: Dictionary) -> void:
    var velocity = data["velocity"]  # Could crash if key missing

# GOOD - Validates structure first
func use_data(data: Dictionary) -> void:
    if not DictionaryValidators.validate_collision_info(data):
        return
    var velocity = data.get("velocity", Vector3.ZERO)
```

### 2. Use .get() with Defaults for Optional Fields
```gdscript
# Access optional fields safely
var position = collision_info.get("position", Vector3.ZERO)
var collider = collision_info.get("collider", null)
```

### 3. Use Validator Functions for Creation
```gdscript
# Use validators for creating new instances
var state = DictionaryValidators.create_controller_state(...)

# Easier to maintain if structure changes
```

### 4. Document Dictionary Access in Comments
```gdscript
func _apply_velocity_modifier(body: RigidBody3D, force: Vector3, celestial: Dictionary) -> Vector3:
    """Modify gravitational force based on body velocity relative to escape velocity.

    Args:
        celestial: CelestialBody dictionary with keys: node, mass, radius, position
    """
    var escape_velocity = calculate_escape_velocity(
        celestial.mass,      # From CelestialBody
        celestial.radius,    # From CelestialBody
        body.global_position,
        celestial.position   # From CelestialBody
    )
```

### 5. Handle Type Mismatches Gracefully
```gdscript
# GOOD - Type checking with fallback
if data.get("trigger") is float:
    trigger_value = data["trigger"]
else:
    trigger_value = 0.0
    push_warning("Controller state 'trigger' was not a float")
```

---

## Migration Guide

If you encounter code using unvalidated Dictionaries:

1. **Identify the structure** - Look at how the Dictionary is used
2. **Add type comment** - Add documentation above the variable declaration
3. **Add validation** - Call appropriate validator function before use
4. **Use utility functions** - Replace manual dictionary creation with validators

### Example Migration

**Before:**
```gdscript
var state = {}
state["trigger"] = 0.5
state["grip"] = 0.0
state["thumbstick"] = Vector2.ZERO
# ... more assignments
```

**After:**
```gdscript
var state = DictionaryValidators.create_controller_state(
    trigger_value=0.5,
    grip_value=0.0,
    thumbstick=Vector2.ZERO
)
# Validation happens automatically in create function
```
