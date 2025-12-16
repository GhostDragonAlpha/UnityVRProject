# VR Locomotion Guide

**Version:** 1.0
**Last Updated:** 2025-12-09
**Status:** Production Ready

This guide documents the VR locomotion systems implemented in SpaceTime, including zero-G flight controls, object grabbing, and teleportation. The project leverages both custom implementations and the godot-xr-tools addon for comprehensive VR locomotion.

---

## Table of Contents

1. [Overview](#overview)
2. [Flight Controls (Zero-G Navigation)](#flight-controls-zero-g-navigation)
3. [Object Grabbing System](#object-grabbing-system)
4. [Teleportation System](#teleportation-system)
5. [VR Comfort Features Integration](#vr-comfort-features-integration)
6. [Controller Input Mapping](#controller-input-mapping)
7. [Configuration Examples](#configuration-examples)
8. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview

SpaceTime supports three primary locomotion modes optimized for VR:

1. **Zero-G Flight** - Free-flight navigation for space environments
2. **Object Grabbing** - Pick up, carry, and throw objects with hand controllers
3. **Teleportation** - Comfort-focused instant movement with arc-based targeting

All systems are designed with VR comfort in mind, featuring:
- Snap-turn rotation to reduce motion sickness
- Vignetting during rapid acceleration
- Dead zone configuration for precise input
- Haptic feedback for tactile confirmation
- Desktop fallback mode for development without VR hardware

### Architecture Overview

The locomotion systems are coordinated through:
- **VRManager** (C:/Ignotus/scripts/core/vr_manager.gd) - OpenXR initialization, controller tracking
- **VRComfortSystem** (C:/Ignotus/scripts/core/vr_comfort_system.gd) - Vignetting, snap-turns, stationary mode
- **VRTeleportation** (C:/Ignotus/scripts/player/vr_teleportation.gd) - Custom teleportation implementation
- **godot-xr-tools addon** (C:/Ignotus/addons/godot-xr-tools/) - Community-standard VR locomotion components

---

## Flight Controls (Zero-G Navigation)

### Overview

Zero-G flight allows players to navigate freely through space environments using their VR controllers. The system supports both custom implementations and the godot-xr-tools `XRToolsMovementFlight` component.

### Custom Flight Implementation

**Location:** C:/Ignotus/scenes/features/vr_locomotion_test.gd

The custom flight system provides direct control over movement with camera-relative orientation:

```gdscript
# Flight parameters
const FLIGHT_ACCELERATION: float = 2.0
const FLIGHT_MAX_SPEED: float = 5.0
const FLIGHT_DRAG: float = 0.8

# Enable flight mode
var flight_enabled: bool = false
var flight_velocity: Vector3 = Vector3.ZERO
```

**Flight Movement Processing:**
```gdscript
func _process_flight_movement(delta: float) -> void:
    # Get controller input
    var left_stick: Vector2 = left_controller.get_vector2("primary")
    var right_stick: Vector2 = right_controller.get_vector2("primary")

    # Calculate movement direction based on camera orientation
    var camera_basis: Basis = xr_camera.global_transform.basis
    var forward: Vector3 = -camera_basis.z
    var right: Vector3 = camera_basis.x

    # Apply movement input
    var move_direction: Vector3 = Vector3.ZERO
    move_direction += forward * left_stick.y  # Forward/backward
    move_direction += right * left_stick.x    # Strafe left/right

    # Apply acceleration with max speed clamping
    if move_direction.length() > 0:
        move_direction = move_direction.normalized()
        flight_velocity += move_direction * FLIGHT_ACCELERATION * delta

        if flight_velocity.length() > FLIGHT_MAX_SPEED:
            flight_velocity = flight_velocity.normalized() * FLIGHT_MAX_SPEED

    # Apply drag
    flight_velocity *= (1.0 - FLIGHT_DRAG * delta)

    # Move XR origin
    xr_origin.global_position += flight_velocity * delta
```

### godot-xr-tools Flight Component

**Component:** `XRToolsMovementFlight`
**Location:** C:/Ignotus/addons/godot-xr-tools/functions/movement_flight.gd

The XR Tools flight provider offers advanced flight mechanics with multiple control modes:

#### Control Modes

**Pitch Control:**
- `HEAD` - Head orientation controls vertical movement
- `CONTROLLER` - Controller orientation controls vertical movement

**Bearing Control:**
- `HEAD` - Head orientation controls horizontal direction
- `CONTROLLER` - Controller orientation controls horizontal direction
- `BODY` - XROrigin3D orientation controls horizontal direction

#### Configuration Properties

```gdscript
@export var controller: FlightController = FlightController.LEFT
@export var flight_button: String = "by_button"
@export var pitch: FlightPitch = FlightPitch.CONTROLLER
@export var bearing: FlightBearing = FlightBearing.CONTROLLER

# Speed-based flight (Mary Poppins mode)
@export var speed_scale: float = 5.0
@export var speed_traction: float = 3.0

# Acceleration-based flight (realistic mode)
@export var acceleration_scale: float = 0.0
@export var drag: float = 0.1
@export var guidance: float = 0.0

# Movement exclusivity
@export var exclusive: bool = true
```

#### Scene Setup Example

```gdscript
# Add to left or right XRController3D node
var flight_component = XRToolsMovementFlight.new()
flight_component.controller = XRToolsMovementFlight.FlightController.LEFT
flight_component.flight_button = "by_button"
flight_component.pitch = XRToolsMovementFlight.FlightPitch.CONTROLLER
flight_component.bearing = XRToolsMovementFlight.FlightBearing.CONTROLLER
flight_component.speed_scale = 5.0
flight_component.exclusive = true
left_controller.add_child(flight_component)
```

### Controller Mapping for Flight

| Input | Left Controller | Right Controller |
|-------|----------------|------------------|
| **Movement** | Thumbstick Y (forward/back), X (strafe) | - |
| **Rotation** | - | Thumbstick X (yaw left/right) |
| **Flight Toggle** | Trigger or B/Y button | - |
| **Vertical Movement** | Controller pitch (when enabled) | - |

### Flight Physics Parameters

**Recommended Settings for Space Environment:**
- **Speed Scale**: 5.0-10.0 m/s (slow exploration to fast transit)
- **Acceleration**: 2.0-5.0 m/s² (gradual acceleration)
- **Drag**: 0.1-0.8 (lower for zero-G feel, higher for air-like resistance)
- **Max Speed**: 5.0-20.0 m/s (depends on environment scale)

---

## Object Grabbing System

### Overview

The object grabbing system allows players to pick up, hold, and throw objects using their VR controllers. The system uses the godot-xr-tools `XRToolsFunctionPickup` component.

### XRToolsFunctionPickup Component

**Location:** C:/Ignotus/addons/godot-xr-tools/functions/function_pickup.gd

#### Core Features

1. **Proximity Grabbing** - Pick up nearby objects within grab radius
2. **Ranged Grabbing** - Point and grab distant objects
3. **Throwing** - Release objects with velocity for physics-based throwing
4. **Collision Detection** - Proper collision handling for grabbed objects
5. **Multi-hand Support** - Separate grab handling for left/right hands

#### Configuration Properties

```gdscript
@export var enabled: bool = true
@export var pickup_axis_action: String = "grip"
@export var action_button_action: String = "trigger_click"

# Proximity grab settings
@export var grab_distance: float = 0.3
@export_flags_3d_physics var grab_collision_mask: int = DEFAULT_GRAB_MASK

# Ranged grab settings
@export var ranged_enable: bool = true
@export var ranged_distance: float = 5.0
@export_range(0.0, 45.0) var ranged_angle: float = 5.0
@export_flags_3d_physics var ranged_collision_mask: int = DEFAULT_RANGE_MASK

# Throwing physics
@export var impulse_factor: float = 1.0
@export var velocity_samples: int = 5
```

### Making Objects Pickable

Objects must inherit from `XRToolsPickable` or implement the pickable interface:

**Location:** C:/Ignotus/addons/godot-xr-tools/objects/pickable.gd

```gdscript
# Example pickable object setup
extends RigidBody3D
class_name PickableObject

func _ready():
    # Add to pickable collision layer (layer 3)
    collision_layer = 0b0000_0000_0000_0000_0000_0000_0000_0100
    collision_mask = 0b0000_0000_0000_0000_0000_0000_0000_0001

    # Ensure object has proper physics properties
    mass = 1.0
    gravity_scale = 0.0  # For zero-G environments
```

### Scene Setup for Grabbing

```gdscript
# Add XRToolsFunctionPickup to each controller
# Left Controller
var left_pickup = XRToolsFunctionPickup.new()
left_pickup.enabled = true
left_pickup.pickup_axis_action = "grip"
left_pickup.grab_distance = 0.3
left_pickup.ranged_enable = true
left_pickup.ranged_distance = 5.0
left_controller.add_child(left_pickup)

# Right Controller
var right_pickup = XRToolsFunctionPickup.new()
right_pickup.enabled = true
right_pickup.pickup_axis_action = "grip"
right_pickup.grab_distance = 0.3
right_pickup.ranged_enable = true
right_pickup.ranged_distance = 5.0
right_controller.add_child(right_pickup)
```

### Grab Signals

```gdscript
# Connect to pickup signals for feedback
left_pickup.has_picked_up.connect(_on_object_picked_up)
left_pickup.has_dropped.connect(_on_object_dropped)

func _on_object_picked_up(object):
    print("Picked up: ", object.name)
    # Trigger haptic feedback
    if haptic_manager:
        haptic_manager.trigger_haptic("left", 0.5, 0.1)

func _on_object_dropped():
    print("Dropped object")
```

### Controller Mapping for Grabbing

| Action | Input | Function |
|--------|-------|----------|
| **Proximity Grab** | Grip button (hold) | Pick up nearby object |
| **Ranged Grab** | Trigger + Grip (point then hold) | Grab distant object |
| **Release** | Release Grip button | Drop held object |
| **Throw** | Release Grip while moving | Throw object with velocity |

### Collision Layer Configuration

**Recommended Layer Setup:**
- **Layer 1 (0x0001)**: Default collision (environment)
- **Layer 3 (0x0004)**: Pickable objects
- **Layer 19 (0x40000)**: Grab handles (for specific grab points)

---

## Teleportation System

### Overview

The teleportation system provides comfort-focused instant movement with arc-based targeting, visual feedback, and collision detection. Both custom and godot-xr-tools implementations are available.

### Custom VRTeleportation System

**Location:** C:/Ignotus/scripts/player/vr_teleportation.gd

The custom implementation provides fine-grained control over teleportation mechanics:

#### Features

1. **Arc-Based Targeting** - Parabolic trajectory preview
2. **Visual Feedback** - Color-coded reticle (green=valid, red=invalid)
3. **Fade Transitions** - Brief fade to black during teleport
4. **Collision Detection** - Slope validation, headroom checking
5. **Snap Rotation** - Optional rotation during teleport
6. **Haptic Feedback** - Tactile confirmation

#### Configuration Properties

```gdscript
# Range settings
@export var teleport_range: float = 10.0
@export var min_teleport_distance: float = 1.0
@export var arc_height: float = 2.0
@export var arc_resolution: int = 32

# Target validation
@export var max_slope_angle: float = 45.0
@export var min_headroom: float = 2.0
@export var player_radius: float = 0.4

# Visual feedback
@export var valid_color: Color = Color(0.0, 1.0, 0.0, 0.8)
@export var invalid_color: Color = Color(1.0, 0.0, 0.0, 0.8)
@export var arc_width: float = 0.05
@export var reticle_radius: float = 0.5

# Fade transition
@export var fade_duration: float = 0.2
@export var fade_color: Color = Color.BLACK

# Input settings
@export var teleport_hand: String = "left"
@export var trigger_button: String = "trigger"
@export var teleport_on_release: bool = true

# Comfort settings
@export var snap_rotation_enabled: bool = false
@export var snap_rotation_angle: float = 45.0
@export var haptic_feedback: bool = true
```

#### Initialization

```gdscript
var teleport_system = VRTeleportation.new()
add_child(teleport_system)

# Initialize with VR manager and XR origin
teleport_system.initialize(vr_manager, xr_origin)

# Connect signals
teleport_system.teleport_started.connect(_on_teleport_started)
teleport_system.teleport_completed.connect(_on_teleport_completed)
teleport_system.targeting_state_changed.connect(_on_targeting_changed)
```

#### Arc Calculation

The custom system calculates parabolic arcs for natural teleport preview:

```gdscript
func calculate_teleport_arc(origin: Vector3, direction: Vector3) -> PackedVector3Array:
    var points := PackedVector3Array()
    var horizontal_distance := teleport_range
    var gravity := 9.8  # m/s²

    # Calculate arc trajectory
    var initial_velocity := sqrt(2.0 * gravity * arc_height)
    var time_to_apex := initial_velocity / gravity
    var total_time := time_to_apex * 2.0

    # Generate arc points with collision detection
    for i in range(arc_resolution + 1):
        var t := float(i) / float(arc_resolution) * total_time
        var horizontal := direction * (initial_velocity * t * 0.7)
        var vertical := Vector3.UP * (initial_velocity * t - 0.5 * gravity * t * t)
        var point := origin + horizontal + vertical
        points.append(point)

        # Stop at collision
        if i > 0:
            var hit := _raycast_segment(points[i - 1], point)
            if hit:
                points.append(hit.position)
                break

    return points
```

#### Target Validation

```gdscript
func is_valid_teleport_target(position: Vector3, normal: Vector3) -> bool:
    # Range check
    var distance := xr_origin.global_position.distance_to(position)
    if distance < min_teleport_distance or distance > teleport_range:
        return false

    # Slope check
    var angle := rad_to_deg(normal.angle_to(Vector3.UP))
    if angle > max_slope_angle:
        return false

    # Headroom check
    var headroom_check := _raycast(
        position + Vector3.UP * 0.1,
        position + Vector3.UP * min_headroom
    )
    if headroom_check:
        return false  # Blocked headroom

    # Player collision check
    var clearance_check := _sphere_cast(position + Vector3.UP * 1.0, player_radius)
    if clearance_check:
        return false  # Player would collide

    return true
```

### godot-xr-tools Teleport Component

**Component:** `XRToolsFunctionTeleport`
**Location:** C:/Ignotus/addons/godot-xr-tools/functions/function_teleport.gd

#### Configuration Properties

```gdscript
@export var enabled: bool = true
@export var teleport_button_action: String = "trigger_click"
@export var rotation_action: String = "primary"

# Visuals
@export var can_teleport_color: Color = Color(0.0, 1.0, 0.0, 1.0)
@export var cant_teleport_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var strength: float = 5.0
@export var arc_texture: Texture2D
@export var target_texture: Texture2D

# Player
@export var player_height: float = 1.8
@export var player_radius: float = 0.4
@export var player_scene: PackedScene

# Collision
@export var max_slope: float = 20.0
@export_flags_3d_physics var collision_mask: int = 1023
@export_flags_3d_physics var valid_teleport_mask: int = DEFAULT_MASK
```

#### Scene Setup

```gdscript
# Add to left controller
var teleport = XRToolsFunctionTeleport.new()
teleport.enabled = true
teleport.teleport_button_action = "trigger_click"
teleport.rotation_action = "primary"
teleport.can_teleport_color = Color(0.0, 1.0, 0.0, 1.0)
teleport.cant_teleport_color = Color(1.0, 0.0, 0.0, 1.0)
teleport.max_slope = 45.0
left_controller.add_child(teleport)
```

### Controller Mapping for Teleportation

| Action | Input | Function |
|--------|-------|----------|
| **Start Targeting** | Trigger (press and hold) | Show teleport arc |
| **Adjust Rotation** | Thumbstick X (while targeting) | Rotate target preview |
| **Execute Teleport** | Trigger (release) | Teleport to target |
| **Cancel** | Release outside valid area | Cancel teleport |

### Teleportation Workflow

1. **Press and hold trigger** - Activates targeting mode, shows arc preview
2. **Aim controller** - Arc updates in real-time, reticle shows target position
3. **Adjust rotation (optional)** - Use thumbstick to rotate target orientation
4. **Validate target** - Reticle color indicates valid (green) or invalid (red)
5. **Release trigger** - Execute teleport with fade transition

---

## VR Comfort Features Integration

### Overview

The VRComfortSystem provides motion sickness prevention features that integrate with all locomotion modes.

**Location:** C:/Ignotus/scripts/core/vr_comfort_system.gd

### Comfort Features

#### 1. Vignetting During Acceleration

Dynamically applies edge darkening during rapid movement:

```gdscript
# Vignetting configuration
var _vignetting_enabled: bool = true
var _vignetting_max_intensity: float = 0.7

# Acceleration thresholds
const VIGNETTE_ACCEL_THRESHOLD: float = 5.0   # m/s² - start vignetting
const VIGNETTE_ACCEL_MAX: float = 20.0        # m/s² - maximum vignetting

# Auto-calculated based on spacecraft acceleration
func _update_vignetting(delta: float) -> void:
    var current_velocity: Vector3 = spacecraft.get_linear_velocity()
    var accel_vector: Vector3 = (current_velocity - _last_velocity) / delta
    var acceleration := accel_vector.length()

    if acceleration > VIGNETTE_ACCEL_THRESHOLD:
        var accel_factor = (acceleration - VIGNETTE_ACCEL_THRESHOLD) /
                          (VIGNETTE_ACCEL_MAX - VIGNETTE_ACCEL_THRESHOLD)
        var intensity = clampf(accel_factor, 0.0, 1.0) * _vignetting_max_intensity
        apply_vignette(intensity)
```

#### 2. Snap-Turn Rotation

Discrete rotation increments to reduce motion sickness:

```gdscript
# Snap-turn configuration
var _snap_turn_enabled: bool = false
var _snap_turn_angle: float = 45.0
const SNAP_TURN_COOLDOWN_TIME: float = 0.3

# Execute snap turn
func execute_snap_turn(direction: int) -> bool:
    if not _snap_turn_enabled or _snap_turn_cooldown > 0:
        return false

    var turn_angle_rad = deg_to_rad(_snap_turn_angle * sign(direction))
    vr_manager.xr_origin.rotation.y += turn_angle_rad
    _snap_turn_cooldown = SNAP_TURN_COOLDOWN_TIME

    snap_turn_executed.emit(_snap_turn_angle * sign(direction))
    return true

# Process controller input for snap turns
func _process_snap_turn_input() -> void:
    var right_state := vr_manager.get_controller_state("right")
    var right_thumbstick: Vector2 = right_state.get("thumbstick", Vector2.ZERO)

    const STICK_THRESHOLD = 0.7
    if right_thumbstick.x < -STICK_THRESHOLD:
        execute_snap_turn(-1)  # Turn left
    elif right_thumbstick.x > STICK_THRESHOLD:
        execute_snap_turn(1)   # Turn right
```

#### 3. Stationary Mode

Locks player position while moving the universe (advanced comfort feature):

```gdscript
var _stationary_mode_active: bool = false

func set_stationary_mode(enabled: bool) -> void:
    _stationary_mode_active = enabled

    if enabled:
        # Move universe instead of player
        # Implementation depends on FloatingOriginSystem
        print("Stationary mode ENABLED - player locked")
    else:
        print("Stationary mode DISABLED - normal movement")

    stationary_mode_changed.emit(enabled)
```

### Comfort System Initialization

```gdscript
# Initialize comfort system
var comfort_system = VRComfortSystem.new()
ResonanceEngine.add_child(comfort_system)

# Initialize with VR manager and spacecraft
comfort_system.initialize(vr_manager, spacecraft_node)

# Connect signals
comfort_system.vignetting_changed.connect(_on_vignette_changed)
comfort_system.snap_turn_executed.connect(_on_snap_turn)
comfort_system.stationary_mode_changed.connect(_on_stationary_changed)
```

### Settings Integration

Comfort settings are saved via SettingsManager:

```gdscript
# Settings keys (section: "vr")
- comfort_mode: bool              # Master enable/disable
- vignetting_enabled: bool        # Enable vignetting
- vignetting_intensity: float     # Max vignetting (0.0-1.0)
- snap_turn_enabled: bool         # Enable snap turns
- snap_turn_angle: float          # Snap angle (15-180 degrees)
- stationary_mode: bool           # Enable stationary mode
```

---

## Controller Input Mapping

### Complete Controller Layout

#### Left Controller

| Input | Action Name | Function | Usage |
|-------|-------------|----------|-------|
| **Trigger** | `trigger` | Analog value 0.0-1.0 | Flight toggle, teleport targeting |
| **Trigger Click** | `trigger_click` | Digital button | Flight toggle (godot-xr-tools) |
| **Grip** | `grip` | Analog value 0.0-1.0 | Object pickup/hold |
| **Thumbstick** | `primary` | Vector2 | Movement (flight forward/back/strafe) |
| **Thumbstick Click** | `primary_click` | Digital button | Special actions |
| **X Button** | `ax_button` | Digital button | Menu/system actions |
| **Y Button** | `by_button` | Digital button | Flight toggle (XR Tools default) |
| **Menu Button** | `menu_button` | Digital button | Open menu |

#### Right Controller

| Input | Action Name | Function | Usage |
|-------|-------------|----------|-------|
| **Trigger** | `trigger` | Analog value 0.0-1.0 | Teleport targeting, interactions |
| **Trigger Click** | `trigger_click` | Digital button | Confirm teleport |
| **Grip** | `grip` | Analog value 0.0-1.0 | Object pickup/hold |
| **Thumbstick** | `primary` | Vector2 | Rotation (yaw), snap turns, teleport rotation |
| **Thumbstick Click** | `primary_click` | Digital button | Special actions |
| **A Button** | `ax_button` | Digital button | Confirm actions |
| **B Button** | `by_button` | Digital button | Cancel actions |
| **Menu Button** | `menu_button` | Digital button | Open menu |

### Dead Zone Configuration

The VRManager applies dead zones to prevent drift and accidental inputs:

```gdscript
# Default dead zone values
var _deadzone_trigger: float = 0.1        # 10% dead zone
var _deadzone_grip: float = 0.1           # 10% dead zone
var _deadzone_thumbstick: float = 0.15    # 15% radial dead zone
var _deadzone_enabled: bool = true

# Configure at runtime
func set_deadzone(trigger: float = -1.0, grip: float = -1.0,
                  thumbstick: float = -1.0, enabled: bool = true) -> void:
    if trigger >= 0.0:
        _deadzone_trigger = clamp(trigger, 0.0, 1.0)
    if grip >= 0.0:
        _deadzone_grip = clamp(grip, 0.0, 1.0)
    if thumbstick >= 0.0:
        _deadzone_thumbstick = clamp(thumbstick, 0.0, 1.0)
    _deadzone_enabled = enabled
```

### Button Debouncing

Prevents multiple triggers from single button press:

```gdscript
var _debounce_threshold_ms: float = 50.0  # 50ms debounce window

func set_debounce_threshold(milliseconds: float) -> void:
    _debounce_threshold_ms = clamp(milliseconds, 0.0, 500.0)
```

### Reading Controller State

```gdscript
# Get controller state from VRManager
var left_state := vr_manager.get_controller_state("left")
var right_state := vr_manager.get_controller_state("right")

# State dictionary contains:
# - trigger: float (0.0-1.0, dead zone applied)
# - grip: float (0.0-1.0, dead zone applied)
# - thumbstick: Vector2 (dead zone applied)
# - button_ax: bool (debounced)
# - button_by: bool (debounced)
# - button_menu: bool (debounced)
# - thumbstick_click: bool (debounced)
# - position: Vector3 (controller position)
# - rotation: Quaternion (controller rotation)
```

---

## Configuration Examples

### Example 1: Basic Zero-G Flight Setup

```gdscript
# Scene: res://scenes/space_station_interior.tscn

extends Node3D

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

func _ready():
    # Add XRToolsMovementFlight component
    var flight = XRToolsMovementFlight.new()
    flight.controller = XRToolsMovementFlight.FlightController.LEFT
    flight.flight_button = "by_button"
    flight.pitch = XRToolsMovementFlight.FlightPitch.CONTROLLER
    flight.bearing = XRToolsMovementFlight.FlightBearing.CONTROLLER

    # Configure flight physics
    flight.speed_scale = 5.0
    flight.speed_traction = 3.0
    flight.drag = 0.1
    flight.exclusive = true

    # Add to controller
    left_controller.add_child(flight)

    # Connect signals
    flight.flight_started.connect(_on_flight_started)
    flight.flight_finished.connect(_on_flight_finished)

func _on_flight_started():
    print("Flight mode activated")

func _on_flight_finished():
    print("Flight mode deactivated")
```

### Example 2: Complete Locomotion Setup (Flight + Teleport + Grab)

```gdscript
extends Node3D

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController

func _ready():
    # Setup flight on left controller
    var flight = XRToolsMovementFlight.new()
    flight.controller = XRToolsMovementFlight.FlightController.LEFT
    flight.flight_button = "by_button"
    flight.speed_scale = 5.0
    left_controller.add_child(flight)

    # Setup teleport on right controller
    var teleport = XRToolsFunctionTeleport.new()
    teleport.enabled = true
    teleport.teleport_button_action = "trigger_click"
    teleport.max_slope = 45.0
    teleport.can_teleport_color = Color(0.0, 1.0, 0.0, 1.0)
    teleport.cant_teleport_color = Color(1.0, 0.0, 0.0, 1.0)
    right_controller.add_child(teleport)

    # Setup pickup on both controllers
    var left_pickup = XRToolsFunctionPickup.new()
    left_pickup.pickup_axis_action = "grip"
    left_pickup.grab_distance = 0.3
    left_pickup.ranged_enable = true
    left_pickup.ranged_distance = 5.0
    left_controller.add_child(left_pickup)

    var right_pickup = XRToolsFunctionPickup.new()
    right_pickup.pickup_axis_action = "grip"
    right_pickup.grab_distance = 0.3
    right_pickup.ranged_enable = true
    right_pickup.ranged_distance = 5.0
    right_controller.add_child(right_pickup)
```

### Example 3: Custom Teleportation with Comfort Features

```gdscript
extends Node3D

@onready var vr_manager: VRManager = get_node("/root/ResonanceEngine/VRManager")
@onready var comfort_system: VRComfortSystem = get_node("/root/ResonanceEngine/VRComfortSystem")
@onready var xr_origin: XROrigin3D = $XROrigin3D

var teleport_system: VRTeleportation

func _ready():
    # Create custom teleport system
    teleport_system = VRTeleportation.new()
    add_child(teleport_system)

    # Configure teleportation
    teleport_system.teleport_range = 10.0
    teleport_system.arc_height = 2.0
    teleport_system.max_slope_angle = 45.0
    teleport_system.valid_color = Color(0.0, 1.0, 0.0, 0.8)
    teleport_system.invalid_color = Color(1.0, 0.0, 0.0, 0.8)
    teleport_system.fade_duration = 0.2
    teleport_system.haptic_feedback = true

    # Initialize with VR components
    teleport_system.initialize(vr_manager, xr_origin)

    # Connect signals
    teleport_system.teleport_started.connect(_on_teleport_started)
    teleport_system.teleport_completed.connect(_on_teleport_completed)

    # Configure comfort features
    comfort_system.set_snap_turn_angle(45.0)

func _on_teleport_started(from_pos: Vector3, to_pos: Vector3):
    # Apply extra vignetting during teleport
    comfort_system.apply_vignette(0.5)

func _on_teleport_completed(position: Vector3):
    print("Teleported to: ", position)
```

### Example 4: Pickable Object Setup

```gdscript
# PickableToolbox.gd
extends RigidBody3D

func _ready():
    # Configure for pickup system
    collision_layer = 0b0000_0000_0000_0000_0000_0000_0000_0100  # Layer 3
    collision_mask = 0b0000_0000_0000_0000_0000_0000_0000_0001   # Layer 1

    # Physics properties for zero-G
    mass = 5.0
    gravity_scale = 0.0
    linear_damp = 0.1
    angular_damp = 0.1

    # Make it pickable
    # Note: XRToolsFunctionPickup will detect this automatically
    # based on collision layer
```

---

## Troubleshooting Guide

### Flight Controls Not Working

**Symptom:** Controller input not moving player in flight mode

**Checklist:**
1. Verify OpenXR is initialized: Check for "[VRManager] OpenXR initialized successfully" in console
2. Check controller tracking: Verify controllers are detected and active
3. Confirm flight mode is enabled: Check `is_active` property on `XRToolsMovementFlight`
4. Verify button mapping: Ensure `flight_button` matches controller button name
5. Check XROrigin3D reference: Flight component needs valid XROrigin3D parent
6. Test in VR headset: Flight requires actual VR hardware or simulator

**Common Fixes:**
```gdscript
# Verify flight component is active
if flight_component.is_active:
    print("Flight active")
else:
    print("Flight inactive - press ", flight_component.flight_button)

# Check controller state
var controller_state = vr_manager.get_controller_state("left")
print("Left controller state: ", controller_state)

# Manual flight activation (for testing)
flight_component.set_flying(true)
```

### Objects Not Grabbable

**Symptom:** Grip button doesn't pick up objects

**Checklist:**
1. Verify collision layers: Object must be on layer 3 (pickable)
2. Check XRToolsFunctionPickup component: Must be child of XRController3D
3. Verify grab distance: Object must be within `grab_distance` (default 0.3m)
4. Check object physics: Must be RigidBody3D or implement pickable interface
5. Verify collision shapes: Object needs valid CollisionShape3D child
6. Test ranged grab: Try pointing directly at object with trigger + grip

**Common Fixes:**
```gdscript
# Check if object is in grab range
var pickup_component = left_controller.get_node("XRToolsFunctionPickup")
print("Closest object: ", pickup_component.closest_object)
print("Picked up object: ", pickup_component.picked_up_object)

# Verify collision layer configuration
print("Object collision layer: ", object.collision_layer)
print("Pickup grab mask: ", pickup_component.grab_collision_mask)

# Check if masks overlap
var can_grab = (object.collision_layer & pickup_component.grab_collision_mask) != 0
print("Can grab: ", can_grab)
```

### Teleportation Arc Not Appearing

**Symptom:** No visual arc when pressing trigger

**Checklist:**
1. Verify teleport component enabled: Check `enabled` property
2. Check trigger button mapping: Ensure `teleport_button_action` matches controller
3. Verify controller reference: Teleport needs valid XRController3D parent
4. Check scene hierarchy: Teleport visual nodes must be properly instantiated
5. Verify collision mask: Ensure world geometry is on collision layer
6. Test with debug output: Add print statements to teleport input handling

**Common Fixes:**
```gdscript
# Custom teleport system debug
print("Is targeting: ", teleport_system.is_currently_targeting())
print("Is valid target: ", teleport_system.is_current_target_valid())
print("Current target: ", teleport_system.get_current_target())

# XR Tools teleport debug
print("Teleport enabled: ", teleport_component.enabled)
print("Is teleporting: ", teleport_component.is_teleporting)
print("Can teleport: ", teleport_component.can_teleport)
```

### VR Comfort Features Not Working

**Symptom:** Vignetting not appearing, snap turns not executing

**Checklist:**
1. Verify VRComfortSystem initialization: Check for "Initialized successfully" message
2. Check settings: Ensure comfort features are enabled in SettingsManager
3. Verify spacecraft reference: Vignetting requires valid spacecraft node
4. Check acceleration threshold: May need to move faster to trigger vignetting
5. Verify snap turn cooldown: Can only snap once per 0.3 seconds
6. Check thumbstick input: Snap turns require significant thumbstick deflection (>0.7)

**Common Fixes:**
```gdscript
# Check comfort system state
print("Comfort mode enabled: ", comfort_system._comfort_mode_enabled)
print("Vignetting enabled: ", comfort_system._vignetting_enabled)
print("Current vignette intensity: ", comfort_system.get_vignette_intensity())
print("Current acceleration: ", comfort_system.get_current_acceleration())

# Force vignetting test
comfort_system.apply_vignette(0.7)  # 70% intensity

# Force snap turn test
comfort_system.execute_snap_turn(1)  # Turn right 45 degrees
```

### Dead Zones Too Aggressive

**Symptom:** Controller input feels unresponsive

**Solution:**
```gdscript
# Reduce dead zones
vr_manager.set_deadzone(
    0.05,   # trigger (5% instead of 10%)
    0.05,   # grip (5% instead of 10%)
    0.08,   # thumbstick (8% instead of 15%)
    true    # enabled
)

# Disable dead zones entirely (not recommended)
vr_manager.set_deadzone(-1.0, -1.0, -1.0, false)

# Get current configuration
var config = vr_manager.get_deadzone_config()
print("Dead zone config: ", config)
```

### Desktop Fallback Mode Not Working

**Symptom:** Application crashes or freezes when VR unavailable

**Solution:**
```gdscript
# Force desktop mode at startup
vr_manager.initialize_vr(false, true)  # force_vr=false, force_desktop=true

# Check current mode
if vr_manager.is_desktop_mode():
    print("Running in desktop fallback mode")
    # Desktop controls: WASD movement, mouse look, Space/Shift vertical
elif vr_manager.is_vr_active():
    print("Running in VR mode")
```

### Performance Issues in VR

**Symptom:** Low framerate, stuttering, judder

**Checklist:**
1. Check physics tick rate: Ensure 90Hz physics (Project Settings > Physics > Common > Physics Ticks Per Second = 90)
2. Disable expensive features: Reduce vignette resolution, arc resolution
3. Optimize collision detection: Use simplified collision shapes for pickable objects
4. Check shadow settings: Disable shadows on locomotion visual components
5. Verify world scale: Incorrect XRServer.world_scale can cause issues

**Performance Optimizations:**
```gdscript
# Reduce teleport arc resolution
teleport_system.arc_resolution = 16  # Default is 32

# Simplify flight physics
flight_component.exclusive = true  # Prevent multiple movement providers

# Optimize pickup detection
pickup_component.velocity_samples = 3  # Default is 5

# Reduce vignette update frequency
# In VRComfortSystem, update vignetting in _physics_process instead of _process
```

---

## Additional Resources

### Related Documentation
- **C:/Ignotus/CLAUDE.md** - Project overview and architecture
- **C:/Ignotus/docs/current/guides/DEVELOPMENT_WORKFLOW.md** - Development process
- **C:/Ignotus/CODE_QUALITY_REPORT.md** - Code quality and known issues

### Key Implementation Files
- **VRManager:** C:/Ignotus/scripts/core/vr_manager.gd
- **VRComfortSystem:** C:/Ignotus/scripts/core/vr_comfort_system.gd
- **VRTeleportation:** C:/Ignotus/scripts/player/vr_teleportation.gd
- **VR Locomotion Test:** C:/Ignotus/scenes/features/vr_locomotion_test.gd
- **godot-xr-tools:** C:/Ignotus/addons/godot-xr-tools/

### godot-xr-tools Documentation
- **GitHub:** https://github.com/GodotVR/godot-xr-tools
- **Movement Providers:** C:/Ignotus/addons/godot-xr-tools/functions/
- **Pickable Objects:** C:/Ignotus/addons/godot-xr-tools/objects/

### Testing Scenes
- **VR Main Scene:** C:/Ignotus/vr_main.tscn
- **VR Locomotion Test:** C:/Ignotus/scenes/features/vr_locomotion_test.tscn

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-12-09 | Initial comprehensive guide creation | Claude Sonnet 4.5 |

---

**End of VR Locomotion Guide**
