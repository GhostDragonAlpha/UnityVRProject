extends Node

## Test script to query VoxelPerformanceMonitor statistics
## Attaches to VoxelTerrainTest scene and prints voxel chunk generation data

var stats_timer: float = 0.0
var report_interval: float = 2.0  # Print stats every 2 seconds
var terrain_connected: bool = false


func _ready() -> void:
	print("=== VoxelStats Test Script Started ===")

	# Wait a frame for scene to fully load
	await get_tree().process_frame

	# Find and connect VoxelTerrain to VoxelPerformanceMonitor
	var terrain = get_node_or_null("/root/VoxelTerrainTest/VoxelTerrain")
	if terrain:
		print("[VoxelStats] Found VoxelTerrain node: ", terrain.name)

		# Connect to VoxelPerformanceMonitor
		var monitor = get_node_or_null("/root/VoxelPerformanceMonitor")
		if monitor:
			var success = monitor.set_voxel_terrain(terrain)
			if success:
				print("[VoxelStats] Successfully connected terrain to VoxelPerformanceMonitor")
				terrain_connected = true
			else:
				print("[VoxelStats] ERROR: Failed to connect terrain to VoxelPerformanceMonitor")
		else:
			print("[VoxelStats] ERROR: VoxelPerformanceMonitor autoload not found")
	else:
		print("[VoxelStats] ERROR: VoxelTerrain node not found in scene")

	# Get player position
	var player = get_node_or_null("/root/VoxelTerrainTest/TestPlayer")
	if player:
		print("[VoxelStats] Player position: ", player.global_position)

	# Enable debug UI
	var monitor2 = get_node_or_null("/root/VoxelPerformanceMonitor")
	if monitor2:
		monitor2.set_debug_ui_enabled(true)
		print("[VoxelStats] Debug UI enabled")


func _process(delta: float) -> void:
	stats_timer += delta

	if stats_timer >= report_interval:
		stats_timer = 0.0
		_print_statistics()


func _print_statistics() -> void:
	"""Print VoxelPerformanceMonitor statistics"""
	var monitor = get_node_or_null("/root/VoxelPerformanceMonitor")
	if not monitor:
		print("[VoxelStats] ERROR: VoxelPerformanceMonitor not available")
		return

	var stats = monitor.get_statistics()

	print("\n=== Voxel Performance Statistics ===")
	print("Terrain Connected: ", terrain_connected)
	print("\n--- Chunk Data ---")
	print("  Active Chunks: ", stats.get("active_chunk_count", "N/A"))
	print("  Total Generated: ", stats.get("total_chunks_generated", "N/A"))
	print("  Total Unloaded: ", stats.get("total_chunks_unloaded", "N/A"))
	print("  Max Chunks: ", stats.get("max_chunk_count", "N/A"))

	print("\n--- Generation Time ---")
	print("  Chunk Avg: %.2f ms" % stats.get("chunk_generation_avg_ms", 0.0))
	print("  Chunk Max: %.2f ms" % stats.get("chunk_generation_max_ms", 0.0))
	print("  Collision Avg: %.2f ms" % stats.get("collision_generation_avg_ms", 0.0))
	print("  Collision Max: %.2f ms" % stats.get("collision_generation_max_ms", 0.0))

	print("\n--- Frame Time (Target: %.2f ms for 90 FPS) ---" % stats.get("frame_time_budget_ms", 11.11))
	print("  Physics Avg: %.2f ms" % stats.get("physics_frame_time_ms", 0.0))
	print("  Physics Max: %.2f ms" % stats.get("physics_frame_time_max_ms", 0.0))
	print("  Render Avg: %.2f ms" % stats.get("render_frame_time_ms", 0.0))
	print("  Render Max: %.2f ms" % stats.get("render_frame_time_max_ms", 0.0))

	print("\n--- Memory ---")
	print("  Voxel Memory: %.1f MB / %.1f MB" % [stats.get("voxel_memory_mb", 0.0), stats.get("max_memory_mb", 0.0)])
	print("  Total Memory: %.1f MB" % stats.get("total_memory_mb", 0.0))

	var warnings = stats.get("warning_states", {})
	var has_warnings = stats.get("has_warnings", false)
	print("\n--- Warnings ---")
	if has_warnings:
		for warning_type in warnings:
			if warnings[warning_type]:
				print("  [!] ", warning_type.replace("_", " ").capitalize())
	else:
		print("  None - All systems nominal")

	# Check if chunks are generating
	var chunks_generated = stats.get("total_chunks_generated", 0)
	if chunks_generated == 0:
		print("\n[WARNING] NO CHUNKS HAVE BEEN GENERATED YET")
		print("  Possible issues:")
		print("  - VoxelTerrain may not be properly initialized")
		print("  - Player may be too far from terrain")
		print("  - Terrain view_distance may be too small")
		print("  - Terrain may not be enabled")

	print("=====================================\n")
