# Validation Tools Guide

## Overview

The validation system provides comprehensive testing for game systems, particularly collision detection and scene integrity. The collision validator ensures all interactive elements and physical objects have proper collision shapes configured.

## System Architecture

### Collision Shape Validator (`collision_validator.gd`)

An automated test script that validates collision shapes in three key scenes:
- **cockpit_model.tscn** - Spacecraft interior controls
- **spacecraft_exterior.tscn** - Spacecraft physics body
- **creature_test.tscn** - Creature interaction testing

**Location**: `C:/godot/scripts/validation/collision_validator.gd`

**Type**: Standalone test script (runs to completion, exits automatically)

## Setup

### Scene Configuration

Ensure the following scenes exist with correct structure:

#### 1. Cockpit Model (`res://scenes/spacecraft/cockpit_model.tscn`)

Required structure:
```
cockpit_model (Node3D)
└── InteractionAreas (Node3D)
    ├── ThrottleArea (Area3D)
    │   └── CollisionShape3D
    │       └── BoxShape3D (throttle_area)
    ├── PowerButtonArea (Area3D)
    │   └── CollisionShape3D
    │       └── BoxShape3D (power_button)
    ├── NavModeSwitchArea (Area3D)
    │   └── CollisionShape3D
    │       └── BoxShape3D (nav_switch)
    ├── TimeAccelDialArea (Area3D)
    │   └── CollisionShape3D
    │       └── BoxShape3D (time_dial)
    └── SignalBoostButtonArea (Area3D)
        └── CollisionShape3D
            └── BoxShape3D (signal_button)
```

#### 2. Spacecraft Exterior (`res://scenes/spacecraft/spacecraft_exterior.tscn`)

Required structure:
```
spacecraft_exterior (RigidBody3D)
└── CollisionShape (CollisionShape3D)
    └── BoxShape3D
```

#### 3. Creature Test (`res://scenes/creature_test.tscn`)

Required structure:
```
creature_test (Node3D)
├── SpaceRabbit (CharacterBody3D or RigidBody3D)
│   └── CollisionShape3D
│       └── Shape3D (BoxShape3D, CapsuleShape3D, etc.)
└── Ground (StaticBody3D)
    └── CollisionShape3D
        └── Shape3D
```

## Running Validation

### Run in Godot Editor

1. Create a new scene with the collision validator as the root node
2. Attach the `collision_validator.gd` script
3. Run the scene (F5)
4. Results print to console and exit automatically

### Run from Command Line

```bash
# Linux/Mac
godot --path C:/godot --script scripts/validation/collision_validator.gd

# Windows
godot.exe --path C:\godot --script scripts\validation\collision_validator.gd

# Headless mode (faster, no GUI)
godot --headless --path C:/godot --script scripts/validation/collision_validator.gd
```

### Automated CI/CD Integration

Add to GitHub Actions workflow:

```yaml
name: Collision Validation

on: [push, pull_request]

jobs:
  validate-collisions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.5

      - name: Run Collision Validation
        run: |
          godot --headless --path . --script scripts/validation/collision_validator.gd
          EXIT_CODE=$?
          if [ $EXIT_CODE -ne 0 ]; then
            echo "Collision validation failed!"
            exit 1
          fi
```

## Test Results

### Success Output

When all validations pass:

```
================================================================================
COLLISION SHAPE VALIDATION TEST
================================================================================

[1/3] Validating cockpit_model.tscn...
[2/3] Validating spacecraft_exterior.tscn...
[3/3] Validating creature_test.tscn...

================================================================================
VALIDATION RESULTS
================================================================================

[PASS] cockpit_load: PASS
  Message: Scene loaded successfully

[PASS] cockpit_shapes: PASS
  Message: All 5 collision shapes validated
  ✓ ThrottleArea: Valid BoxShape3D (monitoring: true)
  ✓ PowerButtonArea: Valid BoxShape3D (monitoring: true)
  ✓ NavModeSwitchArea: Valid BoxShape3D (monitoring: true)
  ✓ TimeAccelDialArea: Valid BoxShape3D (monitoring: true)
  ✓ SignalBoostButtonArea: Valid BoxShape3D (monitoring: true)

[PASS] spacecraft_collision: PASS
  Message: Valid BoxShape3D with size: (10, 15, 25)

[PASS] creature_test: PASS
  Message: Rabbit: CapsuleShape3D, Ground: BoxShape3D

================================================================================
SUMMARY: 4/4 tests passed
[SUCCESS] ALL TESTS PASSED
================================================================================
```

### Failure Output

When validation fails:

```
================================================================================
COLLISION SHAPE VALIDATION TEST
================================================================================

[1/3] Validating cockpit_model.tscn...

================================================================================
VALIDATION RESULTS
================================================================================

[FAIL] cockpit_load: FAIL
  Message: Failed to load scene

[FAIL] cockpit_shapes: FAIL
  Message: Some shapes failed validation
  ✗ ThrottleArea: Area3D not found
  ✗ PowerButtonArea: CollisionShape3D not found
  ✓ NavModeSwitchArea: Valid BoxShape3D (monitoring: true)
  ✗ TimeAccelDialArea: Shape is not BoxShape3D (got SphereShape3D)
  ✗ SignalBoostButtonArea: Shape is null

[FAIL] spacecraft_collision: FAIL
  Message: CollisionShape node not found

[FAIL] creature_test: FAIL
  Message: Failed to load scene

================================================================================
SUMMARY: 0/4 tests passed
[FAILED] SOME TESTS FAILED
================================================================================
```

## Detailed Validation Checks

### Cockpit Model Validation

Tests for each interactive area:

```
1. Area3D exists
2. Area3D is actual Area3D node (not another type)
3. CollisionShape3D child exists
4. CollisionShape3D.shape is not null
5. Shape is BoxShape3D (not other shape types)
6. Area3D is monitoring (ready to detect overlaps)
```

**Expected Areas**:
- ThrottleArea - Control throttle/acceleration
- PowerButtonArea - Toggle spacecraft power
- NavModeSwitchArea - Switch navigation modes
- TimeAccelDialArea - Control time acceleration
- SignalBoostButtonArea - Boost signal strength

### Spacecraft Exterior Validation

Tests for main collision body:

```
1. CollisionShape node exists
2. CollisionShape.shape is not null
3. Shape is BoxShape3D
4. Box dimensions (size) are reasonable
```

**Expected Configuration**:
```
Size: Sufficient to encompass spacecraft model (typically 10-25 units each axis)
Type: BoxShape3D (simplest, fastest collision)
```

### Creature Test Validation

Tests creature and environment collisions:

```
1. SpaceRabbit node exists
2. SpaceRabbit has CollisionShape3D
3. CollisionShape3D.shape is valid
4. Ground node exists
5. Ground has CollisionShape3D
6. Ground CollisionShape3D.shape is valid
```

**Expected Configuration**:
```
Rabbit: CapsuleShape3D or BoxShape3D (creature body)
Ground: BoxShape3D or PlaneShape3D (flat surface)
```

## Test Results Dictionary

Each test result has this structure:

```gdscript
{
    "status": "PASS" or "FAIL",
    "message": "Human-readable description",
    "details": [
        "✓ or ✗ item description",
        ...
    ]
}
```

### Accessing Results Programmatically

```gdscript
# Extend collision_validator.gd to use results
extends Node

var validation_results = {}

func _ready() -> void:
    # Run validation
    validate_all_scenes()

    # Check results
    for test_name in validation_results:
        var result = validation_results[test_name]
        if result.status == "FAIL":
            print("FAILED TEST: ", test_name)
            print("  Reason: ", result.message)

func check_specific_result(test_name: String) -> bool:
    return validation_results.get(test_name, {}).get("status") == "PASS"
```

## Extending Validation

### Add Custom Shape Validation

```gdscript
func validate_custom_scene() -> void:
    var scene_path := "res://scenes/custom/my_scene.tscn"
    var scene := load(scene_path)

    if scene == null:
        validation_results["custom_load"] = {
            "status": "FAIL",
            "message": "Failed to load scene"
        }
        return

    var instance := scene.instantiate()
    add_child(instance)
    await get_tree().process_frame

    # Validate specific node
    var my_collision = instance.get_node_or_null("CollisionShape3D")
    if my_collision and my_collision.shape is BoxShape3D:
        validation_results["custom_shape"] = {
            "status": "PASS",
            "message": "Shape validated"
        }
    else:
        validation_results["custom_shape"] = {
            "status": "FAIL",
            "message": "Invalid shape"
        }

    instance.queue_free()
```

### Add Physics Validation

```gdscript
func validate_physics_interactions() -> void:
    # Test collision detection
    var area1 = Area3D.new()
    var shape1 = BoxShape3D.new()
    var collision1 = CollisionShape3D.new()
    collision1.shape = shape1
    area1.add_child(collision1)

    var area2 = Area3D.new()
    var shape2 = BoxShape3D.new()
    var collision2 = CollisionShape3D.new()
    collision2.shape = shape2
    area2.add_child(collision2)

    # Position overlapping
    area1.position = Vector3.ZERO
    area2.position = Vector3(1, 0, 0)

    add_child(area1)
    add_child(area2)

    await get_tree().process_frame

    # Check overlap detection
    var overlaps = area1.get_overlapping_areas()
    if area2 in overlaps:
        validation_results["physics_overlap"] = {
            "status": "PASS",
            "message": "Overlap detection working"
        }
    else:
        validation_results["physics_overlap"] = {
            "status": "FAIL",
            "message": "Overlap not detected"
        }

    area1.queue_free()
    area2.queue_free()
```

## Common Issues and Fixes

### Issue: "Scene not found"
**Cause**: Scene path is incorrect or file doesn't exist
**Fix**:
```gdscript
# Verify scene exists
var scene_path = "res://scenes/spacecraft/cockpit_model.tscn"
if not ResourceLoader.exists(scene_path):
    print("ERROR: Scene not found at ", scene_path)
    print("Checking alternatives...")

    # List available scenes
    var dir = DirAccess.open("res://scenes/spacecraft/")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tscn"):
                print("  - ", file_name)
            file_name = dir.get_next()
```

### Issue: "Area3D not found" or "CollisionShape3D not found"
**Cause**: Node structure doesn't match expected hierarchy
**Fix**:
```gdscript
# Debug node structure
func print_node_tree(node: Node, indent: String = "") -> void:
    print(indent + node.name + " (" + node.get_class() + ")")
    for child in node.get_children():
        print_node_tree(child, indent + "  ")

# Use in validation
var instance = scene.instantiate()
add_child(instance)
await get_tree().process_frame
print_node_tree(instance)
```

### Issue: "Shape is not BoxShape3D"
**Cause**: Wrong shape type configured in scene
**Fix**:
```gdscript
# Check actual shape type
var collision_shape = area.get_node_or_null("CollisionShape3D")
if collision_shape:
    print("Shape type: ", collision_shape.shape.get_class())

    # Convert if possible
    if collision_shape.shape is SphereShape3D:
        # Replace with BoxShape3D
        var new_shape = BoxShape3D.new()
        new_shape.size = Vector3(1, 1, 1)  # Adjust size as needed
        collision_shape.shape = new_shape
```

### Issue: "Shape is null"
**Cause**: CollisionShape3D node exists but has no shape assigned
**Fix**:
```gdscript
# Add missing shape
var collision_shape = area.get_node_or_null("CollisionShape3D")
if collision_shape and collision_shape.shape == null:
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(1, 1, 1)
    collision_shape.shape = box_shape
    print("Shape assigned to ", area.name)
```

## Best Practices

1. **Run validation before each commit**:
```bash
godot --headless --path . --script scripts/validation/collision_validator.gd
```

2. **Validate after scene edits**:
- Change a collision area? Run validator
- Modify physics shapes? Run validator
- Add new interactive areas? Run validator

3. **Integrate with pre-commit hooks**:
```bash
#!/bin/bash
# .git/hooks/pre-commit

if git diff --cached --name-only | grep -E "\.tscn$"; then
    godot --headless --path . --script scripts/validation/collision_validator.gd
    if [ $? -ne 0 ]; then
        echo "Collision validation failed! Commit aborted."
        exit 1
    fi
fi
```

4. **Test after physics changes**:
- Godot physics engine updates
- Custom physics system changes
- Collision layer/mask modifications

5. **Document expected shapes**:
- Add comments in scene files
- Maintain shape documentation
- Keep collision requirements in code

## Performance Notes

- **Speed**: Validates 3 scenes in <1 second
- **Memory**: Minimal overhead
- **Headless mode**: 2-3x faster than GUI mode
- **CPU**: Single-threaded, no optimization needed

## Related Documentation

- **COLLISION_SHAPES_REFERENCE.md** - Shape type guide
- **PHYSICS_SYSTEM.md** - Physics integration details
- **TESTING_GUIDE.md** - Overall testing strategy

## Support

For validation issues:
1. Check scene structure matches expected hierarchy
2. Verify all required nodes exist
3. Run with print statements to debug node tree
4. Export scene to file to examine structure
5. Check Godot output panel for detailed errors
