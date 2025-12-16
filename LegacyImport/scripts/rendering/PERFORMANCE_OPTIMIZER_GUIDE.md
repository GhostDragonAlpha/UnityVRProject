# PerformanceOptimizer Guide

## Overview

The PerformanceOptimizer is a comprehensive system for maintaining VR performance at the target 90 FPS. It profiles frame time, automatically adjusts quality settings, implements occlusion culling, optimizes physics calculations, and provides detailed performance monitoring.

## Requirements Addressed

- **2.1**: Maintain minimum 90 FPS during normal operation
- **2.2**: Create separate stereoscopic display regions for VR
- **2.3**: Reduce visual complexity through automatic LOD adjustments
- **2.4**: Apply correct inter-pupillary distance
- **2.5**: Log warnings and reduce rendering load when performance degrades
- **50.4**: Add performance monitoring

## Architecture

### Quality Levels

The optimizer supports 5 quality levels:

1. **ULTRA** - Maximum visual fidelity

   - LOD bias: 1.5 (higher detail at distance)
   - MSAA: 4x
   - Screen-space AA: FXAA
   - TAA: Enabled
   - Physics iterations: 8
   - Shader complexity: High

2. **HIGH** - Balanced quality and performance (default)

   - LOD bias: 1.0 (normal)
   - MSAA: 2x
   - Screen-space AA: FXAA
   - TAA: Enabled
   - Physics iterations: 8
   - Shader complexity: Medium

3. **MEDIUM** - Favor performance

   - LOD bias: 0.75 (reduced LOD distances)
   - MSAA: 2x
   - Screen-space AA: Disabled
   - TAA: Disabled
   - Physics iterations: 6
   - Shader complexity: Low

4. **LOW** - Prioritize performance

   - LOD bias: 0.5 (aggressive LOD reduction)
   - MSAA: Disabled
   - Screen-space AA: Disabled
   - TAA: Disabled
   - Physics iterations: 4
   - Shader complexity: Minimal

5. **MINIMUM** - Maximum performance
   - LOD bias: 0.25 (maximum LOD reduction)
   - MSAA: Disabled
   - Screen-space AA: Disabled
   - TAA: Disabled
   - Physics iterations: 2
   - Shader complexity: Minimal

### Automatic Quality Adjustment

The optimizer continuously monitors FPS and automatically adjusts quality:

- **FPS < 80**: Reduce quality level (with 2-second cooldown)
- **FPS > 95**: Increase quality level (with 2-second cooldown)
- Emits signals when FPS drops below or recovers to target

### Frame Profiling

- Samples frame time over 60 frames for accurate averaging
- Calculates current FPS from average frame time
- Provides frame time budget monitoring (11.11ms for 90 FPS)

### Occlusion Culling

- Automatically finds and manages OccluderInstance3D nodes
- Can create occluders for MeshInstance3D objects
- Toggle occlusion culling on/off dynamically

### Performance Statistics

Collects comprehensive metrics using Godot's Performance singleton:

- FPS and frame time
- Process time and physics time
- Memory usage (static and dynamic)
- Objects and vertices rendered
- Draw calls
- Active physics objects and collision pairs

## Usage

### Basic Initialization

```gdscript
# In ResonanceEngine or main scene
var performance_optimizer = PerformanceOptimizer.new()
add_child(performance_optimizer)

# Initialize with LODManager and viewport
var lod_manager = get_node("LODManager")
performance_optimizer.initialize(lod_manager, get_viewport())

# Connect to signals
performance_optimizer.fps_below_target.connect(_on_fps_below_target)
performance_optimizer.fps_recovered.connect(_on_fps_recovered)
performance_optimizer.quality_level_changed.connect(_on_quality_changed)
```

### Manual Quality Control

```gdscript
# Set specific quality level
performance_optimizer.set_quality_level(PerformanceOptimizer.QualityLevel.HIGH)

# Enable/disable automatic quality adjustment
performance_optimizer.set_auto_quality_enabled(true)

# Get current quality level
var level = performance_optimizer.get_quality_level()
```

### Performance Monitoring

```gdscript
# Get current FPS
var fps = performance_optimizer.get_current_fps()

# Get average frame time
var frame_time = performance_optimizer.get_average_frame_time_ms()

# Check if meeting target
var is_good = performance_optimizer.is_fps_meeting_target()

# Get health status
var health = performance_optimizer.get_fps_health()  # "Excellent", "Good", "Acceptable", "Poor", "Critical"

# Get detailed statistics
var stats = performance_optimizer.get_statistics()
print("FPS: ", stats.fps)
print("Objects rendered: ", stats.objects_rendered)
print("Memory: ", stats.memory_dynamic, " MB")

# Get formatted report
var report = performance_optimizer.get_performance_report()
print(report)
```

### Occlusion Culling

```gdscript
# Enable/disable occlusion culling
performance_optimizer.set_occlusion_culling_enabled(true)

# Create occluder for a mesh
var mesh_instance = $MyMesh
var occluder = performance_optimizer.create_occluder_for_mesh(mesh_instance)
```

### Physics Optimization

```gdscript
# Optimize physics based on current quality level
performance_optimizer.optimize_physics(physics_engine)

# The optimizer automatically adjusts:
# - Physics solver iterations
# - Physics substeps
```

## Integration with Other Systems

### LODManager Integration

The optimizer automatically adjusts LOD bias based on quality level:

```gdscript
# LOD bias is set automatically when quality changes
# ULTRA: 1.5 (higher detail)
# HIGH: 1.0 (normal)
# MEDIUM: 0.75
# LOW: 0.5
# MINIMUM: 0.25 (maximum performance)
```

### Viewport Settings

The optimizer manages viewport rendering settings:

```gdscript
# MSAA (Multi-Sample Anti-Aliasing)
viewport.msaa_3d = Viewport.MSAA_4X  # ULTRA
viewport.msaa_3d = Viewport.MSAA_2X  # HIGH/MEDIUM
viewport.msaa_3d = Viewport.MSAA_DISABLED  # LOW/MINIMUM

# Screen-space AA
viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA  # ULTRA/HIGH
viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED  # MEDIUM/LOW/MINIMUM

# Temporal Anti-Aliasing
viewport.use_taa = true  # ULTRA/HIGH
viewport.use_taa = false  # MEDIUM/LOW/MINIMUM
```

### Shader Complexity

The optimizer provides a shader complexity level (0-3) that shaders can query:

```gdscript
# In your shader code, you can adjust features based on complexity
var complexity = performance_optimizer.get_shader_complexity()

# 0 = Minimal (disable expensive effects)
# 1 = Low (basic effects only)
# 2 = Medium (most effects)
# 3 = High (all effects)
```

## Signals

### fps_below_target(current_fps: float, target_fps: float)

Emitted when FPS drops below the minimum acceptable threshold (80 FPS).

```gdscript
func _on_fps_below_target(current_fps: float, target_fps: float) -> void:
    print("Performance warning: FPS = %.1f" % current_fps)
    # Show performance warning to user
```

### fps_recovered(current_fps: float)

Emitted when FPS recovers to acceptable levels.

```gdscript
func _on_fps_recovered(current_fps: float) -> void:
    print("Performance recovered: FPS = %.1f" % current_fps)
```

### quality_level_changed(old_level: int, new_level: int)

Emitted when quality level changes (automatic or manual).

```gdscript
func _on_quality_changed(old_level: int, new_level: int) -> void:
    var level_name = PerformanceOptimizer.QualityLevel.keys()[new_level]
    print("Quality changed to: ", level_name)
```

### occlusion_culling_toggled(enabled: bool)

Emitted when occlusion culling is enabled or disabled.

```gdscript
func _on_occlusion_toggled(enabled: bool) -> void:
    print("Occlusion culling: ", "ON" if enabled else "OFF")
```

### statistics_updated(stats: Dictionary)

Emitted periodically (every 60 frames) with updated statistics.

```gdscript
func _on_statistics_updated(stats: Dictionary) -> void:
    update_performance_ui(stats)
```

## Performance Targets

### VR Requirements

- **Target FPS**: 90 FPS per eye
- **Frame Time Budget**: 11.11ms
- **Minimum Acceptable**: 80 FPS (12.5ms)

### Quality Adjustment Strategy

1. Monitor FPS over 60-frame rolling average
2. If FPS < 80 for 2+ seconds, reduce quality
3. If FPS > 95 for 2+ seconds, increase quality
4. Never adjust more than once per 2 seconds (cooldown)

## Best Practices

### 1. Initialize Early

Initialize the optimizer early in your startup sequence, after the renderer and LODManager are ready.

### 2. Connect to Signals

Always connect to `fps_below_target` to log performance issues and potentially notify the user.

### 3. Provide User Control

Allow users to manually set quality level and disable auto-adjustment if desired:

```gdscript
# In settings menu
func _on_quality_setting_changed(level: int) -> void:
    performance_optimizer.set_auto_quality_enabled(false)
    performance_optimizer.set_quality_level(level)

func _on_auto_quality_toggled(enabled: bool) -> void:
    performance_optimizer.set_auto_quality_enabled(enabled)
```

### 4. Monitor Statistics

Display key statistics in a debug overlay:

```gdscript
func _update_debug_overlay() -> void:
    var stats = performance_optimizer.get_statistics()
    debug_label.text = "FPS: %.1f\nFrame: %.2fms\nObjects: %d" % [
        stats.fps,
        stats.frame_time_ms,
        stats.objects_rendered
    ]
```

### 5. Use Occlusion Culling

Create occluders for large static geometry:

```gdscript
# For planets, large structures, etc.
for mesh in large_static_meshes:
    performance_optimizer.create_occluder_for_mesh(mesh)
```

### 6. Reset Statistics When Needed

Reset statistics when changing scenes or after loading:

```gdscript
func _on_scene_changed() -> void:
    performance_optimizer.reset_statistics()
```

## Troubleshooting

### FPS Still Below Target

If automatic quality adjustment doesn't help:

1. Check if LODManager is properly configured
2. Verify occlusion culling is enabled
3. Profile specific bottlenecks using Godot's profiler
4. Consider reducing scene complexity (fewer objects, simpler shaders)

### Quality Oscillating

If quality keeps changing up and down:

1. Increase the cooldown period (modify QUALITY_ADJUSTMENT_COOLDOWN)
2. Widen the FPS thresholds (MIN_ACCEPTABLE_FPS and TARGET_FPS + buffer)
3. Disable auto-adjustment and set quality manually

### Statistics Not Updating

Ensure the optimizer is initialized and added to the scene tree:

```gdscript
if not performance_optimizer.is_initialized():
    print("ERROR: PerformanceOptimizer not initialized")
```

## Testing

Run the unit tests to verify functionality:

```bash
# Through remote server (when Godot is running)
python tests/run_performance_optimizer_test.py

# Or directly (when Godot editor is available)
godot --headless --script tests/unit/test_performance_optimizer.gd
```

## Future Enhancements

Potential improvements for future versions:

1. **Adaptive LOD Distances**: Dynamically adjust LOD distances based on scene complexity
2. **GPU Profiling**: Integrate GPU timing for more accurate bottleneck detection
3. **Predictive Quality**: Use machine learning to predict quality needs
4. **Per-Scene Profiles**: Save optimal quality settings per scene
5. **Network Optimization**: Reduce network traffic in multiplayer when performance is poor
6. **Shader Variants**: Automatically compile and switch between shader variants
7. **Memory Pressure Detection**: Reduce quality when memory usage is high

## References

- Godot Performance Monitoring: https://docs.godotengine.org/en/stable/classes/class_performance.html
- VR Performance Best Practices: https://docs.godotengine.org/en/stable/tutorials/vr/index.html
- LOD System Documentation: See `scripts/rendering/LOD_MANAGER_GUIDE.md`
