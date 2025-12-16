extends Node3D
## VR Tracking Test Scene
## Tests VR headset and controller tracking functionality
## Press F12 to exit

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var fallback_camera: Camera3D = $XROrigin3D/FallbackCamera
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController

var xr_interface: XRInterface = null
var frame_count: int = 0
var fps_report_interval: int = 300  # Report FPS every 300 frames (5 seconds at 60fps)

func _ready() -> void:
	print("[VR Tracking Test] Initializing...")

	# Try to initialize VR
	xr_interface = XRServer.find_interface("OpenXR")

	if xr_interface:
		print("[VR Tracking Test] OpenXR interface found")

		if xr_interface.is_initialized():
			print("[VR Tracking Test] ✅ OpenXR already initialized")
			_setup_vr_mode()
		else:
			print("[VR Tracking Test] Attempting to initialize OpenXR...")
			if xr_interface.initialize():
				print("[VR Tracking Test] ✅ OpenXR initialized successfully")
				_setup_vr_mode()
			else:
				print("[VR Tracking Test] ❌ Failed to initialize OpenXR")
				_setup_fallback_mode()
	else:
		print("[VR Tracking Test] ⚠️  OpenXR interface not found - using fallback camera")
		_setup_fallback_mode()

	print("[VR Tracking Test] Scene ready - Press F12 to exit")

func _setup_vr_mode() -> void:
	"""Setup for VR mode"""
	print("[VR Tracking Test] Setting up VR mode...")

	# Enable XR camera
	xr_camera.current = true
	fallback_camera.current = false

	# Get viewport
	var viewport := get_viewport()
	viewport.use_xr = true

	print("[VR Tracking Test] VR mode configured")
	print("[VR Tracking Test] Red box = Left controller")
	print("[VR Tracking Test] Blue box = Right controller")

func _setup_fallback_mode() -> void:
	"""Setup for non-VR fallback mode"""
	print("[VR Tracking Test] Setting up fallback mode...")

	# Use fallback camera
	xr_camera.current = false
	fallback_camera.current = true

	var viewport := get_viewport()
	viewport.use_xr = false

	print("[VR Tracking Test] Fallback mode configured")

func _process(_delta: float) -> void:
	frame_count += 1

	# Report FPS periodically
	if frame_count % fps_report_interval == 0:
		var fps := Engine.get_frames_per_second()
		if fps < 90:
			print("[VR Tracking Test] FPS: %d (target: 90)" % fps)
		else:
			print("[VR Tracking Test] FPS: %d ✅" % fps)

	# Report controller tracking status every 5 seconds
	if frame_count % fps_report_interval == 0 and xr_interface and xr_interface.is_initialized():
		_report_tracking_status()

func _report_tracking_status() -> void:
	"""Report the current tracking status of VR devices"""
	print("\n[VR Tracking Test] === Tracking Status ===")

	# Check headset tracking
	var camera_transform := xr_camera.global_transform
	print("[VR Tracking Test] Headset: Position (%.2f, %.2f, %.2f)" % [
		camera_transform.origin.x,
		camera_transform.origin.y,
		camera_transform.origin.z
	])

	# Check controller tracking
	if left_controller.get_is_active():
		var left_pos := left_controller.global_transform.origin
		print("[VR Tracking Test] Left Controller ✅: Position (%.2f, %.2f, %.2f)" % [
			left_pos.x, left_pos.y, left_pos.z
		])
	else:
		print("[VR Tracking Test] Left Controller ❌: Not tracked")

	if right_controller.get_is_active():
		var right_pos := right_controller.global_transform.origin
		print("[VR Tracking Test] Right Controller ✅: Position (%.2f, %.2f, %.2f)" % [
			right_pos.x, right_pos.y, right_pos.z
		])
	else:
		print("[VR Tracking Test] Right Controller ❌: Not tracked")

	print("[VR Tracking Test] ========================\n")

func _unhandled_input(event: InputEvent) -> void:
	# F12 = Quick exit
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		print("[VR Tracking Test] F12 pressed - exiting to main scene")

		# Clean up XR
		if xr_interface and xr_interface.is_initialized():
			print("[VR Tracking Test] Uninitializing XR interface...")
			xr_interface.uninitialize()

		# Go back to minimal test scene
		get_tree().change_scene_to_file("res://minimal_test.tscn")

	# ESC = Alternative exit
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("[VR Tracking Test] ESC pressed - exiting to main scene")

		# Clean up XR
		if xr_interface and xr_interface.is_initialized():
			print("[VR Tracking Test] Uninitializing XR interface...")
			xr_interface.uninitialize()

		get_tree().change_scene_to_file("res://minimal_test.tscn")
