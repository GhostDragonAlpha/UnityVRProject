# VoxelPerformanceMonitor - Quick Start Guide

## ✅ Installation Complete

The VoxelPerformanceMonitor is **already installed and configured** as an autoload in your project. No setup required!

## 🚀 Use in 3 Lines of Code

### Option 1: Enable Debug UI (Easiest)
```gdscript
# In your main scene _ready() function:
func _ready():
    VoxelPerformanceMonitor.set_debug_ui_enabled(true)
```
**That's it!** You'll see real-time performance stats in the top-right corner.

### Option 2: Connect to godot_voxel Addon
```gdscript
# If using Zylann's voxel addon:
func _ready():
    VoxelPerformanceMonitor.set_voxel_terrain($VoxelTerrain)
    VoxelPerformanceMonitor.set_debug_ui_enabled(true)
```
**Done!** The monitor automatically tracks all voxel operations.

### Option 3: Instrument Custom Voxel Code
```gdscript
# In your chunk generation code:
func generate_chunk(position: Vector3i):
    VoxelPerformanceMonitor.start_chunk_generation()
    # ... your chunk generation code ...
    VoxelPerformanceMonitor.end_chunk_generation()
    VoxelPerformanceMonitor.increment_chunk_count()
```

## 📊 What You Get

### Real-Time Monitoring
- **Frame time tracking** - Physics and render frames vs 11.11ms budget (90 FPS)
- **Chunk generation time** - Average and max generation times
- **Collision generation time** - Average and max collision mesh times
- **Active chunk count** - Current chunks loaded
- **Memory usage** - Voxel system memory consumption

### Automatic Warnings
When performance drops below 90 FPS target:
```gdscript
# Connect to warnings:
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, value, threshold):
        print("Performance warning: %s = %.2f ms (threshold: %.2f ms)" % [type, value, threshold])
)
```

Warning types you'll see:
- `render_frame` - Render frame time > 11ms
- `physics_frame` - Physics frame time > 11ms
- `chunk_generation` - Chunk generation > 5ms
- `collision_generation` - Collision generation > 3ms
- `chunk_count` - Active chunks > 512
- `memory` - Memory usage > 2048 MB

## 🎯 Common Usage Patterns

### Development: Enable Debug UI
```gdscript
func _ready():
    # Show stats overlay during development
    if OS.is_debug_build():
        VoxelPerformanceMonitor.set_debug_ui_enabled(true)
```

### Production: Respond to Warnings
```gdscript
func _ready():
    VoxelPerformanceMonitor.performance_warning.connect(_on_perf_warning)

func _on_perf_warning(type: String, value: float, threshold: float):
    match type:
        "render_frame":
            # Enable quality reduction
            ResonanceEngine.performance_optimizer.set_auto_quality_enabled(true)
        "chunk_count":
            # Reduce view distance
            voxel_terrain.view_distance -= 16
        "memory":
            # Unload distant chunks
            unload_far_chunks()
```

### Profiling: Get Statistics
```gdscript
func _on_profile_button_pressed():
    var stats = VoxelPerformanceMonitor.get_statistics()
    print("Active chunks: %d" % stats.active_chunk_count)
    print("Avg chunk gen: %.2f ms" % stats.chunk_generation_avg_ms)
    print("Physics frame: %.2f ms" % stats.physics_frame_time_ms)

    # Or get formatted report:
    print(VoxelPerformanceMonitor.get_performance_report())
```

## 📖 More Information

- **Full Documentation**: `docs/voxel_performance_monitor.md`
- **Quick Reference**: `docs/voxel_performance_quick_reference.md`
- **Integration Examples**: `examples/voxel_performance_integration.gd`
- **Unit Tests**: `tests/unit/test_voxel_performance_monitor.gd`
- **Project README**: `VOXEL_PERFORMANCE_MONITOR_README.md`

## 🎮 VR Performance Targets

The monitor enforces these thresholds for **90 FPS VR**:

| Metric | Budget | Why |
|--------|--------|-----|
| Frame Time | 11.11 ms | 1000ms / 90fps = 11.11ms per frame |
| Chunk Gen | 5 ms | Max time per single chunk |
| Collision Gen | 3 ms | Max time per collision mesh |
| Active Chunks | 512 | Balance memory vs performance |
| Memory | 2048 MB | System limit for voxel data |

## ⚡ Performance Impact

- **Overhead**: < 0.1ms per frame
- **Memory**: ~50 KB for sample buffers
- **No GC pressure**: All buffers pre-allocated

## 🔧 Troubleshooting

### "VoxelPerformanceMonitor not found"
The monitor is an autoload. Access it directly:
```gdscript
VoxelPerformanceMonitor.get_statistics()
# NOT: var monitor = VoxelPerformanceMonitor.new()
```

### Debug UI not showing
```gdscript
# Ensure it's enabled:
VoxelPerformanceMonitor.set_debug_ui_enabled(true)

# Check if monitoring is active:
print(VoxelPerformanceMonitor.is_monitoring_enabled())
```

### No warnings firing
```gdscript
# Connect to signal to see warnings:
VoxelPerformanceMonitor.performance_warning.connect(
    func(type, val, thresh):
        push_warning("Voxel: %s = %.2f (threshold: %.2f)" % [type, val, thresh])
)
```

## 🎉 You're Ready!

The VoxelPerformanceMonitor is **installed and ready to use**. Just add one line to enable the debug UI and start monitoring your voxel terrain performance.

**Recommended first step:**
```gdscript
# Add to your main scene:
func _ready():
    VoxelPerformanceMonitor.set_debug_ui_enabled(true)
```

Run your project and watch the real-time stats in the top-right corner!
