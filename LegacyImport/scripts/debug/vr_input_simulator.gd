extends Node
## VR Input Simulator
## Simulates VR controller inputs for automated testing

signal simulation_started
signal simulation_completed(success: bool)

var test_duration: float = 5.0  # Run test for 5 seconds
var test_timer: float = 0.0
var is_running: bool = false

# Simulated input values
var simulated_left_thumbstick: Vector2 = Vector2.ZERO
var simulated_right_thumbstick: Vector2 = Vector2.ZERO
var simulated_trigger: float = 0.0
var simulated_grip: float = 0.0
var simulate_jetpack: bool = false  # Enable jetpack thrust simulation

func _ready():
	print("[VR Input Simulator] Ready - call start_movement_test() to begin")

func start_movement_test():
	print("\n========== STARTING AUTOMATED MOVEMENT TEST ==========")
	print("[VR Simulator] Simulating forward movement for ", test_duration, " seconds")
	is_running = true
	test_timer = 0.0

	# Simulate pushing thumbstick forward
	simulated_left_thumbstick = Vector2(0, -1.0)  # Forward movement

	set_process(true)
	simulation_started.emit()

func stop_simulation():
	print("[VR Simulator] Stopping simulation")
	is_running = false
	simulated_left_thumbstick = Vector2.ZERO
	set_process(false)

func _process(delta: float):
	if not is_running:
		return

	test_timer += delta

	if test_timer >= test_duration:
		print("[VR Simulator] Test duration reached")
		stop_simulation()
		simulation_completed.emit(true)

## Get simulated controller state (called by VRManager)
func get_simulated_state(hand: String) -> Dictionary:
	# Simulate grip for jetpack on right hand
	var grip_value = simulated_grip
	if hand == "right" and simulate_jetpack:
		grip_value = 1.0  # Full grip for jetpack thrust

	return {
		"trigger": simulated_trigger,
		"grip": grip_value,
		"thumbstick": simulated_left_thumbstick if hand == "left" else simulated_right_thumbstick,
		"button_ax": false,
		"button_by": false,
		"button_menu": false,
		"thumbstick_click": false,
		"position": Vector3.ZERO,
		"rotation": Quaternion.IDENTITY
	}
