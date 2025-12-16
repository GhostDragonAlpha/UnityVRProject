# VR Locomotion Integration - Quick Summary

## Overview

Integration of VR locomotion controls with realistic planetary physics for walking on rotating, curved planetary surfaces. Walking only works when grounded; jetpack provides aerial mobility.

---

## Key Design Decisions

### 1. Locomotion Method
**Primary**: Smooth locomotion (thumbstick-based, camera-relative)
- ✅ Already implemented in `walking_controller.gd`
- VR comfort: Vignette effect + snap turning
- Desktop fallback: WASD + mouse

**Secondary**: Teleport locomotion (optional future enhancement)
- Point and click to teleport to location
- Maximum VR comfort
- Good for users sensitive to motion sickness

### 2. Planetary Reference Frame
**Surface-Relative** (player moves with rotating planet)

```
Player velocity = Surface velocity + Input velocity + Jetpack velocity

Surface velocity = ω × r
Where:
  ω = planet angular velocity (rad/s)
  r = radius from planet center to player
```

**Why**: Maintains player position relative to surface features as planet rotates.

### 3. Movement Constraint
**Grounded-Only Walking**

```gdscript
if is_on_ground:
    apply_movement_input()  # WASD/thumbstick controls work
else:
    # In air: no walking control
    # Use jetpack for aerial mobility
    if jetpack_active:
        apply_jetpack_thrust()
```

**Why**: Realistic physics - you can't walk on air!

### 4. Planetary Physics Integration

**Gravity**:
- Direction: Always toward planet center
- Magnitude: g = G * M / R² (clamped 0.1-50.0 m/s²)
- Applied every physics frame

**Surface Alignment**:
- Character aligns to surface normal (perpendicular to gravity)
- Smooth interpolation prevents jittering
- Currently disabled (will re-enable with fixes)

**Movement Direction**:
- Projects camera-forward onto surface tangent plane
- Ensures movement is always parallel to surface
- No "climbing" or "digging" into terrain

---

## Implementation Phases

### Phase 1: Core Physics (Critical) ⚡
1. Add `get_angular_velocity()` to CelestialBody
2. Calculate surface velocity in walking controller
3. Improve movement direction (surface tangent projection)

### Phase 2: Ground Constraints (Critical) ⚡
1. Strict ground detection (multiple methods)
2. Only apply movement input when grounded
3. Jetpack provides aerial mobility

### Phase 3: Enhanced Features (High Priority)
1. Low-gravity flight mode (directional jetpack)
2. Gravity-scaled jump height
3. Surface alignment (re-enable with smoothing)

### Phase 4: Advanced Features (Medium Priority)
1. Teleport locomotion
2. Advanced comfort features
3. Debug visualization

---

## Required Code Changes

### 1. CelestialBody Class
**New exports**:
```gdscript
@export var rotation_axis: Vector3 = Vector3(0, 1, 0)
@export var rotation_period: float = 86164.0  # seconds
```

**New method**:
```gdscript
func get_angular_velocity() -> Vector3:
    var angular_speed = TAU / rotation_period
    return rotation_axis.normalized() * angular_speed
```

### 2. WalkingController Class
**New method**:
```gdscript
func get_surface_velocity() -> Vector3:
    if not current_planet:
        return Vector3.ZERO

    var omega = current_planet.get_angular_velocity()
    var radius = global_position - current_planet.global_position
    return omega.cross(radius)
```

**Modified physics process**:
```gdscript
func _physics_process(delta: float) -> void:
    # 1. Ground detection
    update_ground_detection()

    # 2. Gravity (always applied)
    if not is_on_floor():
        velocity += gravity_direction * current_gravity * delta

    # 3. Surface velocity (move with planet)
    var surface_vel = get_surface_velocity()

    # 4. Input movement (only when grounded)
    var input_vel = Vector3.ZERO
    if is_on_ground:
        var input_dir = get_movement_input()
        var direction = calculate_movement_direction(input_dir)
        if direction != Vector3.ZERO:
            var speed = sprint_speed if is_sprinting() else walk_speed
            input_vel = direction * speed

    # 5. Compose velocity
    velocity = input_vel + surface_vel

    # 6. Jetpack (works in air)
    if is_jetpack_thrust_pressed() and current_fuel > 0:
        velocity += -gravity_direction * jetpack_thrust * delta
        current_fuel -= jetpack_fuel_consumption * delta

    # 7. Move
    move_and_slide()
```

**Improved movement calculation**:
```gdscript
func calculate_movement_direction(input: Vector2) -> Vector3:
    # Get camera forward
    var camera_forward = -vr_manager.get_hmd_pose().basis.z

    # Project onto surface tangent plane
    var surface_normal = -gravity_direction
    var surface_forward = camera_forward - camera_forward.project(surface_normal)

    # Handle looking straight up/down
    if surface_forward.length_squared() < 0.001:
        surface_forward = transform.basis.z
    else:
        surface_forward = surface_forward.normalized()

    # Calculate right vector
    var surface_right = surface_forward.cross(surface_normal).normalized()

    # Combine with input
    return (surface_forward * -input.y + surface_right * input.x).normalized()
```

---

## Testing Checklist

### Basic Movement
- [ ] Walk forward/backward/strafe (VR thumbstick)
- [ ] Walk forward/backward/strafe (desktop WASD)
- [ ] Sprint (thumbstick click / Shift)
- [ ] Look around (HMD / mouse)

### Planetary Rotation
- [ ] Stand still - position stable relative to surface features
- [ ] Walk forward - no drift
- [ ] Jump - land approximately same spot (accounting for rotation)

### Grounded Constraint
- [ ] Walk on ground - works normally
- [ ] Jump in air - cannot walk
- [ ] Jetpack in air - provides mobility
- [ ] Land from jump - immediately regain control

### Curved Surfaces
- [ ] Walk up hill - smooth transition
- [ ] Walk down valley - no sliding
- [ ] Body aligns to surface normal
- [ ] Camera maintains world-up orientation

### Gravity Variations
- [ ] Earth (9.8 m/s²) - normal feel
- [ ] Moon (1.62 m/s²) - floaty, high jumps
- [ ] Mars (3.7 m/s²) - slightly floaty
- [ ] Jupiter (24.8 m/s²) - heavy, low jumps

### VR Comfort
- [ ] Smooth locomotion - no nausea triggers
- [ ] Snap turns - 45° discrete rotation
- [ ] Vignette during movement
- [ ] No unexpected view rotation

---

## Common Issues and Solutions

### Issue: Player drifts on rotating planet
**Solution**: Ensure surface velocity is added to character velocity every frame.

### Issue: Jittering on curved terrain
**Solution**:
- Use quaternion slerp for surface alignment
- Increase smoothing factor (lower alignment_speed)
- Disable on steep slopes (>45°)

### Issue: Motion sickness in VR
**Solution**:
- Enable vignette during movement
- Disable automatic surface alignment
- Provide teleport locomotion alternative
- Add "artificial nose" reference in HUD

### Issue: Falling through terrain at high speed
**Solution**:
- Enable continuous collision detection
- Increase safe_margin on CharacterBody3D
- Limit maximum walking speed

---

## Performance Targets

- Physics process: <1ms per frame
- Ground detection: <0.1ms per frame
- Surface velocity calculation: <0.05ms per frame
- Memory: No growth over time
- Frame rate: Maintain 90 FPS for VR

---

## Configuration Values

```gdscript
# Movement
walk_speed = 3.0              # m/s
sprint_speed = 6.0            # m/s
jump_velocity = 4.0           # m/s

# Physics
gravity_scale = 1.0           # Multiplier
air_friction = 0.99           # Per frame
ground_friction = 5.0         # m/s²

# Surface alignment
enable_surface_alignment = true
alignment_speed = 3.0         # Smoothing

# Jetpack
jetpack_thrust = 15.0         # m/s²
low_gravity_threshold = 5.0   # m/s²

# Ground detection
ground_ray_length = 2.0       # m
ground_distance_threshold = 1.0  # m

# VR comfort
snap_turn_angle = 45.0        # degrees
vignette_intensity = 0.7      # 0-1
```

---

## VR Controller Layout

### Left Controller
- **Thumbstick**: Move (forward/back/strafe)
- **Thumbstick Click**: Sprint
- **Grip**: (Available)
- **Trigger**: (Available)

### Right Controller
- **Thumbstick Left/Right**: Snap turn (45°)
- **Grip**: Jetpack thrust
- **A Button**: Jump
- **B Button**: Return to spacecraft
- **Trigger**: (Available)

### Desktop Controls
- **W/A/S/D**: Move
- **Mouse**: Look
- **Shift**: Sprint
- **Space**: Jump
- **E**: Interact

---

## Key Files

- **Design**: `docs/VR_LOCOMOTION_PHYSICS_INTEGRATION_PLAN.md` (this full plan)
- **Implementation**: `scripts/player/walking_controller.gd`
- **Integration**: `scripts/player/transition_system.gd`
- **VR System**: `scripts/core/vr_manager.gd`
- **Physics**: `scripts/celestial/orbital_mechanics.gd`
- **Effects**: `scripts/player/jetpack_effects.gd`

---

## Next Steps

1. **Review** this summary and full plan
2. **Implement Phase 1** (core physics integration)
3. **Test** planetary rotation and surface velocity
4. **Implement Phase 2** (grounded constraints)
5. **Test** aerial vs ground movement
6. **Iterate** on remaining phases

---

**Status**: Ready for implementation
**Priority**: High (critical for realistic planetary walking)
**Estimated Effort**: 3-5 days for Phases 1-2, 2-3 days for Phase 3

**For Full Details**: See `VR_LOCOMOTION_PHYSICS_INTEGRATION_PLAN.md`
