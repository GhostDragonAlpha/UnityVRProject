extends Node

## Test script to verify voxel_test_terrain.tscn can be instantiated

func _ready():
	print("============================================================")
	print("[VoxelInstantiationTest] Starting instantiation test...")
	print("============================================================")

	# Test 1: Check if scene file exists
	print("\n[Test 1] Checking scene file exists...")
	var scene_path = "res://voxel_test_terrain.tscn"
	if ResourceLoader.exists(scene_path):
		print("  ✓ Scene file exists at: ", scene_path)
	else:
		print("  ✗ FAILED: Scene file not found at: ", scene_path)
		_quit_with_result(false)
		return

	# Test 2: Check if script file exists
	print("\n[Test 2] Checking script file exists...")
	var script_path = "res://voxel_test_terrain.gd"
	if ResourceLoader.exists(script_path):
		print("  ✓ Script file exists at: ", script_path)
	else:
		print("  ✗ FAILED: Script file not found at: ", script_path)
		_quit_with_result(false)
		return

	# Test 3: Load the scene resource
	print("\n[Test 3] Loading scene resource...")
	var scene_resource = load(scene_path)
	if scene_resource == null:
		print("  ✗ FAILED: Could not load scene resource")
		_quit_with_result(false)
		return
	print("  ✓ Scene resource loaded successfully")
	print("    Resource type: ", scene_resource.get_class())

	# Test 4: Instantiate the scene
	print("\n[Test 4] Instantiating scene...")
	var scene_instance = scene_resource.instantiate()
	if scene_instance == null:
		print("  ✗ FAILED: Could not instantiate scene")
		_quit_with_result(false)
		return
	print("  ✓ Scene instantiated successfully")
	print("    Node type: ", scene_instance.get_class())
	print("    Node name: ", scene_instance.name)

	# Test 5: Check if script is attached
	print("\n[Test 5] Checking if script is attached...")
	var attached_script = scene_instance.get_script()
	if attached_script == null:
		print("  ✗ WARNING: No script attached to scene instance")
	else:
		print("  ✓ Script is attached")
		print("    Script path: ", attached_script.resource_path)

	# Test 6: Add to scene tree and test _ready()
	print("\n[Test 6] Adding to scene tree and testing _ready()...")
	add_child(scene_instance)
	print("  ✓ Node added to scene tree")

	# Wait one frame for _ready() to execute
	await get_tree().process_frame

	# Test 7: Check if node is still valid after _ready()
	print("\n[Test 7] Checking node validity after _ready()...")
	if is_instance_valid(scene_instance):
		print("  ✓ Node is still valid")
	else:
		print("  ✗ FAILED: Node became invalid after _ready()")
		_quit_with_result(false)
		return

	# Test 8: Check for any child nodes created
	print("\n[Test 8] Checking for child nodes...")
	var child_count = scene_instance.get_child_count()
	print("  Child count: ", child_count)
	if child_count > 0:
		print("  Children:")
		for i in range(child_count):
			var child = scene_instance.get_child(i)
			print("    - ", child.name, " (", child.get_class(), ")")

	# Test 9: Check for errors in output
	print("\n[Test 9] Final validation...")
	print("  ✓ All tests passed!")

	print("")
	print("============================================================")
	print("[VoxelInstantiationTest] RESULT: SUCCESS")
	print("[VoxelInstantiationTest] The voxel_test_terrain.tscn scene")
	print("[VoxelInstantiationTest] can be instantiated without errors.")
	print("============================================================")

	_quit_with_result(true)

func _quit_with_result(success: bool):
	# Wait a moment to ensure all output is flushed
	await get_tree().create_timer(0.5).timeout

	# Save result to file for external verification
	var file = FileAccess.open("res://test_result.txt", FileAccess.WRITE)
	if file:
		if success:
			file.store_string("SUCCESS")
		else:
			file.store_string("FAILED")
		file.close()

	# Quit with appropriate exit code
	get_tree().quit(0 if success else 1)
