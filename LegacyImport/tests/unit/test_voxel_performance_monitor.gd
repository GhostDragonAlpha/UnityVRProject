## Unit tests for VoxelPerformanceMonitor
## Tests performance monitoring, threshold detection, and statistics tracking
extends GdUnitTestSuite

## Test setup
var monitor: Node  # VoxelPerformanceMonitor (autoload without class_name)
var warning_received: bool = false
var recovery_received: bool = false
var last_warning_type: String = ""
var last_stats: Dictionary = {}


func before_test() -> void:
	"""Setup before each test."""
	# VoxelPerformanceMonitor doesn't have class_name, so we load the script
	var MonitorScript = load("res://scripts/core/voxel_performance_monitor.gd")
	monitor = MonitorScript.new()
	monitor.name = "TestMonitor"
	add_child(monitor)

	# Wait for _ready to complete
	await get_tree().process_frame

	# Connect signals for testing
	monitor.performance_warning.connect(_on_warning)
	monitor.performance_recovered.connect(_on_recovery)
	monitor.statistics_updated.connect(_on_stats)

	# Reset flags
	warning_received = false
	recovery_received = false
	last_warning_type = ""
	last_stats = {}


func after_test() -> void:
	"""Cleanup after each test."""
	if monitor != null:
		monitor.queue_free()
		monitor = null


func _on_warning(type: String, value: float, threshold: float) -> void:
	"""Signal handler for warnings."""
	warning_received = true
	last_warning_type = type


func _on_recovery(metric: String) -> void:
	"""Signal handler for recovery."""
	recovery_received = true


func _on_stats(stats: Dictionary) -> void:
	"""Signal handler for statistics."""
	last_stats = stats


## Initialization Tests

func test_monitor_initializes_correctly() -> void:
	"""Test that monitor initializes with correct default values."""
	assert_bool(monitor._is_initialized).is_true()
	assert_bool(monitor._monitoring_enabled).is_true()
	assert_int(monitor._active_chunk_count).is_equal(0)
	assert_int(monitor._total_chunks_generated).is_equal(0)
	assert_int(monitor._total_chunks_unloaded).is_equal(0)


func test_constants_match_90fps_target() -> void:
	"""Test that constants are correctly set for 90 FPS VR."""
	assert_float(monitor.TARGET_FPS).is_equal(90.0)
	assert_float(monitor.FRAME_TIME_BUDGET_MS).is_equal_approx(11.11, 0.01)
	assert_float(monitor.PHYSICS_TIME_BUDGET_MS).is_equal_approx(11.11, 0.01)
	assert_float(monitor.WARNING_THRESHOLD).is_equal(0.9)


## Manual Timing API Tests

func test_chunk_generation_timing() -> void:
	"""Test manual chunk generation timing."""
	# Connect to completion signal
	var duration_ms: float = 0.0
	monitor.chunk_generation_completed.connect(func(d): duration_ms = d)

	# Start timing
	monitor.start_chunk_generation()

	# Simulate work (2ms)
	await get_tree().create_timer(0.002).timeout

	# End timing
	monitor.end_chunk_generation()

	# Check duration is approximately 2ms (with tolerance for timer precision)
	assert_float(duration_ms).is_greater(1.0)
	assert_float(duration_ms).is_less(10.0)


func test_collision_generation_timing() -> void:
	"""Test manual collision mesh generation timing."""
	# Connect to completion signal
	var duration_ms: float = 0.0
	monitor.collision_generation_completed.connect(func(d): duration_ms = d)

	# Start timing
	monitor.start_collision_generation()

	# Simulate work (1ms)
	await get_tree().create_timer(0.001).timeout

	# End timing
	monitor.end_collision_generation()

	# Check duration is approximately 1ms
	assert_float(duration_ms).is_greater(0.5)
	assert_float(duration_ms).is_less(5.0)


func test_chunk_count_tracking() -> void:
	"""Test manual chunk count tracking."""
	# Initially zero
	assert_int(monitor._active_chunk_count).is_equal(0)

	# Increment
	monitor.increment_chunk_count()
	assert_int(monitor._active_chunk_count).is_equal(1)
	assert_int(monitor._total_chunks_generated).is_equal(1)

	# Increment again
	monitor.increment_chunk_count()
	assert_int(monitor._active_chunk_count).is_equal(2)
	assert_int(monitor._total_chunks_generated).is_equal(2)

	# Decrement
	monitor.decrement_chunk_count()
	assert_int(monitor._active_chunk_count).is_equal(1)

	# Decrement to zero
	monitor.decrement_chunk_count()
	assert_int(monitor._active_chunk_count).is_equal(0)

	# Decrement below zero (should clamp to 0)
	monitor.decrement_chunk_count()
	assert_int(monitor._active_chunk_count).is_equal(0)


## Warning System Tests

func test_chunk_count_warning_triggers() -> void:
	"""Test that chunk count warning triggers at threshold."""
	# Add chunks up to threshold
	for i in range(monitor.MAX_ACTIVE_CHUNKS + 1):
		monitor.increment_chunk_count()

	# Wait for signal processing
	await get_tree().process_frame

	# Check warning was triggered
	assert_bool(warning_received).is_true()
	assert_str(last_warning_type).is_equal("chunk_count")


func test_chunk_count_warning_clears() -> void:
	"""Test that chunk count warning clears when count drops."""
	# Trigger warning
	for i in range(monitor.MAX_ACTIVE_CHUNKS + 10):
		monitor.increment_chunk_count()

	await get_tree().process_frame
	assert_bool(warning_received).is_true()

	# Reset flags
	warning_received = false
	recovery_received = false

	# Reduce count below threshold
	for i in range(20):
		monitor.decrement_chunk_count()

	await get_tree().process_frame

	# Check recovery was signaled
	assert_bool(recovery_received).is_true()


func test_chunk_generation_warning_triggers() -> void:
	"""Test that chunk generation warning triggers when generation is too slow."""
	# Simulate slow chunk generation (> 5ms threshold)
	monitor.start_chunk_generation()
	await get_tree().create_timer(0.006).timeout  # 6ms
	monitor.end_chunk_generation()

	# Check warning was triggered
	assert_bool(warning_received).is_true()
	assert_str(last_warning_type).is_equal("chunk_generation")


func test_collision_generation_warning_triggers() -> void:
	"""Test that collision generation warning triggers when generation is too slow."""
	# Simulate slow collision generation (> 3ms threshold)
	monitor.start_collision_generation()
	await get_tree().create_timer(0.004).timeout  # 4ms
	monitor.end_collision_generation()

	# Check warning was triggered
	assert_bool(warning_received).is_true()
	assert_str(last_warning_type).is_equal("collision_generation")


## Statistics Tests

func test_get_statistics_returns_complete_data() -> void:
	"""Test that get_statistics returns all expected fields."""
	var stats = monitor.get_statistics()

	# Frame time metrics
	assert_bool(stats.has("target_fps")).is_true()
	assert_bool(stats.has("frame_time_budget_ms")).is_true()
	assert_bool(stats.has("physics_frame_time_ms")).is_true()
	assert_bool(stats.has("render_frame_time_ms")).is_true()

	# Chunk metrics
	assert_bool(stats.has("active_chunk_count")).is_true()
	assert_bool(stats.has("total_chunks_generated")).is_true()
	assert_bool(stats.has("total_chunks_unloaded")).is_true()

	# Generation timing
	assert_bool(stats.has("chunk_generation_avg_ms")).is_true()
	assert_bool(stats.has("collision_generation_avg_ms")).is_true()

	# Memory
	assert_bool(stats.has("voxel_memory_mb")).is_true()
	assert_bool(stats.has("total_memory_mb")).is_true()

	# Warning states
	assert_bool(stats.has("has_warnings")).is_true()
	assert_bool(stats.has("warning_states")).is_true()


func test_statistics_update_with_chunk_operations() -> void:
	"""Test that statistics update when chunks are added/removed."""
	# Add some chunks
	for i in range(10):
		monitor.increment_chunk_count()

	var stats = monitor.get_statistics()
	assert_int(stats.active_chunk_count).is_equal(10)
	assert_int(stats.total_chunks_generated).is_equal(10)

	# Remove some chunks
	for i in range(5):
		monitor.decrement_chunk_count()

	stats = monitor.get_statistics()
	assert_int(stats.active_chunk_count).is_equal(5)


func test_get_performance_report_returns_formatted_string() -> void:
	"""Test that performance report is properly formatted."""
	var report = monitor.get_performance_report()

	# Check for expected sections
	assert_str(report).contains("=== Voxel Performance Report ===")
	assert_str(report).contains("--- Frame Time ---")
	assert_str(report).contains("--- Chunks ---")
	assert_str(report).contains("--- Generation Time ---")
	assert_str(report).contains("--- Memory ---")
	assert_str(report).contains("--- Warnings ---")


## Performance Query Tests

func test_is_performance_acceptable_returns_true_when_no_warnings() -> void:
	"""Test that is_performance_acceptable returns true with no warnings."""
	assert_bool(monitor.is_performance_acceptable()).is_true()


func test_is_performance_acceptable_returns_false_with_warnings() -> void:
	"""Test that is_performance_acceptable returns false with active warnings."""
	# Trigger a warning
	for i in range(monitor.MAX_ACTIVE_CHUNKS + 1):
		monitor.increment_chunk_count()

	await get_tree().process_frame

	# Check performance is not acceptable
	assert_bool(monitor.is_performance_acceptable()).is_false()


func test_get_active_warnings_returns_empty_when_no_warnings() -> void:
	"""Test that get_active_warnings returns empty array with no warnings."""
	var warnings = monitor.get_active_warnings()
	assert_array(warnings).is_empty()


func test_get_active_warnings_returns_warning_types() -> void:
	"""Test that get_active_warnings returns correct warning types."""
	# Trigger chunk count warning
	for i in range(monitor.MAX_ACTIVE_CHUNKS + 1):
		monitor.increment_chunk_count()

	await get_tree().process_frame

	var warnings = monitor.get_active_warnings()
	assert_array(warnings).contains(["chunk_count"])


## Control Tests

func test_set_monitoring_enabled_disables_monitoring() -> void:
	"""Test that monitoring can be disabled."""
	monitor.set_monitoring_enabled(false)
	assert_bool(monitor.is_monitoring_enabled()).is_false()

	# Chunk operations should still work but not trigger frame time monitoring
	monitor.increment_chunk_count()
	assert_int(monitor._active_chunk_count).is_equal(1)


func test_reset_statistics_clears_all_data() -> void:
	"""Test that reset_statistics clears all counters and statistics."""
	# Add some data
	for i in range(10):
		monitor.increment_chunk_count()

	monitor.start_chunk_generation()
	await get_tree().create_timer(0.002).timeout
	monitor.end_chunk_generation()

	# Reset
	monitor.reset_statistics()

	# Verify everything is reset
	assert_int(monitor._active_chunk_count).is_equal(0)
	assert_int(monitor._total_chunks_generated).is_equal(0)
	assert_int(monitor._total_chunks_unloaded).is_equal(0)

	var stats = monitor.get_statistics()
	assert_bool(stats.has_warnings).is_false()


## Frame Time Tracking Tests

func test_physics_process_tracks_frame_time() -> void:
	"""Test that _physics_process tracks frame time."""
	# Let a few physics frames run
	for i in range(10):
		await get_tree().physics_frame

	# Get statistics
	var stats = monitor.get_statistics()

	# Physics frame time should be recorded and non-zero
	assert_float(stats.physics_frame_time_ms).is_greater(0.0)
	assert_float(stats.physics_frame_time_ms).is_less(100.0)  # Sanity check


func test_process_tracks_frame_time() -> void:
	"""Test that _process tracks render frame time."""
	# Let a few render frames run
	for i in range(10):
		await get_tree().process_frame

	# Get statistics
	var stats = monitor.get_statistics()

	# Render frame time should be recorded and non-zero
	assert_float(stats.render_frame_time_ms).is_greater(0.0)
	assert_float(stats.render_frame_time_ms).is_less(100.0)  # Sanity check


## Debug UI Tests

func test_debug_ui_can_be_enabled() -> void:
	"""Test that debug UI can be enabled without errors."""
	monitor.set_debug_ui_enabled(true)

	# Wait for UI creation
	await get_tree().process_frame

	# Check UI was created
	assert_object(monitor._debug_panel).is_not_null()
	assert_object(monitor._debug_label).is_not_null()


func test_debug_ui_can_be_disabled() -> void:
	"""Test that debug UI can be disabled."""
	# Enable first
	monitor.set_debug_ui_enabled(true)
	await get_tree().process_frame

	# Disable
	monitor.set_debug_ui_enabled(false)
	await get_tree().process_frame

	# Check UI was destroyed
	assert_object(monitor._debug_panel).is_null()
	assert_object(monitor._debug_label).is_null()


## Integration Tests

func test_end_generation_without_start_shows_warning() -> void:
	"""Test that calling end without start shows a warning."""
	# This should push a warning but not crash
	monitor.end_chunk_generation()

	# Verify system is still functional
	assert_bool(monitor._is_initialized).is_true()


func test_monitor_handles_rapid_chunk_changes() -> void:
	"""Test that monitor handles rapid chunk add/remove cycles."""
	# Rapidly add and remove chunks
	for cycle in range(100):
		for i in range(10):
			monitor.increment_chunk_count()
		for i in range(10):
			monitor.decrement_chunk_count()

	# Should end at zero
	assert_int(monitor._active_chunk_count).is_equal(0)

	# Total generated should be tracked
	assert_int(monitor._total_chunks_generated).is_equal(1000)


func test_multiple_warnings_can_be_active_simultaneously() -> void:
	"""Test that multiple warning types can be active at once."""
	# Trigger chunk count warning
	for i in range(monitor.MAX_ACTIVE_CHUNKS + 1):
		monitor.increment_chunk_count()

	# Trigger chunk generation warning
	monitor.start_chunk_generation()
	await get_tree().create_timer(0.006).timeout
	monitor.end_chunk_generation()

	# Get active warnings
	var warnings = monitor.get_active_warnings()

	# Both warnings should be active
	assert_array(warnings).contains_exactly(["chunk_count", "chunk_generation"])


## Shutdown Tests

func test_shutdown_cleans_up_resources() -> void:
	"""Test that shutdown properly cleans up resources."""
	# Enable debug UI
	monitor.set_debug_ui_enabled(true)
	await get_tree().process_frame

	# Shutdown
	monitor.shutdown()

	# Check cleanup
	assert_bool(monitor._is_initialized).is_false()
	assert_object(monitor._debug_panel).is_null()
	assert_object(monitor._voxel_terrain).is_null()
