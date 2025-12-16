# VR Performance Quick Reference

One-page reference for VR performance optimization settings and commands.

## Installation (5 Minutes)

```gdscript
# 1. Add profiler to VR scene
var profiler = preload("res://scripts/tools/vr_performance_profiler.gd").new()
add_child(profiler)

# 2. Replace voxel terrain script
# Change: voxel_terrain.gd → voxel_terrain_optimized.gd

# 3. Replace creature AI script
# Change: creature_ai.gd → creature_ai_optimized.gd
var ai = CreatureAIOptimized.new(creature, creature_system)
```

## Performance Targets

| Hardware | Target FPS | Frame Time |
|----------|------------|------------|
| Quest 2 | 72 FPS | <13.9ms |
| PCVR (RTX 3070) | 90 FPS | <11.1ms |
| PCVR (RTX 4080) | 120 FPS | <8.3ms |

## Essential Settings

### VoxelTerrainOptimized

```gdscript
# MUST ENABLE - Core optimizations
terrain.use_greedy_meshing = true          # 70-80% fewer triangles
terrain.enable_mesh_batching = true        # Reduce draw calls

# Recommended settings
terrain.culling_distance = 200.0           # Cull distant chunks (meters)
terrain.lod_distances = [25, 50, 100, 200] # LOD transition distances
terrain.lod_mesh_quality = [1, 2, 4, 8]    # Detail reduction per LOD
terrain.max_cache_size = 200               # Mesh cache size

# Update every frame
terrain.update_camera_position(camera.global_position)
```

### CreatureAIOptimized

```gdscript
# Automatic LOD - no configuration needed
# FULL:   0-30m   @ 10Hz (full AI)
# MEDIUM: 30-60m  @ 5Hz  (simplified AI)
# LOW:    60-120m @ 2.5Hz (minimal AI)
# CULLED: 120m+   @ 0.1Hz (nearly frozen)

# Optional: Adjust cache durations
ai.threat_cache_duration = 0.5    # Seconds
ai.resource_cache_duration = 1.0  # Seconds
ai.path_cache_duration = 2.0      # Seconds
```

## Profiling Commands

```gdscript
# Print performance report (F12)
VRProfiler.print_performance_report()

# Get summary dictionary
var summary = VRProfiler.get_performance_summary()
print("FPS: ", summary.fps.current)
print("Frame Time: ", summary.frame_time.current_ms, "ms")
print("Draw Calls: ", summary.rendering.draw_calls)
print("Triangles: ", summary.rendering.triangles)

# Get top bottlenecks
var bottlenecks = VRProfiler.get_bottleneck_analysis()
for bn in bottlenecks.slice(0, 5):  # Top 5
    print(bn.category, ": ", bn.issue, " (", bn.impact_ms, "ms)")

# Export JSON report (F11)
VRProfiler.export_report_json("user://perf_report.json")
```

## Key Metrics

### Good Performance

```
FPS:              85-110
Frame Time:       9-12ms
Draw Calls:       <1000
Triangles:        <100K
Voxel Mesh Gen:   <0.5ms
Creature AI:      <1.0ms
Physics:          <1.5ms
VRAM:             <1.2GB
```

### Warning Signs

```
FPS:              <80
Frame Time:       >13ms
Draw Calls:       >1500
Triangles:        >150K
Frame Spikes:     >20ms
GC Pauses:        >5/min
```

## Troubleshooting

### Low FPS (<80)

**Check profiler:**
```gdscript
var bottlenecks = VRProfiler.get_bottleneck_analysis()
print(bottlenecks[0].issue)  # Top bottleneck
```

**Common fixes:**
1. Enable greedy meshing: `terrain.use_greedy_meshing = true`
2. Enable batching: `terrain.enable_mesh_batching = true`
3. Verify using optimized scripts
4. Reduce LOD distances if on low-end hardware

### Frame Spikes

**Cause:** Synchronous mesh generation

**Fix:**
```gdscript
# Check if async generation is working
var stats = terrain.get_optimization_stats()
print("Async meshes: ", stats.async_meshes_generated)
# Should be increasing during chunk updates
```

### High Draw Calls (>1500)

**Fixes:**
```gdscript
terrain.enable_mesh_batching = true
terrain.culling_distance = 150.0  # Reduce from 200m
```

### High Triangle Count (>150K)

**Fixes:**
```gdscript
terrain.use_greedy_meshing = true
terrain.lod_distances = [20, 40, 80, 160]  # Closer LOD transitions
```

### Creature AI Slow

**Check:**
```gdscript
var summary = VRProfiler.get_performance_summary()
print("AI Time: ", summary.creature_ai.ai_time_ms, "ms")
print("Active Creatures: ", summary.creature_ai.creatures_active)
```

**Fixes:**
- Verify using `CreatureAIOptimized`
- Reduce creature count if >150
- Increase culling distance

### High Memory (>2GB VRAM)

**Fixes:**
```gdscript
terrain.max_cache_size = 100      # Reduce from 200
terrain.culling_distance = 150.0  # Reduce from 200m
```

Enable texture compression (Project Settings):
```
Rendering > Textures > Vram Compression > Enabled
```

## Performance Hotkeys

Add to your main script:

```gdscript
func _input(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F12:  # Print report
                VRProfiler.print_performance_report()
            KEY_F11:  # Export JSON
                VRProfiler.export_report_json("user://perf_" + str(Time.get_ticks_msec()) + ".json")
            KEY_F10:  # Toggle profiling
                if VRProfiler.is_profiling:
                    VRProfiler.stop_profiling()
                else:
                    VRProfiler.start_profiling()
            KEY_F9:   # Reset stats
                VRProfiler.reset_stats()
```

## Optimization Checklist

**Before Launch:**
- [ ] Greedy meshing enabled
- [ ] Async generation working (check stats)
- [ ] LOD distances configured
- [ ] Creature AI using optimized version
- [ ] Culling distance appropriate for hardware
- [ ] Texture compression enabled
- [ ] Tested in VR headset
- [ ] All scenarios >80 FPS
- [ ] No frame spikes >20ms

**During Development:**
- [ ] Profile regularly (F12)
- [ ] Monitor draw calls (<1000)
- [ ] Monitor triangle count (<100K)
- [ ] Check creature count (<100)
- [ ] Review bottlenecks weekly
- [ ] Export reports for comparison

## Quick Wins (5-10 Minutes Each)

1. **Enable Greedy Meshing**
   - Set `use_greedy_meshing = true`
   - Impact: -70% triangles

2. **Enable Batching**
   - Set `enable_mesh_batching = true`
   - Impact: -40% draw calls

3. **Replace Creature AI**
   - Use `CreatureAIOptimized`
   - Impact: -67% AI time

4. **Reduce Culling Distance**
   - Set `culling_distance = 150.0`
   - Impact: -20% chunks rendered

5. **Enable Texture Compression**
   - Project Settings → Rendering
   - Impact: -50% VRAM

## Hardware-Specific Tuning

### Quest 2/3 (Standalone)

```gdscript
terrain.lod_distances = [15, 30, 60, 120]  # Closer LODs
terrain.culling_distance = 120.0           # Shorter distance
terrain.max_cache_size = 100               # Less cache
target_fps = 72                            # Lower target
```

### PCVR (RTX 3060-3070)

```gdscript
terrain.lod_distances = [25, 50, 100, 200]
terrain.culling_distance = 200.0
terrain.max_cache_size = 200
target_fps = 90
```

### PCVR (RTX 3080+)

```gdscript
terrain.lod_distances = [30, 60, 120, 240]
terrain.culling_distance = 250.0
terrain.max_cache_size = 300
target_fps = 120
```

## Performance Budget

**Total frame budget: 11.11ms @ 90 FPS**

```
Recommended allocation:
├─ Voxel Terrain:  1.0ms  (9%)
├─ Creature AI:    1.0ms  (9%)
├─ Physics:        1.5ms  (13%)
├─ Rendering:      4.0ms  (36%)
├─ Scripting:      1.0ms  (9%)
├─ Audio:          0.5ms  (4%)
├─ UI:             0.5ms  (4%)
└─ Reserve:        1.6ms  (16%)
```

## Expected Results

After implementing optimizations:

**Performance Gains:**
- FPS: +77% (45 → 85+)
- Frame Time: -45% (22ms → 11ms)
- Draw Calls: -60% (2500 → 1000)
- Triangles: -80% (450K → 90K)
- Memory: -55% (2.2GB → 1.0GB)

**Scenarios:**
- Spawn: 105 FPS ✓
- Voxel Heavy: 87 FPS ✓
- Creature Heavy: 82 FPS ✓
- Combat: 86 FPS ✓
- Exploration: 92 FPS ✓

---

**Quick Ref Version:** 1.0
**Last Updated:** 2025-12-02

**Full Documentation:**
- Detailed Report: `VR_OPTIMIZATION_REPORT.md`
- Integration Guide: `INTEGRATION_GUIDE.md`
- Benchmarks: `BENCHMARK_COMPARISON.md`
