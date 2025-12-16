# Spacecraft Control Quick Reference

## Keyboard Controls

```
┌───────────────────────────────────────────┐
│  W/S      Forward/Backward Thrust         │
│  SPACE    Vertical Thrust Up              │
│  CTRL     Vertical Thrust Down            │
│  A/D      Yaw (Turn Left/Right)           │
│  Q/E      Roll (Barrel Roll)              │
└───────────────────────────────────────────┘
```

## Physics Constants

| Property | Value |
|----------|-------|
| Base Thrust | 50,000 N |
| Max Thrust | 500,000 N |
| Rotation Speed | 45 deg/sec |
| Angular Damping | 0.5 |
| Gravity | 0.0 (space) |

## GDScript API

```gdscript
# Basic controls
spacecraft.set_throttle(0.5)                    # 50% thrust
spacecraft.apply_rotation(pitch, yaw, roll)     # Rotation

# State queries
var vel = spacecraft.get_velocity()             # Vector3
var speed = spacecraft.get_velocity_magnitude() # float
var stats = spacecraft.get_statistics()         # Dictionary

# Upgrades
spacecraft.apply_upgrade("engine", 2)           # Level 2 engine

# Utility
spacecraft.stop()                               # Emergency stop
spacecraft.reset_state()                        # Reset all
```

## Upgrade System

Each level = +25% improvement

| Type | Effect |
|------|--------|
| engine | Thrust power |
| rotation | Rotation power |
| mass | Reduces mass |
| shields | No physics effect |

## Requirements Met

✓ 31.1: Force via Godot Physics
✓ 31.2: Newton's first law
✓ 31.3: Angular damping
✓ 31.4: Vector force sum
✓ 31.5: Impulse on collision

## Scene Integration

**Status:** Not instantiated in vr_main.tscn

**To add:**
1. Add RigidBody3D node named "Spacecraft"
2. Attach `scripts/player/spacecraft.gd`
3. Add CollisionShape3D child
4. Add visual mesh

## Test Results

**Success Rate:** 83.3% (5/6 tests passed)

**Passed:**
- Control Mappings
- Physics Properties
- Upgrade System
- Requirements Compliance
- API Integration

**Failed:**
- Scene Integration (not in scene)

---

**Implementation File:** `C:/godot/scripts/player/spacecraft.gd`
**Test Report:** `C:/godot/SPACECRAFT_TEST_RESULTS.md`
**Test Data:** `C:/godot/spacecraft_test_results.json`
