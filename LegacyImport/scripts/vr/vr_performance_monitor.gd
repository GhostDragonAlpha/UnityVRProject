## VRPerformanceMonitor - VR-specific performance monitoring for 90 FPS target
## Tracks frame times, reprojection rate, dropped frames, and VR-specific metrics
## to ensure smooth VR experience.
##
## Requirements: 90 FPS VR target (11.11ms frame time budget)
## Monitors:
##   - Frame times with rolling average (90 samples = 1 second at 90 FPS)
##   - FPS tracking with warning at < 88 FPS
##   - VR reprojection events (when available from XR runtime)
##   - Dropped frames detection
##   - Integration with VoxelPerformanceMonitor for chunk generation impact
##
## Usage:
##   1. Add to VR scenes (NOT an autoload - manual instantiation)
##   2. Add as child of XROrigin3D or VR root node
##   3. Monitor real-time stats via: get_average_fps(), check_vr_performance()
##   4. Connect to performance_warning signal for alerts
##   5. Optional: Enable console reporting via set_console_reporting_enabled(true)
##
## Example:
##   var vr_perf = VRPerformanceMonitor.new()
##   add_child(vr_perf)
##   vr_perf.set_console_reporting_enabled(true)
extends Node

## Emitted when FPS drops below warning threshold (88 FPS)
signal performance_warning(warning_type: String, current_fps: float, target_fps: float)
## Emitted when performance recovers to acceptable levels
signal performance_recovered()
## Emitted when a frame is dropped
signal frame_dropped(consecutive_drops: int)
## Emitted when VR reprojection is detected
signal reprojection_detected(reprojection_rate: float)

## Target frame rate for VR (90 FPS)
const TARGET_FPS: float = 90.0
## Frame time budget in milliseconds (1000ms / 90fps = 11.11ms)
const FRAME_TIME_BUDGET_MS: float = 11.11
## Warning threshold for FPS (88 FPS minimum)
const FPS_WARNING_THRESHOLD: float = 88.0
## Number of samples for rolling average (90 samples = 1 second at 90 FPS)
const SAMPLE_SIZE: int = 90
## Threshold for detecting dropped frames (if frame time > 2x budget)
const DROPPED_FRAME_THRESHOLD_MS: float = 22.22  # 2x budget

## Frame time tracking
var _frame_times: Array[float] = []
var _current_sample_index: int = 0
var _samples_collected: int = 0

## Performance tracking
var _current_fps: float = TARGET_FPS
var _average_frame_time_ms: float = FRAME_TIME_BUDGET_MS
var _max_frame_time_ms: float = 0.0
var _min_frame_time_ms: float = FRAME_TIME_BUDGET_MS

## Warning state
var _is_underperforming: bool = false
var _consecutive_low_fps_frames: int = 0
var _low_fps_warning_threshold: int = 10  # Warn after 10 consecutive low FPS frames

## Dropped frames tracking
var _total_dropped_frames: int = 0
var _consecutive_dropped_frames: int = 0
var _last_frame_time: int = 0

## VR-specific metrics
var _reprojection_events: int = 0
var _estimated_reprojection_rate: float = 0.0
var _xr_interface: XRInterface = null

## Integration with VoxelPerformanceMonitor
var _voxel_monitor: Node = null
var _voxel_monitor_connected: bool = false

## Console reporting
var _console_reporting_enabled: bool = false
var _console_report_interval_sec: float = 5.0
var _last_console_report_time: float = 0.0

## Statistics
var _statistics: Dictionary = {}
var _start_time: float = 0.0


func _ready() -> void:
	"""Initialize the VR performance monitor."""
	# Initialize frame time sample array
	_frame_times.resize(SAMPLE_SIZE)
	for i in range(SAMPLE_SIZE):
		_frame_times[i] = FRAME_TIME_BUDGET_MS

	# Try to get XR interface for VR-specific metrics
	_xr_interface = XRServer.get_primary_interface()
	if _xr_interface:
		print("[VRPerformanceMonitor] Connected to XR interface: %s" % _xr_interface.get_name())
	else:
		print("[VRPerformanceMonitor] No XR interface detected - running in fallback mode")

	# Try to connect to VoxelPerformanceMonitor autoload
	_connect_to_voxel_monitor()

	_start_time = Time.get_ticks_msec() / 1000.0
	_last_frame_time = Time.get_ticks_usec()

	print("[VRPerformanceMonitor] Initialized - Target: 90 FPS (%.2f ms budget)" % FRAME_TIME_BUDGET_MS)


func _process(delta: float) -> void:
	"""Track frame times and calculate performance metrics."""
	# Record frame time
	var frame_time_ms = delta * 1000.0
	_record_frame_time(frame_time_ms)

	# Check for dropped frames
	_check_dropped_frames(frame_time_ms)

	# Update current FPS from rolling average
	_update_fps_metrics()

	# Check VR-specific metrics
	_update_vr_metrics()

	# Check performance thresholds
	_check_performance_thresholds()

	# Console reporting if enabled
	if _console_reporting_enabled:
		_update_console_reporting()


## Frame Time Tracking

func _record_frame_time(frame_time_ms: float) -> void:
	"""Record a frame time sample in the rolling average buffer.

	Args:
		frame_time_ms: Frame time in milliseconds
	"""
	_frame_times[_current_sample_index] = frame_time_ms
	_current_sample_index = (_current_sample_index + 1) % SAMPLE_SIZE

	if _samples_collected < SAMPLE_SIZE:
		_samples_collected += 1


func _update_fps_metrics() -> void:
	"""Update FPS and frame time metrics from rolling average."""
	# Calculate average frame time
	var total_time = 0.0
	var sample_count = min(_samples_collected, SAMPLE_SIZE)

	_max_frame_time_ms = 0.0
	_min_frame_time_ms = 999999.0

	for i in range(sample_count):
		var frame_time = _frame_times[i]
		total_time += frame_time

		if frame_time > _max_frame_time_ms:
			_max_frame_time_ms = frame_time
		if frame_time < _min_frame_time_ms:
			_min_frame_time_ms = frame_time

	_average_frame_time_ms = total_time / sample_count if sample_count > 0 else FRAME_TIME_BUDGET_MS

	# Calculate FPS from average frame time
	_current_fps = 1000.0 / _average_frame_time_ms if _average_frame_time_ms > 0 else TARGET_FPS


func _check_dropped_frames(frame_time_ms: float) -> void:
	"""Check if the current frame was dropped (took more than 2x budget).

	Args:
		frame_time_ms: Current frame time in milliseconds
	"""
	if frame_time_ms > DROPPED_FRAME_THRESHOLD_MS:
		_total_dropped_frames += 1
		_consecutive_dropped_frames += 1
		frame_dropped.emit(_consecutive_dropped_frames)

		if _consecutive_dropped_frames == 1:
			print("[VRPerformanceMonitor] Frame dropped! (%.2f ms)" % frame_time_ms)
		elif _consecutive_dropped_frames % 5 == 0:
			push_warning("[VRPerformanceMonitor] %d consecutive dropped frames!" % _consecutive_dropped_frames)
	else:
		_consecutive_dropped_frames = 0


## VR-Specific Metrics

func _update_vr_metrics() -> void:
	"""Update VR-specific performance metrics."""
	if not _xr_interface or not _xr_interface.is_initialized():
		return

	# Check for reprojection (estimated from frame time spikes)
	# Note: Direct reprojection data may not be available from all XR runtimes
	# This is an estimation based on frame time patterns
	var current_frame_time = _frame_times[(_current_sample_index - 1 + SAMPLE_SIZE) % SAMPLE_SIZE]

	# Detect potential reprojection: frame time between 1.5x and 2x budget
	if current_frame_time > (FRAME_TIME_BUDGET_MS * 1.5) and current_frame_time < DROPPED_FRAME_THRESHOLD_MS:
		_reprojection_events += 1

	# Calculate estimated reprojection rate (percentage of frames with reprojection)
	if _samples_collected >= SAMPLE_SIZE:
		_estimated_reprojection_rate = (_reprojection_events / float(SAMPLE_SIZE)) * 100.0


## Performance Threshold Checking

func _check_performance_thresholds() -> void:
	"""Check if performance is below acceptable thresholds and emit warnings."""
	if _current_fps < FPS_WARNING_THRESHOLD:
		_consecutive_low_fps_frames += 1

		if not _is_underperforming and _consecutive_low_fps_frames >= _low_fps_warning_threshold:
			_is_underperforming = true
			var message = "VR performance below threshold! Current: %.1f FPS, Target: %.1f FPS (Frame time: %.2f ms)" % [
				_current_fps,
				TARGET_FPS,
				_average_frame_time_ms
			]
			push_warning("[VRPerformanceMonitor] " + message)
			performance_warning.emit("low_fps", _current_fps, TARGET_FPS)
	else:
		if _is_underperforming:
			_is_underperforming = false
			print("[VRPerformanceMonitor] Performance recovered! Current: %.1f FPS" % _current_fps)
			performance_recovered.emit()

		_consecutive_low_fps_frames = 0


## Integration with VoxelPerformanceMonitor

func _connect_to_voxel_monitor() -> void:
	"""Attempt to connect to VoxelPerformanceMonitor autoload."""
	if Engine.has_singleton("VoxelPerformanceMonitor"):
		_voxel_monitor = Engine.get_singleton("VoxelPerformanceMonitor")
	elif has_node("/root/VoxelPerformanceMonitor"):
		_voxel_monitor = get_node("/root/VoxelPerformanceMonitor")

	if _voxel_monitor:
		# Connect to voxel monitor signals to track chunk generation impact
		if _voxel_monitor.has_signal("performance_warning"):
			_voxel_monitor.connect("performance_warning", _on_voxel_performance_warning)
		if _voxel_monitor.has_signal("chunk_generation_completed"):
			_voxel_monitor.connect("chunk_generation_completed", _on_chunk_generation_completed)

		_voxel_monitor_connected = true
		print("[VRPerformanceMonitor] Connected to VoxelPerformanceMonitor")
	else:
		print("[VRPerformanceMonitor] VoxelPerformanceMonitor not found - running standalone")


func _on_voxel_performance_warning(warning_type: String, value: float, threshold: float) -> void:
	"""Handle performance warnings from VoxelPerformanceMonitor.

	Args:
		warning_type: Type of warning (chunk_generation, collision_generation, etc.)
		value: Current value that triggered warning
		threshold: Threshold that was exceeded
	"""
	print("[VRPerformanceMonitor] Voxel system warning: %s (%.2f > %.2f)" % [warning_type, value, threshold])


func _on_chunk_generation_completed(duration_ms: float) -> void:
	"""Track chunk generation impact on frame time.

	Args:
		duration_ms: Time taken to generate chunk in milliseconds
	"""
	if duration_ms > 5.0:  # Significant chunk generation time
		print("[VRPerformanceMonitor] Heavy chunk generation: %.2f ms (may impact frame time)" % duration_ms)


## Public API

func get_average_fps() -> float:
	"""Get the current rolling average FPS.

	Returns:
		Average FPS over the last SAMPLE_SIZE frames
	"""
	return _current_fps


func get_frame_time_ms() -> float:
	"""Get the current average frame time in milliseconds.

	Returns:
		Average frame time in milliseconds
	"""
	return _average_frame_time_ms


func check_vr_performance() -> bool:
	"""Check if VR performance is meeting the 90 FPS target.

	Returns:
		true if meeting 90 FPS target (>= 88 FPS), false otherwise
	"""
	return _current_fps >= FPS_WARNING_THRESHOLD


func get_statistics() -> Dictionary:
	"""Get comprehensive performance statistics.

	Returns:
		Dictionary containing all performance metrics
	"""
	var uptime = (Time.get_ticks_msec() / 1000.0) - _start_time

	_statistics = {
		# FPS metrics
		"target_fps": TARGET_FPS,
		"current_fps": _current_fps,
		"fps_warning_threshold": FPS_WARNING_THRESHOLD,
		"is_meeting_target": check_vr_performance(),

		# Frame time metrics
		"frame_time_budget_ms": FRAME_TIME_BUDGET_MS,
		"average_frame_time_ms": _average_frame_time_ms,
		"max_frame_time_ms": _max_frame_time_ms,
		"min_frame_time_ms": _min_frame_time_ms,

		# Dropped frames
		"total_dropped_frames": _total_dropped_frames,
		"consecutive_dropped_frames": _consecutive_dropped_frames,
		"dropped_frame_threshold_ms": DROPPED_FRAME_THRESHOLD_MS,

		# VR-specific metrics
		"xr_interface_active": _xr_interface != null and _xr_interface.is_initialized(),
		"xr_interface_name": _xr_interface.get_name() if _xr_interface else "None",
		"reprojection_events": _reprojection_events,
		"estimated_reprojection_rate": _estimated_reprojection_rate,

		# Integration
		"voxel_monitor_connected": _voxel_monitor_connected,

		# General
		"uptime_seconds": uptime,
		"samples_collected": _samples_collected,
		"is_underperforming": _is_underperforming,
		"consecutive_low_fps_frames": _consecutive_low_fps_frames,
	}

	# Add voxel statistics if available
	if _voxel_monitor and _voxel_monitor_connected:
		var voxel_stats = _voxel_monitor.get_statistics()
		if voxel_stats:
			_statistics["voxel_chunk_generation_avg_ms"] = voxel_stats.get("chunk_generation_avg_ms", 0.0)
			_statistics["voxel_collision_generation_avg_ms"] = voxel_stats.get("collision_generation_avg_ms", 0.0)
			_statistics["voxel_active_chunks"] = voxel_stats.get("active_chunk_count", 0)
			_statistics["voxel_has_warnings"] = voxel_stats.get("has_warnings", false)

	return _statistics


func get_performance_report() -> String:
	"""Get a formatted performance report string for console output.

	Returns:
		Formatted multi-line string with performance metrics
	"""
	var stats = get_statistics()

	var report = "=== VR Performance Report ===\n"

	# FPS Status
	report += "\n--- FPS Status ---\n"
	report += "Target: %.1f FPS (%.2f ms budget)\n" % [TARGET_FPS, FRAME_TIME_BUDGET_MS]
	report += "Current: %.1f FPS (%.2f ms average)\n" % [stats.current_fps, stats.average_frame_time_ms]

	var status_icon = "[OK]" if stats.is_meeting_target else "[!!]"
	var status_text = "GOOD" if stats.is_meeting_target else "UNDERPERFORMING"
	report += "Status: %s %s\n" % [status_icon, status_text]

	# Frame Time Details
	report += "\n--- Frame Time ---\n"
	report += "Average: %.2f ms\n" % stats.average_frame_time_ms
	report += "Min: %.2f ms\n" % stats.min_frame_time_ms
	report += "Max: %.2f ms\n" % stats.max_frame_time_ms

	# Dropped Frames
	report += "\n--- Dropped Frames ---\n"
	report += "Total: %d\n" % stats.total_dropped_frames
	report += "Consecutive: %d\n" % stats.consecutive_dropped_frames

	# VR-Specific
	if stats.xr_interface_active:
		report += "\n--- VR Metrics ---\n"
		report += "XR Interface: %s\n" % stats.xr_interface_name
		report += "Reprojection Events: %d\n" % stats.reprojection_events
		report += "Estimated Reprojection Rate: %.1f%%\n" % stats.estimated_reprojection_rate

	# Voxel Integration
	if stats.voxel_monitor_connected:
		report += "\n--- Voxel Terrain Impact ---\n"
		report += "Chunk Generation: %.2f ms (avg)\n" % stats.get("voxel_chunk_generation_avg_ms", 0.0)
		report += "Collision Generation: %.2f ms (avg)\n" % stats.get("voxel_collision_generation_avg_ms", 0.0)
		report += "Active Chunks: %d\n" % stats.get("voxel_active_chunks", 0)

		if stats.get("voxel_has_warnings", false):
			report += "[!] Voxel system has active warnings\n"

	# Uptime
	report += "\n--- Session ---\n"
	report += "Uptime: %.1f seconds\n" % stats.uptime_seconds
	report += "Samples: %d / %d\n" % [stats.samples_collected, SAMPLE_SIZE]

	return report


## Console Reporting

func set_console_reporting_enabled(enabled: bool, interval_sec: float = 5.0) -> void:
	"""Enable or disable periodic console reporting.

	Args:
		enabled: true to enable console reporting, false to disable
		interval_sec: Interval between reports in seconds (default: 5.0)
	"""
	_console_reporting_enabled = enabled
	_console_report_interval_sec = interval_sec
	_last_console_report_time = Time.get_ticks_msec() / 1000.0

	print("[VRPerformanceMonitor] Console reporting %s (interval: %.1fs)" % [
		"enabled" if enabled else "disabled",
		interval_sec
	])


func _update_console_reporting() -> void:
	"""Update console reporting if enabled and interval has elapsed."""
	var current_time = Time.get_ticks_msec() / 1000.0

	if current_time - _last_console_report_time >= _console_report_interval_sec:
		print(get_performance_report())
		_last_console_report_time = current_time


func print_current_stats() -> void:
	"""Print current performance statistics to console (one-time)."""
	print(get_performance_report())


## Control

func reset_statistics() -> void:
	"""Reset all statistics and counters."""
	_total_dropped_frames = 0
	_consecutive_dropped_frames = 0
	_reprojection_events = 0
	_consecutive_low_fps_frames = 0
	_is_underperforming = false
	_samples_collected = 0
	_current_sample_index = 0
	_start_time = Time.get_ticks_msec() / 1000.0

	# Reset frame time samples
	for i in range(SAMPLE_SIZE):
		_frame_times[i] = FRAME_TIME_BUDGET_MS

	print("[VRPerformanceMonitor] Statistics reset")


func get_voxel_monitor() -> Node:
	"""Get reference to VoxelPerformanceMonitor if connected.

	Returns:
		VoxelPerformanceMonitor node or null if not connected
	"""
	return _voxel_monitor


## Shutdown

func _notification(what: int) -> void:
	"""Handle notifications."""
	if what == NOTIFICATION_PREDELETE:
		if _voxel_monitor and _voxel_monitor_connected:
			# Disconnect signals
			if _voxel_monitor.has_signal("performance_warning") and _voxel_monitor.is_connected("performance_warning", _on_voxel_performance_warning):
				_voxel_monitor.disconnect("performance_warning", _on_voxel_performance_warning)
			if _voxel_monitor.has_signal("chunk_generation_completed") and _voxel_monitor.is_connected("chunk_generation_completed", _on_chunk_generation_completed):
				_voxel_monitor.disconnect("chunk_generation_completed", _on_chunk_generation_completed)

		print("[VRPerformanceMonitor] Shutdown complete")
