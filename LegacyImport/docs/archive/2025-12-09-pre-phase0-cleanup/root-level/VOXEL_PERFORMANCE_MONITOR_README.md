# VoxelPerformanceMonitor - Complete Performance Monitoring for Voxel Terrain

## Overview

The VoxelPerformanceMonitor is a comprehensive performance monitoring system specifically designed for voxel terrain systems in the SpaceTime VR project. It ensures the critical 90 FPS VR target is maintained by tracking all performance-critical metrics and providing real-time warnings when performance degrades.

## Current Status

✅ **COMPLETE** - Fully implemented and ready to use

### What's Included

1. **Core Monitor** (`scripts/core/voxel_performance_monitor.gd`)
   - Frame time tracking (physics and render)
   - Chunk generation profiling
   - Collision mesh generation profiling
   - Memory usage monitoring
   - Active chunk counting
   - Automatic warning system
   - Real-time statistics
   - Optional debug UI overlay

2. **Documentation**
   - Full documentation: `docs/voxel_performance_monitor.md`
   - Quick reference: `docs/voxel_performance_quick_reference.md`

3. **Examples**
   - Integration guide: `examples/voxel_performance_integration.gd`
   - Shows usage with godot_voxel addon
   - Shows usage with custom voxel implementations
   - Demonstrates signal handling
   - Shows HTTP API integration
   - Shows telemetry streaming integration

4. **Tests**
   - Comprehensive unit tests: `tests/unit/test_voxel_performance_monitor.gd`
   - Tests all major functionality
   - Tests warning system
   - Tests statistics tracking
   - Tests debug UI

5. **Autoload Configuration**
   - ✅ Already added to `project.godot` autoloads (line 24)

## Quick Start

### 1. Basic Usage (No Setup Required)

The monitor is already configured as an autoload and ready to use:

```gdscript
# Access from anywhere in your project
VoxelPerformanceMonitor.set_debug_ui_enabled(true)
print(VoxelPerformanceMonitor.get_performance_report())
```

### 2. With godot_voxel Addon

If you're using Zylann's godot_voxel addon:

```gdscript
# In your terrain setup script (e.g., vr_main.gd)
func _ready():
    var voxel_terrain = $VoxelTerrain

    # Connect monitor to terrain
    VoxelPerformanceMonitor.set_voxel_terrain(voxel_terrain)

    # Enable debug UI during development
    VoxelPerformanceMonitor.set_debug_ui_enabled(true)

    # Connect to warnings
    VoxelPerformanceMonitor.performance_warning.connect(_on_voxel_warning)

func _on_voxel_warning(type: String, value: float, threshold: float):
    print("Voxel performance warning: %s" % type)
    # Take appropriate action based on warning type
```

### 3. With Custom Voxel Implementation

If you're building a custom voxel system:

```gdscript
func generate_chunk(pos: Vector3i):
    # Start timing
    VoxelPerformanceMonitor.start_chunk_generation()

    # Your chunk generation code
    var chunk_data = create_chunk(pos)

    # End timing
    VoxelPerformanceMonitor.end_chunk_generation()
    VoxelPerformanceMonitor.increment_chunk_count()

func generate_collision_mesh(chunk):
    VoxelPerformanceMonitor.start_collision_generation()
    var collision = create_collision_mesh(chunk)
    VoxelPerformanceMonitor.end_collision_generation()

func unload_chunk(pos: Vector3i):
    destroy_chunk(pos)
    VoxelPerformanceMonitor.decrement_chunk_count()
```

## Performance Targets (90 FPS VR)

The monitor enforces these thresholds:

| Metric | Threshold | Warning Trigger |
|--------|-----------|-----------------|
| Physics Frame Time | 11.11 ms | 10.0 ms (90%) |
| Render Frame Time | 11.11 ms | 10.0 ms (90%) |
| Chunk Generation | 5.0 ms | Per chunk |
| Collision Generation | 3.0 ms | Per mesh |
| Active Chunks | 512 | Total count |
| Memory Usage | 2048 MB | Voxel system |

## Key Features

### Automatic Signal Integration

When connected to a VoxelTerrain (godot_voxel addon), the monitor automatically hooks into:
- `block_loaded` - Tracks chunk loading
- `block_unloaded` - Tracks chunk unloading
- `mesh_block_entered` - Tracks mesh visibility
- `mesh_block_exited` - Tracks mesh culling

### Real-Time Warning System

Emits signals when thresholds are exceeded:
```gdscript
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, value, threshold):
        match type:
            "render_frame":
                # Enable quality reduction
                ResonanceEngine.performance_optimizer.set_auto_quality_enabled(true)
            "chunk_count":
                # Reduce view distance
                reduce_view_distance()
            "memory":
                # Unload distant chunks
                unload_far_chunks()
)
```

### Debug UI Overlay

Enable a real-time performance overlay:
```gdscript
VoxelPerformanceMonitor.set_debug_ui_enabled(true)
```

Shows:
- Current frame times (physics and render)
- Active chunk count
- Generation times (average and max)
- Memory usage
- Active warnings

### Comprehensive Statistics

Get detailed performance metrics:
```gdscript
var stats = VoxelPerformanceMonitor.get_statistics()
print("Physics frame: %.2f ms" % stats.physics_frame_time_ms)
print("Active chunks: %d / %d" % [stats.active_chunk_count, stats.max_chunk_count])
print("Chunk gen avg: %.2f ms" % stats.chunk_generation_avg_ms)
```

## Integration Points

### With ResonanceEngine

The monitor is designed to work alongside the existing PerformanceOptimizer:

```gdscript
# Coordinate quality reduction when voxel performance suffers
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, val, thresh):
        if type in ["render_frame", "physics_frame"]:
            ResonanceEngine.performance_optimizer.set_auto_quality_enabled(true)
)
```

### With HTTP API

Add endpoints to monitor voxel performance remotely:

```gdscript
# In scripts/http_api/performance_router.gd (or new voxel_router.gd)

# GET /voxel/performance
func handle_get_performance(request):
    return VoxelPerformanceMonitor.get_statistics()

# GET /voxel/performance/report
func handle_get_report(request):
    return {
        "report": VoxelPerformanceMonitor.get_performance_report(),
        "acceptable": VoxelPerformanceMonitor.is_performance_acceptable()
    }

# GET /voxel/warnings
func handle_get_warnings(request):
    return {
        "warnings": VoxelPerformanceMonitor.get_active_warnings(),
        "has_warnings": not VoxelPerformanceMonitor.is_performance_acceptable()
    }
```

### With Telemetry System

Stream voxel performance to the existing telemetry system:

```gdscript
# In addons/godot_debug_connection/telemetry_server.gd or similar

VoxelPerformanceMonitor.statistics_updated.connect(
    func(stats):
        var telemetry = {
            "type": "voxel_performance",
            "timestamp": Time.get_ticks_msec(),
            "fps": 1000.0 / stats.render_frame_time_ms if stats.render_frame_time_ms > 0 else 0,
            "physics_ms": stats.physics_frame_time_ms,
            "render_ms": stats.render_frame_time_ms,
            "chunks": stats.active_chunk_count,
            "chunk_gen_ms": stats.chunk_generation_avg_ms,
            "warnings": stats.warning_states
        }

        # Send to all connected telemetry clients
        broadcast_telemetry(telemetry)
)
```

## Common Use Cases

### 1. Development Debugging

```gdscript
# Enable debug UI to see real-time stats
VoxelPerformanceMonitor.set_debug_ui_enabled(true)

# Print detailed report when debugging
func _input(event):
    if event is InputEventKey and event.pressed and event.keycode == KEY_P:
        print(VoxelPerformanceMonitor.get_performance_report())
```

### 2. Automated Performance Testing

```gdscript
# In automated tests
func test_voxel_performance():
    # Generate test load
    for i in range(100):
        generate_test_chunk(Vector3i(i, 0, 0))

    # Wait for generation
    await get_tree().create_timer(1.0).timeout

    # Check performance
    assert(VoxelPerformanceMonitor.is_performance_acceptable(),
           "Voxel performance degraded during test")

    var stats = VoxelPerformanceMonitor.get_statistics()
    assert(stats.chunk_generation_avg_ms < 5.0,
           "Chunk generation too slow")
```

### 3. Dynamic Quality Adjustment

```gdscript
# Automatically adjust voxel quality based on performance
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, value, threshold):
        if type == "chunk_generation":
            # Reduce chunk detail
            voxel_terrain.lod_distance *= 0.9
        elif type == "collision_generation":
            # Simplify collision
            voxel_terrain.collision_resolution -= 1
        elif type == "chunk_count":
            # Reduce view distance
            voxel_terrain.view_distance = max(64, voxel_terrain.view_distance - 16)
)

VoxelPerformanceMonitor.performance_recovered.connect(
    func(metric):
        # Gradually restore quality when performance improves
        if metric == "chunk_count":
            voxel_terrain.view_distance = min(256, voxel_terrain.view_distance + 8)
)
```

### 4. Performance Profiling

```gdscript
# Profile specific operations
func profile_chunk_generation():
    VoxelPerformanceMonitor.reset_statistics()

    # Generate chunks
    for i in range(100):
        VoxelPerformanceMonitor.start_chunk_generation()
        generate_chunk(Vector3i(i, 0, 0))
        VoxelPerformanceMonitor.end_chunk_generation()

    # Analyze results
    var stats = VoxelPerformanceMonitor.get_statistics()
    print("Average generation: %.2f ms" % stats.chunk_generation_avg_ms)
    print("Max generation: %.2f ms" % stats.chunk_generation_max_ms)
    print("Total chunks: %d" % stats.total_chunks_generated)
```

## File Locations

```
C:/godot/
├── scripts/core/
│   └── voxel_performance_monitor.gd          # Main implementation
├── examples/
│   └── voxel_performance_integration.gd      # Integration examples
├── docs/
│   ├── voxel_performance_monitor.md          # Full documentation
│   └── voxel_performance_quick_reference.md  # Quick reference guide
├── tests/unit/
│   └── test_voxel_performance_monitor.gd     # Unit tests
└── project.godot                             # Autoload configured (line 24)
```

## Testing

Run the unit tests to verify functionality:

```bash
# From Godot editor (with GdUnit4 installed)
# Open GdUnit4 panel and run:
tests/unit/test_voxel_performance_monitor.gd

# Or via command line
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_voxel_performance_monitor.gd
```

Tests cover:
- Initialization
- Manual timing API
- Chunk count tracking
- Warning triggers and recovery
- Statistics accuracy
- Debug UI functionality
- Edge cases and error handling

## Next Steps

### To Use with godot_voxel Addon

1. Install godot_voxel addon from Asset Library
2. Add VoxelTerrain node to your scene
3. Call `VoxelPerformanceMonitor.set_voxel_terrain(terrain)`
4. Enable debug UI for development

### To Use with Custom Voxel System

1. Instrument your chunk generation with `start/end_chunk_generation()`
2. Instrument collision generation with `start/end_collision_generation()`
3. Call `increment/decrement_chunk_count()` on load/unload
4. Connect to warning signals
5. Implement warning response logic

### To Extend Functionality

1. Add HTTP API endpoints (see integration examples)
2. Add telemetry streaming (see integration examples)
3. Customize thresholds via settings system
4. Add custom warning types for your use case
5. Integrate with your UI system for in-game display

## Performance Optimization Tips

When warnings trigger, consider these optimizations:

**Chunk Generation Warnings:**
- Reduce chunk batch size
- Simplify generation algorithms
- Cache noise calculations
- Use lookup tables

**Collision Generation Warnings:**
- Reduce collision mesh resolution
- Use simpler collision shapes
- Defer collision generation
- Skip collision for distant chunks

**Frame Time Warnings:**
- Enable PerformanceOptimizer auto-quality
- Reduce view distance
- Implement LOD system
- Use occlusion culling

**Memory Warnings:**
- Unload distant chunks
- Compress chunk data
- Use lower LOD for distant chunks
- Free temporary buffers

**Chunk Count Warnings:**
- Reduce view distance
- Increase chunk size
- Implement better culling
- Use async chunk loading

## Support

For questions or issues:
1. Check the full documentation: `docs/voxel_performance_monitor.md`
2. Check the quick reference: `docs/voxel_performance_quick_reference.md`
3. Check the integration examples: `examples/voxel_performance_integration.gd`
4. Review the unit tests for usage patterns: `tests/unit/test_voxel_performance_monitor.gd`

## License

Part of the SpaceTime VR project. See project LICENSE for details.
