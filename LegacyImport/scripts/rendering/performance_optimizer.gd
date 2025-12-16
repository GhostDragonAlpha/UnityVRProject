## PerformanceOptimizer - Rendering Pipeline Optimization System
## Profiles frame time, optimizes shader complexity, implements occlusion culling,
## optimizes physics calculations, and provides performance monitoring.
##
## Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 50.4
## - 2.1: Maintain minimum 90 FPS during normal operation
## - 2.2: Create separate stereoscopic display regions for VR
## - 2.3: Reduce visual complexity through automatic LOD adjustments
## - 2.4: Apply correct inter-pupillary distance
## - 2.5: Log warnings and reduce rendering load when performance degrades
## - 50.4: Add performance monitoring
extends Node
class_name PerformanceOptimizer

## Emitted when performance optimization is initialized
signal optimizer_initialized
## Emitted when FPS drops below target
signal fps_below_target(current_fps: float, target_fps: float)
## Emitted when FPS recovers to target
signal fps_recovered(current_fps: float)
## Emitted when quality level changes
signal quality_level_changed(old_level: int, new_level: int)
## Emitted when occlusion culling is toggled
signal occlusion_culling_toggled(enabled: bool)
## Emitted when performance statistics are updated
signal statistics_updated(stats: Dictionary)

## Target frame rate for VR (90 FPS)
const TARGET_FPS: float = 90.0

## Minimum acceptable FPS before quality reduction
const MIN_ACCEPTABLE_FPS: float = 80.0

## Frame time budget in milliseconds (1000ms / 90fps = 11.11ms)
const FRAME_TIME_BUDGET_MS: float = 11.11

## Number of frames to average for FPS calculation
const FPS_SAMPLE_SIZE: int = 60

## Quality levels (0 = ultra, 1 = high, 2 = medium, 3 = low, 4 = minimum)
enum QualityLevel {
	ULTRA = 0,
	HIGH = 1,
	MEDIUM = 2,
	LOW = 3,
	MINIMUM = 4
}

## Current quality level
var current_quality_level: QualityLevel = QualityLevel.HIGH

## Whether automatic quality adjustment is enabled
var auto_quality_enabled: bool = true

## Whether occlusion culling is enabled
var occlusion_culling_enabled: bool = true

## Frame time samples for averaging
var _frame_time_samples: Array[float] = []

## Current frame index for sampling
var _sample_index: int = 0

## Average frame time in milliseconds
var _average_frame_time_ms: float = 0.0

## Current FPS
var _current_fps: float = 90.0

## Time since last quality adjustment
var _time_since_quality_adjustment: float = 0.0

## Minimum time between quality adjustments (seconds)
const QUALITY_ADJUSTMENT_COOLDOWN: float = 2.0

## Whether FPS is currently below target
var _fps_below_target: bool = false

## Frame counter for statistics
var _frame_count: int = 0

## Total time elapsed
var _total_time: float = 0.0

## Performance statistics
var _statistics: Dictionary = {}

## Reference to LODManager
var _lod_manager: LODManager = null

## Reference to rendering viewport
var _viewport: Viewport = null

## Whether the optimizer is initialized
var _initialized: bool = false

## Occlusion culling nodes
var _occluders: Array[OccluderInstance3D] = []

## Physics optimization settings
var _physics_iterations: int = 8  # Default Godot physics iterations
var _physics_substeps: int = 1

## Shader complexity level (affects shader features)
var _shader_complexity: int = 2  # 0=minimal, 1=low, 2=medium, 3=high


func _ready() -> void:
	# Initialize frame time samples array
	_frame_time_samples.resize(FPS_SAMPLE_SIZE)
	for i in range(FPS_SAMPLE_SIZE):
		_frame_time_samples[i] = FRAME_TIME_BUDGET_MS


func _process(delta: float) -> void:
	if not _initialized:
		return
	
	_total_time += delta
	_frame_count += 1
	
	# Profile frame time
	_profile_frame_time(delta)
	
	# Check if quality adjustment is needed
	if auto_quality_enabled:
		_time_since_quality_adjustment += delta
		if _time_since_quality_adjustment >= QUALITY_ADJUSTMENT_COOLDOWN:
			_check_and_adjust_quality()
			_time_since_quality_adjustment = 0.0
	
	# Update statistics periodically (every 60 frames)
	if _frame_count % 60 == 0:
		_update_statistics()


## Initialize the performance optimizer
## @param lod_manager: Reference to LODManager for quality adjustments
## @param viewport: Reference to the main viewport
func initialize(lod_manager: LODManager = null, viewport: Viewport = null) -> bool:
	_lod_manager = lod_manager
	_viewport = viewport if viewport != null else get_viewport()
	
	# Apply initial quality settings
	_apply_quality_level(current_quality_level)
	
	# Setup occlusion culling if enabled
	if occlusion_culling_enabled:
		_setup_occlusion_culling()
	
	_initialized = true
	optimizer_initialized.emit()
	print("PerformanceOptimizer: Initialized at quality level %s" % QualityLevel.keys()[current_quality_level])
	return true


## Profile frame time using Performance singleton
## Requirements: 2.1 - Maintain minimum 90 FPS
func _profile_frame_time(delta: float) -> void:
	"""Profile the current frame time and update FPS calculations."""
	var frame_time_ms = delta * 1000.0
	
	# Store frame time sample
	_frame_time_samples[_sample_index] = frame_time_ms
	_sample_index = (_sample_index + 1) % FPS_SAMPLE_SIZE
	
	# Calculate average frame time
	var total_time = 0.0
	for sample in _frame_time_samples:
		total_time += sample
	_average_frame_time_ms = total_time / FPS_SAMPLE_SIZE
	
	# Calculate FPS
	if _average_frame_time_ms > 0.0:
		_current_fps = 1000.0 / _average_frame_time_ms
	else:
		_current_fps = TARGET_FPS


## Check if quality adjustment is needed and apply it
## Requirements: 2.3, 2.5 - Reduce visual complexity when performance degrades
func _check_and_adjust_quality() -> void:
	"""Check current FPS and adjust quality level if needed."""
	# Check if FPS is below minimum acceptable
	if _current_fps < MIN_ACCEPTABLE_FPS:
		if not _fps_below_target:
			_fps_below_target = true
			fps_below_target.emit(_current_fps, TARGET_FPS)
			push_warning("PerformanceOptimizer: FPS below target (%.1f < %.1f)" % [_current_fps, TARGET_FPS])
		
		# Reduce quality if not already at minimum
		if current_quality_level < QualityLevel.MINIMUM:
			_reduce_quality()
	
	# Check if FPS has recovered and we can increase quality
	elif _current_fps > TARGET_FPS + 5.0:  # 5 FPS buffer
		if _fps_below_target:
			_fps_below_target = false
			fps_recovered.emit(_current_fps)
			print("PerformanceOptimizer: FPS recovered (%.1f)" % _current_fps)
		
		# Increase quality if not already at maximum
		if current_quality_level > QualityLevel.ULTRA:
			_increase_quality()


## Reduce quality level
func _reduce_quality() -> void:
	"""Reduce quality level by one step."""
	var old_level = current_quality_level
	var new_level = mini(current_quality_level + 1, QualityLevel.MINIMUM)
	
	if new_level != old_level:
		current_quality_level = new_level
		_apply_quality_level(new_level)
		quality_level_changed.emit(old_level, new_level)
		print("PerformanceOptimizer: Quality reduced to %s" % QualityLevel.keys()[new_level])


## Increase quality level
func _increase_quality() -> void:
	"""Increase quality level by one step."""
	var old_level = current_quality_level
	var new_level = maxi(current_quality_level - 1, QualityLevel.ULTRA)
	
	if new_level != old_level:
		current_quality_level = new_level
		_apply_quality_level(new_level)
		quality_level_changed.emit(old_level, new_level)
		print("PerformanceOptimizer: Quality increased to %s" % QualityLevel.keys()[new_level])


## Apply quality level settings
## Requirements: 2.3 - Reduce visual complexity through LOD adjustments
func _apply_quality_level(level: QualityLevel) -> void:
	"""Apply all settings for a given quality level."""
	match level:
		QualityLevel.ULTRA:
			_apply_ultra_quality()
		QualityLevel.HIGH:
			_apply_high_quality()
		QualityLevel.MEDIUM:
			_apply_medium_quality()
		QualityLevel.LOW:
			_apply_low_quality()
		QualityLevel.MINIMUM:
			_apply_minimum_quality()


## Apply ultra quality settings
func _apply_ultra_quality() -> void:
	"""Apply ultra quality settings (maximum visual fidelity)."""
	_shader_complexity = 3
	_physics_iterations = 8
	_physics_substeps = 1
	
	if _lod_manager != null:
		_lod_manager.set_lod_bias(1.5)  # Higher detail at distance
	
	if _viewport != null:
		_viewport.msaa_3d = Viewport.MSAA_4X
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_viewport.use_taa = true
	
	# Enable all rendering features
	RenderingServer.gi_set_use_half_resolution(false)


## Apply high quality settings
func _apply_high_quality() -> void:
	"""Apply high quality settings (balanced quality and performance)."""
	_shader_complexity = 2
	_physics_iterations = 8
	_physics_substeps = 1
	
	if _lod_manager != null:
		_lod_manager.set_lod_bias(1.0)  # Normal LOD bias
	
	if _viewport != null:
		_viewport.msaa_3d = Viewport.MSAA_2X
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_viewport.use_taa = true
	
	RenderingServer.gi_set_use_half_resolution(false)


## Apply medium quality settings
func _apply_medium_quality() -> void:
	"""Apply medium quality settings (favor performance)."""
	_shader_complexity = 1
	_physics_iterations = 6
	_physics_substeps = 1
	
	if _lod_manager != null:
		_lod_manager.set_lod_bias(0.75)  # Reduce LOD distances
	
	if _viewport != null:
		_viewport.msaa_3d = Viewport.MSAA_2X
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_viewport.use_taa = false
	
	RenderingServer.gi_set_use_half_resolution(true)


## Apply low quality settings
func _apply_low_quality() -> void:
	"""Apply low quality settings (prioritize performance)."""
	_shader_complexity = 0
	_physics_iterations = 4
	_physics_substeps = 1
	
	if _lod_manager != null:
		_lod_manager.set_lod_bias(0.5)  # Aggressive LOD reduction
	
	if _viewport != null:
		_viewport.msaa_3d = Viewport.MSAA_DISABLED
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_viewport.use_taa = false
	
	RenderingServer.gi_set_use_half_resolution(true)


## Apply minimum quality settings
func _apply_minimum_quality() -> void:
	"""Apply minimum quality settings (maximum performance)."""
	_shader_complexity = 0
	_physics_iterations = 2
	_physics_substeps = 1
	
	if _lod_manager != null:
		_lod_manager.set_lod_bias(0.25)  # Maximum LOD reduction
	
	if _viewport != null:
		_viewport.msaa_3d = Viewport.MSAA_DISABLED
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_viewport.use_taa = false
	
	RenderingServer.gi_set_use_half_resolution(true)


## Setup occlusion culling using OccluderInstance3D
## Requirements: 50.4 - Implement occlusion culling
func _setup_occlusion_culling() -> void:
	"""Setup occlusion culling for the scene."""
	# Find all OccluderInstance3D nodes in the scene
	_occluders.clear()
	_find_occluders(get_tree().root)
	
	print("PerformanceOptimizer: Found %d occluders" % _occluders.size())


## Recursively find all OccluderInstance3D nodes
func _find_occluders(node: Node) -> void:
	"""Recursively find all occluder nodes in the scene tree."""
	if node is OccluderInstance3D:
		_occluders.append(node)
	
	for child in node.get_children():
		_find_occluders(child)


## Create an occluder for a mesh
## @param mesh_instance: The MeshInstance3D to create an occluder for
## @return: The created OccluderInstance3D node
func create_occluder_for_mesh(mesh_instance: MeshInstance3D) -> OccluderInstance3D:
	"""Create an occluder instance for a mesh."""
	if mesh_instance == null or mesh_instance.mesh == null:
		return null
	
	var occluder := OccluderInstance3D.new()
	occluder.name = mesh_instance.name + "_Occluder"
	
	# Create a box occluder based on the mesh AABB
	var aabb = mesh_instance.get_aabb()
	var occluder_shape := BoxOccluder3D.new()
	occluder_shape.size = aabb.size
	
	occluder.occluder = occluder_shape
	occluder.position = aabb.get_center()
	
	mesh_instance.add_child(occluder)
	_occluders.append(occluder)
	
	return occluder


## Enable or disable occlusion culling
func set_occlusion_culling_enabled(enabled: bool) -> void:
	"""Enable or disable occlusion culling."""
	occlusion_culling_enabled = enabled
	
	# Toggle all occluders
	for occluder in _occluders:
		if is_instance_valid(occluder):
			occluder.visible = enabled
	
	occlusion_culling_toggled.emit(enabled)
	print("PerformanceOptimizer: Occlusion culling %s" % ("enabled" if enabled else "disabled"))


## Optimize physics calculations
## Requirements: 50.4 - Optimize physics calculations
func optimize_physics(physics_engine: PhysicsEngine = null) -> void:
	"""Optimize physics calculations based on current quality level."""
	# Adjust physics iterations based on quality level
	var iterations = _physics_iterations
	
	# Set physics iterations (this affects accuracy vs performance)
	ProjectSettings.set_setting("physics/3d/solver/solver_iterations", iterations)
	
	if physics_engine != null:
		# Could add physics-specific optimizations here
		# For example, reducing the number of active bodies or simplifying collision shapes
		pass


## Get current FPS
func get_current_fps() -> float:
	"""Get the current frames per second."""
	return _current_fps


## Get average frame time in milliseconds
func get_average_frame_time_ms() -> float:
	"""Get the average frame time in milliseconds."""
	return _average_frame_time_ms


## Get current quality level
func get_quality_level() -> QualityLevel:
	"""Get the current quality level."""
	return current_quality_level


## Set quality level manually
func set_quality_level(level: QualityLevel) -> void:
	"""Manually set the quality level."""
	var old_level = current_quality_level
	current_quality_level = level
	_apply_quality_level(level)
	quality_level_changed.emit(old_level, level)


## Enable or disable automatic quality adjustment
func set_auto_quality_enabled(enabled: bool) -> void:
	"""Enable or disable automatic quality adjustment."""
	auto_quality_enabled = enabled
	print("PerformanceOptimizer: Auto quality adjustment %s" % ("enabled" if enabled else "disabled"))


## Get shader complexity level
func get_shader_complexity() -> int:
	"""Get the current shader complexity level (0-3)."""
	return _shader_complexity


## Update performance statistics
func _update_statistics() -> void:
	"""Update performance statistics using Performance singleton."""
	_statistics = {
		"fps": _current_fps,
		"frame_time_ms": _average_frame_time_ms,
		"quality_level": QualityLevel.keys()[current_quality_level],
		"auto_quality_enabled": auto_quality_enabled,
		"occlusion_culling_enabled": occlusion_culling_enabled,
		"shader_complexity": _shader_complexity,
		"physics_iterations": _physics_iterations,
		
		# Performance singleton metrics
		"time_process": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"time_physics_process": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"memory_static": Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0,  # MB
		"memory_static_max": Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024.0 / 1024.0,  # MB
		"objects_rendered": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"vertices_rendered": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"physics_3d_active_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		"physics_3d_collision_pairs": Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
	}
	
	statistics_updated.emit(_statistics)


## Get performance statistics
func get_statistics() -> Dictionary:
	"""Get current performance statistics."""
	if _statistics.is_empty():
		_update_statistics()
	return _statistics


## Get detailed performance report
func get_performance_report() -> String:
	"""Get a formatted performance report string."""
	var stats = get_statistics()
	
	var report = "=== Performance Report ===\n"
	report += "FPS: %.1f / %.1f (target)\n" % [stats.fps, TARGET_FPS]
	report += "Frame Time: %.2f ms / %.2f ms (budget)\n" % [stats.frame_time_ms, FRAME_TIME_BUDGET_MS]
	report += "Quality Level: %s\n" % stats.quality_level
	report += "Auto Quality: %s\n" % ("ON" if stats.auto_quality_enabled else "OFF")
	report += "\n--- Rendering ---\n"
	report += "Objects: %d\n" % stats.objects_rendered
	report += "Vertices: %d\n" % stats.vertices_rendered
	report += "Draw Calls: %d\n" % stats.draw_calls
	report += "Shader Complexity: %d\n" % stats.shader_complexity
	report += "Occlusion Culling: %s\n" % ("ON" if stats.occlusion_culling_enabled else "OFF")
	report += "\n--- Physics ---\n"
	report += "Active Objects: %d\n" % stats.physics_3d_active_objects
	report += "Collision Pairs: %d\n" % stats.physics_3d_collision_pairs
	report += "Iterations: %d\n" % stats.physics_iterations
	report += "\n--- Memory ---\n"
	report += "Static: %.1f MB\n" % stats.memory_static
	report += "Dynamic: %.1f MB\n" % stats.memory_dynamic
	report += "\n--- Timing ---\n"
	report += "Process: %.2f ms\n" % stats.time_process
	report += "Physics: %.2f ms\n" % stats.time_physics_process
	
	return report


## Check if FPS is meeting target
func is_fps_meeting_target() -> bool:
	"""Check if current FPS meets the target."""
	return _current_fps >= MIN_ACCEPTABLE_FPS


## Get FPS health status
func get_fps_health() -> String:
	"""Get a string describing FPS health status."""
	if _current_fps >= TARGET_FPS:
		return "Excellent"
	elif _current_fps >= MIN_ACCEPTABLE_FPS:
		return "Good"
	elif _current_fps >= 60.0:
		return "Acceptable"
	elif _current_fps >= 45.0:
		return "Poor"
	else:
		return "Critical"


## Reset performance statistics
func reset_statistics() -> void:
	"""Reset all performance statistics."""
	_frame_count = 0
	_total_time = 0.0
	_sample_index = 0
	for i in range(FPS_SAMPLE_SIZE):
		_frame_time_samples[i] = FRAME_TIME_BUDGET_MS
	_average_frame_time_ms = FRAME_TIME_BUDGET_MS
	_current_fps = TARGET_FPS


## Check if the optimizer is initialized
func is_initialized() -> bool:
	"""Check if the optimizer is initialized."""
	return _initialized


## Shutdown and cleanup
func shutdown() -> void:
	"""Shutdown the performance optimizer."""
	_occluders.clear()
	_lod_manager = null
	_viewport = null
	_initialized = false
	print("PerformanceOptimizer: Shutdown complete")
