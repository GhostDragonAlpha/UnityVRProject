# VoxelPerformanceMonitor - Quick Reference

## Installation
```ini
# Add to project.godot [autoload] section
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
```

## Basic Setup
```gdscript
# Connect to voxel terrain (godot_voxel addon)
VoxelPerformanceMonitor.set_voxel_terrain($VoxelTerrain)

# Enable debug UI
VoxelPerformanceMonitor.set_debug_ui_enabled(true)

# Connect to warnings
VoxelPerformanceMonitor.performance_warning.connect(_on_perf_warning)
```

## Manual Timing (Custom Voxel Systems)
```gdscript
# Chunk generation
VoxelPerformanceMonitor.start_chunk_generation()
# ... your generation code ...
VoxelPerformanceMonitor.end_chunk_generation()
VoxelPerformanceMonitor.increment_chunk_count()

# Collision generation
VoxelPerformanceMonitor.start_collision_generation()
# ... your collision code ...
VoxelPerformanceMonitor.end_collision_generation()

# Unload chunk
VoxelPerformanceMonitor.decrement_chunk_count()
```

## Performance Thresholds (90 FPS VR)
| Metric | Threshold | Description |
|--------|-----------|-------------|
| Physics Frame | 11.11 ms | Physics timestep budget |
| Render Frame | 11.11 ms | Render frame budget |
| Chunk Generation | 5 ms | Max time per chunk |
| Collision Generation | 3 ms | Max time per collision mesh |
| Active Chunks | 512 | Max chunks in memory |
| Memory | 2048 MB | Max voxel memory usage |

## Warning Types
- `chunk_generation` - Chunk generation too slow
- `collision_generation` - Collision generation too slow
- `physics_frame` - Physics frame over budget
- `render_frame` - Render frame over budget
- `memory` - Memory usage too high
- `chunk_count` - Too many active chunks

## Common Responses to Warnings
```gdscript
func _on_perf_warning(type: String, value: float, threshold: float) -> void:
    match type:
        "chunk_generation":
            # Reduce chunk batch size or complexity
            voxel_system.chunk_batch_size -= 1

        "collision_generation":
            # Simplify collision meshes
            voxel_system.collision_resolution -= 1

        "physics_frame":
            # Reduce physics load
            voxel_system.disable_distant_physics()

        "render_frame":
            # Enable auto quality reduction
            ResonanceEngine.performance_optimizer.set_auto_quality_enabled(true)

        "memory":
            # Unload distant chunks
            voxel_system.reduce_view_distance()

        "chunk_count":
            # Reduce view distance
            voxel_system.view_distance -= 16
```

## Query Statistics
```gdscript
# Get all statistics
var stats = VoxelPerformanceMonitor.get_statistics()
print("Active chunks: ", stats.active_chunk_count)
print("Physics frame: ", stats.physics_frame_time_ms, " ms")

# Get formatted report
print(VoxelPerformanceMonitor.get_performance_report())

# Check if performance is acceptable
if not VoxelPerformanceMonitor.is_performance_acceptable():
    print("Performance issues: ", VoxelPerformanceMonitor.get_active_warnings())
```

## Integration with PerformanceOptimizer
```gdscript
# Auto-reduce quality when voxel frame time warnings occur
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, val, thresh):
        if type in ["render_frame", "physics_frame"]:
            ResonanceEngine.performance_optimizer.set_auto_quality_enabled(true)
)
```

## HTTP API Integration (Example)
```gdscript
# Add to scripts/http_api/performance_router.gd

# GET /voxel/performance
func get_voxel_performance() -> Dictionary:
    return VoxelPerformanceMonitor.get_statistics()

# GET /voxel/performance/report
func get_voxel_report() -> String:
    return VoxelPerformanceMonitor.get_performance_report()

# GET /voxel/warnings
func get_voxel_warnings() -> Array:
    return VoxelPerformanceMonitor.get_active_warnings()
```

## Signals
```gdscript
# Warning triggered
performance_warning.connect(func(type, value, threshold): ...)

# Warning cleared
performance_recovered.connect(func(metric): ...)

# Statistics updated (every second)
statistics_updated.connect(func(stats): ...)

# Generation completed
chunk_generation_completed.connect(func(duration_ms): ...)
collision_generation_completed.connect(func(duration_ms): ...)
```

## Control Methods
```gdscript
# Enable/disable monitoring
VoxelPerformanceMonitor.set_monitoring_enabled(true)

# Enable/disable debug UI
VoxelPerformanceMonitor.set_debug_ui_enabled(true)

# Reset statistics
VoxelPerformanceMonitor.reset_statistics()

# Shutdown
VoxelPerformanceMonitor.shutdown()
```

## Statistics Dictionary Structure
```gdscript
{
    # Frame metrics
    "target_fps": 90.0,
    "frame_time_budget_ms": 11.11,
    "physics_frame_time_ms": float,     # Average
    "render_frame_time_ms": float,      # Average
    "physics_frame_time_max_ms": float, # Max in window
    "render_frame_time_max_ms": float,  # Max in window

    # Chunk metrics
    "active_chunk_count": int,
    "total_chunks_generated": int,
    "total_chunks_unloaded": int,
    "max_chunk_count": 512,

    # Generation timing
    "chunk_generation_avg_ms": float,
    "chunk_generation_max_ms": float,
    "collision_generation_avg_ms": float,
    "collision_generation_max_ms": float,

    # Memory
    "voxel_memory_mb": float,
    "max_memory_mb": 2048.0,
    "total_memory_mb": float,

    # Performance singleton
    "time_process": float,
    "time_physics_process": float,

    # Warnings
    "has_warnings": bool,
    "warning_states": Dictionary
}
```

## Best Practices
1. Enable debug UI during development
2. Connect to warning signals and respond appropriately
3. Test on actual VR hardware (90 FPS requirement is strict)
4. Profile before optimizing (use statistics to find bottlenecks)
5. Implement gradual quality degradation (not sudden drops)
6. Add hysteresis to prevent quality thrashing
7. Log all warnings for post-mortem analysis
8. Monitor in CI/CD and automated tests

## Performance Optimization Checklist

### When chunk_generation warning fires:
- [ ] Reduce chunk batch size
- [ ] Simplify noise/generation algorithms
- [ ] Cache repeated calculations
- [ ] Move to background thread (if possible)
- [ ] Reduce chunk detail level

### When collision_generation warning fires:
- [ ] Reduce collision mesh resolution
- [ ] Use simpler collision shapes (boxes vs meshes)
- [ ] Defer collision generation
- [ ] Batch collision updates
- [ ] Skip collision for distant chunks

### When physics_frame warning fires:
- [ ] Reduce physics iterations
- [ ] Simplify collision shapes
- [ ] Reduce active physics bodies
- [ ] Disable physics for distant chunks
- [ ] Use static collision for non-interactive chunks

### When render_frame warning fires:
- [ ] Enable PerformanceOptimizer auto-quality
- [ ] Reduce LOD distances
- [ ] Reduce shadow quality
- [ ] Disable expensive effects (reflections, GI)
- [ ] Reduce mesh complexity

### When memory warning fires:
- [ ] Reduce view distance
- [ ] Unload distant chunks more aggressively
- [ ] Compress chunk data in memory
- [ ] Use LOD (lower resolution for distant chunks)
- [ ] Free temporary generation buffers

### When chunk_count warning fires:
- [ ] Reduce view distance
- [ ] Increase chunk size (fewer larger chunks)
- [ ] Implement frustum culling
- [ ] Implement occlusion culling
- [ ] Unload chunks behind player

## See Also
- Full documentation: `docs/voxel_performance_monitor.md`
- Integration examples: `examples/voxel_performance_integration.gd`
- Unit tests: `tests/unit/test_voxel_performance_monitor.gd`
- PerformanceOptimizer: `scripts/rendering/performance_optimizer.gd`
