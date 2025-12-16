extends Node
## Automated Movement Test
## Tests VR movement system automatically and reports results

var simulator = null
var player = null
var initial_position: Vector3 = Vector3.ZERO
var test_started: bool = false

func _ready():
	print("\n========== AUTOMATED MOVEMENT TEST ==========")
	print("[Auto Test] Initializing...")

	# Wait for scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame

	# Find player
	player = find_player_node()

	if not player:
		print("[Auto Test] FAILED: Player not found in scene")
		return

	print("[Auto Test] Player found: ", player.get_path())
	initial_position = player.global_position
	print("[Auto Test] Initial position: ", initial_position)

	# Create simulator
	var VRInputSimulatorScript = preload("res://scripts/debug/vr_input_simulator.gd")
	simulator = VRInputSimulatorScript.new()
	simulator.name = "VRInputSimulator"
	add_child(simulator)

	# Connect signals
	simulator.simulation_completed.connect(_on_simulation_completed)

	# Start test after 2 seconds
	await get_tree().create_timer(2.0).timeout
	start_test()

func find_player_node() -> Node:
	# Search for WalkingController or Player node
	var root = get_tree().root
	return find_node_recursive(root, "Player")

func find_node_recursive(node: Node, target_name: String):
	if node.name == target_name:
		return node

	for child in node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result

	return null

func start_test():
	print("\n========== STARTING MOVEMENT TEST ==========")
	print("[Auto Test] Starting simulated movement...")

	test_started = true
	set_process(true)

	# Start simulator
	simulator.start_movement_test()

func _process(delta: float):
	if not test_started or not player:
		return

	# Monitor player position
	var current_pos = player.global_position
	var distance_moved = initial_position.distance_to(current_pos)

	# Log every second
	if Engine.get_frames_drawn() % 90 == 0:  # 90 FPS
		print("[Auto Test] Position: ", current_pos, " | Moved: ", distance_moved, "m")

func _on_simulation_completed(success: bool):
	print("\n========== TEST RESULTS ==========")

	if not player:
		print("[Auto Test] FAILED: Player node not found")
		return

	var final_position = player.global_position
	var distance_moved = initial_position.distance_to(final_position)

	print("[Auto Test] Initial position: ", initial_position)
	print("[Auto Test] Final position:   ", final_position)
	print("[Auto Test] Distance moved:   ", distance_moved, " meters")

	if distance_moved > 0.5:  # Moved at least 0.5 meters
		print("[Auto Test] ✓ SUCCESS: Player movement working!")
		print("[Auto Test] Movement system is functional")
	else:
		print("[Auto Test] ✗ FAILED: Player did not move")
		print("[Auto Test] Expected movement >0.5m, got ", distance_moved, "m")
		print("[Auto Test] Possible issues:")
		print("[Auto Test] - VR controller input not being read")
		print("[Auto Test] - WalkingController not processing input")
		print("[Auto Test] - Physics not enabled")

	print("====================================\n")
