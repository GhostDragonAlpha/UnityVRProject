## ResonanceEngine - Core Engine Coordinator
## Main autoload singleton that initializes and manages all subsystems.
## This is the central coordinator for Project Resonance.
##
## Requirements: 1.5 - Initialize main scene with 90 FPS target frame rate
## ResonanceEngine - Core Engine Coordinator
## Main autoload singleton that initializes and manages all subsystems.
## This is the central coordinator for Project Resonance.
##
## Requirements: 1.5 - Initialize main scene with 90 FPS target frame rate
extends Node

## Emitted when all subsystems have been initialized
signal subsystems_initialized
## Emitted when a subsystem fails to initialize
signal subsystem_init_failed(subsystem_name: String, error: String)
## Emitted when the engine is shutting down
signal engine_shutting_down
## Emitted when the engine has completed shutdown
signal engine_shutdown_complete

## Engine version for save file compatibility
const ENGINE_VERSION := "0.1.0"
## Target frame rate for VR (90 FPS per eye)
const TARGET_FPS := 90

## Subsystem references - will be populated as subsystems are implemented
var vr_manager: Node = null
var vr_comfort_system: Node = null
var haptic_manager: Node = null
var floating_origin: Node = null
var relativity: Node = null
var physics_engine: Node = null
var time_manager: Node = null
var renderer: Node = null
var audio_manager: Node = null
var fractal_zoom: Node = null
var capture_event_system: Node = null
var save_system: Node = null
var settings_manager: Node = null
var performance_optimizer: Node = null

## Engine state
var _is_initialized := false
var _is_shutting_down := false
var _frame_count := 0
var _accumulated_time := 0.0
var _last_fps := 0.0

## Logging configuration
var _log_level := LogLevel.INFO
var _log_to_file := false
var _log_file: FileAccess = null

## Log levels for filtering messages
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3
}

## Launch arguments
var _force_vr_mode := false
var _force_desktop_mode := false

func _ready() -> void:
	log_info("ResonanceEngine initializing...")
	log_debug("=== DIAGNOSTIC: Engine.gd _ready() called ===")
	
	# Parse command line arguments
	_parse_launch_arguments()
	
	_initialize_engine()

func _parse_launch_arguments() -> void:
	"""Parse command line arguments for launch configuration."""
	var args = OS.get_cmdline_args()
	log_info("Launch arguments: %s" % str(args))
	
	if "--vr" in args or "--force-vr" in args:
		_force_vr_mode = true
		log_info("Launch Flag: Forcing VR Mode")
	
	if "--desktop" in args or "--no-vr" in args:
		_force_desktop_mode = true
		log_info("Launch Flag: Forcing Desktop Mode")



func _initialize_engine() -> void:
	"""Initialize all engine subsystems in the correct order."""

	# Set target FPS for the engine
	Engine.max_fps = TARGET_FPS
	log_info("Target FPS set to %d" % TARGET_FPS)

	# Initialize subsystems in dependency order
	var init_success := true

	# CRITICAL FIX: Add dependency validation during initialization
	# Phase 1: Core systems (no dependencies)
	init_success = init_success and _init_subsystem("TimeManager", _init_time_manager, [])
	init_success = init_success and _init_subsystem("RelativityManager", _init_relativity, [])

	# Phase 2: Systems that depend on core
	init_success = init_success and _init_subsystem("FloatingOrigin", _init_floating_origin, [])
	init_success = init_success and _init_subsystem("PhysicsEngine", _init_physics_engine, [])

	# Phase 3: VR and rendering (depends on physics)
	init_success = init_success and _init_subsystem("VRManager", _init_vr_manager, [])
	init_success = init_success and _init_subsystem("VRComfortSystem", _init_vr_comfort_system, ["VRManager"])
	init_success = init_success and _init_subsystem("HapticManager", _init_haptic_manager, ["VRManager"])
	init_success = init_success and _init_subsystem("Renderer", _init_renderer, [])

	# Phase 4: Performance optimization (depends on renderer)
	init_success = init_success and _init_subsystem("PerformanceOptimizer", _init_performance_optimizer, ["Renderer"])

	# Phase 5: Audio (depends on VR for spatial audio)
	init_success = init_success and _init_subsystem("AudioManager", _init_audio_manager, ["VRManager"])

	# Phase 6: Advanced features
	init_success = init_success and _init_subsystem("FractalZoom", _init_fractal_zoom, [])
	init_success = init_success and _init_subsystem("CaptureEventSystem", _init_capture_event_system, [])

	# Phase 7: Persistence
	init_success = init_success and _init_subsystem("SettingsManager", _init_settings_manager, [])
	init_success = init_success and _init_subsystem("SaveSystem", _init_save_system, [])

	if init_success:
		_is_initialized = true
		log_info("ResonanceEngine initialization complete")
		subsystems_initialized.emit()
	else:
		log_error("ResonanceEngine initialization failed - some subsystems could not be initialized")


func _init_subsystem(name: String, init_callable: Callable, dependencies: Array = []) -> bool:
	"""Helper to initialize a subsystem with error handling and dependency validation."""
	log_debug("Initializing subsystem: %s" % name)

	# CRITICAL FIX: Validate dependencies before initialization
	for dep_name in dependencies:
		if not _is_subsystem_initialized(dep_name):
			log_error("Subsystem %s cannot initialize: dependency %s not ready" % [name, dep_name])
			subsystem_init_failed.emit(name, "Missing dependency: " + dep_name)
			return false

	var result = init_callable.call()
	if result:
		log_info("Subsystem initialized: %s" % name)
	else:
		log_warning("Subsystem not available: %s (will be initialized when implemented)" % name)
		subsystem_init_failed.emit(name, "Subsystem not yet implemented")

	# Return true even if subsystem isn't available yet - we allow partial initialization
	return true


func _is_subsystem_initialized(name: String) -> bool:
	"""Check if a subsystem has been initialized and is available."""
	match name:
		"VRManager":
			return vr_manager != null
		"VRComfortSystem":
			return vr_comfort_system != null
		"HapticManager":
			return haptic_manager != null
		"FloatingOrigin":
			return floating_origin != null
		"Relativity":
			return relativity != null
		"PhysicsEngine":
			return physics_engine != null
		"TimeManager":
			return time_manager != null
		"Renderer":
			return renderer != null
		"AudioManager":
			return audio_manager != null
		"FractalZoom":
			return fractal_zoom != null
		"CaptureEventSystem":
			return capture_event_system != null
		"SaveSystem":
			return save_system != null
		"SettingsManager":
			return settings_manager != null
		"PerformanceOptimizer":
			return performance_optimizer != null
		_:
			log_warning("Unknown subsystem name in dependency check: %s" % name)
			return false


func _init_time_manager() -> bool:
	"""Initialize the time management subsystem."""
	# Create TimeManager instance
	var TimeManagerScript = load("res://scripts/core/time_manager.gd")
	var time_mgr = TimeManagerScript.new()
	time_mgr.name = "TimeManager"
	add_child(time_mgr)
	
	time_manager = time_mgr
	register_subsystem("TimeManager", time_mgr)
	
	log_info("TimeManager initialized")
	return true


func _init_relativity() -> bool:
	"""Initialize the relativity manager subsystem."""
	# Create RelativityManager instance
	var RelativityManagerScript = load("res://scripts/core/relativity.gd")
	var relativity_mgr = RelativityManagerScript.new()
	relativity_mgr.name = "RelativityManager"
	add_child(relativity_mgr)
	
	relativity = relativity_mgr
	register_subsystem("Relativity", relativity_mgr)
	
	log_info("RelativityManager initialized")
	return true


func _init_floating_origin() -> bool:
	"""Initialize the floating origin subsystem."""
	# Create FloatingOriginSystem instance
	var FloatingOriginSystemScript = load("res://scripts/core/floating_origin.gd")
	var floating_origin_system = FloatingOriginSystemScript.new()
	floating_origin_system.name = "FloatingOriginSystem"
	add_child(floating_origin_system)
	
	# The system will be fully initialized when a player node is set
	# For now, just register it with the engine
	floating_origin = floating_origin_system
	register_subsystem("FloatingOrigin", floating_origin_system)
	
	log_info("FloatingOriginSystem created - awaiting player node assignment")
	return true


func _init_physics_engine() -> bool:
	"""Initialize the physics engine subsystem."""
	# Create PhysicsEngine instance
	var PhysicsEngineScript = load("res://scripts/core/physics_engine.gd")
	var physics_eng = PhysicsEngineScript.new()
	physics_eng.name = "PhysicsEngine"
	add_child(physics_eng)
	
	physics_engine = physics_eng
	register_subsystem("PhysicsEngine", physics_eng)
	
	log_info("PhysicsEngine initialized")
	return true


func _init_vr_manager() -> bool:
	"""Initialize the VR manager subsystem."""
	# Create VRManager instance
	var VRManagerScript = load("res://scripts/core/vr_manager.gd")
	var vr_mgr = VRManagerScript.new()
	vr_mgr.name = "VRManager"
	add_child(vr_mgr)
	
	# Initialize VR (will fall back to desktop if VR unavailable)
	# Respect launch flags
	var force_desktop = _force_desktop_mode
	var force_vr = _force_vr_mode
	
	if vr_mgr.initialize_vr(force_vr, force_desktop):
		vr_manager = vr_mgr
		register_subsystem("VRManager", vr_mgr)
		return true
	
	# Cleanup on failure
	vr_mgr.queue_free()
	return false


func _init_vr_comfort_system() -> bool:
	"""Initialize the VR comfort system subsystem."""
	if vr_manager == null:
		log_warning("VRComfortSystem requires VRManager - skipping initialization")
		return false
	
	# Create VRComfortSystem instance
	var script = load("res://scripts/core/vr_comfort_system.gd")
	if not script:
		log_error("Failed to load VRComfortSystem script")
		return false
	
	var comfort_sys = script.new()
	comfort_sys.name = "VRComfortSystem"
	add_child(comfort_sys)
	
	# Initialize with VR manager (spacecraft will be set later)
	if comfort_sys.initialize(vr_manager):
		vr_comfort_system = comfort_sys
		register_subsystem("VRComfortSystem", comfort_sys)
		log_info("VRComfortSystem initialized")
		return true
	else:
		log_error("VRComfortSystem failed to initialize")
		comfort_sys.queue_free()
		return false


func _init_haptic_manager() -> bool:
	"""Initialize the haptic manager subsystem."""
	if vr_manager == null:
		log_warning("HapticManager requires VRManager - skipping initialization")
		return false
	
	# Create HapticManager instance
	var script = load("res://scripts/core/haptic_manager.gd")
	if not script:
		log_error("Failed to load HapticManager script")
		return false
	
	var haptic_mgr = script.new()
	haptic_mgr.name = "HapticManager"
	add_child(haptic_mgr)
	
	# Initialize haptic manager
	if haptic_mgr.initialize():
		haptic_manager = haptic_mgr
		register_subsystem("HapticManager", haptic_mgr)
		log_info("HapticManager initialized")
		return true
	else:
		log_warning("HapticManager initialization returned false - may not have VR controllers")
		# Still register it even if no controllers are available
		haptic_manager = haptic_mgr
		register_subsystem("HapticManager", haptic_mgr)
		return true


func _init_renderer() -> bool:
	"""Initialize the rendering subsystem."""
	# Create RenderingSystem instance
	var RenderingSystemScript = load("res://scripts/rendering/rendering_system.gd")
	var rendering_sys = RenderingSystemScript.new()
	rendering_sys.name = "RenderingSystem"
	add_child(rendering_sys)
	
	# Get the main scene root for initialization
	var scene_root = get_tree().current_scene
	if scene_root is Node3D:
		if rendering_sys.initialize(scene_root):
			renderer = rendering_sys
			register_subsystem("Renderer", rendering_sys)
			log_info("RenderingSystem initialized")
			return true
		else:
			log_error("RenderingSystem failed to initialize")
			rendering_sys.queue_free()
			return false
	else:
		# Scene not ready yet, defer initialization
		log_warning("Scene not ready for RenderingSystem - will initialize later")
		renderer = rendering_sys
		register_subsystem("Renderer", rendering_sys)
		return true


func _init_performance_optimizer() -> bool:
	"""Initialize the performance optimizer subsystem."""
	# Create PerformanceOptimizer instance
	var script = load("res://scripts/rendering/performance_optimizer.gd")
	if not script:
		log_error("Failed to load PerformanceOptimizer script")
		return false
	
	var perf_optimizer = script.new()
	perf_optimizer.name = "PerformanceOptimizer"
	add_child(perf_optimizer)
	
	# Get LODManager from renderer if available
	var lod_manager = null
	if renderer != null and renderer.has_method("get_lod_manager"):
		lod_manager = renderer.get_lod_manager()
	
	# Initialize with LODManager and viewport
	if perf_optimizer.initialize(lod_manager, get_viewport()):
		performance_optimizer = perf_optimizer
		register_subsystem("PerformanceOptimizer", perf_optimizer)
		
		# Connect to FPS warnings
		perf_optimizer.fps_below_target.connect(_on_fps_below_target)
		perf_optimizer.fps_recovered.connect(_on_fps_recovered)
		
		log_info("PerformanceOptimizer initialized")
		return true
	else:
		log_error("PerformanceOptimizer failed to initialize")
		perf_optimizer.queue_free()
		return false


func _on_fps_below_target(current_fps: float, target_fps: float) -> void:
	"""Handle FPS dropping below target."""
	log_warning("Performance: FPS below target (%.1f < %.1f)" % [current_fps, target_fps])


func _on_fps_recovered(current_fps: float) -> void:
	"""Handle FPS recovering to target."""
	log_info("Performance: FPS recovered (%.1f)" % current_fps)


func _init_audio_manager() -> bool:
	"""Initialize the audio manager subsystem."""
	# AudioManager will be implemented in Phase 9
	return false


func _init_fractal_zoom() -> bool:
	"""Initialize the fractal zoom subsystem."""
	# Create FractalZoomSystem instance
	var script = load("res://scripts/core/fractal_zoom_system.gd")
	if not script:
		log_error("Failed to load FractalZoomSystem script")
		return false
		
	var fractal_zoom_sys = script.new()
	fractal_zoom_sys.name = "FractalZoomSystem"
	add_child(fractal_zoom_sys)
	
	fractal_zoom = fractal_zoom_sys
	register_subsystem("FractalZoom", fractal_zoom_sys)
	
	log_info("FractalZoomSystem created - awaiting player node assignment")
	return true


func _init_capture_event_system() -> bool:
	"""Initialize the capture event subsystem."""
	# Create CaptureEventSystem instance
	var script = load("res://scripts/gameplay/capture_event_system.gd")
	if not script:
		log_error("Failed to load CaptureEventSystem script")
		return false
		
	var capture_sys = script.new()
	capture_sys.name = "CaptureEventSystem"
	add_child(capture_sys)
	
	capture_event_system = capture_sys
	register_subsystem("CaptureEventSystem", capture_sys)
	
	log_info("CaptureEventSystem created - awaiting spacecraft assignment")
	return true


func _init_save_system() -> bool:
	"""Initialize the save system subsystem."""
	# Create SaveSystem instance
	var script = load("res://scripts/core/save_system.gd")
	if not script:
		log_error("Failed to load SaveSystem script")
		return false
		
	var save_sys = script.new()
	save_sys.name = "SaveSystem"
	add_child(save_sys)
	# Initialize the save system (creates directories)
	if not save_sys.initialize():
		log_error("SaveSystem failed to initialize")
		save_sys.queue_free()
		return false

	
	save_system = save_sys
	register_subsystem("SaveSystem", save_sys)
	
	log_info("SaveSystem initialized")
	return true


func _init_settings_manager() -> bool:
	"""Initialize the settings manager subsystem."""
	# Create SettingsManager instance
	var script = load("res://scripts/core/settings_manager.gd")
	if not script:
		log_error("Failed to load SettingsManager script")
		return false
		
	var settings_mgr = script.new()
	settings_mgr.name = "SettingsManager"
	add_child(settings_mgr)
	
	settings_manager = settings_mgr
	register_subsystem("SettingsManager", settings_mgr)
	
	log_info("SettingsManager initialized")
	return true


func _process(delta: float) -> void:
	"""Main process loop - updates all subsystems that need per-frame updates."""
	if not _is_initialized or _is_shutting_down:
		return
	
	# Track FPS
	_update_fps_counter(delta)
	
	# Update subsystems that need per-frame updates
	# These will be called when subsystems are implemented
	_update_vr(delta)
	_update_vr_comfort(delta)
	_update_relativity(delta)
	_update_renderer(delta)
	_update_audio(delta)


func _physics_process(delta: float) -> void:
	"""Physics process loop - updates physics-related subsystems at fixed timestep."""
	if not _is_initialized or _is_shutting_down:
		return
	
	# Update physics-related subsystems
	_update_floating_origin(delta)
	_update_physics(delta)
	_update_time_manager(delta)


func _update_fps_counter(delta: float) -> void:
	"""Track and log FPS for performance monitoring."""
	_frame_count += 1
	_accumulated_time += delta
	
	# Update FPS every second
	if _accumulated_time >= 1.0:
		_last_fps = _frame_count / _accumulated_time
		_frame_count = 0
		_accumulated_time = 0.0
		
		# Warn if FPS drops below target
		if _last_fps < TARGET_FPS * 0.9:  # 10% tolerance
			log_warning("FPS below target: %.1f (target: %d)" % [_last_fps, TARGET_FPS])


func _update_vr(delta: float) -> void:
	"""Update VR tracking and input."""
	if vr_manager != null and vr_manager.has_method("update"):
		vr_manager.update(delta)


func _update_vr_comfort(delta: float) -> void:
	"""Update VR comfort system."""
	if vr_comfort_system != null and vr_comfort_system.has_method("update"):
		vr_comfort_system.update(delta)


func _update_relativity(delta: float) -> void:
	"""Update relativistic effects."""
	if relativity != null and relativity.has_method("update"):
		relativity.update(delta)


func _update_floating_origin(delta: float) -> void:
	"""Update floating origin system."""
	if floating_origin != null and floating_origin.has_method("update"):
		floating_origin.update(delta)


func _update_physics(delta: float) -> void:
	"""Update physics simulation."""
	if physics_engine != null and physics_engine.has_method("update"):
		physics_engine.update(delta)


func _update_time_manager(delta: float) -> void:
	"""Update simulation time."""
	if time_manager != null and time_manager.has_method("update"):
		time_manager.update(delta)


func _update_renderer(delta: float) -> void:
	"""Update rendering systems."""
	if renderer != null and renderer.has_method("update"):
		renderer.update(delta)


func _update_audio(delta: float) -> void:
	"""Update audio systems."""
	if audio_manager != null and audio_manager.has_method("update"):
		audio_manager.update(delta)


func _update_fractal_zoom(delta: float) -> void:
	"""Update fractal zoom system."""
	if fractal_zoom != null and fractal_zoom.has_method("update"):
		fractal_zoom.update(delta)


## Shutdown and Cleanup

func shutdown() -> void:
	"""Gracefully shutdown all subsystems and clean up resources."""
	if _is_shutting_down:
		log_warning("Shutdown already in progress")
		return
	
	log_info("ResonanceEngine shutting down...")
	_is_shutting_down = true
	engine_shutting_down.emit()
	
	# Shutdown subsystems in reverse order of initialization
	_shutdown_subsystem("SaveSystem", save_system)
	_shutdown_subsystem("SettingsManager", settings_manager)
	_shutdown_subsystem("CaptureEventSystem", capture_event_system)
	_shutdown_subsystem("FractalZoom", fractal_zoom)
	_shutdown_subsystem("AudioManager", audio_manager)
	_shutdown_subsystem("Renderer", renderer)
	_shutdown_subsystem("VRComfortSystem", vr_comfort_system)
	_shutdown_subsystem("VRManager", vr_manager)
	_shutdown_subsystem("PhysicsEngine", physics_engine)
	_shutdown_subsystem("FloatingOrigin", floating_origin)
	_shutdown_subsystem("RelativityManager", relativity)
	_shutdown_subsystem("TimeManager", time_manager)
	
	# Close log file if open
	if _log_file != null:
		_log_file.close()
		_log_file = null
	
	_is_initialized = false
	log_info("ResonanceEngine shutdown complete")
	engine_shutdown_complete.emit()


func _shutdown_subsystem(name: String, subsystem: Node) -> void:
	"""Helper to shutdown a subsystem with error handling."""
	if subsystem == null:
		return
	
	log_debug("Shutting down subsystem: %s" % name)
	
	if subsystem.has_method("shutdown"):
		subsystem.shutdown()
	
	log_info("Subsystem shutdown: %s" % name)


func _notification(what: int) -> void:
	"""Handle engine notifications for cleanup."""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		log_info("Window close requested - initiating shutdown")
		shutdown()
	elif what == NOTIFICATION_PREDELETE:
		if _is_initialized and not _is_shutting_down:
			shutdown()


## Helper Methods for Subsystem Configuration

func set_spacecraft_for_comfort_system(spacecraft_node: Node) -> void:
	"""Set the spacecraft reference for VR comfort system acceleration tracking."""
	if vr_comfort_system != null and vr_comfort_system.has_method("set_spacecraft"):
		vr_comfort_system.set_spacecraft(spacecraft_node)
		log_debug("Spacecraft set for VR comfort system")


## Subsystem Registration

func register_subsystem(name: String, subsystem: Node) -> void:
	"""Register a subsystem with the engine coordinator."""
	match name:
		"VRManager":
			vr_manager = subsystem
		"VRComfortSystem":
			vr_comfort_system = subsystem
		"FloatingOrigin":
			floating_origin = subsystem
		"Relativity":
			relativity = subsystem
		"PhysicsEngine":
			physics_engine = subsystem
		"TimeManager":
			time_manager = subsystem
		"Renderer":
			renderer = subsystem
		"AudioManager":
			audio_manager = subsystem
		"FractalZoom":
			fractal_zoom = subsystem
		"CaptureEventSystem":
			capture_event_system = subsystem
		"SaveSystem":
			save_system = subsystem
		"SettingsManager":
			settings_manager = subsystem
		_:
			log_warning("Unknown subsystem name: %s" % name)
			return
	
	log_info("Subsystem registered: %s" % name)


func unregister_subsystem(name: String) -> void:
	"""Unregister a subsystem from the engine coordinator."""
	# CRITICAL FIX: Properly cleanup subsystem nodes to prevent memory leaks
	var subsystem: Node = null

	match name:
		"VRManager":
			subsystem = vr_manager
			vr_manager = null
		"VRComfortSystem":
			subsystem = vr_comfort_system
			vr_comfort_system = null
		"HapticManager":
			subsystem = haptic_manager
			haptic_manager = null
		"FloatingOrigin":
			subsystem = floating_origin
			floating_origin = null
		"Relativity":
			subsystem = relativity
			relativity = null
		"PhysicsEngine":
			subsystem = physics_engine
			physics_engine = null
		"TimeManager":
			subsystem = time_manager
			time_manager = null
		"Renderer":
			subsystem = renderer
			renderer = null
		"AudioManager":
			subsystem = audio_manager
			audio_manager = null
		"FractalZoom":
			subsystem = fractal_zoom
			fractal_zoom = null
		"CaptureEventSystem":
			subsystem = capture_event_system
			capture_event_system = null
		"SaveSystem":
			subsystem = save_system
			save_system = null
		"SettingsManager":
			subsystem = settings_manager
			settings_manager = null
		"PerformanceOptimizer":
			subsystem = performance_optimizer
			performance_optimizer = null
		_:
			log_warning("Unknown subsystem name: %s" % name)
			return

	# Clean up the subsystem node if it exists
	if subsystem != null and is_instance_valid(subsystem):
		# Remove from scene tree if it's our child
		if subsystem.get_parent() == self:
			remove_child(subsystem)
		# Queue for deletion to free memory
		subsystem.queue_free()
		log_debug("Subsystem node freed: %s" % name)

	log_info("Subsystem unregistered: %s" % name)


## Logging System

func log_debug(message: String) -> void:
	"""Log a debug message."""
	_log(LogLevel.DEBUG, message)


func log_info(message: String) -> void:
	"""Log an info message."""
	_log(LogLevel.INFO, message)


func log_warning(message: String) -> void:
	"""Log a warning message."""
	_log(LogLevel.WARNING, message)


func log_error(message: String) -> void:
	"""Log an error message."""
	_log(LogLevel.ERROR, message)


func _log(level: LogLevel, message: String) -> void:
	"""Internal logging function with level filtering."""
	if level < _log_level:
		return
	
	var timestamp := Time.get_datetime_string_from_system()
	var level_str := _get_level_string(level)
	var formatted := "[%s] [%s] %s" % [timestamp, level_str, message]
	
	# Output to console
	match level:
		LogLevel.DEBUG, LogLevel.INFO:
			print(formatted)
		LogLevel.WARNING:
			push_warning(formatted)
		LogLevel.ERROR:
			push_error(formatted)
	
	# Output to file if enabled
	if _log_to_file and _log_file != null:
		_log_file.store_line(formatted)


func _get_level_string(level: LogLevel) -> String:
	"""Convert log level to string."""
	match level:
		LogLevel.DEBUG:
			return "DEBUG"
		LogLevel.INFO:
			return "INFO"
		LogLevel.WARNING:
			return "WARN"
		LogLevel.ERROR:
			return "ERROR"
		_:
			return "UNKNOWN"


func set_log_level(level: LogLevel) -> void:
	"""Set the minimum log level for output."""
	_log_level = level
	log_info("Log level set to: %s" % _get_level_string(level))


func enable_file_logging(file_path: String) -> bool:
	"""Enable logging to a file."""
	_log_file = FileAccess.open(file_path, FileAccess.WRITE)
	if _log_file == null:
		log_error("Failed to open log file: %s" % file_path)
		return false
	
	_log_to_file = true
	log_info("File logging enabled: %s" % file_path)
	return true


func disable_file_logging() -> void:
	"""Disable logging to a file."""
	if _log_file != null:
		_log_file.close()
		_log_file = null
	_log_to_file = false
	log_info("File logging disabled")


## Floating Origin Helpers

func set_floating_origin_player(player: Node3D) -> bool:
	"""Set the player node for the floating origin system."""
	if floating_origin == null:
		log_error("FloatingOriginSystem not initialized")
		return false
	
	if floating_origin.has_method("set_player_node"):
		floating_origin.set_player_node(player)
		log_info("Floating origin player node set")
		return true
	
	return false


func register_with_floating_origin(obj: Node3D) -> void:
	"""Register an object with the floating origin system for coordinate rebasing."""
	if floating_origin != null and floating_origin.has_method("register_object"):
		floating_origin.register_object(obj)


func unregister_from_floating_origin(obj: Node3D) -> void:
	"""Unregister an object from the floating origin system."""
	if floating_origin != null and floating_origin.has_method("unregister_object"):
		floating_origin.unregister_object(obj)


## State Queries

func is_initialized() -> bool:
	"""Check if the engine is fully initialized."""
	return _is_initialized


func is_shutting_down() -> bool:
	"""Check if the engine is in the process of shutting down."""
	return _is_shutting_down


func get_current_fps() -> float:
	"""Get the current frames per second."""
	return _last_fps


func get_engine_version() -> String:
	"""Get the engine version string."""
	return ENGINE_VERSION


func get_subsystem_status() -> Dictionary:
	"""Get the initialization status of all subsystems."""
	return {
		"VRManager": vr_manager != null,
		"VRComfortSystem": vr_comfort_system != null,
		"HapticManager": haptic_manager != null,
		"FloatingOrigin": floating_origin != null,
		"Relativity": relativity != null,
		"PhysicsEngine": physics_engine != null,
		"TimeManager": time_manager != null,
		"Renderer": renderer != null,
		"AudioManager": audio_manager != null,
		"FractalZoom": fractal_zoom != null,
		"CaptureEventSystem": capture_event_system != null,
		"SaveSystem": save_system != null,
		"SettingsManager": settings_manager != null,
		"PerformanceOptimizer": performance_optimizer != null
	}


func get_settings_manager() -> Node:
	"""Get the settings manager instance."""
	return settings_manager


## Haptic Manager Helpers

func get_haptic_manager() -> Node:
	"""Get the haptic manager instance."""
	return haptic_manager


func trigger_haptic_feedback(hand: String, intensity: float, duration: float) -> void:
	"""Trigger haptic feedback on a specific controller.
	
	Args:
		hand: "left", "right", or "both"
		intensity: Haptic intensity (0.0 to 1.0)
		duration: Duration in seconds
	"""
	if haptic_manager != null and haptic_manager.has_method("trigger_haptic"):
		if hand == "both":
			haptic_manager.trigger_haptic_both(intensity, duration)
		else:
			haptic_manager.trigger_haptic(hand, intensity, duration)


## Fractal Zoom Helpers

func set_fractal_zoom_player(player: Node3D, environment: Node3D = null) -> bool:
	"""Set the player node for the fractal zoom system."""
	if fractal_zoom == null:
		log_error("FractalZoomSystem not initialized")
		return false
	
	if fractal_zoom.has_method("initialize"):
		var success = fractal_zoom.initialize(player, environment)
		if success:
			log_info("Fractal zoom player node set")
		return success
	
	return false


func initiate_fractal_zoom(direction: int) -> bool:
	"""Initiate a fractal zoom transition."""
	if fractal_zoom == null:
		log_error("FractalZoomSystem not initialized")
		return false
	
	if fractal_zoom.has_method("zoom"):
		return fractal_zoom.zoom(direction)
	
	return false


func get_current_scale_level() -> int:
	"""Get the current fractal zoom scale level."""
	if fractal_zoom != null and fractal_zoom.has_method("get_current_scale_level"):
		return fractal_zoom.get_current_scale_level()
	return 0


## Capture Event System Helpers

func initialize_capture_event_system(craft: RigidBody3D, pilot: Node = null) -> bool:
	"""Initialize the capture event system with spacecraft and pilot controller."""
	if capture_event_system == null:
		log_error("CaptureEventSystem not initialized")
		return false
	
	if capture_event_system.has_method("initialize"):
		var success = capture_event_system.initialize(craft, pilot)
		if success:
			log_info("Capture event system initialized with spacecraft")
		return success
	
	return false


func cancel_capture_event() -> void:
	"""Cancel an in-progress capture event."""
	if capture_event_system != null and capture_event_system.has_method("cancel_capture"):
		capture_event_system.cancel_capture()


func is_capture_in_progress() -> bool:
	"""Check if a capture event is currently in progress."""
	if capture_event_system != null and capture_event_system.has_method("is_capturing"):
		return capture_event_system.is_capturing()
	return false


func set_capture_events_enabled(enabled: bool) -> void:
	"""Enable or disable capture event detection."""
	if capture_event_system != null and capture_event_system.has_method("set_capture_enabled"):
		capture_event_system.set_capture_enabled(enabled)


## Save System Helpers

func initialize_save_system(craft: Node = null) -> bool:
	"""Initialize the save system with references to game systems."""
	if save_system == null:
		log_error("SaveSystem not initialized")
		return false
	
	# Set spacecraft reference
	if craft != null:
		save_system.set_spacecraft(craft)
	
	# Set time manager reference
	if time_manager != null:
		save_system.set_time_manager(time_manager)
	
	# Set floating origin reference
	if floating_origin != null:
		save_system.set_floating_origin(floating_origin)
	
	log_info("Save system initialized with game references")
	return true


func save_game(slot: int) -> bool:
	"""Save the current game state to the specified slot."""
	if save_system == null:
		log_error("SaveSystem not initialized")
		return false
	
	return save_system.save_game(slot)


func load_game(slot: int) -> bool:
	"""Load game state from the specified slot."""
	if save_system == null:
		log_error("SaveSystem not initialized")
		return false
	
	return save_system.load_game(slot)


func get_save_metadata(slot: int) -> Dictionary:
	"""Get metadata for a save slot."""
	if save_system == null:
		return {}
	
	return save_system.get_save_metadata(slot)


func get_all_save_metadata() -> Array[Dictionary]:
	"""Get metadata for all save slots."""
	if save_system == null:
		return []
	
	return save_system.get_all_save_metadata()


func delete_save(slot: int) -> bool:
	"""Delete a save file."""
	if save_system == null:
		return false
	
	return save_system.delete_save(slot)


func has_save(slot: int) -> bool:
	"""Check if a save slot has data."""
	if save_system == null:
		return false
	
	return save_system.has_save(slot)


func set_auto_save_enabled(enabled: bool) -> void:
	"""Enable or disable auto-save."""
	if save_system != null:
		save_system.set_auto_save_enabled(enabled)


func set_auto_save_slot(slot: int) -> void:
	"""Set which slot to use for auto-save."""
	if save_system != null:
		save_system.set_auto_save_slot(slot)
