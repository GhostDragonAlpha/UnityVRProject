# Null Guard Quick Reference Card

**For:** SpaceTime VR Developers
**Purpose:** Quick lookup for implementing null guards in GDScript

---

## The 5 Guard Patterns

### Pattern 1: Simple Validation
**When:** Accessing any object property/method that could be null
```gdscript
if not is_instance_valid(object):
    return  # or return safe_default
```

### Pattern 2: Type-Specific Validation
**When:** Object must be specific type (Camera3D, RigidBody3D, etc.)
```gdscript
if not (is_instance_valid(object) and object is ExpectedType):
    object = null  # Clear invalid reference
    return
```

### Pattern 3: Loop Skip
**When:** Iterating over array of objects that could be invalid
```gdscript
for item in array:
    if not is_instance_valid(item):
        continue  # Skip invalid items
    # Safe to use item here
```

### Pattern 4: Safe Fallback
**When:** Function must return a value
```gdscript
if not is_instance_valid(object):
    return INF           # For distances
    return Vector3.ZERO  # For directions
    return false         # For boolean checks
    return []            # For arrays
```

### Pattern 5: Creation Validation
**When:** Creating new objects that could fail
```gdscript
var obj = SomeType.new()
if not is_instance_valid(obj):
    push_error("Failed to create: " + context)
    cleanup_partial_state()
    return
# Safe to use obj here
```

---

## Common Scenarios

### Scenario: Accessing Camera
```gdscript
# ❌ WRONG - Could crash if camera is freed
var pos = _camera.global_position

# ✅ CORRECT - Pattern 2 (type check)
if not (is_instance_valid(_camera) and _camera is Camera3D):
    _camera = null
    return
var pos = _camera.global_position
```

### Scenario: Applying Physics Force
```gdscript
# ❌ WRONG - Could crash if body is freed
body.apply_central_force(force)

# ✅ CORRECT - Pattern 1 with null check
if body == null or not is_instance_valid(body):
    return
body.apply_central_force(force)
```

### Scenario: Updating All Objects
```gdscript
# ❌ WRONG - Could crash on freed object
for obj in objects:
    obj.update()

# ✅ CORRECT - Pattern 3 (loop skip)
for obj in objects:
    if not is_instance_valid(obj):
        continue
    obj.update()
```

### Scenario: Parent-Child Relationship
```gdscript
# ❌ WRONG - Could crash if parent freed
var distance = get_distance_to(parent_body)
var soi = calculate_hill_sphere(distance, parent_body.mass)

# ✅ CORRECT - Pattern 4 (safe fallback)
if is_instance_valid(parent_body):
    var distance = get_distance_to(parent_body)
    if distance > EPSILON and distance < INF:
        sphere_of_influence = calculate_hill_sphere(distance, parent_body.mass)
    else:
        sphere_of_influence = radius * pow(mass / 1000.0, 0.4) * 10.0
else:
    sphere_of_influence = radius * pow(mass / 1000.0, 0.4) * 10.0
```

### Scenario: Creating Visual Model
```gdscript
# ❌ WRONG - Could crash if creation fails
var model = MeshInstance3D.new()
var mesh = SphereMesh.new()
mesh.radius = 100.0
model.mesh = mesh

# ✅ CORRECT - Pattern 5 (creation validation)
var model = MeshInstance3D.new()
if not is_instance_valid(model):
    push_error("Failed to create MeshInstance3D")
    return

var mesh = SphereMesh.new()
if not is_instance_valid(mesh):
    push_error("Failed to create SphereMesh")
    model.queue_free()
    return

mesh.radius = 100.0
model.mesh = mesh
```

---

## Checklist for Code Review

When reviewing code, check for these common issues:

- [ ] ✅ All object property accesses have `is_instance_valid()` check
- [ ] ✅ Type-specific operations include type check (`object is Type`)
- [ ] ✅ Loops over object arrays skip invalid items
- [ ] ✅ Functions return safe defaults for invalid inputs
- [ ] ✅ Object creation is validated before use
- [ ] ✅ Parent-child relationships check parent validity
- [ ] ✅ Error messages include context (object name, operation)
- [ ] ✅ Partial state is cleaned up on failure
- [ ] ✅ Invalid references are nulled to prevent future access

---

## Safe Default Values

Choose appropriate defaults based on data type:

| Type | Safe Default | Use Case |
|------|-------------|----------|
| `float` (distance) | `INF` | Indicates unreachable/invalid distance |
| `float` (percentage) | `0.0` | No effect |
| `float` (multiplier) | `1.0` | Neutral multiplier |
| `Vector3` (direction) | `Vector3.ZERO` | No direction |
| `Vector3` (position) | `Vector3.ZERO` | Origin point |
| `bool` | `false` | Safe negative result |
| `Array` | `[]` | Empty array |
| `Dictionary` | `{}` | Empty dictionary |
| `int` (index) | `-1` | Invalid index indicator |
| `Object` | `null` | No object |

---

## Performance Best Practices

### ✅ DO
```gdscript
# Cache the check result if used multiple times
if not is_instance_valid(object):
    return

var pos = object.global_position
var rot = object.global_rotation
var scale = object.scale
```

### ❌ DON'T
```gdscript
# Don't check multiple times for same object
if not is_instance_valid(object):
    return
var pos = object.global_position

if not is_instance_valid(object):  # Redundant!
    return
var rot = object.global_rotation
```

### ✅ DO
```gdscript
# Early return to skip unnecessary work
if not is_instance_valid(object):
    return

# Expensive calculations only if valid
var complex_result = expensive_calculation(object)
```

### ❌ DON'T
```gdscript
# Don't do expensive work before checking
var complex_result = expensive_calculation(object)

if not is_instance_valid(object):  # Too late!
    return
```

---

## Error Logging Best Practices

### ✅ GOOD - Includes context
```gdscript
if not is_instance_valid(model):
    push_error("Failed to create MeshInstance3D for celestial body: " + body_name)
    return
```

### ❌ BAD - No context
```gdscript
if not is_instance_valid(model):
    push_error("Model is invalid")
    return
```

### ✅ GOOD - Logs and handles gracefully
```gdscript
if not is_instance_valid(sphere_mesh):
    push_error("Failed to create SphereMesh for: " + body_name)
    model.queue_free()
    model = null
    return
```

### ❌ BAD - Logs but leaves invalid state
```gdscript
if not is_instance_valid(sphere_mesh):
    push_error("Mesh creation failed")
    # model is now in invalid state!
```

---

## Common Pitfalls to Avoid

### Pitfall 1: Checking null but not validity
```gdscript
# ❌ WRONG - Freed objects are not null!
if object != null:
    object.do_something()

# ✅ CORRECT - Always use is_instance_valid()
if is_instance_valid(object):
    object.do_something()
```

### Pitfall 2: Not checking type
```gdscript
# ❌ WRONG - Could be wrong type
if is_instance_valid(node):
    var pos = node.global_position  # Works for any Node3D
    var fov = node.fov              # Crashes if not Camera3D!

# ✅ CORRECT - Check specific type
if is_instance_valid(node) and node is Camera3D:
    var pos = node.global_position
    var fov = node.fov
```

### Pitfall 3: Forgetting to clean up on failure
```gdscript
# ❌ WRONG - Leaves orphaned objects
var model = MeshInstance3D.new()
var mesh = SphereMesh.new()
if not is_instance_valid(mesh):
    return  # model is orphaned!

# ✅ CORRECT - Clean up partial state
var model = MeshInstance3D.new()
var mesh = SphereMesh.new()
if not is_instance_valid(mesh):
    model.queue_free()  # Clean up
    return
```

### Pitfall 4: Accessing properties in error messages
```gdscript
# ❌ WRONG - Could crash in error handler!
if not is_instance_valid(object):
    push_error("Invalid object: " + object.name)  # Accessing .name on invalid object!

# ✅ CORRECT - Don't access invalid objects
var obj_name = object.name if is_instance_valid(object) else "unknown"
if not is_instance_valid(object):
    push_error("Invalid object: " + obj_name)
```

---

## Testing Your Guards

### Manual Test Checklist
- [ ] Test with object set to null
- [ ] Test with object freed but reference remains
- [ ] Test with wrong type of object
- [ ] Test during scene cleanup/switching
- [ ] Test with rapid object creation/deletion

### Code to Test Null Guards
```gdscript
# Create a test scene
func test_null_guards():
    # Test 1: Null object
    var obj = null
    your_function(obj)  # Should not crash

    # Test 2: Invalid object (freed)
    obj = RigidBody3D.new()
    obj.queue_free()
    await get_tree().process_frame
    your_function(obj)  # Should not crash

    # Test 3: Wrong type
    obj = Node3D.new()  # Not RigidBody3D
    your_function(obj)  # Should detect wrong type
    obj.queue_free()
```

---

## Integration with Existing Code

### Adding Guards to Existing Function
```gdscript
# BEFORE
func update_object(obj: Node3D) -> void:
    obj.position += velocity * delta
    obj.rotation += angular_velocity * delta

# AFTER
func update_object(obj: Node3D) -> void:
    # Add guard at start
    if not is_instance_valid(obj):
        return

    obj.position += velocity * delta
    obj.rotation += angular_velocity * delta
```

### Adding Guards to Loops
```gdscript
# BEFORE
func update_all_objects() -> void:
    for obj in objects:
        obj.update()

# AFTER
func update_all_objects() -> void:
    for obj in objects:
        # Add guard inside loop
        if not is_instance_valid(obj):
            continue
        obj.update()
```

---

## Quick Decision Tree

```
Need to access object?
  │
  ├─ Is it nullable? ──NO──> No guard needed
  │        │
  │       YES
  │        │
  ├─ In a loop? ──YES──> Use Pattern 3 (continue)
  │        │
  │       NO
  │        │
  ├─ Needs specific type? ──YES──> Use Pattern 2 (type check)
  │        │
  │       NO
  │        │
  ├─ Must return value? ──YES──> Use Pattern 4 (safe default)
  │        │
  │       NO
  │        │
  └─────> Use Pattern 1 (simple check)
```

---

## Example: Complete Guard Implementation

```gdscript
## Update LOD for a single object
func _update_object_lod(lod_data: LODObjectData, camera_pos: Vector3) -> void:
    # GUARD 1: Check if root node is valid
    if not is_instance_valid(lod_data.root_node):
        # Clean up invalid entry
        _objects.erase(lod_data.object_id)
        return

    # GUARD 2: Check visibility notifier
    if lod_data.visibility_notifier != null and is_instance_valid(lod_data.visibility_notifier):
        lod_data.is_visible = lod_data.visibility_notifier.is_on_screen()

        if not lod_data.is_visible:
            # Use lowest LOD for invisible objects
            var lowest_lod := lod_data.lod_levels.size() - 1
            if lod_data.current_lod != lowest_lod:
                _set_lod_level(lod_data, lowest_lod)
            return

    # Safe to proceed - all guards passed
    var object_pos := lod_data.root_node.global_position
    var distance := camera_pos.distance_to(object_pos)
    var new_lod := _calculate_lod_level(distance, lod_data)

    if new_lod != lod_data.current_lod:
        _set_lod_level(lod_data, new_lod)
```

---

## References

- **Full Validation Report:** `NULL_GUARD_VALIDATION.md`
- **Summary:** `NULL_GUARD_SUMMARY.md`
- **Visual Diagrams:** `NULL_GUARD_DIAGRAM.md`
- **Test Suite:** `tests/validate_null_guards.gd`

---

**Version:** 1.0
**Last Updated:** 2025-12-03
**Quick Reference for:** SpaceTime VR Development Team
