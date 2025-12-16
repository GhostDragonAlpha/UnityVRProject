## VRTeleportation - VR-Friendly Teleportation System for Navigation
## Provides comfort-focused teleportation mechanics with arc-based targeting,
## visual feedback, fade transitions, and collision detection for safe movement.
##
## Requirements:
## - Instant teleport (no motion during transition)
## - Arc-based targeting (parabolic trajectory preview)
## - Visual feedback (target reticle, valid/invalid indicators)
## - Fade transition (brief fade to black during teleport)
## - Collision detection (can't teleport into walls/objects)
## - Maximum range limiting
extends Node3D
class_name VRTeleportation

## Emitted when teleportation starts
signal teleport_started(from_position: Vector3, to_position: Vector3)
## Emitted when teleportation completes
signal teleport_completed(position: Vector3)
## Emitted when targeting state changes
signal targeting_state_changed(is_targeting: bool)
## Emitted when target validity changes
signal target_validity_changed(is_valid: bool)

## Teleportation range settings
@export var teleport_range: float = 10.0  ## Maximum teleport distance (meters)
@export var min_teleport_distance: float = 1.0  ## Minimum teleport distance (meters)
@export var arc_height: float = 2.0  ## Height of parabolic arc (meters)
@export var arc_resolution: int = 32  ## Number of points in arc visualization

## Target validation settings
@export var max_slope_angle: float = 45.0  ## Maximum walkable slope (degrees)
@export var min_headroom: float = 2.0  ## Required clearance above target (meters)
@export var player_radius: float = 0.4  ## Player collision radius (meters)

## Visual feedback settings
@export var valid_color: Color = Color(0.0, 1.0, 0.0, 0.8)  ## Green for valid targets
@export var invalid_color: Color = Color(1.0, 0.0, 0.0, 0.8)  ## Red for invalid targets
@export var arc_width: float = 0.05  ## Width of arc line (meters)
@export var reticle_radius: float = 0.5  ## Radius of target reticle (meters)

## Fade transition settings
@export var fade_duration: float = 0.2  ## Duration of fade in/out (seconds)
@export var fade_color: Color = Color.BLACK  ## Color to fade to

## Input settings
@export var teleport_hand: String = "left"  ## Which controller triggers teleport
@export var trigger_button: String = "trigger"  ## Button to hold for targeting
@export var teleport_on_release: bool = true  ## Teleport when button released

## Comfort settings
@export var snap_rotation_enabled: bool = false  ## Enable rotation during teleport
@export var snap_rotation_angle: float = 45.0  ## Rotation increment (degrees)
@export var vignette_during_fade: bool = true  ## Apply vignette during transition
@export var haptic_feedback: bool = true  ## Trigger haptic on teleport

## References
var vr_manager: VRManager = null
var haptic_manager: HapticManager = null
var vr_comfort_system: VRComfortSystem = null
var xr_origin: XROrigin3D = null
var xr_camera: XRCamera3D = null
var controller: XRController3D = null

## Visual components
var arc_mesh_instance: MeshInstance3D = null
var reticle_mesh_instance: MeshInstance3D = null
var fade_overlay: ColorRect = null
var fade_material: ShaderMaterial = null

## State tracking
var is_targeting: bool = false
var is_teleporting: bool = false
var is_valid_target: bool = false
var current_target_position: Vector3 = Vector3.ZERO
var current_target_normal: Vector3 = Vector3.UP
var current_arc_points: PackedVector3Array = PackedVector3Array()
var last_trigger_state: float = 0.0

## Collision detection
var collision_space: PhysicsDirectSpaceState3D = null
var ray_query: PhysicsRayQueryParameters3D = null

## Audio feedback
var teleport_sound: AudioStreamPlayer3D = null
const TELEPORT_SOUND_PITCH: float = 1.2
const INVALID_TARGET_SOUND_PITCH: float = 0.8


func _ready() -> void:
	# Create visual components
	_setup_arc_visualization()
	_setup_reticle()
	_setup_fade_overlay()

	# Create audio components
	_setup_audio()

	# Set up collision detection
	collision_space = get_world_3d().direct_space_state
	ray_query = PhysicsRayQueryParameters3D.new()

	# Start inactive
	set_process(false)
	set_physics_process(false)

	print("[VRTeleportation] Teleportation system initialized")


## Initialize the teleportation system
## @param vr_mgr: Reference to VRManager
## @param xr_origin_node: XROrigin3D to teleport
## @return: true if initialization was successful
func initialize(vr_mgr: VRManager, xr_origin_node: XROrigin3D) -> bool:
	vr_manager = vr_mgr
	xr_origin = xr_origin_node

	if vr_manager == null:
		push_error("[VRTeleportation] VRManager is null")
		return false

	if xr_origin == null:
		push_error("[VRTeleportation] XROrigin3D is null")
		return false

	# Get XR camera
	xr_camera = vr_manager.get_xr_camera()
	if xr_camera == null:
		push_warning("[VRTeleportation] XRCamera3D not found")

	# Get controller
	controller = vr_manager.get_controller(teleport_hand)
	if controller == null:
		push_warning("[VRTeleportation] Controller '%s' not found" % teleport_hand)

	# Get haptic manager
	haptic_manager = _get_haptic_manager()
	if haptic_manager == null:
		push_warning("[VRTeleportation] HapticManager not found - haptic feedback disabled")

	# Get VR comfort system
	vr_comfort_system = _get_vr_comfort_system()
	if vr_comfort_system == null:
		push_warning("[VRTeleportation] VRComfortSystem not found - vignette disabled")

	# Activate system
	set_process(true)
	set_physics_process(true)

	print("[VRTeleportation] Initialized successfully")
	return true


## Set up arc visualization mesh
func _setup_arc_visualization() -> void:
	arc_mesh_instance = MeshInstance3D.new()
	arc_mesh_instance.name = "TeleportArc"
	arc_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arc_mesh_instance.visible = false
	add_child.call_deferred(arc_mesh_instance)

	# Create material for arc
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mesh_instance.material_override = material


## Set up target reticle mesh
func _setup_reticle() -> void:
	reticle_mesh_instance = MeshInstance3D.new()
	reticle_mesh_instance.name = "TeleportReticle"
	reticle_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reticle_mesh_instance.visible = false
	add_child.call_deferred(reticle_mesh_instance)

	# Create circle mesh for reticle
	var mesh := _create_circle_mesh(reticle_radius, 32)
	reticle_mesh_instance.mesh = mesh

	# Create material for reticle
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = valid_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	reticle_mesh_instance.material_override = material


## Set up fade overlay for transitions
func _setup_fade_overlay() -> void:
	# Create canvas layer for fade overlay
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "TeleportFadeLayer"
	canvas_layer.layer = 100  ## On top of everything
	add_child.call_deferred(canvas_layer)

	# Create color rect for fade
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child.call_deferred(fade_overlay)

	# Create fade shader material
	fade_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = _get_fade_shader_code()
	fade_material.shader = shader
	fade_material.set_shader_parameter("fade_alpha", 0.0)
	fade_material.set_shader_parameter("fade_color", fade_color)

	fade_overlay.material = fade_material


## Set up audio feedback
func _setup_audio() -> void:
	teleport_sound = AudioStreamPlayer3D.new()
	teleport_sound.name = "TeleportSound"
	teleport_sound.bus = "SFX"
	add_child.call_deferred(teleport_sound)

	# TODO: Load actual sound file when available
	# For now, we'll just trigger without sound
	# teleport_sound.stream = preload("res://assets/audio/teleport.ogg")


func _process(delta: float) -> void:
	if is_teleporting:
		return  ## Don't process input during teleport

	if not vr_manager or not vr_manager.is_vr_active():
		return  ## Only works in VR mode

	# Check for targeting input
	_handle_teleport_input()

	# Update visual feedback if targeting
	if is_targeting:
		update_teleport_preview()


## Handle teleport input from VR controller
func _handle_teleport_input() -> void:
	if controller == null:
		return

	var controller_state := vr_manager.get_controller_state(teleport_hand)
	if controller_state.is_empty():
		return

	var trigger_value: float = controller_state.get(trigger_button, 0.0)

	# Check if trigger was just pressed (threshold crossed)
	if trigger_value > 0.5 and last_trigger_state <= 0.5:
		_start_targeting()

	# Check if trigger was just released
	if trigger_value <= 0.5 and last_trigger_state > 0.5:
		if is_targeting and teleport_on_release:
			_execute_teleport()
		_stop_targeting()

	# Handle snap rotation input (right thumbstick)
	if snap_rotation_enabled and is_targeting:
		_handle_snap_rotation_input()

	last_trigger_state = trigger_value


## Start targeting mode
func _start_targeting() -> void:
	if is_targeting:
		return

	is_targeting = true
	arc_mesh_instance.visible = true
	reticle_mesh_instance.visible = true

	targeting_state_changed.emit(true)
	print("[VRTeleportation] Targeting started")


## Stop targeting mode
func _stop_targeting() -> void:
	if not is_targeting:
		return

	is_targeting = false
	arc_mesh_instance.visible = false
	reticle_mesh_instance.visible = false

	targeting_state_changed.emit(false)
	print("[VRTeleportation] Targeting stopped")


## Update teleport arc and target preview
func update_teleport_preview() -> void:
	if controller == null:
		return

	# Get controller position and direction
	var controller_transform := controller.global_transform
	var origin := controller_transform.origin
	var direction := -controller_transform.basis.z  ## Forward direction

	# Calculate arc trajectory
	current_arc_points = calculate_teleport_arc(origin, direction)

	# Find target position
	var target_result := _find_arc_endpoint(current_arc_points)
	if target_result.is_empty():
		is_valid_target = false
		_update_visual_feedback()
		return

	current_target_position = target_result.position
	current_target_normal = target_result.normal

	# Validate target
	is_valid_target = is_valid_teleport_target(current_target_position, current_target_normal)

	# Update visual feedback
	_update_visual_feedback()

	# Emit signal if validity changed
	target_validity_changed.emit(is_valid_target)


## Calculate parabolic arc trajectory
## @param origin: Starting position of arc
## @param direction: Initial direction of arc
## @return: Array of Vector3 points forming the arc
func calculate_teleport_arc(origin: Vector3, direction: Vector3) -> PackedVector3Array:
	var points := PackedVector3Array()

	# Normalize direction
	direction = direction.normalized()

	# Calculate arc parameters
	var horizontal_distance := teleport_range
	var gravity := 9.8  ## m/s²

	# Initial velocity needed to reach max range with desired arc height
	var initial_velocity := sqrt(2.0 * gravity * arc_height)
	var time_to_apex := initial_velocity / gravity
	var total_time := time_to_apex * 2.0

	# Generate arc points
	for i in range(arc_resolution + 1):
		var t := float(i) / float(arc_resolution) * total_time

		# Parabolic trajectory
		var horizontal := direction * (initial_velocity * t * 0.7)  ## Scale down horizontal
		var vertical := Vector3.UP * (initial_velocity * t - 0.5 * gravity * t * t)

		var point := origin + horizontal + vertical
		points.append(point)

		# Stop early if we hit something
		if i > 0:
			var hit := _raycast_segment(points[i - 1], point)
			if hit:
				points.append(hit.position)
				break

	return points


## Find the endpoint of the arc where it hits a surface
## @param arc_points: Array of points forming the arc
## @return: Dictionary with {position: Vector3, normal: Vector3} or empty if no hit
func _find_arc_endpoint(arc_points: PackedVector3Array) -> Dictionary:
	if arc_points.size() < 2:
		return {}

	# The last point is either the natural end or a collision point
	var endpoint := arc_points[arc_points.size() - 1]

	# Raycast down from endpoint to find ground
	var down_hit := _raycast(endpoint, endpoint + Vector3.DOWN * 5.0)
	if down_hit:
		return {
			"position": down_hit.position,
			"normal": down_hit.normal
		}

	return {}


## Validate if position is a valid teleport target
## @param position: Target position to validate
## @param normal: Surface normal at target
## @return: true if target is valid
func is_valid_teleport_target(position: Vector3, normal: Vector3) -> bool:
	# Check if position is within range
	if xr_origin == null:
		return false

	var distance := xr_origin.global_position.distance_to(position)
	if distance < min_teleport_distance or distance > teleport_range:
		return false

	# Check slope angle
	var angle := rad_to_deg(normal.angle_to(Vector3.UP))
	if angle > max_slope_angle:
		return false

	# Check for adequate headroom
	var headroom_check := _raycast(position + Vector3.UP * 0.1, position + Vector3.UP * min_headroom)
	if headroom_check:
		return false  ## Something blocking headroom

	# Check for obstacles at player position
	var clearance_check := _sphere_cast(position + Vector3.UP * 1.0, player_radius)
	if clearance_check:
		return false  ## Player would collide with something

	return true


## Execute the teleport to current target
func execute_teleport(target: Vector3 = current_target_position) -> void:
	if is_teleporting:
		return

	if not is_valid_target:
		_play_invalid_target_feedback()
		return

	is_teleporting = true
	var start_position := xr_origin.global_position

	teleport_started.emit(start_position, target)
	print("[VRTeleportation] Teleporting from %s to %s" % [start_position, target])

	# Start fade-out sequence
	await _fade_to_black()

	# Move player to target
	_move_player_to_target(target)

	# Trigger haptic feedback
	if haptic_feedback and haptic_manager:
		haptic_manager.trigger_haptic(teleport_hand, 0.5, 0.1)

	# Play sound
	if teleport_sound and teleport_sound.stream:
		teleport_sound.pitch_scale = TELEPORT_SOUND_PITCH
		teleport_sound.play()

	# Fade back in
	await _fade_from_black()

	is_teleporting = false
	teleport_completed.emit(target)
	print("[VRTeleportation] Teleport completed")


## Internal method to actually execute teleport
func _execute_teleport() -> void:
	execute_teleport(current_target_position)


## Move player to target position
## @param target: Target position
func _move_player_to_target(target: Vector3) -> void:
	if xr_origin == null:
		return

	# Adjust target to account for XR camera offset
	var camera_offset := Vector3.ZERO
	if xr_camera:
		camera_offset = xr_camera.position
		camera_offset.y = 0  ## Don't adjust for vertical offset

	# Set new position
	xr_origin.global_position = target - camera_offset


## Update visual feedback based on target validity
func _update_visual_feedback() -> void:
	if arc_mesh_instance == null or reticle_mesh_instance == null:
		return

	# Update arc mesh
	_update_arc_mesh()

	# Update reticle
	var color := valid_color if is_valid_target else invalid_color
	var material := reticle_mesh_instance.material_override as StandardMaterial3D
	if material:
		material.albedo_color = color

	# Position reticle at target
	reticle_mesh_instance.global_position = current_target_position

	# Align reticle to surface normal
	if current_target_normal != Vector3.ZERO:
		var up := current_target_normal
		var forward := Vector3.FORWARD
		if abs(up.dot(forward)) > 0.99:
			forward = Vector3.RIGHT
		var right := forward.cross(up).normalized()
		forward = up.cross(right).normalized()
		reticle_mesh_instance.global_transform.basis = Basis(right, up, forward)


## Update arc mesh geometry
func _update_arc_mesh() -> void:
	if current_arc_points.size() < 2:
		arc_mesh_instance.mesh = null
		return

	var mesh := _create_arc_mesh(current_arc_points)
	arc_mesh_instance.mesh = mesh


## Create mesh for arc visualization
## @param points: Array of points forming the arc
## @return: ArrayMesh representing the arc
func _create_arc_mesh(points: PackedVector3Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	var color := valid_color if is_valid_target else invalid_color

	# Create tube around arc points
	for i in range(points.size()):
		vertices.append(points[i])
		colors.append(color)

	# Create line strip indices
	for i in range(points.size() - 1):
		indices.append(i)
		indices.append(i + 1)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	return array_mesh


## Create circle mesh for reticle
## @param radius: Circle radius
## @param segments: Number of segments
## @return: ArrayMesh representing a circle
func _create_circle_mesh(radius: float, segments: int) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	# Center vertex
	vertices.append(Vector3.ZERO)
	colors.append(Color.WHITE)

	# Circle vertices
	for i in range(segments + 1):
		var angle := float(i) / float(segments) * TAU
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		vertices.append(Vector3(x, 0, z))
		colors.append(Color.WHITE)

	# Create triangle fan indices
	for i in range(segments):
		indices.append(0)
		indices.append(i + 1)
		indices.append(i + 2)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return array_mesh


## Fade to black transition
func _fade_to_black() -> void:
	if fade_material == null:
		return

	var tween := create_tween()
	tween.tween_method(_set_fade_alpha, 0.0, 1.0, fade_duration)
	await tween.finished


## Fade from black transition
func _fade_from_black() -> void:
	if fade_material == null:
		return

	var tween := create_tween()
	tween.tween_method(_set_fade_alpha, 1.0, 0.0, fade_duration)
	await tween.finished


## Set fade alpha for shader
func _set_fade_alpha(alpha: float) -> void:
	if fade_material:
		fade_material.set_shader_parameter("fade_alpha", alpha)


## Perform raycast between two points
## @param from: Start position
## @param to: End position
## @return: Dictionary with hit info or null
func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	if collision_space == null:
		return {}

	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true

	var result := collision_space.intersect_ray(ray_query)
	return result


## Perform raycast for segment (helper)
func _raycast_segment(from: Vector3, to: Vector3) -> Dictionary:
	return _raycast(from, to)


## Perform sphere cast for clearance checking
## @param position: Center position
## @param radius: Sphere radius
## @return: Dictionary with hit info or null
func _sphere_cast(position: Vector3, radius: float) -> Dictionary:
	if collision_space == null:
		return {}

	# Use shape cast for sphere
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, position)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results := collision_space.intersect_shape(query, 1)
	if results.size() > 0:
		return results[0]
	return {}


## Handle snap rotation input during targeting
func _handle_snap_rotation_input() -> void:
	if not vr_manager or not snap_rotation_enabled:
		return

	var controller_state := vr_manager.get_controller_state(teleport_hand)
	if controller_state.is_empty():
		return

	var thumbstick: Vector2 = controller_state.get("thumbstick", Vector2.ZERO)

	# Rotate XR origin on snap
	if abs(thumbstick.x) > 0.7:
		var angle := snap_rotation_angle if thumbstick.x > 0 else -snap_rotation_angle
		if xr_origin:
			xr_origin.rotate_y(deg_to_rad(angle))


## Play feedback for invalid target
func _play_invalid_target_feedback() -> void:
	# Haptic feedback
	if haptic_feedback and haptic_manager:
		haptic_manager.trigger_haptic(teleport_hand, 0.3, 0.05)

	# Audio feedback
	if teleport_sound and teleport_sound.stream:
		teleport_sound.pitch_scale = INVALID_TARGET_SOUND_PITCH
		teleport_sound.play()

	print("[VRTeleportation] Invalid target - cannot teleport")


## Get fade shader code
func _get_fade_shader_code() -> String:
	return """
shader_type canvas_item;

uniform float fade_alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	COLOR = vec4(fade_color.rgb, fade_alpha);
}
"""


## Get reference to HapticManager
func _get_haptic_manager() -> HapticManager:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("get_haptic_manager"):
		return engine.get_haptic_manager()
	return get_node_or_null("/root/ResonanceEngine/HapticManager")


## Get reference to VRComfortSystem
func _get_vr_comfort_system() -> VRComfortSystem:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("get_vr_comfort_system"):
		return engine.get_vr_comfort_system()
	return get_node_or_null("/root/ResonanceEngine/VRComfortSystem")


## Get current target position
func get_current_target() -> Vector3:
	return current_target_position


## Check if currently targeting
func is_currently_targeting() -> bool:
	return is_targeting


## Check if currently teleporting
func is_currently_teleporting() -> bool:
	return is_teleporting


## Get current target validity
func is_current_target_valid() -> bool:
	return is_valid_target


## Set which hand controls teleportation
func set_teleport_hand(hand: String) -> void:
	teleport_hand = hand
	if vr_manager:
		controller = vr_manager.get_controller(hand)


## Set teleport range
func set_teleport_range(range: float) -> void:
	teleport_range = max(range, min_teleport_distance)


## Enable/disable snap rotation
func set_snap_rotation_enabled(enabled: bool) -> void:
	snap_rotation_enabled = enabled


## Shutdown and cleanup
func shutdown() -> void:
	set_process(false)
	set_physics_process(false)

	if arc_mesh_instance:
		arc_mesh_instance.queue_free()
	if reticle_mesh_instance:
		reticle_mesh_instance.queue_free()
	if fade_overlay:
		fade_overlay.queue_free()
	if teleport_sound:
		teleport_sound.queue_free()

	print("[VRTeleportation] Shutdown complete")
