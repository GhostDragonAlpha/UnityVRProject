## VoxelPerformanceMonitor - Performance monitoring for voxel terrain system
## Tracks chunk generation, collision mesh generation, memory usage, and frame times
## to ensure 90 FPS VR target is maintained.
##
## Requirements: 90 FPS VR target (11.11ms frame time budget)
## Monitors:
##   - Chunk generation time (ms)
##   - Collision mesh generation time (ms)
##   - Active chunk count
##   - Memory usage (MB)
##   - Physics frame time (ms)
##   - Rendering frame time (ms)
##
## Usage:
##   1. Add as autoload in project.godot
##   2. Connect voxel terrain via: set_voxel_terrain(terrain_node)
##   3. Monitor real-time stats via: get_statistics()
##   4. Enable debug UI via: set_debug_ui_enabled(true)
extends Node

## Emitted when performance warning is triggered (frame time > 11ms)
signal performance_warning(warning_type: String, value: float, threshold: float)
## Emitted when performance recovers to acceptable levels
signal performance_recovered(metric: String)
## Emitted when statistics are updated
signal statistics_updated(stats: Dictionary)
## Emitted when chunk generation completes
signal chunk_generation_completed(duration_ms: float)
## Emitted when collision mesh generation completes
signal collision_generation_completed(duration_ms: float)

## Target frame rate for VR (90 FPS)
const TARGET_FPS: float = 90.0
## Frame time budget in milliseconds (1000ms / 90fps = 11.11ms)
const FRAME_TIME_BUDGET_MS: float = 11.11
## Physics frame time budget (same as render for 90Hz physics)
const PHYSICS_TIME_BUDGET_MS: float = 11.11
## Warning threshold multiplier (trigger at 90% of budget)
const WARNING_THRESHOLD: float = 0.9

## Performance thresholds
const MAX_CHUNK_GENERATION_MS: float = 5.0  # Max time for single chunk generation
const MAX_COLLISION_GENERATION_MS: float = 3.0  # Max time for collision mesh
const MAX_ACTIVE_CHUNKS: int = 512  # Max number of active chunks
const MAX_MEMORY_MB: float = 2048.0  # Max memory for voxel system (2GB)

## Performance tracking
var _statistics: Dictionary = {}
var _is_initialized: bool = false
var _monitoring_enabled: bool = true

## Voxel terrain reference
var _voxel_terrain: Node = null
var _terrain_connected: bool = false

## Chunk tracking
var _active_chunk_count: int = 0
var _total_chunks_generated: int = 0
var _total_chunks_unloaded: int = 0

## Generation timing
var _chunk_generation_start: int = 0
var _collision_generation_start: int = 0
var _chunk_generation_times: Array[float] = []
var _collision_generation_times: Array[float] = []
var _max_generation_samples: int = 60  # Track last 60 generations

## Memory tracking
var _voxel_memory_usage_mb: float = 0.0
var _last_memory_check: int = 0
var _memory_check_interval_ms: int = 1000  # Check memory every second

## Frame time tracking
var _physics_frame_times: Array[float] = []
var _render_frame_times: Array[float] = []
var _frame_sample_size: int = 90  # Sample last 90 frames (1 second at 90fps)

## Warning state tracking
var _warning_states: Dictionary = {
	"chunk_generation": false,
	"collision_generation": false,
	"physics_frame": false,
	"render_frame": false,
	"memory": false,
	"chunk_count": false
}

## Debug UI
var _debug_ui_enabled: bool = false
var _debug_label: Label = null
var _debug_panel: PanelContainer = null


func _ready() -> void:
	"""Initialize the performance monitor."""
	# Initialize sample arrays
	_chunk_generation_times.resize(_max_generation_samples)
	_collision_generation_times.resize(_max_generation_samples)
	_physics_frame_times.resize(_frame_sample_size)
	_render_frame_times.resize(_frame_sample_size)

	# Fill with nominal values
	for i in range(_max_generation_samples):
		_chunk_generation_times[i] = 0.0
		_collision_generation_times[i] = 0.0

	for i in range(_frame_sample_size):
		_physics_frame_times[i] = FRAME_TIME_BUDGET_MS * 0.5
		_render_frame_times[i] = FRAME_TIME_BUDGET_MS * 0.5

	_is_initialized = true
	print("VoxelPerformanceMonitor: Initialized (90 FPS target, %.2f ms budget)" % FRAME_TIME_BUDGET_MS)


func _process(delta: float) -> void:
	"""Track rendering frame time."""
	if not _is_initialized or not _monitoring_enabled:
		return

	# Record render frame time
	var frame_time_ms = delta * 1000.0
	_render_frame_times.append(frame_time_ms)
	_render_frame_times.pop_front()

	# Check render frame time threshold
	_check_render_frame_threshold(frame_time_ms)

	# Update memory tracking periodically
	var current_time_ms = Time.get_ticks_msec()
	if current_time_ms - _last_memory_check >= _memory_check_interval_ms:
		_update_memory_tracking()
		_last_memory_check = current_time_ms


func _physics_process(delta: float) -> void:
	"""Track physics frame time."""
	if not _is_initialized or not _monitoring_enabled:
		return

	# Record physics frame time
	var frame_time_ms = delta * 1000.0
	_physics_frame_times.append(frame_time_ms)
	_physics_frame_times.pop_front()

	# Check physics frame time threshold
	_check_physics_frame_threshold(frame_time_ms)

	# Update statistics every 90 physics frames (1 second at 90Hz)
	if Engine.get_physics_frames() % 90 == 0:
		_update_statistics()


## Voxel Terrain Integration

func set_voxel_terrain(terrain: Node) -> bool:
	"""Connect to a voxel terrain node to monitor its events.

	Args:
		terrain: VoxelTerrain node (from godot_voxel addon) or compatible node

	Returns:
		true if successfully connected, false otherwise
	"""
	if terrain == null:
		push_warning("VoxelPerformanceMonitor: Cannot set null terrain")
		return false

	# Disconnect from previous terrain if any
	if _voxel_terrain != null and _terrain_connected:
		_disconnect_terrain_signals()

	_voxel_terrain = terrain
	_connect_terrain_signals()

	print("VoxelPerformanceMonitor: Connected to voxel terrain '%s'" % terrain.name)
	return true


func _connect_terrain_signals() -> void:
	"""Connect to voxel terrain signals for performance tracking."""
	if _voxel_terrain == null:
		return

	# Check if terrain has the expected signals (godot_voxel addon)
	# Note: These signals may vary depending on the voxel implementation

	# Try to connect to block_loaded signal
	if _voxel_terrain.has_signal("block_loaded"):
		if not _voxel_terrain.is_connected("block_loaded", _on_chunk_loaded):
			_voxel_terrain.connect("block_loaded", _on_chunk_loaded)

	# Try to connect to block_unloaded signal
	if _voxel_terrain.has_signal("block_unloaded"):
		if not _voxel_terrain.is_connected("block_unloaded", _on_chunk_unloaded):
			_voxel_terrain.connect("block_unloaded", _on_chunk_unloaded)

	# Try to connect to mesh_block_entered signal
	if _voxel_terrain.has_signal("mesh_block_entered"):
		if not _voxel_terrain.is_connected("mesh_block_entered", _on_mesh_block_entered):
			_voxel_terrain.connect("mesh_block_entered", _on_mesh_block_entered)

	# Try to connect to mesh_block_exited signal
	if _voxel_terrain.has_signal("mesh_block_exited"):
		if not _voxel_terrain.is_connected("mesh_block_exited", _on_mesh_block_exited):
			_voxel_terrain.connect("mesh_block_exited", _on_mesh_block_exited)

	_terrain_connected = true


func _disconnect_terrain_signals() -> void:
	"""Disconnect from voxel terrain signals."""
	if _voxel_terrain == null:
		return

	if _voxel_terrain.has_signal("block_loaded") and _voxel_terrain.is_connected("block_loaded", _on_chunk_loaded):
		_voxel_terrain.disconnect("block_loaded", _on_chunk_loaded)

	if _voxel_terrain.has_signal("block_unloaded") and _voxel_terrain.is_connected("block_unloaded", _on_chunk_unloaded):
		_voxel_terrain.disconnect("block_unloaded", _on_chunk_unloaded)

	if _voxel_terrain.has_signal("mesh_block_entered") and _voxel_terrain.is_connected("mesh_block_entered", _on_mesh_block_entered):
		_voxel_terrain.disconnect("mesh_block_entered", _on_mesh_block_entered)

	if _voxel_terrain.has_signal("mesh_block_exited") and _voxel_terrain.is_connected("mesh_block_exited", _on_mesh_block_exited):
		_voxel_terrain.disconnect("mesh_block_exited", _on_mesh_block_exited)

	_terrain_connected = false


## Signal Handlers

func _on_chunk_loaded(block_info: Dictionary) -> void:
	"""Called when a voxel chunk/block is loaded."""
	_active_chunk_count += 1
	_total_chunks_generated += 1

	# Check if we exceeded max chunk count
	if _active_chunk_count > MAX_ACTIVE_CHUNKS:
		_trigger_warning("chunk_count", _active_chunk_count, MAX_ACTIVE_CHUNKS)


func _on_chunk_unloaded(block_info: Dictionary) -> void:
	"""Called when a voxel chunk/block is unloaded."""
	_active_chunk_count = max(0, _active_chunk_count - 1)
	_total_chunks_unloaded += 1

	# Clear warning if chunk count is back to acceptable
	if _active_chunk_count <= MAX_ACTIVE_CHUNKS and _warning_states["chunk_count"]:
		_clear_warning("chunk_count")


func _on_mesh_block_entered(block_info: Dictionary) -> void:
	"""Called when a mesh block enters view."""
	# Could track mesh-specific metrics here
	pass


func _on_mesh_block_exited(block_info: Dictionary) -> void:
	"""Called when a mesh block exits view."""
	# Could track mesh-specific metrics here
	pass


## Manual Timing API (for custom voxel implementations)

func start_chunk_generation() -> void:
	"""Call this before starting chunk generation to measure time."""
	_chunk_generation_start = Time.get_ticks_usec()


func end_chunk_generation() -> void:
	"""Call this after chunk generation completes to record time."""
	if _chunk_generation_start == 0:
		push_warning("VoxelPerformanceMonitor: end_chunk_generation called without start_chunk_generation")
		return

	var duration_us = Time.get_ticks_usec() - _chunk_generation_start
	var duration_ms = duration_us / 1000.0

	# Record generation time
	_chunk_generation_times.append(duration_ms)
	_chunk_generation_times.pop_front()

	_chunk_generation_start = 0

	# Check threshold
	if duration_ms > MAX_CHUNK_GENERATION_MS:
		_trigger_warning("chunk_generation", duration_ms, MAX_CHUNK_GENERATION_MS)
	elif _warning_states["chunk_generation"]:
		_clear_warning("chunk_generation")

	chunk_generation_completed.emit(duration_ms)


func start_collision_generation() -> void:
	"""Call this before starting collision mesh generation to measure time."""
	_collision_generation_start = Time.get_ticks_usec()


func end_collision_generation() -> void:
	"""Call this after collision mesh generation completes to record time."""
	if _collision_generation_start == 0:
		push_warning("VoxelPerformanceMonitor: end_collision_generation called without start_collision_generation")
		return

	var duration_us = Time.get_ticks_usec() - _collision_generation_start
	var duration_ms = duration_us / 1000.0

	# Record generation time
	_collision_generation_times.append(duration_ms)
	_collision_generation_times.pop_front()

	_collision_generation_start = 0

	# Check threshold
	if duration_ms > MAX_COLLISION_GENERATION_MS:
		_trigger_warning("collision_generation", duration_ms, MAX_COLLISION_GENERATION_MS)
	elif _warning_states["collision_generation"]:
		_clear_warning("collision_generation")

	collision_generation_completed.emit(duration_ms)


func increment_chunk_count() -> void:
	"""Manually increment active chunk count (for custom implementations)."""
	_active_chunk_count += 1
	_total_chunks_generated += 1

	if _active_chunk_count > MAX_ACTIVE_CHUNKS:
		_trigger_warning("chunk_count", _active_chunk_count, MAX_ACTIVE_CHUNKS)


func decrement_chunk_count() -> void:
	"""Manually decrement active chunk count (for custom implementations)."""
	_active_chunk_count = max(0, _active_chunk_count - 1)

	if _active_chunk_count <= MAX_ACTIVE_CHUNKS and _warning_states["chunk_count"]:
		_clear_warning("chunk_count")


## Performance Threshold Checking

func _check_render_frame_threshold(frame_time_ms: float) -> void:
	"""Check if render frame time exceeds threshold."""
	var threshold = FRAME_TIME_BUDGET_MS * WARNING_THRESHOLD

	if frame_time_ms > threshold:
		_trigger_warning("render_frame", frame_time_ms, FRAME_TIME_BUDGET_MS)
	elif _warning_states["render_frame"]:
		_clear_warning("render_frame")


func _check_physics_frame_threshold(frame_time_ms: float) -> void:
	"""Check if physics frame time exceeds threshold."""
	var threshold = PHYSICS_TIME_BUDGET_MS * WARNING_THRESHOLD

	if frame_time_ms > threshold:
		_trigger_warning("physics_frame", frame_time_ms, PHYSICS_TIME_BUDGET_MS)
	elif _warning_states["physics_frame"]:
		_clear_warning("physics_frame")


func _update_memory_tracking() -> void:
	"""Update memory usage tracking."""
	# Get total memory usage from Performance singleton
	var total_memory_bytes = Performance.get_monitor(Performance.MEMORY_STATIC)
	var total_memory_mb = total_memory_bytes / 1024.0 / 1024.0

	# Estimate voxel memory (this is approximate - actual tracking would require
	# integration with the specific voxel implementation)
	# For now, we track total memory and assume a percentage is voxel data
	_voxel_memory_usage_mb = total_memory_mb * 0.5  # Assume 50% of memory is voxel data

	# Check threshold
	if _voxel_memory_usage_mb > MAX_MEMORY_MB:
		_trigger_warning("memory", _voxel_memory_usage_mb, MAX_MEMORY_MB)
	elif _warning_states["memory"]:
		_clear_warning("memory")


func _trigger_warning(warning_type: String, value: float, threshold: float) -> void:
	"""Trigger a performance warning."""
	if not _warning_states.get(warning_type, false):
		_warning_states[warning_type] = true

		var message = ""
		match warning_type:
			"chunk_generation":
				message = "Chunk generation time %.2f ms exceeds threshold %.2f ms" % [value, threshold]
			"collision_generation":
				message = "Collision generation time %.2f ms exceeds threshold %.2f ms" % [value, threshold]
			"physics_frame":
				message = "Physics frame time %.2f ms exceeds budget %.2f ms (90 FPS at risk)" % [value, threshold]
			"render_frame":
				message = "Render frame time %.2f ms exceeds budget %.2f ms (90 FPS at risk)" % [value, threshold]
			"memory":
				message = "Voxel memory usage %.1f MB exceeds threshold %.1f MB" % [value, threshold]
			"chunk_count":
				message = "Active chunk count %d exceeds maximum %d" % [int(value), int(threshold)]

		push_warning("VoxelPerformanceMonitor: " + message)
		performance_warning.emit(warning_type, value, threshold)


func _clear_warning(warning_type: String) -> void:
	"""Clear a performance warning."""
	if _warning_states.get(warning_type, false):
		_warning_states[warning_type] = false
		performance_recovered.emit(warning_type)


## Statistics

func _update_statistics() -> void:
	"""Update performance statistics."""
	_statistics = {
		# Frame time metrics
		"target_fps": TARGET_FPS,
		"frame_time_budget_ms": FRAME_TIME_BUDGET_MS,
		"physics_frame_time_ms": _calculate_average(_physics_frame_times),
		"render_frame_time_ms": _calculate_average(_render_frame_times),
		"physics_frame_time_max_ms": _calculate_max(_physics_frame_times),
		"render_frame_time_max_ms": _calculate_max(_render_frame_times),

		# Chunk metrics
		"active_chunk_count": _active_chunk_count,
		"total_chunks_generated": _total_chunks_generated,
		"total_chunks_unloaded": _total_chunks_unloaded,
		"max_chunk_count": MAX_ACTIVE_CHUNKS,

		# Generation timing
		"chunk_generation_avg_ms": _calculate_average(_chunk_generation_times),
		"chunk_generation_max_ms": _calculate_max(_chunk_generation_times),
		"collision_generation_avg_ms": _calculate_average(_collision_generation_times),
		"collision_generation_max_ms": _calculate_max(_collision_generation_times),

		# Memory
		"voxel_memory_mb": _voxel_memory_usage_mb,
		"max_memory_mb": MAX_MEMORY_MB,
		"total_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0,

		# Performance singleton metrics
		"time_process": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"time_physics_process": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,

		# Warning states
		"has_warnings": _has_active_warnings(),
		"warning_states": _warning_states.duplicate()
	}

	statistics_updated.emit(_statistics)

	# Update debug UI if enabled
	if _debug_ui_enabled and _debug_label != null:
		_update_debug_ui()


func get_statistics() -> Dictionary:
	"""Get current performance statistics.

	Returns:
		Dictionary containing all performance metrics
	"""
	if _statistics.is_empty():
		_update_statistics()
	return _statistics


func get_performance_report() -> String:
	"""Get a formatted performance report string.

	Returns:
		Formatted multi-line string with performance metrics
	"""
	var stats = get_statistics()

	var report = "=== Voxel Performance Report ===\n"
	report += "\n--- Frame Time ---\n"
	report += "Target: 90 FPS (%.2f ms budget)\n" % FRAME_TIME_BUDGET_MS
	report += "Physics: %.2f ms (avg) / %.2f ms (max)\n" % [stats.physics_frame_time_ms, stats.physics_frame_time_max_ms]
	report += "Render: %.2f ms (avg) / %.2f ms (max)\n" % [stats.render_frame_time_ms, stats.render_frame_time_max_ms]

	report += "\n--- Chunks ---\n"
	report += "Active: %d / %d\n" % [stats.active_chunk_count, stats.max_chunk_count]
	report += "Generated: %d\n" % stats.total_chunks_generated
	report += "Unloaded: %d\n" % stats.total_chunks_unloaded

	report += "\n--- Generation Time ---\n"
	report += "Chunk: %.2f ms (avg) / %.2f ms (max)\n" % [stats.chunk_generation_avg_ms, stats.chunk_generation_max_ms]
	report += "Collision: %.2f ms (avg) / %.2f ms (max)\n" % [stats.collision_generation_avg_ms, stats.collision_generation_max_ms]

	report += "\n--- Memory ---\n"
	report += "Voxel: %.1f MB / %.1f MB\n" % [stats.voxel_memory_mb, stats.max_memory_mb]
	report += "Total: %.1f MB\n" % stats.total_memory_mb

	report += "\n--- Warnings ---\n"
	if stats.has_warnings:
		for warning_type in stats.warning_states:
			if stats.warning_states[warning_type]:
				report += "  [!] %s\n" % warning_type.replace("_", " ").capitalize()
	else:
		report += "  None - All systems nominal\n"

	return report


func _calculate_average(samples: Array[float]) -> float:
	"""Calculate average of sample array."""
	if samples.is_empty():
		return 0.0

	var total = 0.0
	var count = 0
	for sample in samples:
		if sample > 0.0:  # Ignore zero/uninitialized samples
			total += sample
			count += 1

	return total / count if count > 0 else 0.0


func _calculate_max(samples: Array[float]) -> float:
	"""Calculate maximum of sample array."""
	if samples.is_empty():
		return 0.0

	var max_val = 0.0
	for sample in samples:
		if sample > max_val:
			max_val = sample

	return max_val


func _has_active_warnings() -> bool:
	"""Check if any warnings are active."""
	for warning_type in _warning_states:
		if _warning_states[warning_type]:
			return true
	return false


## Debug UI

func set_debug_ui_enabled(enabled: bool) -> void:
	"""Enable or disable the debug UI overlay.

	Args:
		enabled: true to show debug UI, false to hide
	"""
	_debug_ui_enabled = enabled

	if enabled and _debug_panel == null:
		_create_debug_ui()
	elif not enabled and _debug_panel != null:
		_destroy_debug_ui()


func _create_debug_ui() -> void:
	"""Create the debug UI overlay."""
	# Create panel container
	_debug_panel = PanelContainer.new()
	_debug_panel.name = "VoxelPerformanceDebugUI"

	# Position in top-right corner
	_debug_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_debug_panel.position = Vector2(-350, 10)
	_debug_panel.custom_minimum_size = Vector2(340, 0)

	# Create label
	_debug_label = Label.new()
	_debug_label.add_theme_font_size_override("font_size", 12)
	_debug_panel.add_child(_debug_label)

	# Add to scene tree
	get_tree().root.add_child(_debug_panel)

	print("VoxelPerformanceMonitor: Debug UI enabled")


func _destroy_debug_ui() -> void:
	"""Destroy the debug UI overlay."""
	if _debug_panel != null:
		_debug_panel.queue_free()
		_debug_panel = null
		_debug_label = null

	print("VoxelPerformanceMonitor: Debug UI disabled")


func _update_debug_ui() -> void:
	"""Update the debug UI with current statistics."""
	if _debug_label == null:
		return

	var stats = _statistics

	var text = "=== Voxel Performance ===\n"
	text += "\nFrame Time (Budget: %.1fms)\n" % FRAME_TIME_BUDGET_MS
	text += "  Physics: %.1fms / %.1fms\n" % [stats.physics_frame_time_ms, stats.physics_frame_time_max_ms]
	text += "  Render: %.1fms / %.1fms\n" % [stats.render_frame_time_ms, stats.render_frame_time_max_ms]

	text += "\nChunks\n"
	text += "  Active: %d / %d\n" % [stats.active_chunk_count, stats.max_chunk_count]
	text += "  Generated: %d\n" % stats.total_chunks_generated

	text += "\nGeneration Time\n"
	text += "  Chunk: %.1fms / %.1fms\n" % [stats.chunk_generation_avg_ms, stats.chunk_generation_max_ms]
	text += "  Collision: %.1fms / %.1fms\n" % [stats.collision_generation_avg_ms, stats.collision_generation_max_ms]

	text += "\nMemory\n"
	text += "  Voxel: %.0fMB / %.0fMB\n" % [stats.voxel_memory_mb, stats.max_memory_mb]

	if stats.has_warnings:
		text += "\n[!] Warnings Active:\n"
		for warning_type in stats.warning_states:
			if stats.warning_states[warning_type]:
				text += "  - %s\n" % warning_type.replace("_", " ").capitalize()

	_debug_label.text = text


## Control

func set_monitoring_enabled(enabled: bool) -> void:
	"""Enable or disable performance monitoring.

	Args:
		enabled: true to enable monitoring, false to disable
	"""
	_monitoring_enabled = enabled
	print("VoxelPerformanceMonitor: Monitoring %s" % ("enabled" if enabled else "disabled"))


func is_monitoring_enabled() -> bool:
	"""Check if monitoring is enabled.

	Returns:
		true if monitoring is enabled, false otherwise
	"""
	return _monitoring_enabled


func reset_statistics() -> void:
	"""Reset all statistics and counters."""
	_active_chunk_count = 0
	_total_chunks_generated = 0
	_total_chunks_unloaded = 0

	for i in range(_max_generation_samples):
		_chunk_generation_times[i] = 0.0
		_collision_generation_times[i] = 0.0

	for i in range(_frame_sample_size):
		_physics_frame_times[i] = FRAME_TIME_BUDGET_MS * 0.5
		_render_frame_times[i] = FRAME_TIME_BUDGET_MS * 0.5

	for warning_type in _warning_states:
		_warning_states[warning_type] = false

	_statistics.clear()

	print("VoxelPerformanceMonitor: Statistics reset")


func is_performance_acceptable() -> bool:
	"""Check if all performance metrics are within acceptable ranges.

	Returns:
		true if performance is acceptable, false if any warnings are active
	"""
	return not _has_active_warnings()


func get_active_warnings() -> Array[String]:
	"""Get list of active warning types.

	Returns:
		Array of warning type strings
	"""
	var warnings: Array[String] = []
	for warning_type in _warning_states:
		if _warning_states[warning_type]:
			warnings.append(warning_type)
	return warnings


## Shutdown

func shutdown() -> void:
	"""Shutdown and cleanup the performance monitor."""
	if _voxel_terrain != null and _terrain_connected:
		_disconnect_terrain_signals()

	_destroy_debug_ui()

	_voxel_terrain = null
	_is_initialized = false

	print("VoxelPerformanceMonitor: Shutdown complete")


func _notification(what: int) -> void:
	"""Handle notifications."""
	if what == NOTIFICATION_PREDELETE:
		shutdown()
