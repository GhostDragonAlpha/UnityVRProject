# LOD (Level of Detail) System

## Overview

The LOD Manager (`LODManager`) implements automatic Level of Detail switching based on camera distance and visibility culling. This system is critical for maintaining 90 FPS in VR by reducing rendering complexity for distant or off-screen objects.

**File:** `C:/godot/scripts/rendering/lod_manager.gd`

## Core Concepts

### LOD Levels

Objects are rendered at different detail levels based on distance:

```
LOD 0 (Highest Detail)   LOD 1              LOD 2           LOD 3         LOD 4 (Lowest)
  ████████████             ████████            ████            ██              ·
  Closest objects       Medium distance     Far objects    Very far      Tiny/culled
  100% vertices         50% vertices        25% vertices   10% vertices   Billboards
```

### Distance Thresholds

Default thresholds (configurable):
```gdscript
lod_distances = [100.0, 500.0, 2000.0, 10000.0]
```

- **Distance < 100:** LOD 0 (highest detail)
- **100 ≤ Distance < 500:** LOD 1
- **500 ≤ Distance < 2000:** LOD 2
- **2000 ≤ Distance < 10000:** LOD 3
- **Distance ≥ 10000:** LOD 4 (lowest detail)

### LOD Bias

LOD bias is a multiplier that shifts distance thresholds:

```gdscript
effective_distance = distance / (lod_bias * priority)
```

- **Bias > 1.0:** Higher quality at greater distances (performance cost)
- **Bias = 1.0:** Normal quality
- **Bias < 1.0:** Lower quality, better performance

**Quality Settings:**
- **Ultra:** 1.5 bias
- **High:** 1.0 bias
- **Medium:** 0.75 bias
- **Low:** 0.5 bias
- **Minimum:** 0.25 bias

## API Reference

### Initialization

```gdscript
var lod_manager = LODManager.new()
add_child(lod_manager)

# Initialize with camera (typically XRCamera3D)
lod_manager.initialize(xr_camera)

# Or let it find the active camera automatically
lod_manager.initialize()
```

**Signals:**
```gdscript
signal lod_initialized()
signal lod_changed(object_id: String, old_level: int, new_level: int)
signal object_registered(object_id: String)
signal object_unregistered(object_id: String)
signal lod_bias_changed(new_bias: float)
```

### Registering Objects

#### Manual Registration

```gdscript
# Create LOD levels (decreasing detail)
var lod_0 = high_detail_mesh_instance  # Highest detail
var lod_1 = medium_detail_mesh_instance
var lod_2 = low_detail_mesh_instance
var lod_3 = billboard_mesh_instance    # Lowest detail

var lod_levels: Array[Node3D] = [lod_0, lod_1, lod_2, lod_3]

# Register with LOD manager
lod_manager.register_object(
    "asteroid_001",           # Unique ID
    asteroid_root,            # Root Node3D
    lod_levels,              # Array of LOD meshes
    1.0,                     # Priority (optional)
    []                       # Custom distances (optional)
)
```

#### Automatic Registration

For objects with child nodes named `LOD_0`, `LOD_1`, etc.:

```gdscript
# Scene structure:
# AsteroidRoot (Node3D)
#   ├─ LOD_0 (MeshInstance3D)
#   ├─ LOD_1 (MeshInstance3D)
#   ├─ LOD_2 (MeshInstance3D)
#   └─ LOD_3 (MeshInstance3D)

lod_manager.register_object_auto("asteroid_001", asteroid_root)
# Automatically finds LOD_0, LOD_1, LOD_2, LOD_3
```

#### Priority System

Objects with higher priority maintain higher detail at greater distances:

```gdscript
# Important objects (player's spacecraft, mission targets)
lod_manager.register_object("player_ship", ship_root, lod_levels, 2.0)

# Normal objects
lod_manager.register_object("asteroid", asteroid_root, lod_levels, 1.0)

# Background objects (distant stars, nebulae)
lod_manager.register_object("star_field", stars_root, lod_levels, 0.5)
```

**Effect:**
- Priority 2.0: Uses LOD 0 at 2x the distance
- Priority 1.0: Normal LOD distances
- Priority 0.5: Switches to lower LOD at 0.5x the distance

#### Custom Distance Thresholds

Override global distances for specific objects:

```gdscript
# Large object visible from far away (planet)
var planet_distances = [1000.0, 5000.0, 20000.0, 100000.0]
lod_manager.set_object_distances("planet_001", planet_distances)

# Small object culled quickly (debris)
var debris_distances = [50.0, 200.0, 1000.0, 5000.0]
lod_manager.set_object_distances("debris_001", debris_distances)
```

### Updating LODs

LODs update automatically in `_process()`, but you can control the frequency:

```gdscript
# Update every frame (default)
lod_manager.set_update_frequency(0.0)

# Update 30 times per second (reduces CPU usage)
lod_manager.set_update_frequency(30.0)

# Update 10 times per second (aggressive optimization)
lod_manager.set_update_frequency(10.0)
```

**Manual Update:**
```gdscript
# Force update all LODs immediately
lod_manager.update_all_lods()

# Force update specific object
lod_manager.update_object_lod("asteroid_001")
```

### Querying LOD State

```gdscript
# Get current LOD level for an object
var lod_level = lod_manager.get_object_lod("asteroid_001")
# Returns: 0, 1, 2, 3, 4, or -1 if not found

# Get number of LOD levels
var lod_count = lod_manager.get_object_lod_count("asteroid_001")

# Check if object is visible on screen
var is_visible = lod_manager.is_object_visible("asteroid_001")

# Check if object is registered
if lod_manager.has_object("asteroid_001"):
    print("Object is managed by LOD system")
```

### Configuration

```gdscript
# Set global LOD distance thresholds
lod_manager.set_lod_distances([150.0, 600.0, 2500.0, 12000.0])

# Set LOD bias (quality vs performance)
lod_manager.set_lod_bias(0.75)  # Favor performance

# Change camera reference
lod_manager.set_camera(new_camera)

# Get current settings
var distances = lod_manager.get_lod_distances()
var bias = lod_manager.get_lod_bias()
var camera = lod_manager.get_camera()
```

### Debugging and Statistics

```gdscript
# Get comprehensive statistics
var stats = lod_manager.get_statistics()
print("Total Objects: ", stats.total_objects)
print("Visible Objects: ", stats.visible_objects)
print("LOD Bias: ", stats.lod_bias)
print("LOD Distribution: ", stats.lod_distribution)
# → {"lod_0": 5, "lod_1": 12, "lod_2": 23, "lod_3": 8}
print("Switches This Frame: ", stats.switches_this_frame)
print("Total Switches: ", stats.total_switches)

# Force all objects to specific LOD (debugging/screenshots)
lod_manager.force_all_lod(0)  # Force highest detail
# ... take screenshot ...
lod_manager.reset_all_lod()  # Resume automatic LOD
```

### Cleanup

```gdscript
# Unregister single object
lod_manager.unregister_object("asteroid_001")

# Unregister all objects and shutdown
lod_manager.shutdown()
```

## Usage Patterns

### Pattern 1: Procedural Asteroid Field

```gdscript
func spawn_asteroid_field(count: int):
    for i in range(count):
        var asteroid = create_asteroid()

        # Create LOD levels procedurally
        var lod_levels: Array[Node3D] = []
        lod_levels.append(create_asteroid_mesh(1.0))    # LOD 0: 100%
        lod_levels.append(create_asteroid_mesh(0.6))    # LOD 1: 60%
        lod_levels.append(create_asteroid_mesh(0.3))    # LOD 2: 30%
        lod_levels.append(create_billboard_mesh())       # LOD 3: Billboard

        # Register with LOD manager
        lod_manager.register_object(
            "asteroid_%d" % i,
            asteroid,
            lod_levels,
            0.8  # Lower priority for asteroids
        )
```

### Pattern 2: Static Scene with Pre-Built LODs

```gdscript
# In scene: Planet.tscn
# Planet (Node3D)
#   ├─ LOD_0 (MeshInstance3D) - High poly sphere
#   ├─ LOD_1 (MeshInstance3D) - Medium poly sphere
#   ├─ LOD_2 (MeshInstance3D) - Low poly icosphere
#   └─ LOD_3 (MeshInstance3D) - Impostor billboard

func _ready():
    # Automatic registration
    lod_manager.register_object_auto("planet_earth", self, 1.5)

    # Set custom distances for planets (visible from far away)
    lod_manager.set_object_distances("planet_earth", [
        5000.0,   # LOD 0 → 1
        20000.0,  # LOD 1 → 2
        100000.0, # LOD 2 → 3
        500000.0  # LOD 3 → 4 (culled)
    ])
```

### Pattern 3: Player Spacecraft (Always High Detail)

```gdscript
func setup_player_ship():
    # Even though player ship has LODs, give it maximum priority
    # and very distant thresholds so it always stays at LOD 0
    lod_manager.register_object(
        "player_ship",
        ship_root,
        ship_lod_levels,
        10.0,  # Maximum priority
        [10000.0, 50000.0, 100000.0, 500000.0]  # Huge distances
    )
```

### Pattern 4: Dynamic LOD Based on Screen Size

```gdscript
# For objects where angular size matters more than distance
func register_with_angular_lod(object_id: String, root: Node3D, radius: float):
    # Calculate distance thresholds based on angular size
    # Target: LOD switch when object appears < X pixels
    var screen_height = get_viewport().size.y
    var fov_rad = deg_to_rad(camera.fov)

    # Switch to next LOD when object is < 200 pixels tall
    var target_pixels = 200.0
    var distance_for_pixels = (screen_height * radius) / (2.0 * tan(fov_rad / 2.0) * target_pixels)

    var custom_distances = [
        distance_for_pixels * 1.0,  # LOD 0 → 1
        distance_for_pixels * 2.0,  # LOD 1 → 2
        distance_for_pixels * 4.0,  # LOD 2 → 3
        distance_for_pixels * 8.0   # LOD 3 → 4
    ]

    lod_manager.register_object(object_id, root, lod_levels, 1.0, custom_distances)
```

### Pattern 5: LOD Integration with PerformanceOptimizer

```gdscript
# Automatic quality adjustment
performance_optimizer.quality_level_changed.connect(func(old_level, new_level):
    match new_level:
        PerformanceOptimizer.QualityLevel.ULTRA:
            lod_manager.set_lod_bias(1.5)
            lod_manager.set_update_frequency(0.0)  # Every frame
        PerformanceOptimizer.QualityLevel.HIGH:
            lod_manager.set_lod_bias(1.0)
            lod_manager.set_update_frequency(0.0)
        PerformanceOptimizer.QualityLevel.MEDIUM:
            lod_manager.set_lod_bias(0.75)
            lod_manager.set_update_frequency(30.0)
        PerformanceOptimizer.QualityLevel.LOW:
            lod_manager.set_lod_bias(0.5)
            lod_manager.set_update_frequency(20.0)
        PerformanceOptimizer.QualityLevel.MINIMUM:
            lod_manager.set_lod_bias(0.25)
            lod_manager.set_update_frequency(10.0)
)
```

## Visibility Culling

LODManager uses `VisibleOnScreenNotifier3D` for frustum culling:

```gdscript
# Automatically created per object
# If object is off-screen, force to lowest LOD
if not visibility_notifier.is_on_screen():
    set_to_lowest_lod()
    return
```

**Manual AABB Configuration:**
```gdscript
# Update visibility bounds to match object size
var mesh_aabb = mesh_instance.get_aabb()
lod_manager.set_object_bounds("asteroid_001", mesh_aabb)
```

## Performance Considerations

### LOD Switch Cost

Switching LOD levels has a cost (mesh visibility changes):
- **Per-frame switches:** Minimize with appropriate distance buffers
- **Batch switches:** Update frequency reduces total switches

**Monitoring:**
```gdscript
lod_manager.lod_changed.connect(func(object_id, old_level, new_level):
    print("LOD switch: %s %d→%d" % [object_id, old_level, new_level])
)

# Check stats
var stats = lod_manager.get_statistics()
if stats.switches_this_frame > 10:
    push_warning("Too many LOD switches this frame!")
```

### Update Frequency Tuning

Trade-off between responsiveness and CPU usage:

| Frequency | Updates/sec | Use Case |
|-----------|-------------|----------|
| 0.0 | 90 (every frame) | High-speed movement, VR |
| 60.0 | 60 | Normal gameplay |
| 30.0 | 30 | Balanced performance |
| 10.0 | 10 | Aggressive optimization |

**Recommendation:** Start at 30 Hz, measure `switches_this_frame`, adjust if needed.

### Memory Usage

Each registered object stores:
- `LODObjectData` (small): ~200 bytes
- `VisibleOnScreenNotifier3D`: ~1 KB
- LOD meshes: Variable (depends on mesh complexity)

**1000 objects ≈ 1.2 MB overhead + mesh data**

## Integration with Other Systems

### With QuantumRender

LOD and Quantum systems can work together:

```gdscript
# Near objects: Use LOD system
# Far/off-screen objects: Use Quantum rendering (probability clouds)

if distance < 1000.0:
    lod_manager.register_object(id, root, lod_levels)
else:
    quantum_render.register_object(id, root, highest_lod_mesh)
```

### With PerformanceOptimizer

Automatic integration via LOD bias:

```gdscript
# PerformanceOptimizer automatically adjusts LOD bias when FPS drops
performance_optimizer.fps_below_target.connect(func(fps, target):
    # LOD bias automatically reduced to improve performance
    print("LOD bias adjusted to: ", lod_manager.get_lod_bias())
)
```

### With Procedural Generation

Dynamic registration/unregistration:

```gdscript
# When planet comes into range
func on_planet_loaded(planet_data):
    var lod_levels = generate_planet_lods(planet_data)
    lod_manager.register_object(planet_data.id, planet_root, lod_levels)

# When planet goes out of range
func on_planet_unloaded(planet_id):
    lod_manager.unregister_object(planet_id)
```

## Troubleshooting

### Issue: LODs flickering near threshold distances

**Cause:** Object distance is oscillating around LOD threshold.

**Solution 1:** Add hysteresis by increasing update interval:
```gdscript
lod_manager.set_update_frequency(30.0)  # Reduce updates
```

**Solution 2:** Add distance buffer:
```gdscript
# Increase distances by 10% to add buffer
var buffered = [110.0, 550.0, 2200.0, 11000.0]
lod_manager.set_lod_distances(buffered)
```

**Solution 3:** Use custom distances with larger gaps:
```gdscript
lod_manager.set_object_distances("asteroid_001", [150.0, 700.0, 3000.0, 15000.0])
```

### Issue: Objects not switching LOD

**Cause 1:** Camera not set or invalid.
```gdscript
# Check camera
if lod_manager.get_camera() == null:
    lod_manager.set_camera(get_viewport().get_camera_3d())
```

**Cause 2:** LOD manager not initialized.
```gdscript
if not lod_manager.is_initialized():
    lod_manager.initialize()
```

**Cause 3:** Update frequency too low.
```gdscript
lod_manager.set_update_frequency(0.0)  # Update every frame
```

### Issue: Objects always at lowest LOD

**Cause:** Visibility notifier AABB too small or incorrect.

**Solution:**
```gdscript
# Get actual mesh bounds
var mesh_aabb = mesh_instance.get_aabb()
print("Mesh AABB: ", mesh_aabb)

# Update visibility bounds
lod_manager.set_object_bounds("object_id", mesh_aabb)

# Or disable visibility culling for testing
# (manually set visibility notifier to always on-screen)
```

### Issue: Too many LOD switches per frame

**Cause:** Many objects near LOD thresholds.

**Solution 1:** Reduce update frequency:
```gdscript
lod_manager.set_update_frequency(20.0)
```

**Solution 2:** Increase distance gaps:
```gdscript
# More gradual LOD transitions
lod_manager.set_lod_distances([100.0, 600.0, 3000.0, 15000.0])
```

**Solution 3:** Stagger updates:
```gdscript
# Update different object groups on different frames
var frame_group = _frame_count % 3
if frame_group == 0:
    lod_manager.update_object_lod("group_1_*")
elif frame_group == 1:
    lod_manager.update_object_lod("group_2_*")
else:
    lod_manager.update_object_lod("group_3_*")
```

## Best Practices

### 1. Always Provide at Least 3 LOD Levels

```gdscript
# Minimum: High, Medium, Low
var lod_levels = [high_mesh, medium_mesh, low_mesh]
```

### 2. Use Billboards for Distant LODs

```gdscript
# LOD 3: Billboard (2 triangles, always faces camera)
var billboard = create_billboard_from_texture(object_icon)
lod_levels.append(billboard)
```

### 3. Validate Distance Thresholds

```gdscript
# Ensure ascending order
func set_safe_lod_distances(distances: Array[float]):
    for i in range(1, distances.size()):
        assert(distances[i] > distances[i-1], "LOD distances must be ascending")
    lod_manager.set_lod_distances(distances)
```

### 4. Profile LOD Performance

```gdscript
# Log LOD statistics every 60 frames
if Engine.get_process_frames() % 60 == 0:
    var stats = lod_manager.get_statistics()
    print("LOD Stats: %d objects, %d visible, %d switches" % [
        stats.total_objects,
        stats.visible_objects,
        stats.switches_this_frame
    ])
```

### 5. Use Priorities for Gameplay-Critical Objects

```gdscript
# Player's target: Keep at high detail
lod_manager.set_object_priority("mission_target", 2.0)

# Background decoration: Use lower detail
lod_manager.set_object_priority("space_junk", 0.5)
```

## Related Documentation

- **[RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md)** - Overall rendering system
- **[QUANTUM_RENDERING.md](QUANTUM_RENDERING.md)** - Alternative LOD strategy
- **[C:/godot/docs/performance/VR_OPTIMIZATION.md](../performance/VR_OPTIMIZATION.md)** - VR-specific optimizations

## Version History

- **v1.0** (2025-12-03) - Initial LOD system documentation
