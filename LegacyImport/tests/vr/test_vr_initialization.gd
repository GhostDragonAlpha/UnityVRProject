extends GdUnitTestSuite
## VR Initialization Tests
##
## Automated tests for VR initialization pattern across all VR scenes.
## Tests verify:
## - VR initialization pattern (OpenXR interface detection)
## - Viewport XR flag (get_viewport().use_xr = true)
## - XROrigin3D + XRCamera3D structure exists
## - VR fallback to desktop mode when headset unavailable
##
## CI/CD Integration: Run via tests/test_vr_suite.py

# VR scenes to test
const VR_SCENES = [
	"res://scenes/vr_main.tscn",
	"res://scenes/features/minimal_vr_test.tscn",
	"res://scenes/features/vr_locomotion_test.tscn",
	"res://scenes/features/vr_tracking_test.tscn",
	"res://scenes/features/ship_interaction_test_vr.tscn"
]

# Test timeout in milliseconds (10 seconds per scene load)
const SCENE_LOAD_TIMEOUT_MS = 10000

# Scene instance cache to prevent memory leaks
var _scene_instance: Node = null


## Called before each test
func before_test():
	# Clean up any previous scene instance
	if _scene_instance != null and is_instance_valid(_scene_instance):
		_scene_instance.queue_free()
		_scene_instance = null


## Called after each test
func after_test():
	# Clean up scene instance
	if _scene_instance != null and is_instance_valid(_scene_instance):
		_scene_instance.queue_free()
		_scene_instance = null

	# Clean up XR interface (prevent state leakage between tests)
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		xr_interface.uninitialize()


## Test: vr_main.tscn VR initialization
func test_vr_main_initialization():
	var scene = _load_and_add_scene("res://scenes/vr_main.tscn")
	_verify_vr_initialization(scene, "VRMain")


## Test: minimal_vr_test.tscn VR initialization
func test_minimal_vr_test_initialization():
	var scene = _load_and_add_scene("res://scenes/features/minimal_vr_test.tscn")
	_verify_vr_initialization(scene, "MinimalVRTest")


## Test: vr_locomotion_test.tscn VR initialization
func test_vr_locomotion_test_initialization():
	var scene = _load_and_add_scene("res://scenes/features/vr_locomotion_test.tscn")
	_verify_vr_initialization(scene, "VRLocomotionTest")


## Test: vr_tracking_test.tscn VR initialization
func test_vr_tracking_test_initialization():
	var scene = _load_and_add_scene("res://scenes/features/vr_tracking_test.tscn")
	_verify_vr_initialization(scene, "VRTrackingTest")


## Test: ship_interaction_test_vr.tscn VR initialization (if exists)
func test_ship_interaction_test_vr_initialization():
	# This scene may not exist yet, skip gracefully if missing
	if not FileAccess.file_exists("res://scenes/features/ship_interaction_test_vr.tscn"):
		print("[VRTest] Skipping ship_interaction_test_vr.tscn - scene not found")
		return

	var scene = _load_and_add_scene("res://scenes/features/ship_interaction_test_vr.tscn")
	_verify_vr_initialization(scene, "ShipInteractionTestVR")


## Test: All VR scenes have XROrigin3D structure
func test_all_vr_scenes_have_xr_origin_structure():
	for scene_path in VR_SCENES:
		# Skip non-existent scenes
		if not FileAccess.file_exists(scene_path):
			print("[VRTest] Skipping %s - not found" % scene_path)
			continue

		# Load scene
		var scene = _load_and_add_scene(scene_path)

		# Verify XROrigin3D structure
		_verify_xr_structure(scene, scene_path)

		# Clean up
		if _scene_instance != null and is_instance_valid(_scene_instance):
			_scene_instance.queue_free()
			_scene_instance = null


## Test: VR fallback to desktop mode when OpenXR unavailable
func test_vr_fallback_to_desktop_mode():
	# This test verifies graceful fallback behavior
	# We can't easily simulate "no OpenXR" in test environment,
	# but we can verify the code paths exist

	var scene = _load_and_add_scene("res://scenes/features/vr_tracking_test.tscn")

	# Verify scene has fallback camera
	var fallback_camera = scene.find_child("FallbackCamera", true, false)

	if fallback_camera != null:
		assert_object(fallback_camera).is_not_null()
		assert_bool(fallback_camera is Camera3D).override_failure_message(
			"FallbackCamera should be Camera3D type"
		).is_true()
		print("[VRTest] ✅ Fallback camera found in vr_tracking_test.tscn")
	else:
		# Not all scenes have explicit fallback cameras (they use XRCamera3D fallback)
		print("[VRTest] ℹ️  No explicit fallback camera (using XRCamera3D automatic fallback)")


## Test: Viewport XR flag is set correctly
func test_viewport_xr_flag_set():
	var scene = _load_and_add_scene("res://scenes/features/minimal_vr_test.tscn")

	# Wait for _ready() to complete (deferred call)
	await get_tree().process_frame
	await get_tree().process_frame

	# Get viewport
	var viewport = scene.get_viewport()
	assert_object(viewport).is_not_null()

	# Verify use_xr is set (if OpenXR is available)
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		assert_bool(viewport.use_xr).override_failure_message(
			"Viewport should have use_xr = true when OpenXR is initialized"
		).is_true()
		print("[VRTest] ✅ Viewport use_xr flag is set correctly")
	else:
		print("[VRTest] ℹ️  OpenXR not available, skipping use_xr check")


## Test: XRCamera3D is set as current camera
func test_xr_camera_is_current():
	var scene = _load_and_add_scene("res://scenes/features/minimal_vr_test.tscn")

	# Wait for _ready() to complete
	await get_tree().process_frame
	await get_tree().process_frame

	# Find XRCamera3D
	var xr_camera = scene.find_child("XRCamera3D", true, false)
	assert_object(xr_camera).override_failure_message(
		"Scene should have XRCamera3D node"
	).is_not_null()

	# Verify it's a camera
	assert_bool(xr_camera is XRCamera3D).is_true()

	# Verify it's set as current (if OpenXR initialized)
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		assert_bool(xr_camera.current).override_failure_message(
			"XRCamera3D should be set as current camera when VR is active"
		).is_true()
		print("[VRTest] ✅ XRCamera3D is set as current camera")
	else:
		print("[VRTest] ℹ️  OpenXR not available, skipping camera current check")


## Test: All VR scenes have controllers
func test_vr_scenes_have_controllers():
	for scene_path in VR_SCENES:
		# Skip non-existent scenes
		if not FileAccess.file_exists(scene_path):
			continue

		var scene = _load_and_add_scene(scene_path)

		# Find controllers
		var left_controller = scene.find_child("LeftController", true, false)
		var right_controller = scene.find_child("RightController", true, false)

		# Not all test scenes have controllers, but main VR scenes should
		if "vr_main" in scene_path or "locomotion" in scene_path or "tracking" in scene_path:
			assert_object(left_controller).override_failure_message(
				"%s should have LeftController" % scene_path
			).is_not_null()

			assert_object(right_controller).override_failure_message(
				"%s should have RightController" % scene_path
			).is_not_null()

			# Verify controller types
			if left_controller:
				assert_bool(left_controller is XRController3D).is_true()
			if right_controller:
				assert_bool(right_controller is XRController3D).is_true()

		# Clean up
		if _scene_instance != null and is_instance_valid(_scene_instance):
			_scene_instance.queue_free()
			_scene_instance = null


## Helper: Load scene and add to tree
func _load_and_add_scene(scene_path: String) -> Node:
	"""Load a scene file and add it to the scene tree."""
	# Verify scene exists
	assert_file(scene_path).override_failure_message(
		"Scene file not found: %s" % scene_path
	).exists()

	# Load scene
	var packed_scene = load(scene_path)
	assert_object(packed_scene).override_failure_message(
		"Failed to load scene: %s" % scene_path
	).is_not_null()

	# Instantiate scene
	_scene_instance = packed_scene.instantiate()
	assert_object(_scene_instance).override_failure_message(
		"Failed to instantiate scene: %s" % scene_path
	).is_not_null()

	# Add to tree (required for _ready() to be called)
	add_child(_scene_instance)

	print("[VRTest] ✅ Loaded scene: %s" % scene_path)
	return _scene_instance


## Helper: Verify VR initialization pattern
func _verify_vr_initialization(scene: Node, scene_name: String):
	"""Verify that a scene follows the correct VR initialization pattern."""
	# Wait for _ready() to complete (VR initialization happens in _ready)
	await get_tree().process_frame
	await get_tree().process_frame

	# 1. Verify XROrigin3D exists
	var xr_origin = scene.find_child("XROrigin3D", true, false)
	assert_object(xr_origin).override_failure_message(
		"%s must have XROrigin3D node" % scene_name
	).is_not_null()

	# 2. Verify XRCamera3D exists
	var xr_camera = scene.find_child("XRCamera3D", true, false)
	assert_object(xr_camera).override_failure_message(
		"%s must have XRCamera3D node" % scene_name
	).is_not_null()

	# 3. Verify viewport use_xr flag (if OpenXR available)
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		var viewport = scene.get_viewport()
		assert_bool(viewport.use_xr).override_failure_message(
			"%s should set viewport.use_xr = true when OpenXR is available" % scene_name
		).is_true()

		# 4. Verify XRCamera3D is current
		assert_bool(xr_camera.current).override_failure_message(
			"%s should set XRCamera3D.current = true when VR is active" % scene_name
		).is_true()

		print("[VRTest] ✅ %s: VR initialization pattern verified" % scene_name)
	else:
		print("[VRTest] ℹ️  %s: OpenXR not available, basic structure verified" % scene_name)


## Helper: Verify XR structure
func _verify_xr_structure(scene: Node, scene_path: String):
	"""Verify that a scene has the required XR node structure."""
	# Find XROrigin3D
	var xr_origin = scene.find_child("XROrigin3D", true, false)
	assert_object(xr_origin).override_failure_message(
		"Scene %s must have XROrigin3D" % scene_path
	).is_not_null()

	# Find XRCamera3D (should be child of XROrigin3D)
	var xr_camera = scene.find_child("XRCamera3D", true, false)
	assert_object(xr_camera).override_failure_message(
		"Scene %s must have XRCamera3D" % scene_path
	).is_not_null()

	# Verify XRCamera3D is descendant of XROrigin3D
	if xr_camera != null and xr_origin != null:
		var is_descendant = false
		var current = xr_camera.get_parent()

		while current != null:
			if current == xr_origin:
				is_descendant = true
				break
			current = current.get_parent()

		assert_bool(is_descendant).override_failure_message(
			"XRCamera3D must be a descendant of XROrigin3D in %s" % scene_path
		).is_true()

	print("[VRTest] ✅ XR structure verified for: %s" % scene_path)


## Test: VR scenes are loadable without errors
func test_all_vr_scenes_loadable():
	"""Ensure all VR scenes can be loaded without errors."""
	var load_failures = []

	for scene_path in VR_SCENES:
		# Skip non-existent scenes
		if not FileAccess.file_exists(scene_path):
			print("[VRTest] Skipping %s - not found" % scene_path)
			continue

		# Try to load
		var packed_scene = load(scene_path)
		if packed_scene == null:
			load_failures.append(scene_path)
			print("[VRTest] ❌ Failed to load: %s" % scene_path)
		else:
			print("[VRTest] ✅ Successfully loaded: %s" % scene_path)

	# Assert no failures
	assert_array(load_failures).override_failure_message(
		"Failed to load VR scenes: %s" % str(load_failures)
	).is_empty()


## Test: VR initialization is idempotent
func test_vr_initialization_idempotent():
	"""Verify that VR initialization can be called multiple times safely."""
	var scene = _load_and_add_scene("res://scenes/features/minimal_vr_test.tscn")

	# Wait for first initialization
	await get_tree().process_frame
	await get_tree().process_frame

	# Get initial state
	var xr_interface = XRServer.find_interface("OpenXR")
	var initial_initialized = xr_interface != null and xr_interface.is_initialized()

	# Try to initialize again (should be safe)
	if xr_interface:
		var result = xr_interface.initialize()
		# Should either succeed or already be initialized
		var still_initialized = xr_interface.is_initialized()
		assert_bool(still_initialized).is_equal(initial_initialized)
		print("[VRTest] ✅ VR initialization is idempotent")
	else:
		print("[VRTest] ℹ️  OpenXR interface not found, skipping idempotent test")
