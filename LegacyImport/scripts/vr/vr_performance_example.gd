## Example script demonstrating VRPerformanceMonitor usage in VR scenes
## This script shows how to add VR performance monitoring to your VR project
## and respond to performance warnings.
##
## Usage:
##   1. Attach this script to your XROrigin3D or VR root node
##   2. The monitor will automatically start tracking performance
##   3. Console reports will be printed every 5 seconds
##   4. Performance warnings will trigger automatic quality adjustments
extends Node3D

## Reference to VR performance monitor
var vr_perf_monitor: Node = null

## Performance adjustment settings
var current_quality_level: int = 2  # 0=Low, 1=Medium, 2=High
var can_adjust_quality: bool = true
var quality_cooldown_sec: float = 10.0
var last_quality_adjustment: float = 0.0


func _ready() -> void:
	"""Initialize VR performance monitoring."""
	# Create and add VR performance monitor
	var VRMonitorScript = load("res://scripts/vr/vr_performance_monitor.gd")
	vr_perf_monitor = VRMonitorScript.new()
	vr_perf_monitor.name = "VRPerformanceMonitor"
	add_child(vr_perf_monitor)

	# Wait for monitor to initialize
	await get_tree().process_frame

	# Connect to performance signals
	vr_perf_monitor.performance_warning.connect(_on_performance_warning)
	vr_perf_monitor.performance_recovered.connect(_on_performance_recovered)
	vr_perf_monitor.frame_dropped.connect(_on_frame_dropped)
	vr_perf_monitor.reprojection_detected.connect(_on_reprojection_detected)

	# Enable console reporting (every 5 seconds)
	vr_perf_monitor.set_console_reporting_enabled(true, 5.0)

	print("[VRPerformanceExample] VR performance monitoring active")
	print("[VRPerformanceExample] Initial quality level: %d (0=Low, 1=Medium, 2=High)" % current_quality_level)


func _process(_delta: float) -> void:
	"""Called every frame for custom monitoring logic."""
	# Example: Check if we should adjust quality based on sustained performance
	if not can_adjust_quality:
		var time_since_adjustment = (Time.get_ticks_msec() / 1000.0) - last_quality_adjustment
		if time_since_adjustment >= quality_cooldown_sec:
			can_adjust_quality = true

	# Example: Manual performance check every second
	if Engine.get_process_frames() % 90 == 0:  # Every ~1 second at 90 FPS
		_check_custom_performance()


func _check_custom_performance() -> void:
	"""Custom performance checking logic."""
	var stats = vr_perf_monitor.get_statistics()

	# Example: If FPS is consistently low and quality is not at minimum
	if not stats.is_meeting_target and current_quality_level > 0:
		if can_adjust_quality:
			_reduce_quality()

	# Example: If performance is good for a while, try increasing quality
	if stats.is_meeting_target and current_quality_level < 2:
		# Check if we've been performing well (no dropped frames recently)
		if stats.total_dropped_frames == 0 and can_adjust_quality:
			# Consider increasing quality after sustained good performance
			# (You might want to track sustained performance over time here)
			pass


## Signal Handlers

func _on_performance_warning(warning_type: String, current_fps: float, target_fps: float) -> void:
	"""Handle performance warning from VR monitor.

	Args:
		warning_type: Type of warning (e.g., "low_fps")
		current_fps: Current FPS
		target_fps: Target FPS (90.0)
	"""
	print("[VRPerformanceExample] Performance warning: %s - Current: %.1f FPS, Target: %.1f FPS" % [
		warning_type,
		current_fps,
		target_fps
	])

	# Automatically reduce quality if we can
	if can_adjust_quality and current_quality_level > 0:
		_reduce_quality()


func _on_performance_recovered() -> void:
	"""Handle performance recovery signal."""
	print("[VRPerformanceExample] Performance recovered!")

	# You might want to try increasing quality after sustained good performance
	# But be careful not to cause oscillation between quality levels


func _on_frame_dropped(consecutive_drops: int) -> void:
	"""Handle dropped frame signal.

	Args:
		consecutive_drops: Number of consecutive dropped frames
	"""
	if consecutive_drops == 1:
		print("[VRPerformanceExample] Frame dropped!")
	elif consecutive_drops % 5 == 0:
		push_warning("[VRPerformanceExample] %d consecutive frames dropped - severe performance issue!" % consecutive_drops)

		# Take emergency action if many consecutive drops
		if consecutive_drops >= 10 and current_quality_level > 0:
			_reduce_quality()


func _on_reprojection_detected(reprojection_rate: float) -> void:
	"""Handle VR reprojection detection.

	Args:
		reprojection_rate: Estimated reprojection rate percentage
	"""
	if reprojection_rate > 5.0:  # More than 5% reprojection
		print("[VRPerformanceExample] High reprojection rate detected: %.1f%%" % reprojection_rate)


## Quality Adjustment

func _reduce_quality() -> void:
	"""Reduce rendering quality to improve performance."""
	if current_quality_level <= 0:
		print("[VRPerformanceExample] Quality already at minimum level")
		return

	current_quality_level -= 1
	can_adjust_quality = false
	last_quality_adjustment = Time.get_ticks_msec() / 1000.0

	print("[VRPerformanceExample] Reducing quality to level %d" % current_quality_level)

	# Apply quality settings
	_apply_quality_settings()


func _increase_quality() -> void:
	"""Increase rendering quality."""
	if current_quality_level >= 2:
		print("[VRPerformanceExample] Quality already at maximum level")
		return

	current_quality_level += 1
	can_adjust_quality = false
	last_quality_adjustment = Time.get_ticks_msec() / 1000.0

	print("[VRPerformanceExample] Increasing quality to level %d" % current_quality_level)

	# Apply quality settings
	_apply_quality_settings()


func _apply_quality_settings() -> void:
	"""Apply rendering quality settings based on current quality level."""
	var viewport = get_viewport()
	if not viewport:
		return

	match current_quality_level:
		0:  # Low quality
			# Reduce MSAA
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			# Disable expensive effects
			_set_environment_quality(false, false, false)
			print("[VRPerformanceExample] Applied LOW quality settings")

		1:  # Medium quality
			# 2x MSAA
			viewport.msaa_3d = Viewport.MSAA_2X
			# Enable some effects
			_set_environment_quality(false, true, false)
			print("[VRPerformanceExample] Applied MEDIUM quality settings")

		2:  # High quality
			# 4x MSAA
			viewport.msaa_3d = Viewport.MSAA_4X
			# Enable all effects
			_set_environment_quality(true, true, true)
			print("[VRPerformanceExample] Applied HIGH quality settings")


func _set_environment_quality(glow: bool, ssr: bool, ssao: bool) -> void:
	"""Set environment quality settings.

	Args:
		glow: Enable glow effect
		ssr: Enable screen-space reflections
		ssao: Enable screen-space ambient occlusion
	"""
	# Find WorldEnvironment in scene
	var world_env = _find_world_environment(get_tree().root)
	if not world_env or not world_env.environment:
		return

	var env: Environment = world_env.environment

	env.glow_enabled = glow
	env.ssr_enabled = ssr
	env.ssao_enabled = ssao


func _find_world_environment(node: Node) -> WorldEnvironment:
	"""Recursively find WorldEnvironment in scene tree.

	Args:
		node: Starting node for search

	Returns:
		WorldEnvironment node or null if not found
	"""
	if node is WorldEnvironment:
		return node

	for child in node.get_children():
		var result = _find_world_environment(child)
		if result:
			return result

	return null


## Public API

func get_current_fps() -> float:
	"""Get current average FPS from monitor.

	Returns:
		Current average FPS
	"""
	if vr_perf_monitor:
		return vr_perf_monitor.get_average_fps()
	return 0.0


func get_performance_stats() -> Dictionary:
	"""Get full performance statistics.

	Returns:
		Dictionary with performance metrics
	"""
	if vr_perf_monitor:
		return vr_perf_monitor.get_statistics()
	return {}


func print_performance_report() -> void:
	"""Print detailed performance report to console."""
	if vr_perf_monitor:
		vr_perf_monitor.print_current_stats()


func force_quality_level(level: int) -> void:
	"""Manually set quality level.

	Args:
		level: Quality level (0=Low, 1=Medium, 2=High)
	"""
	if level < 0 or level > 2:
		push_warning("[VRPerformanceExample] Invalid quality level: %d (must be 0-2)" % level)
		return

	current_quality_level = level
	_apply_quality_settings()


## Cleanup

func _notification(what: int) -> void:
	"""Handle notifications."""
	if what == NOTIFICATION_PREDELETE:
		if vr_perf_monitor:
			print("[VRPerformanceExample] Cleaning up VR performance monitor")
