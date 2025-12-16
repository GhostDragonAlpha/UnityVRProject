extends Node3D
## Floating Origin Test Scene
##
## Tests the FloatingOriginSystem by moving the player long distances.
##
## Controls:
##   W/S: Move forward/backward
##   A/D: Strafe left/right
##   Space: Move up (for testing)
##   Shift: Move down (for testing)
##   T: Teleport forward 5km (quick test)
##   R: Reset to origin
##   P: Print stats

## Movement speed (m/s)
const MOVE_SPEED := 10.0

## Fast teleport distance (meters)
const TELEPORT_DISTANCE := 5000.0  # 5km

## Player reference
@onready var player: CharacterBody3D = $Player

## UI label
@onready var status_label: Label = $UI/StatusLabel

## Distance markers parent
@onready var markers_parent: Node3D = $DistanceMarkers

## Statistics
var total_distance_traveled := 0.0
var shift_count := 0


func _ready() -> void:
	print("[FloatingOriginTest] Scene ready")

	# Register player with FloatingOriginSystem
	if player:
		FloatingOriginSystem.set_player(player)
		FloatingOriginSystem.register_object(player)
		print("[FloatingOriginTest] Player registered with FloatingOriginSystem")

	# Create initial distance markers
	_create_distance_markers()

	# Connect to universe shift (if we add signals later)
	# FloatingOriginSystem.universe_shifted.connect(_on_universe_shifted)


func _process(delta: float) -> void:
	# Handle input
	_handle_movement(delta)

	# Update UI
	_update_ui()

	# Check for teleport/reset
	if Input.is_action_just_pressed("ui_accept"):  # T key
		_teleport_forward()
	if Input.is_key_pressed(KEY_R):
		_reset_to_origin()
	if Input.is_key_pressed(KEY_P):
		_print_stats()


func _handle_movement(delta: float) -> void:
	if not player:
		return

	var velocity := Vector3.ZERO

	# Forward/backward
	if Input.is_key_pressed(KEY_W):
		velocity.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		velocity.z += 1.0

	# Strafe left/right
	if Input.is_key_pressed(KEY_A):
		velocity.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		velocity.x += 1.0

	# Up/down (for testing)
	if Input.is_key_pressed(KEY_SPACE):
		velocity.y += 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		velocity.y -= 1.0

	# Normalize and apply speed
	if velocity.length() > 0:
		velocity = velocity.normalized() * MOVE_SPEED

	# Apply velocity
	player.velocity = velocity
	player.move_and_slide()

	# Track distance
	var distance_this_frame := velocity.length() * delta
	total_distance_traveled += distance_this_frame


func _update_ui() -> void:
	if not status_label or not player:
		return

	var stats := FloatingOriginSystem.get_stats()
	var distance_from_origin: float = stats.distance_from_origin
	var universe_offset: Vector3 = stats.universe_offset
	var true_position := FloatingOriginSystem.get_true_global_position(player)

	status_label.text = "Floating Origin Test\n"
	status_label.text += "Distance from origin: %.2f m (%.2f km)\n" % [distance_from_origin, distance_from_origin / 1000.0]
	status_label.text += "Total distance traveled: %.2f m (%.2f km)\n" % [total_distance_traveled, total_distance_traveled / 1000.0]
	status_label.text += "Universe offset: (%.2f, %.2f, %.2f) km\n" % [universe_offset.x / 1000.0, universe_offset.y / 1000.0, universe_offset.z / 1000.0]
	status_label.text += "True position: (%.2f, %.2f, %.2f) km\n" % [true_position.x / 1000.0, true_position.y / 1000.0, true_position.z / 1000.0]
	status_label.text += "Universe shifts: %d\n" % shift_count
	status_label.text += "\n"
	status_label.text += "Controls:\n"
	status_label.text += "  WASD: Move, Space/Shift: Up/Down\n"
	status_label.text += "  Enter: Teleport 5km forward\n"
	status_label.text += "  R: Reset to origin\n"
	status_label.text += "  P: Print stats to console"

	# Check if shift occurred (distance dropped significantly)
	_check_for_shift(distance_from_origin)


var _last_distance := 0.0

func _check_for_shift(current_distance: float) -> void:
	# If distance suddenly decreased by a lot, a shift occurred
	if _last_distance > FloatingOriginSystem.SHIFT_THRESHOLD * 0.8 and current_distance < FloatingOriginSystem.SHIFT_THRESHOLD * 0.2:
		shift_count += 1
		print("[FloatingOriginTest] Universe shift detected! Total shifts: %d" % shift_count)

	_last_distance = current_distance


func _create_distance_markers() -> void:
	# Create markers every 2km up to 20km
	for i in range(1, 11):
		var distance := i * 2000.0  # 2km, 4km, 6km, etc.
		_create_marker(Vector3(0, 0, -distance), i * 2)


func _create_marker(position: Vector3, km: int) -> void:
	var marker := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(10, 50, 10)
	marker.mesh = box_mesh
	marker.position = position
	markers_parent.add_child(marker)

	# Register marker with FloatingOriginSystem
	FloatingOriginSystem.register_object(marker)

	# Create label above marker
	var label_3d := Label3D.new()
	label_3d.text = "%d km" % km
	label_3d.pixel_size = 0.05
	label_3d.position = position + Vector3(0, 30, 0)
	markers_parent.add_child(label_3d)

	FloatingOriginSystem.register_object(label_3d)


func _teleport_forward() -> void:
	if not player:
		return

	print("[FloatingOriginTest] Teleporting forward %d km" % (TELEPORT_DISTANCE / 1000))
	player.global_position += Vector3(0, 0, -TELEPORT_DISTANCE)
	total_distance_traveled += TELEPORT_DISTANCE


func _reset_to_origin() -> void:
	if not player:
		return

	print("[FloatingOriginTest] Resetting to origin")
	player.global_position = Vector3(0, 1, 0)
	total_distance_traveled = 0.0
	shift_count = 0


func _print_stats() -> void:
	print("[FloatingOriginTest] ===== Statistics =====")
	print("  Total distance traveled: %.2f km" % (total_distance_traveled / 1000.0))
	print("  Universe shifts: %d" % shift_count)
	FloatingOriginSystem.print_status()
