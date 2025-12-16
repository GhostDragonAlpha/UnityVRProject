## Dictionary Validators - Type checking and validation for Dictionary structures
## Provides utility functions to validate Dictionary structures used across
## the physics and VR systems, ensuring all required keys exist with correct types.
extends Node
class_name DictionaryValidators

#region Type Definitions

## CelestialBody Dictionary structure (used in PhysicsEngine)
## {
##   "node": Node3D - Reference to the 3D node representing the celestial body
##   "mass": float - Mass in arbitrary units (used for gravity calculations)
##   "radius": float - Radius in meters (used for escape velocity and SOI calculations)
##   "position": Vector3 - Cached world position updated each frame
## }

## CollisionInfo Dictionary structure (used in HapticManager and Spacecraft signals)
## {
##   "velocity": Vector3 - Velocity vector at time of collision
##   "position": Vector3 - Position where collision occurred
##   "normal": Vector3 - Surface normal at collision point
##   "depth": float - Penetration depth of collision
##   "collider": Node3D - The node that was collided with
##   "collider_id": int - RID of the colliding object (optional)
## }

## ControllerState Dictionary structure (used in VRManager)
## {
##   "trigger": float - Trigger value (0.0 to 1.0)
##   "grip": float - Grip value (0.0 to 1.0)
##   "thumbstick": Vector2 - Thumbstick position (-1.0 to 1.0)
##   "button_ax": bool - A/X button state (left controller: X, right: A)
##   "button_by": bool - B/Y button state (left controller: Y, right: B)
##   "button_menu": bool - Menu button state
##   "thumbstick_click": bool - Thumbstick click/press state
##   "position": Vector3 - Controller position (optional)
##   "rotation": Quaternion - Controller rotation (optional)
## }

#endregion

#region CelestialBody Validation

## Validate a CelestialBody dictionary has all required fields with correct types
static func validate_celestial_body(data: Dictionary) -> bool:
	"""Check if dictionary is a valid CelestialBody."""
	if not data.has("node"):
		push_error("CelestialBody missing 'node' field")
		return false
	if not (data["node"] is Node3D or data["node"] == null):
		push_error("CelestialBody 'node' must be Node3D or null, got %s" % data["node"].get_class())
		return false

	if not data.has("mass"):
		push_error("CelestialBody missing 'mass' field")
		return false
	if not data["mass"] is float:
		push_error("CelestialBody 'mass' must be float, got %s" % typeof(data["mass"]))
		return false

	if not data.has("radius"):
		push_error("CelestialBody missing 'radius' field")
		return false
	if not data["radius"] is float:
		push_error("CelestialBody 'radius' must be float, got %s" % typeof(data["radius"]))
		return false

	if not data.has("position"):
		push_error("CelestialBody missing 'position' field")
		return false
	if not data["position"] is Vector3:
		push_error("CelestialBody 'position' must be Vector3, got %s" % typeof(data["position"]))
		return false

	return true


## Create a new valid CelestialBody dictionary
static func create_celestial_body(node: Node3D, mass: float, radius: float, position: Vector3 = Vector3.ZERO) -> Dictionary:
	"""Create a new CelestialBody dictionary with default values."""
	var pos = position if position != Vector3.ZERO else (node.global_position if node else Vector3.ZERO)
	return {
		"node": node,
		"mass": mass,
		"radius": radius,
		"position": pos
	}

#endregion

#region CollisionInfo Validation

## Validate a CollisionInfo dictionary has all required fields with correct types
static func validate_collision_info(data: Dictionary) -> bool:
	"""Check if dictionary is a valid CollisionInfo."""
	if not data.has("velocity"):
		push_error("CollisionInfo missing 'velocity' field")
		return false
	if not data["velocity"] is Vector3:
		push_error("CollisionInfo 'velocity' must be Vector3, got %s" % typeof(data["velocity"]))
		return false

	# Position, normal, and depth are recommended but optional
	if data.has("position") and not data["position"] is Vector3:
		push_error("CollisionInfo 'position' must be Vector3 if present, got %s" % typeof(data["position"]))
		return false

	if data.has("normal") and not data["normal"] is Vector3:
		push_error("CollisionInfo 'normal' must be Vector3 if present, got %s" % typeof(data["normal"]))
		return false

	if data.has("depth") and not data["depth"] is float:
		push_error("CollisionInfo 'depth' must be float if present, got %s" % typeof(data["depth"]))
		return false

	return true


## Create a new valid CollisionInfo dictionary
static func create_collision_info(velocity: Vector3, position: Vector3 = Vector3.ZERO,
		normal: Vector3 = Vector3.ZERO, depth: float = 0.0, collider: Node3D = null) -> Dictionary:
	"""Create a new CollisionInfo dictionary with provided values."""
	var info = {
		"velocity": velocity,
		"position": position,
		"normal": normal,
		"depth": depth
	}

	if collider:
		info["collider"] = collider

	return info

#endregion

#region ControllerState Validation

## Validate a ControllerState dictionary has all required fields with correct types
static func validate_controller_state(data: Dictionary) -> bool:
	"""Check if dictionary is a valid ControllerState."""
	if not data.has("trigger"):
		push_error("ControllerState missing 'trigger' field")
		return false
	if not data["trigger"] is float:
		push_error("ControllerState 'trigger' must be float, got %s" % typeof(data["trigger"]))
		return false

	if not data.has("grip"):
		push_error("ControllerState missing 'grip' field")
		return false
	if not data["grip"] is float:
		push_error("ControllerState 'grip' must be float, got %s" % typeof(data["grip"]))
		return false

	if not data.has("thumbstick"):
		push_error("ControllerState missing 'thumbstick' field")
		return false
	if not data["thumbstick"] is Vector2:
		push_error("ControllerState 'thumbstick' must be Vector2, got %s" % typeof(data["thumbstick"]))
		return false

	if not data.has("button_ax"):
		push_error("ControllerState missing 'button_ax' field")
		return false
	if not data["button_ax"] is bool:
		push_error("ControllerState 'button_ax' must be bool, got %s" % typeof(data["button_ax"]))
		return false

	if not data.has("button_by"):
		push_error("ControllerState missing 'button_by' field")
		return false
	if not data["button_by"] is bool:
		push_error("ControllerState 'button_by' must be bool, got %s" % typeof(data["button_by"]))
		return false

	if not data.has("button_menu"):
		push_error("ControllerState missing 'button_menu' field")
		return false
	if not data["button_menu"] is bool:
		push_error("ControllerState 'button_menu' must be bool, got %s" % typeof(data["button_menu"]))
		return false

	if not data.has("thumbstick_click"):
		push_error("ControllerState missing 'thumbstick_click' field")
		return false
	if not data["thumbstick_click"] is bool:
		push_error("ControllerState 'thumbstick_click' must be bool, got %s" % typeof(data["thumbstick_click"]))
		return false

	# Position and rotation are optional
	if data.has("position") and not data["position"] is Vector3:
		push_error("ControllerState 'position' must be Vector3 if present, got %s" % typeof(data["position"]))
		return false

	if data.has("rotation") and not data["rotation"] is Quaternion:
		push_error("ControllerState 'rotation' must be Quaternion if present, got %s" % typeof(data["rotation"]))
		return false

	return true


## Create a new valid ControllerState dictionary with default values
static func create_controller_state(trigger: float = 0.0, grip: float = 0.0,
		thumbstick: Vector2 = Vector2.ZERO, button_ax: bool = false, button_by: bool = false,
		button_menu: bool = false, thumbstick_click: bool = false,
		position: Vector3 = Vector3.ZERO, rotation: Quaternion = Quaternion.IDENTITY) -> Dictionary:
	"""Create a new ControllerState dictionary with provided values."""
	return {
		"trigger": clamp(trigger, 0.0, 1.0),
		"grip": clamp(grip, 0.0, 1.0),
		"thumbstick": thumbstick.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0)),
		"button_ax": button_ax,
		"button_by": button_by,
		"button_menu": button_menu,
		"thumbstick_click": thumbstick_click,
		"position": position,
		"rotation": rotation
	}

#endregion

#region Continuous Effects Validation

## HapticManager ContinuousEffect structure:
## {
##   "intensity": float - Haptic intensity (0.0 to 1.0)
##   "start_time": float - Time when effect started (seconds)
##   "duration": float - Duration of effect in seconds (-1.0 for infinite)
## }

## Validate a ContinuousEffect dictionary
static func validate_continuous_effect(data: Dictionary) -> bool:
	"""Check if dictionary is a valid ContinuousEffect."""
	if not data.has("intensity"):
		push_error("ContinuousEffect missing 'intensity' field")
		return false
	if not data["intensity"] is float:
		push_error("ContinuousEffect 'intensity' must be float, got %s" % typeof(data["intensity"]))
		return false

	if not data.has("start_time"):
		push_error("ContinuousEffect missing 'start_time' field")
		return false
	if not data["start_time"] is float:
		push_error("ContinuousEffect 'start_time' must be float, got %s" % typeof(data["start_time"]))
		return false

	if not data.has("duration"):
		push_error("ContinuousEffect missing 'duration' field")
		return false
	if not data["duration"] is float:
		push_error("ContinuousEffect 'duration' must be float, got %s" % typeof(data["duration"]))
		return false

	return true


## Create a new valid ContinuousEffect dictionary
static func create_continuous_effect(intensity: float, start_time: float, duration: float = -1.0) -> Dictionary:
	"""Create a new ContinuousEffect dictionary."""
	return {
		"intensity": clamp(intensity, 0.0, 1.0),
		"start_time": start_time,
		"duration": duration
	}

#endregion
