# VR Physics Integration Analysis

**Document Version:** 1.0
**Date:** 2025-12-09
**Status:** ANALYSIS COMPLETE - READY FOR IMPLEMENTATION
**Severity:** HIGH - Multiple critical integration gaps identified

---

## Executive Summary

This document analyzes the integration gaps between VR locomotion systems and space physics systems in the SpaceTime project. Three **HIGH severity** issues have been identified that prevent proper VR flight mechanics and physics integration.

**Critical Findings:**
1. **Walking Controller Gravity Bypass** - WalkingController calculates gravity independently, bypassing PhysicsEngine's N-body calculations
2. **VR Controller Input Integration** - Spacecraft controls use keyboard only; no VR controller → spacecraft thrust integration
3. **Dual Floating Origin Systems** - Two competing floating origin implementations exist without clear authority

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Critical Issues](#critical-issues)
3. [VR Flight Movement Integration](#vr-flight-movement-integration)
4. [XRToolsMovementFlight vs PhysicsEngine Conflicts](#xrtoolsmovementflight-vs-physicsengine-conflicts)
5. [VR Controller to Spacecraft Integration](#vr-controller-to-spacecraft-integration)
6. [Floating Origin System Selection](#floating-origin-system-selection)
7. [Integration Checklist](#integration-checklist)
8. [Recommended Architecture](#recommended-architecture)

---

## Architecture Overview

### Current System Components

#### Space Physics Systems
- **PhysicsEngine** (`scripts/core/physics_engine.gd`)
  - N-body gravity simulation using Newton's law (F = G·m₁·m₂/r²)
  - Spatial partitioning for performance (10km grid cells)
  - Manages celestial bodies and spacecraft as RigidBody3D
  - Velocity-based gravity modifiers (escape velocity calculations)
  - **Port:** Integrates with Godot's PhysicsServer3D

- **FloatingOriginSystem (Autoload)** (`scripts/core/floating_origin_system.gd`)
  - Threshold: 10km
  - Registers objects for coordinate rebasing
  - Tracks universe offset
  - Integrates with AstronomicalCoordinateSystem

- **FloatingOrigin (Legacy)** (`scripts/core/floating_origin.gd`)
  - Threshold: 5km (requirements-based: 5.1)
  - Different coordinate management approach
  - **CONFLICT:** Two implementations exist

- **AstronomicalCoordinateSystem** (`scripts/core/astronomical_coordinate_system.gd`)
  - Multi-scale coordinate tracking (local/AU/light-years)
  - Layer-based LOD system
  - Integrates with FloatingOriginSystem

#### VR Locomotion Systems
- **WalkingController** (`scripts/player/walking_controller.gd`)
  - CharacterBody3D-based surface locomotion
  - **ISSUE:** Calculates own gravity using `G = 6.67430e-11` (real constant)
  - **ISSUE:** Bypasses PhysicsEngine completely
  - Jetpack system with thrust physics
  - VR controller thumbstick input for movement

- **XRToolsMovementFlight** (`addons/godot-xr-tools/functions/movement_flight.gd`)
  - VR flight locomotion provider
  - Uses velocity-based flight model
  - Applies drag, traction, guidance parameters
  - **ISSUE:** No integration with PhysicsEngine gravity
  - **ISSUE:** Operates in XRToolsPlayerBody coordinate space

- **Spacecraft** (`scripts/player/spacecraft.gd`)
  - RigidBody3D with thrust and rotation controls
  - `gravity_scale = 0.0` (expects PhysicsEngine to apply gravity)
  - **ISSUE:** Only keyboard input, no VR controller integration
  - Registered with PhysicsEngine for N-body gravity

- **PilotController** (`scripts/player/pilot_controller.gd`)
  - Maps VR controller input to spacecraft controls
  - **ISSUE:** Only connects to Spacecraft node, not to VR flight
  - Supports both VR and desktop modes

#### Transition Systems
- **TransitionSystem** (`scripts/player/transition_system.gd`)
  - Manages transitions between space/atmosphere/surface/walking modes
  - Creates WalkingController and PlanetLandingController
  - **ISSUE:** No VR flight mode integration

- **VRManager** (`scripts/core/vr_manager.gd`)
  - OpenXR initialization and HMD tracking
  - Controller state tracking with deadzones
  - Desktop fallback support
  - Emits controller button/input signals

---

## Critical Issues

### ISSUE 1: Walking Controller Gravity Bypass (HIGH SEVERITY)

**Location:** `scripts/player/walking_controller.gd:134-160`

**Problem:**
```gdscript
# WalkingController.gd line 134-148
func calculate_planet_gravity(planet: CelestialBody) -> void:
    const G = 6.67430e-11  # Real gravitational constant (SI units)
    const GAME_UNIT_TO_METERS = 1_000_000.0
    var mass = planet.mass
    var radius = planet.radius

    var radius_meters = radius * GAME_UNIT_TO_METERS
    current_gravity = (G * mass) / (radius_meters * radius_meters)
```

**Issues:**
1. **Bypasses PhysicsEngine:** WalkingController calculates gravity independently using real SI units
2. **Inconsistent with PhysicsEngine:** PhysicsEngine uses `G = 6.674e-23` (scaled for game units)
3. **No N-body gravity:** Walking mode doesn't account for multiple celestial bodies
4. **No velocity modifiers:** Ignores PhysicsEngine's escape velocity modifiers (requirements 9.3, 9.4)

**Impact:**
- Gravity feels different between spacecraft mode and walking mode
- Player can't experience realistic multi-body gravity while walking
- Surface gravity calculations are inconsistent with orbital mechanics

**Root Cause:**
WalkingController was designed as a standalone system without integration with the existing PhysicsEngine infrastructure.

---

### ISSUE 2: VR Controller Input Integration (HIGH SEVERITY)

**Location:** Multiple files

**Problem:**
No direct connection exists between VR controller input and spacecraft thrust/rotation forces through PhysicsEngine.

**Current Flow:**
```
VRManager → controller signals → (nowhere)
Spacecraft → _process_keyboard_input() → keyboard only
PilotController → Spacecraft.set_throttle() → NOT connected to VR flight
```

**Missing Flow:**
```
VR Controller → PilotController → Spacecraft → PhysicsEngine forces
VR Controller → XRToolsMovementFlight → ??? (no physics integration)
```

**Issues:**
1. **Spacecraft.gd (line 164-202):** Only processes keyboard input in `_process_keyboard_input()`
2. **PilotController.gd:** Reads VR controller state but only applies to Spacecraft node
3. **XRToolsMovementFlight:** Manages flight velocity but has no PhysicsEngine connection
4. **No Force Mapping:** VR controller trigger/thumbstick values don't translate to thrust forces

**Impact:**
- VR users can't use controllers to fly spacecraft in space
- No way to apply VR flight locomotion physics to spacecraft RigidBody3D
- Desktop keyboard is the only control method for spacecraft

---

### ISSUE 3: Dual Floating Origin Systems (MEDIUM SEVERITY)

**Location:** Two implementations exist

**Systems:**
1. **FloatingOriginSystem (Autoload)** - `scripts/core/floating_origin_system.gd`
   - Threshold: 10km
   - Universe offset tracking
   - AstronomicalCoordinateSystem integration

2. **FloatingOrigin (Component)** - `scripts/core/floating_origin.gd`
   - Threshold: 5km (per requirements 5.1)
   - Different rebasing approach
   - Physics body velocity preservation

**Conflict:**
```gdscript
# FloatingOriginSystem.gd
const SHIFT_THRESHOLD := 10000.0  # 10km

# FloatingOrigin.gd (requirements-based)
@export var rebase_threshold: float = 5000.0  # 5km from requirement 5.1
```

**Issues:**
1. **No Clear Authority:** Which system should VR systems use?
2. **Different Thresholds:** 5km vs 10km - affects VR precision
3. **Different APIs:** Registration methods differ
4. **Potential Double-Rebasing:** Both systems could trigger on same player movement

**Impact:**
- VR tracking precision issues if wrong system is used
- Potential coordinate desync between systems
- Confusion for developers about which to use

---

## VR Flight Movement Integration

### How VR Flight Should Integrate with PhysicsEngine Gravity

**Current XRToolsMovementFlight Behavior:**
```gdscript
# addons/godot-xr-tools/functions/movement_flight.gd:177-185
var flight_velocity := player_body.velocity
flight_velocity *= 1.0 - drag * delta
flight_velocity = flight_velocity.lerp(heading * speed_scale, speed_traction * delta)
flight_velocity += heading * acceleration_scale * delta

if exclusive:
    player_body.velocity = player_body.move_player(flight_velocity)
    return true
```

**Problems:**
1. **No Gravity Integration:** Flight velocity calculation doesn't account for PhysicsEngine gravity
2. **CharacterBody3D:** Uses `player_body.move_player()` instead of RigidBody3D forces
3. **Velocity Override:** Sets velocity directly, doesn't accumulate forces

**Recommended Integration:**

```gdscript
# PROPOSED: VR Flight with PhysicsEngine Integration
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
    # ... existing flight direction calculation ...

    # Get gravity from PhysicsEngine for current position
    var physics_engine = get_physics_engine()
    if physics_engine and physics_engine.gravity_enabled:
        var gravity_acceleration = physics_engine.get_gravity_acceleration_at_point(
            player_body.global_position
        )
        # Apply gravity to flight velocity
        flight_velocity += gravity_acceleration * delta
    else:
        # Fallback to simple gravity if PhysicsEngine unavailable
        flight_velocity += player_body.gravity * delta

    # ... existing drag, traction, guidance ...
```

**Benefits:**
- VR flight respects N-body gravity from multiple celestial bodies
- Smooth transitions between space and atmosphere
- Consistent physics across all locomotion modes
- Escape velocity effects apply to VR flight

---

## XRToolsMovementFlight vs PhysicsEngine Conflicts

### Conflict Analysis

| Aspect | XRToolsMovementFlight | PhysicsEngine | Conflict |
|--------|----------------------|---------------|----------|
| **Body Type** | CharacterBody3D | RigidBody3D | YES - incompatible physics modes |
| **Gravity Source** | `player_body.gravity` (simple) | N-body calculation | YES - different accuracy |
| **Force Application** | Velocity override | `apply_central_force()` | YES - different paradigms |
| **Coordinate Space** | XROrigin3D local | Global physics space | YES - tracking issues |
| **Movement Model** | Traction/guidance | Newtonian physics | YES - different feel |

### Root Cause: Body Type Mismatch

**XRToolsPlayerBody:**
- Inherits from `CharacterBody3D`
- Uses `move_and_slide()` for collision
- Velocity is directly set, not force-accumulated

**Spacecraft:**
- Inherits from `RigidBody3D`
- Uses `apply_central_force()` for thrust
- Velocity accumulates from forces

**Conclusion:**
**XRToolsMovementFlight cannot directly control Spacecraft** because they use incompatible physics body types.

### Proposed Solutions

#### Option A: Spacecraft as Movement Provider (RECOMMENDED)

Create a new movement provider that controls the Spacecraft RigidBody3D:

```gdscript
# NEW: XRToolsMovementSpacecraft
extends XRToolsMovementProvider

var spacecraft: Spacecraft = null

func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
    if not spacecraft:
        return

    # Get VR controller input
    var throttle = _controller.get_vector2("trigger").x
    var thumbstick = _controller.get_vector2("primary")

    # Apply to spacecraft as forces (PhysicsEngine handles gravity)
    spacecraft.set_throttle(throttle)
    spacecraft.apply_rotation(thumbstick.y, thumbstick.x, 0.0)

    # Sync XROrigin to spacecraft position
    player_body.global_position = spacecraft.global_position
```

**Pros:**
- Preserves PhysicsEngine N-body gravity
- VR controllers directly control spacecraft
- Works with existing Spacecraft class
- No modification to XRTools needed

**Cons:**
- XROrigin position is "teleported" to match spacecraft
- May feel less smooth than velocity-based flight

#### Option B: Hybrid Velocity Bridge (COMPLEX)

Keep CharacterBody3D but inject PhysicsEngine gravity:

```gdscript
# MODIFIED: XRToolsMovementFlight with gravity injection
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
    # Calculate flight velocity
    var flight_velocity = _calculate_flight_velocity(delta, player_body)

    # Inject PhysicsEngine gravity
    var gravity = _get_physics_engine_gravity(player_body.global_position)
    flight_velocity += gravity * delta

    # Apply to CharacterBody3D
    player_body.velocity = flight_velocity
    player_body.move_and_slide()
```

**Pros:**
- Keeps smooth VR flight feel
- Adds PhysicsEngine gravity
- Less invasive to XRTools

**Cons:**
- CharacterBody3D and RigidBody3D physics don't interact
- Spacecraft thrust forces won't work
- Complex to tune gravity + flight parameters

#### Option C: Dual-Mode System (FLEXIBLE)

Switch between CharacterBody3D (surface/atmo) and RigidBody3D (space):

```gdscript
# TransitionSystem decides which body type to use
match current_state:
    TransitionState.SPACE:
        use_spacecraft_rigidbody()  # PhysicsEngine gravity
    TransitionState.ATMOSPHERE:
        use_xr_flight_characterbody()  # XRTools flight
    TransitionState.WALKING:
        use_walking_controller()  # Surface gravity
```

**Pros:**
- Best physics for each mode
- Clear separation of concerns
- Optimal performance per mode

**Cons:**
- Complex state management
- Transition discontinuities
- Dual codepaths to maintain

---

## VR Controller to Spacecraft Integration

### Current Architecture

**PilotController** reads VR controller state but only applies to Spacecraft:

```gdscript
# scripts/player/pilot_controller.gd:176-196
func _process_vr_input(delta: float) -> void:
    var left_state := vr_manager.get_controller_state("left")
    var right_state := vr_manager.get_controller_state("right")

    var throttle_state := left_state if throttle_hand == ControlHand.LEFT else right_state
    _process_throttle_input(throttle_state)  # Gets trigger value

    var rotation_state := right_state if rotation_hand == ControlHand.RIGHT else left_state
    _process_rotation_input(rotation_state)  # Gets thumbstick

func _apply_controls_to_spacecraft() -> void:
    spacecraft.set_throttle(_current_throttle)
    spacecraft.apply_rotation(_current_pitch, _current_yaw, _current_roll)
```

**Problem:** This works for keyboard → spacecraft but NOT for VR flight mode using XRToolsMovementFlight.

### Recommended Integration Path

#### Step 1: Create VRSpacecraftController

New movement provider that bridges VR controllers and Spacecraft:

```gdscript
# NEW FILE: addons/godot-xr-tools/functions/movement_spacecraft.gd
class_name XRToolsMovementSpacecraft
extends XRToolsMovementProvider

@export var spacecraft: Spacecraft = null
@export var controller: FlightController = FlightController.LEFT
@export var throttle_hand: Hand = Hand.LEFT
@export var rotation_hand: Hand = Hand.RIGHT

func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
    if not spacecraft:
        return false

    # Read VR controller input
    var throttle_controller = _left_controller if throttle_hand == Hand.LEFT else _right_controller
    var rotation_controller = _right_controller if rotation_hand == Hand.RIGHT else _left_controller

    # Get input values
    var trigger = throttle_controller.get_float("trigger")
    var thumbstick = rotation_controller.get_vector2("primary")
    var grip = rotation_controller.get_float("grip")

    # Map to spacecraft controls
    spacecraft.set_throttle(trigger)

    # Thumbstick controls pitch/yaw, grip + thumbstick for roll
    var pitch = -thumbstick.y
    var yaw = thumbstick.x if grip < 0.5 else 0.0
    var roll = thumbstick.x if grip >= 0.5 else 0.0
    spacecraft.apply_rotation(pitch, yaw, roll)

    # Sync XROrigin to spacecraft (with optional smoothing)
    player_body.global_position = player_body.global_position.lerp(
        spacecraft.global_position,
        10.0 * delta
    )

    # PhysicsEngine handles gravity forces on spacecraft RigidBody3D
    return true  # Exclusive - no further movement providers
```

#### Step 2: Integrate with TransitionSystem

```gdscript
# scripts/player/transition_system.gd
func enable_space_flight_mode() -> void:
    # Create spacecraft movement provider
    var spacecraft_movement = XRToolsMovementSpacecraft.new()
    spacecraft_movement.spacecraft = spacecraft
    spacecraft_movement.controller = XRToolsMovementSpacecraft.FlightController.LEFT

    # Add to XRToolsPlayerBody
    var player_body = vr_manager.get_player_body()
    player_body.add_child(spacecraft_movement)

    # Register spacecraft with PhysicsEngine for N-body gravity
    var physics_engine = ResonanceEngine.get_physics_engine()
    physics_engine.add_rigid_body(spacecraft)
```

#### Step 3: Handle Gravity Integration

```gdscript
# Spacecraft.gd - ensure gravity_scale is 0.0
func _configure_rigid_body() -> void:
    gravity_scale = 0.0  # PhysicsEngine applies forces manually

# PhysicsEngine.gd - applies N-body gravity
func calculate_n_body_gravity(dt: float) -> void:
    for body in registered_bodies:
        var total_force = Vector3.ZERO
        for celestial in celestial_bodies:
            var force = calculate_gravitational_force(...)
            force = _apply_velocity_modifier(body, force, celestial)
            total_force += force
        apply_force_to_body(body, total_force)  # Uses apply_central_force()
```

### Input Mapping

| VR Controller | Input | Spacecraft Control |
|---------------|-------|-------------------|
| Left Trigger | Analog 0.0-1.0 | Throttle (forward thrust) |
| Right Thumbstick Y | Analog -1.0 to 1.0 | Pitch (up/down) |
| Right Thumbstick X | Analog -1.0 to 1.0 | Yaw (left/right) |
| Right Grip + Thumbstick X | Analog | Roll (barrel roll) |
| Left/Right Menu | Button | Pause/Menu |
| Right A/X Button | Button | Action (scan/interact) |

---

## Floating Origin System Selection

### Comparison Matrix

| Feature | FloatingOriginSystem (Autoload) | FloatingOrigin (Component) |
|---------|--------------------------------|---------------------------|
| **Threshold** | 10km | 5km (requirements) |
| **Architecture** | Singleton autoload | Component instance |
| **Coordinate Tracking** | Universe offset | Global offset |
| **Integration** | AstronomicalCoordinateSystem | Standalone |
| **Registration API** | `register_object()` | `register_object()` |
| **Physics Handling** | Basic node shift | RigidBody3D velocity preservation |
| **VR Support** | Not specified | Not specified |

### Recommendation: Use FloatingOriginSystem (Autoload)

**Rationale:**
1. **Already Integrated:** Works with AstronomicalCoordinateSystem
2. **Higher Threshold:** 10km is better for space-scale precision
3. **Singleton Pattern:** Easier access from any node
4. **Active Development:** More recent updates

**Migration Path:**
1. Deprecate `scripts/core/floating_origin.gd`
2. Update requirement 5.1 threshold from 5km to 10km
3. Ensure all VR nodes register with FloatingOriginSystem
4. Add VR-specific precision handling if needed

### VR-Specific Considerations

**XROrigin3D Registration:**
```gdscript
# VRManager.gd - register XR nodes with floating origin
func _setup_xr_nodes() -> void:
    # ... create XROrigin3D ...

    # Register with floating origin system
    var floating_origin = get_node("/root/FloatingOriginSystem")
    if floating_origin:
        floating_origin.register_object(xr_origin)
        floating_origin.set_player(xr_origin)
```

**Tracking Precision:**
- VR tracking requires sub-millimeter precision
- Floating origin shift at 10km maintains precision within ±0.001m
- No additional handling needed for VR if shifts are instantaneous

---

## Integration Checklist

### Phase 1: Gravity Integration (HIGH PRIORITY)

- [ ] **WalkingController Gravity Integration**
  - [ ] Remove `calculate_planet_gravity()` function
  - [ ] Get gravity from PhysicsEngine: `PhysicsEngine.get_gravity_at_point(global_position)`
  - [ ] Apply gravity direction from PhysicsEngine
  - [ ] Test gravity consistency between walking and spacecraft modes

- [ ] **Update Jetpack Physics**
  - [ ] Ensure jetpack thrust works against PhysicsEngine gravity direction
  - [ ] Test low-gravity flight mode with multiple celestial bodies

- [ ] **Add PhysicsEngine Query Method**
  - [ ] Implement `PhysicsEngine.get_gravity_at_point(point: Vector3) -> Vector3`
  - [ ] Implement `PhysicsEngine.get_gravity_direction_at_point(point: Vector3) -> Vector3`
  - [ ] Return zero gravity if no celestial bodies nearby

### Phase 2: VR Controller Integration (HIGH PRIORITY)

- [ ] **Create XRToolsMovementSpacecraft**
  - [ ] New file: `addons/godot-xr-tools/functions/movement_spacecraft.gd`
  - [ ] Extend `XRToolsMovementProvider`
  - [ ] Read VR controller trigger/thumbstick
  - [ ] Apply to Spacecraft via `set_throttle()` and `apply_rotation()`
  - [ ] Sync XROrigin position to spacecraft

- [ ] **Integrate with TransitionSystem**
  - [ ] Add `enable_space_flight_mode()` method
  - [ ] Create and attach XRToolsMovementSpacecraft
  - [ ] Register spacecraft with PhysicsEngine
  - [ ] Handle state transitions to/from flight mode

- [ ] **Update PilotController**
  - [ ] Make PilotController work with both desktop and VR modes
  - [ ] Route VR input through movement provider instead of direct spacecraft control
  - [ ] Add configuration for hand assignment (left/right for throttle/rotation)

- [ ] **Input Mapping**
  - [ ] Map left trigger to throttle
  - [ ] Map right thumbstick to pitch/yaw
  - [ ] Map right grip + thumbstick to roll
  - [ ] Add deadzone handling (already in VRManager)

### Phase 3: Floating Origin Consolidation (MEDIUM PRIORITY)

- [ ] **Deprecate Dual System**
  - [ ] Choose FloatingOriginSystem (autoload) as canonical
  - [ ] Mark `scripts/core/floating_origin.gd` as deprecated
  - [ ] Update documentation to reference only FloatingOriginSystem

- [ ] **Update Registrations**
  - [ ] Ensure Spacecraft registers with FloatingOriginSystem
  - [ ] Ensure XROrigin3D registers with FloatingOriginSystem
  - [ ] Ensure WalkingController registers when active
  - [ ] Ensure all celestial bodies register

- [ ] **VR Tracking Integration**
  - [ ] Register XROrigin3D in VRManager._setup_xr_nodes()
  - [ ] Set player reference to XROrigin3D
  - [ ] Test VR tracking precision during floating origin shifts

- [ ] **Update Requirements**
  - [ ] Change requirement 5.1 threshold from 5km to 10km
  - [ ] Document floating origin system choice in CLAUDE.md

### Phase 4: Testing and Validation (CRITICAL)

- [ ] **Gravity Consistency Tests**
  - [ ] Test walking mode gravity matches spacecraft orbit calculations
  - [ ] Test jetpack thrust against realistic planetary gravity
  - [ ] Test multi-body gravity (moon + planet) in walking mode

- [ ] **VR Flight Tests**
  - [ ] Test VR controller → spacecraft thrust mapping
  - [ ] Test smooth flight in space with N-body gravity
  - [ ] Test atmospheric entry with VR flight controls
  - [ ] Test transition from spacecraft to walking mode

- [ ] **Floating Origin Tests**
  - [ ] Test VR tracking during floating origin shift
  - [ ] Test spacecraft physics during floating origin shift
  - [ ] Test walking mode during floating origin shift
  - [ ] Verify no double-shifting occurs

- [ ] **Performance Tests**
  - [ ] Measure PhysicsEngine overhead with VR flight
  - [ ] Ensure 90 FPS VR target maintained
  - [ ] Check spatial partitioning efficiency

### Phase 5: Documentation (REQUIRED)

- [ ] **Update CLAUDE.md**
  - [ ] Document VR flight integration architecture
  - [ ] Update floating origin system section
  - [ ] Add VR controller → spacecraft mapping

- [ ] **Create VR Flight Guide**
  - [ ] Document XRToolsMovementSpacecraft usage
  - [ ] Provide examples for developers
  - [ ] Explain gravity integration

- [ ] **Update Testing Documentation**
  - [ ] Add VR flight test procedures
  - [ ] Document expected gravity behavior
  - [ ] Add troubleshooting guide

---

## Recommended Architecture

### Proposed Integration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         VR INPUT                             │
│  VRManager → XRController3D (trigger, thumbstick, grip)     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  MOVEMENT PROVIDER                           │
│            XRToolsMovementSpacecraft                         │
│  - Reads VR controller state                                 │
│  - Maps to Spacecraft controls                               │
│  - Syncs XROrigin position                                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   SPACECRAFT (RigidBody3D)                   │
│  - set_throttle(trigger_value)                               │
│  - apply_rotation(pitch, yaw, roll)                          │
│  - gravity_scale = 0.0 (physics handled externally)          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    PHYSICS ENGINE                            │
│  - Calculates N-body gravity for spacecraft position         │
│  - Applies forces: apply_central_force(gravity_force)        │
│  - Velocity modifiers based on escape velocity               │
│  - Spatial partitioning for performance                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              FLOATING ORIGIN SYSTEM (Autoload)               │
│  - Shifts universe at 10km threshold                         │
│  - Updates spacecraft, XROrigin, celestial bodies            │
│  - Notifies AstronomicalCoordinateSystem                     │
└─────────────────────────────────────────────────────────────┘
```

### Walking Mode Gravity Integration

```
┌─────────────────────────────────────────────────────────────┐
│              WALKING CONTROLLER (CharacterBody3D)            │
│  - VR controller thumbstick for movement                     │
│  - Jetpack thrust from grip button                           │
│  - NO local gravity calculation                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    PHYSICS ENGINE                            │
│  gravity = PhysicsEngine.get_gravity_at_point(position)      │
│  gravity_direction = PhysicsEngine.get_dominant_source(...)  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Principles

1. **Single Source of Truth for Gravity:** PhysicsEngine is the ONLY system that calculates gravity
2. **VR Controllers Control Forces:** Not velocities - let physics accumulate
3. **Floating Origin is Universal:** All systems register with FloatingOriginSystem (autoload)
4. **Body Type Dictates Integration:** RigidBody3D for space, CharacterBody3D for surface
5. **TransitionSystem Orchestrates:** Manages which movement provider is active

---

## Appendix A: Code Locations

### Files Requiring Modification

| File | Lines | Change Required |
|------|-------|----------------|
| `scripts/player/walking_controller.gd` | 134-160 | Remove gravity calculation, query PhysicsEngine |
| `scripts/player/walking_controller.gd` | 246-265 | Use PhysicsEngine gravity direction |
| `scripts/core/physics_engine.gd` | NEW | Add `get_gravity_at_point()` method |
| `scripts/core/physics_engine.gd` | NEW | Add `get_gravity_direction_at_point()` method |
| `scripts/player/transition_system.gd` | NEW | Add `enable_space_flight_mode()` |
| `scripts/core/vr_manager.gd` | 236-276 | Register XROrigin with FloatingOriginSystem |

### New Files Required

1. `addons/godot-xr-tools/functions/movement_spacecraft.gd` - VR spacecraft controller
2. `addons/godot-xr-tools/functions/movement_spacecraft.tscn` - Scene for movement provider
3. `docs/guides/VR_FLIGHT_INTEGRATION_GUIDE.md` - Developer documentation

---

## Appendix B: Testing Requirements

### Unit Tests Needed

1. **PhysicsEngine Query Tests**
   - Test `get_gravity_at_point()` with single celestial body
   - Test multi-body gravity summation
   - Test spatial partitioning query performance

2. **WalkingController Gravity Tests**
   - Verify gravity matches PhysicsEngine calculations
   - Test jetpack thrust against gravity direction
   - Test low-gravity flight mode behavior

3. **VR Input Integration Tests**
   - Test VR controller → spacecraft throttle mapping
   - Test rotation mapping (pitch/yaw/roll)
   - Test deadzone handling

### Integration Tests Needed

1. **Flight Mode Transitions**
   - Space → Atmosphere → Surface → Walking
   - Each transition preserves physics momentum
   - VR tracking remains smooth

2. **Floating Origin During VR Flight**
   - Test spacecraft control during shift
   - Test VR tracking precision
   - Test gravity calculation continuity

3. **Multi-Body Gravity**
   - Test orbiting moon with planet gravity
   - Test Lagrange point behavior
   - Test escape velocity modifiers

---

## Document Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-09 | Initial analysis complete |

---

**END OF DOCUMENT**
