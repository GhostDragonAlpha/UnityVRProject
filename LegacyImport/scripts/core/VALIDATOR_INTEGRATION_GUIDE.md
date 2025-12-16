# Dictionary Validator Integration Guide

This guide explains how to integrate the `DictionaryValidators` utility class into existing code to ensure type safety for Dictionary structures used in the physics and VR systems.

## Quick Start

### 1. Import the Validator Class

The `DictionaryValidators` class is a utility class with static methods. No need to instantiate it:

```gdscript
# In any .gd file that needs validation:
var is_valid = DictionaryValidators.validate_celestial_body(celestial)
```

### 2. Validate Dictionary Structures

Before using any Dictionary that comes from external sources or when you need to ensure type safety:

```gdscript
# PhysicsEngine - Validate when adding celestial bodies
func add_celestial_body(node: Node3D, mass: float, radius: float) -> void:
    var body = {
        "node": node,
        "mass": mass,
        "radius": radius,
        "position": node.global_position
    }

    if not DictionaryValidators.validate_celestial_body(body):
        push_error("Failed to create valid celestial body")
        return

    celestial_bodies.append(body)
```

### 3. Create Dictionaries Using Validators

For consistency and maintainability, use the validator creation functions:

```gdscript
# HapticManager - Create controller state safely
var state = DictionaryValidators.create_controller_state(
    trigger_value=0.5,
    grip_value=0.3,
    thumbstick=thumbstick_input,
    button_ax=button_ax_pressed,
    button_by=button_by_pressed,
    button_menu=menu_pressed,
    thumbstick_click=primary_click
)
```

---

## Integration Points by File

### PhysicsEngine (C:/godot/scripts/core/physics_engine.gd)

**Current Dictionary:** `celestial_bodies: Array[Dictionary]`

**Type:** CelestialBody

**Changes Needed:**

1. **Add documentation comment:**
```gdscript
## Array of celestial bodies (gravity sources)
## CelestialBody Dictionary structure: {
##   "node": Node3D - Reference to the 3D node representing the celestial body
##   "mass": float - Mass in arbitrary units
##   "radius": float - Radius in meters
##   "position": Vector3 - Cached world position updated each frame
## }
## Use DictionaryValidators.validate_celestial_body() for validation
var celestial_bodies: Array[Dictionary] = []
```

2. **In add_celestial_body():**
```gdscript
func add_celestial_body(node: Node3D, mass: float, radius: float) -> void:
    """Register a celestial body as a gravity source."""
    if node == null:
        push_warning("PhysicsEngine: Cannot register null celestial body")
        return

    # Create using validator
    var body = DictionaryValidators.create_celestial_body(node, mass, radius, node.global_position)

    # Check if already registered
    for celestial in celestial_bodies:
        if celestial.node == node:
            # Update existing entry
            celestial.mass = mass
            celestial.radius = radius
            celestial.position = node.global_position
            return

    # Add new entry (already validated by create function)
    celestial_bodies.append(body)
```

3. **In calculate_n_body_gravity():**
```gdscript
func calculate_n_body_gravity(dt: float) -> void:
    """Calculate gravitational forces from all celestial bodies on all registered bodies."""
    # ... existing code ...

    for celestial in nearby_celestials:
        # Optional: Add debug validation for nearby celestials
        if not DictionaryValidators.validate_celestial_body(celestial):
            push_error("Invalid celestial body in nearby list")
            continue

        # Rest of function...
```

---

### HapticManager (C:/godot/scripts/core/haptic_manager.gd)

**Current Dictionaries:**
1. `_continuous_effects: Dictionary` - Contains ContinuousEffect dictionaries
2. Signal handler receives `collision_info: Dictionary` - CollisionInfo type

**Changes Needed:**

1. **Add documentation for _continuous_effects:**
```gdscript
## Continuous haptic effects tracking
## Structure: {
##   "left": {effect_name: ContinuousEffect},
##   "right": {effect_name: ContinuousEffect}
## }
## ContinuousEffect: {intensity: float, start_time: float, duration: float}
## Use DictionaryValidators.create_continuous_effect() for creation
var _continuous_effects: Dictionary = {
    "left": {},
    "right": {}
}
```

2. **In _on_spacecraft_collision():**
```gdscript
func _on_spacecraft_collision(collision_info: Dictionary) -> void:
    # Validate collision info structure
    if not DictionaryValidators.validate_collision_info(collision_info):
        push_error("Invalid collision info received")
        return

    var velocity: Vector3 = collision_info.get("velocity", Vector3.ZERO)
    var collision_velocity: float = velocity.length()
    trigger_collision(collision_velocity)
```

3. **In start_continuous_effect():**
```gdscript
func start_continuous_effect(hand: String, effect_name: String, intensity: float, duration: float = -1.0) -> void:
    var current_time := Time.get_ticks_msec() / 1000.0

    # Use validator to create effect
    var effect_data = DictionaryValidators.create_continuous_effect(
        clamp(intensity, 0.0, 1.0),
        current_time,
        duration
    )

    if hand == "both":
        _continuous_effects["left"][effect_name] = effect_data.duplicate()
        _continuous_effects["right"][effect_name] = effect_data.duplicate()
    else:
        _continuous_effects[hand][effect_name] = effect_data
```

4. **In _update_continuous_effects():**
```gdscript
func _update_continuous_effects(delta: float) -> void:
    var current_time := Time.get_ticks_msec() / 1000.0

    for hand in ["left", "right"]:
        var effects: Dictionary = _continuous_effects[hand]
        var effects_to_remove: Array[String] = []

        for effect_name in effects.keys():
            var effect: Dictionary = effects[effect_name]

            # Validate effect structure
            if not DictionaryValidators.validate_continuous_effect(effect):
                push_warning("Invalid continuous effect '%s' on %s hand" % [effect_name, hand])
                effects_to_remove.append(effect_name)
                continue

            var elapsed: float = current_time - effect.start_time

            # Check if effect should continue
            if elapsed >= effect.get("duration", DURATION_CONTINUOUS):
                effects_to_remove.append(effect_name)

        # Remove expired effects
        for effect_name in effects_to_remove:
            effects.erase(effect_name)
```

---

### VRManager (C:/godot/scripts/core/vr_manager.gd)

**Current Dictionaries:**
1. `_left_controller_state: Dictionary` - ControllerState type
2. `_right_controller_state: Dictionary` - ControllerState type

**Changes Needed:**

1. **Add documentation for controller state variables:**
```gdscript
## Controller state tracking
## ControllerState Dictionary structure: {
##   "trigger": float, "grip": float, "thumbstick": Vector2,
##   "button_ax": bool, "button_by": bool, "button_menu": bool,
##   "thumbstick_click": bool, "position": Vector3, "rotation": Quaternion
## }
## Use DictionaryValidators.create_controller_state() for creation
var _left_controller_state: Dictionary = {}
var _right_controller_state: Dictionary = {}
```

2. **In _update_controller_state():**
```gdscript
func _update_controller_state(controller: XRController3D, hand: String) -> void:
    # Defensive null check
    if not controller or not is_instance_valid(controller):
        return

    var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state

    # Use validator to create complete state
    state = DictionaryValidators.create_controller_state(
        trigger=controller.get_float("trigger"),
        grip=controller.get_float("grip"),
        thumbstick=controller.get_vector2("primary"),
        button_ax=controller.is_button_pressed("ax_button"),
        button_by=controller.is_button_pressed("by_button"),
        button_menu=controller.is_button_pressed("menu_button"),
        thumbstick_click=controller.is_button_pressed("primary_click"),
        position=controller.global_position if controller else Vector3.ZERO,
        rotation=controller.global_transform.basis.get_rotation_quaternion() if controller else Quaternion.IDENTITY
    )

    # Validate before storing
    if DictionaryValidators.validate_controller_state(state):
        if hand == "left":
            _left_controller_state = state
        else:
            _right_controller_state = state
    else:
        push_error("Failed to create valid controller state for %s hand" % hand)
```

3. **In get_controller_state():**
```gdscript
func get_controller_state(hand: String) -> Dictionary:
    # Check if there's a VR input simulator running
    var simulator = get_tree().root.find_child("VRInputSimulator", true, false)
    if simulator and simulator.has_method("get_simulated_state"):
        return simulator.get_simulated_state(hand)

    if current_mode == VRMode.DESKTOP:
        return _get_desktop_simulated_controller_state(hand)

    # Return copy and validate if needed in debug mode
    if hand == "left":
        var state = _left_controller_state.duplicate()
        # Optional: Validate in debug builds
        # if OS.is_debug_build() and not DictionaryValidators.validate_controller_state(state):
        #     push_warning("Retrieved invalid controller state for left hand")
        return state
    elif hand == "right":
        var state = _right_controller_state.duplicate()
        # Optional: Validate in debug builds
        # if OS.is_debug_build() and not DictionaryValidators.validate_controller_state(state):
        #     push_warning("Retrieved invalid controller state for right hand")
        return state

    return DictionaryValidators.create_controller_state()  # Return empty default state
```

4. **In _get_desktop_simulated_controller_state():**
```gdscript
func _get_desktop_simulated_controller_state(hand: String) -> Dictionary:
    # Use validator to create proper default state
    var state = DictionaryValidators.create_controller_state()

    # Simulate right controller with mouse buttons
    if hand == "right":
        state["trigger"] = 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0
        state["grip"] = 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0.0

    return state
```

---

## Validation Strategies

### Strategy 1: Defensive Programming (Recommended)

Always validate external Dictionary data:

```gdscript
func receive_external_data(data: Dictionary) -> void:
    if not DictionaryValidators.validate_collision_info(data):
        push_error("Received invalid collision info")
        return

    # Safe to use data now
    process_collision(data)
```

### Strategy 2: Creation-Based Safety

Use validators only for creation, assume internal structures are valid:

```gdscript
# Internal function - always creates valid structures
func _create_effect() -> Dictionary:
    return DictionaryValidators.create_continuous_effect(0.8, Time.get_ticks_msec() / 1000.0)

# Only validate when receiving from unknown sources
func receive_external_effect(effect: Dictionary) -> void:
    if not DictionaryValidators.validate_continuous_effect(effect):
        return
```

### Strategy 3: Debug-Only Validation

Validate only in debug builds for performance:

```gdscript
func process_data(data: Dictionary) -> void:
    if OS.is_debug_build():
        assert(DictionaryValidators.validate_controller_state(data), "Invalid controller state")

    # Process assuming valid
```

---

## Testing Validators

### Unit Test Example

```gdscript
# In tests/test_dictionary_validators.gd
extends GdUnitTestSuite

func test_celestial_body_validation() -> void:
    var valid_body = DictionaryValidators.create_celestial_body(
        Node3D.new(),
        1000.0,
        696000.0
    )

    assert_that(DictionaryValidators.validate_celestial_body(valid_body)).is_true()

    # Test invalid body (missing field)
    var invalid_body = {"node": Node3D.new(), "mass": 1000.0}
    assert_that(DictionaryValidators.validate_celestial_body(invalid_body)).is_false()


func test_controller_state_creation() -> void:
    var state = DictionaryValidators.create_controller_state(
        trigger=0.5,
        grip=0.3
    )

    assert_that(state["trigger"]).is_equal(0.5)
    assert_that(state["grip"]).is_equal(0.3)
    assert_that(state["thumbstick"]).is_equal(Vector2.ZERO)
```

---

## Performance Considerations

### When to Validate

1. **Always validate:**
   - Data from external sources
   - Data from signals/events
   - User-provided data
   - Data at module boundaries

2. **Optional validation:**
   - Internal data in hot loops (performance critical)
   - Data you created with validators
   - Data validated at a higher level

3. **Never validate:**
   - Already-validated data in tight loops
   - Data from trusted internal functions
   - During frame updates in 90 FPS loops (unless needed)

### Optimization Tips

```gdscript
# GOOD - Validate once at entry point
func process_data_batch(items: Array[Dictionary]) -> void:
    # Validate all at once
    for item in items:
        if not DictionaryValidators.validate_celestial_body(item):
            push_error("Skipping invalid item")
            continue

    # Process validated items
    for item in items:
        apply_gravity(item)  # No validation needed


# BAD - Validate in hot loop
func apply_gravity_each_frame() -> void:
    for celestial in celestial_bodies:
        if not DictionaryValidators.validate_celestial_body(celestial):  # SLOW
            continue
        apply_force(celestial)
```

---

## Error Handling

Validators will push errors/warnings, but you can also check return values:

```gdscript
# Check return value
if DictionaryValidators.validate_celestial_body(data):
    use_data(data)
else:
    handle_invalid_data()

# Errors are also printed to console
# [ERROR] [DictionaryValidators] CelestialBody missing 'mass' field
```

---

## Migration Checklist

- [ ] Create/import `DictionaryValidators.gd`
- [ ] Add type documentation comments to all Dictionary variables
- [ ] Update `add_celestial_body()` in PhysicsEngine
- [ ] Update collision signal handler in HapticManager
- [ ] Update controller state methods in VRManager
- [ ] Update continuous effects handling in HapticManager
- [ ] Run tests to verify validation works
- [ ] Review hot-path performance if needed
- [ ] Document Dictionary structures in CLAUDE.md

---

## References

- Dictionary type definitions: `DICTIONARY_TYPE_DEFINITIONS.md`
- Validator implementation: `dictionary_validators.gd`
- PhysicsEngine documentation: `C:/godot/scripts/core/physics_engine.gd`
- HapticManager documentation: `C:/godot/scripts/core/haptic_manager.gd`
- VRManager documentation: `C:/godot/scripts/core/vr_manager.gd`
