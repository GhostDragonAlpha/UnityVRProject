# VR Performance Profiling Guide

## Overview

The VRPerformanceProfiler provides comprehensive real-time performance monitoring for VR applications, measuring frame times, FPS, draw calls, physics, memory usage, and more. It identifies bottlenecks and provides optimization recommendations.

**Target Performance**: 90 FPS minimum for VR (11.11 ms per frame)

## System Architecture

### VRPerformanceProfiler (`vr_performance_profiler.gd`)

An autoload singleton that continuously monitors:
- Frame time breakdown (CPU vs GPU)
- FPS tracking (current, min, max, average)
- Rendering metrics (draw calls, triangles, objects)
- Physics performance (bodies, collision checks)
- Memory usage (static, dynamic, video)
- Voxel terrain performance (chunks, mesh generation)
- Creature AI performance
- Garbage collection pauses

**Location**: `C:/godot/scripts/tools/vr_performance_profiler.gd`

**Autoload**: Already configured in `project.godot`

## Setup and Initialization

### Automatic Initialization

The profiler automatically initializes on scene load:

```gdscript
# In _ready():
start_profiling()  # Automatically called
```

### Manual Control

Control profiling from code:

```gdscript
# Start profiling
VRPerformanceProfiler.start_profiling()

# Stop profiling
VRPerformanceProfiler.stop_profiling()

# Reset all statistics
VRPerformanceProfiler.reset_stats()
```

### Scene Requirements

The profiler automatically finds these systems in the scene tree:

```
/root/VRMain/
  XROrigin3D/
    XRCamera3D           # VR camera (detected automatically)

VoxelTerrain            # Voxel terrain system
VoxelTerrainOptimizer   # Voxel optimization
CreatureSystem          # AI creatures
```

If systems aren't found, profiling continues but some metrics will be unavailable.

## Usage

### Getting Performance Summary

Get comprehensive performance metrics:

```gdscript
# Get all performance data as Dictionary
var summary = VRPerformanceProfiler.get_performance_summary()

# Access specific metrics
var fps = summary.fps.current
var draw_calls = summary.rendering.draw_calls
var memory_mb = summary.memory.total_mb
```

### Summary Structure

```
{
  "fps": {
    "current": 88.5,
    "average": 87.2,
    "min": 72.0,
    "max": 90.0,
    "target": 90.0,
    "target_met": true
  },
  "frame_time": {
    "current_ms": 11.35,
    "average_ms": 11.49,
    "target_ms": 11.11,
    "cpu_ms": 8.2,
    "gpu_ms": 3.15
  },
  "rendering": {
    "draw_calls": 1847,
    "triangles": 425000,
    "vertices": 1275000,
    "objects": 342,
    "batches": 124
  },
  "voxel_terrain": {
    "chunks_rendered": 64,
    "chunks_culled": 128,
    "meshes_generated": 12,
    "mesh_gen_time_ms": 1.45,
    "section_time_ms": 0.89
  },
  "creature_ai": {
    "creatures_active": 24,
    "ai_updates": 24,
    "ai_time_ms": 0.67,
    "section_time_ms": 0.72
  },
  "physics": {
    "active_bodies": 234,
    "collision_checks": 1024,
    "physics_time_ms": 1.82,
    "section_time_ms": 1.90
  },
  "memory": {
    "static_mb": 256.4,
    "dynamic_mb": 512.8,
    "video_mb": 1834.6,
    "total_mb": 2603.8
  },
  "gc": {
    "pauses_detected": 3,
    "last_pause_ms": 2.14
  },
  "profiling": {
    "frame_count": 5400,
    "duration_sec": 60.0
  }
}
```

### Performance Analysis

Get bottleneck analysis with recommendations:

```gdscript
# Get top bottlenecks sorted by impact
var bottlenecks = VRPerformanceProfiler.get_bottleneck_analysis()

for bottleneck in bottlenecks:
    print("Issue: ", bottleneck.category, " - ", bottleneck.issue)
    print("Severity: ", ["OK", "LOW", "MEDIUM", "HIGH"][bottleneck.severity])
    print("Current: ", bottleneck.current, " Target: ", bottleneck.target)
    print("Impact: %.2f ms" % bottleneck.impact_ms)

    for recommendation in bottleneck.recommendations:
        print("  - ", recommendation)
```

### Print Performance Report

Print comprehensive report to console:

```gdscript
VRPerformanceProfiler.print_performance_report()
```

Output:
```
================================================================================
VR PERFORMANCE PROFILING REPORT
================================================================================

--- FPS METRICS ---
  Current FPS: 88.5 (Target: 90.0)
  Average FPS: 87.2
  Min FPS: 72.0
  Max FPS: 90.0
  Target Met: NO

--- FRAME TIME ---
  Current: 11.35 ms
  Average: 11.49 ms
  Target: 11.11 ms
  Budget Remaining: -0.24 ms

--- RENDERING ---
  Draw Calls: 1847
  Triangles: 425000
  Objects: 342

[... more sections ...]

--- TOP BOTTLENECKS ---
  1. Rendering: High draw calls
     Severity: MEDIUM
     Current: 1847 | Target: 1000
     Est. Impact: 4.23 ms
     Recommendations:
       - Enable mesh batching in voxel terrain
       - Use GPU instancing for repeated objects
       - Merge nearby voxel chunks
       - Reduce material count

[... more bottlenecks ...]
```

### Export Report as JSON

Export profiling data for analysis:

```gdscript
VRPerformanceProfiler.export_report_json("user://performance_report.json")
```

Generated JSON:
```json
{
  "timestamp": "2024-01-03T14:35:42",
  "summary": { /* ... summary data ... */ },
  "bottlenecks": [ /* ... bottleneck recommendations ... */ ]
}
```

## Performance Thresholds

### Warning Levels

The profiler emits warnings when metrics exceed thresholds:

| Metric | Warning Threshold | Severity |
|--------|-------------------|----------|
| FPS below target | < 85.5 FPS (95% of 90) | Level 1 |
| Frame time above target | > 12.22 ms (110% of 11.11) | Level 1 |
| Draw calls | > 2000 | Level 2 |
| Triangle count | > 500000 | Level 2 |
| Video memory | > 2000 MB | Level 2 |
| Physics bodies | > 1000 | Level 2 |
| Active creatures | > 100 | Level 2 |

### Bottleneck Severity Levels

| Level | Color | Action Required |
|-------|-------|-----------------|
| 0 - OK | Green | No action |
| 1 - LOW | Yellow | Monitor |
| 2 - MEDIUM | Orange | Optimize soon |
| 3 - HIGH | Red | Optimize immediately |

## Performance Monitoring

### Signal Connections

Connect to profiler signals for real-time alerts:

```gdscript
# Connect to FPS drop warning
VRPerformanceProfiler.fps_drop_detected.connect(_on_fps_drop)
VRPerformanceProfiler.frame_spike_detected.connect(_on_frame_spike)
VRPerformanceProfiler.performance_warning.connect(_on_warning)

func _on_fps_drop(fps: float):
    print("FPS dropped to: ", fps)
    # Trigger dynamic quality reduction

func _on_frame_spike(frame_time_ms: float):
    print("Frame spike: ", frame_time_ms, " ms")
    # Log GC pause or investigate bottleneck

func _on_warning(message: String, severity: int):
    print("Performance warning (%d): %s" % [severity, message])
    # Update UI indicator
```

### Continuous Monitoring

Monitor performance in a custom script:

```gdscript
extends Node

func _process(_delta):
    var summary = VRPerformanceProfiler.get_performance_summary()

    # Update HUD
    update_fps_display(summary.fps.current)
    update_frame_time_display(summary.frame_time.current_ms)

    # Dynamic quality scaling
    if summary.fps.current < 80:
        reduce_quality()
    elif summary.fps.current > 90:
        increase_quality()

func update_fps_display(fps: float):
    # Update in-game HUD
    pass

func reduce_quality():
    # Lower LOD, reduce draw distance, etc.
    pass

func increase_quality():
    # Increase LOD, increase draw distance, etc.
    pass
```

## Profiling Sections

### Frame Time Breakdown

Frame time is split into profiling sections:

```gdscript
section_times = {
    "voxel_terrain": 0.89,      # Voxel chunk updates
    "creature_ai": 0.72,        # Creature AI thinking
    "physics": 1.90,            # Physics simulation
    "rendering": 3.45,          # Draw call submission
    "scripting": 0.12,          # GDScript execution
    "ui": 0.23,                 # UI updates
    "audio": 0.08               # Audio processing
}
```

Each section time is measured in milliseconds. Use to identify which subsystem is the bottleneck:

```gdscript
var summary = VRPerformanceProfiler.get_performance_summary()

# Find slowest section
var slowest_section = ""
var slowest_time = 0.0
for section_name in summary.keys():
    if "section_time_ms" in section_name:
        var time = summary[section_name]["section_time_ms"]
        if time > slowest_time:
            slowest_time = time
            slowest_section = section_name

print("Slowest section: %s (%.2f ms)" % [slowest_section, slowest_time])
```

## Examples

### Example 1: Detect Performance Issues

```gdscript
func check_performance_health() -> bool:
    var summary = VRPerformanceProfiler.get_performance_summary()
    var bottlenecks = VRPerformanceProfiler.get_bottleneck_analysis()

    # Check FPS target
    if not summary.fps.target_met:
        print("WARNING: FPS below target (", summary.fps.current, "/90)")
        return false

    # Check for high-impact bottlenecks
    for bottleneck in bottlenecks:
        if bottleneck.severity == 3:  # High severity
            print("CRITICAL: ", bottleneck.issue, " (", bottleneck.impact_ms, " ms impact)")
            return false

    return true
```

### Example 2: Log Performance Metrics

```gdscript
func log_performance_snapshot():
    var summary = VRPerformanceProfiler.get_performance_summary()

    var log = {
        "timestamp": Time.get_datetime_string_from_system(),
        "fps": summary.fps.current,
        "frame_time_ms": summary.frame_time.current_ms,
        "draw_calls": summary.rendering.draw_calls,
        "memory_mb": summary.memory.total_mb,
        "gc_pauses": summary.gc.pauses_detected
    }

    # Send to telemetry server
    TelemetryServer.log_metric("vr_performance", log)

    # Or save to file
    var file = FileAccess.open("user://perf_log.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(log))
```

### Example 3: Dynamic Quality Adjustment

```gdscript
class_name PerformanceScaler
extends Node

var min_quality = 0.5
var max_quality = 1.0
var current_quality = 1.0

func _process(_delta):
    var summary = VRPerformanceProfiler.get_performance_summary()

    # Too slow - reduce quality
    if summary.fps.current < 85 and current_quality > min_quality:
        current_quality -= 0.1
        apply_quality_level(current_quality)
        print("Quality reduced to: ", current_quality)

    # Good performance - increase quality
    elif summary.fps.current > 89 and current_quality < max_quality:
        current_quality += 0.05
        apply_quality_level(current_quality)
        print("Quality increased to: ", current_quality)

func apply_quality_level(quality: float):
    # Update voxel LOD
    if VRPerformanceProfiler.voxel_optimizer:
        var lod_distance = lerp(50.0, 200.0, quality)
        VRPerformanceProfiler.voxel_optimizer.set_lod_distance(lod_distance)

    # Update draw distance
    var environment = get_viewport().world_environment.environment
    environment.far_plane = lerp(1000.0, 10000.0, quality)
```

### Example 4: Performance-Based Alerts

```gdscript
func setup_performance_alerts():
    VRPerformanceProfiler.performance_warning.connect(_on_perf_warning)
    VRPerformanceProfiler.fps_drop_detected.connect(_on_fps_drop)
    VRPerformanceProfiler.frame_spike_detected.connect(_on_frame_spike)

func _on_perf_warning(message: String, severity: int):
    var levels = ["OK", "LOW", "MEDIUM", "HIGH"]

    # Log to telemetry
    TelemetryServer.log_warning("vr_performance", {
        "severity": levels[severity],
        "message": message,
        "timestamp": Time.get_ticks_msec()
    })

    # Show UI warning if high severity
    if severity >= 2:
        show_performance_warning(message, severity)

func show_performance_warning(message: String, severity: int):
    # Update UI label or show overlay
    var warning_label = get_node("WarningLabel")
    warning_label.text = message
    warning_label.modulate.h = 0.0 if severity >= 3 else 30.0  # Red for critical
```

## Troubleshooting

### Issue: Profiler Shows 0 FPS
**Cause**: Profiler not running or initialized
**Solution**:
```gdscript
# Verify profiling is active
print("Profiling: ", VRPerformanceProfiler.is_profiling)

# Start manually
VRPerformanceProfiler.start_profiling()
```

### Issue: Draw Calls Always 0
**Cause**: System not found in scene tree
**Solution**:
```gdscript
# Check which systems were found
print("Rendering stats available: ", VRPerformanceProfiler.draw_calls > 0)

# Verify scene structure matches expectations
var camera = get_node_or_null("/root/VRMain/XROrigin3D/XRCamera3D")
print("Camera found: ", camera != null)
```

### Issue: Memory Numbers Seem Wrong
**Cause**: Engine reporting memory in bytes, profiler converts to MB
**Solution**:
```gdscript
# Verify math
var raw_bytes = Performance.get_monitor(Performance.MEMORY_STATIC)
var converted_mb = raw_bytes / 1024.0 / 1024.0
print("Raw: ", raw_bytes, " bytes = ", converted_mb, " MB")
```

### Issue: Voxel Terrain Metrics Missing
**Cause**: Voxel terrain system not found
**Solution**:
```gdscript
# Verify voxel terrain exists
var voxel_terrain = VRPerformanceProfiler.voxel_terrain
print("Voxel terrain found: ", voxel_terrain != null)

# If missing, manually set reference
if voxel_terrain == null:
    var found_voxel = get_tree().root.find_child("VoxelTerrain", true, false)
    if found_voxel:
        VRPerformanceProfiler.voxel_terrain = found_voxel
```

## Best Practices

1. **Monitor regularly during development**:
```gdscript
# Print report every 60 frames
var frame_counter = 0
func _process(_delta):
    frame_counter += 1
    if frame_counter >= 60:
        VRPerformanceProfiler.print_performance_report()
        frame_counter = 0
```

2. **Track performance over time**:
```gdscript
# Export report periodically for trend analysis
var export_interval = 300  # Every 5 minutes
var export_counter = 0

func _process(_delta):
    export_counter += 1
    if export_counter >= export_interval:
        var timestamp = Time.get_datetime_dict_from_system()
        var filename = "user://perf_report_%04d%02d%02d_%02d%02d%02d.json" % \
            [timestamp.year, timestamp.month, timestamp.day, timestamp.hour, timestamp.minute, timestamp.second]
        VRPerformanceProfiler.export_report_json(filename)
        export_counter = 0
```

3. **Implement quality scaling based on performance**:
- Monitor FPS trend (not just current frame)
- Use hysteresis to avoid rapid quality changes
- Save quality preference for next session

4. **Profile different scenes**:
- Measure performance in different environments
- Identify scene-specific bottlenecks
- Optimize highest-impact scenes first

## Performance Targets

| Metric | Target | Minimum |
|--------|--------|---------|
| FPS | 90 | 72 (80% of target) |
| Frame Time | 11.11 ms | 13.88 ms |
| Draw Calls | <1500 | <2500 |
| Triangles | <300k | <500k |
| Physics Bodies | <500 | <1000 |
| Creatures | <50 | <100 |
| Video Memory | <1500 MB | <2000 MB |

## Related Documentation

- **VR_OPTIMIZATION.md** - Detailed optimization techniques
- **PERFORMANCE_PROFILING_ADVANCED.md** - Advanced profiling features
- **TESTING_GUIDE.md** - Performance testing procedures

## Support

For profiling issues:
1. Check console output for initialization messages
2. Verify scene structure matches expectations
3. Export JSON report for detailed analysis
4. Check related system scripts for proper integration
