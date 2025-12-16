# VR + Physics Quick Reference Guide

**Last Updated:** 2025-12-10
**For:** vr_main.gd dual-mode VR system

---

## Two Control Modes

### VR Player Mode (`physics_movement_enabled = false`)

**Who Controls Position:**
- ✅ VR Tracking (OpenXR)
- ❌ NOT Physics

**Code Pattern:**
```gdscript
func _vr_player_mode_physics(delta: float) -> void:
	# ❌ NEVER DO THIS:
	# player_body.global_position = xr_origin.global_position

	# ✅ CORRECT: Let scene tree handle position
	if not player_body.is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()
```

**Scene Hierarchy:**
```
XROrigin3D (VR tracking controls this)
  └── CharacterBody3D (follows parent automatically)
```

---

### AI Training Mode (`gravity_enabled = true`)

**Who Controls Position:**
- ✅ AI/Physics
- ❌ NOT VR Tracking

**Code Pattern:**
```gdscript
func _ai_training_mode_physics(delta: float) -> void:
	# Physics controls position
	var acceleration = _calculate_total_gravity()
	velocity += acceleration * delta

	player_body.velocity = velocity
	player_body.move_and_slide()

	# ✅ CORRECT: VR camera follows physics
	xr_origin.global_position = player_body.global_position

	velocity = player_body.velocity
```

---

## Critical Rules

### Rule 1: Never Override VR Tracking in VR Player Mode
❌ **WRONG:**
```gdscript
func _vr_player_mode_physics(delta: float):
	player_body.global_position = xr_origin.global_position  # BREAKS VR!
```

✅ **CORRECT:**
```gdscript
func _vr_player_mode_physics(delta: float):
	# CharacterBody3D follows XROrigin3D automatically via scene tree
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()
```

### Rule 2: VR Camera Must Follow Physics in AI Training Mode
❌ **WRONG:**
```gdscript
func _ai_training_mode_physics(delta: float):
	# Physics updates position but VR camera doesn't follow
	player_body.move_and_slide()
	# Missing: xr_origin.global_position = player_body.global_position
```

✅ **CORRECT:**
```gdscript
func _ai_training_mode_physics(delta: float):
	player_body.move_and_slide()
	xr_origin.global_position = player_body.global_position  # VR follows physics
```

### Rule 3: CharacterBody3D MUST Be Child of XROrigin3D
❌ **WRONG Scene Hierarchy:**
```
VRMain
  ├── XROrigin3D
  │   └── XRCamera3D
  └── CharacterBody3D  # ← NOT A CHILD!
```

✅ **CORRECT Scene Hierarchy:**
```
VRMain
  └── XROrigin3D
      ├── XRCamera3D
      └── CharacterBody3D  # ← CHILD OF XROrigin3D
```

---

## Mode Switching

### Switching to VR Player Mode
1. Set `physics_movement_enabled = false` in scene or via code
2. Ensure `gravity_enabled = false`
3. VR tracking takes over immediately
4. CharacterBody3D follows XROrigin3D via scene tree

### Switching to AI Training Mode
1. Set `gravity_enabled = true` in code
2. Physics simulation begins
3. XROrigin3D follows CharacterBody3D
4. VR headset shows AI's perspective

### Code Example
```gdscript
func _physics_process(delta: float) -> void:
	if not is_instance_valid(xr_origin) or not is_instance_valid(player_body):
		return

	# VR PLAYER MODE
	if not physics_movement_enabled:
		_vr_player_mode_physics(delta)
		return

	# AI TRAINING MODE
	if gravity_enabled:
		_ai_training_mode_physics(delta)
```

---

## Common Mistakes & Fixes

### Mistake 1: Manual Position Setting in VR Player Mode
**Symptom:** Gray screen, XROrigin3D stuck at (0,0,0), no head tracking

**Cause:**
```gdscript
func _vr_player_mode_physics(delta: float):
	player_body.global_position = xr_origin.global_position  # ← BUG
```

**Fix:**
```gdscript
func _vr_player_mode_physics(delta: float):
	# Remove manual position setting
	# CharacterBody3D follows XROrigin3D automatically
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()
```

### Mistake 2: Wrong Scene Hierarchy
**Symptom:** VR tracking doesn't affect CharacterBody3D position

**Cause:** CharacterBody3D not child of XROrigin3D

**Fix:** Re-parent CharacterBody3D under XROrigin3D in scene tree

### Mistake 3: Forgetting to Update XROrigin in AI Mode
**Symptom:** VR camera stuck at origin while AI moves around

**Cause:**
```gdscript
func _ai_training_mode_physics(delta: float):
	player_body.move_and_slide()
	# Missing: xr_origin.global_position = player_body.global_position
```

**Fix:**
```gdscript
func _ai_training_mode_physics(delta: float):
	player_body.move_and_slide()
	xr_origin.global_position = player_body.global_position  # ← ADD THIS
```

---

## Testing Checklist

### VR Player Mode
- [ ] Put on VR headset
- [ ] Move head - XRCamera3D position updates
- [ ] Walk around - collision detection works
- [ ] Look at ground - see terrain/objects at correct distance

### AI Training Mode
- [ ] Enable gravity simulation
- [ ] AI controls character movement
- [ ] VR headset shows AI's perspective
- [ ] VR camera follows character smoothly

---

## Troubleshooting

**Gray screen in VR headset:**
1. Check: `XRCamera3D.current == true`
2. Check: `FallbackCamera.current == false`
3. Check: No manual `player_body.global_position =` in VR Player Mode
4. Check: CharacterBody3D is child of XROrigin3D

**VR tracking not updating:**
1. Verify OpenXR initialized (console: "OpenXR initialized successfully")
2. Check for manual position overrides in `_vr_player_mode_physics()`
3. Verify `physics_movement_enabled == false`
4. Test with debug print: `print(xr_origin.global_position)`

**AI mode camera stuck at origin:**
1. Check: `xr_origin.global_position = player_body.global_position` in AI function
2. Verify `gravity_enabled == true`
3. Ensure physics simulation is running

---

## Reference Files

**Implementation:** `vr_main.gd:132-206`
**Scene File:** `scenes/vr_main.tscn`
**Architecture Doc:** `docs/current/guides/VR_ARCHITECTURE.md`
**Bug Report:** `VR_TRACKING_FAILURE_ROOT_CAUSE.md`

---

## Quick Patterns

### Pattern: VR Player Physics
```gdscript
# Physics provides collision/ground detection only
# VR tracking controls position
player_body.velocity = Vector3(0, velocity.y, 0)
player_body.move_and_slide()
is_grounded = player_body.is_on_floor()
```

### Pattern: AI Training Physics
```gdscript
# Physics controls position
# VR camera follows for observation
var acceleration = _calculate_physics()
velocity += acceleration * delta
player_body.velocity = velocity
player_body.move_and_slide()
xr_origin.global_position = player_body.global_position
velocity = player_body.velocity
```

### Pattern: Mode Detection
```gdscript
if not physics_movement_enabled:
	# VR Player Mode
	_vr_player_mode_physics(delta)
elif gravity_enabled:
	# AI Training Mode
	_ai_training_mode_physics(delta)
```

---

**Remember:** VR Player Mode = VR controls position, Physics follows. AI Training Mode = Physics controls position, VR follows.
