extends XRController3D
## Basic VR Controller - Simple movement and interaction for user testing
##
## Provides:
## - Teleport movement (trigger button)
## - Object grabbing (grip button)
## - Pointer ray for targeting

## Teleport ray mesh
var teleport_ray: MeshInstance3D = null
var teleport_target: MeshInstance3D = null

## Grab system
var held_object: RigidBody3D = null
var grab_joint: Generic6DOFJoint3D = null

## Movement speed
const TELEPORT_MAX_DISTANCE: float = 5.0

## Button state tracking
var trigger_was_pressed: bool = false
var grip_was_pressed: bool = false
var trigger_pressed: bool = false
var grip_pressed: bool = false


func _ready() -> void:
	# Create teleport visualization
	_setup_teleport_ray()
	_setup_teleport_target()

	print("[VR Controller] %s initialized" % name)


func _setup_teleport_ray() -> void:
	"""Create a visual ray for teleportation."""
	teleport_ray = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = TELEPORT_MAX_DISTANCE
	teleport_ray.mesh = cylinder

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	teleport_ray.material_override = material

	# Position ray in front of controller
	teleport_ray.rotation.x = -PI / 2  # Point forward
	teleport_ray.position.z = -TELEPORT_MAX_DISTANCE / 2

	add_child.call_deferred(teleport_ray)
	teleport_ray.visible = false


func _setup_teleport_target() -> void:
	"""Create a visual target indicator for teleportation."""
	teleport_target = MeshInstance3D.new()
	var circle = CylinderMesh.new()
	circle.top_radius = 0.3
	circle.bottom_radius = 0.3
	circle.height = 0.01
	teleport_target.mesh = circle

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 1.0, 0.4, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	teleport_target.material_override = material

	get_tree().root.add_child.call_deferred(teleport_target)
	teleport_target.visible = false


func _process(_delta: float) -> void:
	# Get button states (VRManager handles dead zones and debouncing)
	var vr_manager = _get_vr_manager()
	var controller_state = {}

	if vr_manager:
		controller_state = vr_manager.get_controller_state(_get_controller_hand())
		var trigger_value = controller_state.get("trigger", 0.0)
		var grip_value = controller_state.get("grip", 0.0)

		trigger_pressed = trigger_value > 0.5
		grip_pressed = grip_value > 0.5
	else:
		# Fallback to raw input if VRManager not available
		trigger_pressed = get_float("trigger") > 0.5
		grip_pressed = get_float("squeeze") > 0.5

	# Handle teleport (trigger button)
	if trigger_pressed and not trigger_was_pressed:
		_start_teleport()
	elif not trigger_pressed and trigger_was_pressed:
		_execute_teleport()

	# Handle grab (grip button)
	if grip_pressed and not grip_was_pressed:
		_try_grab()
	elif not grip_pressed and grip_was_pressed:
		_release_grab()

	# Update teleport visualization
	if trigger_pressed:
		_update_teleport_ray()

	# Update grabbed object position
	if held_object != null:
		_update_held_object()

	# Update button states
	trigger_was_pressed = trigger_pressed
	grip_was_pressed = grip_pressed


func _start_teleport() -> void:
	"""Start showing teleport ray."""
	teleport_ray.visible = true
	teleport_target.visible = true


func _update_teleport_ray() -> void:
	"""Update teleport ray and target position."""
	# Cast ray forward from controller
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var forward = -global_transform.basis.z
	var to = from + forward * TELEPORT_MAX_DISTANCE

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Only hit layer 1 (ground)

	var result = space_state.intersect_ray(query)

	if result:
		# Hit something, show target at hit point
		teleport_target.global_position = result.position
		teleport_target.global_position.y = result.position.y + 0.01  # Slightly above ground
		teleport_target.visible = true
	else:
		# No hit, hide target
		teleport_target.visible = false


func _execute_teleport() -> void:
	"""Teleport player to target location."""
	teleport_ray.visible = false

	if teleport_target.visible:
		# Get XROrigin3D (player root)
		var xr_origin = get_parent()
		if xr_origin is XROrigin3D:
			# Teleport to target position
			xr_origin.global_position = teleport_target.global_position
			print("[VR Controller] Teleported to: %s" % teleport_target.global_position)

	teleport_target.visible = false


func _try_grab() -> void:
	"""Try to grab an object."""
	if held_object != null:
		return  # Already holding something

	# Cast a short ray to find grabbable objects
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var forward = -global_transform.basis.z
	var to = from + forward * 0.5  # Short grab range

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Layer 2 for grabbable objects

	var result = space_state.intersect_ray(query)

	if result and result.collider is RigidBody3D:
		held_object = result.collider
		print("[VR Controller] Grabbed: %s" % held_object.name)

		# Disable gravity while held
		held_object.gravity_scale = 0.0
		held_object.linear_velocity = Vector3.ZERO
		held_object.angular_velocity = Vector3.ZERO


func _update_held_object() -> void:
	"""Update position of held object."""
	if held_object != null and is_instance_valid(held_object):
		# Smoothly move object towards controller
		var target_pos = global_position + (-global_transform.basis.z * 0.3)
		held_object.global_position = held_object.global_position.lerp(target_pos, 0.3)

		# Match controller rotation
		held_object.global_rotation = global_rotation


func _release_grab() -> void:
	"""Release the held object."""
	if held_object != null and is_instance_valid(held_object):
		print("[VR Controller] Released: %s" % held_object.name)

		# Re-enable gravity
		held_object.gravity_scale = 1.0

		# Apply velocity based on controller movement
		var controller_velocity = get_vector2("primary").length() * 5.0  # Simple approximation
		held_object.linear_velocity = -global_transform.basis.z * controller_velocity

		held_object = null


## Helper methods

func _get_vr_manager() -> Node:
	"""Get reference to VRManager."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node and engine_node.has_method("get_vr_manager"):
		return engine_node.get_vr_manager()

	return get_tree().root.find_child("VRManager", true, false)


func _get_controller_hand() -> String:
	"""Get which hand this controller represents (left or right)."""
	if "left" in name.to_lower():
		return "left"
	return "right"


func _exit_tree() -> void:
	"""Cleanup."""
	if teleport_target != null and is_instance_valid(teleport_target):
		teleport_target.queue_free()
