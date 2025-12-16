# VR Performance Monitoring Guide

**Created:** 2025-12-09
**Status:** Production Ready
**Related Phase:** VR Locomotion Phase 7 (Performance Monitoring)

## Overview

The VR Performance Monitoring system provides real-time performance tracking specifically designed for VR applications targeting 90 FPS. It monitors frame times, detects performance issues, tracks dropped frames, and integrates with the existing VoxelPerformanceMonitor to provide comprehensive performance insights.

## Key Features

- **90 FPS Tracking**: Rolling average over 90 samples (1 second at 90 FPS)
- **FPS Warning System**: Alerts when FPS drops below 88 FPS
- **Dropped Frame Detection**: Tracks frames that exceed 2x frame budget
- **VR-Specific Metrics**: Monitors reprojection events and VR runtime performance
- **Voxel Integration**: Connects to VoxelPerformanceMonitor to track chunk generation impact
- **Console Reporting**: Optional periodic performance reports
- **Signal-based Alerts**: React to performance changes in your code

## Quick Start

### Basic Setup

Add the VR performance monitor to your VR scene:

```gdscript
extends Node3D

var vr_perf_monitor: Node = null

func _ready() -> void:
    # Load and instantiate monitor
    var VRMonitorScript = load("res://scripts/vr/vr_performance_monitor.gd")
    vr_perf_monitor = VRMonitorScript.new()
    vr_perf_monitor.name = "VRPerformanceMonitor"
    add_child(vr_perf_monitor)

    # Enable console reporting (optional)
    vr_perf_monitor.set_console_reporting_enabled(true, 5.0)  # Every 5 seconds

    print("VR performance monitoring active")
```

### Check Performance

```gdscript
# Check if meeting 90 FPS target
if vr_perf_monitor.check_vr_performance():
    print("Performance is good!")
else:
    print("Performance is below target")

# Get current FPS
var current_fps = vr_perf_monitor.get_average_fps()
print("Current FPS: %.1f" % current_fps)

# Get frame time
var frame_time = vr_perf_monitor.get_frame_time_ms()
print("Frame time: %.2f ms" % frame_time)
```

## Performance Targets

| Metric | Target | Warning Threshold |
|--------|--------|-------------------|
| Frame Rate | 90 FPS | < 88 FPS |
| Frame Time | 11.11 ms | > 10.0 ms (90% of budget) |
| Dropped Frames | 0 | > 22.22 ms (2x budget) |
| Reprojection Rate | 0% | > 5% |

## Signals

Connect to signals to respond to performance changes:

```gdscript
func _ready() -> void:
    vr_perf_monitor.performance_warning.connect(_on_performance_warning)
    vr_perf_monitor.performance_recovered.connect(_on_performance_recovered)
    vr_perf_monitor.frame_dropped.connect(_on_frame_dropped)
    vr_perf_monitor.reprojection_detected.connect(_on_reprojection_detected)

func _on_performance_warning(warning_type: String, current_fps: float, target_fps: float) -> void:
    print("Warning: %s - Current: %.1f FPS, Target: %.1f FPS" % [
        warning_type, current_fps, target_fps
    ])
    # Take action: reduce quality, disable effects, etc.

func _on_performance_recovered() -> void:
    print("Performance recovered to acceptable levels")

func _on_frame_dropped(consecutive_drops: int) -> void:
    print("Frame dropped! Consecutive: %d" % consecutive_drops)

func _on_reprojection_detected(reprojection_rate: float) -> void:
    print("Reprojection detected: %.1f%%" % reprojection_rate)
```

## Statistics API

Get comprehensive performance statistics:

```gdscript
var stats = vr_perf_monitor.get_statistics()

# FPS metrics
print("Current FPS: %.1f" % stats.current_fps)
print("Meeting target: %s" % stats.is_meeting_target)

# Frame time metrics
print("Average frame time: %.2f ms" % stats.average_frame_time_ms)
print("Max frame time: %.2f ms" % stats.max_frame_time_ms)
print("Min frame time: %.2f ms" % stats.min_frame_time_ms)

# Dropped frames
print("Total dropped: %d" % stats.total_dropped_frames)
print("Consecutive: %d" % stats.consecutive_dropped_frames)

# VR-specific
if stats.xr_interface_active:
    print("XR Interface: %s" % stats.xr_interface_name)
    print("Reprojection events: %d" % stats.reprojection_events)
    print("Reprojection rate: %.1f%%" % stats.estimated_reprojection_rate)

# Voxel integration (if VoxelPerformanceMonitor available)
if stats.voxel_monitor_connected:
    print("Chunk generation: %.2f ms" % stats.voxel_chunk_generation_avg_ms)
    print("Active chunks: %d" % stats.voxel_active_chunks)
```

## Performance Reports

Generate formatted performance reports:

```gdscript
# Get formatted report string
var report = vr_perf_monitor.get_performance_report()
print(report)

# Print report directly
vr_perf_monitor.print_current_stats()
```

Example report output:

```
=== VR Performance Report ===

--- FPS Status ---
Target: 90.0 FPS (11.11 ms budget)
Current: 89.5 FPS (11.17 ms average)
Status: [OK] GOOD

--- Frame Time ---
Average: 11.17 ms
Min: 10.23 ms
Max: 12.45 ms

--- Dropped Frames ---
Total: 0
Consecutive: 0

--- VR Metrics ---
XR Interface: OpenXR
Reprojection Events: 2
Estimated Reprojection Rate: 2.2%

--- Voxel Terrain Impact ---
Chunk Generation: 3.2 ms (avg)
Collision Generation: 1.8 ms (avg)
Active Chunks: 128

--- Session ---
Uptime: 45.2 seconds
Samples: 90 / 90
```

## Console Reporting

Enable automatic periodic reporting to console:

```gdscript
# Enable with 5 second interval
vr_perf_monitor.set_console_reporting_enabled(true, 5.0)

# Disable
vr_perf_monitor.set_console_reporting_enabled(false)
```

## Integration with VoxelPerformanceMonitor

The VR performance monitor automatically attempts to connect to the VoxelPerformanceMonitor autoload:

```gdscript
# Check if connected
var voxel_monitor = vr_perf_monitor.get_voxel_monitor()
if voxel_monitor:
    print("Connected to VoxelPerformanceMonitor")

    # Voxel statistics will be included in get_statistics()
    var stats = vr_perf_monitor.get_statistics()
    if stats.voxel_monitor_connected:
        print("Chunk generation: %.2f ms" % stats.voxel_chunk_generation_avg_ms)
```

When connected, the VR monitor will:
- Track chunk generation impact on frame times
- Include voxel metrics in statistics
- Respond to voxel performance warnings
- Display voxel data in performance reports

## Automatic Quality Adjustment Example

See `scripts/vr/vr_performance_example.gd` for a complete example with automatic quality adjustment:

```gdscript
func _on_performance_warning(warning_type: String, current_fps: float, target_fps: float) -> void:
    # Automatically reduce quality when performance drops
    if can_adjust_quality and current_quality_level > 0:
        _reduce_quality()

func _reduce_quality() -> void:
    current_quality_level -= 1

    match current_quality_level:
        0:  # Low
            viewport.msaa_3d = Viewport.MSAA_DISABLED
        1:  # Medium
            viewport.msaa_3d = Viewport.MSAA_2X
        2:  # High
            viewport.msaa_3d = Viewport.MSAA_4X
```

## Best Practices

### 1. Add to VR Root Node

Add the monitor as a child of your XROrigin3D or main VR node:

```gdscript
# In your VR scene root script
func _ready() -> void:
    var monitor = load("res://scripts/vr/vr_performance_monitor.gd").new()
    add_child(monitor)
```

### 2. Don't Make it an Autoload

VRPerformanceMonitor is designed to be manually instantiated in VR scenes, not as an autoload. This allows:
- Multiple VR scenes with independent monitoring
- Easy cleanup when switching between VR and non-VR modes
- Scene-specific performance tuning

### 3. React to Warnings

Always connect to `performance_warning` signal and take action:

```gdscript
func _on_performance_warning(warning_type, current_fps, target_fps):
    # Reduce quality
    # Disable expensive effects
    # Lower voxel terrain detail
    # Reduce particle counts
```

### 4. Implement Quality Cooldown

Prevent rapid quality oscillation:

```gdscript
var quality_cooldown_sec: float = 10.0
var last_quality_change: float = 0.0

func can_change_quality() -> bool:
    var time_elapsed = (Time.get_ticks_msec() / 1000.0) - last_quality_change
    return time_elapsed >= quality_cooldown_sec
```

### 5. Monitor Voxel Impact

If using voxel terrain, track its performance impact:

```gdscript
var stats = vr_perf_monitor.get_statistics()
if stats.voxel_monitor_connected:
    if stats.voxel_chunk_generation_avg_ms > 5.0:
        # Chunk generation is expensive
        # Consider reducing LOD or chunk load rate
```

### 6. Use Statistics for Telemetry

Send performance data to analytics or monitoring systems:

```gdscript
func _on_statistics_updated() -> void:
    var stats = vr_perf_monitor.get_statistics()

    # Send to analytics
    Analytics.record_performance({
        "fps": stats.current_fps,
        "frame_time_ms": stats.average_frame_time_ms,
        "dropped_frames": stats.total_dropped_frames,
        "meeting_target": stats.is_meeting_target
    })
```

## Testing

Unit tests are available at `tests/unit/test_vr_performance_monitor.gd`:

```bash
# Run tests via GdUnit4 panel in Godot editor
# Or via command line:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_vr_performance_monitor.gd
```

Tests cover:
- Initialization and constants
- FPS tracking and rolling averages
- Dropped frame detection
- Performance threshold warnings
- Statistics API
- Signal emissions
- Integration with VoxelPerformanceMonitor

## API Reference

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TARGET_FPS` | 90.0 | Target frame rate for VR |
| `FRAME_TIME_BUDGET_MS` | 11.11 | Frame time budget in milliseconds |
| `FPS_WARNING_THRESHOLD` | 88.0 | Minimum acceptable FPS |
| `SAMPLE_SIZE` | 90 | Number of samples in rolling average |
| `DROPPED_FRAME_THRESHOLD_MS` | 22.22 | Threshold for dropped frame (2x budget) |

### Methods

#### Performance Checking

```gdscript
get_average_fps() -> float
```
Returns current rolling average FPS.

```gdscript
get_frame_time_ms() -> float
```
Returns current average frame time in milliseconds.

```gdscript
check_vr_performance() -> bool
```
Returns true if meeting 90 FPS target (>= 88 FPS).

#### Statistics

```gdscript
get_statistics() -> Dictionary
```
Returns comprehensive performance statistics dictionary.

```gdscript
get_performance_report() -> String
```
Returns formatted performance report string.

```gdscript
print_current_stats() -> void
```
Prints performance report to console.

#### Console Reporting

```gdscript
set_console_reporting_enabled(enabled: bool, interval_sec: float = 5.0) -> void
```
Enables or disables periodic console reporting.

#### Control

```gdscript
reset_statistics() -> void
```
Resets all statistics and counters.

```gdscript
get_voxel_monitor() -> Node
```
Returns reference to VoxelPerformanceMonitor if connected, null otherwise.

### Signals

```gdscript
signal performance_warning(warning_type: String, current_fps: float, target_fps: float)
```
Emitted when FPS drops below 88 FPS threshold.

```gdscript
signal performance_recovered()
```
Emitted when performance recovers to acceptable levels.

```gdscript
signal frame_dropped(consecutive_drops: int)
```
Emitted when a frame is dropped (exceeds 2x budget).

```gdscript
signal reprojection_detected(reprojection_rate: float)
```
Emitted when VR reprojection is detected.

## Troubleshooting

### Monitor Not Tracking Performance

**Problem:** FPS always shows 90.0
**Solution:** Ensure monitor is added to scene tree and _ready() has been called

### Statistics Always Empty

**Problem:** `get_statistics()` returns empty dictionary
**Solution:** Wait at least one frame after initialization for samples to collect

### No Voxel Integration

**Problem:** Voxel statistics not appearing
**Solution:** Ensure VoxelPerformanceMonitor is registered as an autoload in project.godot

### Warnings Not Triggering

**Problem:** Performance warning signal not emitting
**Solution:** Monitor requires 10 consecutive low FPS frames to trigger warning (prevents false positives)

## Performance Impact

The VRPerformanceMonitor itself has minimal performance impact:

- **Memory**: ~2KB (90 samples × 8 bytes per float × 2 arrays)
- **CPU**: < 0.1ms per frame
- **Process overhead**: Negligible (simple arithmetic operations)

The monitor is designed to have minimal impact on the very performance it's measuring.

## Related Documentation

- [VoxelPerformanceMonitor](../../scripts/core/voxel_performance_monitor.gd)
- [VR Performance Example](../../scripts/vr/vr_performance_example.gd)
- [Development Workflow Guide](DEVELOPMENT_WORKFLOW.md)
- [Production Readiness Checklist](../../PRODUCTION_READINESS_CHECKLIST.md)

## Future Enhancements

Potential improvements for future versions:

1. **GPU Performance Tracking**: Monitor GPU frame time separately from CPU
2. **Historical Trending**: Track performance trends over time
3. **Automatic LOD Adjustment**: Integration with LOD system for automatic quality scaling
4. **Network Metrics**: Track network latency impact on frame times
5. **Audio Performance**: Monitor audio processing impact
6. **Extended VR Metrics**: Direct integration with XR runtime performance APIs
7. **Performance Profiles**: Save/load performance profiles for different quality settings

## Version History

- **v1.0** (2025-12-09): Initial implementation
  - 90 FPS tracking with rolling average
  - Dropped frame detection
  - VR-specific metrics
  - VoxelPerformanceMonitor integration
  - Console reporting
  - Comprehensive test suite
