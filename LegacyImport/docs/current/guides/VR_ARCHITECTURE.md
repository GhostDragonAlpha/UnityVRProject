# VR Architecture: Player Mode vs AI Training Mode

**Last Updated:** 2025-12-10
**Status:** PRODUCTION CRITICAL - DO NOT MODIFY WITHOUT UNDERSTANDING

## Overview

This document explains the dual-mode VR system architecture that allows the same scene to support both:
- **VR Player Mode**: Human controls via VR headset tracking
- **AI Training Mode**: RL/ML agent controls, VR camera follows for observation

## Critical Scene Hierarchy

```
VRMain (Node3D)
  └── XROrigin3D (VR tracking anchor)
      ├── XRCamera3D (VR headset tracking)
      ├── FallbackCamera (Desktop fallback - must be DISABLED in VR)
      └── PlayerCollision (CharacterBody3D - physics body)
```

**CRITICAL:** CharacterBody3D MUST be a child of XROrigin3D for VR Player Mode to work.

## The Two Control Modes

### VR Player Mode (`physics_movement_enabled = false`)

**Who Controls Position:**
- **XROrigin3D**: Controlled by OpenXR/SteamVR tracking
- **CharacterBody3D**: Follows XROrigin3D automatically (parent-child relationship)

**Physics Role:**
- Collision detection via `move_and_slide()`
- Ground detection for `is_grounded` state
- **NOT** position control

**Code Pattern:**
```gdscript
func _vr_player_mode_physics(delta: float) -> void:
	# DON'T manually set position - CharacterBody3D is child of XROrigin3D
	# It automatically follows parent transform
	# Manual position setting was breaking XR tracking!

	# Apply local gravity for ground detection
	if not player_body.is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
		is_grounded = true

	# Move with collision detection (position set by VR tracking)
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()

	is_grounded = player_body.is_on_floor()
```

**NEVER DO THIS in VR Player Mode:**
```gdscript
player_body.global_position = xr_origin.global_position  # ← BREAKS VR TRACKING!
```

### AI Training Mode (`gravity_enabled = true`)

**Who Controls Position:**
- **CharacterBody3D**: Controlled by AI/physics simulation
- **XROrigin3D**: Follows CharacterBody3D for VR observation

**Physics Role:**
- Position control via N-body gravity simulation
- Orbital mechanics
- Collision and landing

**Code Pattern:**
```gdscript
func _ai_training_mode_physics(delta: float) -> void:
	# Calculate physics
	var total_acceleration = _calculate_total_gravity()
	velocity += total_acceleration * delta

	# Apply to CharacterBody3D
	player_body.velocity = velocity
	player_body.move_and_slide()

	# VR camera follows physics body
	xr_origin.global_position = player_body.global_position  # ← CORRECT for AI mode!

	is_grounded = player_body.is_on_floor()
	velocity = player_body.velocity
```

## The Bug That Broke VR Tracking

### What Happened

During RL/ML agent implementation, the following line was added to `_vr_player_mode_physics()`:

```gdscript
player_body.global_position = xr_origin.global_position  # ← THE BUG
```

This line is **correct** for AI Training Mode but **breaks** VR Player Mode.

### Why It Broke

**Scene Tree Transform Inheritance:**
1. CharacterBody3D is a **child** of XROrigin3D
2. Children automatically inherit parent global_transform
3. Setting child's global_position manually fights with parent transform

**The Conflict:**
```
Frame N:
  1. OpenXR updates XROrigin3D.global_position to (1.0, 1.7, 0.5)
  2. CharacterBody3D inherits position (1.0, 1.7, 0.5)
  3. Physics code sets: player_body.global_position = xr_origin.global_position
  4. This creates feedback loop preventing tracking updates
  5. Result: Both stuck at (0, 0, 0)
```

### The Fix

**Remove manual position setting in VR Player Mode:**
```gdscript
func _vr_player_mode_physics(delta: float) -> void:
	# ← REMOVED: player_body.global_position = xr_origin.global_position

	# CharacterBody3D follows XROrigin3D automatically via scene tree
	# Only physics operations:
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()
```

## Mode Switching

```gdscript
func _physics_process(delta: float) -> void:
	if not is_instance_valid(xr_origin) or not is_instance_valid(player_body):
		return

	# VR PLAYER MODE: VR tracking controls, physics follows
	if not physics_movement_enabled:
		_vr_player_mode_physics(delta)
		return

	# AI TRAINING MODE: AI/physics controls, VR follows
	if gravity_enabled:
		_ai_training_mode_physics(delta)
```

**Export Variable in Scene:**
```
[node name="VRMain" type="Node3D"]
script = ExtResource("1_vr_main")
physics_movement_enabled = false  # ← Set to true for AI Training Mode
```

## Common Pitfalls

### ❌ WRONG: Manual Position Override in VR Mode
```gdscript
func _vr_player_mode_physics(delta: float):
	player_body.global_position = xr_origin.global_position  # BREAKS TRACKING!
	player_body.move_and_slide()
```

### ✅ CORRECT: Let Scene Tree Handle Position
```gdscript
func _vr_player_mode_physics(delta: float):
	# No manual position setting - CharacterBody3D follows parent
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()
```

### ❌ WRONG: CharacterBody3D Not Child of XROrigin3D
```
VRMain
  ├── XROrigin3D
  │   └── XRCamera3D
  └── PlayerCollision  # ← WRONG! Must be child of XROrigin3D
```

### ✅ CORRECT: Proper Hierarchy
```
VRMain
  └── XROrigin3D
      ├── XRCamera3D
      └── PlayerCollision  # ← CORRECT! Child inherits transform
```

## Debugging VR Tracking Issues

### Symptoms of Broken VR Tracking
- Gray screen in VR headset
- XROrigin3D stuck at (0, 0, 0)
- XRCamera3D stuck at (0, 0, 0) or (0, 1.7, 0)
- No response to head movement

### Diagnostic Checklist

**1. Check Camera Activation:**
```gdscript
print("XRCamera3D active: ", $XROrigin3D/XRCamera3D.current)
print("FallbackCamera active: ", $XROrigin3D/FallbackCamera.current)
```
Expected: XRCamera3D = true, FallbackCamera = false

**2. Check OpenXR Initialization:**
```
Console output should show:
[VRMain] OpenXR initialized successfully
[VRMain] Viewport marked for XR rendering
```

**3. Check Position Updates:**
```gdscript
print("XROrigin pos: ", xr_origin.global_position)
print("XRCamera pos: ", $XROrigin3D/XRCamera3D.global_position)
```
If both stuck at (0,0,0), tracking is broken.

**4. Check for Manual Position Overrides:**
Search `vr_main.gd` for:
```gdscript
player_body.global_position =
```
This line should ONLY appear in `_ai_training_mode_physics()`, NOT in `_vr_player_mode_physics()`.

**5. Verify Scene Hierarchy:**
```
XROrigin3D
  └── PlayerCollision (CharacterBody3D)  ← Must be child!
```

## Implementation Reference

**File:** `vr_main.gd`

**VR Player Mode Function:** `_vr_player_mode_physics()` (lines 148-174)

**AI Training Mode Function:** `_ai_training_mode_physics()` (lines 176-206)

**Mode Dispatcher:** `_physics_process()` (lines 132-146)

## Related Documentation

- `VR_TRACKING_FAILURE_ROOT_CAUSE.md`: Detailed bug analysis from 2025-12-10
- `CLAUDE.md`: Project overview and development guidelines
- `vr_main.gd`: Main VR scene implementation

## Future Development Guidelines

**When adding new VR features:**

1. **Always check current mode** before modifying position
2. **Never manually set CharacterBody3D.global_position** in VR Player Mode
3. **Test both modes** after changes
4. **Preserve scene hierarchy** - CharacterBody3D must stay child of XROrigin3D
5. **Add debug prints** for position tracking when debugging

**When implementing RL/AI features:**

1. **Modify only AI Training Mode function** (`_ai_training_mode_physics()`)
2. **Keep VR Player Mode untouched** unless specifically needed
3. **Test mode switching** works correctly
4. **Document any new mode-specific behavior**

## Version History

**v1.0 (2025-12-10):** Initial documentation after VR tracking bug fix
- Documented VR Player Mode vs AI Training Mode architecture
- Explained the manual position override bug
- Provided debugging checklist
