extends RigidBody3D
class_name XRToolsPickable

## XRToolsPickable - Grabbable object implementation
##
## Implements the XRToolsPickable interface for objects that can be picked up,
## held, and thrown by VR controllers using XRToolsFunctionPickup.
##
## This script provides physics-based interaction with VR hand controllers,
## including grab detection, hold mechanics, and throw force application.

## If true, this object can be picked up by the player
@export var can_pick_up := true

## If true, this object can be grabbed from a distance (ranged grab)
@export var can_ranged_grab := false

## If true, player must hold button to keep object grabbed (vs toggle)
@export var press_to_hold := false

## Reference to the XRToolsFunctionPickup instance currently holding this object
var _picked_up_by: XRToolsFunctionPickup = null


## Called when a controller picks up this object
## Freezes physics and tracks the grabbing controller
func pick_up(by: XRToolsFunctionPickup) -> void:
	if not can_pick_up:
		return

	_picked_up_by = by
	freeze = true


## Called when a controller releases this object
## Unfreezes physics and applies throw velocity/angular velocity
func let_go(by: XRToolsFunctionPickup, impulse: Vector3, angular_impulse: Vector3) -> void:
	if _picked_up_by != by:
		return

	_picked_up_by = null
	freeze = false

	# Apply throw forces
	apply_central_impulse(impulse)
	apply_torque_impulse(angular_impulse)


## Returns true if this object is currently being held by a controller
func is_picked_up() -> bool:
	return _picked_up_by != null


## Called to request visual highlight when controller hovers over object
## Optional implementation - can be used to add emission shader or outline
func request_highlight(by: XRToolsFunctionPickup, enable: bool) -> void:
	# Optional: Add visual feedback here
	# Example: Change material emission, add outline shader, etc.
	pass
