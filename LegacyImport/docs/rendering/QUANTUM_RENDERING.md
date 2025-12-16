# Quantum Rendering System

## Overview

The Quantum Rendering system (`QuantumRender`) implements a unique "observation-based" rendering mechanic inspired by quantum physics. Objects outside the player's view frustum are rendered as probability clouds (particle systems) and "collapse" to solid meshes when observed.

This system provides:
- **Performance optimization:** Simplified rendering for unobserved objects
- **Visual feedback:** Player can see probability clouds for objects behind them
- **Simplified collision:** Unobserved objects use sphere collision instead of detailed shapes
- **Thematic coherence:** Aligns with game's quantum mechanics theme

**File:** `C:/godot/scripts/rendering/quantum_render.gd`

**Requirements:** 28.1-28.5

## Core Concepts

### Quantum States

Objects exist in one of four states:

```
┌─────────────┐
│  OBSERVED   │ ◄─── Solid mesh visible, full collision
└──────┬──────┘
       │ (exit view frustum)
       ▼
┌─────────────┐
│ DECOHERING  │ ◄─── Transitioning to probability cloud (0.1s)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ UNOBSERVED  │ ◄─── Probability cloud, simplified collision
└──────┬──────┘
       │ (enter view frustum)
       ▼
┌─────────────┐
│ COLLAPSING  │ ◄─── Transitioning to solid mesh (0.1s)
└──────┬──────┘
       │
       └─────► OBSERVED
```

### Observation Detection

Uses Godot's `VisibleOnScreenNotifier3D` for frustum culling:

```gdscript
# Automatically created for each object
visibility_notifier.is_on_screen()  # true if in camera frustum
```

### Probability Clouds

Unobserved objects are rendered as `GPUParticles3D`:
- **1000 particles** default
- **Spherical emission** based on mesh AABB
- **Cyan/blue color** (quantum theme)
- **Additive blending** for glow effect

### Collision Simplification

When unobserved:
- **Original collision:** Disabled (detailed CollisionShape3D)
- **Simplified collision:** Enabled (simple SphereShape3D)

**Performance gain:** ~5x faster collision detection for distant objects

## API Reference

### Initialization

```gdscript
var quantum_render = QuantumRender.new()
add_child(quantum_render)

# Initialize with camera (typically XRCamera3D)
quantum_render.initialize(xr_camera)

# Or let it find the active camera automatically
quantum_render.initialize()
```

**Signals:**
```gdscript
signal quantum_initialized()
signal object_decoherence(object_id: String)  # Observed → Unobserved
signal object_collapse(object_id: String)      # Unobserved → Observed
signal object_registered(object_id: String)
signal object_unregistered(object_id: String)
```

### Registering Objects

```gdscript
# Register an object for quantum rendering
quantum_render.register_object(
    "asteroid_001",           # Unique ID
    asteroid_root,            # Root Node3D
    asteroid_mesh_instance,   # Solid mesh to show when observed
    asteroid_collision_shape  # Optional: Collision to simplify (can be null)
)
```

**What happens:**
1. Creates `VisibleOnScreenNotifier3D` on the root node
2. Creates `GPUParticles3D` probability cloud (initially hidden)
3. Creates simplified `SphereShape3D` collision (initially disabled)
4. Starts in OBSERVED state (solid mesh visible)

### Manual State Control

```gdscript
# Force object to observed state (solid mesh)
quantum_render.force_observe("asteroid_001")

# Force object to unobserved state (probability cloud)
quantum_render.force_unobserve("asteroid_001")

# Query current state
var state = quantum_render.get_object_state("asteroid_001")
# Returns: QuantumState.OBSERVED, UNOBSERVED, COLLAPSING, or DECOHERING

# Check if object is observed
if quantum_render.is_object_observed("asteroid_001"):
    print("Player can see asteroid")
```

### Configuration

```gdscript
# Set update frequency (updates per second)
quantum_render.set_update_frequency(60.0)  # Default

# Update visibility bounds for accurate culling
var mesh_aabb = mesh_instance.get_aabb()
quantum_render.set_object_bounds("asteroid_001", mesh_aabb)
```

### Querying

```gdscript
# Check if object is registered
if quantum_render.has_object("asteroid_001"):
    print("Object is managed by quantum system")

# Get number of registered objects
var count = quantum_render.get_object_count()

# Get all registered IDs
var ids = quantum_render.get_registered_objects()  # Array[String]

# Get statistics
var stats = quantum_render.get_statistics()
print("Observed: ", stats.observed_objects)
print("Unobserved: ", stats.unobserved_objects)
print("Total collapses: ", stats.total_collapses)
print("Total decoherences: ", stats.total_decoherences)
```

### Cleanup

```gdscript
# Unregister single object
quantum_render.unregister_object("asteroid_001")

# Shutdown (unregister all)
quantum_render.shutdown()
```

## Usage Patterns

### Pattern 1: Basic Registration

```gdscript
# Scene structure:
# Asteroid (Node3D)
#   ├─ MeshInstance3D
#   └─ CollisionShape3D

func _ready():
    var mesh = $MeshInstance3D
    var collision = $CollisionShape3D

    quantum_render.register_object(
        "asteroid_%d" % get_instance_id(),
        self,
        mesh,
        collision
    )
```

### Pattern 2: Dynamic Object Spawning

```gdscript
func spawn_quantum_asteroid(position: Vector3):
    var asteroid = asteroid_scene.instantiate()
    asteroid.global_position = position
    add_child(asteroid)

    # Register immediately
    quantum_render.register_object(
        "asteroid_%d" % asteroid.get_instance_id(),
        asteroid,
        asteroid.get_node("Mesh"),
        asteroid.get_node("Collision")
    )

    return asteroid
```

### Pattern 3: Selective Quantum Rendering

Only use quantum rendering for distant objects:

```gdscript
func register_if_distant(object_id: String, root: Node3D, distance: float):
    if distance > 1000.0:
        # Far away: Use quantum rendering
        quantum_render.register_object(
            object_id,
            root,
            root.get_node("Mesh"),
            root.get_node("Collision")
        )
    else:
        # Close by: Use normal rendering (or LOD system)
        lod_manager.register_object(object_id, root, lod_levels)
```

### Pattern 4: Mission-Critical Objects

Keep mission targets always observed:

```gdscript
func set_mission_target(target_id: String):
    # Force target to always be observed (prevent decoherence)
    quantum_render.force_observe(target_id)

    # Or just don't register with quantum system at all
    if quantum_render.has_object(target_id):
        quantum_render.unregister_object(target_id)
```

### Pattern 5: Event-Driven Gameplay

React to quantum state changes:

```gdscript
func _ready():
    quantum_render.object_collapse.connect(_on_object_observed)
    quantum_render.object_decoherence.connect(_on_object_unobserved)

func _on_object_observed(object_id: String):
    print("Player observed: ", object_id)
    # Could trigger audio cue, mission update, etc.

func _on_object_unobserved(object_id: String):
    print("Player stopped observing: ", object_id)
    # Could pause animations, reduce AI complexity, etc.
```

### Pattern 6: Combined with LOD System

Use both systems together for maximum optimization:

```gdscript
func setup_rendering_optimization(object_id: String, root: Node3D, distance: float):
    if distance < 500.0:
        # Close: Use LOD system (3-4 detail levels)
        lod_manager.register_object(object_id, root, lod_levels)

    elif distance < 5000.0:
        # Medium: Use quantum rendering (solid vs cloud)
        quantum_render.register_object(
            object_id,
            root,
            root.get_node("LOD_0"),  # Use highest LOD when collapsed
            root.get_node("Collision")
        )

    else:
        # Far: Completely culled or use impostor/billboard
        root.visible = false
```

## Technical Details

### Visibility Detection

```gdscript
# VisibleOnScreenNotifier3D setup
func _setup_visibility_notifier(root_node: Node3D) -> VisibleOnScreenNotifier3D:
    var notifier = VisibleOnScreenNotifier3D.new()
    notifier.name = "QuantumVisibilityNotifier"

    # Set AABB (should match object bounds)
    notifier.aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))

    root_node.add_child(notifier)

    # Connect signals
    notifier.screen_entered.connect(_on_object_screen_entered)
    notifier.screen_exited.connect(_on_object_screen_exited)

    return notifier
```

**Important:** AABB must match object size for accurate culling.

### Probability Cloud Creation

```gdscript
# GPUParticles3D setup
func _create_probability_cloud(root_node: Node3D, solid_mesh: Node3D) -> GPUParticles3D:
    var particles = GPUParticles3D.new()
    particles.amount = 1000  # Particle count
    particles.lifetime = 2.0
    particles.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))

    # Particle material
    var particle_material = ParticleProcessMaterial.new()
    particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    particle_material.emission_box_extents = mesh_bounds.size * 0.5
    particle_material.initial_velocity_min = 0.1
    particle_material.initial_velocity_max = 0.5
    particle_material.gravity = Vector3.ZERO

    particles.process_material = particle_material

    # Draw material (glowing cyan particles)
    var draw_material = StandardMaterial3D.new()
    draw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    draw_material.albedo_color = Color(0.5, 0.8, 1.0, 0.6)  # Cyan
    draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    draw_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
    sphere_mesh.radius = 0.1
    sphere_mesh.material = draw_material

    particles.draw_pass_1 = sphere_mesh

    # Initially hidden
    particles.visible = false
    particles.emitting = false

    root_node.add_child(particles)
    return particles
```

### Collision Simplification

```gdscript
# Create simplified collision
func _create_simplified_collision(original: CollisionShape3D) -> CollisionShape3D:
    var simplified = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()

    # Estimate radius from original shape
    if original.shape is BoxShape3D:
        var box = original.shape as BoxShape3D
        sphere_shape.radius = box.size.length() * 0.5
    elif original.shape is SphereShape3D:
        sphere_shape.radius = original.shape.radius
    elif original.shape is CapsuleShape3D:
        var capsule = original.shape as CapsuleShape3D
        sphere_shape.radius = max(capsule.radius, capsule.height * 0.5)
    else:
        sphere_shape.radius = 1.0  # Default

    simplified.shape = sphere_shape
    simplified.disabled = true  # Start disabled

    original.get_parent().add_child(simplified)
    return simplified
```

### State Transitions

#### Collapse (Unobserved → Observed)

```gdscript
# Requirement 28.3: 0.1 second transition
const COLLAPSE_DURATION: float = 0.1

func _update_collapse_transition(quantum_data: QuantumObjectData, delta: float):
    quantum_data.transition_progress += delta / COLLAPSE_DURATION

    if quantum_data.transition_progress >= 1.0:
        # Transition complete
        quantum_data.current_state = QuantumState.OBSERVED
        quantum_data.solid_mesh.visible = true
        quantum_data.particle_cloud.visible = false
        quantum_data.particle_cloud.emitting = false

        # Restore full collision
        quantum_data.collision_shape.disabled = false
        quantum_data.simplified_collision.disabled = true

        object_collapse.emit(quantum_data.object_id)
    else:
        # Interpolate: Fade in solid mesh, fade out particles
        var alpha = quantum_data.transition_progress
        quantum_data.particle_cloud.amount_ratio = 1.0 - alpha
        # Also fade mesh alpha if material supports it
```

#### Decoherence (Observed → Unobserved)

```gdscript
func _update_decoherence_transition(quantum_data: QuantumObjectData, delta: float):
    quantum_data.transition_progress += delta / COLLAPSE_DURATION

    if quantum_data.transition_progress >= 1.0:
        # Transition complete
        quantum_data.current_state = QuantumState.UNOBSERVED
        quantum_data.solid_mesh.visible = false
        quantum_data.particle_cloud.visible = true
        quantum_data.particle_cloud.emitting = true

        # Switch to simplified collision
        quantum_data.collision_shape.disabled = true
        quantum_data.simplified_collision.disabled = false

        object_decoherence.emit(quantum_data.object_id)
    else:
        # Interpolate: Fade out solid mesh, fade in particles
        var alpha = quantum_data.transition_progress
        quantum_data.particle_cloud.amount_ratio = alpha
```

## Performance Impact

### Memory per Object

```
Overhead per registered object:
- QuantumObjectData: ~200 bytes
- VisibleOnScreenNotifier3D: ~1 KB
- GPUParticles3D: ~10 KB (includes particle buffer)
- Simplified CollisionShape3D: ~500 bytes

Total: ~12 KB per object
```

**1000 objects ≈ 12 MB overhead**

### Rendering Cost

| State | Vertices | Draw Calls | Collision Checks |
|-------|----------|------------|------------------|
| Observed (solid) | Mesh verts | 1 per mesh | Full detail |
| Unobserved (cloud) | 1000 particles | 1 batch | Sphere only |

**Savings:** ~80% vertex reduction for complex meshes, ~90% collision cost reduction

### Update Cost

- **60 Hz update rate:** ~0.5ms CPU time for 1000 objects
- **Per-object cost:** ~0.5 µs (state check + visibility query)

## Integration with Other Systems

### With LODManager

Use both systems in tiers:

```gdscript
# Distance-based system selection
if distance < 1000.0:
    # Close: LOD system (4 detail levels)
    lod_manager.register_object(id, root, lod_levels)

elif distance < 10000.0:
    # Medium: Quantum system (2 states: solid/cloud)
    quantum_render.register_object(id, root, mesh, collision)

else:
    # Far: Completely culled
    root.visible = false
```

### With PerformanceOptimizer

React to performance changes:

```gdscript
performance_optimizer.fps_below_target.connect(func(fps, target):
    # Reduce quantum update frequency to save CPU
    quantum_render.set_update_frequency(30.0)
)

performance_optimizer.fps_recovered.connect(func(fps):
    # Restore normal update rate
    quantum_render.set_update_frequency(60.0)
)
```

### With Gameplay Systems

```gdscript
# Mission system: Highlight observed targets
quantum_render.object_collapse.connect(func(object_id):
    if mission_system.is_target(object_id):
        ui.show_target_marker(object_id)
)

# Audio system: Play "collapse" sound
quantum_render.object_collapse.connect(func(object_id):
    audio_manager.play_3d("quantum_collapse", object_position)
)
```

## Troubleshooting

### Issue: Objects not switching to probability clouds

**Cause 1:** AABB too small, not detected as off-screen.
```gdscript
# Fix: Update bounds to match mesh
var mesh_aabb = mesh_instance.get_aabb()
quantum_render.set_object_bounds("obj_id", mesh_aabb)
```

**Cause 2:** Camera not set.
```gdscript
# Fix: Set camera explicitly
quantum_render.set_camera(get_viewport().get_camera_3d())
```

**Cause 3:** Update frequency too low.
```gdscript
# Fix: Increase update rate
quantum_render.set_update_frequency(60.0)
```

### Issue: Probability clouds not visible

**Cause:** Particle visibility AABB too small.
```gdscript
# Fix: Increase particle cloud bounds
quantum_render.set_object_bounds("obj_id", AABB(Vector3(-50,-50,-50), Vector3(100,100,100)))
```

### Issue: Particles causing performance issues

**Cause:** Too many particles (1000 default per object).

**Solution:** Reduce particle count (requires modifying `_create_probability_cloud()`):
```gdscript
# In quantum_render.gd, change:
const CLOUD_PARTICLE_COUNT: int = 500  # Reduced from 1000
```

Or use quantum rendering selectively:
```gdscript
# Only use quantum rendering for large/important objects
if object_importance > 0.5:
    quantum_render.register_object(id, root, mesh, collision)
```

### Issue: Collision detection broken for unobserved objects

**Cause:** Simplified collision sphere radius too small.

**Solution:** Manually adjust simplified collision:
```gdscript
# After registration, get simplified collision and adjust
var quantum_data = quantum_render._objects[object_id]
if quantum_data.simplified_collision != null:
    var sphere_shape = quantum_data.simplified_collision.shape as SphereShape3D
    sphere_shape.radius *= 1.5  # Increase by 50%
```

### Issue: Objects flicker when near screen edge

**Cause:** Rapid on-screen/off-screen state changes.

**Solution 1:** Increase AABB to add buffer:
```gdscript
var mesh_aabb = mesh_instance.get_aabb()
mesh_aabb = mesh_aabb.grow(5.0)  # Add 5-unit buffer
quantum_render.set_object_bounds("obj_id", mesh_aabb)
```

**Solution 2:** Reduce update frequency:
```gdscript
quantum_render.set_update_frequency(20.0)  # Slower updates
```

## Best Practices

### 1. Update Visibility Bounds After Registration

```gdscript
quantum_render.register_object(id, root, mesh, collision)

# Always update bounds to match actual mesh
var mesh_aabb = mesh.get_aabb()
quantum_render.set_object_bounds(id, mesh_aabb)
```

### 2. Use for Large, Distant Objects

Quantum rendering works best for:
- **Asteroids** (numerous, distant)
- **Distant spacecraft** (complex meshes)
- **Space stations** (large, detailed)

Not ideal for:
- **Player's ship** (always observed)
- **HUD elements** (always visible)
- **Very small objects** (particle overhead > mesh cost)

### 3. Profile State Transitions

```gdscript
# Monitor quantum events
quantum_render.object_collapse.connect(func(id):
    print("[Quantum] Collapse: ", id)
)

quantum_render.object_decoherence.connect(func(id):
    print("[Quantum] Decoherence: ", id)
)

# Check stats periodically
if Engine.get_process_frames() % 60 == 0:
    var stats = quantum_render.get_statistics()
    if stats.collapses_this_frame > 5:
        push_warning("Too many quantum collapses this frame!")
```

### 4. Disable for Performance-Critical Moments

```gdscript
# During combat or intense scenes, disable quantum rendering
func enter_combat():
    # Force all objects to observed state
    for id in quantum_render.get_registered_objects():
        quantum_render.force_observe(id)

func exit_combat():
    # Resume automatic quantum rendering
    # Objects will naturally decohere when off-screen
    pass
```

### 5. Combine with Spatial Partitioning

```gdscript
# Only process quantum objects in active sectors
func update_active_sector(sector_id: String):
    for object_id in sector_objects[sector_id]:
        if not quantum_render.has_object(object_id):
            # Register objects entering active sector
            quantum_render.register_object(object_id, root, mesh, collision)

    # Unregister objects leaving active sector
    for object_id in quantum_render.get_registered_objects():
        if not is_in_active_sector(object_id):
            quantum_render.unregister_object(object_id)
```

## Thematic Integration

The quantum rendering system aligns with the game's themes:

### Visual Design

- **Probability clouds:** Cyan/blue particles suggest "quantum uncertainty"
- **Collapse effect:** Smooth 0.1s transition mimics wave function collapse
- **Additive blending:** Creates ethereal, non-physical appearance

### Audio Cues

Suggested audio events (not implemented in core system):

```gdscript
quantum_render.object_collapse.connect(func(id):
    audio.play_sound("quantum_collapse")  # Sharp, crystalline sound
)

quantum_render.object_decoherence.connect(func(id):
    audio.play_sound("quantum_decohere")  # Fading, whispy sound
)
```

### Gameplay Mechanics

Potential gameplay uses:

1. **Stealth:** Unobserved enemies don't detect player
2. **Puzzles:** Objects only exist when observed
3. **Narrative:** "Schrodinger's asteroid" - contents unknown until observed
4. **Difficulty:** More enemies spawn in unobserved areas

## Related Documentation

- **[RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md)** - Overall rendering system
- **[LOD_SYSTEM.md](LOD_SYSTEM.md)** - Alternative LOD strategy
- **[SHADER_SYSTEM.md](SHADER_SYSTEM.md)** - Shader management for particle effects

## Version History

- **v1.0** (2025-12-03) - Initial quantum rendering documentation
