extends Node

## Test script to verify Zylann voxel GDExtension loaded correctly

func _ready():
	print("[VoxelTest] Testing voxel extension...")

	# Try to instantiate VoxelTerrain node
	var voxel_terrain = ClassDB.instantiate("VoxelTerrain")

	if voxel_terrain:
		print("[VoxelTest] ✓ VoxelTerrain class found - GDExtension loaded successfully!")
		print("[VoxelTest] VoxelTerrain type: ", voxel_terrain.get_class())

		# Check for key voxel classes
		var classes_to_check = [
			"VoxelTerrain",
			"VoxelLodTerrain",
			"VoxelMesher",
			"VoxelBlockyLibrary"
		]

		print("[VoxelTest] Checking available voxel classes:")
		for cls in classes_to_check:
			if ClassDB.class_exists(cls):
				print("[VoxelTest]   ✓ ", cls)
			else:
				print("[VoxelTest]   ✗ ", cls, " NOT FOUND")

		voxel_terrain.queue_free()
	else:
		print("[VoxelTest] ✗ FAILED - VoxelTerrain class not found!")
		print("[VoxelTest] GDExtension may not have loaded correctly.")
		print("[VoxelTest] Check addons/zylann.voxel/ directory exists.")
