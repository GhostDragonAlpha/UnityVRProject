# QuantumRender System Guide

## Overview

The QuantumRender system implements quantum observation mechanics where objects transition between two states based on whether they are visible to the player's camera:

- **Observed State**: Objects appear as solid meshes with full collision detection
- **Unobserved State**: Objects appear as probability clouds (particle systems) with simplified collision

This creates a unique visual effect inspired by quantum mechanics, where unobserved objects exist in a "superposition" state represented by particle clouds, and "collapse" into solid form when observed.

## Requirements Implemented

- **28.1**: Detect objects outside view frustum using VisibleOnScreenNotifier3D
- **28.2**: Render unobserved objects as probability clouds using GPUParticles3D
- **28.3**: Collapse to solid mesh when observed (within 0.1 seconds)
- **28.4**: Use particle systems for clouds
- **28.5**: Simplify collision for unobserved objects

## Key Features

### Automatic State Transitions

Objects automatically transition between observed and unobserved states based on camera visibility:

1. **Collapse** (Unobserved → Observed): When an object enters the camera's view frustum
2. **Decoherence** (Observed → Unobserved): When an object leaves the camera's view frustum

Transitions complete in 0.1 seconds with smooth interpolation.

### Probability Cloud Rendering

Unobserved objects are rendered as particle clouds with:

- 1000 particles per object
- Cyan/blue quantum-themed coloring
- Additive blending for a glowing effect
- Particles distributed within the object's bounding box
- Gentle random motion to simulate quantum uncertainty

### Collision Simplification

When objects are unobserved:

- Original collision shapes are disabled
- Simplified sphere collision shapes are enabled
- Reduces physics computation overhead for distant/invisible objects

## Usage

### Basic Setup

```gdscript
# Create the quantum render system
var quantum_render := QuantumRender.new()
add_child(quantum_render)

# Initialize with the player's camera
var camera := get_viewport().get_camera_3d()
quantum_render.initialize(camera)
```

### Registering Objects

```gdscript
# Register an object for quantum rendering
var object_root := Node3D.new()
var mesh_instance := MeshInstance3D.new()
# ... set up mesh ...

quantum_render.register_object(
	"unique_object_id",
	object_root,
	mesh_instance
)
```

### With Collision Shapes

```gdscript
# Register with collision shape for automatic simplification
var collision_shape := CollisionShape3D.new()
# ... set up collision ...

quantum_render.register_object(
	"object_with_collision",
	object_root,
	mesh_instance,
	collision_shape
)
```

### Monitoring State

```gdscript
# Check if an object is observed
if quantum_render.is_object_observed("object_id"):
	print("Object is in solid form")
else:
	print("Object is a probability cloud")

# Get detailed state
var state := quantum_render.get_object_state("object_id")
match state:
	QuantumRender.QuantumState.OBSERVED:
		print("Fully observed")
	QuantumRender.QuantumState.UNOBSERVED:
		print("Fully unobserved")
	QuantumRender.QuantumState.COLLAPSING:
		print("Transitioning to observed")
	QuantumRender.QuantumState.DECOHERING:
		print("Transitioning to unobserved")
```

### Manual Control

```gdscript
# Force an object to observed state (useful for cutscenes)
quantum_render.force_observe("object_id")

# Force an object to unobserved state
quantum_render.force_unobserve("object_id")
```

### Statistics and Debugging

```gdscript
# Get system statistics
var stats := quantum_render.get_statistics()
print("Total objects: ", stats.total_objects)
print("Observed: ", stats.observed_objects)
print("Unobserved: ", stats.unobserved_objects)
print("Total collapses: ", stats.total_collapses)
print("Total decoherences: ", stats.total_decoherences)
```

## Signals

The system emits signals for monitoring state changes:

```gdscript
# Connect to signals
quantum_render.quantum_initialized.connect(_on_quantum_initialized)
quantum_render.object_collapse.connect(_on_object_collapse)
quantum_render.object_decoherence.connect(_on_object_decoherence)
quantum_render.object_registered.connect(_on_object_registered)
quantum_render.object_unregistered.connect(_on_object_unregistered)

func _on_object_collapse(object_id: String) -> void:
	print("Object %s collapsed to observed state" % object_id)

func _on_object_decoherence(object_id: String) -> void:
	print("Object %s decohered to unobserved state" % object_id)
```

## Performance Considerations

### Update Frequency

By default, the system updates at 60 Hz. You can adjust this for performance:

```gdscript
# Update every frame (0 = every frame)
quantum_render.set_update_frequency(0)

# Update 30 times per second (good balance)
quantum_render.set_update_frequency(30)

# Update 10 times per second (better performance)
quantum_render.set_update_frequency(10)
```

### Particle Count

The default particle count is 1000 per object. For better performance with many objects, you can modify the `CLOUD_PARTICLE_COUNT` constant in the source code.

### Visibility Bounds

Set accurate visibility bounds for better culling:

```gdscript
# Set custom AABB for an object
var bounds := AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
quantum_render.set_object_bounds("object_id", bounds)
```

## Integration with Other Systems

### With LOD Manager

The QuantumRender system works alongside the LOD Manager:

```gdscript
# Register with both systems
lod_manager.register_object("obj_id", root, lod_levels)
quantum_render.register_object("obj_id", root, lod_levels[0])
```

### With Floating Origin

The system automatically works with floating origin rebasing since it uses relative positions from the root nodes.

### With Physics Engine

Collision simplification reduces physics overhead:

- Observed objects: Full collision detection
- Unobserved objects: Simple sphere collision
- Transitioning objects: Collision state changes at transition completion

## Best Practices

1. **Register objects early**: Register objects during scene initialization for smooth transitions
2. **Use unique IDs**: Ensure each object has a unique identifier
3. **Set accurate bounds**: Proper visibility bounds improve culling accuracy
4. **Monitor statistics**: Use statistics to optimize particle counts and update frequency
5. **Test transitions**: Verify transitions look smooth at your target frame rate

## Troubleshooting

### Objects not transitioning

- Verify the camera reference is set correctly
- Check that VisibleOnScreenNotifier3D is properly configured
- Ensure objects have valid visibility bounds

### Performance issues

- Reduce update frequency
- Lower particle count (modify CLOUD_PARTICLE_COUNT)
- Reduce number of registered objects
- Use more aggressive visibility bounds

### Particles not visible

- Check that particle materials are set up correctly
- Verify particle emission is enabled
- Ensure visibility_aabb is large enough
- Check that particles aren't being culled by the camera

## Example: Asteroid Field

```gdscript
extends Node3D

var quantum_render: QuantumRender

func _ready() -> void:
	# Set up quantum render
	quantum_render = QuantumRender.new()
	add_child(quantum_render)
	quantum_render.initialize(get_viewport().get_camera_3d())

	# Create asteroid field
	for i in range(100):
		create_quantum_asteroid(i)

func create_quantum_asteroid(index: int) -> void:
	var asteroid := Node3D.new()
	asteroid.name = "Asteroid_%d" % index
	asteroid.position = Vector3(
		randf_range(-100, 100),
		randf_range(-100, 100),
		randf_range(-100, 100)
	)
	add_child(asteroid)

	# Create mesh
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = SphereMesh.new()
	asteroid.add_child(mesh_instance)

	# Create collision
	var collision := CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	asteroid.add_child(collision)

	# Register with quantum render
	quantum_render.register_object(
		"asteroid_%d" % index,
		asteroid,
		mesh_instance,
		collision
	)
```

## Future Enhancements

Potential improvements for future versions:

1. **Configurable particle appearance**: Allow customization of particle colors, sizes, and behaviors
2. **Multiple collapse styles**: Different transition effects (fade, materialize, etc.)
3. **Distance-based particle density**: Fewer particles for distant objects
4. **Quantum entanglement**: Link related objects' quantum states
5. **Wave function visualization**: Show probability distributions as heat maps

## Technical Details

### State Machine

The system uses a simple state machine with four states:

```
OBSERVED ←→ DECOHERING ←→ UNOBSERVED ←→ COLLAPSING ←→ OBSERVED
```

Transitions are triggered by visibility changes and complete over COLLAPSE_DURATION (0.1 seconds).

### Particle System

Particles use:

- `ParticleProcessMaterial` for physics simulation
- `StandardMaterial3D` with additive blending for appearance
- `SphereMesh` as the particle shape
- Emission box matching the object's bounds

### Collision Simplification

Original collision shapes are analyzed to create simplified sphere collisions:

- Box shapes: Sphere radius = diagonal length / 2
- Sphere shapes: Same radius
- Capsule shapes: Radius = max(capsule radius, height / 2)
- Other shapes: Default radius of 1.0

## API Reference

See the inline documentation in `quantum_render.gd` for complete API details.
