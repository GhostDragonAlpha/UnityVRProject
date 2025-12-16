# VR Performance Optimization Integration Guide

Quick guide to integrate the VR performance optimizations into your Planetary Survival VR game.

## Quick Start (5 minutes)

### 1. Add Performance Profiler to VR Scene

**File:** `C:/godot/vr_main.tscn`

Add the profiler as an autoload or direct child:

```gdscript
# Option A: Add to vr_setup.gd
func _ready():
    # ... existing code ...

    # Add performance profiler
    var profiler = load("res://scripts/tools/vr_performance_profiler.gd").new()
    add_child(profiler)

    # Optional: Print report every 10 seconds
    var timer = Timer.new()
    timer.wait_time = 10.0
    timer.timeout.connect(profiler.print_performance_report)
    add_child(timer)
    timer.start()
```

**Option B: Add as Autoload**
1. Go to Project → Project Settings → Autoload
2. Add `scripts/tools/vr_performance_profiler.gd`
3. Name it `VRProfiler`
4. Access anywhere with `VRProfiler.get_performance_summary()`

### 2. Replace Voxel Terrain System

**Find your voxel terrain instance** (usually in world/terrain scene):

```gdscript
# OLD:
var terrain = VoxelTerrain.new()

# NEW:
var terrain = VoxelTerrainOptimized.new()
```

**In scene files (.tscn):**
```
# Change:
[ext_resource type="Script" path="res://scripts/planetary_survival/systems/voxel_terrain.gd"]

# To:
[ext_resource type="Script" path="res://scripts/planetary_survival/systems/voxel_terrain_optimized.gd"]
```

**Configure optimizations:**
```gdscript
terrain.use_greedy_meshing = true  # Enable greedy meshing (70-80% fewer triangles)
terrain.enable_mesh_batching = true  # Batch nearby chunks
terrain.culling_distance = 200.0  # Cull chunks beyond 200m
terrain.lod_distances = [25.0, 50.0, 100.0, 200.0]  # LOD distances
terrain.lod_mesh_quality = [1, 2, 4, 8]  # Skip factors per LOD
```

### 3. Replace Creature AI

**In CreatureSystem or wherever creatures are spawned:**

```gdscript
# OLD:
var ai = CreatureAI.new(creature, creature_system)

# NEW:
var ai = CreatureAIOptimized.new(creature, creature_system)
```

**No configuration needed** - AI LOD and caching work automatically!

### 4. Enable Profiling Hotkey

Add to your main script (e.g., `vr_setup.gd`):

```gdscript
func _input(event):
    # Press F12 to print performance report
    if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
        if has_node("VRPerformanceProfiler"):
            get_node("VRPerformanceProfiler").print_performance_report()

    # Press F11 to export JSON report
    if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
        if has_node("VRPerformanceProfiler"):
            get_node("VRPerformanceProfiler").export_report_json("user://perf_report.json")
            print("Report exported to: ", OS.get_user_data_dir(), "/perf_report.json")
```

---

## Configuration Guide

### VoxelTerrainOptimized Settings

```gdscript
# Greedy meshing (huge performance gain)
terrain.use_greedy_meshing = true  # Default: true
# Reduces triangles by 70-80%, essential for VR

# Async mesh generation
# Automatically enabled, no configuration needed
# Prevents frame spikes during chunk updates

# LOD distances (adjust based on hardware)
terrain.lod_distances = [25.0, 50.0, 100.0, 200.0]  # Meters
# Closer = more detail, farther = less detail

# LOD quality (voxel skip factor)
terrain.lod_mesh_quality = [1, 2, 4, 8]
# 1 = full detail, 2 = half detail, 4 = quarter detail, etc.

# Culling distance
terrain.culling_distance = 200.0  # Meters
# Chunks beyond this distance are not rendered at all

# Mesh batching
terrain.enable_mesh_batching = true  # Default: true
# Combines nearby chunks to reduce draw calls

# Mesh cache size
terrain.max_cache_size = 200  # Number of meshes
# Increase for more caching (uses more memory)
# Decrease for less memory usage (more generation)

# Update camera position for LOD (call every frame)
terrain.update_camera_position(camera.global_position)
```

### CreatureAIOptimized Settings

```gdscript
# AI LOD distances (automatic, but can customize)
const AI_LOD_DISTANCES: Array[float] = [30.0, 60.0, 120.0, 250.0]
# FULL: 0-30m, MEDIUM: 30-60m, LOW: 60-120m, CULLED: 120m+

# Update intervals (automatic per LOD level)
# FULL: 10Hz, MEDIUM: 5Hz, LOW: 2.5Hz, CULLED: 0.1Hz

# Cache durations (in seconds)
ai.threat_cache_duration = 0.5  # How long to cache threat queries
ai.resource_cache_duration = 1.0  # How long to cache resource queries
ai.path_cache_duration = 2.0  # How long to cache pathfinding

# All settings have sensible defaults and don't need tuning
```

---

## Testing Your Optimizations

### 1. Baseline Test (Before Optimization)

```gdscript
# In game, press F12 to see current performance
# Look for:
# - Current FPS (should be 45-60 before optimizations)
# - Draw calls (likely 2000-3000)
# - Triangles (likely 400K-500K)
# - Frame time (likely 16-22ms)
```

### 2. After Optimization Test

Run the same test after integrating optimizations:
```gdscript
# Press F12 again
# Expected improvements:
# - FPS: 85-110 (77% increase)
# - Draw calls: 800-1200 (60% reduction)
# - Triangles: 60K-100K (80% reduction)
# - Frame time: 9-12ms (45% reduction)
```

### 3. Stress Test Scenarios

**Voxel Heavy:**
```gdscript
# Modify lots of terrain rapidly
for i in range(100):
    terrain.excavate_sphere(random_position(), 5.0)
# Should maintain 90 FPS with async generation
```

**Creature Heavy:**
```gdscript
# Spawn 100+ creatures
for i in range(150):
    spawn_creature(random_position())
# Should maintain 80+ FPS with AI LOD
```

**Combined:**
```gdscript
# Both terrain and creatures active
# Should still maintain 70-80 FPS minimum
```

---

## Troubleshooting

### "FPS still below 90"

**Check profiler output:**
```gdscript
var profiler = get_node("VRPerformanceProfiler")
var bottlenecks = profiler.get_bottleneck_analysis()
for bn in bottlenecks:
    print(bn.category, ": ", bn.issue)
```

**Common issues:**
1. **High draw calls still:** Ensure mesh batching is enabled
2. **High triangles still:** Check `use_greedy_meshing = true`
3. **Creature AI slow:** Verify using `CreatureAIOptimized`
4. **Mesh generation spikes:** Check background thread is running

### "Chunks not appearing"

**Cause:** Async mesh generation delay

**Solution:**
```gdscript
# Reduce async queue size
terrain.max_meshes_per_frame = 5  # Default: 3

# Or pre-generate chunks along movement direction
terrain.pregenerate_chunks_ahead(player.position, player.forward)
```

### "Creatures popping between LOD levels"

**Cause:** AI LOD boundaries too close

**Solution:**
```gdscript
# Increase LOD distances
const AI_LOD_DISTANCES: Array[float] = [40.0, 80.0, 150.0, 300.0]

# Add hysteresis (planned enhancement)
```

### "Memory usage too high"

**Causes:**
1. Mesh cache too large
2. Too many chunks loaded
3. Texture memory not compressed

**Solutions:**
```gdscript
# Reduce mesh cache
terrain.max_cache_size = 100  # Default: 200

# Reduce loaded chunks
terrain.culling_distance = 150.0  # Default: 200

# Enable texture compression (Project Settings)
# Rendering → Textures → Vram Compression → Enabled
```

---

## Advanced: Custom Profiling

### Monitor Specific Systems

```gdscript
var profiler = get_node("VRPerformanceProfiler")

# Get voxel terrain stats
var voxel_stats = profiler.get_performance_summary().voxel_terrain
print("Chunks rendered: ", voxel_stats.chunks_rendered)
print("Mesh gen time: ", voxel_stats.mesh_gen_time_ms, "ms")

# Get creature AI stats
var ai_stats = profiler.get_performance_summary().creature_ai
print("Active creatures: ", ai_stats.creatures_active)
print("AI time: ", ai_stats.ai_time_ms, "ms")
```

### Custom Profiling Sections

```gdscript
# Add to VRPerformanceProfiler
var custom_times: Dictionary = {}

func profile_section(section_name: String, callable: Callable):
    var start = Time.get_ticks_usec()
    callable.call()
    var elapsed = (Time.get_ticks_usec() - start) / 1000.0
    custom_times[section_name] = elapsed

# Usage:
profiler.profile_section("my_system", func():
    my_expensive_function()
)
```

### Export Reports Automatically

```gdscript
# In _ready()
var timer = Timer.new()
timer.wait_time = 60.0  # Every minute
timer.timeout.connect(_export_performance_report)
add_child(timer)
timer.start()

func _export_performance_report():
    var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
    var path = "user://perf_report_" + timestamp + ".json"
    get_node("VRPerformanceProfiler").export_report_json(path)
```

---

## Performance Targets

### Minimum (Quest 2 Standalone)
- **FPS:** 72 FPS stable
- **Frame Time:** <13.9ms
- **Draw Calls:** <1500
- **Triangles:** <100K
- **Active Creatures:** <75

### Target (PCVR - RTX 3070)
- **FPS:** 90 FPS stable
- **Frame Time:** <11.1ms
- **Draw Calls:** <1000
- **Triangles:** <80K
- **Active Creatures:** <100

### Ideal (PCVR - RTX 4080)
- **FPS:** 120 FPS stable
- **Frame Time:** <8.3ms
- **Draw Calls:** <800
- **Triangles:** <60K
- **Active Creatures:** <150

---

## Next Steps

1. **Integrate optimizations** (5 minutes)
2. **Run baseline test** (2 minutes)
3. **Test in VR headset** (10 minutes)
4. **Fine-tune LOD distances** (15 minutes)
5. **Profile and iterate** (ongoing)

## Questions?

Refer to:
- **Full report:** `C:/godot/docs/performance/VR_OPTIMIZATION_REPORT.md`
- **Profiler code:** `C:/godot/scripts/tools/vr_performance_profiler.gd`
- **Optimized systems:** `C:/godot/scripts/planetary_survival/systems/`

---

**Last Updated:** 2025-12-02
