extends Node3D
## Ship Interaction Test VR Scene
## Tests VR interaction with spacecraft cockpit controls

## Reference to XR components
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController

## Reference to UI status label
@onready var status_label: Label = $UI/StatusLabel

## VR initialization state
var vr_initialized: bool = false

func _ready() -> void:
	print("[ShipInteractionTestVR] Scene ready")

	# Update status
	_update_status("Initializing VR...")

	# Initialize OpenXR
	var xr_interface = XRServer.find_interface("OpenXR")
	if not xr_interface:
		print("[ShipInteractionTestVR] ERROR: OpenXR interface not found")
		_update_status("ERROR: OpenXR interface not found\nRunning in desktop mode")
		return

	print("[ShipInteractionTestVR] Found OpenXR interface")

	# Initialize the interface (CRITICAL - must happen before use_xr)
	if not xr_interface.initialize():
		print("[ShipInteractionTestVR] ERROR: OpenXR initialization failed")
		_update_status("ERROR: OpenXR initialization failed\nCheck SteamVR is running")
		return

	print("[ShipInteractionTestVR] OpenXR initialized successfully")

	# CRITICAL: Mark viewport for XR rendering
	get_viewport().use_xr = true
	print("[ShipInteractionTestVR] Viewport marked for XR rendering")

	# Activate XR camera
	xr_camera.current = true
	print("[ShipInteractionTestVR] XR Camera activated")

	vr_initialized = true
	_update_status("VR READY\nTest ship cockpit interactions")
	print("[ShipInteractionTestVR] VR initialization complete")


func _update_status(text: String) -> void:
	"""Update the status label with current information."""
	if is_instance_valid(status_label):
		status_label.text = "Ship Interaction Test (VR)\n" + text


func _physics_process(_delta: float) -> void:
	"""Monitor VR controller states."""
	if not vr_initialized:
		return

	# Check controller tracking
	if Engine.get_physics_frames() % 60 == 0:  # Once per second at 60fps
		var left_tracked = left_controller.get_is_active() if is_instance_valid(left_controller) else false
		var right_tracked = right_controller.get_is_active() if is_instance_valid(right_controller) else false

		var controller_status = ""
		if left_tracked and right_tracked:
			controller_status = "Controllers: Both tracked"
		elif left_tracked:
			controller_status = "Controllers: Left only"
		elif right_tracked:
			controller_status = "Controllers: Right only"
		else:
			controller_status = "Controllers: None tracked"

		_update_status("VR READY\n" + controller_status + "\nTest ship cockpit interactions")
