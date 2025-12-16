extends Node

## Performance Optimization System (Core)
## Monitors frame time, optimizes rendering, and maintains 90 FPS target
## Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 50.4

signal performance_degraded(fps: float, frame_time_ms: float)
signal performance_improved(fps: float, frame_time_ms: float)
signal quality_adjusted(new_quality: int)

## Performance targets
const TARGET_FPS: float = 90.0
const TARGET_FRAME_TIME_MS: float = 1000.0 / TARGET_FPS  # 11.11ms
const CRITICAL_FPS: float = 60.0
const EXCELLENT_FPS: float = 120.0

## Quality levels
enum QualityLevel {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
	ULTRA = 3
}

## Frame time tracking
var frame_times: Array[float] = []
var frame_times_capacity: int = 120  # 120 frames = ~1-2 seconds at 90 FPS

## Performance metrics
var current_fps: float = 60.0
var average_frame_time_ms: float = 16.67
var frame_count: int = 0
var total_time: float = 0.0

## Current quality level
var current_quality: QualityLevel = QualityLevel.HIGH

## Auto-adjustment settings
var auto_adjust_quality: bool = true
var adjustment_cooldown: float = 5.0  # Seconds before next adjustment
var last_adjustment_time: float = 0.0

## Performance monitoring
var monitoring_enabled: bool = true


func _ready() -> void:
	set_process(true)
	print("PerformanceOptimizer: Initialized with target %d FPS" % TARGET_FPS)


func _process(delta: float) -> void:
	if not monitoring_enabled:
		return

	# Track frame time
	_track_frame_time(delta)

	# Update metrics every second
	total_time += delta
	if total_time >= 1.0:
		_update_metrics()
		_check_performance()
		total_time = 0.0


## Track individual frame time
func _track_frame_time(delta: float) -> void:
	var frame_time_ms = delta * 1000.0
	frame_times.append(frame_time_ms)

	# Keep only recent frames
	if frame_times.size() > frame_times_capacity:
		frame_times.pop_front()

	frame_count += 1


## Update performance metrics
func _update_metrics() -> void:
	if frame_times.is_empty():
		return

	# Calculate average frame time
	var sum: float = 0.0
	for ft in frame_times:
		sum += ft
	average_frame_time_ms = sum / frame_times.size()

	# Calculate FPS
	if average_frame_time_ms > 0.0:
		current_fps = 1000.0 / average_frame_time_ms

	# Log metrics
	if Engine.get_frames_per_second() > 0:
		var engine_fps = Engine.get_frames_per_second()
		# Use more accurate measurement
		current_fps = (current_fps + engine_fps) / 2.0


## Check performance and trigger adjustments
func _check_performance() -> void:
	# Check if performance is degraded
	if current_fps < CRITICAL_FPS:
		performance_degraded.emit(current_fps, average_frame_time_ms)
		_try_auto_adjust_quality(false)  # Decrease quality

	# Check if performance is excellent
	elif current_fps > EXCELLENT_FPS:
		performance_improved.emit(current_fps, average_frame_time_ms)
		_try_auto_adjust_quality(true)  # Increase quality

	# Log performance status
	_log_performance_status()


## Try to automatically adjust quality
func _try_auto_adjust_quality(increase: bool) -> void:
	if not auto_adjust_quality:
		return

	# Check cooldown
	var time_since_last = Time.get_ticks_msec() / 1000.0 - last_adjustment_time
	if time_since_last < adjustment_cooldown:
		return

	# Adjust quality
	if increase and current_quality < QualityLevel.ULTRA:
		set_quality_level(current_quality + 1)
		last_adjustment_time = Time.get_ticks_msec() / 1000.0
	elif not increase and current_quality > QualityLevel.LOW:
		set_quality_level(current_quality - 1)
		last_adjustment_time = Time.get_ticks_msec() / 1000.0


## Set quality level and apply optimizations
## Requirement 50.4: Performance optimization
func set_quality_level(level: QualityLevel) -> void:
	current_quality = level

	print("PerformanceOptimizer: Setting quality to %s" % _quality_name(level))

	# Apply quality settings
	match level:
		QualityLevel.LOW:
			_apply_low_quality()
		QualityLevel.MEDIUM:
			_apply_medium_quality()
		QualityLevel.HIGH:
			_apply_high_quality()
		QualityLevel.ULTRA:
			_apply_ultra_quality()

	quality_adjusted.emit(level)


## Apply LOW quality settings
func _apply_low_quality() -> void:
	# Reduce shadow quality
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 2048)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 2048)

	# Disable SDFGI
	ProjectSettings.set_setting("rendering/global_illumination/sdfgi/enabled", false)

	# Reduce mesh LOD bias
	ProjectSettings.set_setting("rendering/mesh_lod/lod_change/threshold_pixels", 2.0)

	# Disable volumetric fog
	var env = get_viewport().world_3d.environment
	if env:
		env.volumetric_fog_enabled = false

	print("PerformanceOptimizer: LOW quality applied")


## Apply MEDIUM quality settings
func _apply_medium_quality() -> void:
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 4096)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 4096)

	ProjectSettings.set_setting("rendering/global_illumination/sdfgi/enabled", false)
	ProjectSettings.set_setting("rendering/mesh_lod/lod_change/threshold_pixels", 1.0)

	var env = get_viewport().world_3d.environment
	if env:
		env.volumetric_fog_enabled = false

	print("PerformanceOptimizer: MEDIUM quality applied")


## Apply HIGH quality settings
func _apply_high_quality() -> void:
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 8192)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 8192)

	ProjectSettings.set_setting("rendering/global_illumination/sdfgi/enabled", true)
	ProjectSettings.set_setting("rendering/mesh_lod/lod_change/threshold_pixels", 0.5)

	var env = get_viewport().world_3d.environment
	if env:
		env.volumetric_fog_enabled = true
		if env.has_method("set_volumetric_fog_density"):
			env.volumetric_fog_density = 0.01

	print("PerformanceOptimizer: HIGH quality applied")


## Apply ULTRA quality settings
func _apply_ultra_quality() -> void:
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 16384)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 16384)

	ProjectSettings.set_setting("rendering/global_illumination/sdfgi/enabled", true)
	ProjectSettings.set_setting("rendering/mesh_lod/lod_change/threshold_pixels", 0.25)

	var env = get_viewport().world_3d.environment
	if env:
		env.volumetric_fog_enabled = true
		if env.has_method("set_volumetric_fog_density"):
			env.volumetric_fog_density = 0.02

	print("PerformanceOptimizer: ULTRA quality applied")


## Get quality level name
func _quality_name(level: QualityLevel) -> String:
	match level:
		QualityLevel.LOW:
			return "LOW"
		QualityLevel.MEDIUM:
			return "MEDIUM"
		QualityLevel.HIGH:
			return "HIGH"
		QualityLevel.ULTRA:
			return "ULTRA"
	return "UNKNOWN"


## Log performance status
func _log_performance_status() -> void:
	var status = ""
	if current_fps >= TARGET_FPS:
		status = "EXCELLENT"
	elif current_fps >= CRITICAL_FPS:
		status = "GOOD"
	else:
		status = "DEGRADED"

	print("PerformanceOptimizer: FPS=%.1f (%.2fms) - %s [%s]" %
		[current_fps, average_frame_time_ms, status, _quality_name(current_quality)])


## Get current FPS
func get_fps() -> float:
	return current_fps


## Get average frame time in milliseconds
func get_frame_time_ms() -> float:
	return average_frame_time_ms


## Get current quality level
func get_quality_level() -> QualityLevel:
	return current_quality


## Enable/disable auto quality adjustment
func set_auto_adjust(enabled: bool) -> void:
	auto_adjust_quality = enabled
	print("PerformanceOptimizer: Auto-adjust %s" % ("enabled" if enabled else "disabled"))


## Enable/disable performance monitoring
func set_monitoring_enabled(enabled: bool) -> void:
	monitoring_enabled = enabled


## Get performance report
func get_performance_report() -> Dictionary:
	return {
		"fps": current_fps,
		"frame_time_ms": average_frame_time_ms,
		"quality_level": current_quality,
		"quality_name": _quality_name(current_quality),
		"target_fps": TARGET_FPS,
		"target_frame_time_ms": TARGET_FRAME_TIME_MS,
		"frame_count": frame_count,
		"auto_adjust_enabled": auto_adjust_quality,
		"status": "excellent" if current_fps >= TARGET_FPS else "good" if current_fps >= CRITICAL_FPS else "degraded"
	}


## Profile frame time over N frames
## Requirement 2.1, 2.2: Performance profiling
func profile_frames(num_frames: int = 1000) -> Dictionary:
	"""Profile frame time over specified number of frames."""
	print("PerformanceOptimizer: Profiling %d frames..." % num_frames)

	var profile_times: Array[float] = []
	var start_time = Time.get_ticks_msec()

	# Collect frame times
	for i in range(num_frames):
		var frame_start = Time.get_ticks_usec()
		await get_tree().process_frame
		var frame_end = Time.get_ticks_usec()

		var frame_time_ms = (frame_end - frame_start) / 1000.0
		profile_times.append(frame_time_ms)

	var end_time = Time.get_ticks_msec()
	var total_time_ms = end_time - start_time

	# Calculate statistics
	var min_time = profile_times.min()
	var max_time = profile_times.max()
	var sum_time = 0.0
	for t in profile_times:
		sum_time += t
	var avg_time = sum_time / profile_times.size()
	var avg_fps = 1000.0 / avg_time

	var report = {
		"num_frames": num_frames,
		"total_time_ms": total_time_ms,
		"min_frame_time_ms": min_time,
		"max_frame_time_ms": max_time,
		"avg_frame_time_ms": avg_time,
		"avg_fps": avg_fps,
		"target_fps": TARGET_FPS,
		"meets_target": avg_fps >= TARGET_FPS
	}

	print("PerformanceOptimizer: Profile complete - Avg FPS: %.1f (%.2fms)" % [avg_fps, avg_time])

	return report
