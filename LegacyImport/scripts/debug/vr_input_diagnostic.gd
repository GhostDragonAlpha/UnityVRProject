extends Node
## VR Input Diagnostic Tool
## Automatically logs all VR controller inputs to diagnose issues

var left_controller: XRController3D = null
var right_controller: XRController3D = null
var diagnostic_timer: float = 0.0
var log_interval: float = 1.0  # Log every second

func _ready():
	print("[VR Diagnostic] Starting VR input diagnostic...")

	# Find controllers in scene
	await get_tree().process_frame
	find_controllers()

	set_process(true)

func find_controllers():
	# Search for XRController3D nodes
	var root = get_tree().root
	left_controller = find_node_recursive(root, "LeftController")
	right_controller = find_node_recursive(root, "RightController")

	if left_controller:
		print("[VR Diagnostic] Found LeftController: ", left_controller.get_path())
	else:
		print("[VR Diagnostic] WARNING: LeftController not found!")

	if right_controller:
		print("[VR Diagnostic] Found RightController: ", right_controller.get_path())
	else:
		print("[VR Diagnostic] WARNING: RightController not found!")

func find_node_recursive(node: Node, target_name: String):
	if node.name == target_name and node is XRController3D:
		return node

	for child in node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result

	return null

func _process(delta: float):
	diagnostic_timer += delta

	if diagnostic_timer >= log_interval:
		diagnostic_timer = 0.0
		log_controller_state()

func log_controller_state():
	print("\n========== VR INPUT DIAGNOSTIC ==========")

	if left_controller:
		print("[LEFT CONTROLLER]")
		print("  Active: ", left_controller.get_is_active())
		print("  Tracker: ", left_controller.tracker)

		# Try all possible input names
		var inputs_to_test = [
			"primary",           # Standard thumbstick
			"thumbstick",        # Alternative name
			"trackpad",          # Index uses trackpad
			"joystick",          # Another alternative
		]

		for input_name in inputs_to_test:
			var vec = left_controller.get_vector2(input_name)
			if vec != Vector2.ZERO:
				print("  ", input_name, ": ", vec)

		# Test buttons
		print("  trigger: ", left_controller.get_float("trigger"))
		print("  grip: ", left_controller.get_float("grip"))

		# Test button presses
		var buttons_to_test = [
			"ax_button",
			"by_button",
			"menu_button",
			"primary_click",
			"trackpad_click",
		]

		for button in buttons_to_test:
			if left_controller.is_button_pressed(button):
				print("  BUTTON PRESSED: ", button)
	else:
		print("[LEFT CONTROLLER] Not found")

	print("=========================================\n")
