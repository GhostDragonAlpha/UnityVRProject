## FractalZoomSystem - Scale-Invariant Navigation System
## Enables players to zoom between scales using Golden Ratio factors.
## Reveals nested lattice structures and maintains geometric patterns across scales.
##
## Requirements: 26.1, 26.2, 26.3, 26.4, 26.5
extends Node
class_name FractalZoomSystem

## Zoom direction enum
enum ZoomDirection {
	IN,   # Zoom into smaller scales
	OUT   # Zoom out to larger scales
}

## Emitted when a zoom transition starts
signal zoom_started(direction: int, target_scale: float)
## Emitted when a zoom transition completes
signal zoom_completed(new_scale: float)
## Emitted when zoom is cancelled
signal zoom_cancelled()

## Golden Ratio constant (phi ~= 1.618)
const GOLDEN_RATIO := 1.618033988749

## Zoom transition duration in seconds
const ZOOM_DURATION := 2.0

## Minimum and maximum scale levels
const MIN_SCALE_LEVEL := -10  # Subatomic
const MAX_SCALE_LEVEL := 10   # Galactic

## Current scale level (0 = human scale)
var current_scale_level: int = 0

## Current scale factor relative to base scale
var current_scale_factor: float = 1.0

## Player node reference
var player_node: Node3D = null

## Lattice renderer reference for updating nested structures
var lattice_renderer: Node = null

## Tween for smooth transitions
var _zoom_tween: Tween = null

## Is a zoom currently in progress?
var _is_zooming: bool = false

## Original player scale before zoom
var _original_player_scale: Vector3 = Vector3.ONE

## Environment root for scaling
var _environment_root: Node3D = null


func _ready() -> void:
	_original_player_scale = Vector3.ONE


## Initialize the fractal zoom system
func initialize(player: Node3D, environment: Node3D = null) -> bool:
	if player == null:
		push_error("FractalZoomSystem: Cannot initialize with null player node")
		return false
	
	player_node = player
	_original_player_scale = player.scale
	_environment_root = environment
	
	# Try to find lattice renderer
	_find_lattice_renderer()
	
	print("FractalZoomSystem initialized at scale level 0")
	return true


## Find the lattice renderer in the scene tree
func _find_lattice_renderer() -> void:
	# Look for LatticeRenderer in the scene
	var root = get_tree().root
	lattice_renderer = _find_node_by_class(root, "LatticeRenderer")
	
	if lattice_renderer != null:
		print("FractalZoomSystem: Found LatticeRenderer")
	else:
		push_warning("FractalZoomSystem: LatticeRenderer not found - nested structures will not update")


## Recursively find a node by class name
func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node.get_class() == target_class_name or (node.get_script() != null and node.get_script().get_global_name() == target_class_name):
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result != null:
			return result
	
	return null


## Initiate a zoom transition
func zoom(direction: int) -> bool:
	if _is_zooming:
		push_warning("FractalZoomSystem: Zoom already in progress")
		return false
	
	if player_node == null:
		push_error("FractalZoomSystem: Player node not set")
		return false
	
	# Calculate target scale level
	var target_level := current_scale_level
	if direction == ZoomDirection.IN:
		target_level -= 1
	else:
		target_level += 1
	
	# Check bounds
	if target_level < MIN_SCALE_LEVEL:
		push_warning("FractalZoomSystem: Cannot zoom in further - at minimum scale")
		return false
	
	if target_level > MAX_SCALE_LEVEL:
		push_warning("FractalZoomSystem: Cannot zoom out further - at maximum scale")
		return false
	
	# Calculate target scale factor
	var target_scale_factor := _calculate_scale_factor(target_level)
	
	# Start zoom transition
	_start_zoom_transition(direction, target_level, target_scale_factor)
	
	return true


## Zoom to a specific scale level
func zoom_to_level(target_level: int) -> bool:
	if _is_zooming:
		push_warning("FractalZoomSystem: Zoom already in progress")
		return false
	
	if target_level < MIN_SCALE_LEVEL or target_level > MAX_SCALE_LEVEL:
		push_error("FractalZoomSystem: Target level %d out of bounds [%d, %d]" % [target_level, MIN_SCALE_LEVEL, MAX_SCALE_LEVEL])
		return false
	
	if player_node == null:
		push_error("FractalZoomSystem: Player node not set")
		return false
	
	var direction := ZoomDirection.IN if target_level < current_scale_level else ZoomDirection.OUT
	var target_scale_factor := _calculate_scale_factor(target_level)
	
	_start_zoom_transition(direction, target_level, target_scale_factor)
	
	return true


## Calculate scale factor for a given level using Golden Ratio
func _calculate_scale_factor(level: int) -> float:
	# Scale factor = phi^level
	# Positive levels = larger (zoom out)
	# Negative levels = smaller (zoom in)
	return pow(GOLDEN_RATIO, float(level))


## Start the zoom transition animation
func _start_zoom_transition(direction: int, target_level: int, target_scale_factor: float) -> void:
	_is_zooming = true
	
	zoom_started.emit(direction, target_scale_factor)
	
	# Cancel any existing tween
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	
	# Create new tween
	_zoom_tween = create_tween()
	_zoom_tween.set_parallel(true)
	_zoom_tween.set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Scale the player relative to environment
	var initial_player_scale := player_node.scale
	var target_player_scale := _original_player_scale * target_scale_factor
	
	_zoom_tween.tween_property(player_node, "scale", target_player_scale, ZOOM_DURATION)
	
	# If we have an environment root, scale it inversely to maintain relative sizes
	if _environment_root != null:
		var initial_env_scale := _environment_root.scale
		var target_env_scale := Vector3.ONE / target_scale_factor
		_zoom_tween.tween_property(_environment_root, "scale", target_env_scale, ZOOM_DURATION)
	
	# Update lattice density to reveal nested structures
	if lattice_renderer != null and lattice_renderer.has_method("set_grid_density"):
		var initial_density := _get_lattice_density()
		var target_density := _calculate_lattice_density(target_level)
		_zoom_tween.tween_method(_update_lattice_density, initial_density, target_density, ZOOM_DURATION)
	
	# When transition completes
	_zoom_tween.finished.connect(_on_zoom_transition_complete.bind(target_level, target_scale_factor))


## Update lattice density during transition
func _update_lattice_density(density: float) -> void:
	if lattice_renderer != null and lattice_renderer.has_method("set_grid_density"):
		lattice_renderer.set_grid_density(density)


## Get current lattice density
func _get_lattice_density() -> float:
	if lattice_renderer != null and lattice_renderer.has_method("get_grid_density"):
		return lattice_renderer.get_grid_density()
	return 10.0  # Default density


## Calculate lattice density for a scale level
func _calculate_lattice_density(level: int) -> float:
	# Base density at human scale
	var base_density := 10.0
	
	# Increase density when zooming in (negative levels)
	# Decrease density when zooming out (positive levels)
	# Use Golden Ratio to maintain fractal pattern
	return base_density * pow(GOLDEN_RATIO, float(-level))


## Called when zoom transition completes
func _on_zoom_transition_complete(target_level: int, target_scale_factor: float) -> void:
	current_scale_level = target_level
	current_scale_factor = target_scale_factor
	_is_zooming = false
	
	print("FractalZoomSystem: Zoom complete - now at level %d (scale factor: %.3f)" % [current_scale_level, current_scale_factor])
	
	zoom_completed.emit(current_scale_factor)


## Cancel an in-progress zoom
func cancel_zoom() -> void:
	if not _is_zooming:
		return
	
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	
	_is_zooming = false
	zoom_cancelled.emit()
	
	print("FractalZoomSystem: Zoom cancelled")


## Get the current scale level
func get_current_scale_level() -> int:
	return current_scale_level


## Get the current scale factor
func get_current_scale_factor() -> float:
	return current_scale_factor


## Check if a zoom is in progress
func is_zooming() -> bool:
	return _is_zooming


## Get the scale description for UI display
func get_scale_description() -> String:
	match current_scale_level:
		-10, -9, -8:
			return "Subatomic Scale"
		-7, -6, -5:
			return "Molecular Scale"
		-4, -3, -2:
			return "Microscopic Scale"
		-1:
			return "Millimeter Scale"
		0:
			return "Human Scale"
		1:
			return "Building Scale"
		2, 3:
			return "City Scale"
		4, 5:
			return "Continental Scale"
		6, 7:
			return "Planetary Scale"
		8, 9:
			return "Solar System Scale"
		10:
			return "Galactic Scale"
		_:
			return "Unknown Scale"


## Get the relative size description
func get_relative_size_description() -> String:
	if current_scale_factor < 0.001:
		return "Smaller than an atom"
	elif current_scale_factor < 0.01:
		return "Molecular size"
	elif current_scale_factor < 0.1:
		return "Microscopic"
	elif current_scale_factor < 1.0:
		return "Miniature"
	elif current_scale_factor == 1.0:
		return "Normal size"
	elif current_scale_factor < 10.0:
		return "Giant"
	elif current_scale_factor < 100.0:
		return "Colossal"
	elif current_scale_factor < 1000.0:
		return "Planetary"
	else:
		return "Cosmic"


## Reset to human scale
func reset_to_human_scale() -> bool:
	return zoom_to_level(0)


## Cleanup
func shutdown() -> void:
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	
	player_node = null
	lattice_renderer = null
	_environment_root = null
	
	print("FractalZoomSystem shutdown")
