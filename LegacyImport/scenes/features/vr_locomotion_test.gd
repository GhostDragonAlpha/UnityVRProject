extends Node3D
## VR Locomotion Test Scene
## Tests VR flight movement, hand presence, and object grabbing in zero-G space environment

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController

var flight_enabled: bool = false
var flight_velocity: Vector3 = Vector3.ZERO
const FLIGHT_ACCELERATION: float = 2.0
const FLIGHT_MAX_SPEED: float = 5.0
const FLIGHT_DRAG: float = 0.8

func _ready() -> void:
	print("[VRLocomotionTest] Scene ready")

	# Initialize OpenXR
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("[VRLocomotionTest] Found OpenXR interface")

		if xr_interface.initialize():
			print("[VRLocomotionTest] OpenXR initialized successfully")

			# CRITICAL: Mark viewport for XR rendering
			get_viewport().use_xr = true
			print("[VRLocomotionTest] Viewport marked for XR rendering")

			# Activate XR camera
			xr_camera.current = true
			print("[VRLocomotionTest] XR Camera activated")

			print("[VRLocomotionTest] VR READY")
			print("[VRLocomotionTest] Controls:")
			print("[VRLocomotionTest]   - Left trigger: Toggle flight mode")
			print("[VRLocomotionTest]   - Left thumbstick: Move forward/back/strafe while in flight")
			print("[VRLocomotionTest]   - Right thumbstick: Turn left/right")
			print("[VRLocomotionTest]   - Grip buttons: Grab green cube")
		else:
			print("[VRLocomotionTest] ERROR: OpenXR initialization failed")
	else:
		print("[VRLocomotionTest] ERROR: OpenXR interface not found")


func _process(delta: float) -> void:
	if not left_controller or not right_controller:
		return

	# Toggle flight mode with left trigger
	if left_controller.is_button_pressed("trigger_click"):
		if not flight_enabled:
			flight_enabled = true
			print("[VRLocomotionTest] Flight mode ENABLED")
	elif flight_enabled:
		flight_enabled = false
		flight_velocity = Vector3.ZERO
		print("[VRLocomotionTest] Flight mode DISABLED")

	# Process flight movement
	if flight_enabled:
		_process_flight_movement(delta)


func _process_flight_movement(delta: float) -> void:
	# Get controller input
	var left_stick: Vector2 = left_controller.get_vector2("primary")
	var right_stick: Vector2 = right_controller.get_vector2("primary")

	# Calculate movement direction based on camera orientation
	var camera_basis: Basis = xr_camera.global_transform.basis
	var forward: Vector3 = -camera_basis.z
	var right: Vector3 = camera_basis.x

	# Apply movement input (thumbstick Y = forward/back, X = strafe left/right)
	var move_direction: Vector3 = Vector3.ZERO
	move_direction += forward * left_stick.y  # Forward/backward
	move_direction += right * left_stick.x    # Strafe left/right

	# Normalize and apply acceleration
	if move_direction.length() > 0:
		move_direction = move_direction.normalized()
		flight_velocity += move_direction * FLIGHT_ACCELERATION * delta

		# Clamp to max speed
		if flight_velocity.length() > FLIGHT_MAX_SPEED:
			flight_velocity = flight_velocity.normalized() * FLIGHT_MAX_SPEED

	# Apply drag
	flight_velocity *= (1.0 - FLIGHT_DRAG * delta)

	# Apply velocity to XR origin
	xr_origin.global_position += flight_velocity * delta

	# Apply rotation from right thumbstick
	if abs(right_stick.x) > 0.1:
		var rotation_speed: float = 1.5  # radians per second
		xr_origin.rotate_y(-right_stick.x * rotation_speed * delta)
