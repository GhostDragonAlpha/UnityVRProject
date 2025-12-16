# VoxelPerformanceMonitor Documentation

## Overview

The VoxelPerformanceMonitor is a comprehensive performance monitoring system designed to ensure the SpaceTime VR project maintains its 90 FPS target while running voxel terrain systems. It tracks critical performance metrics and provides real-time warnings when performance degrades.

## Key Features

- **Frame Time Tracking**: Monitors both physics (11.11ms) and rendering (11.11ms) frame times
- **Chunk Generation Profiling**: Tracks time spent generating voxel chunks
- **Collision Mesh Profiling**: Tracks time spent generating collision meshes
- **Memory Monitoring**: Tracks voxel system memory usage
- **Active Chunk Counting**: Monitors the number of active chunks in memory
- **Automatic Warnings**: Emits signals when performance thresholds are exceeded
- **Debug UI**: Optional real-time stats overlay for development
- **Telemetry Integration**: Ready for integration with existing telemetry system

## Installation

### 1. Add to Autoloads

Add the following line to `project.godot` under the `[autoload]` section:

```ini
[autoload]
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
```

### 2. Position in Initialization Order

The VoxelPerformanceMonitor should be loaded after core systems but doesn't have strict dependencies. Recommended position:

```ini
[autoload]
ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
```

## Usage

### With godot_voxel Addon

If using Zylann's godot_voxel addon:

```gdscript
# In your terrain setup script
var voxel_terrain = $VoxelTerrain  # Your VoxelTerrain node

# Connect the monitor
VoxelPerformanceMonitor.set_voxel_terrain(voxel_terrain)

# Enable debug UI during development
VoxelPerformanceMonitor.set_debug_ui_enabled(true)

# Connect to warnings
VoxelPerformanceMonitor.performance_warning.connect(_on_performance_warning)
```

The monitor will automatically connect to the terrain's signals:
- `block_loaded` - Triggered when chunks load
- `block_unloaded` - Triggered when chunks unload
- `mesh_block_entered` - Triggered when mesh blocks enter view
- `mesh_block_exited` - Triggered when mesh blocks exit view

### With Custom Voxel Implementation

If using a custom voxel system, use the manual timing API:

```gdscript
func generate_chunk(position: Vector3i) -> void:
    # Start timing
    VoxelPerformanceMonitor.start_chunk_generation()

    # Your chunk generation code
    var chunk = create_chunk_data(position)

    # End timing (automatically checks thresholds)
    VoxelPerformanceMonitor.end_chunk_generation()

    # Update chunk count
    VoxelPerformanceMonitor.increment_chunk_count()

func generate_collision_mesh(chunk: Chunk) -> void:
    # Start timing
    VoxelPerformanceMonitor.start_collision_generation()

    # Your collision mesh generation code
    var collision = create_collision_mesh(chunk)

    # End timing
    VoxelPerformanceMonitor.end_collision_generation()

func unload_chunk(position: Vector3i) -> void:
    # Your chunk unloading code
    remove_chunk(position)

    # Update chunk count
    VoxelPerformanceMonitor.decrement_chunk_count()
```

## Performance Thresholds

### Frame Time Budgets (90 FPS VR)
- **Physics Frame**: 11.11ms (1000ms / 90fps)
- **Render Frame**: 11.11ms (1000ms / 90fps)
- **Warning Trigger**: 90% of budget (10ms)

### Generation Time Limits
- **Chunk Generation**: 5ms maximum (single chunk)
- **Collision Generation**: 3ms maximum (single chunk)

### Resource Limits
- **Active Chunks**: 512 maximum
- **Memory**: 2048 MB maximum (voxel system estimate)

## Signals

### performance_warning
```gdscript
signal performance_warning(warning_type: String, value: float, threshold: float)
```

Emitted when a performance metric exceeds its threshold.

**Warning Types:**
- `chunk_generation` - Chunk generation took too long
- `collision_generation` - Collision mesh generation took too long
- `physics_frame` - Physics frame time exceeded budget
- `render_frame` - Render frame time exceeded budget
- `memory` - Memory usage exceeded threshold
- `chunk_count` - Active chunk count exceeded maximum

**Example:**
```gdscript
func _on_performance_warning(type: String, value: float, threshold: float) -> void:
    match type:
        "render_frame":
            # Reduce rendering quality
            PerformanceOptimizer.set_auto_quality_enabled(true)
        "chunk_count":
            # Reduce view distance
            voxel_terrain.view_distance -= 16
        "memory":
            # Unload distant chunks
            unload_distant_chunks()
```

### performance_recovered
```gdscript
signal performance_recovered(metric: String)
```

Emitted when a previously-warned metric returns to acceptable levels.

### statistics_updated
```gdscript
signal statistics_updated(stats: Dictionary)
```

Emitted every second (90 physics frames at 90Hz) with current statistics.

### chunk_generation_completed
```gdscript
signal chunk_generation_completed(duration_ms: float)
```

Emitted after each chunk generation completes (manual timing API only).

### collision_generation_completed
```gdscript
signal collision_generation_completed(duration_ms: float)
```

Emitted after each collision generation completes (manual timing API only).

## Statistics

### get_statistics() -> Dictionary

Returns a dictionary with all current performance metrics:

```gdscript
{
    # Frame time metrics
    "target_fps": 90.0,
    "frame_time_budget_ms": 11.11,
    "physics_frame_time_ms": 8.5,      # Average
    "render_frame_time_ms": 9.2,       # Average
    "physics_frame_time_max_ms": 12.1, # Maximum in sample window
    "render_frame_time_max_ms": 13.4,  # Maximum in sample window

    # Chunk metrics
    "active_chunk_count": 256,
    "total_chunks_generated": 1024,
    "total_chunks_unloaded": 768,
    "max_chunk_count": 512,

    # Generation timing
    "chunk_generation_avg_ms": 2.3,
    "chunk_generation_max_ms": 4.8,
    "collision_generation_avg_ms": 1.2,
    "collision_generation_max_ms": 2.9,

    # Memory
    "voxel_memory_mb": 512.0,
    "max_memory_mb": 2048.0,
    "total_memory_mb": 1024.0,

    # Performance singleton metrics
    "time_process": 9.5,
    "time_physics_process": 8.2,

    # Warning states
    "has_warnings": false,
    "warning_states": {
        "chunk_generation": false,
        "collision_generation": false,
        "physics_frame": false,
        "render_frame": false,
        "memory": false,
        "chunk_count": false
    }
}
```

### get_performance_report() -> String

Returns a formatted multi-line string with all statistics:

```
=== Voxel Performance Report ===

--- Frame Time ---
Target: 90 FPS (11.11 ms budget)
Physics: 8.50 ms (avg) / 12.10 ms (max)
Render: 9.20 ms (avg) / 13.40 ms (max)

--- Chunks ---
Active: 256 / 512
Generated: 1024
Unloaded: 768

--- Generation Time ---
Chunk: 2.30 ms (avg) / 4.80 ms (max)
Collision: 1.20 ms (avg) / 2.90 ms (max)

--- Memory ---
Voxel: 512.0 MB / 2048.0 MB
Total: 1024.0 MB

--- Warnings ---
  None - All systems nominal
```

## Debug UI

The debug UI provides a real-time overlay showing performance metrics:

```gdscript
# Enable debug UI
VoxelPerformanceMonitor.set_debug_ui_enabled(true)

# Disable debug UI
VoxelPerformanceMonitor.set_debug_ui_enabled(false)
```

The debug UI appears in the top-right corner and shows:
- Frame time (physics and render)
- Active chunk count
- Generation times
- Memory usage
- Active warnings

## API Reference

### Configuration

#### set_voxel_terrain(terrain: Node) -> bool
Connect to a voxel terrain node (godot_voxel addon).

#### set_monitoring_enabled(enabled: bool) -> void
Enable or disable performance monitoring.

#### is_monitoring_enabled() -> bool
Check if monitoring is enabled.

#### set_debug_ui_enabled(enabled: bool) -> void
Show or hide the debug UI overlay.

### Manual Timing

#### start_chunk_generation() -> void
Start timing a chunk generation operation.

#### end_chunk_generation() -> void
End timing and record chunk generation time.

#### start_collision_generation() -> void
Start timing a collision mesh generation operation.

#### end_collision_generation() -> void
End timing and record collision generation time.

#### increment_chunk_count() -> void
Manually increment the active chunk count.

#### decrement_chunk_count() -> void
Manually decrement the active chunk count.

### Query Methods

#### get_statistics() -> Dictionary
Get current performance statistics (see Statistics section).

#### get_performance_report() -> String
Get a formatted performance report string.

#### is_performance_acceptable() -> bool
Check if all metrics are within acceptable ranges.

#### get_active_warnings() -> Array[String]
Get list of currently active warning types.

### Control

#### reset_statistics() -> void
Reset all statistics and counters to initial state.

#### shutdown() -> void
Cleanup and shutdown the monitor.

## Integration Examples

### With ResonanceEngine PerformanceOptimizer

```gdscript
# Connect voxel warnings to quality adjustment
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, val, thresh):
        if type in ["render_frame", "physics_frame"]:
            ResonanceEngine.performance_optimizer.set_auto_quality_enabled(true)
)
```

### With HTTP API

Add endpoints to `scripts/http_api/performance_router.gd`:

```gdscript
# GET /voxel/performance
func _handle_get_voxel_performance(request: HTTPServerRequest) -> Dictionary:
    return VoxelPerformanceMonitor.get_statistics()

# GET /voxel/performance/report
func _handle_get_voxel_report(request: HTTPServerRequest) -> String:
    return VoxelPerformanceMonitor.get_performance_report()
```

### With Telemetry Streaming

```gdscript
# Stream voxel performance to telemetry
VoxelPerformanceMonitor.statistics_updated.connect(
    func(stats):
        TelemetryServer.send_event({
            "type": "voxel_performance",
            "timestamp": Time.get_ticks_msec(),
            "physics_frame_ms": stats.physics_frame_time_ms,
            "render_frame_ms": stats.render_frame_time_ms,
            "active_chunks": stats.active_chunk_count,
            "has_warnings": stats.has_warnings
        })
)
```

## Performance Optimization Strategies

When warnings are triggered, consider these optimizations:

### Chunk Generation Warnings
- Reduce chunk generation batch size
- Defer non-essential chunk processing
- Use simpler noise functions
- Cache repeated calculations

### Collision Generation Warnings
- Simplify collision mesh resolution
- Use simpler collision shapes (boxes instead of mesh)
- Defer collision generation to background thread
- Batch collision updates

### Physics Frame Warnings
- Reduce physics iterations (ProjectSettings)
- Simplify collision shapes
- Reduce active physics bodies
- Increase physics timestep (not recommended for VR)

### Render Frame Warnings
- Enable PerformanceOptimizer auto-quality
- Reduce LOD distances
- Reduce shadow quality
- Disable expensive effects

### Memory Warnings
- Reduce view distance
- Unload distant chunks more aggressively
- Compress chunk data
- Use LOD for distant chunks (lower resolution)

### Chunk Count Warnings
- Reduce view distance
- Increase chunk size (fewer, larger chunks)
- Implement more aggressive culling

## Best Practices

1. **Enable during development**: Always run with debug UI enabled during development to catch performance issues early

2. **Monitor in CI/CD**: Include performance checks in automated testing

3. **Log warnings**: Connect to signals and log all warnings for analysis

4. **Gradual degradation**: When warnings occur, reduce quality gradually rather than drastically

5. **Hysteresis**: Add buffer zones to prevent quality thrashing (don't reduce immediately when crossing threshold)

6. **Profile first**: Use statistics to identify bottlenecks before applying optimizations

7. **Test on target hardware**: VR performance requirements are strict - test on actual VR hardware

## Troubleshooting

### Monitor not receiving chunk events
- Verify voxel terrain has the expected signals
- Check `_terrain_connected` is true
- Call `set_voxel_terrain()` after terrain is in scene tree

### Frame time warnings constantly firing
- Check if other systems (not voxel) are causing slowdown
- Verify TARGET_FPS is achievable on hardware
- Review PerformanceOptimizer quality settings

### Statistics not updating
- Verify `set_monitoring_enabled(true)` is called
- Check monitor is properly initialized
- Ensure monitor is in scene tree (autoload)

### Debug UI not showing
- Verify UI layer is not being hidden
- Check `set_debug_ui_enabled(true)` is called
- Ensure game is running (not paused)

## See Also

- `scripts/rendering/performance_optimizer.gd` - General performance optimization
- `scripts/core/engine.gd` - ResonanceEngine core coordinator
- `examples/voxel_performance_integration.gd` - Integration examples
- `addons/godot_voxel/` - Zylann's voxel addon (if installed)
