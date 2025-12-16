extends SceneTree

## Minimal test to instantiate voxel_test_terrain.tscn
## Runs without autoloads to avoid initialization hangs

func _init():
	print("")
	print("============================================================")
	print("MINIMAL VOXEL TERRAIN INSTANTIATION TEST")
	print("============================================================")

	var scene_path = "res://voxel_test_terrain.tscn"

	# Test 1: Load scene
	print("\n[1] Loading scene: ", scene_path)
	var packed_scene = load(scene_path)
	if packed_scene == null:
		print("    FAILED: Could not load scene")
		quit(1)
		return
	print("    SUCCESS: Scene loaded")

	# Test 2: Instantiate scene
	print("\n[2] Instantiating scene...")
	var instance = packed_scene.instantiate()
	if instance == null:
		print("    FAILED: Could not instantiate scene")
		quit(1)
		return
	print("    SUCCESS: Scene instantiated")
	print("    Type: ", instance.get_class())
	print("    Name: ", instance.name)

	# Test 3: Check script
	print("\n[3] Checking script attachment...")
	var script = instance.get_script()
	if script == null:
		print("    WARNING: No script attached")
	else:
		print("    SUCCESS: Script attached")
		print("    Script: ", script.resource_path)

	# Test 4: Check if we can create VoxelTerrain
	print("\n[4] Testing VoxelTerrain class availability...")
	if ClassDB.class_exists("VoxelTerrain"):
		print("    SUCCESS: VoxelTerrain class is available")
		var voxel_test = ClassDB.instantiate("VoxelTerrain")
		if voxel_test:
			print("    SUCCESS: VoxelTerrain can be instantiated")
			voxel_test.free()
		else:
			print("    FAILED: Could not instantiate VoxelTerrain")
	else:
		print("    FAILED: VoxelTerrain class not found")
		print("    This means godot_voxel GDExtension is not loaded")

	# Cleanup
	instance.free()

	print("")
	print("============================================================")
	print("TEST COMPLETE: voxel_test_terrain.tscn can be instantiated")
	print("============================================================")
	print("")

	quit(0)
