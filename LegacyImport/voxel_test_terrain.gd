extends Node3D

## Simple script to set up VoxelTerrain for testing player landing

@onready var voxel_terrain: Node = null

func _ready():
	print("[VoxelTestTerrain] Initializing voxel terrain...")

	# Try to find VoxelTerrain node
	voxel_terrain = find_child("VoxelTerrain", true, false)

	if voxel_terrain == null:
		# Create VoxelTerrain programmatically if it doesn't exist
		print("[VoxelTestTerrain] Creating VoxelTerrain node...")
		voxel_terrain = ClassDB.instantiate("VoxelTerrain")

		if voxel_terrain:
			add_child(voxel_terrain)
			_configure_voxel_terrain()
		else:
			print("[VoxelTestTerrain] ERROR: Failed to instantiate VoxelTerrain!")
			print("[VoxelTestTerrain] Make sure godot_voxel GDExtension is loaded.")
			return
	else:
		print("[VoxelTestTerrain] Found existing VoxelTerrain node")
		_configure_voxel_terrain()

func _configure_voxel_terrain():
	print("[VoxelTestTerrain] Configuring voxel terrain...")

	# Create a simple stream for flat terrain
	# Note: We'll use VoxelGeneratorFlat if available, or set up manually

	# Enable collision
	if voxel_terrain.has_method("set_generate_collisions"):
		voxel_terrain.set_generate_collisions(true)
		print("[VoxelTestTerrain] Collision generation enabled")

	# Set view distance
	if voxel_terrain.has_method("set_view_distance"):
		voxel_terrain.set_view_distance(128)
		print("[VoxelTestTerrain] View distance set to 128")

	# Try to create a simple flat generator
	var generator = ClassDB.instantiate("VoxelGeneratorFlat")
	if generator:
		print("[VoxelTestTerrain] Created VoxelGeneratorFlat")

		# Set height to 0 for flat terrain at origin
		if generator.has_method("set_height"):
			generator.set_height(0.0)

		# Create stream
		var stream = ClassDB.instantiate("VoxelStreamScripted")
		if stream and stream.has_method("set_generator"):
			stream.set_generator(generator)

			if voxel_terrain.has_method("set_stream"):
				voxel_terrain.set_stream(stream)
				print("[VoxelTestTerrain] Stream configured with flat generator")
	else:
		print("[VoxelTestTerrain] VoxelGeneratorFlat not available, terrain will be empty")

	print("[VoxelTestTerrain] Configuration complete!")
	print("[VoxelTestTerrain] Voxel terrain should be visible and collidable")
