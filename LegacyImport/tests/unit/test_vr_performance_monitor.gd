## Unit tests for VRPerformanceMonitor
## Tests VR-specific performance monitoring, FPS tracking, and integration with VoxelPerformanceMonitor
extends GdUnitTestSuite

## Test setup
var vr_monitor: Node  # VRPerformanceMonitor
var warning_received: bool = false
var recovery_received: bool = false
var frame_dropped_received: bool = false
var last_warning_fps: float = 0.0
var last_dropped_count: int = 0


func before_test() -> void:
	"""Setup before each test."""
	# Load VRPerformanceMonitor script
	var VRMonitorScript = load("res://scripts/vr/vr_performance_monitor.gd")
	vr_monitor = VRMonitorScript.new()
	vr_monitor.name = "TestVRMonitor"
	add_child(vr_monitor)

	# Wait for _ready to complete
	await get_tree().process_frame

	# Connect signals for testing
	vr_monitor.performance_warning.connect(_on_warning)
	vr_monitor.performance_recovered.connect(_on_recovery)
	vr_monitor.frame_dropped.connect(_on_frame_dropped)

	# Reset flags
	warning_received = false
	recovery_received = false
	frame_dropped_received = false
	last_warning_fps = 0.0
	last_dropped_count = 0


func after_test() -> void:
	"""Cleanup after each test."""
	if vr_monitor != null:
		vr_monitor.queue_free()
		vr_monitor = null


func _on_warning(warning_type: String, current_fps: float, target_fps: float) -> void:
	"""Signal handler for warnings."""
	warning_received = true
	last_warning_fps = current_fps


func _on_recovery() -> void:
	"""Signal handler for recovery."""
	recovery_received = true


func _on_frame_dropped(consecutive_drops: int) -> void:
	"""Signal handler for dropped frames."""
	frame_dropped_received = true
	last_dropped_count = consecutive_drops


## Initialization Tests

func test_monitor_initializes_correctly() -> void:
	"""Test that monitor initializes with correct default values."""
	assert_float(vr_monitor._current_fps).is_equal(90.0)
	assert_int(vr_monitor._samples_collected).is_equal(0)
	assert_int(vr_monitor._total_dropped_frames).is_equal(0)
	assert_bool(vr_monitor._is_underperforming).is_false()


func test_constants_match_90fps_target() -> void:
	"""Test that constants are correctly set for 90 FPS VR."""
	assert_float(vr_monitor.TARGET_FPS).is_equal(90.0)
	assert_float(vr_monitor.FRAME_TIME_BUDGET_MS).is_equal_approx(11.11, 0.01)
	assert_float(vr_monitor.FPS_WARNING_THRESHOLD).is_equal(88.0)
	assert_int(vr_monitor.SAMPLE_SIZE).is_equal(90)


func test_frame_time_array_initialized() -> void:
	"""Test that frame time array is properly initialized."""
	assert_int(vr_monitor._frame_times.size()).is_equal(90)

	# All samples should be initialized to budget value
	for i in range(90):
		assert_float(vr_monitor._frame_times[i]).is_equal(11.11)


## FPS Tracking Tests

func test_get_average_fps_initial_value() -> void:
	"""Test that initial average FPS is at target."""
	var fps = vr_monitor.get_average_fps()
	assert_float(fps).is_equal(90.0)


func test_get_frame_time_initial_value() -> void:
	"""Test that initial frame time matches budget."""
	var frame_time = vr_monitor.get_frame_time_ms()
	assert_float(frame_time).is_equal_approx(11.11, 0.01)


func test_check_vr_performance_initially_good() -> void:
	"""Test that VR performance check initially returns true."""
	var is_good = vr_monitor.check_vr_performance()
	assert_bool(is_good).is_true()


## Frame Time Recording Tests

func test_frame_time_recording() -> void:
	"""Test that frame times are recorded correctly."""
	# Simulate good frame time (10ms = 100 FPS)
	vr_monitor._record_frame_time(10.0)

	assert_int(vr_monitor._samples_collected).is_equal(1)
	assert_int(vr_monitor._current_sample_index).is_equal(1)
	assert_float(vr_monitor._frame_times[0]).is_equal(10.0)


func test_rolling_average_calculation() -> void:
	"""Test that rolling average is calculated correctly."""
	# Record several frame times
	for i in range(10):
		vr_monitor._record_frame_time(10.0)  # 10ms = 100 FPS

	# Update FPS metrics
	vr_monitor._update_fps_metrics()

	# Average should be close to 10ms, giving ~100 FPS
	var avg_fps = vr_monitor.get_average_fps()
	assert_float(avg_fps).is_greater(95.0)
	assert_float(avg_fps).is_less(105.0)


func test_rolling_buffer_wraps_correctly() -> void:
	"""Test that rolling buffer wraps around after SAMPLE_SIZE samples."""
	# Record more than SAMPLE_SIZE samples
	for i in range(100):
		vr_monitor._record_frame_time(10.0)

	# Samples collected should be capped at SAMPLE_SIZE
	assert_int(vr_monitor._samples_collected).is_equal(90)

	# Current index should have wrapped around
	assert_int(vr_monitor._current_sample_index).is_equal(10)  # 100 % 90 = 10


## Dropped Frame Detection Tests

func test_dropped_frame_detection() -> void:
	"""Test that dropped frames are detected when frame time > 2x budget."""
	# Simulate dropped frame (25ms > 22.22ms threshold)
	vr_monitor._check_dropped_frames(25.0)

	assert_bool(frame_dropped_received).is_true()
	assert_int(vr_monitor._total_dropped_frames).is_equal(1)
	assert_int(vr_monitor._consecutive_dropped_frames).is_equal(1)
	assert_int(last_dropped_count).is_equal(1)


func test_consecutive_dropped_frames() -> void:
	"""Test that consecutive dropped frames are tracked correctly."""
	# Simulate 3 consecutive dropped frames
	for i in range(3):
		vr_monitor._check_dropped_frames(25.0)

	assert_int(vr_monitor._total_dropped_frames).is_equal(3)
	assert_int(vr_monitor._consecutive_dropped_frames).is_equal(3)


func test_dropped_frame_reset() -> void:
	"""Test that consecutive counter resets after good frame."""
	# Dropped frame
	vr_monitor._check_dropped_frames(25.0)
	assert_int(vr_monitor._consecutive_dropped_frames).is_equal(1)

	# Good frame
	vr_monitor._check_dropped_frames(10.0)
	assert_int(vr_monitor._consecutive_dropped_frames).is_equal(0)

	# Total count should still be 1
	assert_int(vr_monitor._total_dropped_frames).is_equal(1)


## Performance Threshold Tests

func test_performance_warning_triggered_on_low_fps() -> void:
	"""Test that performance warning is triggered when FPS drops below threshold."""
	# Simulate low FPS frames (20ms = 50 FPS, below 88 FPS threshold)
	for i in range(15):  # Need 10 consecutive low frames to trigger warning
		vr_monitor._record_frame_time(20.0)
		vr_monitor._update_fps_metrics()
		vr_monitor._check_performance_thresholds()
		await get_tree().process_frame

	assert_bool(warning_received).is_true()
	assert_bool(vr_monitor._is_underperforming).is_true()


func test_performance_recovery_signal() -> void:
	"""Test that recovery signal is emitted when performance improves."""
	# First trigger warning by simulating low FPS
	for i in range(15):
		vr_monitor._record_frame_time(20.0)
		vr_monitor._update_fps_metrics()
		vr_monitor._check_performance_thresholds()

	assert_bool(vr_monitor._is_underperforming).is_true()

	# Now simulate good FPS recovery (10ms = 100 FPS)
	for i in range(10):
		vr_monitor._record_frame_time(10.0)
		vr_monitor._update_fps_metrics()
		vr_monitor._check_performance_thresholds()

	assert_bool(recovery_received).is_true()
	assert_bool(vr_monitor._is_underperforming).is_false()


## Statistics Tests

func test_get_statistics_returns_complete_data() -> void:
	"""Test that get_statistics returns all expected fields."""
	var stats = vr_monitor.get_statistics()

	# Check required fields exist
	assert_bool(stats.has("target_fps")).is_true()
	assert_bool(stats.has("current_fps")).is_true()
	assert_bool(stats.has("average_frame_time_ms")).is_true()
	assert_bool(stats.has("total_dropped_frames")).is_true()
	assert_bool(stats.has("is_meeting_target")).is_true()
	assert_bool(stats.has("xr_interface_active")).is_true()
	assert_bool(stats.has("uptime_seconds")).is_true()


func test_statistics_values_are_correct() -> void:
	"""Test that statistics contain correct values."""
	# Record some frames
	for i in range(10):
		vr_monitor._record_frame_time(10.0)
	vr_monitor._update_fps_metrics()

	var stats = vr_monitor.get_statistics()

	assert_float(stats.target_fps).is_equal(90.0)
	assert_float(stats.current_fps).is_greater(95.0)  # Should be ~100 FPS with 10ms frames
	assert_bool(stats.is_meeting_target).is_true()
	assert_int(stats.total_dropped_frames).is_equal(0)


## Performance Report Tests

func test_get_performance_report_generates_string() -> void:
	"""Test that performance report generates a non-empty string."""
	var report = vr_monitor.get_performance_report()

	assert_bool(report.length() > 0).is_true()
	assert_bool(report.contains("VR Performance Report")).is_true()
	assert_bool(report.contains("FPS Status")).is_true()
	assert_bool(report.contains("Frame Time")).is_true()


func test_performance_report_shows_good_status() -> void:
	"""Test that performance report shows GOOD status when meeting target."""
	var report = vr_monitor.get_performance_report()

	assert_bool(report.contains("GOOD")).is_true()
	assert_bool(report.contains("[OK]")).is_true()


func test_performance_report_shows_underperforming_status() -> void:
	"""Test that performance report shows underperforming status when below threshold."""
	# Trigger underperformance
	for i in range(15):
		vr_monitor._record_frame_time(20.0)
		vr_monitor._update_fps_metrics()
		vr_monitor._check_performance_thresholds()

	var report = vr_monitor.get_performance_report()

	assert_bool(report.contains("UNDERPERFORMING")).is_true()
	assert_bool(report.contains("[!!]")).is_true()


## Reset Tests

func test_reset_statistics() -> void:
	"""Test that reset_statistics clears all counters."""
	# Generate some data
	for i in range(20):
		vr_monitor._record_frame_time(10.0)
	vr_monitor._check_dropped_frames(25.0)  # Trigger dropped frame

	assert_int(vr_monitor._samples_collected).is_greater(0)
	assert_int(vr_monitor._total_dropped_frames).is_equal(1)

	# Reset
	vr_monitor.reset_statistics()

	assert_int(vr_monitor._samples_collected).is_equal(0)
	assert_int(vr_monitor._total_dropped_frames).is_equal(0)
	assert_int(vr_monitor._consecutive_dropped_frames).is_equal(0)
	assert_bool(vr_monitor._is_underperforming).is_false()


## Integration Tests

func test_voxel_monitor_integration_attempt() -> void:
	"""Test that VR monitor attempts to connect to VoxelPerformanceMonitor."""
	# VoxelPerformanceMonitor may or may not be available as autoload
	# Just verify the connection attempt doesn't crash
	var voxel_ref = vr_monitor.get_voxel_monitor()

	# Reference may be null if autoload not available in test environment
	# This is expected behavior - monitor should handle gracefully
	if voxel_ref != null:
		assert_bool(vr_monitor._voxel_monitor_connected).is_true()
	else:
		# Should be false or disconnected
		assert_bool(vr_monitor._voxel_monitor_connected).is_false()


## Console Reporting Tests

func test_console_reporting_can_be_enabled() -> void:
	"""Test that console reporting can be enabled without errors."""
	vr_monitor.set_console_reporting_enabled(true, 1.0)
	assert_bool(vr_monitor._console_reporting_enabled).is_true()
	assert_float(vr_monitor._console_report_interval_sec).is_equal(1.0)


func test_console_reporting_can_be_disabled() -> void:
	"""Test that console reporting can be disabled."""
	vr_monitor.set_console_reporting_enabled(true, 1.0)
	vr_monitor.set_console_reporting_enabled(false)
	assert_bool(vr_monitor._console_reporting_enabled).is_false()


func test_print_current_stats_runs_without_error() -> void:
	"""Test that print_current_stats executes without crashing."""
	# Just verify it doesn't crash
	vr_monitor.print_current_stats()
	# If we get here, it didn't crash
	assert_bool(true).is_true()


## Edge Case Tests

func test_handles_zero_frame_time() -> void:
	"""Test that monitor handles zero frame time gracefully."""
	vr_monitor._record_frame_time(0.0)
	vr_monitor._update_fps_metrics()

	# Should not crash and should have valid FPS
	var fps = vr_monitor.get_average_fps()
	assert_float(fps).is_greater(0.0)


func test_handles_extremely_high_frame_time() -> void:
	"""Test that monitor handles extremely high frame time."""
	vr_monitor._record_frame_time(1000.0)  # 1 second frame time
	vr_monitor._update_fps_metrics()

	# Should detect as dropped frame
	vr_monitor._check_dropped_frames(1000.0)
	assert_int(vr_monitor._total_dropped_frames).is_equal(1)


func test_max_min_frame_time_tracking() -> void:
	"""Test that max and min frame times are tracked correctly."""
	# Record variety of frame times
	vr_monitor._record_frame_time(5.0)   # Min
	vr_monitor._record_frame_time(10.0)
	vr_monitor._record_frame_time(15.0)  # Max
	vr_monitor._record_frame_time(10.0)

	vr_monitor._update_fps_metrics()

	assert_float(vr_monitor._min_frame_time_ms).is_equal(5.0)
	assert_float(vr_monitor._max_frame_time_ms).is_equal(15.0)
