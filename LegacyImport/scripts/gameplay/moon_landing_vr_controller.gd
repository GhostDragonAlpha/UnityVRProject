extends Node
class_name MoonLandingVRController
## VR Controller for Moon Landing Scene
## Handles VR initialization, input mapping, and mode transitions
## Coordinates between spacecraft controls and walking mode

signal vr_mode_changed(is_vr: bool)
signal mode_switched(from_mode: String, to_mode: String)

enum Mode {
	SPACECRAFT,  ## Piloting spacecraft
	WALKING      ## Walking on moon surface
}

## References to scene nodes
@onready var xr_origin: XROrigin3D = get_node_or_null("../XROrigin3D")
@onready var xr_camera: XRCamera3D = get_node_or_null("../XROrigin3D/XRCamera3D")
@onready var left_controller: XRController3D = get_node_or_null("../XROrigin3D/LeftController")
@onready var right_controller: XRController3D = get_node_or_null("../XROrigin3D/RightController")
@onready var spacecraft: Spacecraft = get_node_or_null("../Spacecraft")
@onready var pilot_controller: PilotController = get_node_or_null("../Spacecraft/PilotController")
@onready var desktop_camera: Camera3D = get_node_or_null("../Environment/Camera3D")

## Walking controller (will be created on demand)
var walking_controller: WalkingController = null

## VR Manager reference
var vr_manager: VRManager = null

## Current mode
var current_mode: Mode = Mode.SPACECRAFT

## Is VR active
var is_vr_active: bool = false

## Cockpit camera position (relative to spacecraft)
var cockpit_camera_offset: Vector3 = Vector3(0, 1.5, 1.0)  ## Seated position in cockpit

## Walking spawn offset from spacecraft
var walking_spawn_offset: Vector3 = Vector3(0, -2.5, -5.0)  ## Spawn 5m in front, 2.5m below


func _ready() -> void:
	print("[MoonLandingVRController] Initializing VR controller")

	# Get VR manager from engine
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("get_vr_manager"):
		vr_manager = engine.get_vr_manager()

	# Initialize VR if available
	call_deferred("_initialize_vr")


func _initialize_vr() -> void:
	"""Initialize VR system and set up scene based on VR availability."""
	if not vr_manager:
		print("[MoonLandingVRController] VR Manager not available, attempting direct OpenXR initialization")
		_initialize_openxr_direct()
		return

	# Check if VR is active
	is_vr_active = vr_manager.is_vr_active()

	if is_vr_active:
		print("VR mode initialized successfully")
		_setup_vr_mode()
	else:
		print("enabling desktop fallback")
		_setup_desktop_mode()

	vr_mode_changed.emit(is_vr_active)


func _initialize_openxr_direct() -> void:
	"""Initialize OpenXR directly without VRManager (fallback mode)."""
	print("[MoonLandingVRController] Attempting direct OpenXR initialization...")

	var xr_interface = XRServer.find_interface("OpenXR")
	if not xr_interface:
		print("[MoonLandingVRController] OpenXR interface not found - using desktop mode")
		_setup_desktop_mode()
		return

	# CRITICAL: Enable viewport XR mode FIRST (required by OpenXR spec)
	print("[MoonLandingVRController] Enabling viewport XR mode...")
	get_viewport().use_xr = true

	# Initialize OpenXR if not already initialized
	if not xr_interface.is_initialized():
		print("[MoonLandingVRController] Initializing OpenXR interface...")
		if not xr_interface.initialize():
			print("[MoonLandingVRController] Failed to initialize OpenXR - using desktop mode")
			get_viewport().use_xr = false
			_setup_desktop_mode()
			return

	print("[MoonLandingVRController] OpenXR initialized successfully")
	is_vr_active = true
	_setup_vr_mode()
	vr_mode_changed.emit(is_vr_active)


func _setup_vr_mode() -> void:
	"""Set up scene for VR mode."""
	# Disable desktop camera
	if desktop_camera:
		desktop_camera.current = false

	# Enable XR viewport
	get_viewport().use_xr = true

	# Position XR origin at spacecraft cockpit
	_position_camera_in_cockpit()

	# Make XR camera current
	if xr_camera:
		xr_camera.current = true

	print("[MoonLandingVRController] VR mode setup complete")


func _setup_desktop_mode() -> void:
	"""Set up scene for desktop mode."""
	# Disable XR viewport
	get_viewport().use_xr = false

	# Enable desktop camera
	if desktop_camera:
		desktop_camera.current = true

	# Hide hand meshes (not needed in desktop)
	if left_controller:
		var left_hand = left_controller.get_node_or_null("LeftHand")
		if left_hand:
			left_hand.visible = false

	if right_controller:
		var right_hand = right_controller.get_node_or_null("RightHand")
		if right_hand:
			right_hand.visible = false

	print("[MoonLandingVRController] Desktop mode setup complete")


func _position_camera_in_cockpit() -> void:
	"""Position VR camera in spacecraft cockpit."""
	if not xr_origin or not spacecraft:
		return

	# Reparent XR origin to spacecraft
	if xr_origin.get_parent():
		xr_origin.get_parent().remove_child(xr_origin)

	spacecraft.add_child(xr_origin)

	# Position at cockpit location
	xr_origin.position = cockpit_camera_offset
	xr_origin.rotation = Vector3.ZERO

	print("[MoonLandingVRController] Camera positioned in cockpit at: ", cockpit_camera_offset)


func switch_to_walking_mode() -> void:
	"""Switch from spacecraft to walking mode."""
	if current_mode == Mode.WALKING:
		print("[MoonLandingVRController] Already in walking mode")
		return

	print("[MoonLandingVRController] Switching to walking mode")

	# Create walking controller if not exists
	if not walking_controller:
		_create_walking_controller()

	# Calculate spawn position (in front of spacecraft)
	var spawn_pos = spacecraft.global_position + spacecraft.global_transform.basis * walking_spawn_offset

	# Get current planet (Moon)
	var moon = get_node_or_null("../Moon")

	# Initialize walking controller
	walking_controller.initialize(vr_manager, moon, spawn_pos, spacecraft)

	# Reparent XR origin to walking controller
	if is_vr_active and xr_origin:
		if xr_origin.get_parent():
			xr_origin.get_parent().remove_child(xr_origin)

		walking_controller.add_child(xr_origin)
		xr_origin.position = Vector3(0, 0.9, 0)  ## Eye height
		xr_origin.rotation = Vector3.ZERO

	# Activate walking controller
	walking_controller.activate()

	# Update mode
	var previous_mode = "SPACECRAFT"
	current_mode = Mode.WALKING
	mode_switched.emit(previous_mode, "WALKING")

	print("[MoonLandingVRController] Walking mode activated at: ", spawn_pos)


func switch_to_spacecraft_mode() -> void:
	"""Switch from walking to spacecraft mode."""
	if current_mode == Mode.SPACECRAFT:
		print("[MoonLandingVRController] Already in spacecraft mode")
		return

	print("[MoonLandingVRController] Switching to spacecraft mode")

	# Deactivate walking controller
	if walking_controller:
		walking_controller.deactivate()

	# Reposition camera in cockpit
	_position_camera_in_cockpit()

	# Update mode
	var previous_mode = "WALKING"
	current_mode = Mode.SPACECRAFT
	mode_switched.emit(previous_mode, "SPACECRAFT")

	print("[MoonLandingVRController] Spacecraft mode activated")


func _create_walking_controller() -> void:
	"""Create walking controller node."""
	walking_controller = WalkingController.new()
	walking_controller.name = "WalkingController"

	# Add to scene
	get_parent().add_child(walking_controller)

	# Connect signals
	walking_controller.returned_to_spacecraft.connect(_on_returned_to_spacecraft)

	print("[MoonLandingVRController] Walking controller created")


func _on_returned_to_spacecraft() -> void:
	"""Handle return to spacecraft signal from walking controller."""
	print("[MoonLandingVRController] Player returned to spacecraft")
	switch_to_spacecraft_mode()


func get_current_mode() -> Mode:
	"""Get current mode."""
	return current_mode


func is_in_vr_mode() -> bool:
	"""Check if VR mode is active."""
	return is_vr_active


## Public API for querying state

func get_vr_manager() -> VRManager:
	"""Get VR manager reference."""
	return vr_manager


func get_walking_controller() -> WalkingController:
	"""Get walking controller reference."""
	return walking_controller


func get_spacecraft() -> Spacecraft:
	"""Get spacecraft reference."""
	return spacecraft
