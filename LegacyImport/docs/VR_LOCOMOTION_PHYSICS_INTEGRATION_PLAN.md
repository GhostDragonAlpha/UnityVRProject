# VR Locomotion with Realistic Planetary Physics - Integration Plan

## Executive Summary

This document outlines a comprehensive plan for integrating VR locomotion controls with the realistic planetary physics system in SpaceTime. The design balances immersive VR locomotion methods with scientifically accurate planetary rotation, gravity, and reference frames, ensuring walking only works when grounded.

**Key Design Decisions:**
- **Primary locomotion method**: Smooth locomotion with comfort features (vignette, snap turns)
- **Secondary method**: Teleport locomotion for maximum VR comfort (optional)
- **Planetary reference frame**: Surface-relative (player moves with rotating planet)
- **Movement constraint**: Walking only enabled when grounded (jetpack for aerial movement)
- **Physics integration**: CharacterBody3D with custom gravity and surface normal alignment

---

## 1. VR Locomotion Methods Research

### 1.1 Standard VR Locomotion Approaches

Based on VR locomotion research and industry standards:

#### A. Smooth Locomotion (Recommended Primary)
**Description**: Continuous movement via controller thumbstick, similar to traditional FPS games.

**Advantages:**
- Natural and intuitive for experienced VR users
- Precise control over movement direction and speed
- Works well with planetary rotation (player maintains orientation)
- Already partially implemented in `WalkingController`

**Disadvantages:**
- Can cause motion sickness in susceptible users
- Requires VR comfort features (vignette, snap turns)

**Implementation Status**: ✅ Already implemented in `walking_controller.gd`
- Left thumbstick for movement
- Right thumbstick for snap turning (45° increments)
- Sprint toggle via thumbstick click

#### B. Teleport Locomotion (Recommended Secondary)
**Description**: Point controller to aim, press button to instantly teleport to target location.

**Advantages:**
- Minimal motion sickness (instant position change)
- Good for users with low VR tolerance
- Works well with rotating planets (maintains relative position)

**Disadvantages:**
- Less immersive than smooth locomotion
- Can feel disorienting on curved planetary surfaces
- Requires valid ground detection and arc projection

**Implementation Status**: ❌ Not yet implemented
**Priority**: Medium (alternative comfort option)

#### C. Arm-Swinger Locomotion
**Description**: Swing arms to simulate walking motion.

**Advantages:**
- Physical engagement reduces motion sickness
- Natural walking simulation

**Disadvantages:**
- Tiring for extended play
- Less precise than thumbstick control
- Awkward on rotating surfaces

**Recommendation**: ❌ Not suitable for this project

#### D. Room-Scale Walking
**Description**: Physical movement in real space translates to game movement.

**Advantages:**
- Most natural VR experience
- Zero motion sickness

**Disadvantages:**
- Limited by physical play space
- Requires boundary system
- Impractical for planetary exploration

**Recommendation**: ✅ Support as complement (small-scale adjustments)

### 1.2 VR Comfort Features

Critical for reducing motion sickness during smooth locomotion:

#### Vignette Effect (FOV Reduction)
- Darken peripheral vision during movement
- Reduces optical flow perception
- **Status**: ✅ Planned in `VRComfortSystem`
- **Implementation**: Shader-based vignette that intensifies with movement speed

#### Snap Turning
- Discrete rotation increments (typically 22.5°, 45°, or 90°)
- Avoids continuous rotation (major motion sickness trigger)
- **Status**: ✅ Already implemented (45° increments)
- **Implementation**: Right thumbstick horizontal input

#### Independent Head Movement
- Player head can move independently of body direction
- Camera follows HMD tracking, not thumbstick direction
- **Status**: ✅ Inherent in VR system (XRCamera3D tracks HMD)

#### Stable Reference Points
- Keep cockpit/UI elements visible during movement
- Provides visual anchor for inner ear
- **Status**: Partial (cockpit visible in spacecraft mode)
- **Enhancement needed**: Consider HUD elements as reference during walking

---

## 2. Planetary Physics Integration

### 2.1 Current Physics System

From analysis of `orbital_mechanics.gd`, `relativity.gd`, and `walking_controller.gd`:

**Gravity System:**
```gdscript
# Newton's law of universal gravitation
g = G * M / R²

Where:
- G = 6.67430e-11 (gravitational constant)
- M = planet mass (kg)
- R = planet radius (m)
```

**Current Implementation:**
- Surface gravity: 0.1 - 50.0 m/s² (clamped for gameplay)
- Gravity direction: Always points toward planet center
- Applied in `_physics_process()` via CharacterBody3D velocity

**Status**: ✅ Already correctly implemented

### 2.2 Planetary Rotation

**Critical Question**: Does the planet surface rotate in world space?

**Current State Analysis:**
```gdscript
# From walking_controller.gd line 248-253
# Update gravity direction every frame (pulls toward planet center)
if current_planet:
    var to_planet = current_planet.global_position - global_position
    if to_planet.length() > 0:
        gravity_direction = to_planet.normalized()
        # DISABLED: Surface alignment causing orientation issues
        # align_to_planet_surface(delta)
```

**Key Findings:**
1. Surface alignment is **disabled** (commented out)
2. Gravity direction updates dynamically
3. CharacterBody3D position is in **world space**
4. Planet likely rotates in world space (realistic simulation)

**Implication**: Player needs to move with rotating surface to maintain position.

### 2.3 Reference Frame Design Decision

**Option A: World-Fixed Frame** (Not Recommended)
- Player stays at fixed world coordinates
- Planet rotates beneath player
- Player would drift relative to surface features

**Option B: Surface-Relative Frame** (Recommended ✅)
- Player moves with rotating planet surface
- Maintains relative position to surface features
- Natural for walking experience

**Implementation Strategy:**

```gdscript
# Pseudo-code for surface-relative movement
func _physics_process(delta: float) -> void:
    # 1. Get planet's rotation this frame
    var planet_angular_velocity = current_planet.get_angular_velocity()
    var radius_vector = global_position - current_planet.global_position
    var surface_velocity = planet_angular_velocity.cross(radius_vector)

    # 2. Apply surface velocity to maintain relative position
    velocity += surface_velocity

    # 3. Apply player movement (relative to surface)
    var input_dir = get_movement_input()
    var surface_relative_movement = calculate_surface_movement(input_dir)
    velocity += surface_relative_movement

    # 4. Apply gravity (toward planet center)
    if not is_on_floor():
        velocity += gravity_direction * current_gravity * delta

    # 5. Move character
    move_and_slide()
```

**Key Requirements:**
- `CelestialBody` must expose `get_angular_velocity()` method
- Angular velocity should be in radians/second
- Surface velocity calculated using cross product: ω × r

### 2.4 Surface Normal Alignment

**Current Status**: Disabled due to orientation issues

**Problem**: Direct alignment causes jittering/instability

**Solution**: Smooth interpolated alignment with configurable speed

```gdscript
# Improved version of align_to_planet_surface()
func align_to_planet_surface(delta: float) -> void:
    # Target "up" direction (away from planet center)
    var target_up = -gravity_direction

    # Use quaternion slerp for smooth rotation
    var current_rotation = Quaternion(transform.basis)
    var target_rotation = _build_aligned_rotation(target_up)

    # Smooth interpolation with configurable speed
    var alignment_speed = 3.0  # Adjust for stability vs responsiveness
    var t = min(alignment_speed * delta, 1.0)

    var new_rotation = current_rotation.slerp(target_rotation, t)
    transform.basis = Basis(new_rotation)

func _build_aligned_rotation(up_direction: Vector3) -> Quaternion:
    # Build rotation that aligns Y-axis with up_direction
    # While preserving player's forward facing direction
    var forward = -transform.basis.z
    forward = forward - forward.project(up_direction)  # Project to surface plane
    forward = forward.normalized()

    var right = forward.cross(up_direction).normalized()
    forward = up_direction.cross(right).normalized()

    var aligned_basis = Basis(right, up_direction, -forward)
    return Quaternion(aligned_basis)
```

**Testing Priority**: High (re-enable with improved implementation)

---

## 3. Controller Input to CharacterBody3D Movement

### 3.1 Current Input Mapping

**VR Controllers** (from `walking_controller.gd`):

| Input | Controller | Action | Status |
|-------|-----------|--------|--------|
| Movement | Left thumbstick | WASD-style movement | ✅ Implemented |
| Sprint | Left thumbstick click | Increase speed 2x | ✅ Implemented |
| Snap turn | Right thumbstick X-axis | Rotate 45° | ✅ Implemented |
| Jump | Right A button | Vertical velocity | ✅ Implemented |
| Jetpack | Right grip button | Upward thrust | ✅ Implemented |
| Interact | Right B button | Return to spacecraft | ✅ Implemented |

**Desktop Fallback**:

| Input | Key/Mouse | Action | Status |
|-------|----------|--------|--------|
| Movement | W/A/S/D | WASD-style movement | ✅ Implemented |
| Look | Mouse | Camera rotation | ✅ Implemented |
| Sprint | Shift | Increase speed | ✅ Implemented |
| Jump | Space | Vertical velocity | ✅ Implemented |
| Interact | E | Return to spacecraft | ✅ Implemented |

### 3.2 Movement Direction Calculation

**Current Implementation** (lines 354-395):
```gdscript
func calculate_movement_direction(input: Vector2) -> Vector3:
    # Gets camera transform (HMD pose in VR, desktop camera otherwise)
    var camera_transform = vr_manager.get_hmd_pose()

    # Forward/right vectors relative to camera facing
    var forward = -camera_transform.basis.z
    var right = camera_transform.basis.x

    # Project to horizontal plane (ignore Y component)
    forward.y = 0
    right.y = 0
    forward = forward.normalized()
    right = right.normalized()

    # Combine input with camera orientation
    var direction = (forward * -input.y + right * input.x)
    return direction.normalized()
```

**Issue**: Does not account for planetary surface curvature or rotation

**Improved Implementation**:
```gdscript
func calculate_movement_direction(input: Vector2) -> Vector3:
    if input == Vector2.ZERO:
        return Vector3.ZERO

    # Get camera transform
    var camera_transform = vr_manager.get_hmd_pose()

    # Get surface tangent plane (perpendicular to gravity)
    var surface_normal = -gravity_direction

    # Project camera forward onto surface tangent plane
    var camera_forward = -camera_transform.basis.z
    var surface_forward = camera_forward - camera_forward.project(surface_normal)

    # Handle edge case: looking straight up/down
    if surface_forward.length_squared() < 0.001:
        surface_forward = transform.basis.z  # Use body forward
    else:
        surface_forward = surface_forward.normalized()

    # Calculate right vector on surface
    var surface_right = surface_forward.cross(surface_normal).normalized()

    # Recalculate forward to ensure orthogonality
    surface_forward = surface_normal.cross(surface_right).normalized()

    # Combine input with surface-aligned directions
    var direction = (surface_forward * -input.y + surface_right * input.x)

    return direction.normalized()
```

**Benefits:**
- Movement always tangent to planetary surface
- No "climbing" when looking up/down
- Correct behavior on curved surfaces
- Maintains intuitive camera-relative controls

### 3.3 Speed and Acceleration

**Current Values**:
- Walk speed: 3.0 m/s
- Sprint speed: 6.0 m/s
- Jump velocity: 4.0 m/s

**Proposed Enhancement**: Scale with local gravity

```gdscript
func calculate_adjusted_speeds():
    # Earth gravity reference
    const EARTH_GRAVITY = 9.8

    # Scale speeds by gravity ratio
    var gravity_ratio = current_gravity / EARTH_GRAVITY

    # Walking feels same relative to local gravity
    var adjusted_walk = walk_speed * sqrt(gravity_ratio)
    var adjusted_sprint = sprint_speed * sqrt(gravity_ratio)
    var adjusted_jump = jump_velocity * sqrt(gravity_ratio)

    return {
        "walk": adjusted_walk,
        "sprint": adjusted_sprint,
        "jump": adjusted_jump
    }
```

**Rationale**:
- Low gravity → longer strides, higher jumps (like Moon walking)
- High gravity → shorter strides, lower jumps
- Square root scaling maintains similar traversal time

---

## 4. Grounded-Only Walking Constraint

### 4.1 Ground Detection System

**Current Implementation** (lines 98-107, 459-462):

```gdscript
# Setup
func setup_ground_raycast() -> void:
    ground_raycast = RayCast3D.new()
    ground_raycast.target_position = Vector3(0, -2.0, 0)  # Cast 2m down
    ground_raycast.enabled = true
    ground_raycast.collide_with_areas = false
    ground_raycast.collide_with_bodies = true
    add_child(ground_raycast)

# Update
func update_ground_detection() -> void:
    if ground_raycast:
        is_on_ground = ground_raycast.is_colliding()
```

**Current Issues**:
1. Redundant with `CharacterBody3D.is_on_floor()`
2. Custom `is_on_ground` not consistently used
3. Ray length (2m) may be too short for high-speed movement

**Improved Implementation**:

```gdscript
## Ground detection with multiple methods for reliability
func update_ground_detection() -> void:
    # Method 1: CharacterBody3D built-in (most reliable)
    var cb_grounded = is_on_floor()

    # Method 2: Raycast (for prediction/future ground)
    var ray_grounded = false
    if ground_raycast and ground_raycast.is_colliding():
        var hit_distance = ground_raycast.get_collision_point().distance_to(global_position)
        ray_grounded = hit_distance < 1.0  # Within 1m = grounded

    # Method 3: Vertical velocity check (falling fast = not grounded)
    var velocity_check = velocity.dot(gravity_direction) > -10.0  # Not falling fast

    # Combine all methods (AND logic for strict grounding)
    is_on_ground = cb_grounded or (ray_grounded and velocity_check)

    # Debug visualization in editor
    if OS.is_debug_build():
        _debug_draw_ground_state()
```

### 4.2 Movement Constraints

**Rule**: Walking input only applies when grounded. In air, only jetpack thrust applies.

```gdscript
func _physics_process(delta: float) -> void:
    # ... existing gravity and jetpack code ...

    # Get movement input
    var input_dir = get_movement_input()

    # Calculate movement direction
    var direction = calculate_movement_direction(input_dir)

    # **NEW: Only apply movement when grounded**
    if is_on_ground and direction != Vector3.ZERO:
        var speed = sprint_speed if is_sprinting() else walk_speed

        # Apply movement (horizontal only)
        velocity = velocity.project(gravity_direction)  # Keep vertical component
        velocity += direction * speed  # Add horizontal movement

        # Apply surface velocity to move with planet
        if current_planet and current_planet.has_method("get_angular_velocity"):
            var ang_vel = current_planet.get_angular_velocity()
            var radius = global_position - current_planet.global_position
            var surface_vel = ang_vel.cross(radius)
            velocity += surface_vel
    else:
        # In air: no horizontal control (except jetpack which is separate)
        # Apply air friction (very light)
        var horizontal_vel = velocity - velocity.project(gravity_direction)
        horizontal_vel *= 0.99  # 1% friction per frame
        velocity = velocity.project(gravity_direction) + horizontal_vel

    # Move the character
    move_and_slide()
```

### 4.3 Jetpack System Integration

**Current Implementation**: Jetpack provides upward thrust when grip pressed (lines 265-280)

**Enhancement**: Jetpack becomes primary aerial movement

```gdscript
# Low-gravity threshold determines flight mode
@export var low_gravity_threshold: float = 5.0  # Below 5 m/s² = flight mode

func _physics_process(delta: float) -> void:
    # Determine if in low-gravity flight mode
    is_in_flight_mode = current_gravity < low_gravity_threshold

    # In flight mode: jetpack provides directional thrust
    if is_in_flight_mode and not is_on_ground:
        # Jetpack thrust in direction of movement input
        if jetpack_enabled and is_jetpack_thrust_pressed() and current_fuel > 0:
            var input_dir = get_movement_input()
            var thrust_direction = calculate_movement_direction(input_dir)

            # Apply directional thrust
            if thrust_direction != Vector3.ZERO:
                velocity += thrust_direction * jetpack_thrust * delta
            else:
                # No directional input: thrust upward
                velocity += -gravity_direction * jetpack_thrust * delta

            current_fuel -= jetpack_fuel_consumption * delta
    else:
        # Normal gravity: jetpack only provides upward thrust
        if jetpack_enabled and is_jetpack_thrust_pressed() and current_fuel > 0:
            velocity += -gravity_direction * jetpack_thrust * delta
            current_fuel -= jetpack_fuel_consumption * delta
```

**Benefits**:
- Low gravity worlds: Full 3D flight control
- Normal gravity: Jump boost only
- Maintains fuel management system
- Natural transition between walking and flying

### 4.4 Jump Mechanics

**Current**: Simple vertical impulse on button press

**Enhancement**: Scale with gravity and check ground

```gdscript
func is_jump_pressed() -> bool:
    # ... existing input detection ...

func apply_jump():
    # Only jump if on ground
    if not is_on_ground:
        return

    # Scale jump velocity by local gravity
    var adjusted_jump = jump_velocity * sqrt(current_gravity / 9.8)

    # Apply jump in "up" direction (away from planet center)
    velocity += -gravity_direction * adjusted_jump

    # Optional: Small forward boost for momentum
    var move_direction = calculate_movement_direction(get_movement_input())
    if move_direction != Vector3.ZERO:
        velocity += move_direction * (adjusted_jump * 0.2)  # 20% forward
```

---

## 5. Reference Frame Implementation

### 5.1 Surface-Relative Coordinate System

**Goal**: Player maintains position relative to surface features as planet rotates.

**Required CelestialBody API**:

```gdscript
# New methods needed in CelestialBody class
class_name CelestialBody

## Get the angular velocity vector (radians/second)
func get_angular_velocity() -> Vector3:
    # For Earth: ~7.2921159e-5 rad/s (23h 56m 4s sidereal day)
    # Axis: typically Vector3(0, 1, 0) for upright rotation
    return rotation_axis.normalized() * angular_speed

## Get rotation axis (normalized)
@export var rotation_axis: Vector3 = Vector3(0, 1, 0)

## Get angular speed (radians per second)
@export var angular_speed: float = 7.2921159e-5  # Earth's rotation
```

**Surface Velocity Calculation**:

```gdscript
## Calculate velocity of surface at player's position
func get_surface_velocity_at_position(pos: Vector3) -> Vector3:
    if not current_planet:
        return Vector3.ZERO

    if not current_planet.has_method("get_angular_velocity"):
        push_warning("Planet lacks angular velocity method")
        return Vector3.ZERO

    # ω (angular velocity)
    var omega = current_planet.get_angular_velocity()

    # r (radius vector from planet center to player)
    var radius = pos - current_planet.global_position

    # v = ω × r (cross product gives tangential velocity)
    var surface_velocity = omega.cross(radius)

    return surface_velocity
```

### 5.2 Movement Composition

**Physics Process Order**:

```gdscript
func _physics_process(delta: float) -> void:
    # 1. Update ground detection
    update_ground_detection()

    # 2. Apply gravity
    if not is_on_floor():
        velocity += gravity_direction * current_gravity * delta

    # 3. Get surface velocity (moves with planet)
    var surface_vel = get_surface_velocity_at_position(global_position)

    # 4. Get player input velocity (relative to surface)
    var input_velocity = Vector3.ZERO
    if is_on_ground:
        var input_dir = get_movement_input()
        var direction = calculate_movement_direction(input_dir)
        if direction != Vector3.ZERO:
            var speed = sprint_speed if is_sprinting() else walk_speed
            input_velocity = direction * speed

    # 5. Apply jetpack (if active)
    var jetpack_velocity = Vector3.ZERO
    if is_jetpack_thrust_pressed() and current_fuel > 0:
        jetpack_velocity = -gravity_direction * jetpack_thrust * delta
        current_fuel -= jetpack_fuel_consumption * delta

    # 6. Compose final velocity
    # Note: CharacterBody3D velocity is absolute, not relative
    # So we need to add surface velocity each frame
    velocity = input_velocity + surface_vel + jetpack_velocity

    # 7. Apply friction when no input (only to relative velocity)
    if input_velocity == Vector3.ZERO and is_on_ground:
        var relative_vel = velocity - surface_vel
        var friction = walk_speed * delta * 5.0
        relative_vel = relative_vel.move_toward(Vector3.ZERO, friction)
        velocity = relative_vel + surface_vel

    # 8. Move character
    move_and_slide()

    # 9. Update effects
    update_jetpack_effects()
```

### 5.3 Camera and VR Tracking

**VR Camera (XRCamera3D)**:
- Already tracks HMD in world space
- No changes needed to camera itself
- Player body follows camera yaw for movement direction

**Desktop Camera**:
- Mouse look controls pitch and yaw
- Same movement calculation as VR

**Orientation on Curved Surfaces**:
```gdscript
func _physics_process(delta: float) -> void:
    # ... movement code ...

    # Align character to surface normal (re-enabled with smoothing)
    if current_planet and is_on_ground:
        align_to_planet_surface(delta)
```

**XROrigin Parenting**:
```gdscript
# Current implementation (lines 199-204)
func activate() -> void:
    # Attach XR origin to character body
    if vr_manager and vr_manager.is_vr_active() and xr_origin:
        if xr_origin.get_parent():
            xr_origin.get_parent().remove_child(xr_origin)
        add_child(xr_origin)
        xr_origin.position = Vector3(0, 0.9, 0)  # Eye height
```

**This is correct**: XROrigin moves with CharacterBody3D, which moves with planet surface.

---

## 6. Specific Implementation Tasks

### 6.1 Phase 1: Core Planetary Physics Integration

#### Task 1.1: Add Angular Velocity to CelestialBody
**File**: `scripts/celestial/celestial_body.gd` (assumed to exist)

```gdscript
class_name CelestialBody extends Node3D

## Rotation axis (normalized direction)
@export var rotation_axis: Vector3 = Vector3(0, 1, 0):
    set(value):
        rotation_axis = value.normalized()

## Rotation period (seconds for one full rotation)
@export var rotation_period: float = 86164.0:  # Earth sidereal day
    set(value):
        rotation_period = max(value, 1.0)  # Prevent division by zero
        angular_speed = TAU / rotation_period

## Angular speed (radians per second) - auto-calculated
var angular_speed: float = 0.0

func _ready():
    # Calculate angular speed from period
    angular_speed = TAU / rotation_period

## Get angular velocity vector
func get_angular_velocity() -> Vector3:
    return rotation_axis * angular_speed

## Apply rotation in physics process
func _physics_process(delta: float):
    # Rotate the planet
    rotate_object_local(rotation_axis, angular_speed * delta)
```

**Testing**:
- Create test planet with 10-second rotation period
- Verify visible rotation
- Measure angular velocity output

#### Task 1.2: Surface Velocity Calculation
**File**: `scripts/player/walking_controller.gd`

Add method:
```gdscript
## Calculate surface velocity at current position
func get_surface_velocity() -> Vector3:
    if not current_planet:
        return Vector3.ZERO

    if not current_planet.has_method("get_angular_velocity"):
        return Vector3.ZERO

    var omega = current_planet.get_angular_velocity()
    var radius = global_position - current_planet.global_position
    return omega.cross(radius)
```

Integrate into physics process (see Section 5.2).

#### Task 1.3: Improve Movement Direction Calculation
**File**: `scripts/player/walking_controller.gd`

Replace `calculate_movement_direction()` with improved version from Section 3.2.

**Testing**:
- Walk on flat terrain: Should feel normal
- Walk on curved surface: Should project to tangent plane
- Look straight up/down: Should use fallback direction

### 6.2 Phase 2: Grounded Movement Constraints

#### Task 2.1: Strict Ground Detection
**File**: `scripts/player/walking_controller.gd`

Replace `update_ground_detection()` with improved version from Section 4.1.

**Testing**:
- Walk off cliff: Should transition to falling state
- Land from jump: Should restore movement control
- Run at high speed: Raycast should predict ground

#### Task 2.2: Conditional Movement Application
**File**: `scripts/player/walking_controller.gd`

Modify `_physics_process()` to only apply movement when grounded (Section 4.2).

**Testing**:
- Jump and push forward: Should not change horizontal velocity
- Walk normally: Should move as before
- Jetpack in air: Should provide mobility

### 6.3 Phase 3: Enhanced Jetpack System

#### Task 3.1: Low-Gravity Flight Mode
**File**: `scripts/player/walking_controller.gd`

Implement directional jetpack thrust for low-gravity environments (Section 4.3).

**Testing**:
- Moon (low gravity): Jetpack should provide directional control in air
- Earth (normal gravity): Jetpack should only boost upward
- Fuel consumption: Should drain at same rate regardless of mode

#### Task 3.2: Gravity-Scaled Jump
**File**: `scripts/player/walking_controller.gd`

Implement `apply_jump()` with gravity scaling (Section 4.4).

**Testing**:
- Earth gravity: Jump should feel normal (~1.5m high)
- Moon gravity: Jump should feel floaty (~9m high)
- High gravity: Jump should feel limited (~0.5m high)

### 6.4 Phase 4: Surface Alignment

#### Task 4.1: Re-enable Surface Alignment
**File**: `scripts/player/walking_controller.gd`

Replace `align_to_planet_surface()` with improved quaternion slerp version (Section 2.4).

**Testing**:
- Walk on curved surface: Should smoothly tilt with terrain
- No jitter: Interpolation should be stable
- Performance: Should not cause frame drops

#### Task 4.2: Camera Independence
**File**: `scripts/player/walking_controller.gd`

Verify XRCamera tracks HMD independently of body alignment.

**Testing**:
- Look around while walking: Head should move freely
- Body tilts with terrain: Camera should maintain world up
- VR comfort: No unexpected rotation of view

### 6.5 Phase 5: Teleport Locomotion (Optional)

#### Task 5.1: Arc Projection System
**New File**: `scripts/player/teleport_locomotion.gd`

```gdscript
extends Node3D
class_name TeleportLocomotion

## Projects arc from controller to valid ground location
func project_teleport_arc(controller_transform: Transform3D,
                          max_distance: float) -> Dictionary:
    var result = {
        "valid": false,
        "target_position": Vector3.ZERO,
        "arc_points": []
    }

    # Projectile motion arc
    var start = controller_transform.origin
    var forward = -controller_transform.basis.z
    var velocity = forward * 10.0 + Vector3.UP * 5.0

    const STEP_COUNT = 20
    const STEP_TIME = 0.1

    var position = start
    var arc_points = [position]

    for i in range(STEP_COUNT):
        # Apply gravity
        velocity += Vector3.DOWN * 9.8 * STEP_TIME
        position += velocity * STEP_TIME
        arc_points.append(position)

        # Raycast for ground
        var space_state = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(
            arc_points[i], position
        )
        var collision = space_state.intersect_ray(query)

        if collision:
            result["valid"] = true
            result["target_position"] = collision["position"]
            result["arc_points"] = arc_points
            return result

    return result
```

#### Task 5.2: Visual Feedback
**File**: `scripts/player/teleport_locomotion.gd`

Add arc line renderer and target indicator:
- Green arc/marker when valid target
- Red arc/marker when invalid target
- Particle effects at target location

#### Task 5.3: Teleport Execution
**File**: `scripts/player/walking_controller.gd`

```gdscript
func execute_teleport(target_position: Vector3) -> void:
    if not is_valid_teleport_target(target_position):
        return

    # Fade to black
    fade_screen(0.2)
    await get_tree().create_timer(0.2).timeout

    # Teleport
    global_position = target_position

    # Maintain surface-relative velocity
    velocity = get_surface_velocity()

    # Fade from black
    fade_screen(0.2, true)
```

### 6.6 Phase 6: Testing and Refinement

#### Test Suite 1: Basic Movement
- Walk forward/backward/strafe on flat terrain
- Verify speed matches expected values
- Check VR and desktop input both work

#### Test Suite 2: Planetary Rotation
- Stand still on rotating planet
- Verify player maintains position relative to surface
- Check surface features don't drift

#### Test Suite 3: Curved Surfaces
- Walk over hills and valleys
- Verify smooth alignment to surface normal
- Check no jittering or instability

#### Test Suite 4: Grounded Constraint
- Jump and try to walk in air (should not work)
- Jetpack in air (should work)
- Land and resume walking (should work)

#### Test Suite 5: Gravity Variations
- Walk on Moon (low gravity)
- Walk on Jupiter (high gravity)
- Verify speed/jump scaling feels appropriate

#### Test Suite 6: VR Comfort
- Smooth locomotion with vignette
- Snap turning (no continuous rotation)
- No unexpected view rotation

---

## 7. Configuration and Tuning

### 7.1 Exposed Parameters

**WalkingController** should expose these for tuning:

```gdscript
## Movement speeds
@export_group("Movement")
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 6.0
@export var jump_velocity: float = 4.0

## Physics
@export_group("Physics")
@export var gravity_scale: float = 1.0  # Multiplier for calculated gravity
@export var air_friction: float = 0.99  # Per-frame multiplier
@export var ground_friction: float = 5.0  # m/s² deceleration

## Surface alignment
@export_group("Surface Alignment")
@export var enable_surface_alignment: bool = true
@export var alignment_speed: float = 3.0  # Smoothing factor

## Jetpack
@export_group("Jetpack")
@export var jetpack_thrust: float = 15.0
@export var low_gravity_threshold: float = 5.0

## Ground detection
@export_group("Ground Detection")
@export var ground_ray_length: float = 2.0
@export var ground_distance_threshold: float = 1.0

## VR Comfort
@export_group("VR Comfort")
@export var smooth_locomotion: bool = true
@export var snap_turn_angle: float = 45.0
@export var vignette_enabled: bool = true
@export var vignette_intensity: float = 0.7
```

### 7.2 Debug Visualization

**Add debug drawing** (editor only):

```gdscript
func _process(delta):
    if not OS.is_debug_build():
        return

    # Draw gravity direction
    DebugDraw3D.draw_arrow(
        global_position,
        global_position + gravity_direction * 2.0,
        Color.RED
    )

    # Draw surface velocity
    var surf_vel = get_surface_velocity()
    DebugDraw3D.draw_arrow(
        global_position,
        global_position + surf_vel.normalized() * 2.0,
        Color.BLUE
    )

    # Draw movement direction
    var move_dir = calculate_movement_direction(get_movement_input())
    if move_dir != Vector3.ZERO:
        DebugDraw3D.draw_arrow(
            global_position,
            global_position + move_dir * 2.0,
            Color.GREEN
        )

    # Draw ground detection ray
    DebugDraw3D.draw_line(
        global_position,
        global_position + gravity_direction * ground_ray_length,
        Color.YELLOW if is_on_ground else Color.ORANGE
    )
```

### 7.3 Performance Profiling

**Monitor** these metrics:
- Physics process time (should be <1ms)
- Surface velocity calculation time
- Ground detection time
- Memory usage (should not grow over time)

---

## 8. Potential Issues and Solutions

### Issue 1: Player Drifts on Fast-Rotating Planets

**Symptom**: Player slowly slides across surface on high angular velocity planets.

**Cause**: Floating-point precision errors in surface velocity calculation.

**Solution**:
```gdscript
# Use double precision for angular velocity calculations
var omega_double = Vector3(
    float(current_planet.angular_speed) * current_planet.rotation_axis.x,
    float(current_planet.angular_speed) * current_planet.rotation_axis.y,
    float(current_planet.angular_speed) * current_planet.rotation_axis.z
)
```

### Issue 2: Jittering on Steep Slopes

**Symptom**: Character vibrates or stutters on steep terrain.

**Cause**: Competing forces (gravity vs. surface normal).

**Solution**:
```gdscript
# Disable surface alignment on slopes steeper than threshold
var surface_angle = rad_to_deg(acos(-gravity_direction.dot(Vector3.UP)))
if surface_angle > 45.0:
    enable_surface_alignment = false
else:
    enable_surface_alignment = true
```

### Issue 3: VR Motion Sickness

**Symptom**: Users report nausea during planetary walking.

**Cause**: Unexpected rotation from surface alignment.

**Solution**:
- Disable automatic surface alignment (make opt-in)
- Increase vignette intensity during movement
- Provide teleport locomotion alternative
- Add "artificial nose" reference point in HUD

### Issue 4: Falling Through Thin Terrain

**Symptom**: Player occasionally clips through terrain at high speeds.

**Cause**: Collision detection misses fast-moving objects.

**Solution**:
```gdscript
# Enable continuous collision detection
set_motion_mode(CharacterBody3D.MOTION_MODE_GROUNDED)
set_safe_margin(0.08)  # Increase collision margin

# Or reduce max walking speed
const MAX_SAFE_SPEED = 10.0
velocity = velocity.limit_length(MAX_SAFE_SPEED)
```

### Issue 5: Incorrect Movement on Rotating Platform

**Symptom**: When standing on rotating space station, player drifts.

**Cause**: Assuming only planets rotate, not detecting parent platform motion.

**Solution**:
```gdscript
# Detect any parent body rotation
func get_platform_velocity() -> Vector3:
    var parent = get_parent_body()
    if parent and parent.has_method("get_linear_velocity"):
        return parent.get_linear_velocity()
    if current_planet:
        return get_surface_velocity()
    return Vector3.ZERO
```

---

## 9. Future Enhancements

### 9.1 Wall Running
Allow temporary wall walking in low gravity:
- Detect wall surface within reach
- Redirect gravity to wall normal
- Limit duration with stamina system

### 9.2 Magnetic Boots
For zero-G environments (space stations):
- Toggle magnetic attachment to surfaces
- Walk on walls/ceilings
- Audio/visual feedback for attachment

### 9.3 Procedural Animation
Add inverse kinematics for foot placement:
- Feet align to terrain slopes
- Natural stepping motion
- Reduces VR disconnect

### 9.4 Vehicle Driving
Extend system for ground vehicles:
- Wheeled physics on curved surfaces
- Surface-relative steering
- Planetary rotation handling

### 9.5 Networked Multiplayer
Synchronize walking across network:
- Surface-relative position updates
- Rotation frame synchronization
- Interpolation for smooth remote players

---

## 10. Implementation Priority

### Critical Path (Must Have for MVP):
1. ✅ Task 1.1: Angular velocity to CelestialBody
2. ✅ Task 1.2: Surface velocity calculation
3. ✅ Task 1.3: Improved movement direction
4. ✅ Task 2.1: Strict ground detection
5. ✅ Task 2.2: Grounded movement constraints

### High Priority (Significantly Improves Experience):
6. Task 4.1: Surface alignment (re-enable with fixes)
7. Task 3.1: Low-gravity flight mode
8. Task 3.2: Gravity-scaled jump

### Medium Priority (Nice to Have):
9. Task 5.1-5.3: Teleport locomotion
10. Enhanced debug visualization
11. Performance profiling

### Low Priority (Future Polish):
12. Advanced comfort features
13. Procedural animation
14. Wall running / magnetic boots

---

## 11. Testing Strategy

### 11.1 Unit Tests

**File**: `tests/unit/test_walking_physics.gd`

```gdscript
extends GdUnitTestSuite

func test_surface_velocity_calculation():
    var planet = CelestialBody.new()
    planet.rotation_axis = Vector3(0, 1, 0)
    planet.angular_speed = TAU / 86164.0  # Earth
    planet.global_position = Vector3.ZERO

    var walker = WalkingController.new()
    walker.current_planet = planet
    walker.global_position = Vector3(6371000, 0, 0)  # Earth radius

    var surface_vel = walker.get_surface_velocity()

    # At equator, surface velocity should be ~463 m/s
    assert_float(surface_vel.length()).is_equal(463.0, 10.0)
    assert_vector3(surface_vel.normalized()).is_equal(Vector3(0, 0, 1), 0.01)

func test_grounded_movement_only():
    var walker = WalkingController.new()
    walker.is_on_ground = false

    # Attempt to apply movement input while in air
    var initial_velocity = walker.velocity
    walker._apply_movement_input(Vector2(1, 0))

    # Horizontal velocity should not change (only vertical from gravity)
    assert_float(walker.velocity.x).is_equal(initial_velocity.x)
    assert_float(walker.velocity.z).is_equal(initial_velocity.z)

func test_gravity_scaled_jump():
    var walker = WalkingController.new()

    # Test Earth gravity
    walker.current_gravity = 9.8
    walker.apply_jump()
    var earth_jump_vel = walker.velocity.y

    # Test Moon gravity (1/6 Earth)
    walker.velocity = Vector3.ZERO
    walker.current_gravity = 1.62
    walker.apply_jump()
    var moon_jump_vel = walker.velocity.y

    # Moon jump should be ~2.4x Earth jump (sqrt(6))
    var ratio = moon_jump_vel / earth_jump_vel
    assert_float(ratio).is_between(2.3, 2.5)
```

### 11.2 Integration Tests

**File**: `tests/integration/test_planetary_walking.gd`

```gdscript
extends GdUnitTestSuite

func test_walk_on_rotating_planet():
    var scene = load("res://tests/scenes/rotating_planet_test.tscn").instantiate()
    add_child(scene)

    var planet = scene.get_node("Planet")
    var walker = scene.get_node("Walker")

    # Record initial position relative to surface marker
    var marker = planet.get_node("SurfaceMarker")
    var initial_distance = walker.global_position.distance_to(marker.global_position)

    # Simulate 10 seconds of game time
    for i in range(600):  # 10 seconds at 60 FPS
        await get_tree().process_frame

    # Player should still be same distance from marker (moved with surface)
    var final_distance = walker.global_position.distance_to(marker.global_position)
    assert_float(final_distance).is_equal(initial_distance, 1.0)  # Within 1m

func test_walk_over_curved_terrain():
    var scene = load("res://tests/scenes/hill_terrain_test.tscn").instantiate()
    add_child(scene)

    var walker = scene.get_node("Walker")

    # Walk up a 30° slope
    walker.activate()
    Input.action_press("move_forward")

    # Simulate walking for 5 seconds
    for i in range(300):
        await get_tree().process_frame

    Input.action_release("move_forward")

    # Character should be aligned with slope normal
    var ground_normal = walker.get_ground_normal()
    var up_direction = -walker.gravity_direction
    var alignment_angle = rad_to_deg(acos(up_direction.dot(ground_normal)))

    assert_float(alignment_angle).is_less(5.0)  # Within 5° of surface normal
```

### 11.3 Manual Test Checklist

**Planetary Motion**:
- [ ] Stand still on rotating planet - position relative to surface features stable
- [ ] Walk forward - moves with surface rotation
- [ ] Jump - lands approximately same spot (accounting for planet rotation)
- [ ] Sprint - no drift or sliding

**Grounded Constraints**:
- [ ] Walk on ground - normal movement
- [ ] Jump - cannot walk in air
- [ ] Jetpack - provides aerial mobility
- [ ] Land from jump - immediately regain walking control

**Curved Surfaces**:
- [ ] Walk up hill - smooth transition
- [ ] Walk down hill - no falling/sliding
- [ ] Walk on sphere - body aligns to surface
- [ ] Camera stays upright (world-relative)

**Gravity Variations**:
- [ ] Earth gravity (9.8 m/s²) - feels normal
- [ ] Moon gravity (1.62 m/s²) - floaty, high jumps
- [ ] Mars gravity (3.7 m/s²) - slightly floaty
- [ ] Jupiter gravity (24.8 m/s²) - heavy, low jumps

**VR Comfort**:
- [ ] Smooth locomotion - no motion sickness triggers
- [ ] Snap turns - discrete rotation
- [ ] Vignette during movement - reduces peripheral motion
- [ ] No unexpected view rotation

**Desktop Mode**:
- [ ] WASD movement works
- [ ] Mouse look works
- [ ] All interactions match VR functionality

---

## 12. Documentation Updates Required

### 12.1 API Documentation

Update `scripts/player/WALKING_SYSTEM_GUIDE.md`:
- Add section on planetary rotation handling
- Document surface velocity calculation
- Explain reference frames
- Add troubleshooting for rotation-related issues

### 12.2 User Guide

Create `docs/VR_WALKING_CONTROLS.md`:
- Explain why walking only works when grounded
- Document jetpack as aerial mobility
- Describe gravity scaling effects
- Provide tips for VR comfort

### 12.3 Code Comments

Ensure all new methods have comprehensive doc comments:
```gdscript
## Calculate the velocity of the planetary surface at the given position.
## This ensures the player moves with the rotating surface.
##
## Formula: v_surface = ω × r
## Where:
##   ω = angular velocity vector (rad/s)
##   r = radius vector from planet center to position
##
## Returns: Surface velocity in m/s (world space)
func get_surface_velocity_at_position(pos: Vector3) -> Vector3:
```

---

## 13. Conclusion

This plan provides a comprehensive approach to integrating VR locomotion with realistic planetary physics. The design prioritizes:

1. **Player Comfort**: Smooth locomotion with comfort features, optional teleport
2. **Physical Accuracy**: Surface-relative movement respects planetary rotation
3. **Intuitive Controls**: Camera-relative movement feels natural
4. **VR Best Practices**: Independent head tracking, snap turns, vignette
5. **Grounded Constraint**: Walking only works on ground (jetpack for aerial)

**Key Technical Achievements**:
- Surface velocity calculation ensures player moves with rotating planet
- Movement direction projects onto tangent plane of curved surface
- Strict ground detection enables grounded-only walking
- Gravity-scaled movement and jump feel appropriate across different worlds
- VR comfort features prevent motion sickness

**Implementation Phases**:
1. **Phase 1** (Critical): Surface velocity and movement improvements
2. **Phase 2** (Critical): Grounded movement constraints
3. **Phase 3** (High): Enhanced jetpack and gravity scaling
4. **Phase 4** (High): Surface alignment re-enable
5. **Phase 5** (Medium): Teleport locomotion
6. **Phase 6** (Ongoing): Testing and refinement

**Success Metrics**:
- ✅ Player position stable relative to surface features
- ✅ No drift or sliding on rotating planets
- ✅ Walking disabled in air (jetpack provides aerial mobility)
- ✅ Smooth movement on curved surfaces without jitter
- ✅ VR comfort maintained (no unexpected rotation)
- ✅ All unit and integration tests pass

This plan is ready for implementation. Each phase is self-contained and can be developed and tested independently before moving to the next phase.

---

## Appendix A: Mathematical Derivations

### A.1 Surface Velocity from Angular Velocity

Given:
- ω = angular velocity vector (axis direction × angular speed)
- r = radius vector from rotation center to point

The tangential velocity at that point is:
```
v = ω × r
```

**Proof**:
- The cross product ω × r gives a vector perpendicular to both ω and r
- Magnitude: |v| = |ω| * |r| * sin(θ) where θ is angle between ω and r
- Direction: Follows right-hand rule (tangent to rotation)
- For perpendicular vectors (θ = 90°): |v| = |ω| * |r| = (angular speed) * (radius)

### A.2 Gravity Scaling for Jump Height

Jump height equation: h = v₀² / (2g)

For constant jump height across different gravities:
- h_Earth = v_Earth² / (2 * g_Earth)
- h_Other = v_Other² / (2 * g_Other)

Setting h_Earth = h_Other:
```
v_Other = v_Earth * sqrt(g_Other / g_Earth)
```

This means jump velocity should scale with the square root of gravity ratio.

### A.3 Movement Direction Projection

To project movement onto surface tangent plane:

Given:
- v = desired movement vector (camera-forward)
- n = surface normal (-gravity_direction)

Projection onto tangent plane:
```
v_tangent = v - (v · n) * n
```

Then normalize: v_tangent = v_tangent.normalized()

This ensures movement is always parallel to the surface, never "climbing" into it or "digging" into it.

---

## Appendix B: Reference Frame Comparison

### World-Fixed Frame
```
Player: Fixed world coordinates
Planet: Rotates beneath player
Result: Player drifts across surface

Time = 0s:     Time = 5min:
   P              P
   |                |
  ===              ---
  Planet          Planet rotated
```

### Surface-Relative Frame (Recommended)
```
Player: Velocity = Surface velocity + Input velocity
Planet: Rotates, carrying player with it
Result: Player maintains surface position

Time = 0s:     Time = 5min:
   P              P
   |              |
  ===            ---
  Planet        Planet rotated (player moved with it)
```

---

## Appendix C: Controller Button Layout Reference

### Quest 2 / Quest 3 Controllers

**Left Controller**:
- Thumbstick: Movement (forward/back/strafe)
- Thumbstick Click: Sprint toggle
- Trigger: (Available for other actions)
- Grip: (Available for other actions)
- X/Y Buttons: (Available for other actions)
- Menu Button: System menu

**Right Controller**:
- Thumbstick: Snap turn (horizontal), Vertical movement (jetpack when implemented)
- Thumbstick Click: (Available for other actions)
- Trigger: (Available for other actions)
- Grip: Jetpack thrust
- A Button: Jump
- B Button: Return to spacecraft / interact
- Oculus Button: System menu

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Author**: Claude (Anthropic)
**Status**: Ready for Implementation
