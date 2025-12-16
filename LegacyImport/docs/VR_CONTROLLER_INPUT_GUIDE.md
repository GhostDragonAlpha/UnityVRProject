# VR Controller Input Guide - Valve Index Controllers

**Last Updated:** 2025-12-09
**Status:** Research & Documentation
**Target Hardware:** Valve Index Controllers
**OpenXR Standard:** Yes

## Table of Contents

1. [Overview](#overview)
2. [Valve Index Controller Hardware](#valve-index-controller-hardware)
3. [Current Input Mappings](#current-input-mappings)
4. [Recommended Mappings for Space Flight](#recommended-mappings-for-space-flight)
5. [OpenXR Action Map Best Practices](#openxr-action-map-best-practices)
6. [VR Comfort Considerations](#vr-comfort-considerations)
7. [Implementation Examples](#implementation-examples)
8. [Troubleshooting](#troubleshooting)

---

## Overview

This guide documents VR controller input mappings for Valve Index controllers in the SpaceTime project. The Valve Index controllers provide industry-leading input capabilities with 87 sensors, finger tracking, force-sensitive inputs, and ergonomic design.

**Note:** Valve Index is a discontinued VR headset as of 2025, with a successor (Steam Frame) announced for early 2026. However, Valve Index controllers remain widely used and fully supported through OpenXR.

**Key References:**
- Codebase: `scripts/core/vr_manager.gd` - VR input handling with dead zones and debouncing
- Codebase: `scripts/player/pilot_controller.gd` - Spacecraft control input mapping
- Codebase: `scripts/player/vr_teleportation.gd` - VR locomotion using controller input
- Codebase: `scenes/features/vr_locomotion_test.gd` - VR flight movement test implementation

---

## Valve Index Controller Hardware

### Physical Components

The Valve Index controllers feature an exceptionally comprehensive input system:

#### Primary Inputs

1. **Thumbstick (Analog)**
   - Full 360-degree analog movement
   - Capacitive touch detection (knows when thumb is resting)
   - Clickable at all angles (newer hardware revision)
   - **Note:** Older hardware may not click if pushed too far off-center

2. **Trackpad (Capacitive/Force)**
   - Large oval button on face
   - Force sensor for pressure detection
   - Capacitive sensor for touch detection
   - Can function as: trackpad, scroll wheel, or binary button with haptics

3. **Trigger (Analog)**
   - Full pull range with analog pressure detection
   - Capacitive sensor detects touch before squeeze
   - Index finger position tracking

4. **Grip Sensors (Force-Sensitive)**
   - Force sensors tuned for wide range (light touch to firm squeeze)
   - Positioned for middle, ring, and pinky fingers
   - Natural grabbing motion detection

#### Secondary Inputs

5. **Face Buttons**
   - A/X Button (depending on hand)
   - B/Y Button (depending on hand)
   - Capacitive touch detection on each button

6. **System/Menu Button**
   - Dedicated menu/system button
   - Reserved for system functions in most applications

#### Sensor Array

**87 Sensors Total:**
- Hand position tracking
- Individual finger position tracking (thumb, index, middle, ring, pinky)
- Motion and pressure detection
- Accelerometer for additional movement tracking
- Creates accurate hand representation in VR

### Hardware Capabilities Summary

| Input | Type | Features | Touch Detection | Force Sensing |
|-------|------|----------|-----------------|---------------|
| Thumbstick | Analog 2D | 360° movement, click | Yes | No |
| Trackpad | Capacitive/Force | Multi-mode operation | Yes | Yes |
| Trigger | Analog 1D | Full pull range | Yes | No |
| Grip | Force Sensor | Variable squeeze | Yes | Yes |
| A/X Button | Digital | Binary press | Yes | No |
| B/Y Button | Digital | Binary press | Yes | No |
| System Button | Digital | Binary press | No | No |

**Sources:**
- [Valve Index Controllers Official Page](https://www.valvesoftware.com/en/index/controllers)
- [Valve Index Wikipedia](https://en.wikipedia.org/wiki/Valve_Index)
- [Valve Index Controllers In-Depth Review](https://www.liamfoot.com/valve-index-controllers-in-depth-review)

---

## Current Input Mappings

### SpaceTime Project Implementation

Based on analysis of `scripts/core/vr_manager.gd` and `scripts/player/pilot_controller.gd`:

#### VR Manager Input Processing

**Left Hand Controller:**
```gdscript
State Dictionary Keys:
- "trigger": float (0.0-1.0) - Trigger pull amount
- "grip": float (0.0-1.0) - Grip squeeze amount
- "thumbstick": Vector2 - Thumbstick position
- "button_ax": bool - A/X button state
- "button_by": bool - B/Y button state
- "button_menu": bool - Menu button state
- "thumbstick_click": bool - Thumbstick click state
```

**Right Hand Controller:**
```gdscript
State Dictionary Keys:
- "trigger": float (0.0-1.0) - Trigger pull amount
- "grip": float (0.0-1.0) - Grip squeeze amount
- "thumbstick": Vector2 - Thumbstick position
- "button_ax": bool - A/X button state
- "button_by": bool - B/Y button state
- "button_menu": bool - Menu button state
- "thumbstick_click": bool - Thumbstick click state
```

#### Dead Zone Configuration

From `scripts/core/vr_manager.gd` (lines 73-76):

```gdscript
var _deadzone_trigger: float = 0.1      # 10% dead zone for triggers
var _deadzone_grip: float = 0.1         # 10% dead zone for grip
var _deadzone_thumbstick: float = 0.15  # 15% dead zone for thumbstick
var _deadzone_enabled: bool = true
```

**Dead Zone Processing:**
- Prevents stick drift and unintentional input
- Normalizes remaining range after dead zone
- Configurable via SettingsManager
- Applied to all analog inputs (trigger, grip, thumbstick)

#### Button Debouncing

From `scripts/core/vr_manager.gd` (lines 79-80):

```gdscript
var _button_last_pressed: Dictionary = {}  # Track last press time
var _debounce_threshold_ms: float = 50.0  # 50ms debounce window
```

**Purpose:** Prevents multiple button press events within 50ms window

### Locomotion Test Scene Mappings

From `scenes/features/vr_locomotion_test.gd` (lines 36-40):

```gdscript
Controls:
- Left trigger: Toggle flight mode
- Left thumbstick: Move forward/back/strafe while in flight
- Right thumbstick: Turn left/right
- Grip buttons: Grab green cube
```

**Implementation Details:**
- Trigger uses `is_button_pressed("trigger_click")` for binary toggle
- Thumbstick uses `get_vector2("primary")` for analog movement
- Camera-relative movement (forward based on XR camera orientation)
- Continuous rotation with right thumbstick X-axis

### VR Teleportation Mappings

From `scripts/player/vr_teleportation.gd` (default configuration):

```gdscript
@export var teleport_hand: String = "left"  # Which controller triggers teleport
@export var trigger_button: String = "trigger"  # Button to hold for targeting
@export var teleport_on_release: bool = true  # Teleport when button released
@export var snap_rotation_enabled: bool = false  # Enable rotation during teleport
@export var snap_rotation_angle: float = 45.0  # Rotation increment (degrees)
```

**Teleport Controls:**
- Hold trigger: Show arc trajectory and target reticle
- Release trigger: Teleport to valid target
- Thumbstick X-axis (when snap rotation enabled): Rotate 45° increments

### Pilot Controller Mappings (Spacecraft)

From `scripts/player/pilot_controller.gd` (lines 72-78):

```gdscript
Action Mappings:
- "ax_button": "primary_action"      # A/X button - scan, interact
- "by_button": "secondary_action"    # B/Y button - menu, cancel
- "grip": "grab"                     # Grip button - grab objects
- "menu_button": "pause"             # Menu button - pause game
- "thumbstick_click": "boost"        # Thumbstick click - boost/sprint
```

**Hand Configuration (Spacecraft Flight):**
- **Left Hand:** Throttle control (trigger) + action buttons
- **Right Hand:** Rotation control (thumbstick) + action buttons
- **Grip + Thumbstick:** When grip held, thumbstick X-axis controls roll (not yaw)

**Spacecraft Controls Details:**
```gdscript
Left Hand (Throttle):
- Trigger: Forward thrust (0.0-1.0)
- Grip: (Reserved/unused in current implementation)
- A/X Button: Primary action (scan/interact)
- B/Y Button: Secondary action (menu/cancel)
- Menu Button: Pause
- Thumbstick Click: Boost

Right Hand (Rotation):
- Thumbstick Y-axis: Pitch (up/down)
- Thumbstick X-axis: Yaw (left/right turn)
- Grip + Thumbstick X-axis: Roll (barrel roll when grip held)
- Trigger: (Unused in spacecraft mode)
- A/X Button: Primary action
- B/Y Button: Secondary action
- Menu Button: Pause
- Thumbstick Click: Boost
```

---

## Recommended Mappings for Space Flight

Based on ergonomics, industry standards, and VR comfort best practices:

### Primary Flight Controls

#### Left Hand - Throttle & Power Management

| Input | Function | Reasoning |
|-------|----------|-----------|
| **Trigger** | Main Engine Throttle | Natural trigger motion for acceleration |
| **Grip** | Reverse Thrust / Brake | Squeeze to slow down, intuitive stopping |
| **Thumbstick Y** | Vertical Thrust (Up/Down) | Strafe up/down in zero-G |
| **Thumbstick X** | Lateral Thrust (Left/Right) | Strafe left/right in zero-G |
| **Thumbstick Click** | Boost / Sprint | Emergency speed increase |
| **A/X Button** | Landing Gear Toggle | Quick access for landing |
| **B/Y Button** | Flight Assist Toggle | Enable/disable stability assists |
| **Trackpad Touch** | Power Distribution UI | Slide finger to adjust power levels |
| **Trackpad Click** | Confirm Power Setting | Tactile confirmation |

#### Right Hand - Orientation & Systems

| Input | Function | Reasoning |
|-------|----------|-----------|
| **Thumbstick Y** | Pitch (Nose Up/Down) | Standard flight sim convention |
| **Thumbstick X** | Yaw (Turn Left/Right) | OR Roll when grip held |
| **Grip** | Roll Mode Toggle | Hold to convert yaw to roll |
| **Trigger** | Primary Weapon Fire | Standard VR shooter convention |
| **A/X Button** | Target Lock / Scan | Interaction with objects |
| **B/Y Button** | Cycle Targets | Navigation through UI |
| **Thumbstick Click** | Reset Orientation | Center view/orientation |
| **Trackpad Touch** | Systems Menu | Access to ship systems |
| **Trackpad Click** | Confirm Selection | Menu navigation |

### Alternative "HOTAS-Style" Mapping

For users familiar with flight simulators (Hands On Throttle And Stick):

#### Left Hand = Throttle Quadrant

| Input | Function | Reasoning |
|-------|----------|-----------|
| **Trigger (Full Pull)** | Main Throttle 0-100% | Analog throttle like real aircraft |
| **Trigger (Touch Only)** | Throttle Active Indicator | Capacitive touch for UI feedback |
| **Grip** | Afterburner / Boost | Squeeze for extra thrust |
| **Thumbstick** | Lateral/Vertical Thrusters | Translation controls (strafe) |
| **Thumbstick Click** | Reset Throttle to 50% | Quick neutral throttle |
| **A/X Button** | Previous Target | Target cycling |
| **B/Y Button** | Next Target | Target cycling |
| **Menu Button** | Power Management Menu | System controls |

#### Right Hand = Flight Stick

| Input | Function | Reasoning |
|-------|----------|-----------|
| **Thumbstick Y** | Pitch (Elevator) | Standard flight stick |
| **Thumbstick X** | Roll (Aileron) | Standard flight stick |
| **Grip** | Yaw Mode | Hold for rudder control |
| **Trigger** | Primary Weapon | Trigger = fire (universal) |
| **A/X Button** | Secondary Weapon | Alternative fire mode |
| **B/Y Button** | Countermeasures | Flares/chaff deployment |
| **Thumbstick Click** | Weapon Group Cycle | Switch weapon systems |
| **Menu Button** | Quick Menu | In-flight menu access |

### Comfort-First Mapping (Recommended for VR)

Optimized for minimal fatigue and motion sickness:

| Input | Function | Comfort Benefit |
|-------|----------|-----------------|
| **Left Trigger** | Gradual Acceleration | Smooth, predictable motion |
| **Right Thumbstick** | Snap Turn (45° increments) | Reduces motion sickness from smooth turning |
| **Grip (Both)** | "Dead Man's Switch" | Stop all input when released (safety) |
| **Thumbstick Click** | Toggle Flight Assist | Stability mode for new VR users |
| **Menu Button** | Emergency Stop | Instant velocity zero for comfort |
| **Both Grips Held** | "Pro Mode" - Disable Assists | Expert users can hold grips for full manual control |

### Haptic Feedback Recommendations

From `scripts/core/vr_manager.gd` and VR comfort best practices:

1. **Trigger Haptics:**
   - Light pulse when trigger touch detected
   - Increasing vibration as trigger pull increases
   - Strong pulse at full throttle

2. **Grip Haptics:**
   - Pulse on grip engage/release
   - Continuous light vibration while gripping (tactile feedback)

3. **Button Haptics:**
   - Single sharp pulse on button press
   - Different pulse patterns for different actions (confirmation vs. warning)

4. **Collision/Impact Haptics:**
   - Strong pulse on collision
   - Duration and intensity based on impact force
   - Both controllers vibrate for hull impacts

5. **System Status Haptics:**
   - Warning pulse pattern for low fuel/shields
   - Rhythmic pulse for incoming target lock
   - Emergency pattern for critical damage

**Implementation:** Use `HapticManager.trigger_haptic(hand, intensity, duration)` from `scripts/core/vr_manager.gd`

---

## OpenXR Action Map Best Practices

### Godot-Specific Recommendations

Based on official Godot documentation and OpenXR standards:

#### 1. Use Semantic Actions (Not Hardware-Specific)

**Bad Example (Hardware-Specific):**
```gdscript
# DON'T DO THIS - ties to specific button
if controller.is_button_pressed("a_button"):
    scan_target()
```

**Good Example (Semantic Action):**
```gdscript
# DO THIS - semantic action that can be remapped
if Input.is_action_pressed("scan_target"):
    scan_target()
```

**Reasoning:** OpenXR runtimes handle remapping semantic actions to actual hardware buttons. This allows:
- User customization per controller type
- Automatic adaptation for different VR headsets
- Better accessibility support
- Runtime can make smarter decisions than hardcoded mappings

#### 2. Only Map Controllers You've Tested

From OpenXR Working Group recommendation:

> "Only bindings for controllers actually tested by the developer should be setup. The XR runtimes are designed with this in mind and can perform a better job of rebinding a provided binding than a developer can make educated guesses."

**Implementation:**
- Test with actual Valve Index controllers
- Don't create "guessed" mappings for untested hardware
- Let OpenXR runtime handle fallbacks

#### 3. Action Map System Architecture

From `docs.godotengine.org/en/stable/tutorials/xr/xr_action_map.html`:

**How It Works:**
1. Define semantic actions in your action map (e.g., "throttle_increase", "fire_weapon")
2. Map these actions to controller inputs (trigger, thumbstick, etc.)
3. Send action map to OpenXR runtime as a "blueprint"
4. Runtime performs actual input mapping and handles variations

**Code Example (from Godot XR Tools pattern):**

```gdscript
# In your action map configuration:
Actions:
  - Name: "throttle_increase"
    Type: "float"
    Paths: ["/user/hand/left/input/trigger/value"]

  - Name: "ship_rotation"
    Type: "vector2"
    Paths: ["/user/hand/right/input/thumbstick"]

  - Name: "fire_weapon"
    Type: "boolean"
    Paths: ["/user/hand/right/input/trigger/click"]
```

#### 4. Subscribe to Controller Events

From `scripts/core/vr_manager.gd` implementation pattern:

```gdscript
# Connect to XRController3D signals
controller.button_pressed.connect(_on_controller_button_pressed)
controller.button_released.connect(_on_controller_button_released)
controller.input_float_changed.connect(_on_controller_float_changed)
controller.input_vector2_changed.connect(_on_controller_vector2_changed)

func _on_controller_float_changed(action_name: String, value: float):
    # action_name comes from your OpenXR Action Map
    # Example: "throttle", "trigger", "grip"
    match action_name:
        "throttle":
            spacecraft.set_throttle(value)
        "grip":
            handle_grip_input(value)
```

#### 5. Implement Proper Dead Zones

From `scripts/core/vr_manager.gd` (lines 717-757):

**Scalar Dead Zone (Triggers, Grip):**
```gdscript
func _apply_deadzone(value: float, threshold: float) -> float:
    value = clamp(value, 0.0, 1.0)
    if abs(value) < threshold:
        return 0.0
    # Normalize remaining range (threshold to 1.0 maps to 0.0 to 1.0)
    return (value - threshold) / (1.0 - threshold)
```

**Vector Dead Zone (Thumbstick):**
```gdscript
func _apply_deadzone_vector2(value: Vector2, threshold: float) -> Vector2:
    var magnitude: float = value.length()
    if magnitude < threshold:
        return Vector2.ZERO
    var direction: Vector2 = value.normalized()
    var scaled_magnitude: float = (magnitude - threshold) / (1.0 - threshold)
    return direction * scaled_magnitude
```

**Benefits:**
- Prevents drift from worn controllers
- Makes input feel more responsive at edge of dead zone
- Normalizes input range after dead zone removal

#### 6. Implement Button Debouncing

From `scripts/core/vr_manager.gd` (lines 759-776):

```gdscript
var _debounce_threshold_ms: float = 50.0  # 50ms window
var _button_last_pressed: Dictionary = {}

func _debounce_button(button_id: String, is_pressed: bool) -> bool:
    var current_time_ms: int = Time.get_ticks_msec()
    var last_press_time: int = _button_last_pressed.get(button_id, -10000)

    if not is_pressed:
        return false

    # Check if enough time has passed since last press
    if (current_time_ms - last_press_time) >= _debounce_threshold_ms:
        _button_last_pressed[button_id] = current_time_ms
        return true

    return false  # Still within debounce window
```

**Purpose:** Prevents accidental double-presses from mechanical bounce

---

## VR Comfort Considerations

### Motion Sickness Prevention

Based on VR comfort system in `scripts/core/vr_comfort_system.gd`:

#### 1. Snap Turning vs. Smooth Turning

**Snap Turning (Recommended for Comfort):**
```gdscript
# From vr_teleportation.gd implementation
@export var snap_rotation_enabled: bool = true
@export var snap_rotation_angle: float = 45.0  # Degrees per snap

# Rotate in discrete increments
if thumbstick.x > 0.7:
    xr_origin.rotate_y(deg_to_rad(snap_rotation_angle))
```

**Benefits:**
- Reduces motion sickness by 60-80% compared to smooth turning
- No visual-vestibular conflict
- Instant orientation change

**When to Use Smooth Turning:**
- Expert users who request it
- Provide toggle in settings
- Start with snap turning by default

#### 2. Vignette Effect During Movement

**Purpose:** Reduces peripheral vision during motion to prevent sickness

**Implementation Pattern:**
```gdscript
# Apply vignette when moving fast
var speed_fraction = velocity.length() / max_speed
var vignette_intensity = clamp(speed_fraction * 0.7, 0.0, 0.7)
vr_comfort_system.set_vignette_intensity(vignette_intensity)
```

**Best Practice:**
- Fade in vignette gradually (not instant)
- Keep center vision clear
- Stronger effect at higher speeds

#### 3. Cockpit Frame of Reference

**Cockpit Benefits:**
- Stationary reference frame reduces sickness
- Provides visual anchor during movement
- Especially important for space flight (no ground reference)

**Implementation:**
- Always render visible cockpit elements
- Include stationary HUD elements
- Dashboard/instrument panel provides grounding

#### 4. Acceleration Limits

**Recommendation for VR:**
```gdscript
# Limit acceleration to comfortable levels
const MAX_COMFORTABLE_ACCELERATION = 5.0  # units/s²
const MAX_COMFORTABLE_ROTATION_SPEED = 45.0  # deg/s

# Smooth acceleration curve
var target_throttle = 1.0
var actual_throttle = lerp(current_throttle, target_throttle, delta * 2.0)
```

**Principles:**
- Gradual acceleration (not instant)
- Cap maximum rotation speed
- Use lerp/smoothing for all movement changes

#### 5. Flight Assist Mode

**Purpose:** Help new VR users maintain orientation and stability

**Features:**
```gdscript
# Auto-level spacecraft when no input
if flight_assist_enabled and rotation_input.length() < 0.1:
    # Gradually level to horizon
    var up_direction = Vector3.UP
    var current_up = spacecraft.global_transform.basis.y
    var correction = current_up.lerp(up_direction, delta * 0.5)
    spacecraft.global_transform.basis.y = correction
    spacecraft.global_transform = spacecraft.global_transform.orthonormalized()
```

**Toggleable via button** (default: ON for new users)

### Ergonomics & Fatigue Prevention

#### 1. Neutral Hand Position

**Problem:** Holding controllers with arms extended causes fatigue

**Solutions:**
- Design for hands at sides or chest level
- No required sustained grip pressure
- Trigger activation should work at partial pull

#### 2. "Gorilla Arm" Prevention

**Avoid:**
- Requiring extended arm positions
- Holding arms raised for long periods
- Precise aiming while standing

**Prefer:**
- Seated gameplay option
- Controls work with arms relaxed
- Large hit boxes for UI interaction

#### 3. Haptic Feedback Intensity

**Guidelines:**
- Light haptics for frequent events (movement, UI)
- Medium haptics for important events (collisions)
- Strong haptics for critical events (damage, alerts)
- **Never:** Constant vibration (causes numbness)

**Implementation:**
```gdscript
# Light haptic for UI hover
haptic_manager.trigger_haptic("right", 0.2, 0.05)  # 20% intensity, 50ms

# Medium haptic for button press
haptic_manager.trigger_haptic("left", 0.5, 0.1)  # 50% intensity, 100ms

# Strong haptic for collision
haptic_manager.trigger_haptic("both", 0.8, 0.3)  # 80% intensity, 300ms
```

#### 4. Session Length Warnings

**Recommendation:**
- 30-minute play sessions for new VR users
- 60-90 minute sessions for experienced users
- Prompt user to take breaks
- Save progress frequently

### Accessibility Considerations

#### 1. Customizable Dead Zones

From `scripts/core/vr_manager.gd`:

```gdscript
# Allow users to adjust dead zones
func set_deadzone(trigger: float, grip: float, thumbstick: float):
    _deadzone_trigger = clamp(trigger, 0.0, 0.5)
    _deadzone_grip = clamp(grip, 0.0, 0.5)
    _deadzone_thumbstick = clamp(thumbstick, 0.0, 0.5)
```

**Why:** Users with tremors or reduced fine motor control benefit from larger dead zones

#### 2. Hand Swapping

From `scripts/player/pilot_controller.gd`:

```gdscript
# Allow swapping throttle/rotation hands
func swap_hands() -> void:
    var temp = throttle_hand
    throttle_hand = rotation_hand
    rotation_hand = temp
```

**Why:** Accommodates left-handed users and injury compensation

#### 3. One-Handed Mode

**Implementation:**
```gdscript
# Combine throttle and rotation on single hand
if one_handed_mode:
    # Trigger = throttle
    # Thumbstick = rotation
    # Grip + Thumbstick = secondary controls
```

#### 4. Desktop Fallback

From `scripts/core/vr_manager.gd` (lines 324-352):

**Always provide keyboard/mouse controls:**
- VR hardware may malfunction
- Users may get motion sick
- Accessibility requirement
- Development/testing convenience

---

## Implementation Examples

### Example 1: Basic Controller Input

```gdscript
extends Node3D

@onready var vr_manager = get_node("/root/ResonanceEngine/VRManager")
@onready var spacecraft = $Spacecraft

func _process(delta: float) -> void:
    if vr_manager and vr_manager.is_vr_active():
        # Get left controller state for throttle
        var left_state = vr_manager.get_controller_state("left")
        var throttle = left_state.get("trigger", 0.0)

        # Get right controller state for rotation
        var right_state = vr_manager.get_controller_state("right")
        var thumbstick = right_state.get("thumbstick", Vector2.ZERO)

        # Apply to spacecraft
        spacecraft.set_throttle(throttle)
        spacecraft.apply_rotation(thumbstick.y, thumbstick.x, 0.0)
```

### Example 2: Action Button Handling

```gdscript
extends Node

var vr_manager: VRManager
var _boost_active: bool = false

func _ready():
    vr_manager = get_node("/root/ResonanceEngine/VRManager")
    vr_manager.controller_button_pressed.connect(_on_button_pressed)
    vr_manager.controller_button_released.connect(_on_button_released)

func _on_button_pressed(hand: String, button: String):
    match button:
        "ax_button":
            scan_target()
        "by_button":
            open_menu()
        "primary_click":  # Thumbstick click
            activate_boost()

func _on_button_released(hand: String, button: String):
    if button == "primary_click":
        deactivate_boost()
```

### Example 3: Grip-Modified Controls

```gdscript
# From pilot_controller.gd pattern
func _process_rotation_input(controller_state: Dictionary) -> void:
    var thumbstick = controller_state.get("thumbstick", Vector2.ZERO)
    var grip_value = controller_state.get("grip", 0.0)

    var pitch = thumbstick.y
    var yaw = 0.0
    var roll = 0.0

    if grip_value > 0.5:
        # Grip held: thumbstick X controls roll
        roll = thumbstick.x
    else:
        # Grip not held: thumbstick X controls yaw
        yaw = thumbstick.x

    spacecraft.apply_rotation(pitch, yaw, roll)
```

### Example 4: Haptic Feedback

```gdscript
extends Spacecraft

var haptic_manager: HapticManager

func fire_weapon():
    # Visual/gameplay effects
    spawn_projectile()

    # Haptic feedback on firing hand
    if haptic_manager:
        haptic_manager.trigger_haptic("right", 0.6, 0.15)

func take_damage(amount: float):
    # Visual effects
    show_damage_indicator()

    # Haptic feedback - both controllers
    if haptic_manager:
        var intensity = clamp(amount / 100.0, 0.3, 1.0)
        haptic_manager.trigger_haptic("left", intensity, 0.2)
        haptic_manager.trigger_haptic("right", intensity, 0.2)
```

### Example 5: Comfort-Focused Movement

```gdscript
extends Node3D

@export var snap_turn_angle: float = 45.0
@export var vignette_enabled: bool = true

var last_thumbstick_x: float = 0.0
var vr_comfort_system: VRComfortSystem

func _process_rotation(thumbstick: Vector2, delta: float):
    # Snap turning for comfort
    if abs(thumbstick.x) > 0.7:
        # Only turn on threshold cross (not continuous)
        if abs(last_thumbstick_x) <= 0.7:
            var direction = sign(thumbstick.x)
            xr_origin.rotate_y(deg_to_rad(snap_turn_angle * direction))

            # Brief haptic pulse on snap
            haptic_manager.trigger_haptic("right", 0.3, 0.05)

    last_thumbstick_x = thumbstick.x

    # Apply vignette based on movement speed
    if vignette_enabled and vr_comfort_system:
        var speed = linear_velocity.length()
        var vignette_amount = clamp(speed / 20.0, 0.0, 0.7)
        vr_comfort_system.set_vignette_intensity(vignette_amount)
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Controller Input Not Detected

**Symptoms:**
- `get_controller_state()` returns empty dictionary
- No button presses registered
- Thumbstick always returns `Vector2.ZERO`

**Solutions:**

1. **Check VR Initialization:**
```gdscript
# In console, verify:
[VRManager] VR mode initialized successfully
[VRManager] Tracker added: left_hand
[VRManager] Tracker added: right_hand
```

2. **Verify Controller Connection:**
```gdscript
if vr_manager:
    print("Left connected: ", vr_manager.is_controller_connected("left"))
    print("Right connected: ", vr_manager.is_controller_connected("right"))
```

3. **Check OpenXR Runtime:**
- SteamVR must be running
- Controllers paired and powered on
- Check SteamVR controller bindings

#### Issue: Stick Drift / Unintended Movement

**Symptoms:**
- Spacecraft rotates when thumbstick is released
- Slight movement without input

**Solutions:**

1. **Increase Dead Zone:**
```gdscript
vr_manager.set_deadzone(
    trigger = 0.15,     # 15% dead zone
    grip = 0.15,
    thumbstick = 0.20   # 20% dead zone for worn stick
)
```

2. **Check Controller Calibration in SteamVR:**
- Open SteamVR Settings
- Devices > Controller Settings > Calibrate
- Test with SteamVR controller test

#### Issue: Double Button Presses

**Symptoms:**
- Single button press triggers action twice
- Menu selections activate incorrectly

**Solutions:**

1. **Verify Debouncing is Enabled:**
```gdscript
# Check in VR manager initialization
print("Debounce threshold: ", vr_manager._debounce_threshold_ms)
```

2. **Increase Debounce Time:**
```gdscript
vr_manager.set_debounce_threshold(100.0)  # Increase to 100ms
```

3. **Check Event Connection:**
```gdscript
# Don't connect to same signal multiple times
if not vr_manager.controller_button_pressed.is_connected(_on_button):
    vr_manager.controller_button_pressed.connect(_on_button)
```

#### Issue: Grip Not Working

**Symptoms:**
- `grip` value always 0.0
- Grab actions don't trigger

**Solutions:**

1. **Check Input Name:**
```gdscript
# Try alternative names
var grip_value = state.get("grip", 0.0)
if grip_value == 0.0:
    grip_value = state.get("squeeze", 0.0)  # Some systems use "squeeze"
```

2. **Check Force Threshold:**
```gdscript
# Grip may need firmer squeeze
if grip_value > 0.3:  # Lower threshold
    handle_grip_input()
```

#### Issue: Thumbstick Click Not Detected

**Symptoms:**
- Thumbstick movement works
- Click/press not registering

**Solutions:**

1. **Check Multiple Input Names:**
```gdscript
# Different systems use different names
var click = state.get("thumbstick_click", false)
if not click:
    click = state.get("primary_click", false)
if not click:
    click = state.get("joystick_click", false)
```

2. **Hardware Issue (Older Valve Index):**
- Older controllers may not click off-center
- Keep thumbstick centered when clicking
- Consider using touch detection instead of click

#### Issue: VR Controls Not Working in Exported Build

**Symptoms:**
- Works in editor
- Fails in exported .exe

**Solutions:**

1. **Enable HTTP API in Release:**
```bash
# Set environment variable before running
set GODOT_ENABLE_HTTP_API=true
SpaceTime.exe
```

2. **Check Export Settings:**
- Project > Export > Resources
- Ensure OpenXR plugin is included
- Verify `project.godot` includes OpenXR enabled

3. **Check Console Output:**
```bash
# Run with console to see errors
Godot_v4.5.1-stable_win64_console.exe --path . build/SpaceTime.exe
```

---

## References and Resources

### Official Documentation

- [Godot XR Action Map Documentation](https://docs.godotengine.org/en/stable/tutorials/xr/xr_action_map.html)
- [Godot OpenXR Settings](https://docs.godotengine.org/en/stable/tutorials/xr/openxr_settings.html)
- [Unity OpenXR Valve Index Profile](https://docs.unity3d.com/Packages/com.unity.xr.openxr@1.10/manual/features/valveindexcontrollerprofile.html)

### Hardware Specifications

- [Valve Index Controllers Official Page](https://www.valvesoftware.com/en/index/controllers)
- [Valve Index Wikipedia](https://en.wikipedia.org/wiki/Valve_Index)
- [Valve Index Controllers In-Depth Review](https://www.liamfoot.com/valve-index-controllers-in-depth-review)
- [Steam Community Valve Index Controls Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2207459689)

### Community Resources

- [GitHub: XR Input Events for Action Bindings Discussion](https://github.com/godotengine/godot-proposals/issues/2389)
- [GitHub: Controller Mappings Issue](https://github.com/GodotVR/godot_openxr/issues/99)
- [GitHub: Default OpenXR Action Map Proposals](https://github.com/godotengine/godot-proposals/issues/5951)

### SpaceTime Codebase References

- `scripts/core/vr_manager.gd` - Core VR input handling with dead zones and debouncing
- `scripts/player/pilot_controller.gd` - Spacecraft control mapping and input processing
- `scripts/player/vr_teleportation.gd` - VR-friendly locomotion system
- `scripts/core/vr_comfort_system.gd` - VR comfort features (vignette, snap turns)
- `scenes/features/vr_locomotion_test.gd` - VR flight movement test implementation

---

**Document Status:** Research & Documentation Complete
**Next Steps:**
- Test mappings with actual Valve Index hardware
- Gather user feedback on control schemes
- Iterate based on playtesting results
- Create in-game control remapping UI

**Last Updated:** 2025-12-09
**Maintained By:** SpaceTime VR Development Team
